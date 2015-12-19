package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkEvent extends Event 
	{
		private var _nearID:String;
		public static const CONNECTED:String = new String("connected");
		public static const DISCONNECTED:String = new String("disconnected");
		public static const ERROR:String = new String("error");
		public static const CONNECTING:String = new String("connecting");
		
		public function NetworkEvent(type:String, nearID:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			_nearID = nearID;
			super(type, bubbles, cancelable);
		} 
		
		public override function clone():Event 
		{ 
			return new NetworkEvent(type, _nearID, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NetworkEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get nearID():String 
		{
			return _nearID;
		}
		
	}
	
}