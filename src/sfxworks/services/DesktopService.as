package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import sfxworks.Communications;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DesktopService extends EventDispatcher
	{
		private var c:Communications;
		
		public function DesktopService(communications:Communications) 
		{
			c = communications;
			
			
		}
		
	}

}