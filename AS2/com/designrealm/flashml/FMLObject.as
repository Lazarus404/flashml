import mx.utils.Delegate;

class com.designrealm.flashml.FMLObject extends MovieClip
{

	private var alphaDisabled:Number = 50;
	private var boundingbox:MovieClip;
	private var methodTable:Array;
	private var enabled:Boolean = true;
	private var focus:MovieClip;
	private var focusInterval:Number;
	private var focusLimit:Number = 2000;
	private var focusTime:Number;
	private var focusTimer:Number;
	private var height:Number;
	private var invalidateClip:MovieClip;
	private var keyEnabled:Boolean = true;
	private var width:Number;
	private var invalidateFlag:Boolean = false;
	private var dispatchEvent:Function;
	private var addEventListener:Function;
	private var handleEvent:Function;
	private var removeEventListener:Function;
	public var clipParameters:Object;
	public var parentClass:String;
	
	public function FMLObject(Void) {
		super();
		constructObject();
	}
	
	private function constructObject() {
		init();
		createChildren();
		invalidate();
	}
	
	function init(Void):Void {
		_root._focusrect = false;
		focusEnabled = true;
		this.width = _width;
		this.height = _height;
		_xscale = 100;
		_yscale = 100;
		this.boundingbox._width = 0;
		this.boundingbox._height = 0;
		this.boundingbox._visible = false;
		initFromClipParameters();
	}
	
	
	function size(Void):Void {
		this._width = this.width;
		this._height = this.height;
	}
	
	public function move(x:Number, y:Number):Void {
		this._x = x;
		this._y = y;
	}
	
	function doLater(obj:Object, fn:String):Void {
		if (this.methodTable == undefined) {
			this.methodTable = new Array();
		}
		this.methodTable.push({obj:obj, fn:fn});
		this.onEnterFrame = doLaterDispatcher;
	}
	
	function doLaterDispatcher(Void):Void {
		delete onEnterFrame;
		if (this.invalidateFlag) {
			redraw();
		}
		var tmpMethodTable:Array = this.methodTable;
		this.methodTable = new Array();
		if (tmpMethodTable.length>0) {
			var m:Object;
			while ((m=tmpMethodTable.shift()) != undefined) {
				m.obj[m.fn]();
			}
		}
	}
	
	function cancelAllDoLaters(Void):Void {
		delete this.onEnterFrame;
		this.methodTable = new Array();
	}
	
	function invalidate(Void):Void {
		var tmp = this;
		this.invalidateFlag = true;
		this.onEnterFrame = doLaterDispatcher;
	}
	
	function redraw(bAlways:Boolean):Void {
		if (this.invalidateFlag || bAlways) {
			this.invalidateFlag = false;
			draw();
			size();
		}
	}
	
	function initFromClipParameters(Void):Void {
		var bFound:Boolean = false;
		var i:String;
		for (i in this.clipParameters) {
			if (this.hasOwnProperty(i)) {
				bFound = true;
				this["def_"+i] = this[i];
				delete this[i];
			}
		}
		if (bFound) {
			for (i in this.clipParameters) {
				var v = this["def_"+i];
				if (v != undefined) {
					this[i] = v;
				}
			}
		}
	}
	
	private function hideFocus(Void):Void {
		this.focusTimer = 0;
		clearInterval(this.focusInterval);
		this.focus._visible = false;
	}
	
	private function showFocus(Void):Void {
		if (_global.bitFocusTime != undefined) {
			this.focusLimit = _global.bitFocusTime;
		}
		if (this.focusTime != undefined) {
			this.focusLimit = this.focusTime;
		}
		this.focusTimer = 0;
		if (this.focusLimit>=100 && this.tabIndex != undefined) {
			clearInterval(this.focusInterval);
			this.focus._visible = true;
			this.focusInterval = setInterval(this, "checkFocus", 100);
		}
	}
	
	private function checkFocus(Void):Void {
		var tmp = this;
		this.focusTimer = this.focusTimer+100;
		if (this.focusTimer>this.focusLimit) {
			hideFocus();
		}
	}
	
	static function mergeClipParameters(o, p):Boolean {
		for (var i in p) {
			o[i] = p[i];
		}
		return true;
	}
	
	public function remove(Void):Void {
		if (getDepth()>1048575) {
			this.swapDepths(1048575);
		}
		if (getDepth()<0) {
			this.swapDepths(0);
		}
		this.removeMovieClip();
	}
	
	public function setSize(w:Number, h:Number):Void {
		if (w != undefined) {
			this.width = w;
		}
		if (h != undefined) {
			this.height = h;
		}
		this._xscale = 100;
		this._yscale = 100;
		size();
	}
	
	public function set disabledAlpha(a:Number) {
		this.alphaDisabled = a;
		invalidate();
	}
	
	public function get disabledAlpha():Number {
		return (this.alphaDisabled);
	}
	
	
	
	public function set style(s:Object) {
		var _s = s;
		for (var item in _s) {
			if (this[item] != undefined && this[item] != null) {
				this[item] = this[item];
			}
		}
	}
	
	function createChildren() {
	}
	
	function draw() {
	}

}
