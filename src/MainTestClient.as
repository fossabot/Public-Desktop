package 
{
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class MainTestClient extends EventDispatcher
	{
		
		public function MainTestClient() 
		{
			
		}
		
		public function initTest(event:String):void
		{
			trace(event);
		}
		
	}

}