package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Microphone;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import sfxworks.Communications;
	import sfxworks.NetworkGroupEvent;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class VoiceService extends EventDispatcher
	{
		private var c:Communications;
		private var _microphone:Microphone;
		
		public static const SERVICE_NAME:String = "voiceservice";
		
		private var currentGroup:String = new String();
		private var currentGroupPassword:String = new String();
		private var _username:String;
		
		private var senderNode:NetStream;
		private var recieverNames:Vector.<String>;
		private var recieverNodes:Vector.<NetStream>;
		
		//For calculating voice activity
		private var t:Timer;
		
		
		//Post "xyz left and xyz joined"
		//xyz being their near id
		
		//c.publish(serviceName-voiceGroupName-audio)
		//
		
		public function VoiceService(communicactions:Communications) 
		{			
			c = communicactions;
			_microphone = Microphone.getEnhancedMicrophone(); //Set mic to default | Echo cancellation
			username = new String(c.name);
			
			t = new Timer(500);
			t.addEventListener(TimerEvent.TIMER, detectActivity);
		}
		
		private function detectActivity(e:TimerEvent):void 
		{
			var i:int = 0;
			for each (var node:NetStream in recieverNodes)
			{
				if (node.info.audioByteCount > 0)
				{
					dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_AUDIO_ACTIVITY, recieverNames[i], "", node.info.audioByteCount));
				}
				i++; //faster vs searching through each vector for index of node
			}
		}
		
		public function connectToGroup(name:String, password:String=""):void
		{
			var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + name + password);
			gspec.postingEnabled = true;
			
			senderNode = new NetStream(c.netConnection, NetStream.DIRECT_CONNECTIONS); //Every time a new group is requested...
			recieverNodes = new Vector.<NetStream>(); //it should garbage collect the old NetStreams..in theory
			
			currentGroupPassword = password;
			
			c.addGroup(SERVICE_NAME + name + password, gspec);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			c.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
		}
		
		public function disconnectFromGroup():void
		{
			//Tell communications to remove from index
			c.removeGroup(currentGroup + currentGroupPassword);
			
			//Remove from index
			currentGroup = null;
			currentGroupPassword = null;
			senderNode = new NetStream(c.netConnection, NetStream.DIRECT_CONNECTIONS);
			recieverNodes = new Vector.<NetStream>();
		}
		
		//Used for handling joining / leaving peers
		private function handleObjectRecieved(e:NetworkGroupEvent):void 
		{
			if (e.groupName == SERVICE_NAME + currentGroup + currentGroupPassword)
			{
				switch(e.groupObject.split(" ")[1])
				{
					//            nearid        status    name
					//Order weuhrweirewrqoehrqr joined quantomworks
					case "joined":
						//Recieving audio stream
						var ns:NetStream = new NetStream(c.netConnection,e.groupObject.split(" ")[0]);
						ns.play(SERVICE_NAME + currentGroup);
						
						//Index
						recieverNames.push(e.groupObject.split(" ")[2]);
						recieverNodes.push(ns);
						
						c.groupSendToAll(currentGroup, c.nearID + " exists " + _username);
						dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_CONNECTED, e.groupObject.split(" ")[2]));
						break;
					case "quit":
						for each (var ns:NetStream in recieverNodes)
						{
							if (ns.farID == e.groupObject.split(" ")[0])
							{
								recieverNames.splice(recieverNodes.indexOf(ns), 1);
								recieverNodes.splice(recieverNodes.indexOf(ns), 1);
							}
						}
						dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_DISCONNECTED, e.groupObject.split(" ")[2]));
						break;
					case "namechange": //nearid namechange oldusername newusername
						dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_NAMECHANGE, e.groupObject.split(" ")[2], e.groupObject.split(" ")[3]));
						break;
					case "exists":
						var ns:NetStream = new NetStream(c.netConnection, e.groupObject.split(" ")[0]);
						if (recieverNodes.indexOf(ns) == -1) //Only play and add if user isnt locally added by a join event or something of the sorts
						{
							ns.play(SERVICE_NAME + currentGroup);
							recieverNames.push(e.groupObject.split(" ")[2]);
							recieverNodes.push(ns);
							dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_CONNECTED, e.groupObject.split(" ")[2]));
						}
						break;
				}
			}
		}
		
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			senderNode = new NetStream(c.netConnection, NetStream.DIRECT_CONNECTIONS);
			senderNode.attachAudio(microphone);
			senderNode.publish(SERVICE_NAME + currentGroup);
			
			currentGroup = e.groupName;
			c.addHaveObject(currentGroup, 0, 0);
			c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleGroupObjectRequest);
			
			//c.groupSendToAll(currentGroup, c.nearID + " joined " + username); //Tell everyone in the group that you have arrived
			t.start();
		}
		
		private function handleGroupObjectRequest(e:NetworkGroupEvent):void 
		{
			
		}
		
		public function set microphone(value:Microphone):void 
		{
			if (currentGroup != null)
			{
				senderNode = new NetStream(c.netConnection, NetStream.DIRECT_CONNECTIONS);
				//Reset microphone
				senderNode.attachAudio(value);
				
				//Republish netstream
				senderNode.publish(SERVICE_NAME + currentGroup);
			}
			
			_microphone = value;
		}
		
		public function get microphone():Microphone 
		{
			return _microphone;
		}
		
		public function get username():String 
		{
			return _username;
		}
		
		public function set username(value:String):void 
		{
			if (currentGroup != "")
			{
				c.groupSendToAll(currentGroup, c.nearID + " namechange " + _username + " " + value);
			}
			_username = value;
		}
		
	}

}