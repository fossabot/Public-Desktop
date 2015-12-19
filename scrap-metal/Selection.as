package 
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Selection extends MovieClip 
	{
		
		public var selection:String;
		
		public function Selection(title:String, list:Array) 
		{
			this.buttonMode = true;
			text_txt.text = title;
			
			var positioning:int = new int(12.5);
			var textFormat:TextFormat = new TextFormat();
			textFormat.size = 7;
			textFormat.font = "ArielFont";
			
			
			for each (var item:String in list)
			{
				var tf:TextField = new TextField();
				tf.text = item;
				addChild(tf);
				tf.addEventListener(MouseEvent.CLICK, handleSelection);
				
				tf.y = positioning;
				positioning += 12.5;
				
				//Font
				tf.textColor = 0xFFFFFF;
				tf.alpha = .75;
				//tf.height = 12.5;
				tf.width = 250;
				tf.height = 20;
				
				tf.defaultTextFormat = textFormat;
			}
			
			selection = new String("-1");
		}
		
		private function handleSelection(e:MouseEvent):void 
		{
			selection = e.target.text;
			e.target.border = true;
		}
		
	}

}