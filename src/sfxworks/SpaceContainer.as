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
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SpaceContainer extends MovieClip
	{
		//Stage focus
		private var stagee:Stage;
		
		private static const editframe:int = 7;
		private static const mainFrame:int = 8;
		private static const displayFrame:int = 9;
		
		private var currentSpaceObject:Space;
		private var selectedSpaceFile:File;
		
		private static const desktopFile:File = File.applicationStorageDirectory.resolvePath(".spaces");
		private static const spaceFeed:File = File.applicationStorageDirectory.resolvePath("feed.txt");
		
		
		public function SpaceContainer(stage:Stage) //Intro frames - > Editor frame -> Display Frame
		{
			stop();
			stagee = stage;
			
			if (desktopFile.exists)
			{
				gotoAndStop(mainFrame);
				this.x = (stagee.stageWidth - this.width) / 2;
				navbar_mc.editor_btn.addEventListener(MouseEvent.CLICK, handleGotoEditorClick);
				navbar_mc.loadspace_btn.addEventListener(MouseEvent.CLICK, handleSpaceLoadClick);
				
				//Write to feed handles
				feedinput_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleFeedKeyDown);
			}
			else
			{
				next_btn.addEventListener(MouseEvent.CLICK, handleNextButton);
				back_btn.addEventListener(MouseEvent.CLICK, handleBackButton);
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