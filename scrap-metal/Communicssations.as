package 
{
	import adobe.utils.CustomActions;
	import air.net.URLMonitor;
	import com.fleo.irc.events.IRCErrorEvent;
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlResponse;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.desktop.FilePromiseManager;
	import flash.desktop.NativeApplication;
	import flash.display.IDrawCommand;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import mx.rpc.Responder;
	import flash.events.NetStatusEvent;
	import mx.rpc.AsyncResponder;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class Communications extends MovieClip   //Indexing, handling of calls, video calls, and desktop requests
	{
		private var micID:int;
		private var cameraID:String;
		
		/*
		 * Caller Movieclip [Calltab.as]
		 *  |- accept_btn
		 *  |- deny_btn
		 *  |- Frame 2:
		 *  |- soundwave_mc (visual display of sound from that caller's sound)
		 *  |- end_btn
		 * 
		 */
		
		//Resourcse
		private var t:Timer; //Timer
		private var conn:Connection; //Mysql 
		
		//Indexes
		private var publicKeys:Vector.<ByteArray>;
		private var nearIDs:Vector.<String>;
		private var names:Vector.<String>;
		private var friends:Vector.<Identity>;
		private var activeNetConnections:Vector.<NetStream>;
		private var myNetStream:NetStream;
		
		private var myIdentity:Identity;
		public var nc:NetConnection;
		
		private var _theirDesktop:MovieClip;
		
		private var monitor;
		private var callType:Boolean;
		
		private var logFs:FileStream;
		private var logFile:File;
		
		private var refreshType:String;
		private var refreshArg:String;
		
		public function Communications()
		{
			trace("The wrong communications..");
			logFile = new File();
			logFile = File.applicationStorageDirectory.resolvePath("log8.txt");
			logFs = new FileStream();
			
			
			log("starting communications..");
			
			hover_mc.alpha = 0;
			micID = 0;
			
			monitor = new URLMonitor(new URLRequest('http://www.adobe.com'));
			monitor.addEventListener(StatusEvent.STATUS, handleNetworkStatus);
			monitor.start();
			
			this.addEventListener(MouseEvent.ROLL_OVER, handleMouseOver);
			this.addEventListener(MouseEvent.ROLL_OUT, handleMouseOut);
			
			chat_mc.addEventListener(MouseEvent.ROLL_OVER, alphaRollOver);
			chat_mc.addEventListener(MouseEvent.ROLL_OUT, alphaRollOut);
		}
		
		private function alphaRollOut(e:MouseEvent):void 
		{
			var alpjhaTweenOut:Tween = new Tween(chat_mc.bg_mc, "alpha", Strong.easeOut, 1, 0, .5, true);
		}
		
		private function alphaRollOver(e:MouseEvent):void 
		{
			var alpjhaTweenIn:Tween = new Tween(chat_mc.bg_mc, "alpha", Strong.easeOut, 0, 1, .5, true);
		}
		
		private function handleChatClick(e:MouseEvent):void 
		{
			trace("Handle chat");
		}
		
		private function videoCallButtonClick(e:MouseEvent):void 
		{
			trace("Handle Video Call");
			log("Handling video call");
			log("Converting text to bytearray");
			var netidin:Array = status_mc.netid_txt.text.split(".");
			var ba:ByteArray = new ByteArray();
			for each (var number:String in netidin)
			{
				var integer:int = new int(number); //Convert string to int
				ba.writeInt(integer);
				log("Wrote " + integer.toString());
			}
			call(ba, false);
		}
		
		private function callButtonClick(e:MouseEvent):void 
		{
			trace("Handle call");
			var netidin:Array = status_mc.netid_txt.text.split(".");
			var ba:ByteArray = new ByteArray();
			for each (var number:String in netidin)
			{
				var integer:int = new int(number); //Convert string to int
				ba.writeInt(integer);
			}
			call(ba, true);
		}
		
		private function handleMouseOut(e:MouseEvent):void 
		{
			var tweenOut:Tween = new Tween(this, "x", Strong.easeOut, stage.stageWidth - 120, stage.stageWidth, .5, true);
		}
		
		private function handleMouseOver(e:MouseEvent):void 
		{
			var tweenIn:Tween = new Tween(this, "x", Strong.easeOut, stage.stageWidth, stage.stageWidth - 120, .5, true);
		}
		
		private function handleNetworkStatus(e:StatusEvent):void 
		{
			log("Network status change. Current status = " + monitor.available);
			if (monitor.available == true)
			{
				log("Can connect.");
				nc = new NetConnection();
				nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.connect("rtmfp://p2p.rtmfp.net", "e0708320bf4003e01aa0bcd1-ee3e9ec0c03a");
				status_mc.gotoAndStop(1);
			}
			else
			{
				log("Disconnected.");
				status_mc.gotoAndStop(3);
				chat_mc.input_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleChatKeyDown);
				status_mc.call_btn.removeEventListener(MouseEvent.CLICK, callButtonClick);
				status_mc.videocall_btn.removeEventListener(MouseEvent.CLICK, videoCallButtonClick);
				status_mc.chat_btn.removeEventListener(MouseEvent.CLICK, handleChatClick);
			}
		}
		
		private function init():void
		{
			log("Initializng secondary connections..");
			//Constructors
			publicKeys = new Vector.<ByteArray>();
			nearIDs = new Vector.<String>();
			names = new Vector.<String>();
			myIdentity = new Identity();
			myIdentity.nearID = nc.nearID;
			myIdentity.name = File.userDirectory.name;
			myNetStream = new NetStream(nc);
			
			
			//Domain, Port, username, password, database
			conn = new Connection("173.194.238.40", 3306, "application", "v69q036c71059c812433#_$%55**02", "application");
			conn.addEventListener(Event.CONNECT, handleConnected);
			conn.connect();
			log("Connecting to remote database");
			
			myNetStream.publish("desktop");
			log("Publishing channel [desktop] for subscribers.");
			//NEW --- Communications update
			//Publish to server, allowing anyone to hook
			//That is the name of THIS NET STREAM. desktop.
		}
		
		private function netStatusHandler(e:NetStatusEvent):void
		{ 
			nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			
			switch(e.info.code)
			{ 
				case "NetConnection.Connect.Success":
					log("Connected to cirrus.");
					init();
					break; 
				case "NetConnection.Connect.Closed":
					log("Connection to cirrus closed.");
					break; 
				case "NetConnection.Connect.Failed":
					log("Connection to cirrus failed.");
					break;  
			}
		}
		
		private function call(publicKey:ByteArray, audioOnly:Boolean):void
		{
			log("Finding nearid from public key.");
			
			refresh();
			callType = new Boolean(audioOnly);
			var getNearIDFromPublicKeyStatement:Statement = new Statement(conn);
			getNearIDFromPublicKeyStatement.sql = "SELECT `nearid` FROM `users` WHERE `publickey` = ?"; //A little sloppy
			getNearIDFromPublicKeyStatement.setBinary(1, publicKey);
			log("[SQL]" + getNearIDFromPublicKeyStatement.sql);
			
			var getNearIDFromPublicKeyToken:MySqlToken = getNearIDFromPublicKeyStatement.executeQuery();
			getNearIDFromPublicKeyToken.addResponder(new AsyncResponder(handleNearIDForCall, error, getNearIDFromPublicKeyToken));
		}
		
		private function handleNearIDForCall(data:Object, token:MySqlToken):void
		{
			log("Handling response from database.");
			var rs:ResultSet = new ResultSet(token);
			var farID:String = new String();
			if (rs.next())
			{
				farID = rs.getString("nearid");
			}
			log("[SQL] Returned value = " + farID);
			if (farID == "")
			{
				status_mc.netid_txt.text = "invalid iD";
				log("Could not find id");
			}
			else
			{
				var theirNetstream:NetStream = activeNetConnections[nearIDs.indexOf(farID)];
				theirNetstream.send("requestCall", myIdentity.nearID);
				log("Sending call request to " + names[nearIDs.indexOf(farID)] + "@" + farID);
			}
		}
		
		public function requestCall(farID:String):void
		{
			log("--> call requested from " + farID);
			var ct:CallTab = new CallTab(activeNetConnections[nearIDs.indexOf(farID)], myNetStream, true, micID, callType, cameraID);
			ct.x = -350;
			ct.y = 0;
			addChild(ct);
		}
		
		public function acceptCall(farID:String):void
		{
			log("<-- Accepting call from " + farID);
			var ct:CallTab = new CallTab(activeNetConnections[nearIDs.indexOf(farID)], myNetStream, false, micID, callType, cameraID);
			ct.x = -350;
			ct.y = 0;
			addChild(ct);
		}
		
		public function configureMicrophone(number:int):void
		{
			micID = number;
			//Set micid
		}
		
		public function configureCamera(name:String):void
		{
			cameraID = name;
		}
		
		public function getDesktop(publicKey:ByteArray):void //Type in, convert string to byte array. Query server for target's near id, connect to them
		{
			var getNearIDFromPublicKeyStatement:Statement = conn.createStatement();
			getNearIDFromPublicKeyStatement.sql = "SELECT nearid FROM users WHERE publickey = ?";
			getNearIDFromPublicKeyStatement.setBinary(1, publicKey);
			//Not doing this locally cause that'd be huge. Only taking account for friends.
			
			var getNearIDFromPublicKeyToken:MySqlToken = getNearIDFromPublicKeyStatement.executeQuery();
			getNearIDFromPublicKeyToken.addResponder(new AsyncResponder(handleNearIDForDesktop, error));
		}
		//^ - v
		private function handleNearIDForDesktop(data:Object, token:Object):void
		{
			var rs:ResultSet = ResultSet(data);
			var farID:String;
			
			if (rs.next())
			{
				//get their desktop
				farID = rs.getString("nearid"); //Returns their nearID
				var ns:NetStream = new NetStream(nc, farID); //Connect directly to them
				ns.send("requestDesktop", myIdentity.nearID); //Theyre going to get it because we do a public on init()
				
				//Send over this application's nearID
			}
			else
			{
				//Throw error
			}
		}
		
		public var myDesktop:MovieClip;
		public function requestDesktop(theirID:String):void
		{
			//Send over desktop
			//Get their netstream
			var theirNetStream:NetStream = activeNetConnections[activeNetConnections.indexOf(new NetStream(nc, theirID))];
			//send it over
			theirNetStream.send("reciveDesktop", myDesktop);
		}
		
		
		public function recieveDesktop(dt:MovieClip)
		{
			_theirDesktop.addChild(dt);
			//Dont even throw an event listener. Just put it in a container. It'll load when it loads.
		}
		
		private function refresh():void
		{
			//Get all net streams [For now, get all. In the future, get updated ones] (save server load)
			//conn = new Connection("project-desktop.sfxworks.net", 3306, "application", "v69q036c71059c812433#_$%55**02", "registry");
			//Should already be connected to the db
			log("Refreshing netstreams..");
			
			var getAllConnectionsStatement:Statement = conn.createStatement();
			getAllConnectionsStatement.sql = "SELECT `nearid` FROM `users`;";
			var getAllConnectionsToken:MySqlToken = getAllConnectionsStatement.executeQuery();
			log("[SQL]" +getAllConnectionsStatement.sql);
			
			getAllConnectionsToken.addResponder(new AsyncResponder(handleAllStreams, error));
		}
		
		private function handleAllStreams(data:Object, token:Object):void
		{
			log("Handling response from database");
			var rs:ResultSet = ResultSet(data);
			if (rs.next())
			{
				trace("Result set from refresh = " + rs);
				trace("RS size = " + rs.size());
				
				var raw:Array = new Array();
				for (var i:int = 0; i < rs.size(); i++)
				{
					raw.push(rs.getString("nearid").toString());
					rs.next();
				}
				
				log("[SQL] returned response: " + raw);
				trace("RAW SIZe = " + raw.length);
				
				for (var i:int = 0; i < rs.size(); i++)
				{
					trace("Adding farid:" + raw[i]);
					//Do a search to see if we already subscribed to them and are playing them.
					//Handle drops and reconnects later. [Or just recreate the list everytime]
					//activeNetConnections = new Vector.<NetStream>;
					
					//Subscribe to them
					var ns:NetStream = new NetStream(nc, raw[i]); //Connect to their PC
					ns.play("desktop"); //Subscribe to them on the desktop channel
					log("Connecting to " + raw[i]);
					log("Subscribing to stream [desktop]");
					//Index it.
					activeNetConnections.push(ns);
					log("Adding " + ns.toString() + " to index.");
				}
			}
			
			switch(refreshType)
			{
				case "chat":
					for each (var ns:NetStream in activeNetConnections)
					{
						ns.send("recieveMessage", "[" + myIdentity.name + "]" + refreshArg); //Send message to all connections
						log("Sending message..");
						chat_mc.display_txt.appendText("[" + myIdentity.name + "]" + refreshArg);
						chat_mc.display_txt.appendText("\n");
					}
					break;
			}
		}
		
		public function removeFriend(publickey:ByteArray):void
		{
			var removeFriendStatement:Statement = new Statement(conn);
			removeFriendStatement.sql = "UPDATE keys "
										+ "SET keys = REPLACE(keys, ?, '') "
										+ "WHERE nearID = " + myIdentity.nearID;
			removeFriendStatement.setBinary(1, publickey);
			
			var removeFriendToken:MySqlToken = removeFriendStatement.executeQuery(); //Throw the removal to the server
			removeFriendToken.addResponder(new Responder(success, error)); //TODO: Make responders throw event listeners
			
			var indexOfX:int = publicKeys.indexOf(publickey); //Fetch index by matching it to public keys
			publicKeys = publicKeys.splice(indexOfX, 1); //Remove
			nearIDs = nearIDs.splice(indexOfX, 1); //From each
			names = names.splice(indexOfX, 1); //Vector
		}
		
		public function addFriend(nearID:String):void //Public.
		{
			//Ask server vs user I guess
			var newFriendStatement:Statement = new Statement(conn);
			newFriendStatement.sql = "SELECT publickey FROM users WHERE nearid = " + nearID;
			var newFriendToken:MySqlToken = newFriendStatement.executeQuery();
			newFriendToken.addResponder(new Responder(handleNewFriendKey, error));
			
			var getNewFriendNameStatement:Statement = new Statement(conn);
			getNewFriendNameStatement.sql = "SELECT name FROM users WHERE nearid = " + nearID;
			var getNewFriendNameToken:MySqlToken = getNewFriendNameStatement.executeQuery();
			getNewFriendNameToken.addResponder(new Responder(handleNewFriendName, error));
			
			nearIDs.push(nearID); //Push nearid [No real way to handle if an error occurs in getting the name..] [Might just update() and wipe and reset vectors]
		}
		
		public function getFriendsList():Vector.<Identity>
		{
			var returnVector:Vector.<Identity>;
			for (var i:int = 0; i < publicKeys.length; i++)
			{
				var id:Identity = new Identity();
				id.publicKey = publicKeys[i];
				id.name = names[i];
				id.nearID = nearIDs[i];
				returnVector.push(id);
			}
			
			return returnVector;
		}
		private function handleNewFriendName(data:Object, token:Object):void
		{
			var rs:ResultSet = ResultSet(data);
			if (rs.next())
			{
				names.push(rs.getString("name")); //Push name
			}
		}
		
		private function handleNewFriendKey(data:Object, token:Object):void //Get publickey Throw public key to owned column
		{
			var rs:ResultSet = ResultSet(data);
			if (rs.next())
			{
				var st:Statement = new Statement(conn);
				st.sql = "UPDATE users SET keys = keys + ? WHERE nearid = " + myIdentity.nearID;
				st.setBinary(1, rs.getBinary("publickey"));
				var t:MySqlToken = st.executeQuery();
				t.addResponder(new Responder(success, error));
			}
			
		}
		
		private function generateKey(size:int):ByteArray
		{
			log("Generating key with a size of " + size.toString());
			var d:Date = new Date();
			var b:ByteArray = new ByteArray();
			b.writeFloat(d.getTime());
			
			for (var i:int = 0; i < size; i++)
			{
				b.writeFloat(Math.random());
			}
			
			return b;
		}
		
		private function handleConnected(e:Event):void //Handle Connection (start of process)
		{
			conn.removeEventListener(Event.CONNECT, handleConnected);
			log("MYSQL Connection successful.");
			if (File.applicationStorageDirectory.resolvePath(".key300").exists)
			{
				log("User exists.");
				//Read saved key from local file storage
				var f:File = new File();
				f = File.applicationStorageDirectory.resolvePath(".key300");
				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.READ);
				fs.readBytes(myIdentity.key, 0, 4000); //Read key into identity
				fs.readBytes(myIdentity.publicKey, 0, 24); //Read public key into identity
				fs.close();
				
				update(); //Getting friends from server
			}
			else
			{
				log("A new user. Generating key.");
				myIdentity.key = generateKey(999); //4000 bytes
				myIdentity.publicKey = generateKey(5); //6 numbers total. 6x4 = 24 bytes
				myIdentity.name = File.userDirectory.name;
				
				//Generate key, then update. First run.
				var f:File = new File();
				f = File.applicationStorageDirectory.resolvePath(".key300");
				var fs:FileStream = new FileStream();
				
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(myIdentity.key);
				fs.writeBytes(myIdentity.publicKey);
				fs.close();
				
				register();
			}
		}
		
		private function update():void //Fetch Keys
		{
			log("Updating user in mysql db");
			var st:Statement = conn.createStatement();
			st.sql = "UPDATE users "
				+ "SET `nearid`='"+myIdentity.nearID+"' "
				+ "WHERE `key`=?;";
			st.setBinary(1, myIdentity.key);
			
			//log("NEARID = " + myIdentity.nearID.toString());
			//log("KEY = " + myIdentity.key.toString());
			
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(success, error, t));
		}
		
		private function handleIncommingKeys(data:Object, token:Object):void //Get Public Keys throw back Public Keys
		{
			var rs:ResultSet = ResultSet(data);
			var keys:ByteArray;
			if (rs.next())
			{
				keys = rs.getBinary("keys");
			}
			else
			{
				log("Error.");
			}
			
			var nearIDStatement:Statement = conn.createStatement();
			var nameStatement:Statement = conn.createStatement();
			
			var numberOfKeys:int = keys.length / 40;
			for (var i:int = 0; i < numberOfKeys; i++)
			{
				var key:ByteArray = new ByteArray();
				keys.writeBytes(key, 40 * i, 40); //Each key is 40 bytes, so split here
				nearIDStatement.sql = "SELECT nearid FROM users WHERE publickey = ?"; //Assuming I can add and get multi back
				nearIDStatement.setBinary(i + 1, key);
				
				nameStatement.sql = "SELECT name FROM users WHERE publickey = ?";
				nameStatement.setBinary(i + 1, key);
				
				publicKeys.push(key); //Add to index
			}
			
			var nearIDToken:MySqlToken = nearIDStatement.executeQuery();
			nearIDToken.addResponder(new Responder(handleIncommingNearID, error));
			
			var nameToken:MySqlToken = nameStatement.executeQuery();
			nameToken.addResponder(new Responder(handleIncommingNames, error));
		}
		
		private function handleIncommingNearID(data:Object, token:Object):void //Handle incomming NEARID from Tokens
		{
			var rs:ResultSet = ResultSet(data);
			if (rs.next())
			{
				nearIDs.push(rs.getString("nearid")); //Add to index
			}
		}
		
		private function handleIncommingNames(data:Object, token:Object):void //Handle incomming NAMES from Tokens
		{
			var rs:ResultSet = ResultSet(data);
			if (rs.next())
			{
				names.push(rs.getString("name")); //Add to index
			}
		}
		
		private function register():void //On First Register
		{
			var st:Statement = conn.createStatement();
			st.sql = "INSERT INTO users (`name`, `nearid`, `key`, `publickey`)"
				+ " VALUES ('"+File.userDirectory.name+"','"+myIdentity.nearID+"',?,?);";
			log("NearID = " + myIdentity.nearID);
			st.setBinary(1, myIdentity.key);
			st.setBinary(2, myIdentity.publicKey);
			
			//log("kEY = " + myIdentity.key.toString());
			//log("PUBLIC KEY = " + myIdentity.publicKey.toString());
			
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(success, error, t));
			
		}
		
		private function success(data:Object, token:MySqlToken)
		{
			log("Success.");
			status_mc.gotoAndStop(2);
			
			for (var i:int = 0; i < 6; i++)
			{
				status_mc.publickey_txt.appendText(myIdentity.publicKey.readInt() + ".");
			}
			var tweenOut:Tween = new Tween(this, "x", Strong.easeOut, stage.stageWidth - 120, stage.stageWidth, .5, true);
			
			status_mc.call_btn.addEventListener(MouseEvent.CLICK, callButtonClick);
			status_mc.videocall_btn.addEventListener(MouseEvent.CLICK, videoCallButtonClick);
			status_mc.chat_btn.addEventListener(MouseEvent.CLICK, handleChatClick);
			//status_mc.publickey_txt.text = myIdentity.publicKey.toString();
			
			
			//Chat --
			chat_mc.input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleChatKeyDown);
		}
		
		private function handleChatKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				sendMessage(chat_mc.input_txt.text);
				chat_mc.input_txt.text = "";
			}
		}
		
		private function error(info:Object, token:Object)
		{
			log("Error: " + info);
			log("TOKEN: " + token);
		}
		
		public function get theirDesktop():MovieClip 
		{
			return _theirDesktop;
		}
		
		//Chat --- 
		public function sendMessage(message:String):void
		{
			refresh();
			refreshType = new String("chat");
			refreshArg = new String(message);
			trace("Sending message");
		}
		
		public function recieveMessage(message:String):void
		{
			chat_mc.display_txt.appendText("\n");
			chat_mc.dispaly_txt.appendText(message);
		}
		
		
		//Log handling.
		private function log(message:String):void
		{
			logFs.open(logFile, FileMode.APPEND);
			var d:Date = new Date();
			logFs.writeUTFBytes("[" + d.getTime().toString() + "]:" + message);
			logFs.writeUTFBytes("\n");
			logFs.close();
		}
		
	}

}