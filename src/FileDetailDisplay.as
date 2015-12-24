package 
{
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FileDetailDisplay extends MovieClip 
	{
		
		private var _path:String;
		
		private var t:Timer;
		
		public function FileDetailDisplay(path:String, group:Number, start:Number, end:Number) 
		{
			_path = path;
			var file:File = new File(path);
			filename_txt.text = file.name;
			fileid_txt.text = group.toString() + ":" + start.toString() + "-" + end.toString();
			url_txt.text = "http://sfxworks.net/files.php?id=" + fileid_txt.text;
		}
		
		public function failedToAddFile():void
		{
			//Text says failed to add file
			t = new Timer(3000);
			t.addEventListener(TimerEvent.TIMER, handleTimer);
		}
		
		//Remove files
		private function handleTimer(e:TimerEvent):void 
		{
			
		}
		
		public function get path():String 
		{
			return _path;
		}
		
	}

}