package sfxworks.services 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DesktopServiceEvent extends Event 
	{
		public static const SPACE_OBJECT_RECIEVED:String = "desespacefilerecieved";
		public static const RESOURCE_OBJECT_RECIEVED:String = "deseresourcefilerecieved";
		
		private var _fileName:String;
		private var _part:Number;
		private var _max:Number;
		
		public function DesktopServiceEvent(type:String, fileName:String, part:Number, max:Number, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_fileName = fileName;
			_part = part;
			_max = max;
		} 
		
		public override function clone():Event 
		{ 
			return new DesktopServiceEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DesktopServiceEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get part():Number 
		{
			return _part;
		}
		
		public function get max():Number 
		{
			return _max;
		}
		
		public function get fileName():String 
		{
			return _fileName;
		}
		
	}
	
}