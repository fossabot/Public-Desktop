package sfxworks 
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
	public class LiteHtmlFrame extends MovieClip 
	{
		private var htmlLoader:HTMLLoader;
		
		public function LiteHtmlFrame() 
		{
			htmlLoader = new HTMLLoader();
			htmlLoader.addEventListener(Event.COMPLETE, handleHtmlLoadComplete);
			htmlLoader.addEventListener(Event.LOCATION_CHANGE, handleHtmlLocationChange);
			nav_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleHtmlNavKeyDown);
		}
		
		private function handleHtmlLocationChange(e:Event):void 
		{
			nav_txt.text = htmlLoader.location;
		}
		
		private function handleHtmlLoadComplete(e:Event):void 
		{
			addChild(htmlLoader);
			
			htmlLoader.width = 800;
			htmlLoader.height = 600;
			htmlLoader.y = 26.95;
		}
		
		private function handleHtmlNavKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				htmlLoader.reload();
				htmlLoader.cancelLoad();
				htmlLoader.load(new URLRequest(nav_txt.text));
			}
		}
		
	}

}