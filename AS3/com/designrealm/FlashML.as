package com.designrealm.flashml {
	
	/* TODOs:
	- convert parser to new version of XML - do we really need to?
	*/
	
	// imported for events to have consistent naming
	import com.designrealm.core.DesignrealmConstants;
	import com.designrealm.misc.ObjectUtils;
	import com.designrealm.wrapper.TextInputWrapper;
	
	// for popups
	import com.designrealm.mobile.popup.PopUp;
	import com.designrealm.mobile.popup.PopUpConstants;	
	
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import flash.events.TimerEvent;	
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer; 
	import flash.utils.Timer;
	import flash.geom.Rectangle;
	
	
	public class FlashML extends Sprite {
		
		private var objects:Object;
		private var events:Object;
		private var tags:Object;
		private var functions:Object;
		private var styles:StyleSheet;
		private var stylesLoaded:Boolean = false;	
		private var history:Object = new Object;

		private var _page:Sprite;
		private var _path:String = "";
		private var _src:String;
		private var objCounter:uint = 0;
		
		private var listeners:Array;
		private var nListeners:uint;
		
		private var renderer:*;
		private var parser;
		private var timer;
		private var _popup:PopUp;
		
				
		public function FlashML() {
			super();			
			parser = new Parser();
			parser.addEventListener(FMLEvent.LOAD_SUCCESS, onLoadComplete,false,0,true);
			parser.addEventListener(FMLEvent.LOAD_FAILED, onLoadFailed,false,0,true);
			renderer = new Renderer();			
			objects = new Object();
			tags = new Object();
			events = new Object();
			functions = new Object();			
			timer = new Timer(FMLConstants.TIMEOUT*1000);
			timer.addEventListener(TimerEvent.TIMER, timerHandler,false,0,true);			
			clear();		
		}		
		
		public function addFunction(funcName:String, func:Function):void    {
			functions[funcName] = func;
		}
		
		public function removeFunction(funcName:String):void    {
			if (functions[funcName] != undefined) delete functions[funcName];
		}
		
		public function getFunction(funcName:String):Function {
			return functions[funcName];
		}
		
		public function addTag(tagName:String, cls:Object):void    {
			tags[tagName] = cls;
		}
		
		public function addObject(id:String, obj:Object):void	{
			if (objects[id] != undefined) {
				trace("FML - addObject: '" + id + "' - Note: Already present, overwriting");
				clearObject(id,true);
			}
			else {
				trace("FML - addObject: '" + id + "'");				
			}
			objects[id] = obj;
			if (_page != null) {
				var pageName:String = this._page.name;
				// if (history == undefined) history = new Object;
				if (history[pageName] == undefined) history[pageName] = new Array();
				history[pageName].push(id);
			}
		}
		
		public function clear():void {
			if (_page != null) {
				for each (var _name:String in history[_page.name])
					clearObject(_name,true);
				delete history[_page.name];
				clearObject(_page.name,false);
			}
			if (_page == null) {
				trace("FML - clear: Create new 'main' window");
				_page = createSprite(FMLConstants.MAIN, this as Sprite, false);
			}
	    }	    
		
		public function clearAll():void {
			trace("----- FML - clearAll -----");
			for each (var _name:String in history[FMLConstants.MAIN])
				clearObject(_name,true);			
		}
		
		public function deleteObject(_name:String) {
			clearObject(_name,true);
		}						
		
		public function removeObject(_name:String) {
			var mc = getObject(_name);
			if (mc == null) return;		
			if (objects[_name] != undefined)  {
				trace("FML - removeObject: " + _name);
				removeEvent(_name);					
				delete objects[_name];
			}	
			for (var __page:String in history) {
				for (var _i:uint = 0; _i < history[__page].length; _i++) {
					if (history[__page][_i] == _name) history[__page].splice(_i,1);
				}
			}			
		}		
		
	    public function clearObject(_name:String,deleteCurrent:Boolean = false,level:uint = 0):void {
			var mc = getObject(_name);
			if (mc == null) return;			
			
			//trace('FML - clearObject: clearing ' + mc.name+ ' at level ' + level);
			if (deleteCurrent) removeObject(mc);	
			// if it is a custom class - a clear function may have been implemented
			if ('clear' in mc) mc.clear();

			try { mc.numChildren > 0;  }
			catch(e) { 
				return; 
			}
	
			var childrenToSkip:uint = 0;
			while (mc.numChildren > childrenToSkip) {				
				var _mc = mc.getChildAt(childrenToSkip)				
				// we need to hard-code some exceptions				
				if (_mc.name == 'viewBox') { // || _mc.name == 'activeArea') {
					++childrenToSkip;
					continue;
				}
							
				// is this the top-level object (i.e. the container and we keep its children?)
				if ((level == 0 && !deleteCurrent) && (_mc.name == FMLConstants.CONTENT || _mc.name == FMLConstants.BACKGROUND || _mc.name == FMLConstants.MASK)) {
					++childrenToSkip;
				}
				// we completely delete this object
				else {
					
					// these are the links we know about - objects and events
					if (objects[_mc.name] != null)  {
						removeEvent(_mc.name);					
						delete objects[_mc.name];
					}
					
					// trying to remove tis child
					try { mc.removeChildAt(childrenToSkip); }
					catch(e) { 
						if (_mc is Bitmap) 
							_mc.bitmapData.dispose();
						else 
							trace("FML - clearObject: Failed with object '" + _mc.name + "' = '" + getQualifiedClassName(_mc) + "'");
							++childrenToSkip;
					}
				}

				clearObject(_mc,true,level+1);
				_mc = null;
				
			}
		}
		
		private function createSprite(vid:String, target:Sprite, dontAdd:Boolean = false):Sprite {
			var id:String = (vid != null) ? vid : "obj" + objCounter;
			++objCounter;
			var mc:Sprite = new Sprite();
			mc.name = id;
			target.addChild(mc);
			if (vid != null && !dontAdd) addObject(vid, mc);
			return mc;
		}
		
		// permanent listener
		private function onLoadComplete(e:Event):void{
			dispatchEvent(new FMLEvent(FMLEvent.LOAD_SUCCESS));
		}
		
		// permanent listener		
		private function onLoadFailed(e:Event):void{
			dispatchEvent(new FMLEvent(FMLEvent.LOAD_SUCCESS));
		}		
		
		private function buildPage(obj:Object):void 	{
			// Passing the current page width and height as params to the builder
			var w:uint = _page.width > 0 ? _page.width : obj.width > 0 ? obj.width : 300;
			var h:uint = _page.height > 0 ? _page.height : obj.height > 0 ? obj.height : 200;
			// FML counts as the first clip to complete
			timer.start();
			listeners = new Array();
			listeners.push(null);
			nListeners = 1;
			buildClip(obj, _page, w, h);
			--nListeners;
			trace('FML: Listeners at ' + nListeners + ' - buildPage finished');
			if (nListeners == 0) { 
				dispatchEvent(new FMLEvent(FMLEvent.COMPLETE,{page:this.page}));
				timer.stop();
			}
		}	
	
		private function buildClip(obj:Object, clip:Sprite, pw:Number = 300, ph:Number = 100):void	{	
			if (obj == null || obj['type'] == null) return;
			var type:String = obj['type'].toLowerCase();
			var cls:Class;
			var i:uint
			var mc;
			
			// was a different target specified
			if (obj['page'] != null && objects[obj['page']] != null) {
				clip = objects[obj['page']];
				// now we need to guess the w and h of the new 'clip'
				//var _bounds = clip.getBounds(clip);
				//if (_bounds.width == 0) _bounds = clip.parent.getBounds(clip.parent);
				ph = clip.height > 0 ? clip.height : obj['height'];
				pw = clip.width > 0 ? clip.width : obj['width'];
			}			
			
			switch(type){ // pre-child construction	
				case "html":
				case "xml":
				case "head":
				case "div":
				case "body":
					var _bounds = clip.getBounds(clip);
					ph = (!isNaN(Number(obj['height']))) ? Number(obj['height']) : _bounds.height;
					pw = (!isNaN(Number(obj['width']))) ? Number(obj['width']) : _bounds.width;
					var h:Number = 0

					for (i = 0; i<obj['children'].length; i++) {
						buildClip(obj['children'][i], clip, pw, ph - h );
						// in case the object is not a display object
						try {
							obj['children'][i].y += h;
							h = obj['children'][i].height;
						}
						catch(e) {};
					}										
					break;

					
				////////////////////////////////////////////////////////////////////////////				
				case "styles":
					if (obj['href'] != undefined) setStyles(obj['href']);
					break;
					
				////////////////////////////////////////////////////////////////////////////				
				case "styleblock":
					setStyleBlock(obj['children'].toString());			
					break;
					
				////////////////////////////////////////////////////////////////////////////				
				case "definition":
				case "script":
					break;
					
					
				////////////////////////////////////////////////////////////////////////////
				case "text":				
					var tf:TextField;
					var _createTF:Boolean = true;
				
					//search for an existing TextField
					if (clip is Sprite && clip.numChildren > 0) {
						mc = clip.getChildAt(clip.numChildren-1) as Sprite;
						if (mc is Sprite && mc.numChildren > 0) {
							if (mc.getChildAt(0) is TextField) {
								_createTF = false;
								tf = mc.getChildAt(0) as TextField;
								trace('FML: Reusing found TF ' + tf.name);
							}
						}				
					}
					
					if (_createTF) {
						obj[FMLConstants.CONTAINER] = createSprite(FMLConstants.CONTAINER, clip, true);
						tf = new TextField()
						obj[FMLConstants.CONTAINER].addChild(tf);
						tf.name = obj['id'] ? obj['id'] : 'tf'+ obj[FMLConstants.CONTAINER].getChildIndex(tf);
						tf.width = pw;
						var tf_fmt:TextFormat = new TextFormat();					
						if (obj["embedfont"]) 	{
							// if the embedded font is referenced in the stylesheet
							if (obj["embedfont"] == "true" ) {
								tf.embedFonts = true;
							}
							else if (obj["embedfont"] == "false" ) {
								tf.embedFonts = false;
							}
							// if the font to embed is named directly
							else {
								try { cls = getDefinitionByName(obj["embedfont"]) as Class; }
								catch(e) {}
								if (cls!=null) {
									var myFont:Font = new cls(); 
									tf.embedFonts = true;
									tf_fmt.font = myFont.fontName;
									tf.antiAliasType = 'advanced';
									tf.defaultTextFormat = tf_fmt;
								}
							}
						}
						else {
							tf.embedFonts = FMLConstants.EMBED_FONTS;
						}
						tf.selectable = FMLConstants.SELECTABLE;					
						tf.autoSize = "none";
						tf.multiline = true;
						tf.wordWrap = true;
						tf.condenseWhite = true;
						if (stylesLoaded) tf.styleSheet = styles;
						if (obj['id']) addObject(obj['id'],tf);
					}
			
					// The text properties overrule the inherited properties
					var _valign = obj["valign"] ? obj["valign"].toLowerCase() : null;			
					var _deltay = obj["deltay"] ? obj["deltay"] : null;			
					// var _align = obj["align"] ? obj["align"].toLowerCase() : null;

					tf.htmlText += obj['children'].toString();
					tf.height = tf.textHeight+4;

					// Just for vertical alignment
					align(tf,{valign:_valign, deltay:_deltay},0,ph);
					break;
					
				////////////////////////////////////////////////////////////////////////////		
				// The 'heart' of the engine	
				case "table":
				
					obj[FMLConstants.CONTAINER] = createSprite(obj['id'], clip, false);
					obj[FMLConstants.BACKGROUND] = createSprite(FMLConstants.BACKGROUND, obj[FMLConstants.CONTAINER], true);
					obj[FMLConstants.CONTENT] = createSprite(FMLConstants.CONTENT, obj[FMLConstants.CONTAINER], true);
					
					// initializing graphics variables
					obj['cellspacing'] = (!isNaN(Number(obj['cellspacing']))) ? Number(obj['cellspacing']) : 0;
					obj['cellpadding'] = (!isNaN(Number(obj['cellpadding']))) ? Number(obj['cellpadding']) : 0;
					obj['cornerradius'] = (!isNaN(Number(obj['cornerradius']))) ? Number(obj['cornerradius']) : 0;
					// border for <table> or <td> only
					obj['border'] = (!isNaN(Number(obj['border']))) ? Number(obj['border']) : 0;
					
					// place internal container
					//obj[FMLConstants.CONTAINER].x = obj['cellspacing']  + obj['border'];
					//obj[FMLConstants.CONTAINER].y = obj['cellspacing']  + obj['border'];
					
					// do we have rows?
					if (obj['rows'].length != undefined) 	{
						
						// creating all row objects
						for (var a:uint=0; a<obj['rows'].length; a++) 		{												
		
							// keeping variables throughout the hierarchy
							copyParam(obj['rows'][a],obj,'cellspacing');
							copyParam(obj['rows'][a],obj,'cellpadding');							

							// building row object
							buildClip(obj['rows'][a], obj[FMLConstants.CONTENT]);							
								
							// initial vertical placement of the row
							obj['rows'][a][FMLConstants.CONTAINER].y = obj['rows'][a]['cellspacing'];
							if (a>0) obj['rows'][a][FMLConstants.CONTAINER].y += sumArray(obj['heightarray'], a) + obj['rows'][a]['cellspacing']*a;	
							
							// creating all cell objects
							for (var b:uint=0; b<obj['rows'][a]['cells'].length; b++)	{								
								
								if (obj['rows'][a]['cells'][b] != null && obj['rows'][a]['cells'][b]['type'] != null) {
								
									// keeping variables throughout the hierarchy
									copyParam(obj['rows'][a]['cells'][b],obj['rows'][a],'cellspacing');
									copyParam(obj['rows'][a]['cells'][b],obj['rows'][a],'cellpadding');								
									// border for <table> or <td> only
									obj['rows'][a]['cells'][b]['border'] = (!isNaN(Number(obj['rows'][a]['cells'][b]['border']))) ? Number(obj['rows'][a]['cells'][b]['border']) : 0;
									
									// moving to the right by the sum of the total widthes so far
									obj['rows'][a]['cells'][b][FMLConstants.CONTAINER].x = obj['rows'][a]['cells'][b]['cellspacing']; // + obj['rows'][a]['cells'][b]['border'] ;
									if (b > 0) obj['rows'][a]['cells'][b][FMLConstants.CONTAINER].x += sumArray(obj['widtharray'], b) + obj['rows'][a]['cells'][b]['cellspacing']*b;
									obj['rows'][a]['cells'][b][FMLConstants.CONTENT].x =  obj['rows'][a]['cells'][b]['cellpadding'];
									obj['rows'][a]['cells'][b][FMLConstants.CONTENT].y =  obj['rows'][a]['cells'][b]['cellpadding'];
									
									// Calculating remaining height and width for the current cell
									var remainingH:Number = obj['heightarray'][a] - obj['rows'][a]['cells'][b]['cellspacing']*b;
									var remainingW:Number = obj['widtharray'][b] - obj['rows'][a]['cells'][b]['cellspacing']*b;
									
									// getting rowspan and colspan -- calculating height and width
									var rs:Number = Number(obj['rows'][a]['cells'][b]['rowspan']);
									if (isNaN(rs)) rs = 1;
									for (i=1; i<rs; i++)	
										remainingH += obj['heightarray'][a+i] + obj['rows'][a]['cells'][b]['cellspacing'];
									
									
									var cs:Number = Number(obj['rows'][a]['cells'][b]['colspan']);
									if (isNaN(cs)) cs = 1;									
									for (i=1; i<cs; i++)	
										remainingW += obj['widtharray'][b+i] + obj['rows'][a]['cells'][b]['cellspacing'];
																	
									
									// Building inner clips - i.e. cell contents
									for (var c:uint = 0; c < obj['rows'][a]['cells'][b]['children'].length; c++)	{										
										// copying alignment & other variables from the cell level
										copyParam(obj['rows'][a]['cells'][b]['children'][c],obj['rows'][a]['cells'][b],'align');
										copyParam(obj['rows'][a]['cells'][b]['children'][c],obj['rows'][a]['cells'][b],'valign');

										// creating cell content
										buildClip(obj['rows'][a]['cells'][b]['children'][c], obj['rows'][a]['cells'][b][FMLConstants.CONTENT], remainingW - (obj['rows'][a]['cells'][b]['cellpadding'] * 2), remainingH - (obj['rows'][a]['cells'][b]['cellpadding'] * 2));
									}		

									// rendering cell background
									renderer.paint(obj['rows'][a]['cells'][b][FMLConstants.BACKGROUND], 0, 0, remainingW, remainingH, obj['rows'][a]['cells'][b]);
									
									// rendering mask
									var _maskObj:Object = ObjectUtils.clone(obj['rows'][a]['cells'][b]);
									_maskObj.bgcolor = "0xffffff";
									renderer.paint(obj['rows'][a]['cells'][b][FMLConstants.MASK],0,0,remainingW - (obj['rows'][a]['cells'][b]['cellspacing'] * 2),remainingH - (obj['rows'][a]['cells'][b]['cellspacing'] * 2),_maskObj);
									obj['rows'][a]['cells'][b][FMLConstants.CONTENT].mask = obj['rows'][a]['cells'][b][FMLConstants.MASK];									
									
									copySpriteParams(obj['rows'][a]['cells'][b][FMLConstants.CONTAINER],obj);									
								}
							
							}
						}
	
						// rendering top level
						// why are we adding one here?
						var tablewidth:Number = sumArray(obj['widtharray'])+(obj['widtharray'].length+1)*obj['cellspacing'];
						var tableheight:Number = sumArray(obj['heightarray'])+(obj['heightarray'].length+1)*obj['cellspacing'];
						renderer.paint(obj[FMLConstants.BACKGROUND], 0, 0, tablewidth, tableheight, obj);
						
						// that's it folks!
						scale(obj[FMLConstants.CONTAINER],obj,pw,ph);
						align(obj[FMLConstants.CONTAINER],obj,pw,ph);
						
					}
					break;
					
				////////////////////////////////////////////////////////////////////////////				
				// Just a wrapper that calls buildClip (for 'cells')	
				case "row":
					obj[FMLConstants.CONTAINER] = createSprite(obj['id'], clip, false);
					// build children
					if (obj['cells'].length != undefined)
						for (i=0; i<obj['cells'].length; i++)
							buildClip(obj['cells'][i], obj[FMLConstants.CONTAINER]);
					break;
					
				// The $ stops here!	
				case "cell":
					obj[FMLConstants.CONTAINER] = createSprite(obj['id'], clip, false);
					obj[FMLConstants.BACKGROUND] = createSprite(FMLConstants.BACKGROUND, obj[FMLConstants.CONTAINER], true);
					obj[FMLConstants.CONTENT] = createSprite(FMLConstants.CONTENT, obj[FMLConstants.CONTAINER], true);
					obj[FMLConstants.MASK] = createSprite(FMLConstants.MASK, obj[FMLConstants.CONTAINER], true);
					break;
						
					
				////////////////////////////////////////////////////////////////////////////
				case "movieclip":
					try { cls = getDefinitionByName( obj.src ) as Class; }
					catch(cls) {}
					// what if the mc does not exist
					if (cls != null) {
						obj[FMLConstants.CONTAINER] = createSprite(null, clip, false);				
						var mcLoader = new FMLMovieClipLoader();
						mcLoader.params = { obj:obj, pw:pw, ph:ph, clip:obj[FMLConstants.CONTAINER], fml:this };
						mcLoader.onComplete = onObjectLoadComplete;
						mcLoader.id = listeners.length;
						mcLoader.cls = cls;
						++nListeners;
						listeners.push(mcLoader);
						mcLoader.load();
					}
					break;
									
				////////////////////////////////////////////////////////////////////////////
				case "swf":
				case "image":
					obj[FMLConstants.CONTAINER] = createSprite(FMLConstants.CONTAINER, clip, true);
					var ldr:FMLLoader = new FMLLoader();
					ldr.params = { obj:obj, pw:pw, ph:ph, clip:obj[FMLConstants.CONTAINER], fml:this };
					ldr.onComplete = onObjectLoadComplete;
					ldr.onFail = onObjectLoadFailed;
					ldr.id = listeners.length;
					++nListeners;
					listeners.push(ldr);
					// FMLLoader assigns the name to the new mc (if id is supplied)
					ldr.load(this._path + obj.src);					
					break;
					
					
				////////////////////////////////////////////////////////////////////////////
				// Custom tags
				default:
					if (this.tags[type] != undefined) 	{
						obj[FMLConstants.CONTAINER] = createSprite(FMLConstants.CONTAINER, clip, true);
						var tag = new FMLTag();
						tag.params = { obj:obj, pw:pw, ph:ph, clip:obj[FMLConstants.CONTAINER], fml:this }
						tag.classname = tags[type];
						mc = tag.create();
						if (mc == null) {
							trace('***** FML: Failed to create object of type ' + type + ' *****');
							break;
						}
						// do we have an mc?
						var _super_top:String = getQualifiedSuperclassName(mc);
						if (_super_top == 'flash.display::Sprite' || _super_top == 'flash.display::MovieClip' || _super_top == 'flash.display::DisplayObjectContainer') {
							obj[FMLConstants.CONTAINER].addChild(mc);
						}
						tag.onComplete = onObjectLoadComplete;
						tag.onFail = onObjectLoadFailed;						
						tag.id = listeners.length;
						++nListeners;
						listeners.push(tag);
						tag.generate();
						break;
					}
					else trace("***** FML: Unable to process tag / type: " + type + " *****");						
			}
		}		
		
		private function onObjectLoadComplete(id,container,new_mc,obj,pw,ph):void {			
			var _super_top:String = getQualifiedSuperclassName(new_mc).split("::")[0];
			// trace(_super_top);			
			// add object
			if (obj['id']) addObject(obj['id'],new_mc);			
			// in case the object is not an MC (such as animation objects etc.)
			if (_super_top == 'flash.display') {				
				// we need to process external images / movies now
				if (obj.type == "swf" || obj.type == "image") container.addChild(new_mc);						
				// we did not have the full object yet
				this.scale(new_mc, obj, pw, ph);
				if (obj.type == "swf" || obj.type == "image" || obj.type == "movieclip") 
					copySpriteParams(new_mc,obj);
				else 
					copySpriteParams(new_mc,obj,true);
				copyParams(new_mc,obj);	
				this.align(new_mc, obj, pw, ph);
			}			
			container.visible = true;				

			// in case someone is watching this object
			if (obj['id']) this.dispatchEvent(new FMLEvent("done_" + obj['id']));
			// global listeners
			listeners[id] = null;
			--nListeners;
			trace("FML: load listeners at " + nListeners + " - '" + new_mc.name + "' loaded");
			if (nListeners == 0) {
				this.dispatchEvent(new FMLEvent(FMLEvent.COMPLETE,{page:this.page}));
				timer.stop();
			}
		}
		
		private function onObjectLoadFailed(error,id,obj):void {			
			// tracing
			var traceMessage:String = '***** FML: Error while loading type = ' + obj.type;
			if (obj.id != null) { 
				traceMessage +=  ' id = '+ obj.id;
				dispatchEvent(new FMLEvent("error_" + obj['id']));
			}
			traceMessage += ' msg =' + error.text;
			trace(traceMessage + ' *****');
			
			_popup = new PopUp(PopUpConstants.TYPE_OK,"Can't load '" + obj.id + "'",this.parent as Sprite,null,200);
			
			// global listeners
			if (obj['id']) this.dispatchEvent(new FMLEvent("done_" + obj['id']));			
			listeners[id] = null;
			trace('FML: Load listeners at ' + nListeners);
			
			--nListeners;			
			if (nListeners == 0) { 
				this.dispatchEvent(new FMLEvent(FMLEvent.COMPLETE,{page:this.page}));
				timer.stop();
			}						
		}		
		
		private function timerHandler(e:TimerEvent) {
			timer.stop();
			if (listeners.length > 0) {
				for each (var listener:Object in listeners) {
					if (listener != null) {
						try { listener.clear(); } catch(e) {}
					}
				}
				listeners = null;
				listeners = new Array();
				nListeners = 0;
				dispatchEvent(new FMLEvent(FMLEvent.COMPLETE,{page:this.page}));
				trace('***** FML: Timer resets load listeners *****');
			}
		}

		private function copySpriteParams( dst:Object, src:Object, skipDimensions:Boolean = false):void{
			var _params:Array;
			if (skipDimensions) _params = ['visible','x','y','z','rotationX','rotationY','rotationZ','alpha'];
			else _params = ['visible','x','y','z','rotationX','rotationY','rotationZ','alpha','width','height'];
			for( var param:String in src ) {
				if ( _params.indexOf(param) > -1 && src[param] is String) {
					dst[param] = (!isNaN(Number(src[param]))) ? Number(src[param]) : src[param] == "true" ? true : src[param] == "false" ? false : src[param];
				}					
			}
		}	
	
		private function copyParams( dst:Object, src:Object ):void{
			if (src['params'] == null) return;
			var _params:Array = src['params'].split(';');
			for each( var _current_params:String in _params ) {
				var _current_params_array:Array = _current_params.split(",",2);
				var _name:String = _current_params_array[0];
				var _value:String = _current_params_array[1];
				dst[_name] = (!isNaN(Number(_value))) ? Number(_value) :_value == "true" ? true : _value == "false" ? false : _value;
			}
		}		
		
		private function copyParam( dst:Object, src:Object, param:String ):void { 
			if (dst != null && dst[param] != null) {
				dst[param] = (!isNaN(Number(dst[param]))) ? Number(dst[param]) : dst[param] == "true" ? true : dst[param] == "false" ? false : dst[param];
				return;
			}
			if (src == null || src[param] == undefined ) return;
			dst[param] = (!isNaN(Number(src[param]))) ? Number(src[param]) : src[param] == "true" ? true : src[param] == "false" ? false : src[param];
		}		
		
		public function removeEvent(_name:String,_event:String = null) {
			var mc = getObject(_name);
			if (mc == undefined) return;
			var fullName = getFullName(mc,_name);
						
			if (events[fullName] != undefined ) {
				var event:String;
				// removing all events
				if (_event == null) {
					for each (event in events[fullName]) {
						var _target:Object = mc;
						if (_event == DesignrealmConstants.EVENT_CLICK || _event == DesignrealmConstants.EVENT_OVER || _event == DesignrealmConstants.EVENT_OUT) {
							// _target = _getHitArea(mc);
						}						
						_target.removeEventListener(event,onEventDispatched);
						delete events[fullName][event];
					}
					delete events[fullName];
				}
				// removing only the event we want to clear
				else { 
					event = DesignrealmConstants.EVENTS[_event];			
					if (events[fullName][event] != undefined) {
						mc.removeEventListener(event,onEventDispatched);
						delete events[fullName][event];
					}
				}
			}
			if (_event == null) {
				trace("FML - removeEvent: removed all events from '" + _name + "'");
			}
			else {
				trace("FML - removeEvent: removed event '" + _event + "' from '" + _name + "'");
			}
		}
		
		private function _addHitArea(_target:Object):void {
			if (_target == null) return;
			if (_target.visible == false) {
				_target.alpha = 0;
				_target.visible = true;
			}
			if (_target is TextInputWrapper) return;
			var _hitArea:Sprite = _target.getChildByName("__hitarea");
			if (_hitArea) return;
			var bounds:Rectangle = _target.getBounds(_target);
			var _width:Number = bounds.width;
			var _height:Number = bounds.height;
			_hitArea = new Sprite;
			_hitArea.name = "__hitarea";
			_hitArea.graphics.lineStyle();	
			_hitArea.graphics.beginFill(0xFFFFFF);
			_hitArea.graphics.drawRect(0,0,_width,_height);			
			_hitArea.graphics.endFill();
			_hitArea.alpha = 0;
			_hitArea.x = bounds.left;
			_hitArea.y = bounds.top;
			_target.addChild(_hitArea);
		}
		
		public function addEvent(_name:String,_event:String,func:String,params:*):void{			
			var mc = getObject(_name);
			if (mc == undefined) return;
			var fullName = getFullName(mc,_name);
			var event:String = DesignrealmConstants.EVENTS[_event];						
			if (events[fullName] == undefined) events[fullName] = new Object();
			if (events[fullName][event] == undefined) {
				var _target:Object = mc;
				if (_event == DesignrealmConstants.EVENT_CLICK || _event == DesignrealmConstants.EVENT_OVER || _event == DesignrealmConstants.EVENT_OUT) {
					_addHitArea(mc);
				}
				_target.addEventListener(event,onEventDispatched,false,0,true);
				events[fullName][event] = new Array();
				events[fullName][event].push({params:params,func:func});		
				trace("FML - addEvent: added event '" + _event + "' to '" + _name + "'");					
			}
			else {
				// we can't add the same event handler for the same event twice
				// this allows us to get around a flash bug with: 
				// out and over events combined with cloning keep adding the same event handler
				var _found:Boolean = false;
				for each (var _obj:Object in events[fullName][event]) {
					if (_obj.func == func && _obj.params == params) { 
						_found = true;
						continue;
					}
				}
				if (!_found) {
					events[fullName][event].push({params:params,func:func});		
					trace("FML - addEvent: added event '" + _event + "' to " + _name);					
				}
				else {
					trace("***** FML - addEvent: refused to re-add event '" + _event + "' with same handler to '" + _name +"' *****");			
				}
			}
		}
		
		// need unique identifier for event originators
		private function getFullName(target,defaultName:String = "") {
			if (target == null || target['name'] == undefined) return defaultName;
			if (defaultName == "") defaultName = target.name;
			var nameArray = new Array();
			try {
				nameArray.push(target.name);
				var _parent = target.parent;
				while (_parent != this.stage) {
					nameArray.push(_parent.name);
					_parent = _parent.parent;
				}
				return nameArray.reverse().join(".");
			}
			catch(e) {
				return defaultName;
			}
		}		
		
		private function onEventDispatched(e:Event):void {
			var _name:String = getFullName(e.currentTarget);
			_name = _name.split(".__hitarea").join("");
			var _type:String = e.type;
			if (events == null || events[_name] == null || events[_name][_type] == undefined) {
				trace("***** FML: caught unhandled event '"+_type+"' from '" + e.currentTarget.name + "' *****");
				return;
			}
			trace("FML: event '" + _type + "' caught for '" + e.currentTarget.name + "'");
			for each (var obj:Object in events[_name][_type])
				functions[obj.func].apply(null,[obj.params]);
		}
		
		// 
		private function parseParams(val:Array):Array 	{
			for (var j:uint = 0; j<val.length; j++)
				if (val[j].toString().substr(0,1) == "[" && val[j].toString().substr(val[j].length-1,1) == "]")	{
					var obj = val[j].substr(1, val[j].length-2);
					if (objects[obj]!= undefined) val[j] = objects[obj];
				}
			return val;
		}
		
		private function replace(string:String, from:String, to:String):String {
			if (string == null) return null;
	        return (string.split(from).join(to));
	    }
	    
	    private function setStyles(path:String):void{
			stylesLoaded = true;
			var styleLdr:URLLoader = new URLLoader();
			styleLdr.addEventListener(Event.COMPLETE,onStyleLoad,false,0,true);
			styleLdr.addEventListener(IOErrorEvent.IO_ERROR,onStyleLoadError,false,0,true);
		}
		
		private function onStyleLoad(e:Event):void{
			styles = new StyleSheet();
			styles.parseCSS(e.currentTarget.data);
			dispatchEvent(new FMLEvent(FMLEvent.STYLES_LOAD_SUCCESS));
		}
		
		private function onStyleLoadError(e:Event):void{
			dispatchEvent(new FMLEvent(FMLEvent.STYLES_LOAD_FAILED));
		}
		
		private function setStyleBlock(stylesStr:String)	{
			if (!stylesLoaded)		{
				styles = new StyleSheet();
				stylesLoaded = true;
			}
			styles.parseCSS(stylesStr);
			dispatchEvent(new FMLEvent(FMLEvent.STYLES_PARSED));
		}
		
		function align(mc:Object, obj:Object, w:Number, h:Number):void {				
			var mc_height:Number = mc is TextField ? mc.textHeight : mc.height

			// horizontal alignment
			if (obj['align'] == 'center' || obj['align'] == 'centre') {
				mc.x = (w - mc.width)/2;
			} else if (obj['align'] == 'right') {
				mc.x = w - mc.width;
			}
			if (!isNaN(Number(obj['deltax']))) 
				if (Math.abs(Number(obj['deltax'])) < 1) mc.x += Number(obj['deltax'])*mc.width;
				else mc.x += Number(obj['deltax']);
			
			// vertical alignment
			if (obj['valign'] == 'center' || obj['valign'] == 'centre') {
				mc.y = (h - mc_height)/2;
			} else if (obj['valign'] == 'bottom') {
				mc.y = h - mc_height;
			}
			if (!isNaN(Number(obj['deltay']))) 
				if (Math.abs(Number(obj['deltay'])) < 1) mc.y += Number(obj['deltay'])*mc_height;
				else mc.y += Number(obj['deltay']);

		}
		
		// scaling mc's
		function scale(mc:Object, obj:Object, w:Number, h:Number):void {					
			var mc_height:Number = mc is TextField ? mc.textHeight : mc.height
		
			if (obj['autoscale'] == "true") {
				mc.scaleX = mc.scaleY = Math.min(w/mc.width, h/mc_height);
				if (obj['scale']) {
					mc.scaleX *= Number(obj['scale']);	
					mc.scaleY *= Number(obj['scale']);
				}
				else {
					mc.scaleX *= 0.95;
					mc.scaleY *= 0.95;
				}
			}
			else if (obj['autofit'] == "true") {
				mc.scaleX = mc.scaleY = Math.min(1, w/mc.width, h/mc.height);
				if (obj['scale']) {
					mc.scaleX *= Number(obj['scale']);	
					mc.scaleY *= Number(obj['scale']);
				}
			}
			else if (obj['scale']) 
				mc.scaleX = mc.scaleY = Number(obj['scale']);	
		}
		
		private function sumArray(arr:Array, _last:Number = undefined, _first:Number = 0):Number	{
			var val = 0;
			if (isNaN(_last)) _last = arr.length;
			for (var i:uint = _first; i<_last; i++)
				if (!isNaN(Number(arr[i]))) val += arr[i];
			return val;
		}
		
		public function generate()	{
			if (_page == null) return;
			clear();
			if (objCounter > 10000) objCounter = 0;
			dispatchEvent(new FMLEvent(FMLEvent.GENERATE,{page:this.page}));
			parser.addEventListener(FMLEvent.PARSED,onDataParse,false,0,true);
			parser.addEventListener(FMLEvent.LOAD_FAILED,onDataParseFail,false,0,true);
			parser.getPage(this._path, this._src);
		}
		
		private function onDataParse(e:FMLEvent):void{
			parser.removeEventListener(FMLEvent.PARSED, onDataParse);
			parser.removeEventListener(FMLEvent.LOAD_FAILED,onDataParseFail);
			if (e.target.tableData == null) {
				var _error:FMLEvent = new FMLEvent(FMLEvent.LOAD_FAILED);
				_error.text = "Can't load '" + src + "'";
				dispatchEvent(_error);
				_popup = new PopUp(PopUpConstants.TYPE_OK,"Can't load '" + src + "'",this.parent as Sprite,null,200);
			}
			else {
				buildPage(e.target.tableData);
				dispatchEvent(new FMLEvent(FMLEvent.PARSED));
			}
		}		
		
		private function onDataParseFail(e:FMLEvent):void{
			parser.removeEventListener(FMLEvent.PARSED, onDataParse);
			parser.removeEventListener(FMLEvent.LOAD_FAILED,onDataParseFail);
			var _error:FMLEvent = new FMLEvent(FMLEvent.LOAD_FAILED);
			_error.text = e.text;
			dispatchEvent(_error);
			_popup = new PopUp(PopUpConstants.TYPE_OK,"Can't load '" + src + "'",this.parent as Sprite,null,200);
		}				
		
		public function set path(__path:String) {
			this._path = __path;
		}
		
		public function get path() {
			return this._path;
		}
		
		public function set src(__src:String) {
			this._src = __src;
		}
				
		public function get src() {
			return this._src;
		}
				
		public function set page(__page:String) {
			if (__page != null && objects[__page] != null) this._page = this.objects[__page];
			else this._page = null;
		}
		
		public function get page() {
			if (this._page == null) return null;
			else return this._page.name;
		}
		
		// function to get an object / property from its id
		public function getObject(_name:String):* {
			var nameArray:Array = _name.split(".");
			var _obj:Object = this.objects[nameArray.shift()];
			if (_obj == null) return null;
			if (nameArray.length > 0) {
				var _child:Object;
				var _childName:String = nameArray.join(".");
				if (_childName in _obj) 
					return _obj[_childName];
				try {
					_child = _obj.getObject(_childName);
					return _child;
				}
				catch(e) { return _name; }
			}
			return _obj;			
		}		
		
	}
}