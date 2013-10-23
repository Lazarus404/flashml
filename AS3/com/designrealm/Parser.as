package com.designrealm.flashml {
	
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;	
	import flash.net.URLRequest;
	import flash.utils.ByteArray;	
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	import flash.events.EventDispatcher;	
	
	import com.designrealm.module.Validation;
	import com.designrealm.core.DesignrealmSystem;
	
	public class Parser extends EventDispatcher {
		
		private var path:String;
		public var tags:Array;
		public var tableData:Object;
		private var reXML:RegExp = /^\<\?xml>/;
		private var reSpace:RegExp = /^\W+$/mg;
		private var reNonSpace:RegExp = /\w/mg;
		
		public function Parser(){
			tags = new Array();
		}
		
		public function parseData(xmlContent:XMLNode):Object{		
			// blank xml tag - but this should never occur as all nulls as cleared
			if (xmlContent == null || xmlContent.nodeName == null)
				return null;				
						
			var type:String
			type = xmlContent.nodeName.toLowerCase();
			removeNullFromXML(xmlContent.childNodes);
			
			// custom tag being executed
			if(tags[type] != undefined){				
				var parserResult:* = tags[type].apply(null, [xmlContent]);				
				if(!parserResult) return null;				
				if(parserResult is XMLDocument || parserResult is XMLNode){
					xmlContent = parserResult;
				} else {
					var xml:XMLDocument = new XMLDocument();
					xml.parseXML(parserResult);
					xmlContent = xml.childNodes[0];
				}				
				type = xmlContent.nodeName.toLowerCase();
			}			
			var obj:Object = new Object();
			
			/*			
			if(xmlContent.attributes.src != null && xmlContent.attributes.src.split("/").pop().split(".").length>1){
				xmlContent.attributes.src = cleanPath(this.path + "/" + xmlContent.attributes.src);
			}
			*/
			
			copyAttribs(obj, xmlContent);
			
			obj['type'] = type;
			obj['xml'] = xmlContent;
			
			switch (obj['type']){
				case "html":
				case "xml":				
				case "head":
				case "body":
				case "div":
					obj['children'] = new Array();
					var _parsedChild:Object;
					if (xmlContent.childNodes.length != 0) 
						for (var i:uint = 0; i<xmlContent.childNodes.length; i++) {
							_parsedChild = parseData(xmlContent.childNodes[i]);
							if (_parsedChild != null) obj['children'].push(_parsedChild);
						}
					else
						if (xmlContent.nodeValue != null) {
							_parsedChild = parseData(textNode(xmlContent.nodeValue));
							// support null returns
							if (_parsedChild != null) obj['children'].push(_parsedChild);
						}
					break;
					
				case "link":
					obj['type'] = 'styles';
					break;
					
				case "style":
					obj['type'] = 'styleblock';
					obj['children'] = xmlContent.childNodes.toString();
					break;
					
				case "script":
					obj['children'] = textNode(xmlContent.nodeValue).toString();
					break;
					
				case "title":
				case "meta":
					obj['type'] = 'definition';
					break;
					
				case "img":
				case "input":			
				case "swf":
					var _srcList:Array = obj['src'].split("/").pop().split(".");
					if (_srcList.length>1) {
						var _ext:String = _srcList[_srcList.length-1];
						// Support for other extensions 
						if (_ext != 'jpg' && _ext != 'gif' && _ext != 'png') obj['type'] = _ext;
						else obj['type'] = 'image'; // this includes swf
					}  else {
						obj['type'] = 'movieclip';
					}
					obj['children'] = xmlContent;
					break;
					
				case "table":
					if (xmlContent.childNodes.length > 0){						
						var rows:Array = xmlContent.childNodes;
						var dataObj:Object = parseTable(rows);
						obj['maxcells'] = dataObj.mc;
						obj['placement'] = dataObj.pt;
						obj['heightarray'] = dataObj.ht;
						obj['widtharray'] = dataObj.wt;
						
						var totalW:Number = Math.max(replaceNull(obj['width']), replaceNull(obj['widtharray'].cells[obj['widtharray'].Count-1].AbsolutePos));
						if (totalW == 0 || isNaN(totalW)) totalW = obj['placement'][0].length * 20;
						obj['widtharray'] = obj['widtharray'].parseCells(totalW);
						
						var totalH:Number = Math.max(replaceNull(obj['height']), replaceNull(obj['heightarray'].cells[obj['heightarray'].Count-1].AbsolutePos));
						if (totalH == 0 || isNaN(totalH)) totalH = obj['placement'].length * 20;
						obj['heightarray'] = obj['heightarray'].parseCells(totalH);
						
						if (obj['cellspacing'] == undefined) obj['cellspacing'] = 0;
						if (obj['cellpadding'] == undefined) obj['cellpadding'] = 0;
						
						obj['children'] = new Array();
						obj['rows'] = new Array();
						
						for(i = 0; i<rows.length; i++) {							
							
							var cnt:Number = 0;
							var newRow:Object = new Object();
							
							copyAttribs(newRow, rows[i]);
							newRow['type'] = 'row';
							newRow['cells'] = new Array();
							
							var cells:Array = rows[i].childNodes;
							
							for(j  = 0; j<obj['maxcells']; j++){
								if (cnt < cells.length) 	{
									if (obj['placement'] != null && obj['placement'][i] != null && obj['placement'][i][j] != null && Number(obj['placement'][i][j]) != 0)	{
										var newCell:Object = new Object();
										
										copyAttribs(newCell, cells[j]);
										newCell['type'] = 'cell';
										newCell['children'] = new Array();
										
										if (cells[cnt].hasChildNodes)			
											for (var f:uint=0; f<cells[cnt].childNodes.length; f++)
												newCell['children'].push(parseData(cells[cnt].childNodes[f]));
										else newCell['children'].push(parseData(textNode(cells[cnt])));
	
										copyAttribs(newCell, cells[cnt]);
										newRow['cells'].push(newCell);
										cnt++;
									} 
									else newRow['cells'].push(null);
								} 
								else newRow['cells'].push({children: null, type: null, colspan: null, rowspan: null, height: null, width: null, bordercolor: null, bgcolor: null, align: null, embedfont: null});
							}
							obj['rows'].push(newRow);
						}
						
						
					}
					else obj['children'] = parseData(textNode(xmlContent.toString()));
					break;
					
				default:
					if (obj['type'] != 'td' && obj['type'] != 'tr'){
						if (obj['type'] == 'a' || obj['type'] == 'font' || obj['type'] == 'p' || obj['type'] == 'span' || (obj['type'] == undefined && xmlContent.toString() != ""))		{
							obj['type'] = 'text';
							obj['children'] = textNode(String(xmlContent));
						}
						else{
							obj['children'] = new Array();
							if (xmlContent.childNodes.length > 0)
								for (var j:uint=0; j<xmlContent.childNodes.length; j++)
									obj['children'].push(parseData(xmlContent.childNodes[j]));
							else
								if (xmlContent.nodeValue != null && xmlContent.nodeValue != "")
									obj['children'].push(parseData(textNode(xmlContent.nodeValue.toString())));
						}
					}
					break;
			}			
					
			return obj;	
		}
		
		//////////////////////////////////////////////////////////////////////
		// Takes care of setting attributes and inheritence of table rows and cells
		private function parseTable(rows:Array):Object	{		
			var _pt:Array = new Array();
			var _ht = new CellManager();
			var _wt = new CellManager();
			var _tht:Array = new Array();
			var _twt:Array = new Array();
			var rowsCnt:Number = 0;
			var colsCnt:Number = 0;
			
			// cleaning up rows and cells
			var i:uint = 0;
			var j:uint = 0;
	
	
			// cleaning up table XML
			for (i = 0; i<rows.length; i++) {
				removeNullFromXML(rows[i].childNodes);
					for (j = 0; j < rows[i].childNodes.length; j++) {
						removeNullFromXML(rows[i].childNodes[j].childNodes);
					}
			}
			
			
			for (i=0; i<rows.length; i++)
				if (rows[i].nodeName.toLowerCase() == "tr")
					_pt[rowsCnt++] = new Array();
			_ht.addCells(rowsCnt);
			rowsCnt = 0;
			_wt.addCells(getMaxCols(rows));
			for (i=0; i<rows.length; i++)
				if (rows[i].nodeName.toLowerCase() == "tr")			{
					colsCnt = 0;
					for (j=0; j<rows[i].childNodes.length; j++)
						if (rows[i].childNodes[j].nodeName.toLowerCase() == "td")					{
							colsCnt = this.getCol(rowsCnt, _pt);				
							var hasColspan:Number = 0;
							if (!isNaN(Number(rows[i].childNodes[j].attributes['rowspan'])))						{
								_pt[rowsCnt][colsCnt] = 1;
								addCellSize(_tht, rowsCnt, rowsCnt+(Number(rows[i].childNodes[j].attributes['rowspan']-1)), Number(rows[i].childNodes[j].attributes['height']));
								_ht.setSpan(rowsCnt, Number(rows[i].childNodes[j].attributes['rowspan']), Number(rows[i].childNodes[j].attributes['height']));
								for (var x=0; x<Number(rows[i].childNodes[j].attributes['rowspan']); x++)
									if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])) || hasColspan > 0)								{
										_pt[rowsCnt][colsCnt] = 1;
										addCellSize(_twt, colsCnt, colsCnt+(Number(rows[i].childNodes[j].attributes['colspan']-1)), Number(rows[i].childNodes[j].attributes['width']));
										_wt.setSpan(colsCnt, Number(rows[i].childNodes[j].attributes['colspan']), Number(rows[i].childNodes[j].attributes['width']));
										if (x == 0 && rows[i].childNodes[j].attributes['colspan'] != undefined)									{
											hasColspan = Number(rows[i].childNodes[j].attributes['colspan']);
										}
										for (var y=0; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
											if (x!=0&&y!=0)
												_pt[rowsCnt+x][colsCnt+y] = 0;
									}
									else	{
										if (x!=0)
											_pt[rowsCnt+x][colsCnt] = 0;
										_wt.setSpan(colsCnt, 1, Number(rows[i].childNodes[j].attributes['width']));
									}
								hasColspan = 0;
							}
							else if (!isNaN(rows[i].childNodes[j].attributes['colspan']))						{
								addCellSize(_tht, rowsCnt, rowsCnt+1, Number(rows[i].childNodes[j].attributes['height']));
								addCellSize(_tht, rowsCnt, rowsCnt+1, Number(rows[i].attributes['height']));
								addCellSize(_twt, colsCnt, colsCnt+(Number(rows[i].childNodes[j].attributes['colspan']-1)), Number(rows[i].childNodes[j].attributes['width']));
								_ht.setSpan(rowsCnt, 1, Number(rows[i].childNodes[j].attributes['height']));
								_ht.setSpan(rowsCnt, 1, Number(rows[i].attributes['height']));
								_wt.setSpan(colsCnt, Number(rows[i].childNodes[j].attributes['colspan']), Number(rows[i].childNodes[j].attributes['width']));
								_pt[rowsCnt][colsCnt] = 1;
								for (y=0; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
									if (y!=0)
									_pt[rowsCnt][colsCnt+y] = 0;
							}
							else		{
								addCellSize(_tht, rowsCnt, rowsCnt+1, Number(rows[i].childNodes[j].attributes['height']));
								addCellSize(_tht, rowsCnt, rowsCnt+1, Number(rows[i].attributes['height']));
								addCellSize(_twt, colsCnt, colsCnt+1, Number(rows[i].childNodes[j].attributes['width']));
								_ht.setSpan(rowsCnt, 1, Number(rows[i].childNodes[j].attributes['height']));
								_ht.setSpan(rowsCnt, 1, Number(rows[i].attributes['height']));
								_wt.setSpan(colsCnt, 1, Number(rows[i].childNodes[j].attributes['width']));
								_pt[rowsCnt][colsCnt] = 1;
							}
						}
					rowsCnt++
				}
			if (!isNaN(_wt.cells[_wt.Count-1].AbsolutePos))
				if (_wt.cells[_wt.Count-1].AbsolutePos < getLastArrayValue(_twt, _twt.length-1))
					_wt.cells[_wt.Count-1].AbsolutePos = getLastArrayValue(_twt, _twt.length-1);
					
			if (!isNaN(_ht.cells[_ht.Count-1].AbsolutePos))
				if (_ht.cells[_ht.Count-1].AbsolutePos < getLastArrayValue(_tht, _tht.length-1))
					_ht.cells[_ht.Count-1].AbsolutePos = getLastArrayValue(_tht, _tht.length-1);
			//this.tracePlaceTable(_pt);
			return {mc:_pt[0].length, pt:_pt, ht:_ht, wt:_wt};
		}
			
		
		private function getMaxCols(rows:Array):Number{
			
			var arr:Array = new Array();
			
			var tmpTotal:Number = 0;
			
			var col:Number = 0;
			var row:Number = 0;
			var i:uint = 0;
	
			
			for (i = 0; i<rows.length; i++)
				if (rows[i].nodeName != null && rows[i].nodeName.toLowerCase() == "tr")
					arr[row++] = new Array();
			
			row = 0;
			
			for (i = 0; i<rows.length; i++)
				if (rows[i].nodeName != null && rows[i].nodeName.toLowerCase() == "tr") {
					for (var j:uint = 0; j<rows[i].childNodes.length; j++)
						if (rows[i].childNodes[j].nodeName != null && rows[i].childNodes[j].nodeName.toLowerCase() == "td"){
							col = this.getCol(row, arr);
							arr[row][col] = 1;
							if (!isNaN(Number(rows[i].childNodes[j].attributes['rowspan'])))
								for (var x:uint = 1; x<Number(rows[i].childNodes[j].attributes['rowspan']); x++)
									if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
										for (var y:uint = 1; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
											arr[row+x][col+y] = 1;
									else
										arr[row+x][col] = 1;
							else if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
								if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
									for (y = 1; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
										arr[row][col+y] = 1;
						}
					if (tmpTotal < arr[row].length) tmpTotal = arr[row].length;
					row++;
				}
			//this.tracePlaceTable(arr);
			return tmpTotal;
		}
		
		private function getCol(pos:Number, _pt:Array):Number	{
			for (var i:uint = 0; i<_pt[pos].length; i++)
				if (isNaN(_pt[pos][i]))
					return i;
			return _pt[pos].length;
		}
		
		private function addCellSize(arr:Array, newloc:Number, loc:Number, amt:Number):*	{
			if (!isNaN(amt))		{
				var tmp:Number = replaceNull(getLastArrayValue(arr, newloc-1));
				if (replaceNull(arr[loc]) == (amt+tmp)) return null;
				arr[loc] = amt;
				for (var i:uint = loc; i<arr.length; i++)
					if ((amt+replaceNull(tmp)) > arr[i] && arr[i] != null)
						arr[i] = (amt+replaceNull(tmp));
			}
		}
		
		private function getLastArrayValue(arr:Array, loc:Number):Number{
			for (var i:Number = loc; i>=0; i--)		{
				if (!isNaN(Number(arr[i])))
					return arr[i];
			}
			return 0;
		}
		
		private function copyAttribs(obj:Object, node:XMLNode):void	{
			if (node == null) return;
			for (var i:String in node.attributes)
				obj[i] = node.attributes[i];
		}		
		
		public function cleanPath(path:String):String {
		
			if (path.substr(0,1) == "/") path = path.substr(1);
		
			var pathArray:Array = path.split("/");
			var filename:String = pathArray.pop() as String;
			path = pathArray.join("/") + "/";
			pathArray = path.split("/..");
			
			var i:uint = 0;
			while (i < pathArray.length) {
				var curPath:Array = pathArray[i].split("/");
				curPath.pop();
				pathArray[i] = curPath.join("/");
				i = i + 2;
			}
			
			path = pathArray.join("/") + "/" + filename;
			
			if (path.substr(0,1) == "/") path = path.substr(1);
			
			return path;
			
		}
		
		private function textNode(val:String):XMLNode{
			return new XMLDocument("<span>" + val + "</span>").childNodes[0];
		}
		
		private function replaceNull(val:Object):Number	{
			if (!isNaN(Number(val)))
				return Number(val);
			else
				return 0;
		}
		
		public function fromString(str:String):void	{
			var xml:XMLDocument = new XMLDocument();
			xml.ignoreWhite = true;
			xml.parseXML(str);
			buildPage(xml);
		}
		
		public function buildPage(xml:XMLDocument):void	{
			removeNullFromXML(xml.childNodes);
			for (var i:uint = 0; i<xml.childNodes.length; i++)		{
				tableData = parseData(xml.childNodes[i] as XMLNode);
			}
			dispatchEvent(new FMLEvent(FMLEvent.PARSED));
		}
		
		public function getPage(path:String, src:String):void{
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, getPageComplete,false,0,true);		
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, getPageFailed,false,0,true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, getPageFailed,false,0,true);
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		
			if (path != null)
				this.path = path;
			else 
				this.path = "";
			
			if (DesignrealmSystem.getVariable("IS_ENCRYPTED"))
				src = Validation.getEncryptedFilename(src);
			
			if ( path != "" )
				urlLoader.load(new URLRequest(path  + src));
			else
				urlLoader.load(new URLRequest(src));
		}
		
		
		private function getPageComplete(e:Event):void	{
			e.target.removeEventListener(Event.COMPLETE, getPageComplete);		
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, getPageFailed);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, getPageFailed);		
			dispatchEvent(new FMLEvent(FMLEvent.LOAD_SUCCESS));
			var _data:ByteArray = e.target.data;
			var data:String;
			if (DesignrealmSystem.getVariable("IS_ENCRYPTED")) {
				data = Validation.decrypt(_data);
			}
			else {
				data = _data.toString();
			}			
			
			var dataXML:XMLDocument;
			try {
				 dataXML = new XMLDocument(data);
			}
			catch(e) {
				trace("Parser: Problem parsing data: " + data);
			}
			this.buildPage(new XMLDocument(data));
		}
		
		private function getPageFailed(e:*):void	{
			e.target.removeEventListener(Event.COMPLETE, getPageComplete);		
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, getPageFailed);		
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, getPageFailed);		
			trace("FlashML Parser: error = " + e.text);
			var _event:FMLEvent = new FMLEvent(FMLEvent.LOAD_FAILED);
			_event.text = e.text;
			dispatchEvent(_event);
		}		

		
		private function removeNullFromXML(xml:Array) {
			var i:uint = 0;
			if (xml == null) return;

			while (i < xml.length) {
				if (xml[i].nodeName == null && (!(reNonSpace.test(xml[i].nodeValue)) || xml[i].nodeValue == null || xml[i].nodeValue.length == 0)) {
					xml.splice(i,1);
				}
				else {
					++i;
				}
			}
		}
		
		
		
	}
	
}