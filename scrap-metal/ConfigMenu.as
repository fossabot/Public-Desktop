package 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Camera;
	import flash.media.Microphone;
	import sfxworks.Communications;
	/**
	 * ...
	 * @author ...
	 */
	public class ConfigMenu extends MovieClip
	{
		private var logFile:File;
		private var logFs:FileStream;
		
		private var cameraSelection:Selection;
		private var microphoneSelection:Selection;
		
		private var comm:Communications;
		
		public function ConfigMenu(c:Communications, bg:background) 
		{
			stop();
			next_btn.addEventListener(MouseEvent.CLICK, handleNext);
			back_btn.addEventListener(MouseEvent.CLICK, handleBack);
			
			comm = c;
			
			this.x = 100;
			this.y = 100;
			logFile = new File();
			logFile = File.applicationStorageDirectory.resolvePath("log8.txt");
			logFs = new FileStream();
			
			logFs.open(logFile, FileMode.READ);
			log_txt.appendText(logFs.readUTFBytes(logFile.size));
			logFs.close();
			log_txt.scrollV = log_txt.maxScrollV;
			
			//Camera support
			cameraSelection = new Selection("Select Camera", Camera.names);
			addChild(cameraSelection);
			cameraSelection.x = 88;
			cameraSelection.y = 30;
			
			//Microphone support
			microphoneSelection = new Selection("Select Microphone", Microphone.names);
			addChild(microphoneSelection);
			microphoneSelection.x = 80;
			microphoneSelection.y = 142;
			
			
			//Close
			close_btn.addEventListener(MouseEvent.CLICK, handleClose);
			
			
		}
		
		private function handleBack(e:MouseEvent):void 
		{
			prevFrame();
		}
		
		private function handleNext(e:MouseEvent):void 
		{
			nextFrame();
		}
		
		private function handleClose(e:MouseEvent):void 
		{
			//comm.configureCamera(cameraSelection.selection);
			//comm.configureMicrophone(new int(microphoneSelection.selection));
			this.parent.removeChild(this);
		}
		
	}

}