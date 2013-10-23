package com.designrealm.flashml {

	import flash.display.Sprite;
	import flash.events.Event;

    public dynamic class FMLMovieClipLoader extends Sprite {
		
		public var params: Object;
		public var onComplete: Function;
		public var cls:Object;
		public var id:uint;
		
		private var mc;
		
        public function FMLMovieClipLoader(delay:Number = 1000) {
			super();
        }
		
		public function load() {
			mc = new cls();
			if (params.obj['id']) mc.name = params.obj['id'];
			if (mc != null) mc.addEventListener(Event.ADDED_TO_STAGE,onLoadComplete);
			params.clip.addChild(mc);
		}
		
		private function onLoadComplete(e) {
			if (!isNaN(Number(params.obj.width))) mc.width = Number(params.obj.width);
			if (!isNaN(Number(params.obj.height))) mc.height = Number(params.obj.height);
			this.onComplete.apply(this.params.fml,[id,params.clip,mc,params.obj,params.pw,params.ph]);
			params = null;
		}
		
		public function clear() {
			if (params.clip != null && mc != null) mc.removeEventListener(Event.ADDED_TO_STAGE,onLoadComplete)
			params = null;
			onComplete = null;
			mc = null;
		}
		
    }
}
