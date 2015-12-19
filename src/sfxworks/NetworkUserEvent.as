package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkUserEvent extends Event 
	{
		private var _message:Object;
		private var _name:String;
		
		public static const MESSAGE:String = new String("message");
		public static const CALLING:String = new String("calling");
		public static const INCOMMING_CALL:String = new String("incommingcall");
		public static const OBJECT_REQUEST:String = new String("objectrequest");
		public static const OBJECT_SENDING:String = new String("objectsending");
		public static const OBJECT_RECIEVED:String = new String("objectrecieved");
		
		public function NetworkUserEvent(type:String, name:String, message:Object, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			_message = message;
			_name = name;
			super(type, bubbles, cancelable);
			//What is a netgroup replication strategy
		} 
		
		public override function clone():Event 
		{ 
			return new NetworkUserEvent(type, _name, _message, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NetworkUserEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get message():Object 
		{
			return _message;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
	}
	
}