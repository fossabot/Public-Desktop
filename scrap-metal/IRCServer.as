package 
{
	import air.update.descriptors.ConfigurationDescriptor;
	import air.update.events.StatusFileUpdateErrorEvent;
	import com.fleo.irc.events.JoinEvent;
	import com.fleo.irc.events.NickEvent;
	import com.fleo.irc.events.PrivmsgEvent;
	import com.fleo.irc.IRC;
	import flash.events.Event;
	import flash.text.Texroom_txtield;
	
	/**
	 * ...
	 * @author ...
	 */
	public class IRCServer extends IRC 
	{
		private var _channelName:String;
		private var _serverName:String;
		
		
		public function IRCServer(name:String, server:String="irc.sfxworks.net", port:int=3306) 
		{
			super();
			this.connect(server, port, name);
			
			addEventListener(IRC.EVENT_STATUSMESSAGE,statusMessageEventHandler);
			addEventListener(IRC.EVENT_SOCKOPEN, sockOpenEventHandler);
			addEventListener(IRC.EVENT_ERROR, errorEventHandler);
			
			addEventListener(IRC.EVENT_SOCKERROR, sockErrorEventHandler);
			addEventListener(IRC.EVENT_ACTIVEMESSAGE, activeMessageEventHandler);
			addEventListener(IRC.EVENT_PING, pingEventHandler);
			
			addEventListener(IRC.EVENT_NOTICE, noticeEventHandler);
			addEventListener(IRC.EVENT_JOIN, joinEventHandler);
			addEventListener(IRC.EVENT_PRIVMSG, privmsgEventHandler);
			addEventListener(IRC.EVENT_TOPIC, topicEventHandler);
			addEventListener(IRC.EVENT_MODE, modeEventHandler);
			addEventListener(IRC.EVENT_NICK, nickEventHandler);
			addEventListener(IRC.EVENT_KICK, kickEventHandler);
			addEventListener(IRC.EVENT_QUIT, quitEventHandler);
			
		}
		
		public function joinChannel(channelName:String):void
		{
			
		}
		
		private function noticeEventHandler(e:NoticeEvent):void
		{
			
		}
		private function joinEventHandler(e:JoinEvent):void
		{
			room_txt.appendText("\n");
			room_txt.appendText(e.user + " joined " + e.chan);
		}
		private function privmsgEventHandler(e:PrivmsgEvent):void
		{
			room_txt.appendText("\n");
			room_txt.appendText("PVTMSG[" + e.user + "]:" + e.msg);
		}
		private function topicEventHandler(e:TopicEvent):void
		{
			
		}
		private function modeEventHandler(e:ModeEvent):void
		{
			
		}
		private function nickEventHandler(e:NickEvent):void
		{
			room_txt.appendText("\n");
			room_txt.appendText(e.oldUser + " changed his nickname to " + e.newUser);
		}
		private function kickEventHandler(e:KickEvent):void
		{
			room_txt.appendText("\n");
			room_txt.appendText("You were kicked from the channel. Howd you manage that? :/");
		}
		private function quitEventHandler(e:QuitEvent):void
		{
			
		}
		private function sockErrorEventHandler(e:Event):void
		{
			
		}
		private function pingEventHandler(e:Event):void
		{
			
		}
		
		private function errorEventHandler(e:IRCErrorEvent):void
		{
			trace("Error: "+e.message);
		}
		
		private function sockOpenEventHandler(e:Event):void
		{
			// A utiliser avec jbouncer
			//irc.processInput("/msg root test test");
			//irc.processInput("/msg root create freenode irc.freenode.net");	
		}
		
		private function statusMessageEventHandler(e:Event):void
		{
			trace(irc.getLastStatusMessage());	
		}
		
		private function activeMessageEventHandler(e:Event):void
		{
			room_txt.appendText("\n");
			room_txt.appendText(this.getLastActiveMessage());
		}
		
		public function sendInput(command:String):void
		{
			//Send message??
			this.processInput(command);
			commande_txt.text = "";
		}
		
		public function get serverName():String 
		{
			return _serverName;
		}
		
		public function set serverName(value:String):void 
		{
			_serverName = value;
		}
		
		public function get channelName():String 
		{
			return _channelName;
		}
		
		public function set channelName(value:String):void 
		{
			_channelName = value;
		}
		
		
	}

}