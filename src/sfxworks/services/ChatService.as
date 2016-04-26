package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.events.ChatServiceEvent;
	import sfxworks.services.events.NodeEvent;
	import sfxworks.services.nodes.ChatServiceNodeClient;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class ChatService extends EventDispatcher
	{
		private var c:Communications;
		public static const SERVICE_NAME:String = "chatservice";
		public static const GLOBAL_CHAT_NAME:String = "globalchat";
		
		private var gs:GroupSpecifier;
		private var publicNodeI:NetStream;
		private var publicNodeO:NetStream;
		
		private var publicNodeIConnected:Boolean;
		private var publicNodeOConnected:Boolean;
		
		
		public function ChatService(communications:Communications) 
		{
			c = communications;
			
			publicNodeIConnected = new Boolean(false);
			publicNodeOConnected = new Boolean(false);
			
			gs = new GroupSpecifier(GLOBAL_CHAT_NAME);	
			gs.objectReplicationEnabled = true;
			gs.serverChannelEnabled = true;
			gs.multicastEnabled = true;
			
			c.addGroup(GLOBAL_CHAT_NAME, gs);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGlobalSuccessfull);
			c.addEventListener(NetworkActionEvent.SUCCESS, handleNetworkActionSuccess);
		}
		
		private function handleNetworkActionSuccess(e:NetworkActionEvent):void 
		{
			switch(e.info)
			{
				case publicNodeI:
					var csnc:ChatServiceNodeClient = new ChatServiceNodeClient();
					publicNodeI.client = csnc;
					publicNodeI.play(SERVICE_NAME + GLOBAL_CHAT_NAME);
					csnc.addEventListener(NodeEvent.INCOMMING_DATA, handleIncommingData);
					
					publicNodeIConnected = true;
					break;
				case publicNodeO:
					publicNodeO.client = new ChatServiceNodeClient();
					publicNodeO.publish(SERVICE_NAME + GLOBAL_CHAT_NAME);
					
					publicNodeOConnected = true;
					break;
			}
			if (publicNodeIConnected && publicNodeOConnected)
			{
				trace("ChatService: Successfully connected.");
				c.removeEventListener(NetworkActionEvent.SUCCESS, handleNetworkActionSuccess);
			}
		}
		
		private function handleIncommingData(e:NodeEvent):void 
		{
			trace("Incomming data from chat service: " + e.data);
			dispatchEvent(new ChatServiceEvent(ChatServiceEvent.CHAT_MESSAGE, e.data.nearid, e.data.name, e.data.message));
		}
		
		public function sendMessage(message:String):void
		{
			var objectToSend:Object;
			objectToSend.nearid = c.nearID;
			objectToSend.name = c.name;
			objectToSend.message = message;
			
			publicNodeO.send("recieveMessage", objectToSend);
		}
		
		private function handleGlobalSuccessfull(e:NetworkGroupEvent):void 
		{
			c.removeEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGlobalSuccessfull);
			c.addEventListener(NetworkActionEvent.SUCCESS, handleNetworkActionSuccess);
			
			publicNodeI = new NetStream(c.netConnection, gs.groupspecWithoutAuthorizations());
			publicNodeO = new NetStream(c.netConnection, gs.groupspecWithoutAuthorizations());
		}
		
	}

}