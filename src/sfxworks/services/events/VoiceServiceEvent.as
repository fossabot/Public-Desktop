package sfxworks.services.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class VoiceServiceEvent extends Event 
	{
		public static const USER_CONNECTED:String = "vseuc";
		public static const USER_DISCONNECTED:String = "vseudc";
		public static const USER_NAMECHANGE:String = "vseunc";
		public static const USER_AUDIO_ACTIVITY:String = "vseaa";
		
		private var _name:String;
		private var _newName:String;
		private var _bytes:Number;
		
		public function VoiceServiceEvent(type:String, name:String, newName:String = "", bytes:Number = 0, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			super(type, bubbles, cancelable);
			_name = name;
			_newName = newName;
			_bytes = bytes;
		} 
		
		public override function clone():Event 
		{ 
			return new VoiceServiceEvent(type, _name, _newName, _bytes, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("VoiceServiceEvent", "type", "name", "newName", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function get newName():String 
		{
			return _newName;
		}
		
		public function get bytes():Number 
		{
			return _bytes;
		}
		
	}
	
}