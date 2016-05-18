package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class CLCEvent extends Event 
	{
		public static const MESSAGE:String = "clcmessage";
		private var _message:Object;
		
		public function CLCEvent(type:String, message:Object, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_message = message;
		} 
		
		public override function clone():Event 
		{ 
			return new CLCEvent(type, message, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("CLCEvent", "type", "message", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get message():Object 
		{
			return _message;
		}
		
	}
	
}