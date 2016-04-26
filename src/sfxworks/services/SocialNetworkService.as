package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.events.NodeEvent;
	import sfxworks.services.events.SocialNetworkServiceEvent;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SocialNetworkService extends EventDispatcher 
	{
		public static const SERVICE_NAME:String = "soicalnetworkstream";
		private var communications:Communications;
		
		private var snsNS:NetStream;
		private var gs:GroupSpecifier;
		
		private var snc:SocialNodeClient;
		
		public function SocialNetworkService(c:Communications) 
		{
			communications = c;
			
			gs = new GroupSpecifier(SERVICE_NAME);
			gs.postingEnabled = true;
			gs.serverChannelEnabled = true;
			gs.multicastEnabled = true;
			c.addGroup(SERVICE_NAME, gs);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulConnection);
		}
		
		private function handleSuccessfulConnection(e:NetworkGroupEvent):void 
		{
			communications.removeEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulConnection);
			communications.addEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulNetstreamConnection);
			snsNS = new NetStream(communications.netConnection, gs.groupspecWithoutAuthorizations());
		}
		
		private function handleSuccessfulNetstreamConnection(e:NetworkActionEvent):void 
		{
			if (e.info == snsNS)
			{
				communications.removeEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulNetstreamConnection);
				snc = new SocialNodeClient();
				snc.addEventListener(NodeEvent.INCOMMING_DATA, handlePostData);
				
				snsNS.client = snc;
				snsNS.play(SERVICE_NAME);
				
				dispatchEvent(new SocialNetworkServiceEvent(SocialNetworkServiceEvent.CONNECTED));
			}
		}
		
		private function handlePostData(e:NodeEvent):void 
		{
			var timeStamp:Date = new Date(e.data.year, e.data.month, e.data.date, e.data.hour, e.data.minute, e.data.second, e.data.millisecond);
			
			dispatchEvent(new SocialNetworkServiceEvent(SocialNetworkServiceEvent.POST, e.data.message, e.data.publicKey, e.data.username, timeStamp));
		}
		
		public function post(message:String):void
		{
			var objectToSend:Object;
			
			var timeStamp:Date = new Date();
			
			objectToSend.year = timeStamp.getFullYear();
			objectToSend.month = timeStamp.getMonth();
			objectToSend.date = timeStamp.getDate();
			objectToSend.hour = timeStamp.getHours();
			objectToSend.minute = timeStamp.getMinutes();
			objectToSend.second = timeStamp.getSeconds();
			objectToSend.millisecond = timeStamp.getMilliseconds();
			
			objectToSend.message = message;
			objectToSend.username = communications.name;
			objectToSend.publicKey = communications.publicKey;
			
			snsNS.send("postToFeed", objectToSend);
		}
		
		
		
	}

}