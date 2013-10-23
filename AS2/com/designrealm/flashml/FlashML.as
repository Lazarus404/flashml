import mx.events.EventDispatcher;
import com.designrealm.flashml.ParseMarkup;

class com.designrealm.flashml.FlashML extends MovieClip
{
	public static var className : String = "com.designrealm.flashml.FlashML";
	public static var register : Boolean = registerClass( className, FlashML );
	static private var _timeOut = 2;
	private var _textfields:Number = 0;
	public var _monitorHistory = false;
	public var _spacing:Number = 5;
	public var _selectable = false;
	public var _hasStyles:Boolean = false;	
	public var _objectsHistory;
	private var _listenersHistory;
	private var _id; // for setInterval
	
	public var page:MovieClip;
	public var styles:TextField.StyleSheet;
	public var renderer;
	public var src, path;
	public var objects;
	
	public var dispatchEvent : Function;

	private var tags
	private var functions;

	private var parser;
	private var parserListener;
	
	

	public function FlashML()    {
        EventDispatcher.initialize(this);
		parser = new ParseMarkup();
		
		parserListener = new Object();
		parserListener.scope = this;
		parserListener.loaded = function(evt) {
			this.scope.dispatchEvent({type:"loaded", target:this.scope});
		}
		parserListener.failed = function(evt) {
			this.scope.dispatchEvent({type:"failed", target:this.scope});
		}
		parser.addEventListener("loaded", parserListener);
		parser.addEventListener("failed", parserListener);
		
		objects = new Object();
		tags = new Object();
		functions = new Object();
		_objectsHistory = new Array();
		_listenersHistory = new Array();
		
		clearTable();
		
    }
	
	public function setPage(str) {
		if (str) page = objects[str];
	}
	
  	public function clearTable(Void):Void {
		clearClip( page );
		if ( ! page )
			page = createEmptyClip( "page", "page", this, 0, false );
    }
	
	public function clearClip(mc) {
		while( mc.mc_array.length > 0 )
		{
			var item = mc.mc_array.pop();
			item.clear();
			item.removeMovieClip();
			item.unloadMovie();
			delete item;
		}
		while( mc.txt_array.length > 0 )
		{
			var item = mc.txt_array.pop();
			item.removeTextField();
			item.unloadMovie();
			delete item;
		}
	}
	
	private function buildPage(content):Void 	{
		// Passing the current page width and height as params to the builder
		buildClip(content, page, 0, page._width, page._height);
		if (this._id) clearInterval(this._id);
		this._id = setInterval(this,"clearListeners",_timeOut*1000, [getTimer()]);
		this.dispatchEvent({type:"done", target:this});
	}
	
