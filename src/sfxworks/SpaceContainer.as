package sfxworks 
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SpaceContainer extends MovieClip
	{
		//Stage focus
		private var stagee:Stage;
		
		//Communications
		private var c:Communications;
		
		private static const editframe:int = 7;
		private static const mainFrame:int = 8;
		private static const displayFrame:int = 9;
		
		private var currentSpaceObject:Space;
		private var selectedSpaceFile:File;
		
		private static const desktopFile:File = File.applicationStorageDirectory.resolvePath(".spaces");
		private static const spaceFeed:File = File.applicationStorageDirectory.resolvePath("feed.txt");
		
		
		public function SpaceContainer(stage:Stage, communications:Communications) //Intro frames - > Editor frame -> Display Frame
		{
			stop();
			stagee = stage;
			c = communications;
			
			if (desktopFile.exists)
			{
				gotoAndStop(mainFrame);
				this.x = (stagee.stageWidth - this.width) / 2;
				navbar_mc.editor_btn.addEventListener(MouseEvent.CLICK, handleGotoEditorClick);
				navbar_mc.loadspace_btn.addEventListener(MouseEvent.CLICK, handleSpaceLoadClick);
				navbar_mc.nav_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleNavKeyDown);
				//Write to feed handles
				feedinput_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleFeedKeyDown);
			}
			else
			{
				next_btn.addEventListener(MouseEvent.CLICK, handleNextButton);
				back_btn.addEventListener(MouseEvent.CLICK, handleBackButton);
			}
		}
		
		private function handleNavKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13) //Navbar enter
			{
				var stringKey:String = navbar_mc.nav_txt.text;
				
				navbar_mc.nav_txt.text = "requesting.."
				
				var numbers:Array  = stringKey.split(".");
				var ba:ByteArray = new ByteArray();
				var myIdString:String = new String();
				for (var i:int = 0; i < numbers.length; i++)
				{
					ba.writeDouble(parseFloat(numbers[i]));
					myIdString += c.publicKey[i].toString() + ".";
				}
				var requestedFile:String = stringKey.split("/")[1];
				if (requestedFile != "")
				{
					c.requestObject(ba, "spaceservice," + myIdString + "," + requestedFile);
				}
				else
				{
					c.requestObject(ba, "spaceservice," + myIdString + "," + "default.space");
				}
				
				c.addEventListener(NetworkActionEvent.SUCCESS, handleNavRequestSuccess);
				c.addEventListener(NetworkActionEvent.ERROR, handleNavRequestError);
			}
		}
		
		private function handleNavRequestError(e:NetworkActionEvent):void 
		{
			trace("No target found.");
			
			c.removeEventListener(NetworkActionEvent.SUCCESS, handleNavRequestSuccess);
			c.removeEventListener(NetworkActionEvent.ERROR, handleNavRequestError);
			
			navbar_mc.nav_txt.text = "couldn't find that public key.";
		}
		
		private function handleNavRequestSuccess(e:NetworkActionEvent):void 
		{
			trace("Successfully sent request to target.");
			
			navbar_mc.nav_txt.text = "request sent. waiting for response..";
			
			c.removeEventListener(NetworkActionEvent.SUCCESS, handleNavRequestSuccess);
			c.removeEventListener(NetworkActionEvent.ERROR, handleNavRequestError);
			
			//Add event listener to handle recieved object.
			c.addEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleObjectRecieved);
		}
		
		private function handleObjectRecieved(e:NetworkUserEvent):void 
		{
			//Remove event listener
			c.removeEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleObjectRecieved);
			
			navbar_mc.nav_txt.text = "recieved object.";
			
			var returnResponse:ByteArray = e.message as ByteArray;
			var responseType:String = returnResponse.readUTF();
			
			switch(responseType)
			{
				case "access granted":
					var responseData:ByteArray; //Bytearray containing space data
					returnResponse.readBytes(responseData, returnResponse.position, returnResponse.bytesAvailable);
					//Read part of returnResponse into responseData. Start from it's current position, after it's readUTF()
					//Contains entire array of external files and the origional space file
					
					//Goal: Write all bytearrays to temp files and pass their path to SpaceObject (Or temp directory + )
					
					//Read the space file into the bytearray
					var responseSpace:ByteArray = new ByteArray();
					responseData.readBytes(responseSpace, 0, responseData.readFloat()); 
					
					
					//Write space file to temp file
					var fs:FileStream = new FileStream();
					var tmpSpaceFile:File = File.createTempFile();
					fs.open(tmpSpaceFile, FileMode.WRITE);
					fs.writeBytes(responseSpace);
					fs.close();
					
					//Create temporary directory. Mocks folder structure of source. [Could do it differently to hide username]
					var tmpDir:File = File.createTempDirectory();
					
					//Write files to temporary directory, mocking the structure of the remote user
					var numberOfExternalFiles:Number = responseData.readFloat();
					
					for (var i:Number = 0; i < numberOfExternalFiles; i++)
					{
						//OS TODO: Parse all \ and convert them to proper file.separetor.
						var tmpSourceFile:File = new File(tmpDir.nativePath + responseData.readUTF());
						fs.open(tmpSourceFile, FileMode.WRITE);
						//Start from current position, read the next float to get the length to read
						fs.writeBytes(returnResponse, returnResponse.position, returnResponse.readFloat()); 
						fs.close();
					}
					
					//Create space, pass temporary directory to Space
					var space:Space = new Space(stagee, tmpSpaceFile.nativePath, false, true, tmpDir);
					addChild(space);
					swapChildren(navbar_mc, space);
					currentSpaceObject = space;
					
					this.x = 0;
					this.y = 0;
					break;
				case "access denied":
					navbar_mc.navbar_txt.text = "Access denied..";
					break;
				case "Four,Oh Four..":
					navbar_mc.navbar_txt.text = "Space not found..";
					break;
			}
			
		}
		
		private function handleFeedKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				writeToFeed(feedinput_txt.text);
				feedinput_txt.text = "";
			}
		}
		
		//Write to feed
		public function writeToFeed(message:String):void
		{
			var fs:FileStream = new FileStream();
			fs.open(spaceFeed, FileMode.WRITE);
			fs.writeUTF(message);
			fs.close();
		}
		
		
		public function initSpaceMenu():void //Main menu bar [Triggered on space on exiting]
		{
			//For first runs 
			var fs:FileStream = new FileStream();
			fs.open(desktopFile, FileMode.WRITE);
			fs.writeInt(1);
			fs.close();
			
			//Remove current space object
			currentSpaceObject.removeChildren();
			removeChild(currentSpaceObject);
			currentSpaceObject = null;
			
			gotoAndStop(mainFrame); //Goto MainFrame
			
			this.x = (stagee.stageWidth - this.width) / 2;
			//NavBar Event listeners
			navbar_mc.editor_btn.addEventListener(MouseEvent.CLICK, handleGotoEditorClick);
			navbar_mc.loadspace_btn.addEventListener(MouseEvent.CLICK, handleSpaceLoadClick);
		}
		
		//Handle Display Space
		private function handleSpaceLoadClick(e:MouseEvent):void 
		{
			gotoAndStop(displayFrame);
			selectedSpaceFile = File.applicationStorageDirectory.resolvePath("spaces");
			selectedSpaceFile.browseForOpen("Select a space file.");
			selectedSpaceFile.addEventListener(Event.SELECT, handleSpaceSelection);
			selectedSpaceFile.addEventListener(Event.CANCEL, handleSpaceCancel);
		}
		
		private function handleSpaceSelection(e:Event):void 
		{
			if (currentSpaceObject != null)
			{
				currentSpaceObject.removeChildren();
				removeChild(currentSpaceObject);
			}
			
			selectedSpaceFile.removeEventListener(Event.SELECT, handleSpaceSelection);
			var space:Space = new Space(stagee, selectedSpaceFile.nativePath, false);
			addChild(space);
			swapChildren(navbar_mc, space);
			currentSpaceObject = space;
			
			this.x = 0;
			this.y = 0;
		}
		
		
		//Handle Cancel 
		private function handleSpaceCancel(e:Event):void 
		{
			selectedSpaceFile.removeEventListener(Event.CANCEL, handleSpaceCancel);
			gotoAndStop(mainFrame);
		}
		
		//Handle Editor
		
		private function handleGotoEditorClick(e:MouseEvent):void 
		{
			gotoAndStop(editframe);
			selectedSpaceFile = File.applicationStorageDirectory.resolvePath("spaces");
			selectedSpaceFile.browseForOpen("Select a space file to start editing.");
			selectedSpaceFile.addEventListener(Event.SELECT, handleSpaceSelectionForEditing);
			selectedSpaceFile.addEventListener(Event.CANCEL, handleSpaceCancel);
		}
		
		private function handleSpaceSelectionForEditing(e:Event):void 
		{
			if (currentSpaceObject != null)
			{
				currentSpaceObject.removeChildren();
				removeChild(currentSpaceObject);
			}
			
			selectedSpaceFile.removeEventListener(Event.SELECT, handleSpaceSelectionForEditing);
			gotoAndStop(editframe);
			var space:Space = new Space(stagee, selectedSpaceFile.nativePath, true);
			space.editMode();
			addChild(space);
			currentSpaceObject = space;
			this.x = 0;
			this.y = 0;
		}
		
		//First desktop editor launch
		private function beginFirstDesktop(e:MouseEvent):void 
		{
			//Right click to launch menu
			removeEventListener(MouseEvent.CLICK, beginFirstDesktop);
			gotoAndStop(editframe);
			var space:Space = new Space(stagee);
			space.editMode();
			addChild(space);
			this.x = 0;
			this.y = 0;
			currentSpaceObject = space;
		}
		
		//Navigation
		private function handleNextButton(e:MouseEvent):void 
		{
			if (currentFrame == 5)
			{
				next_btn.removeEventListener(MouseEvent.CLICK, handleNextButton);
				back_btn.removeEventListener(MouseEvent.CLICK, handleBackButton);
				
				addEventListener(MouseEvent.CLICK, beginFirstDesktop);
			}
			if (currentFrame != 1) //Back button is visible
			{
				back_btn.visible = true;
			}
			nextFrame();
		}
		
		private function handleBackButton(e:MouseEvent):void 
		{
			prevFrame();
			if (currentFrame == 1) //Back button goes invis if it's on the first frame
			{
				back_btn.visible = false;
			}
		}
		//Resize UTIL
		private function resize(mc:DisplayObject, maxW:Number, maxH:Number = 0, constrainProportions:Boolean = true):void
		{
			maxH = maxH == 0 ? maxW : maxH;
			mc.width = maxW;
			mc.height = maxH;
			if (constrainProportions)
			{
				mc.scaleX < mc.scaleY ? mc.scaleY = mc.scaleX : mc.scaleX = mc.scaleY;
			}
		}
		
	}

}