package 
{
	import flash.filesystem.File;
	/**
	 * ...
	 * @author ...
	 */
	public class MusicPlayer 
	{
		private var musicDirectory:Vector.<File>; //For accessing of multible music directories.
		private var musicListing:File;
		
		
		
		public function MusicPlayer() 
		{
			musicListing = File.applicationStorageDirectory.resolvePath(".music");
			
		}
		
	}

}