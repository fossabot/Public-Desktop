package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.DesktopObject;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class PublicDesktop extends MovieClip 
	{
		private var f:File;
		private var fs:FileStream;
		private var myidentity:Identity;
		private var communications:Communications;
		private var publicDesktopEditor:PublicDesktopEditor;
		
		private var desktopItems:Vector.<DesktopObject>;
		
		private var profilePicture:File;
		
		public function PublicDesktop(c:Communications)
		{	
			stop();
			
			this.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			
			profilePicture = new File();
			profilePicture = File.applicationStorageDirectory.resolvePath(".profilepicture");
			communications = c;
			overhead_mc.visible = false;
			trace("Started.");
			if (File.applicationStorageDirectory.resolvePath(".desktop13").exists)
			{
				gotoAndStop(4);
				load();
				trace("Exists");
			}
			else
			{
				//gotoAndStop(1);
				trace("Doesnt.");
				yes_btn.addEventListener(MouseEvent.CLICK, handleYes);
				no_btn.addEventListener(MouseEvent.CLICK, handleNo);
				whatis_btn.addEventListener(MouseEvent.CLICK, handleWhatis);
			}
			
		}
		
		
		private function handleWhatis(e:MouseEvent):void 
		{
			yes_btn.removeEventListener(MouseEvent.CLICK, handleYes);
			no_btn.removeEventListener(MouseEvent.CLICK, handleNo);
			whatis_btn.removeEventListener(MouseEvent.CLICK, handleWhatis);
			
			gotoAndStop(2);
			
			back1_btn.addEventListener(MouseEvent.CLICK, handleBack1);
			next_btn.addEventListener(MouseEvent.CLICK, handleNext);
		}
		
		private function handleNext(e:MouseEvent):void 
		{
			next_btn.removeEventListener(MouseEvent.CLICK, handleNext);
			back1_btn.removeEventListener(MouseEvent.CLICK, handleBack1);
			
			gotoAndStop(3);
			
			back2_btn.addEventListener(MouseEvent.CLICK, handleBack2);
			start_btn.addEventListener(MouseEvent.CLICK, handleStart);
		}
		
		private function handleStart(e:MouseEvent):void 
		{
			start_btn.removeEventListener(MouseEvent.CLICK, handleNext);
			back2_btn.removeEventListener(MouseEvent.CLICK, handleBack1);
			
			gotoAndStop(5);
			communications.publicKey.position = 0;
			networkid_txt.text = "";
			for (var i:int = 0; i < 6; i++)
			{
				networkid_txt.appendText(communications.publicKey.readInt().toString() + ".");
			}
			
			input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleNameInputDown);
		}
		
		private function handleinput(e:MouseEvent):void 
		{
			
		}
		
		private function handleBack2(e:MouseEvent):void 
		{
			back2_btn.removeEventListener(MouseEvent.CLICK, handleBack2);
			start_btn.removeEventListener(MouseEvent.CLICK, handleStart);
			
			gotoAndStop(2);
			
			back1_btn.addEventListener(MouseEvent.CLICK, handleBack1);
			next_btn.addEventListener(MouseEvent.CLICK, handleNext);
		}
		
		private function handleBack1(e:MouseEvent):void
		{
			next_btn.removeEventListener(MouseEvent.CLICK, handleNext);
			back1_btn.removeEventListener(MouseEvent.CLICK, handleBack1);
			
			gotoAndStop(1);
		}
		
		private function handleNo(e:MouseEvent):void 
		{
			this.parent.removeChild(this);
		}
		
		private function handleYes(e:MouseEvent):void 
		{
			yes_btn.removeEventListener(MouseEvent.CLICK, handleYes);
			no_btn.removeEventListener(MouseEvent.CLICK, handleNo);
			whatis_btn.removeEventListener(MouseEvent.CLICK, handleWhatis);
			
			gotoAndStop(5);
			
			communications.publicKey.position = 0;
			networkid_txt.text = "";
			for (var i:int = 0; i < 6; i++)
			{
				networkid_txt.appendText(communications.publicKey.readInt().toString() + ".");
			}
			
			input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleNameInputDown);
		}
		
		private var cam:Camera = Camera.getCamera("0");
		private var video:Video = new Video(300, 300);
		private var bitmap:Bitmap;
		private var l:Loader = new Loader();
		
		private var usingImageFromFile:Boolean = new Boolean(false);
		private var usingImageFromCamera:Boolean = new Boolean(false);
		
		private function handleNameInputDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				input_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleNameInputDown);
				communications.nameChange(input_txt.text);
				nextFrame();
				
				skipornext_btn.buttonmode = true;
				back6_btn.addEventListener(MouseEvent.CLICK, handleBack6);
				webcam_btn.addEventListener(MouseEvent.CLICK, getImageFromCamera);
				
				skipornext_btn.buttonMode = true;
				skipornext_btn.addEventListener(MouseEvent.CLICK, handleNextWithOrWithoutImage);
				bitmap = new Bitmap();
				
				imageorvid_mc.addEventListener(MouseEvent.CLICK, handleImageFromFile);
			}
		}
		
		private function handleImageFromFile(e:MouseEvent):void 
		{
			try
			{
				imageorvid_mc.removeChild(bitmap);	
			}
			catch (Error)
			{
				trace("No bitmap");
			}
			
			profilePicture.browse();
			usingImageFromFile = true;
			profilePicture.addEventListener(Event.SELECT, handleProfilePictureSelection);
		}
		
		private function handleProfilePictureSelection(e:Event):void 
		{
			profilePicture.removeEventListener(Event.SELECT, handleProfilePictureSelection);
			l = new Loader();
			var rq:URLRequest = new URLRequest("file://" + profilePicture.nativePath);
			rq.url = rq.url.replace("C:" + File.separator, "/");
			rq.url = rq.url.replace(File.separator, "|");
			rq.url = rq.url.replace("|", "/");
			l.load(rq);
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaderComplete);
			trace("REquest = " + rq.url);
		}
		
		private function handleLoaderComplete(e:Event):void 
		{
			trace("Load complete");
			imageorvid_mc.addChild(l);
		}
			
		private function getImageFromCamera(e:MouseEvent):void 
		{
			imageorvid_mc.removeEventListener(MouseEvent.CLICK, handleImageFromFile);

			video.attachCamera(cam);
			cam.setMode(300, 300, 24);
			imageorvid_mc.addChild(video);
			
			imageorvid_mc.buttonMode = true;
			imageorvid_mc.addEventListener(MouseEvent.CLICK, captureImageFromVideo);
			text_txt.text = "Click on the preview to snap an image.";
			skipornext_btn.text_txt.text = "Skip>>";
			
		}
		
		private function captureImageFromVideo(e:MouseEvent):void 
		{
			imageorvid_mc.removeChild(video);
			var bd:BitmapData = new BitmapData(300,300,true);
			cam.drawToBitmapData(bd);
			bitmap = new Bitmap(bd);
			imageorvid_mc.addChild(bitmap);
			imageorvid_mc.buttonMode = false;
			
			text_txt.text = "Hit next to save, or click the webcam icon again to take another picture.";
			skipornext_btn.text_txt.text = "Next>>";
			
			imageorvid_mc.addEventListener(MouseEvent.CLICK, handleImageFromFile);
		}
		
		private function handleNextWithOrWithoutImage(e:MouseEvent):void 
		{
			back6_btn.removeEventListener(MouseEvent.CLICK, handleBack6);
			webcam_btn.removeEventListener(MouseEvent.CLICK, getImageFromCamera);
			
			nextFrame();
			if (usingImageFromCamera)
			{
				var fs:FileStream = new FileStream();
				var bitmapByte:ByteArray = new ByteArray();
				bitmap.bitmapData.copyPixelsToByteArray(bitmap.getRect(bitmap), bitmapByte);
				
				fs.open(profilePicture, FileMode.WRITE);
				fs.writeBytes(bitmapByte, 0, bitmapByte.length);
				fs.close();
			}
			else if (usingImageFromFile)
			{
				
			}
			
			template4_btn.addEventListener(MouseEvent.CLICK, handleDesktopEditorLaunch);
			back7_btn.addEventListener(MouseEvent.CLICK, handleback7);
		}
		
		private function handleback7(e:MouseEvent):void 
		{
			skipornext_btn.buttonmode = true;
			back6_btn.addEventListener(MouseEvent.CLICK, handleBack6);
			webcam_btn.addEventListener(MouseEvent.CLICK, getImageFromCamera);
			
		}
		
		private function handleDesktopEditorLaunch(e:MouseEvent):void 
		{
			nextFrame();
			publicDesktopEditorInit();
		}
		
		private function publicDesktopEditorInit():void 
		{
			publicDesktopEditor = new PublicDesktopEditor();
			addChild(publicDesktopEditor);
			publicDesktopEditor.width = this.width;
			publicDesktopEditor.height = this.height;
			publicDesktopEditor.config_mc.saveandexit_btn.addEventListener(MouseEvent.CLICK, saveAndExit);
		}
		
		private function saveAndExit(e:MouseEvent):void 
		{
			publicDesktopEditor.config_mc.saveandexit_btn.removeEventListener(MouseEvent.CLICK, saveAndExit);
			trace("Save and exit triggered.");
			publicDesktopEditor.save();
			removeChild(publicDesktopEditor);
			
			gotoAndStop(4);
			gotoEditor_btn.addEventListener(MouseEvent.CLICK, gotoEditor);
			load();
		}
		
		private function gotoEditor(e:MouseEvent):void 
		{
			for each (var desktopItem:DesktopObject in desktopItems)
			{
				removeChild(desktopItem);
			}
			gotoAndStop(8);
			publicDesktopEditorInit();
		}
		
		private function handleBack6(e:MouseEvent):void 
		{
			prevFrame();
			
			communications.publicKey.position = 0;
			networkid_txt.text = "";
			for (var i:int = 0; i < 6; i++)
			{
				networkid_txt.appendText(communications.publicKey.readInt().toString() + ".");
			}
			
			input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleNameInputDown);
		}
		
		private function load():void //Load the desktop from .desktop
		{
			desktopItems = new Vector.<DesktopObject>();
			trace("Load triggered");
			f = new File(); //File for ref
			f = File.applicationStorageDirectory.resolvePath(".desktop13"); //Sourcefile containaing custom desktop
			var fs:FileStream = new FileStream();
			
			fs.open(f, FileMode.READ);
			
			var objectLength:int = fs.readUnsignedInt();
			for (var i:int = 0; i < objectLength; i++) //LENGTH
			{
				trace("for loop triggerd");
				switch(fs.readUTF()) //TYPE
				{
					case "image-from-drive": 
						trace("Adding image from file");
						//Constructor
						var desktopObject:DesktopObject = new DesktopObject(fs.readUTF(), fs.readUTF(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
						desktopObject.addEventListener(MouseEvent.CLICK, handleActions);
						addChild(desktopObject);
						desktopItems.push(desktopObject);
						break;
				}
				
			}
			fs.close();
			
			gotoEditor_btn.addEventListener(MouseEvent.CLICK, gotoEditor);
		}
		
		private function handleActions(e:MouseEvent):void 
		{
			//Paser for actions later
		}
		
		private var focus:Boolean = new Boolean(true);
		private function handleKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 27)
			{
				if (focus == true)
				{
					focus = false;
					overhead_mc.visible = true;
				}
				else
				{
					focus = true;
					overhead_mc.visible = false;
				}
			}
		}
		
		private function parseActions(actions:String, object:DisplayObject):void 
		{
			trace("actions = " + actions);
		}
		
	}

}