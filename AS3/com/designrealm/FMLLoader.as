package com.designrealm.flashml {

	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ErrorEvent;
	
    public dynamic class FMLLoader extends MovieClip
    {
		
		private var loader: Loader;
		public var params: Object;
		public var onComplete: Function;
		public var onFail: Function;
		public var id:uint;

        public function FMLLoader() {
			super();
			loader = new Loader();
        }
		
		public function load(url:String) {
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoadComplete,false,0,true);						
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onLoadError,false,0,true);	
			loader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR,onLoadError,false,0,true);	
			loader.visible = false;
			loader.load(new URLRequest(new String(url)));
		}
		
		private function onLoadComplete(e:Event) {
			loader.removeEventListener(Event.COMPLETE,onLoadComplete);			
			loader.removeEventListener(IOErrorEvent.IO_ERROR,onLoadError);			
			loader.removeEventListener(ErrorEvent.ERROR,onLoadError);
			if (params.obj['id']) loader.name = params.obj['id'];			
			loader.content.cacheAsBitmap = true;
			loader.opaqueBackground = null;
			this.onComplete.apply(params.fml,[id,params.clip,loader,params.obj,params.pw,params.ph]);
			loader.visible = true;
			params = null;
		}
		
		private function onLoadError(e:ErrorEvent) {
			loader.removeEventListener(Event.COMPLETE,onLoadComplete);			
			loader.removeEventListener(IOErrorEvent.IO_ERROR,onLoadError);						
			loader.removeEventListener(ErrorEvent.ERROR,onLoadError);
			this.onFail.apply(params.fml,[e,id,params.obj]);
			params = null;
		}
		
		public function clear() {
			params = null;
			loader.removeEventListener(Event.COMPLETE,onLoadComplete);			
			loader.removeEventListener(ErrorEvent.ERROR,onLoadError);
			loader = null;
			onComplete = null;
			onFail = null;
		}
		
    }
}