	private function createEmptyClip(vid:String, vtype:String, target:MovieClip, depth:Number, dontAdd):MovieClip 	{
		var id:String = (vid != undefined) ? vid : (vtype != undefined) ? vtype + (depth+1) : "obj" + (depth+1);
		var mc = target.createEmptyMovieClip(id, depth+1);
		mc.mc_array = new Array();
		mc.txt_array = new Array();
		if (vid != undefined && vtype != undefined && !dontAdd) addObject(vid, mc);
		target.mc_array.push( mc );
		return mc;
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////	
	///////////////////////////////////////////////////////////////////////////////////////////////

	private function addToListeners(obj) {
		_listenersHistory.push({time:getTimer(), obj:obj});
		return;
	}

	
	// From beginning to end	
	function clearListeners(time) {
		
		clearInterval(this._id);
		
		if (time == undefined) time = getTimer();
		var _str = "FlashML - Clearing listeners: Before = " + _listenersHistory.length;
		while ((_listenersHistory.length>0) && (_listenersHistory[0].time <= time)) {
			_listenersHistory[0].obj.removeMovieClip();
			_listenersHistory[0].obj.removeTextField();
			delete _listenersHistory[0].obj; // for remaining objects
			_listenersHistory.splice(0,1);
		} 
		
		_str += "  After = " + _listenersHistory.length;
		trace(_str);
		return;
	}
	
	public function toString()
	{
		return "FlashML";
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////	
	///////////////////////////////////////////////////////////////////////////////////////////////	
	
	public function addObject(id:String, mc:MovieClip)	{
		objects[ String( id ) ] = MovieClip( mc );
	}
	

	public function addEvents(eventStr:String, mc:MovieClip)	{
		if (eventStr != undefined && eventStr != "") {
			var evArr:Array = eventStr.split(';');
			for (var i=0; i<evArr.length; i++)	{
				var evItems:Array = evArr[i].split(':');
				var funArr:Array = ((evItems.length > 1) ? evItems[1] : evItems[0]).split(',');
				var funcName:String = funArr[0];
				var event:String = evItems[0];
				var funParam:Array = (funArr.length > 1) ? funArr.slice(1) : null;
				
				// creating event object within mc
				mc[event] = new Object;
				mc[event].scope = this;
				mc[event][event] = function() 	{
					this.scope.functions[this.funcName].apply(null,this.params);
				}
				mc[event].funcName = funcName; 
				mc[event].params = parseParams(funParam);
				mc.addEventListener(event, mc[event]);
			}
		}
	}
	
	
	
	private function parseParams(val:Array):Array 	{
			
		for (var j=0; j<val.length; j++)
			if (val[j].substr(0,1) == "[" && val[j].substr(val[j].length-1,1) == "]")	{
				var obj = val[j].substr(1,val[j].length-2);
				if (this.objects[obj]!= undefined) val[j] = this.objects[obj];
			}
		return val;
	}
	
	
	
	private function buildClip(obj:Object, clip:MovieClip, depth:Number, parentWidth:Number, parentHeight:Number) 	{

		var mc : MovieClip;
		var type = obj['type'].toLowerCase();
		
		var pw:Number = 300;
		if (!isNaN(parentWidth)) pw = parentWidth;
		var ph:Number = 100;
		if (!isNaN(parentHeight)) ph = parentHeight;
		
		for ( var f in this.functions )
			clip[f] = this.functions[f];
		
		
		switch (type) 		{ // pre-child construction

			case "html":
			case "head":
			case "div":
				var parent:MovieClip = (obj['position'].toLowerCase() == 'absolute') ? this.page : clip;
				var h:Number = getHeight(parent);				
				trace( parent );
				var div = createEmptyClip("div", type , parent, parent.getNextHighestDepth(),true);
				trace( div );
				var bg = createEmptyClip("bg", type, div, 0,true);
				mc = createEmptyClip(obj['id'], type, div, 1);
				copyParams(mc, clip);
				copyParams(mc, obj);
				div._y = (!isNaN(Number(mc['top']))) ? Number(mc['top']) : h;
				div._x = (!isNaN(Number(mc['left']))) ? Number(mc['left']) : 0;
				var w:Number = (!isNaN(Number(mc['width']))) ? Number(mc['width']) : 300;
				for (var i=0; i<obj['content'].length; i++)
				{
					buildClip(obj['content'][i], mc, i, w);
				}
				var h:Number = (!isNaN(Number(obj['height']))) ? obj['height'] : mc._height;
				var w:Number = (!isNaN(Number(obj['width']))) ? obj['height'] : mc._width;
				this.paint(bg, 0, 0, w, h, (!isNaN(Number(obj['border']))) ? 1 : 0, Number(replace(obj['bordercolor'], "#", "0x")), Number(replace(obj['bgcolor'], "#", "0x")), obj);
				mc = (parent == this.page) ? clip : div;
				break;
				
			////////////////////////////////////////////////////////////////////////////
			case "body":
				clip['embedfont'] = obj['embedfont'];
				if (obj['content'].length != undefined)
				var h:Number = 0;
				for (var i=0; i<obj['content'].length; i++)
				{
					var innerClip = buildClip(obj['content'][i], clip, i, parentWidth, parentHeight);
					trace( "/t" + innerClip );
					// innerClip._y = h;
					h = getHeight(clip);
				}
				break;
				
			////////////////////////////////////////////////////////////////////////////				
			case "styles":
				if (obj['href'] != undefined) setStyles(obj['href']);
				break;
				
			////////////////////////////////////////////////////////////////////////////				
			case "styleblock":
				setStyleBlock(obj['content']);			
				break;
				
			////////////////////////////////////////////////////////////////////////////				
			case "definition":
			case "script":
				break;
				
			////////////////////////////////////////////////////////////////////////////				
			// Handling events
			case "input":
				if (obj['src'] != undefined)	{
					var h:Number = getHeight(clip);
					var vid = (obj['id'] != undefined) ? obj['id'] : (obj['name'] != undefined) ? obj['name'] : "control" + random(9999).toString();
					var mc = clip.attachMovie(obj['src'], vid, depth, {_y:h});
					if (obj['id'] != undefined) addObject(obj['id'], mc);
					addEvents(obj['events'], mc);
					copyParams(mc, obj);
				}
				break;
				
				
			////////////////////////////////////////////////////////////////////////////
			case "text":
			
				// Searching for an existing textfield
				if (depth > 0)
					var i:Number = depth;
					while (i > -1 && clip.getInstanceAtDepth(i) == undefined) i--;
					if (clip.getInstanceAtDepth(i) instanceof TextField)	{
						clip.getInstanceAtDepth(i).htmlText += String((clip['align'].toLowerCase() == "center") ? "<p align=\'center\'>" + obj['content'] + "</p>" : (clip['align'].toLowerCase() == "right") ? "<p align=\'right\'>" + obj['content'] + "</p>" : obj['content']);
						formatText(clip, clip.getInstanceAtDepth(i));
						return clip.getInstanceAtDepth(i);
					}

				// textfield not found, create a new one
				clip.createTextField('textfield'+depth, depth, 0, 0, pw, ph);
				var mc:TextField = clip['textfield'+depth];
				clip.txt_array.push( mc );
				
				for ( var n in this.functions )
					mc[ n ] = this.functions[ n ];
				
				// Setting selectability -- in case user wants to protect content
				mc.selectable = this._selectable;
				
				var tmpXml:XML = new XML(obj['content']);
				if (tmpXml.hasChildNodes() && tmpXml.firstChild.attributes['id'] != "" && tmpXml.firstChild.attributes['id'] != null)
						addObject(tmpXml.firstChild.attributes['id'], mc);
				_textfields++;
				
				// The text properties overrule the inherited properties
				var _valign = obj["valign"] ? obj["valign"] : clip["valign"];			
				var _align = obj["align"] ? obj["align"].toLowerCase() : clip["align"].toLowerCase();
				var _embedfont = obj["embedfont"] ? obj["embedfont"] : clip["embedfont"];
				
				var tf:TextFormat = new TextFormat();
				tf.leftMargin = 1;
				
				if (_embedfont != undefined) 	{
					tf.font = String(_embedfont);
					mc.embedFonts = true;
				}
				formatText(clip, mc);
				var _txt = _align == "center" ? "<p align=\'center\'>" + obj['content'] + "</p>" : _align == "right" ? "<p align=\'right\'>" + obj['content'] + "</p>" : obj['content'];
				// trace(_txt);
				mc.htmlText = _txt; 
				mc.setTextFormat(tf);
				
				// Just for vertical alignment
				align(mc,{valign:_valign},null,ph);
				break;
				
			////////////////////////////////////////////////////////////////////////////		
			// The 'heart' of the engine	
			case "table":
				
				var counter:Number = 100;
				mc = createEmptyClip(obj['id'], type, clip, depth);
				//if (parentHeight != null) mc._y = parentHeight;
				var bg = createEmptyClip('bg', type, mc, 0,true);
				var content = createEmptyClip('content', type, mc, 1,true);
				copyParams(content, obj);
				content['cellspacing'] = Math.max(obj['cellspacing'], 0);
				content['cellpadding'] = Math.max(obj['cellpadding'], 0);
				
				// for each row
				if (obj['rows'].length != undefined) 	{
					var vtstrength = (content['border'] != undefined) ? content['border'] : 0;
					var vtborderColor = (!isNaN(Number(this.replace(content['bordercolor'], "#", "0x")))) ? Number(this.replace(content['bordercolor'], "#", "0x")) : null;
					var vtfill = (content['bgcolor'] != undefined) ? Number(this.replace(content['bgcolor'], "#", "0x")) : null;
					var borderoffset:Number = (!isNaN(Number(vtstrength))) ? Number(vtstrength) : 0;
					content._x = borderoffset + content['cellspacing'];
					content._y = borderoffset + content['cellspacing'];
					
					// Pass #1 to create items and place them horizontally
					for (var a=0; a<obj['rows'].length; a++) 		{
						
						// recursive call to build row
						obj['rows'][a]['clip'] = buildClip(obj['rows'][a], content, a);

						for (var b=0; b<obj['rows'][a]['cells'].length; b++)		{
							
							var sa = sumArray(content['widtharray'], b)
							// moving to the right by the sum of the total widthes so far
							obj['rows'][a]['cells'][b]['clip']._x = sa +(content['cellspacing']*b);
							// moving content by the amount of padding
							obj['rows'][a]['cells'][b]['clip']['content']._x = obj['rows'][a]['cells'][b]['clip']['content']._y = content['cellpadding'];
							
							
							// Calculating remaining height and width for the current row (cell?)
							var remainingH:Number = content['heightarray'][a];
							var remainingW:Number = content['widtharray'][b];
								
							// getting rowspan and colspan -- calculating height and width
							var rs:Number = obj['rows'][a]['cells'][b]['rowspan'];
							if (isNaN(rs)) rs = 1;
							for (var i=1; i<rs; i++)	remainingH += content['heightarray'][a+i] + content['cellspacing'];
							
							var cs:Number = obj['rows'][a]['cells'][b]['colspan'];
							if (isNaN(cs)) cs = 1;						
							for (var i=1; i<cs; i++)	remainingW += content['widtharray'][b+i] + content['cellspacing'];
							
							
							
							// Building inner clips - cells
							var h:Number = 0;						
							for (var c:Number = 0; c<obj['rows'][a]['cells'][b]['clip']['children'].length; c++)	{
								obj['rows'][a]['cells'][b]['clip']['children'][c]['clip'] = buildClip(obj['rows'][a]['cells'][b]['clip']['children'][c], obj['rows'][a]['cells'][b]['clip']['content'], counter++, remainingW - (content['cellpadding'] * 2), remainingH - h - (content['cellpadding'] * 2));
								h = getHeight(obj['rows'][a]['cells'][b]['clip']['content']); // getting it for next row
							}
							
							// Scaling things down
							if (h > remainingH - content['cellpadding'])		{
								var th:Number = h - (remainingH - content['cellpadding']);
								for (var p=0; p<rs; p++)content['heightarray'][a+p] += Number(th/rs);
							}
						}
					}
					
					
					
					// Pass #2 to place items vertically -- works fine
					for (var a=0; a<obj['rows'].length; a++)	{
						
						// initial vertical placement of the row
						if (a>0) obj['rows'][a]['clip']._y = (sumArray(content['heightarray'], a) + (content['cellspacing']*a));					
						
						for (var b=0; b<obj['rows'][a]['cells'].length; b++)	{
							
							var remainingH:Number = content['heightarray'][a];
							var remainingW:Number = content['widtharray'][b];
							
							// getting rowspan and colspan -- calculating height and width
							var rs:Number = obj['rows'][a]['cells'][b]['rowspan'];
							if (isNaN(rs)) rs = 1;
							for (var i=1; i<rs; i++) remainingH += content['heightarray'][a+i] + content['cellspacing'];						
							
							var cs:Number = obj['rows'][a]['cells'][b]['colspan'];
							if (isNaN(cs)) cs = 1;
							for (var i=1; i<cs; i++) remainingW += content['widtharray'][b+i] + content['cellspacing'];								
								
								
							var vfill = (obj['rows'][a]['cells'][b]['bgcolor'] != undefined) ? Number(this.replace(obj['rows'][a]['cells'][b]['bgcolor'], "#", "0x")) : (obj['rows'][a]['clip']['content']['bgcolor'] != undefined) ? Number(this.replace(obj['rows'][a]['clip']['content']['bgcolor'], "#", "0x")) : null;
							this.paint(obj['rows'][a]['cells'][b]['clip']['bg'],   0, 0, remainingW, remainingH, (borderoffset > 0) ? 1 : 0, vtborderColor, vfill, null, obj['rows'][a]['cells'][b]['clip']['content']);
							//this.paint(obj['rows'][a]['cells'][b]['clip']['mask'], -1, -1, remainingW+2, remainingH+2, 0,  null, 0xFF0000, null);
									
							var _mc1 = obj['rows'][a]['cells'][b]['clip'];
							//var _mc2 = obj['rows'][a]['cells'][b]['clip']['mask'];
							//_mc1.setMask(_mc2);
						}
					}
					
					//(mc, x, y, width, height, vstrength, vborderColor, vfill, borderOffset, parameters)	
					
					
					// Placing top level
					var tablewidth:Number = sumArray(content['widtharray'])+((content['widtharray'].length+1)*(content['cellspacing']))+(borderoffset*2)+1;
					var tableheight:Number = sumArray(content['heightarray'])+((content['heightarray'].length+1)*(content['cellspacing']))+(borderoffset*2)+1;
					
					this.paint(bg, 0, 0, tablewidth, tableheight, 0, null, vtborderColor, borderoffset, content);
					
					content['hasBorder'] = new Boolean(0+borderoffset > 0);
					content['cornerradius'] = (!isNaN(Number(content['cornerradius']))) ? ((Number(content['cornerradius']) - (borderoffset-1) > 0) ? Number(content['cornerradius']) - (borderoffset-1) : 0) : null;
					
					this.paint(bg, 0+borderoffset, 0+borderoffset, tablewidth-(borderoffset*2), tableheight-(borderoffset*2), 0, null, vtfill, null, content);
					
					align(mc,obj,pw,ph);
					
				}
				break;
				
			////////////////////////////////////////////////////////////////////////////				
			// Just a wrapper that calls buildClip (for 'cells')	
			case "row":
				mc = createEmptyClip(obj['id'], type, clip, depth);
				var bg = createEmptyClip('bg', type, mc, 0,true);
				var content = createEmptyClip('content', type, mc, 1,true);
				copyParams(content, obj);
				content['cellspacing'] = clip['cellspacing'];
				content['cellpadding'] = clip['cellpadding'];
				// build children
				if (obj['cells'].length != undefined)
				for (var a=0; a<obj['cells'].length; a++)
					obj['cells'][a]['clip'] = buildClip(obj['cells'][a], content, a);
					
				break;
				
			// The $ stops here!	
			case "cell":
				mc = createEmptyClip(obj['id'], type, clip, depth);
				var bg = createEmptyClip('bg', type, mc, 0, true);
				var content = createEmptyClip('content', type, mc, 1, true);
				var mask = createEmptyClip('mask', type, mc, 2, true);
				copyParams(content, obj);
				// build children
				if (obj['content'].length != undefined)	mc['children'] = obj['content'];
				break;
				
				
			////////////////////////////////////////////////////////////////////////////
			case "movieclip":
				var name = obj['id'] ? obj['id'] : "_mc" + depth; 
				mc = clip.attachMovie(obj.src, name, depth);
				if (obj['id']) addObject(obj['id'],mc);
				align(mc,obj,pw,ph);
				scale(mc,obj,pw,ph);
				break;

			////////////////////////////////////////////////////////////////////////////
			
			case "swf":
			case "image":
				var name = obj['id'] != undefined ? obj['id'] : "_mc" + getTimer(); 
				mc = createEmptyClip( name, "image", clip, depth, (obj['id'] == undefined || obj['id'] == "" ) );
				var listener = new Object();
				addToListeners( listener );
				if ( obj['id'] )
				{
					addObject( obj['id'], mc );
					listener.id = obj['id'];
				}
				listener.scope = this;
				listener.obj = obj;
				listener.pw = pw;
				listener.ph = ph;
				listener.clip = clip;
				listener.onLoadInit = function( mc )
				{
					trace( "Load init: " + mc._name );
					this.scope.scale(mc,this.obj,this.pw,this.ph);
					this.scope.align(mc,this.obj,this.pw,this.ph);
					if ( this.id ) this.scope.dispatchEvent( { type : "done_" + this.id, target : mc } );
				}
				listener.onLoadComplete = function( mc ) 
				{
					trace( "Load complete: " + mc._name );
				}
				listener.onLoadError = function( mc, error )
				{
					trace( "Load error! " + mc._name + " " + error );
				}
				
				var mcl : MovieClipLoader = new MovieClipLoader();
				addToListeners( mcl );
				mcl.addListener( listener );
				mcl.loadClip( String( obj.src ), mc );
				
				break;
				
				
			////////////////////////////////////////////////////////////////////////////
			// Custom tags
			default:
				if (type == undefined) break;
				if (this.tags[type] != undefined) 	{
						var listener = new Object;
				
						listener.scope = this;
						listener.obj = obj;
						listener.pw = pw;
						listener.ph = ph;
						listener.done = function() {							
							// this.mc.removeEventListener("done");					
							if (this.mc._width == 0) return; 	

							this.scope.scale(this.mc,this.obj,this.pw,this.ph);
							this.scope.align(this.mc,this.obj,this.pw,this.ph);		
						}
						addToListeners(listener);						
						mc = this.tags[type].apply(listener,[clip,obj,depth]);
						listener.mc = mc;
						// EventDispatcher.initialize(mc);
						
						if (obj['id']) addObject(obj['id'],mc);
						if (mc.addEventListener != undefined) mc.addEventListener("done",listener);
						else {
							listener.done();
							// delete listener;
						}								
						
					}
					else trace("Unable to process tag / type: " + type);
					
		}

		return mc;
	}
	


	
	///////////////////////////////////////////////////////////////////////////////////
	// centering mc's
	function align(mc,obj,w,h) {		
		
		// horizontal alignment
		if (obj['align'] == 'center') {
			mc._x += Math.max((w - mc._width)/2,0);
		} else if (obj['align'] == 'right') {
			mc._x += Math.max((w - mc._width),0);
		}
		
		// vertical alignment
		if (obj['valign'] == 'center') {
			mc._y += Math.max((h - mc._height)/2,0);
		} else if (obj['valign'] == 'bottom') {
			mc._y += Math.max((h - mc._height),0);
		}
	}
	
	// scaling mc's
	function scale(mc,obj,w,h) {
		
		// trace(mc._width + " " + mc._height);
		
		// Scaling to fit image
		var scale = 100;
		if (obj['scale']) scale = obj['scale'];
		else  if(obj['autoscale'] == "true")
			scale = 0.95 * 100*Math.min(w/mc._width,h/mc._height);
		else if (obj['autofit'] == "true")
			scale = 100*Math.min(1,w/mc._width,h/mc._height);
			
		mc._xscale = mc._yscale = scale;
	}
	///////////////////////////////////////////////////////////////////////////////////	
	
	


	
	private function getHeight(parent:MovieClip):Number	{
		if (parent.getNextHighestDepth() == 0) return 0;
		return (!isNaN(parent.getInstanceAtDepth(parent.getNextHighestDepth()-1).height)) ? parent.getInstanceAtDepth(parent.getNextHighestDepth()-1)._y + parent.getInstanceAtDepth(parent.getNextHighestDepth()-1).height :(parent.getInstanceAtDepth(parent.getNextHighestDepth()-1) instanceof TextField) ? parent.getInstanceAtDepth(parent.getNextHighestDepth()-1)._y + parent.getInstanceAtDepth(parent.getNextHighestDepth()-1).textHeight + this._spacing : parent.getInstanceAtDepth(parent.getNextHighestDepth()-1)._y + parent.getInstanceAtDepth(parent.getNextHighestDepth()-1)._height + this._spacing;
	}
	
	private function copyParams( dstObj:Object, srcObj:Object )	{
		for( var i in srcObj )
			dstObj[i] = srcObj[i];
	}

	
	private function setStyles(path)	{
		this._hasStyles = true;
		this.styles = new TextField.StyleSheet();
		this.styles['scope'] = this;
		this.styles.onLoad = function(success)	{
			this.dispatchEvent({type:(success) ? "stylesLoaded" : "stylesFailed", target:this.scope.styles});
			delete this.onLoad;
		}
		this.styles.load(path);
	}
	
	
	private function formatText(clip, textclip, isImg)	{
		with (textclip)		{
			html = true;
			//type = "dynamic";
			autoSize = 'left';
			multiline = true;
			wordWrap = true;
			condenseWhite = true;
			if (!isImg && this._hasStyles && clip['embedfont'] == undefined) styleSheet = this.styles;
		}
	}
	
	
	private function setStyleBlock(styles)	{
		if (!this._hasStyles)		{
			this.styles = new TextField.StyleSheet();
			this._hasStyles = true;
		}
		this.styles.parseCSS(styles);
		this.dispatchEvent({type:"stylesParsed", target:this.styles});
	}
	
	
	private function sumArray(arr:Array, mark:Number):Number	{
		var val = 0;
		if (mark == undefined) mark = arr.length;
		for (var i=0; i<mark; i++)
			if (!isNaN(Number(arr[i]))) val += arr[i];
		return val;
	}
	
	
	private function getMax(num1:Number, num2:Number):Number    {
        var n1:Number = (num1 == null || isNaN(num1)) ? 0 : num1;
        var n2:Number = (num2 == null || isNaN(num2)) ? 0 : num2;
		return (n2 > n1) ? Number(n2) : Number(n1);
    }
	
	
    private function replace(string, from, to)    {
        return (string.split(from).join(to));
    }
	

	/////////////////////////////////////////////////////////////////////////////	
	public function generate()	{
		
		clearTable();
		
		var listener:Object = new Object();
		listener.scope = this;
		listener.onDataParsed = function(evt)	{
			this.scope.parser.removeEventListener("onDataParsed", this);
			this.scope.dispatchEvent({type:"parsed", target:this.scope});
			this.scope.buildPage(evt.target);
			this.scope.dispatchEvent({type:"complete", target:this.scope});
		}
		addToListeners(listener);
		this.parser.addEventListener("onDataParsed", listener);
		this.parser.getPage(this.path,this.src);
		
	}
	
	
	public function generateFromString(str:String)	{
		trace( "page is " + page );
		clearTable();
		trace( "page now is " + page );
		trace( "div is " + page.div );
		var listener:Object = new Object();
		listener.scope = this;
		listener.onDataParsed = function(evt)		{
			this.scope.dispatchEvent({type:"parsed", target:this.scope});
			this.scope.buildPage(evt.target);
			this.scope.parser.removeEventListener("onDataParsed", this);
			this.scope.dispatchEvent({type:"complete", target:this.scope});
			trace( "now parsed" );
		}
		addToListeners(listener);
		this.parser.addEventListener("onDataParsed", listener);
		this.parser.fromString(str);
	}
	
	
	
	/////////////////////////////////////////////////////////////////////////////
	public function addFunction(funcName, func:Function)    {
		this.functions[funcName] = func;
    }
	
	public function addTag(tagName,tagFunc)    {
		this.tags[tagName] = tagFunc;
    }
	
	public function addParserTag(tagName,tagFunc)     {
		this.parser.tags[tagName] = tagFunc;
    }
	////////////////////////////////////////////////////////////////////////////
	
	
	
	public function paint(mc, x, y, width, height, vstrength, vborderColor, vfill, borderOffset, parameters)	{
		if (parameters != undefined && this.renderer != undefined)
			this.renderer.paint(mc, x, y, width, height, vstrength, vborderColor, vfill, borderOffset, parameters);
		else	{
			var tstrength = (!isNaN(vstrength)) ? vstrength : 0;
			var tborderColor = (!isNaN(vborderColor)) ? vborderColor : 0x999999;
			var tfill = (!isNaN(vfill)) ? vfill : null;
			
			if (tstrength > 0) mc.lineStyle(tstrength, tborderColor);
			mc.moveTo(x, y);
			if (!isNaN(tfill)) mc.beginFill(tfill);
			drawRect(mc, x, y, width, height);
			if (!isNaN(borderOffset))	{
				x+=borderOffset;
				y+=borderOffset;
				width-=borderOffset*2;
				height-=borderOffset*2;
				mc.moveTo(x, y);
				drawRect(mc, x, y, width, height);
			}
			if (!isNaN(tfill)) mc.endFill();
		}
	}
	
	private function drawRect(mc:MovieClip, x:Number, y:Number, width:Number, height:Number) 	{
		mc.lineTo(x+width, y);
		mc.lineTo(x+width, y+height);
		mc.lineTo(x, y+height);
		mc.lineTo(x, y);
	}
	
}