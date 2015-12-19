package 
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DropDownMenu extends MovieClip 
	{
		private var origionalMaskHeight:int;
		
		public function DropDownMenu() 
		{
			this.addEventListener(MouseEvent.ROLL_OVER, hanldeRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			origionalMaskHeight = new int(mask_mc.height);
			trace("Constructed");
		}
		
	}

}