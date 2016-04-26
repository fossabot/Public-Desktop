package sfxworks.services.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SocialNetworkServiceEvent extends Event 
	{
		public static const POST:String = "sonesepost";
		public static const CONNECTED:String  = "soneseconnected";
		private var _message:String;
		private var _from:ByteArray;
		private var _username:String;
		private var _time:Date;
		
		public function SocialNetworkServiceEvent(type:String, message:String="", from:ByteArray=null, username:String="", time:Date=null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, message, from, time, bubbles, cancelable);
			_message = message;
			_from = from;
			_time = time;
			_username = username;
		} 
		
		public override function clone():Event 
		{ 
			return new SocialNetworkServiceEvent(type, _message, _from, _username, _time, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("SocialNetworkServiceEvent", "type", "message", "from", "username", "time", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get message():String 
		{
			return _message;
		}
		
		public function get from():ByteArray 
		{
			return _from;
		}
		
		public function get time():Date 
		{
			return _time;
		}
		
		public function get username():String 
		{
			return _username;
		}
		
	}
	
}