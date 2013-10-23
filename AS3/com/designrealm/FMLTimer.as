package com.designrealm.flashml {

	import flash.events.TimerEvent;
    import flash.utils.Timer;
	
    public dynamic class FMLTimer   {
		
		private var timer:Timer;
		public var params: Object;
		public var target: Object;
		public var onComplete: Function;
		public var id:uint;
		
        public function FMLTimer(delay:Number = 1000) {
			timer = new Timer(delay);
			timer.addEventListener(TimerEvent.TIMER, onTimerComplete,false,0,true);
        }
		
		public function start() {
			timer.start();
		}
		
		private function onTimerComplete(e) {
			timer.removeEventListener(TimerEvent.TIMER,onTimerComplete);
			timer.stop();
			this.onComplete.apply(this.params.fml,[id,params.clip,target,params.obj,params.pw,params.ph]);
			params = null;
		}
		
		public function clear() {
			if (timer != null) timer.removeEventListener(TimerEvent.TIMER,onTimerComplete);
			timer = null;
			onComplete = null;
		}
		
    }
}
