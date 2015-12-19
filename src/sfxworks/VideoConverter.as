package sfxworks 
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class VideoConverter extends EventDispatcher 
	{
		private var npsi:NativeProcessStartupInfo;
		private var np:NativeProcess;
		
		private var videoToConvert:File;
		
		public function VideoConverter(target:flash.events.IEventDispatcher=null) 
		{
			super(target);
			npsi = new NativeProcessStartupInfo();
			np = new NativeProcess();
		}
		
		public function convertVideo(path:String, outputName:String):void
		{
			//Arguments for converting video in ffmpeg [-i pathtovideo pathtostoragedirectory]
			npsi.arguments = new Vector.<String>["-i", path, File.applicationStorageDirectory.resolvePath("videos" + File.separator + outputName + ".flv").nativePath]):
			//Path to ffmpeg /bin/ffmpeg/ffmpeg.exe
			npsi.executable = File.applicationDirectory.resolvePath("bin" + File.separator + "ffmpeg" + File.separator + "bin" + File.separator + "ffmpeg.exe");
			
			//Process handler
			np.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, handleStandardOutputData);
			np.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, handleStandardErrorData);
			np.start(npsi); //Start process
		}
		
		private function handleStandardErrorData(e:ProgressEvent):void 
		{
			var stdOut:ByteArray = np.standardError; 
			var data:String = stdOut.readUTFBytes(np.standardError.bytesAvailable);
			
			dispatchEvent(new NativeProcessEvent(NativeProcessEvent.ERROR_DATA, data));
		}
		
		private function handleStandardOutputData(e:ProgressEvent):void 
		{
			var stdOut:ByteArray = np.standardOutput; 
			var data:String = stdOut.readUTFBytes(np.standardOutput.bytesAvailable);
			
			dispatchEvent(new NativeProcessEvent(NativeProcessEvent.OUTPUT_DATA, data));
		}
		
	}

}