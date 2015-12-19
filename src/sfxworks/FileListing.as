package sfxworks 
{
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FileListing extends MovieClip 
	{
		private var _filePath:String;
		private var _fileName:String;
		
		public function FileListing(path:String) 
		{
			super();
			_filePath = path;
			
		}
		
		public function recieveSuccessful():void
		{
			//Change bar to different color to show success
			//Maybe add event listener to openWithDefaultApplication()
		}
		
		public function get filePath():String 
		{
			return _filePath;
		}
		
		public function get fileName():String 
		{
			return _fileName;
		}
		
	}

}