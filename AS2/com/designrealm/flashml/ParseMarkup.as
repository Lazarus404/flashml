import mx.events.EventDispatcher;
import com.designrealm.flashml.CellManager;

class com.designrealm.flashml.ParseMarkup
{
	
	private var path;
	public var tags;
	
	public var dispatchEvent : Function;
	
	// added function getPath
	
	/////////////////////////////////////////////////////////////////
	public function ParseMarkup(Void)    {
        EventDispatcher.initialize(this);
		this.tags = new Array;
    }
	
	
	
	////////////////////////////////////////////////////////////////////////////////////	
	////////////////////////////////////////////////////////////////////////////////////
	//                       The heart of this engine
	////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////
	
	public function parseData(xmlContent:XMLNode):Object	{
		
		var type = xmlContent.nodeName.toLowerCase();

		// Custom parsers
		if (tags[type]) {
			// Getting the string from the external pre-parser
			var parserResult = tags[type].apply(null,[xmlContent]);
			
			if (!parserResult) return null; // some tags are only directives to the parent engine
			
			if (parserResult instanceof XML || parserResult instanceof XMLNode) {
				xmlContent = parserResult;
			} else {
				// Parsing the received string into XML
				var xml = new XML;
				xml.parseXML(parserResult);
				xmlContent = xml.childNodes[0]; // need to go down one level
			} 
			
			// re-assigning the type as per the received XML string (in case it changed);
			type = xmlContent.nodeName.toLowerCase();
		}
		
		var obj:Object = new Object();	

		
		// Adding path to any src=* attributes
		if (xmlContent.attributes.src && xmlContent.attributes.src.split("/").pop().split(".").length>1) {
			xmlContent.attributes.src = cleanPath(this.path + "/" + xmlContent.attributes.src);
		}
		
		copyAttribs(obj, xmlContent);
		
		obj['type'] = type;
		obj['xml'] = xmlContent;
		
		switch (obj['type'])		{
			case "html":
			case "head":
			case "body":
			case "div":
				obj['content'] = new Array();
				var _parsedChild;
				if (xmlContent.hasChildNodes())
					for (var i=0; i<xmlContent.childNodes.length; i++) {
						_parsedChild = parseData(xmlContent.childNodes[i]);
						// support null returns						
						if (_parsedChild) obj['content'].push(_parsedChild);
					}
				else
					if (xmlContent.nodeValue != undefined) {
						_parsedChild = parseData(textNode(xmlContent.nodeValue));
						// support null returns
						if (_parsedChild) obj['content'].push(_parsedChild);
					}
				break;
			case "link":
				obj['type'] = 'styles';
				break;
			case "style":
				obj['type'] = 'styleblock';
				obj['content'] = String(xmlContent.childNodes);
				break;
			case "script":
				obj['content'] = String(textNode(xmlContent.nodeValue));
				break;
			case "title":
			case "meta":
				obj['type'] = 'definition';
				break;
			case "img":
				// 1) For custom renderes (e.g. svg), if the extension is unknown by FlashML, make it into the actual tag (e.g. <svg>) otherwise it stays <image>
				// 2) Separate movieclips that are internal to the current movie / program for separate rendering by FlashML, new tag <movieclip>
				// 3) New tag <swf> automatically extracted
				var _srcList = obj['src'].split("/").pop().split(".");
				if (_srcList.length>1) {
					var _ext = _srcList[_srcList.length-1].toLowerCase();
					// Support for other extensions 
					if (_ext != 'jpg' && _ext != 'gif' && _ext != 'png') obj['type'] = _ext;
					else obj['type'] = 'image'; // this includes swf
				}  else {
					obj['type'] = 'movieclip';
				}
				obj['content'] = xmlContent;
				break;
			case "input":
				break;
			case "table":
				if (xmlContent.hasChildNodes())			{
					
					var rows:Array = xmlContent.childNodes;
					var dataObj:Object = setUtils(rows);
					obj['maxcells'] = dataObj.mc;
					obj['placement'] = dataObj.pt;
					obj['heightarray'] = dataObj.ht;
					obj['widtharray'] = dataObj.wt;
					
					var totalW:Number = Math.max(replaceNull(obj['width']), replaceNull(obj['widtharray'].__Cells[obj['widtharray'].Count-1].AbsolutePos));
					if (totalW == 0 || isNaN(totalW)) totalW = obj['placement'][0].length * 20;
					obj['widtharray'] = obj['widtharray'].parseCells(totalW);
					
					var totalH:Number = Math.max(replaceNull(obj['height']), replaceNull(obj['heightarray'].__Cells[obj['heightarray'].Count-1].AbsolutePos));
					if (totalH == 0 || isNaN(totalH)) totalH = obj['placement'].length * 20;
					obj['heightarray'] = obj['heightarray'].parseCells(totalH);
					
					if (obj['cellspacing'] == undefined) obj['cellspacing'] = 0;
					if (obj['cellpadding'] == undefined) obj['cellpadding'] = 0;
					
					obj['content'] = new Array();
					obj['rows'] = new Array();
					
					for(var x=0; x<rows.length; x++) 		{
						
						var cnt:Number = 0;
						var newRow:Object = new Object();
						
						copyAttribs(newRow, rows[x]);
						newRow['type'] = 'row';
						newRow['cells'] = new Array();
						var cells:Array = rows[x].childNodes;
						for(var y=0; y<obj['maxcells']; y++)		{
							if (cnt < cells.length) 	{
								if (Number(obj['placement'][x][y]) != 0)	{
									var newCell:Object = new Object();
									
									copyAttribs(newCell, cells[y]);
									newCell['type'] = 'cell';
									newCell['content'] = new Array();
									
									if (cells[cnt].hasChildNodes())			{
										for (var f=0; f<cells[cnt].childNodes.length; f++)
											newCell['content'].push(parseData(cells[cnt].childNodes[f]));

									} 	else newCell['content'].push(parseData(textNode(cells[cnt])));

									copyAttribs(newCell, cells[cnt]);
									newRow['cells'][y] = newCell;
									cnt++;
								} 
								else newRow['cells'][y] = null;
							} 
							else newRow['cells'].push({content: null, type: null, colspan: null, rowspan: null, height: null, width: null, bordercolor: null, bgcolor: null, align: null, embedfont: null});
						}
						obj['rows'].push(newRow);
					}
					
					
				}
				else obj['content'] = parseData(textNode(xmlContent.toString()));
					
				break;
			default:
				if (obj['type'] != 'td' && obj['type'] != 'tr')	{
					if ((obj['type'] == 'a' || obj['type'] == 'font' || obj['type'] == 'span' || obj['type'] == null) && xmlContent.toString() != "")		{
						obj['type'] = 'text';
						obj['content'] = textNode(String(xmlContent));
					}
					else		{
						obj['content'] = new Array();
						if (xmlContent.hasChildNodes())
							for (var i=0; i<xmlContent.childNodes.length; i++)
								obj['content'].push(parseData(xmlContent.childNodes[i]));
						else
							if (xmlContent.nodeValue != undefined && xmlContent.nodeValue != "")
								obj['content'].push(parseData(textNode(xmlContent.nodeValue.toString())));
					}
				}
				break;
		}
		return obj;
	}
	
