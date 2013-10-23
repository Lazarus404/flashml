package com.designrealm.flashml {

	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.getDefinitionByName;

	
    public dynamic class FMLTag     {
		
		public var classname: Class;
		public var params: Object;
		public var onComplete: Function;
		public var onFail: Function;
		public var id:uint;

		private var object: Object;
		
        public function FMLTag() {
        }
		
		public function create() {
			try { 
				object = new classname(params); 
			} 
			catch(e) { 
				return null;
			}
			return object;	
		}
		
		public function generate() {
			object.addEventListener(FMLEvent.COMPLETE,onLoadComplete,false,0,true);
			object.addEventListener(ErrorEvent.ERROR,onLoadError,false,0,true);
			object.generate();
		}
		
		private function onLoadComplete(e:FMLEvent) {
			object.removeEventListener(FMLEvent.COMPLETE,onLoadComplete);			
			object.removeEventListener(ErrorEvent.ERROR,onLoadError);
			this.onComplete.apply(params.fml,[id,params.clip,object,params.obj,params.pw,params.ph]);
			params = null;
		}
		
		private function onLoadError(e:ErrorEvent) {
			object.removeEventListener(FMLEvent.COMPLETE,onLoadComplete);			
			object.removeEventListener(ErrorEvent.ERROR,onLoadError);
			this.onFail.apply(params.fml,[e,id,params.obj]);
			params = null;
		}
				
		public function clear() {
			params = null;
			classname = null;
			if (object != null) {
				object.removeEventListener(FMLEvent.COMPLETE,onLoadComplete);			
				object.removeEventListener(ErrorEvent.ERROR,onLoadError);
			}
			onComplete = null;
			onFail = null;
			object = null;
		}
    }
}
