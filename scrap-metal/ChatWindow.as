package 
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	/**
	 * ...
	 * @author ...
	 */
	public class ChatWindow extends MovieClip
	{
		private var t:Timer;
		public function ChatWindow() 
		{
			t = new Timer(2000, 0);
			t.addEventListener(TimerEvent.TIMER, activeOut);
		}
		
		private function activeOut(e:TimerEvent):void 
		{
			var tweenOut:Tween = new Tween(bg_mc, "alpha", Strong.easeOut, 1, stage.stageWidth, 0, true);
			
			input_txt.addEventListener(MouseEvent.ROLL_OVER, handleRollOver);
			
		}
		
		private function handleRollOver(e:MouseEvent):void 
		{
			var tweenOut:Tween = new Tween(bg_mc, "alpha", Strong.easeOut, 0, stage.stageWidth, 1, true);
			this.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
		}
		
		private function handleRollOut(e:MouseEvent):void 
		{
			t.reset();
			t.start();
		}
		
	}

}