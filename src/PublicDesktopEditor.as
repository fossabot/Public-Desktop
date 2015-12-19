package  
{
	import TransformTool;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.media.Video;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import flash.filesystem.File;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class PublicDesktopEditor extends MovieClip
	{
		private var desktopSource:Vector.<String>;
		private var desktopType:Vector.<String>;
		private var desktopObjects:Vector.<DisplayObject>;
		
		private var allEditableObjects:Array;
		
		private var f:File;
		private var fs:FileStream;
		
		private var rightMouseX:int; //Position of Mouse
		private var rightMouseY:int; //For positioning of adding objects
		
		private var fileToDisplay:File;
		private var objectType:String;
		
		//Temp vars
		private var selectedEditableObject:EditableObject;
		
		public function PublicDesktopEditor() //rightmenu_mc (all object types) | prompt_mc prompt_mc.input_txt
		{
			fs = new FileStream();
			desktopType = new Vector.<String>();
			desktopSource = new Vector.<String>();
			desktopObjects = new Vector.<DisplayObject>();
			allEditableObjects = new Array();
			//RightClickMenu (stage)
			background_mc.addEventListener(MouseEvent.RIGHT_CLICK, rightClickHandler); //background only. If a new object handle right click differently.
			//or via switch
			
			desktopObjects = new Vector.<DisplayObject>();
			//All objects on the stage.
			
			//Links come later.
			
			rightmenu_mc.visible = false;
			prompt_mc.visible = false;
			
			f = File.applicationStorageDirectory.resolvePath(".desktop13");
			if (f.exists)
			{
				trace("Loading pre existing desktop");
				load();
			}
			
		}
		
		private function rightClickHandler(e:MouseEvent):void //Visible when user right clicks on stage to add object
		{
			rightmenu_mc.visible = true;
			rightmenu_mc.x = e.localX;
			rightmenu_mc.y = e.localY;
			
			rightMouseX = e.localX;
			rightMouseY = e.localY;
			
			rightmenu_mc.addEventListener(MouseEvent.CLICK, rightMenuHandler);
			rightmenu_mc.addEventListener(MouseEvent.ROLL_OUT, handleRightMenuOut);
		}
		
		private function handleRightMenuOut(e:MouseEvent):void 
		{
			rightmenu_mc.visible = false;
			
			rightmenu_mc.removeEventListener(MouseEvent.CLICK, rightMenuHandler);
			rightmenu_mc.removeEventListener(MouseEvent.ROLL_OUT, handleRightMenuOut);
		}
		
		private function rightMenuHandler(e:MouseEvent):void 
		{
			rightmenu_mc.removeEventListener(MouseEvent.CLICK, rightMenuHandler);
			
			fileToDisplay = new File();
			objectType = new String();
			
			var iFilter:FileFilter = new FileFilter("Images", "*.jpg;*.gif;*.png;*.jpeg;*.bmp");
			var vFilter:FileFilter = new FileFilter("Videos", "*.mp4;*.m4v;*.f4v;*.3gpp;*.flv");
			
			var imageFilter:Array = new Array();
			imageFilter.push(iFilter);
			
			var videoFilter:Array = new Array();
			videoFilter.push(vFilter);
			
			fileToDisplay = new File();
			
			switch(e.target.name)
			{
				case "imagefromdrive":
					fileToDisplay.browseForOpen("Image to add?", imageFilter);
					fileToDisplay.addEventListener(Event.SELECT, handleSelection);
					objectType = "image-from-drive";
					break;
				case "videofromdrive":
					fileToDisplay.browseForOpen("Video to display", videoFilter);
					fileToDisplay.addEventListener(Event.SELECT, handleSelection);
					objectType = "video-from-drive";
					break;
				case "imagefromlink":
					prompt_mc.visible = true;
					prompt_mc.okay_btn.addEventListener(MouseEvent.CLICK, clickHandler);
					objectType = "image-from-link";
					break;
				case "embeddedobjecet": //Cause fuck all the apis for now
					prompt_mc.visible = true;
					prompt_mc.okay_btn.addEventListener(MouseEvent.CLICK, clickHandler);
					objectType = "embedded-object";
					break;
				case "text":
					
					//Handle text boxes and extending (they should do it automatically)
					break;
			}
		}
		
		private function handleSelection(e:Event):void //For file selection of text/video from embedded objects
		{
			fileToDisplay.removeEventListener(Event.SELECT, handleSelection);
			handleObject();
		}
		
		private function clickHandler(e:MouseEvent):void //For linked text/video after promot
		{
			prompt_mc.removeEventListener(MouseEvent.CLICK, clickHandler);
			prompt_mc.visible = false;
			
			handleObject(prompt_mc.input_txt.text);
		}
		
		private var l:Loader = new Loader();
		private var eo:EditableObject;
		private function handleObject(args:String=""):void //Handling objects passed by Right Menu Handler
		{
			eo = new EditableObject(objectType, fileToDisplay.nativePath)
			switch(objectType)
			{
				case "image-from-drive":
					//Main object
					var raw:ByteArray = new ByteArray();
					var fs:FileStream = new FileStream();
					fs.open(fileToDisplay, FileMode.READ);
					fs.readBytes(raw, 0, fileToDisplay.size);
					fs.close();
					l.loadBytes(raw);  //Needs testing
					l.contentLoaderInfo.addEventListener(Event.COMPLETE, handleComplete);
					
					break;
				case "video-from-drive":
					//Construct
					var vp:VideoPlayer = new VideoPlayer(fileToDisplay.nativePath); //Main object
					
					//Index
					desktopType.push("video-from-drive");
					desktopSource.push(fileToDisplay.nativePath);
					
					//Add to Editable Object
					eo.addChild(vp);
					break;
				case "embedded-object":
					//Save first. Need to save the file to load it in HTMLLoader
					f = new File();
					f = File.applicationStorageDirectory.resolvePath("embedds" + File.separator + File.createTempFile().name); //might need to generate unique name
					fs.open(f, FileMode.WRITE);
					fs.writeUTF(args);
					fs.close();
					
					//Construct
					var htmlLoader:HTMLLoader = new HTMLLoader(); //Main object
					htmlLoader.width = 320;
					htmlLoader.height = 240;
					htmlLoader.load(new URLRequest("File://" + f.nativePath.split("C:")[1]));
					
					
					//Index
					desktopSource.push(args);
					desktopType.push("embedded-object");
					
					//Add to Editable Object
					eo.addChild(htmlLoader);
					break;
				case "text": //wow
					//Construct [such wow such class much amaze]
					var textField:TextField = new TextField();
					
					//Save after really...
					
					//Index
					desktopSource.push("REFERENCE_TEXTFIELD");
					desktopType.push("text");
					
					//Add child
					addChild(textField);
					allEditableObjects.push(textField);
					break;
			}
			
			//Position EO at mouse x and y
			eo.x = rightMouseX;
			eo.y = rightMouseY;
			
			//Add EO to stage
			addChild(eo);
			
			//Index EO
			allEditableObjects.push(eo);
			
			
			//Clear RAM
			f = null;
			eo.addEventListener(MouseEvent.CLICK, handleEOClick);
			eo.buttonMode = true;
			selectedEditableObject = eo;
		}
		
		
		//If an editable object is clicked
		private function handleEOClick(e:MouseEvent):void 
		{
			selectedEditableObject.addEventListener(MouseEvent.CLICK, handleEOClick);
			selectedEditableObject.removeEventListener(Event.ENTER_FRAME, updateProperties);
			selectedEditableObject = e.currentTarget as EditableObject;
			e.currentTarget.removeEventListener(MouseEvent.CLICK, handleEOClick);
			selectedEditableObject.addEventListener(Event.ENTER_FRAME, updateProperties);
			
			config_mc.type_txt.text = selectedEditableObject.typee.toString();
			config_mc.x_txt.text = selectedEditableObject.x.toString();
			config_mc.y_txt.text = selectedEditableObject.y.toString();
			config_mc.width_txt.text = selectedEditableObject.width.toString();
			config_mc.height_txt.text = selectedEditableObject.height.toString();
			config_mc.image_mc.removeChildren(1);
			config_mc.image_mc.addChild(selectedEditableObject.imageRep);
			config_mc.nativePath_txt.text = selectedEditableObject.nativePath;
			resizeMe(config_mc.image_mc.getChildAt(1) as MovieClip, 75, 46);
			config_mc.image_mc.getChildAt(1).x += 2;
		}
		
		
		private function updateProperties(e:Event):void 
		{
			config_mc.type_txt.text = selectedEditableObject.typee;
			config_mc.x_txt.text = selectedEditableObject.x.toString();
			config_mc.y_txt.text = selectedEditableObject.y.toString();
			config_mc.width_txt.text = selectedEditableObject.width.toString();
			config_mc.height_txt.text = selectedEditableObject.height.toString();
		}
		
		
		private function handleComplete(e:Event):void 
		{
			//Add to Editable Object
			eo.addDisplay(l.content);
			
		}
		//properties bar (handle text display embedd code and such)
		
		public function save():void
		{
			trace("Init save from publicdesktop editor");
			f = new File();
			f = File.applicationStorageDirectory.resolvePath(".desktop13");
			
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			
			//First byte will be the number of objects in the file
			fs.writeUnsignedInt(allEditableObjects.length);
			trace("Saving length to " + allEditableObjects.length);
			for (var i:int = 0; i < allEditableObjects.length; i++)
			{
				trace("Writing object");
				fs.writeUTF(allEditableObjects[i].typee); //UTF Type
				fs.writeUTF(allEditableObjects[i].text); //UTF Text
				fs.writeUTF(allEditableObjects[i].nativePath); //UTF path 
				fs.writeDouble(allEditableObjects[i].x); //X as 32 bit signed int
				fs.writeDouble(allEditableObjects[i].y); //Y
				fs.writeDouble(allEditableObjects[i].width); //height
				fs.writeDouble(allEditableObjects[i].height); //width
				
				//No need to divide since the order is set
				
				trace("Type = " + allEditableObjects[i].typee);
				trace("text = " + allEditableObjects[i].text);
				trace("nativePath = " + allEditableObjects[i].nativePath);
				trace("x = " + allEditableObjects[i].x);
				trace("y = " + allEditableObjects[i].y);
				trace("width = " + allEditableObjects[i].width);
				trace("height = " + allEditableObjects[i].height);
				
			}
			
			fs.close(); //Type || Source || x y h w
			
			trace("Complete.");
		}
		
		private function load():void //Load the desktop from .desktop
		{
			trace("Load triggered");
			f = new File(); //File for ref
			f = File.applicationStorageDirectory.resolvePath(".desktop13"); //Sourcefile containaing custom desktop
			var fs:FileStream = new FileStream();
			
			fs.open(f, FileMode.READ);
			
			var objectLength:int = fs.readUnsignedInt();
			for (var i:int = 0; i < objectLength; i++) //LENGTH
			{
				var transformTool:TransformTool = new TransformTool();
				var eo:EditableObject = new EditableObject("", "");
				eo.handleSavedObject(fs.readUTF(), fs.readUTF(), fs.readUTF(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
				addChild(eo);
				eo.addEventListener(MouseEvent.CLICK, handleEOClick);
				eo.buttonMode = true;
				selectedEditableObject = eo;
				allEditableObjects.push(eo);
				
				transformTool.target = eo;
				addChild(transformTool);
			}
			fs.close();
		}
		
		private function parseActions(actions:String, object:DisplayObject):void 
		{
			
		}
		
		private function resizeMe(mc:MovieClip, maxW:Number, maxH:Number = 0, constrainProportions:Boolean = true):void
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