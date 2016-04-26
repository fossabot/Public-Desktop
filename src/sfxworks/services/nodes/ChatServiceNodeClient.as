package sfxworks.services.nodes 
{
	import flash.events.EventDispatcher;
	import sfxworks.services.events.NodeEvent;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class ChatServiceNodeClient extends EventDispatcher 
	{
		
		public function ChatServiceNodeClient() 
		{
			trace("Chat service node client init");
		}
		
		public function recieveMessage(object:Object):void
		{
			trace("Recieved data");
			dispatchEvent(new NodeEvent(NodeEvent.INCOMMING_DATA, object));
		}
		
	}

}