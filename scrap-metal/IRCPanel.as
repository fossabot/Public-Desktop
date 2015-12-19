package 
{
	import com.fleo.irc.events.IRCErrorEvent;
	import com.fleo.irc.events.JoinEvent;
	import com.fleo.irc.events.KickEvent;
	import com.fleo.irc.events.ModeEvent;
	import com.fleo.irc.events.NickEvent;
	import com.fleo.irc.events.NoticeEvent;
	import com.fleo.irc.events.PrivmsgEvent;
	import com.fleo.irc.events.QuitEvent;
	import com.fleo.irc.events.TopicEvent;
	import com.fleo.irc.IRC;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author ...
	 */
	public class IRCPanel extends MovieClip 
	{
		private var servers:Vector.<IRCServer>;
		private var currentServer:IRCServer;
		private var currentUsername:String;
		
		public function IRCPanel(username:String) 
		{
			textFields = new Vector.<TextField>();
			input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			
		}
		
		private function handleKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode = 13)
			{
				if (input_txt.text.charAt(0) = "/")
				{
					if(input_txt.text.split("/")[1] == "server") //Have the client handle it if theyre joining another server
					{
						var serverToJoin:String = input_txt.text.split(" ")[1];
						var foundServer:Boolean;
						//Search for room if it exists
						currentServer = 0;
						for each (var server:IRCServer in servers)
						{
							if (server.channelName == serverToJoin)
							{
								removeChildren(); //Remove all existing textfields
								addChild(server.tf); //Add the new one
								foundServer = true;
								currentServer = server;
							}
						}
						if (!foundServer)
						{
							var ircServer:IRCServer = new IRCServer(currentUsername, serverToJoin);
							removeChildren();
							addChild(ircServer.tf);
							
							currentServer = ircServer;
						}
					}
				}
				else //Send the command, or text or whatever to the server
				{
					currentServer.sendInput(input_txt.text); //Send the entire command.
					input_txt.text = "";
				}
			}
		}
	}

}