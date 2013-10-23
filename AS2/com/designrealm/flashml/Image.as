import mx.events.EventDispatcher;

class com.designrealm.flashml.Image extends MovieClip {
	
	private var listener;
	private var loader;
	private var mc;
	public var _width, _height;
	
	function Image() {
		
		listener = new Object;
		listener.scope = this;
		
		listener.onLoadInit = function(mc) {
			this.scope._width = mc._width;
			this.scope._height = mc._height;
			this.scope.complete();
		}
		
		listener.onLoadError = function(mc) {
			trace("Unable to load image");
			this.scope.complete();
		}
		
		loader = new MovieClipLoader();
		loader.addListener(listener);
		EventDispatcher.initialize(this);
		
	}
	
	function load(src) {
		_load.applyDelay(2,this,[src]);
	}
	
	function _load(src) {
		this.mc = this.createEmptyMovieClip("mc",0);
		loader.loadClip(src,mc);
		
	}
	
	function complete() {
		delete listener;
		delete loader;
		trace("loaded!");
		this.dispatchEvent({type:"done"});
	}
	
	
	
}