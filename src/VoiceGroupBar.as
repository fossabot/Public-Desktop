package 
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class VoiceGroupBar extends MovieClip 
	{
		private var graph:Shape;
		private var graphBarHistory:Array;
		private var _username:String;
		
		//W = 190 H = 34.85
		
		public function VoiceGroupBar(username:String) 
		{
			_username = username;
			
			graph = new Shape();
			graphBarHistory = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
			name_txt.text = username;
			
			graph.x = 190;
			graph.y = 0;
			addChild(graph);
		}
		
		public function updateByteLevel(level:Number):void
		{
			graphBarHistory.reverse();
			graphBarHistory.pop();
			graphBarHistory.reverse();
			
			if (level == -1 || level == 0)
			{
				level = 1;
			}
			graphBarHistory.push(level);
			drawNewGraph();
			
			trace("vgb: Mic level = " + level);
		}
		
		private function drawNewGraph():void
		{
			var highestNumber:Number = Math.max.apply(null, graphBarHistory);
			var currentX:int = 0;
			
			graph.graphics.clear();
			graph.graphics.beginFill(0x00CCFF, .5);
			
			trace("All values = " + graphBarHistory);
			
			for (var i:int = 0; i < 19; i++)
			{//                                        highest number  *               percentage
				//trace("vgb: graph height = " + this.height * (graphBarHistory[i] / highestNumber));
				//trace("vgb: highest number = " + highestNumber);
				//trace("vgb: current value = " + graphBarHistory[i]);
				graph.graphics.drawRect(currentX, 0, 10, this.height * (graphBarHistory[i] / highestNumber));
				currentX += 10;
			}
		}
		
		public function get username():String 
		{
			return _username;
		}
		
		public function set username(value:String):void 
		{
			name_txt.text = value;
			_username = value;
		}
		
	}

}