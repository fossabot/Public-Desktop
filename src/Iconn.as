package 
{
	import fl.transitions.easing.*;
	import fl.transitions.Tween;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class Iconn extends Sprite 
	{
		private var f:File;
		private var ic:Bitmap;
		private var _path:String;
		
		public function Iconn(file:File) 
		{
			super();
			f = file;
			ic = new Bitmap(f.icon.bitmaps[0]); //Bitmap data from file
			addChild(ic); //Add display
			
			this.width = 16;
			this.height = 16;
			this.buttonMode = true;
			ic.alpha = .5;
			
			addEventListener(MouseEvent.CLICK, handleClick);
			addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, handleMouseOut);
			
			_path = file.nativePath;
		}
		
		private function handleMouseOut(e:MouseEvent):void //Mouse OUT
		{
			//ic.alpha = .5;
			var tweenMouseOut:Tween = new Tween(ic, "alpha", Elastic.easeOut, 1, .5, 2, true);
		}
		
		private function handleMouseOver(e:MouseEvent):void //Mouse OVER
		{
			var tweenMouseOut:Tween = new Tween(ic, "alpha", Strong.easeOut, .5, 1, 2, true);
		}
		
		private function handleClick(e:MouseEvent):void //Mouse CLICK
		{
			f.openWithDefaultApplication();
			//trace("Active windows = " + NativeApplication.nativeApplication.openedWindows.length);
		}
		
		public function get path():String 
		{
			return _path;
		}
		
	}

}