	private function textNode(val:String):XML	{
		return new XML("<span>" + val + "</span>");
	}
	
	private function copyAttribs(obj, node)	{
		for (var i:String in node.attributes)
			obj[i.toLowerCase()] = node.attributes[i];
	}
/*
	public function tracePlaceTable(_pt:Array):Void
	{
		var tmp = this;
		for (var i=0; i<_pt.length; i++)
		{
			var str:String = "";
			for (var j=0; j<_pt[i].length; j++)
			{
				str = str + ' ' + _pt[i][j].toString();
			}
			trace(str);
		}
	}
*/

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	//// Table processing functions
	//////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////	
	
	

	//////////////////////////////////////////////////////////////////////
	// Takes core of setting attributes and inheritence of table rows and cells
	private function setUtils(rows:Array):Object	{		
		var _pt:Array = new Array();
		var _ht = new CellManager();
		var _wt = new CellManager();
		var _tht:Array = new Array();
		var _twt:Array = new Array();
		var rowsCnt:Number = 0;
		var colsCnt:Number = 0;
		for (var i=0; i<rows.length; i++)
			if (rows[i].nodeName.toLowerCase() == "tr")
				_pt[rowsCnt++] = new Array();
		_ht.addCells(rowsCnt);
		rowsCnt = 0;
		_wt.addCells(getMaxCols(rows));
		for (var i=0; i<rows.length; i++)
			if (rows[i].nodeName.toLowerCase() == "tr")			{
				colsCnt = 0;
				for (var j=0; j<rows[i].childNodes.length; j++)
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
							for (var y=0; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
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
		if (!isNaN(_wt.__Cells[_wt.Count-1].AbsolutePos))
			if (_wt.__Cells[_wt.Count-1].AbsolutePos < getLastArrayValue(_twt, _twt.length-1))
				_wt.__Cells[_wt.Count-1].AbsolutePos = getLastArrayValue(_twt, _twt.length-1);
		if (!isNaN(_ht.__Cells[_ht.Count-1].AbsolutePos))
			if (_ht.__Cells[_ht.Count-1].AbsolutePos < getLastArrayValue(_tht, _tht.length-1))
				_ht.__Cells[_ht.Count-1].AbsolutePos = getLastArrayValue(_tht, _tht.length-1);
		//this.tracePlaceTable(_pt);
		return {mc:_pt[0].length, pt:_pt, ht:_ht, wt:_wt};
	}
	
	
	
	private function getCol(pos:Number, _pt:Array):Number	{
		for (var i=0; i<_pt[pos].length; i++)
			if (isNaN(_pt[pos][i]))
				return i;
		return _pt[pos].length;
	}
	
	
	private function getMaxCols(rows:Array):Number	{
		var arr:Array = new Array();
		var tmpTotal:Number = 0;
		var col:Number = 0;
		var row:Number = 0;
		for (var i=0; i<rows.length; i++)
			if (rows[i].nodeName.toLowerCase() == "tr")
				arr[row++] = new Array();
		row = 0;
		for (var i=0; i<rows.length; i++)
			if (rows[i].nodeName.toLowerCase() == "tr")			{
				for (var j=0; j<rows[i].childNodes.length; j++)
					if (rows[i].childNodes[j].nodeName.toLowerCase() == "td")					{
						col = this.getCol(row, arr);
						arr[row][col] = 1;
						if (!isNaN(Number(rows[i].childNodes[j].attributes['rowspan'])))
							for (var x=1; x<Number(rows[i].childNodes[j].attributes['rowspan']); x++)
								if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
									for (var y=1; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
										arr[row+x][col+y] = 1;
								else
									arr[row+x][col] = 1;
						else if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
							if (!isNaN(Number(rows[i].childNodes[j].attributes['colspan'])))
								for (var y=1; y<Number(rows[i].childNodes[j].attributes['colspan']); y++)
									arr[row][col+y] = 1;
					}
				if (tmpTotal < arr[row].length) tmpTotal = arr[row].length;
				row++;
			}
		//this.tracePlaceTable(arr);
		return tmpTotal;
	}
	
	
	private function addCellSize(arr:Array, newloc:Number, loc:Number, amt:Number)	{
		if (!isNaN(amt))		{
			var tmp:Number = replaceNull(getLastArrayValue(arr, newloc-1));
			if (replaceNull(arr[loc]) == (amt+tmp)) return null;
			arr[loc] = amt;
			for (var i=loc; i<arr.length; i++)
				if ((amt+replaceNull(tmp)) > arr[i] && arr[i] != null)
					arr[i] = (amt+replaceNull(tmp));
		}
	}
	
	
	private function getLastArrayValue(arr:Array, loc:Number)	{
		for (var i=loc; i>=0; i--)		{
			if (!isNaN(arr[i]))
				return arr[i];
		}
		return 0;
	}
	
	private function replaceNull(val:Object):Number	{
		if (!isNaN(val))
			return Number(val);
		else
			return 0;
	}
	
	
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// Functions called from outside to initiate parsing 
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	
	public function buildPage(xml:XML)	{
		var tableData:Object = new Object;
		for (var i=0; i<xml.childNodes.length; i++)		{
			tableData = parseData(xml.childNodes[i]);
		}
		this.dispatchEvent({type:"onDataParsed", target:tableData});
	}
	
	public function getPage(path,src):Void	{
		var obj:XML = new XML();
		
		if (path) this.path = path;
		else this.path = "";
		
		obj.ignoreWhite = true;
		obj['scope'] = this; // Need to force it to avoid error, 'scope' not part of XML prototype
		obj.onLoad = function(success)		{
			if (success)			{
				this.scope.dispatchEvent({type:"loaded", target:this.scope});
				this.scope.buildPage(this);
			}
			else
				this.scope.dispatchEvent({type:"failed", target:this.scope});
		}
		if ( path != "" )
			obj.load(path + "/" + src);
		else
			obj.load(path + src);
	}
	
	public function fromString(str:String)	{
		var xml:XML = new XML()
		xml.ignoreWhite = true;
		xml.parseXML(str);
		this.buildPage(xml);
	}
	
	
	
	function cleanPath(path) {
		
			while (path.indexOf("//")>-1) path = path.split("//").join("/");		
			if (path.substr(0,1) == "/") path = path.substr(1);

		
			var pathArray = path.split("/");
			var filename = pathArray.pop();
			path = pathArray.join("/") + "/";
			pathArray = path.split("/..");
			
			var i = 0;
			while (i < pathArray.length) {
				var curPath = pathArray[i].split("/");
				curPath.pop();
				pathArray[i] = curPath.join("/");
				i = i + 2;
			}
			path = pathArray.join("/") + "/" + filename;
			while (path.indexOf("//")>-1) path = path.split("//").join("/");		
			if (path.substr(0,1) == "/") path = path.substr(1);

			
			return path;
			
		}
	
	
}