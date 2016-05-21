package sfxworks 
{
	import TransformTool;
	import by.blooddy.crypto.MD5;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 * 
	 * Permissions Format
	 * allow(args)
	 * deny(args)
	 * 
	 * constants: all
	 * example:
	 * allow(all)
	 * deny(1002030.1203021.02130123.01230213.03042123.02312401, 1230892.213214124.21321312.431431.213124214.12312312)
	 * 
	 */
	public class Space extends MovieClip 
	{
		private var stagee:Stage;
		
		private var spacename:String;
		private var spacepermissions:String;
		private var spacedata:File;
		private var _access:String;
		
		private var editTool:TransformTool;
		private var _editMode:Boolean;
		
		//Objects on stage
		public var spaceObjects:Vector.<SpaceObject>;
		private var selectedSpaceObject:SpaceObject;
		
		public function Space(stage:Stage, spaceToLoad:String="", editMode:Boolean=false, ext:Boolean=false):void
		{
			stagee = stage;
			_editMode = editMode;
			embed_mc.visible = false;
			rightmenu_mc.visible = false;
			config_mc.visible = false;
			
			spaceObjects = new Vector.<SpaceObject>();
			if (spaceToLoad != "")
			{
				spacedata = new File(spaceToLoad);
				var fs:FileStream = new FileStream();
				fs.open(spacedata, FileMode.READ);
				
				//Load the space based on the data
				var numberOfObjects:Number = fs.readDouble();
				spacepermissions = fs.readUTF();
				
				for (var i:int = 0; i < numberOfObjects; i++)
				{
					if (ext)
					{
						var source:String = fs.readUTF();
						var actions:String = fs.readUTF();
						var bounds:Rectangle = new Rectangle(fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
						var rotation:Number = fs.readDouble();
						var matrix:Matrix = new Matrix(fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
						var sourceSize:Number = fs.readDouble();
						var md5:String = fs.readUTF();
						
						var so:SpaceObject = new SpaceObject(File.applicationStorageDirectory.resolvePath("resource" + File.separator + md5 + ".dsource").nativePath, actions, bounds, rotation, matrix, editMode, source.split(".")[source.split().length - 1]);
					}
					else
					{
						var source:String = fs.readUTF();
						var actions:String = fs.readUTF();
						var bounds:Rectangle = new Rectangle(fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
						var rotation:Number = fs.readDouble();
						var matrix:Matrix = new Matrix(fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble(), fs.readDouble());
						var sourceSize:Number = fs.readDouble();
						var md5:String = fs.readUTF();
						
						var so:SpaceObject = new SpaceObject(source, actions, bounds, rotation, matrix, _editMode, source.split(".")[source.split(".").length - 1]);
					}
					
					if (_editMode)
					{
						bounds_mc.addChild(so); //Add to bounds
						spaceObjects.push(so); //Index
						/*
						config_mc.visible = true;
						config_mc.gotoAndStop(2);
						config_mc.stagename_txt.text = spacedata.extension;
						config_mc.access_txt.text = spacepermissions;
						*/
					}
					else
					{
						bounds_mc.addChild(so) //Add to stage
					}
				}
			}
			
			bounds_mc.addEventListener(MouseEvent.MOUSE_DOWN, handleBoundsMouseDown);
			bounds_mc.addEventListener(MouseEvent.MOUSE_UP, handleBoundsMouseUp);
			
			if (editMode)
			{
				this.editMode();
			}
		}
		
		private function handleBoundsMouseUp(e:MouseEvent):void 
		{
			bounds_mc.stopDrag();
		}
		
		private function handleBoundsMouseDown(e:MouseEvent):void 
		{
			if (_editMode)
			{
				config_mc.gotoAndStop(2);
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				editTool.target = null;
			}
			
			bounds_mc.startDrag();
		}
		
		private function handleMouseWheel(e:MouseEvent):void 
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			editTool.target = null;
			var boundsx:int = bounds_mc.x;
			var boundsy:int = bounds_mc.y;
			if (e.delta > 0) //Positive
			{
				bounds_mc.scaleX += 0.1;
				bounds_mc.scaleY += 0.1;
			}
			else //Negative
			{
				if (bounds_mc.scaleX > 0.2) //If its not the smallest it can be
				{
					bounds_mc.scaleX += -0.1;
					bounds_mc.scaleY += -0.1;
				}
			}
			
			bounds_mc.x = boundsx;
			bounds_mc.y = boundsy;
			
			trace("Bounds scale = " + bounds_mc.scaleX + bounds_mc.scaleY);
		}
		
		public function editMode():void
		{
			 //Init bounds for handling right clicks and events.

			editTool = new TransformTool();
			addEventListener(MouseEvent.RIGHT_CLICK, rightClickHandler);
			
			config_mc.visible = true;
			addChild(editTool);
			
			addEventListener(MouseEvent.MOUSE_WHEEL, handleMouseWheel);
			
			stagee.addEventListener(KeyboardEvent.KEY_DOWN, handleEditKeyDown);
			config_mc.saveandexit_btn.addEventListener(MouseEvent.CLICK, saveandexitClick);
			removeChild(rightmenu_mc);
			bounds_mc.addChild(rightmenu_mc);
			
			config_mc.scaleup_btn.addEventListener(MouseEvent.CLICK, scaleUp);
			config_mc.scaledown_btn.addEventListener(MouseEvent.CLICK, scaleDown);
			
			for each (var so:SpaceObject in spaceObjects)
			{
				so.addEventListener(MouseEvent.CLICK, contentClickHandler);
			}
		}
		
		private function scaleDown(e:MouseEvent):void 
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			editTool.target = null;
			
			if (bounds_mc.scaleX > 0.2) //If its not the smallest it can be
			{
				bounds_mc.scaleX += -0.1;
				bounds_mc.scaleY += -0.1;
			}
		}
		
		private function scaleUp(e:MouseEvent):void 
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			editTool.target = null;
			
			bounds_mc.scaleX += 0.1;
			bounds_mc.scaleY += 0.1;
		}
		
		private function saveandexitClick(e:MouseEvent):void 
		{
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			trace("Number of objects in space container = " + spaceObjects.length);
			config_mc.gotoAndStop(2);
			//Set file name from config_mc
			var f:File = new File(); //ASD / spaces / examplespace
			f = File.applicationStorageDirectory.resolvePath("spaces" + File.separator + config_mc.stagename_txt.text + ".space");
			
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			//First write the number of objects
			fs.writeDouble(spaceObjects.length);
			//Actions detail inside space file
			fs.writeUTF(config_mc.access_txt.text);
			for (var i:int = 0; i < spaceObjects.length; i++)
			{
				trace("Saved object: " + spaceObjects[i].source);
				fs.writeUTF(spaceObjects[i].source); //Source
				fs.writeUTF(spaceObjects[i].actions); //Actions text
				fs.writeDouble(spaceObjects[i].x); //Position
				fs.writeDouble(spaceObjects[i].y);
				fs.writeDouble(spaceObjects[i].width); //Size
				fs.writeDouble(spaceObjects[i].height);
				fs.writeDouble(spaceObjects[i].rotation); //Rotation
				fs.writeDouble(spaceObjects[i].transform.matrix.a); //Matrix
				fs.writeDouble(spaceObjects[i].transform.matrix.b);
				fs.writeDouble(spaceObjects[i].transform.matrix.c);
				fs.writeDouble(spaceObjects[i].transform.matrix.d);
				fs.writeDouble(spaceObjects[i].transform.matrix.tx);
				fs.writeDouble(spaceObjects[i].transform.matrix.ty);
				
				if (spaceObjects[i].source == "embeddedobject")
				{
					fs.writeDouble((spaceObjects[i].actions as String).length);
					fs.writeUTF(MD5.hash(spaceObjects[i].actions as String));
				}
				else
				{
					var source:File = new File(spaceObjects[i].source);				
					var tmp:ByteArray = new ByteArray();
					var fs2:FileStream = new FileStream();
					
					fs2.open(source, FileMode.READ);
						fs2.readBytes(tmp, 0, source.size);
						fs2.close();
					
					//Add:FileSize
					//Add:MD5
					fs.writeDouble(source.size);
					fs.writeUTF(MD5.hashBytes(tmp));
				}
				
			}
			fs.close();
			
			//Save image of desktop
			var pathToSave:File = File.applicationStorageDirectory.resolvePath("spaces" + File.separator + config_mc.stagename_txt.text + ".jpeg");
			
			removeChild(config_mc);
			removeChild(editTool);
			
			//New size will only represent edge to edge of objects
			trace("width of this = " + this.width);
			trace("Height of this = " + this.height);
			/*
			var bmd:BitmapData = new BitmapData(this.width, this.height);
			bmd.draw(this);
			var ba:ByteArray = new ByteArray();
			bmd.encode(new Rectangle(0, 0, this.width, this.height), new JPEGEncoderOptions(), ba);
			
			var fileAccess:FileStream = new FileStream();
			fileAccess.open(pathToSave, FileMode.WRITE);
			fileAccess.writeBytes(ba, 0, ba.length);
			fileAccess.close();
			*/
			stagee.nativeWindow.close();
		}
		
		private function handleEditKeyDown(e:KeyboardEvent):void 
		{
			switch(e.keyCode)
			{
				case 46:
					removeEventListener(Event.ENTER_FRAME, enterFrameHandler);	
					spaceObjects.splice(spaceObjects.indexOf(editTool.target), 1);
					
					bounds_mc.removeChild(editTool.target);
					
					//Remove edit tool
					editTool.target = null;
					
					//Clear config values
					config_mc.image_mc.removeChildren();
					config_mc.x_txt.text = "";
					config_mc.y_txt.text = "";
					config_mc.width_txt.text = "";
					config_mc.height_txt.text = "";
					config_mc.gotoAndStop(2);
					
					trace("Space objects length = " + spaceObjects.length);
					break;
			}
		}
		
		//Right menu and adding objects -------------
		private var fileToDisplay:File;
		private var objectType:String;
		
		private var rightMouseX:int;
		private var rightMouseY:int;
		
		private function rightClickHandler(e:MouseEvent):void
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
			rightmenu_mc.removeEventListener(MouseEvent.ROLL_OUT, handleRightMenuOut);
			rightmenu_mc.visible = false;
			
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
					fileToDisplay.browseForOpen("Video to add?", videoFilter);
					fileToDisplay.addEventListener(Event.SELECT, handleSelection);
					break;
				case "embeddedobject":
					trace("Embeddedobject");
					embed_mc.visible = true;
					embed_mc.add_btn.addEventListener(MouseEvent.CLICK, handleEmbedAddClick);
					embed_mc.close_btn.addEventListener(MouseEvent.CLICK, handleEmbedCloseClick);
					break;
			}
			
			
		}
		
		private function handleEmbedAddClick(e:MouseEvent):void 
		{
			embed_mc.add_btn.removeEventListener(MouseEvent.CLICK, handleEmbedAddClick);
			embed_mc.close_btn.removeEventListener(MouseEvent.CLICK, handleEmbedCloseClick);
			var so:SpaceObject = new SpaceObject("embeddedobject", embed_mc.text_txt.text, new Rectangle(rightMouseX, rightMouseY));
			bounds_mc.addChild(so);
			so.addEventListener(MouseEvent.CLICK, contentClickHandler);
			spaceObjects.push(so);
			embed_mc.visible = false;
		}
		
		private function handleEmbedCloseClick(e:MouseEvent):void 
		{
			embed_mc.add_btn.removeEventListener(MouseEvent.CLICK, handleEmbedAddClick);
			embed_mc.close_btn.removeEventListener(MouseEvent.CLICK, handleEmbedCloseClick);
			embed_mc.visible = false;
		}
		
		private function handleSelection(e:Event):void //For file selection of text/video from embedded objects
		{
			fileToDisplay.removeEventListener(Event.SELECT, handleSelection);
			var so:SpaceObject = new SpaceObject(fileToDisplay.nativePath, "", new Rectangle(rightMouseX, rightMouseY), 0, null, true, fileToDisplay.extension);
			so.addEventListener(MouseEvent.CLICK, contentClickHandler);
			bounds_mc.addChild(so);
			spaceObjects.push(so);
		}
		
		private function contentClickHandler(e:MouseEvent):void 
		{	
			selectedSpaceObject = e.target as SpaceObject;
			config_mc.gotoAndStop(1);
			addChild(editTool);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			//Init selection
			editTool.target = e.target as MovieClip;
			
			if (selectedSpaceObject.source == "embeddedobject") //Cannot rotate or skew embedded objects.
			{
				editTool.scaleEnabled = false;
				editTool.skewEnabled = false;
				editTool.rotationEnabled = false;
			}
			
			editTool.constrainScale = true;
			editTool.parent.setChildIndex(editTool, editTool.parent.numChildren - 1);
			swapChildren(config_mc, editTool);
			
			//Configure..config	
			
			//Image display
			trace("Width and height = " + e.target.width + ":" + e.target.height);
			var bmd:BitmapData = new BitmapData(e.target.width, e.target.height);
			bmd.draw(e.target as DisplayObject);
			var bm:Bitmap = new Bitmap(bmd);
			config_mc.image_mc.addChild(bm);
			resize(bm, 75, 46); //resize
			
			//! Tecnically still just adding aditional bitmaps each time the user clicks on an object
			
			//Properties
			trace("e.target = " + e.target);
			config_mc.x_txt.text = e.target.x.toString();
			config_mc.y_txt.text = e.target.y.toString();
			config_mc.width_txt.text = e.target.width.toString();
			config_mc.height_txt.text = e.target.height.toString();
			config_mc.nativePath_txt.text = e.target.source;
			config_mc.actions_txt.text = e.target.actions;
			config_mc.actions_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleCurrentSpaceObjectKeyDown);
			
			//Auto-Update properties
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function handleCurrentSpaceObjectKeyDown(e:KeyboardEvent):void 
		{
			//Just a constant save of each key typed. Saves to the space object
			selectedSpaceObject.actions = config_mc.actions_txt.text;
		}
		
		private function enterFrameHandler(e:Event):void 
		{
			config_mc.x_txt.text = editTool.target.x.toString();
			config_mc.y_txt.text = editTool.target.y.toString();
			config_mc.width_txt.text = editTool.target.width.toString();
			config_mc.height_txt.text = editTool.target.height.toString();
		}
		
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
		
		public function get access():String 
		{
			return _access;
		}
	}

}