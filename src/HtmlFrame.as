package 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class HtmlFrame extends MovieClip 
	{
		private var htmlLoader:HTMLLoader;
		private var focus:Boolean;
		private var lastRequest:String;
		
		public function HtmlFrame(w:int, h:int, request:String) 
		{
			super();
			overhead_mc.visible = false;
			
			htmlLoader = new HTMLLoader();
			htmlLoader.load(new URLRequest(request));
			htmlLoader.addEventListener(Event.COMPLETE, handleContendLoadComplete);
			
			//htmlLoader.cacheAsBitmap = true;
			
			addChild(htmlLoader);
			
			focus = new Boolean();
			focus = true;
			
			lastRequest = new String("");
			//Handle loss of focus
			this.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			overhead_mc.textbar_txt.text = request;
			
			
			trace("Content width = " + htmlLoader.contentWidth);
		}
		
		private function handleContendLoadComplete(e:Event):void 
		{
			htmlLoader.width = htmlLoader.contentWidth;
			htmlLoader.height = htmlLoader.contentHeight;
		}
		
		private function handleKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 27)
			{
				if (focus)
				{
					trace("No focus. Tabbed");
					focus = false; //No longer focused (tabbed)
					overhead_mc.visible = true; //Make visible the frame
					removeChild(htmlLoader);
				}
			}
			if (e.keyCode == 13)
			{
				if (!focus)
				{
					trace("Navigating to " + overhead_mc.textbar_txt.text);
					overhead_mc.visible = false; //Make focus disappear
					htmlLoader.load(new URLRequest(overhead_mc.textbar_txt.text)); //Load what is in the text
					focus = true; //Set focus (active use of tab) to true)
					addChild(htmlLoader);
				}
			}
		}
		
	}

}