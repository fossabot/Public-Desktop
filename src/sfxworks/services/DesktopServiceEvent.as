package sfxworks.services 
{
	import flash.events.Event;
	import flash.filesystem.File;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DesktopServiceEvent extends Event 
	{
		public static const SPACE_OBJECT_RECIEVED:String = "desespacefilerecieved";
		public static const RESOURCE_OBJECT_RECIEVED:String = "deseresourcefilerecieved";
		public static const PERMISSIONS_ERROR:String = "deseepermissoinserror";
		
		private var _file:File;
		private var _part:Number;
		private var _max:Number;
		private var _extension:String;
		
		public function DesktopServiceEvent(type:String, file:File=null, part:Number=-1, max:Number=-1, extension:String="", bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_file = file;
			_part = part;
			_max = max;
			_extension = extension;
		} 
		
		public override function clone():Event 
		{ 
			return new DesktopServiceEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DesktopServiceEvent", "type", "file", "part", "max", "extension", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get part():Number 
		{
			return _part;
		}
		
		public function get max():Number 
		{
			return _max;
		}
		
		public function get file():File 
		{
			return _file;
		}
		
		public function get extension():String 
		{
			return _extension;
		}
		
	}
	
}