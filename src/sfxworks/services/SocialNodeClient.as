package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SocialNodeClient extends EventDispatcher 
	{
		
		public function SocialNodeClient() 
		{
			
		}
		
		public function postToFeed(feedData:Object):void
		{
			dispatchEvent(new NodeEvent(NodeEvent.INCOMMING_DATA, feedData));
		}
		
	}

}