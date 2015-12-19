package sfxworks 
{
	import sfxworks.NetworkUserEvent;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class ChatFrame extends MovieClip 
	{
		private var communications:Communications;
		public function ChatFrame(c:Communications) 
		{
			communications = c;
			communications.addEventListener(NetworkUserEvent.MESSAGE, handleMessage);
			input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
		}
		
		private function handleKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				communications.broadcast(input_txt.text);
				input_txt.text = "";
			}
		}
		
		private function handleMessage(e:NetworkUserEvent):void 
		{
			output_txt.appendText("[" + e.name + "]: " + e.message);
		}
		
	}

}