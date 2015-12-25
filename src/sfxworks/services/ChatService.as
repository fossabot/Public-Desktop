package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.net.GroupSpecifier;
	import sfxworks.Communications;
	import sfxworks.NetworkGroupEvent;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class ChatService extends EventDispatcher
	{
		private var c:Communications;
		public static const GLOBAL_CHAT_NAME:String = "globalchat";
		
		public function ChatService(communicactions:Communications) 
		{
			c = communicactions;
			var gs:GroupSpecifier = new GroupSpecifier(GLOBAL_CHAT_NAME);	
			gs.postingEnabled = true;
			gs.serverChannelEnabled = true;
			
			c.addGroup(GLOBAL_CHAT_NAME, gs);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGlobalSuccessfull);
		}
		
		public function sendMessage(message:String):void
		{
			var objectToSend:Object;
			objectToSend.nearid = c.nearID;
			objectToSend.name = c.name;
			objectToSend.message = message;
			
			c.postToGroup(GLOBAL_CHAT_NAME, objectToSend);
		}
		
		private function handleGlobalSuccessfull(e:NetworkGroupEvent):void 
		{
			trace("CHAT SERVICE: Connected to " + GLOBAL_CHAT_NAME + " successfully.");
			c.removeEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGlobalSuccessfull);
			c.addEventListener(NetworkGroupEvent.POST, handlePost);
		}
		
		private function handlePost(e:NetworkGroupEvent):void 
		{
			trace("CHAT SERVICE: Incomming post,");
			dispatchEvent(new ChatServiceEvent(ChatServiceEvent.CHAT_MESSAGE, e.groupObject.nearid, e.groupObject.name, e.groupObject.message));
		}
		
	}

}