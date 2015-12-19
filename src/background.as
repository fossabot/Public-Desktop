package 
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Timer;
	import nop.away3d.AWDViewer;
	/**
	 * ...
	 * @author ...
	 */
	
	public class background extends MovieClip 
	{
		private var fs:FileStream;
		private var bg:File;
		private var d:Date;
		
		public function background() 
		{
			super();
			removeChild(bg_mc);
			
			var awd:AWDViewer = new AWDViewer(stage.fullScreenWidth, stage.fullScreenHeight);
			addChild(awd);
			awd.showByURL(File.applicationDirectory.resolvePath("assets" + File.separator + "desktop.awd").nativePath);
			
			//this.scaleX = stage.fullScreenWidth / this.width;
			//this.scaleY = stage.fullScreenHeight / this.height;
			//this.x = (stage.fullScreenWidth - this.width) / 2;
			//this.y = (stage.fullScreenHeight - this.height) / 2;
			
			//stage.nativeWindow.width = stage.width;
			//stage.nativeWindow.height = stage.height;
			//stage.nativeWindow.x = 0;
			//stage.nativeWindow.y = 0;
			
			var t:Timer = new Timer(1000);
			t.addEventListener(TimerEvent.TIMER, updateTime);
			t.start();
			
			time_txt.width = stage.fullScreenWidth;// - (stage.fullScreenWidth - time_txt.width) / 2;
			time_txt.x = 0;
		}
		
		private function updateTime(e:TimerEvent):void 
		{
			d = new Date();
			var m:int = d.getMonth();
			m++;
			time_txt.text =  m.toString() + "." + d.getDate().toString() + "." + d.getFullYear().toString() + " " + d.getHours().toString() + ":" + d.getMinutes().toString() + ":" + d.getSeconds().toString();
		}
		
		public function setbackground(display:DisplayObject):void
		{
			this.removeChildAt(0);
			addChild(display);
		}
	}

}