package sfxworks.services 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FileSharingEvent extends Event 
	{
		public static const READY:String = "ready";
		public static const ERROR:String = "error";
		public static const FILE_ADDED:String = "fileAdded";
		public static const FILE_PART_DOWNLOADED:String = "filePartDownloaded";
		public static const FILE_DOWNLOADED:String = "fileDownloaded";
		
		private var _info:String;
		
		public function FileSharingEvent(type:String, info:String=null, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			_info = info;
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new FileSharingEvent(type, _info, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("FileSharingEvent", "type", "info", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get info():String 
		{
			return _info;
		}
		
	}
	
}