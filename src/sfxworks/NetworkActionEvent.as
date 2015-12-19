package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkActionEvent extends Event 
	{
		private var _info:Object;
		
		public static const SUCCESS:String = "success";
		public static const FAILED:String = "failed";
		public static const ERROR:String = "error";
		public static const REFRESH:String = "refresh";
		
		public function NetworkActionEvent(type:String, info:Object, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_info = info;
			
		} 
		
		public override function clone():Event 
		{ 
			return new NetworkActionEvent(type, _info, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NetworkActionEvent", "type", "info", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get info():Object 
		{
			return _info;
		}
		
	}
	
}