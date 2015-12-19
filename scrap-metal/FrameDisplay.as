package 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.media.StageWebView;
	import flash.net.URLRequest;
	import sfxworks.Communications;
	import sfxworks.SpaceContainer;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FrameDisplay extends MovieClip 
	{
		private var frames:Vector.<MovieClip>;
		private var activeFrameNumber:int = -1;
		
		private var c:Communications;
		
		public function FrameDisplay(communications:Communications) 
		{
			frames = new Vector.<MovieClip>();
			addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
			
			addEventListener(MouseEvent.MOUSE_WHEEL, scrollHandler);
			
			activeFrameNumber = 0;
			c = communications;
		}
		
		private function scrollHandler(e:MouseEvent):void 
		{
			if (scaled)
			{
				switch(e.delta)
				{
					case -3:
						container_mc.x += this.width * 0.75;
						activeFrameNumber --;
						//back
						break;
					case 3:
						container_mc.x -= this.width * 0.75;
						activeFrameNumber ++;
						//forward
						break;
				}
			}
		}
		
		private function keyHandler(e:KeyboardEvent):void 
		{
			switch(e.keyCode)
			{
				case 27:
					handleControl();
					break;
				case 13:
					if (scaled)
					{
						handleControl();
					}
					break;
			}
		}
		
		public function createNewDisplay(type:String, arg:String="http://news.google.com"):void
		{
			trace("FRAMES LENGTH = " + frames.length);
			switch(type)
			{
				case "internet-html":
					var frame:HtmlFrame = new HtmlFrame(this.width, this.height, arg);
					addDisplay(frame);
					frame.overhead_mc.close_btn.addEventListener(MouseEvent.CLICK, handleClose);
					break;
				case "public-desktop":
					//var pd:SpaceContainer = new SpaceContainer();
					//addDisplay(pd);
					//pd.overhead_mc.close_btn.addEventListener(MouseEvent.CLICK, handleClose);
					trace("Created public desktop");
					break;
			}
		}
		
		private function addDisplay(d:MovieClip):void
		{
			trace("Adding new display..");
			frames.push(d);
			container_mc.addChild(d);
			resizeMe(d, stage.width, stage.height, true);
			var difference:int = stage.width - d.width;
			difference = difference / 2;
			d.x = difference;
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
		
		
		private function handleClose(e:MouseEvent):void 
		{
			//trace("ID = " + e.target.parent.parent.frameID);
			container_mc.removeChild(e.target.parent.parent);
		}
		
		private var scaled:Boolean = new Boolean(false);
		private function handleControl():void 
		{
			if (scaled)
			{
				//Scale up
				container_mc.scaleX = 1;
				container_mc.scaleY = 1;
				container_mc.x = container_mc.stage.x + (activeFrameNumber * this.width * -1);
				container_mc.y = container_mc.stage.y;
				
				trace("Container current x = " + container_mc.x);
				trace("Container current y = " + container_mc.y);
				
				//container_mc.enabled = false;
				scaled = false;
			}
			else
			{
				//Scale down
				container_mc.scaleX = 0.75;
				container_mc.scaleY = 0.75;
				container_mc.x = container_mc.stage.x + (activeFrameNumber * this.width * -1);
				container_mc.x += this.width / 8;
				container_mc.x += this.width / 4 * activeFrameNumber;
				container_mc.y = container_mc.stage.stageHeight / 2 - container_mc.height / 2;
				//container_mc.enabled = true;
				scaled = true;
			}
		}
		
	}

}