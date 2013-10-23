package com.designrealm.flashml {
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fl.events.ComponentEvent;	
	
	public class FMLEvent extends flash.events.Event {
		
		public static const LOAD_SUCCESS:String = 'load_success';
		public static const LOAD_FAILED:String = 'load_failed';
		public static const PARSED:String = 'parsed';
		public static const STYLES_LOAD_SUCCESS:String = 'styles_load_success';
		public static const STYLES_LOAD_FAILED:String = 'styles_load_failed';
		public static const STYLES_PARSED:String = 'styles_parsed';
		public static const COMPLETE:String = 'complete';
		public static const TAG_COMPLETE:String = 'tag_complete';
		public static const GENERATE:String = 'generate';
		
		private var _args:Object;
		private var _text:String;

        public function FMLEvent(type:String, __args:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
         	this._args = __args;
        }		
		
		// Override clone
		override public function clone():Event {
			return new FMLEvent(type, _args, bubbles, cancelable);
		}

		public function set text(__text:String):void {
			_text = __text;
		}
		
		public function get text():String {
			return _text;
		}

	}

}