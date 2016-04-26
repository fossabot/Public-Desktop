package sfxworks.services.events 
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
		private var _filePath:String;
		private var _fileIdStart:Number;
		private var _fileIdEnd:Number;
		private var _groupId:Number;
		
		public function FileSharingEvent(type:String, info:String = null, filePath:String = null, fileIdStart:Number = -1, fileIdEnd:Number = -1, groupId:Number = -1, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			_info = info;
			_filePath = filePath;
			_fileIdStart = fileIdStart;
			_fileIdEnd = fileIdEnd;
			_groupId = groupId;
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new FileSharingEvent(type, _info, _filePath, _fileIdStart, _fileIdEnd, _groupId, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("FileSharingEvent", "type", "info", "fileName", "fileIdStart", "fileIdEnd", "groupId", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get info():String 
		{
			return _info;
		}
		
		public function get filePath():String 
		{
			return _filePath;
		}
		
		public function get fileIdStart():Number 
		{
			return _fileIdStart;
		}
		
		public function get fileIdEnd():Number 
		{
			return _fileIdEnd;
		}
		
		public function get groupId():Number 
		{
			return _groupId;
		}
		
	}
	
}