package sfxworks 
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class CommunicationLine extends EventDispatcher //TODO: Apply this to other services (and create parent classes vs extending EventDispatcher)
	{
		private var iStream:NetStream;
		private var oStream:NetStream;
		private var istreamConnected:Boolean;
		private var ostreamConnected:Boolean;
		
		private var groupSpecifier:GroupSpecifier;
		private var lineName:String;
		
		public function CommunicationLine(c:Communications, name:String, gspec:GroupSpecifier, target:flash.events.IEventDispatcher=null) 
		{
			super(target);
			istreamConnected = new Boolean(false);
			ostreamConnected = new Boolean(false);
			lineName = name;
			
			groupSpecifier = gspec;
			
			trace("COMMUNICATION_LINE INIT: " + name);
			
			c.addGroup(name, gspec);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			c.addEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulNetConnection);
		}
		
		private function handleSuccessfulNetConnection(e:NetworkActionEvent):void 
		{
			if (e.info.stream == iStream)
			{
				var clc:CommunicationLineClient = new CommunicationLineClient();
				clc.addEventListener(CLCEvent.MESSAGE, handleIncommingMessage);
				iStream.client = clc;
				iStream.play("stream");
				
				trace("COMMUNICATION_LINE:" + lineName + " Setup inbound stream.");
			}
			else if (e.info.stream == oStream)
			{
				oStream.publish("stream");
				trace("COMMUNICATION_LINE:" + lineName + " Setup outbound stream.");
			}
			
			if (istreamConnected && ostreamConnected)
			{
				dispatchEvent(new NetworkActionEvent(NetworkActionEvent.SUCCESS, lineName));
				trace("COMMUNICATION_LINE:" + lineName + " successfully connected.");
			}
		}
		
		private function handleIncommingMessage(e:CLCEvent):void 
		{
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.MESSAGE, e.message));
			trace("COMMUNICATION_LINE:" + lineName + " Incomming message/object " + e.message);
		}
		
		public function send(object:Object):void
		{
			trace("COMMUNICATION_LINE:" + lineName + " Sending message " + object);
			oStream.send("throwMessage", object);
		}
		
	}

}