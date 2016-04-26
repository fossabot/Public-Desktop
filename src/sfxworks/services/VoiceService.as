package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Microphone;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.events.NodeEvent;
	import sfxworks.services.events.VoiceServiceEvent;
	import sfxworks.services.nodes.VoiceServiceNodeClient;
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
		private var gspec:GroupSpecifier;
		private var _username:String;
		
		
		private var publicNodeI:NetStream; //Used for sending to all groups
		private var publicNodeO:NetStream;
		
		private var _senderNode:NetStream;
		private var recieverNames:Vector.<String>;
		private var recieverKeys:Vector.<ByteArray>;
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
			_microphone.setSilenceLevel(10);
			username = new String(c.name);
			
			t = new Timer(500);
			t.addEventListener(TimerEvent.TIMER, detectActivity);
		}
		
		private function detectActivity(e:TimerEvent):void 
		{
			var i:int = 0;
			for each (var node:NetStream in recieverNodes)
			{
				dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_AUDIO_ACTIVITY, recieverNames[i], "", node.info.audioByteCount));
				i++; //faster vs searching through each vector for index of node
			}
		}
		
		public function connectToGroup(name:String, password:String=""):void
		{
			recieverNames = new Vector.<String>();
			recieverNodes = new Vector.<NetStream>(); //it should garbage collect the old NetStreams..in theory
			recieverKeys = new Vector.<ByteArray>();
			
			currentGroupPassword = password;
			
			gspec = new GroupSpecifier(SERVICE_NAME + name + password);
			gspec.serverChannelEnabled = true;
			gspec.multicastEnabled = true;
			gspec.objectReplicationEnabled = true;
			
			c.addGroup(SERVICE_NAME + name + password, gspec);
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
		}
		
		//Handle disconnecting users (experimental)
		private function handleNodeStatus(e:NetStatusEvent):void 
		{
			switch(e.info)
			{
				case "NetStream.Play.Stop":
					//e.target = netestream
					dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_DISCONNECTED, recieverNames[recieverNodes.indexOf(e.target)]));
					recieverNames.splice(recieverNodes.indexOf(e.target), 1);
					recieverNodes.splice(recieverNodes.indexOf(e.target), 1);	
					break;
			}
		}
		
		//Handle self disconnecting
		public function disconnectFromGroup():void
		{
			//Tell communications to remove from index
			c.removeGroup(currentGroup + currentGroupPassword);
			
			//Remove from index
			currentGroup = null;
			currentGroupPassword = null;
			_senderNode = new NetStream(c.netConnection, NetStream.DIRECT_CONNECTIONS);
			recieverNodes = new Vector.<NetStream>();
		}
		
		//Handle successful connection to group
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			c.removeEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			c.addEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulStreamConnection);
			
			_senderNode = new NetStream(c.netConnection, gspec.groupspecWithoutAuthorizations());
			publicNodeI = new NetStream(c.netConnection, gspec.groupspecWithoutAuthorizations());
			publicNodeO = new NetStream(c.netConnection, gspec.groupspecWithoutAuthorizations());
			
			currentGroup = e.groupName;
			t.start();	
		}
		
		
		//Habdle stream connection from communications. IO handled for group ns
		private function handleSuccessfulStreamConnection(e:NetworkActionEvent):void 
		{
			switch(e.info)
			{
				case publicNodeI:
					trace("vs: Handling public node inbound");
					var vsnc:VoiceServiceNodeClient = new VoiceServiceNodeClient();
					publicNodeI.client = vsnc;
					publicNodeI.play(SERVICE_NAME + currentGroup + currentGroupPassword);
					vsnc.addEventListener(NodeEvent.INCOMMING_DATA, handleIncommingData);
					trace("Public node listening on " + SERVICE_NAME + currentGroup + currentGroupPassword);
					break;
				case publicNodeO:
					trace("vs: Handling public node outbound");
					publicNodeO.client = new VoiceServiceNodeClient();
					publicNodeO.publish(SERVICE_NAME + currentGroup + currentGroupPassword);
					publicNodeO.send("vsncdata", baToString(c.publicKey));
					trace("Public node sending on " + SERVICE_NAME + currentGroup + currentGroupPassword);
					break;
				case _senderNode:
					trace("vs: Handling sender node");
					_senderNode.attachAudio(_microphone);
					_senderNode.publish(baToString(c.publicKey));
					trace("Publishing audio feed on " + baToString(c.publicKey));
					break;
			}
		}
		
		
		//Handle incomming netstream data sent from O stream [Handle joining users]
		private function handleIncommingData(e:NodeEvent):void 
		{
			trace("vs: Incomming data from public node " + e.data);
			
			trace("vs: user:" + e.data.name);
			trace("vs: PublicKey:" + e.data.publicKey);
			
			//If the incomming key isn't it's own && it's not something already in the index
			
			if (c.publicKey != e.data.publicKey && recieverKeys.indexOf(e.data.publicKey) == -1)
			{
				trace("vs: New user:" + e.data.name);
				trace("vs: PublicKey:" + e.data.publicKey);
				//If it cannot find the new connecting public key in itself or within its already listening nodes
				
				//Create and play the netstream
				var ns:NetStream = new NetStream(c.netConnection, gspec.groupspecWithoutAuthorizations());
				ns.addEventListener(NetStatusEvent.NET_STATUS, handleNodeStatus);//>Implying
				ns.play(baToString(e.data.publicKey)); //>Implying
				
				//Add to index
				recieverNames.push(e.data.name);
				recieverKeys.push(e.data.key);
				recieverNodes.push(ns);
				
				//Announce publickey to group for the new user.
				//Could do it for the user, but eh.
				var toSend:Object = new Object();
				toSend.publicKey = c.publicKey;
				toSend.name = c.name;
				
				publicNodeO.send("data", toSend);
				
				//TODO: Have it target the newcommer vs the entire group each node in the group doesnt have to listen to existing users.
				//In the case scenario where theres 9034712192-85324952349572345-24957248975139847139856324056^3 connected users in a group
				// V all to point of extinction type function
				
				//Optionally send name later on. Maybe include some sort of name resolver
				dispatchEvent(new VoiceServiceEvent(VoiceServiceEvent.USER_CONNECTED, e.data.name));
			}
			
		}
		
		public function set microphone(value:Microphone):void 
		{
			_microphone = value;
			if (currentGroup != null)
			{
				_senderNode = new NetStream(c.netConnection, gspec.groupspecWithoutAuthorizations());
				//Reset microphone
			}
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
			c.nameChange(value);
			_username = value;
		}
		
		public function get senderNode():NetStream 
		{
			return _senderNode;
		}
		
		//Util
		private function baToString(bytearray:ByteArray):String
		{
			var str:String = new String();
			for (var i:int = 0; i < 6; i++)
			{
				str += bytearray.readInt().toString() + ".";
			}
			return str;
		}
		
	}

}