package 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.text.TextField;
	import flash.utils.Timer;
	import nop.away3d.AWDViewer;
	/**
	 * ...
	 * @author Samuel Walker
	 */
	
	public class Background extends MovieClip 
	{
		private var fs:FileStream;
		private var bg:File;
		private var d:Date;
		
		private var timetext:TextField = new TextField();
		
		public function Background(bgwidth:int, bgheight:int) 
		{
			removeChildren();
			
			var awd:AWDViewer = new AWDViewer(bgwidth, bgheight);
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
			
			timetext.width = bgwidth;// - (stage.fullScreenWidth - time_txt.width) / 2;
			timetext.x = 0;
			
			addChild(timetext);
		}
		
		private function updateTime(e:TimerEvent):void 
		{
			d = new Date();
			var m:int = d.getMonth();
			m++;
			timetext.text =  m.toString() + "." + d.getDate().toString() + "." + d.getFullYear().toString() + " " + d.getHours().toString() + ":" + d.getMinutes().toString() + ":" + d.getSeconds().toString();
		}
		
		public function setbackground(display:DisplayObject):void
		{
			this.removeChildAt(0);
			addChild(display);
		}
	}

}