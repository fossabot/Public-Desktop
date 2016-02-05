package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class EditableObject extends MovieClip 
	{
		private var dragType:String;
		private var prevMouseX:int;
		private var prevMouseY:int;
		private var _nativePath:String;
		private var _text:String;
		private var _typee:String;
		private var _imageRep:MovieClip;
		
		private var predW:Number;
		private var predH:Number;
		
		public function EditableObject(type:String, nativePath:String) 
		{
			text = new String(" ");
			_nativePath = nativePath;
			_typee = type;
			//side right
			rightside_mc.addEventListener(MouseEvent.MOUSE_DOWN, rightMouseDown);
			rightside_mc.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			//side bottom
			bottomside_mc.addEventListener(MouseEvent.MOUSE_DOWN, bottomMouseDown);
			bottomside_mc.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			
			//Manual scale code
			//bottomright
			bottomright_mc.addEventListener(MouseEvent.CLICK, bottomRightDown);
			
			//Basic drag
			center_mc.addEventListener(MouseEvent.MOUSE_DOWN, handleDrag);
			this.cacheAsBitmap = true;
		}
		
		public function handleSavedObject(type:String, actions:String, source:String, ix:Number, iy:Number, iwidth:Number, iheight:Number)
		{
			_nativePath = source;
			_typee = type;
			
			var raw:ByteArray = new ByteArray();
			var f:File = new File(source);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			fs.readBytes(raw);
			fs.close();
			
			this.x = ix;
			this.y = iy;
			
			predW = iwidth;
			predH = iheight;
			
			var l:Loader = new Loader();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, handleContentComplete);
			l.loadBytes(raw);
		}
		
		private function handleContentComplete(e:Event):void 
		{
			//addChild(e.target.content);
			e.target.content.width = predW;
			e.target.content.height = predH;
			
			addDisplay(e.target.content);
		}
		
		public function addDisplay(displayObject:DisplayObject) //Parent uses addDisplay instead of addChild
		{
			//Proper size and positioning of all objects
			leftside_mc.height = displayObject.height;
			rightside_mc.height = displayObject.height;
			rightside_mc.x = displayObject.width;
			topside_mc.width = displayObject.width;
			bottomside_mc.width = displayObject.width;
			bottomside_mc.y = displayObject.height;
			center_mc.bg_mc.width = displayObject.width;
			center_mc.bg_mc.height = displayObject.height;
			
			bottomright_mc.x = displayObject.width - 15;
			bottomright_mc.y = displayObject.height - 13;
			
			center_mc.addChild(displayObject);
			
			var bmd:BitmapData = new BitmapData(displayObject.width, displayObject.height);
			bmd.draw(displayObject);
			
			var bm:Bitmap = new Bitmap(bmd);
			
			var mc:MovieClip = new MovieClip();
			mc.addChild(bm);
			_imageRep = mc;
		}
		
		private function handleDrag(e:MouseEvent):void 
		{
			this.startDrag();
			addEventListener(MouseEvent.MOUSE_UP, stopDragHandler);
		}
		
		private function stopDragHandler(e:MouseEvent):void 
		{
			this.stopDrag();
			removeEventListener(MouseEvent.MOUSE_UP, stopDragHandler);
		}
		
		private function bottomRightDown(e:MouseEvent):void 
		{
			resizeMe(this, this.width, this.height);
		}
		
		private function bottomMouseDown(e:MouseEvent):void 
		{
			dragType = "bottom";
			prevMouseX = e.stageX;
			prevMouseY = e.stageY;
			this.parent.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			this.parent.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		private function rightMouseDown(e:MouseEvent):void 
		{
			dragType = "right";
			prevMouseX = e.stageX;
			prevMouseY = e.stageY;
			this.parent.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			this.parent.addEventListener(MouseEvent.MOUSE_UP, mouseUp);

			trace("Right mouse down.");
		}
		
		private function mouseUp(e:MouseEvent):void 
		{
			this.parent.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			this.parent.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);

			trace("Mouse up. Removing event listener..");
		}
		
		private function handleMouseMove(e:MouseEvent):void 
		{
			switch(dragType)
			{
				case "right":
					trace("Right triggered.");
					this.width = e.stageX - this.x;
					break;
				case "bottom":
					trace("Bottom triggered");
					this.height = e.stageY - this.y;
					break;
			}
			
			/*
			trace("stage x: " + e.stageX); 
			trace("stage y: " + e.stageY);
			trace("local x: " + e.localX);
			trace("local x: " + e.localY);
			*/
			prevMouseX = e.stageX;
			prevMouseY = e.stageY;
		}
		
		//Author/Tutorial of resizeMe at https://circlecube.com/says/2009/01/how-to-as3-resize-a-movieclip-and-constrain-proportions-actionscript-tutorial/
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
		
		public function get imageRep():MovieClip 
		{
			return _imageRep;
		}
		
		public function get typee():String 
		{
			return _typee;
		}
		
		public function get text():String 
		{
			return _text;
		}
		
		public function set text(value:String):void 
		{
			_text = value;
		}
		
		public function get nativePath():String 
		{
			return _nativePath;
		}
		
	}

}