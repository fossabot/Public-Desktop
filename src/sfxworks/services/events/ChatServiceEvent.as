package sfxworks.services.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class ChatServiceEvent extends Event 
	{
		public static const CHAT_MESSAGE:String = "csmessage";
		
		private var _nearID:String;
		private var _name:String;
		private var _message:String;
		
		public function ChatServiceEvent(type:String, nearID:String=null, name:String=null, message:String=null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_nearID = nearID;
			_name = name;
			_message = message;
		} 
		
		public override function clone():Event 
		{ 
			return new ChatServiceEvent(type, _nearID, _name, _message, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ChatServiceEvent", "type", "nearid", "name", "message", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}