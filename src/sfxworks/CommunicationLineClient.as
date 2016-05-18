package sfxworks 
{
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class CommunicationLineClient extends EventDispatcher
	{
		
		public function CommunicationLineClient() 
		{
			
		}
		
		public function throwMessage(object:Object):void
		{
			dispatchEvent(new CLCEvent(CLCEvent.MESSAGE, object));
		}
		
	}

}