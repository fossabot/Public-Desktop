package sfxworks 
{
	import air.net.URLMonitor;
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.desktop.NativeApplication;
	import flash.errors.IOError;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetGroup;
	import flash.net.URLLoader;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkErrorEvent;
	import sfxworks.NetworkUserEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import sfxworks.NetworkEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import sfxworks.NetworkGroupEvent;
	import mx.rpc.AsyncResponder;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class Communications extends EventDispatcher
	{
		private var _netConnection:NetConnection;
		private var mysqlConnection:Connection;
		
		
		//MyIdentity
		private var _name:String;
		private var _privateKey:ByteArray;
		private var _publicKey:ByteArray;
		private var _nearID:String;
		
		//Temps..
		private var nameChangeRequest:String;
		private var tmpargs:String;
		private var objectToSend:Object;
		
		private var timerRefresh:Timer;
		
		//URLMonitor
		private var monitor:URLMonitor;
		
		//Updater
		private var versionCheckLoader:URLLoader;
		private var versionCheckSource:URLRequest;
		private var applicationContent:XML;
		private var currentVersion:Number;
		
		//Group Management: For chat, video communication or whatever other services
		private var groups:Vector.<NetGroup>;
		private var groupNames:Vector.<String>;
		
		
		
		public function Communications() 
		{
			_netConnection = new NetConnection();
			_name = new String();
			_privateKey = new ByteArray();
			_publicKey = new ByteArray();
			
			nameChangeRequest = new String();
			tmpargs = new String();
			objectToSend = new Object();
			
			groups = new Vector.<NetGroup>();
			groupNames = new Vector.<String>();
			
			timerRefresh = new Timer(10000);
			
			_netConnection.connect("rtmfp://p2p.rtmfp.net", "-");
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, handleNetworkStatus);
			/* Send objects
			 * Send messages
			 * Recieve Objects
			 * Recieve Messages
			 * 
			 * Service Monitor
			 * */
			
			monitor = new URLMonitor(new URLRequest("http://youtube.com"));
			monitor.addEventListener(StatusEvent.STATUS, handleMonitorStatus);
			monitor.start();
			
			
			//Construct Updater
			versionCheckLoader = new URLLoader();
			versionCheckLoader.addEventListener(Event.COMPLETE, parseUpdateDetail);
			versionCheckLoader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			versionCheckSource = new URLRequest("http://sfxworks.net/application.xml");
			
			//Set version
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			currentVersion = new Number(parseFloat(appXML.ns::versionNumber));
			
			trace("COMMUNICATIONS: Applicaton Version = " + currentVersion);
			
		}
		
		//-- Group Management
		public function addGroup(groupName:String, groupSpecifier:GroupSpecifier):void
		{
			groupNames.push(groupName);
			var netGroup:NetGroup = new NetGroup(_netConnection, groupSpecifier.groupspecWithAuthorizations());
			groups.push(netGroup);
			trace("COMMUNICATIONS: Attempting to add group "  + groupName);
			trace("COMMUNICATIONS: Netgroup = " + netGroup);
		}
		
		public function removeGroup(groupName:String):void
		{
			var toRemove:NetGroup = this.getGroup(groupName);
			//Just remove from index since netconnection is the one that handles the event listeners
			groupNames.splice(groups.indexOf(toRemove), 1);
			groups.splice(groups.indexOf(toRemove), 1);
		}
		
		public function addWantObject(groupName:String, startIndex:Number, endIndex:Number):void //Requests objects from the group.
		{
			groups[groupName.indexOf(groupName)].addWantObjects(startIndex, endIndex);
		}
		
		public function addHaveObject(groupName:String, startIndex:Number, endIndex:Number):void //Adds a list of object the service, or whatever calls on commuication has.
		{
			trace("groupname = " + groupName);
			trace("start index = " + startIndex);
			trace("end index = " + endIndex);
			trace("Current group name = " + groupNames[0]);
			trace("Current group = " + groups[0]);
			groups[groupNames.indexOf(groupName)].addHaveObjects(startIndex, endIndex);
		}
		
		public function removeHaveObject(groupName:String, startIndex:Number, endIndex:Number):void
		{
			groups[groupNames.indexOf(groupName)].removeHaveObjects(startIndex, endIndex);
		}
		
		public function satisfyObjectRequest(groupName:String, objectNumber:Number, object:Object):void
		{
			groups[groupNames.indexOf(groupName)].writeRequestedObject(objectNumber, object);
		}
		
		public function postToGroup(groupName:String, object:Object):void
		{
			groups[groupNames.indexOf(groupName)].post(object);
		}
		
		public function getGroup(groupName:String):NetGroup
		{
			return groups[groupNames.indexOf(groupName)];
		}
		
		private function handleIOError(e:IOErrorEvent):void 
		{
			trace("COMMUNICATIONS: IO Error..");
		}
		
		private function handleSecurityError(e:SecurityErrorEvent):void
		{
			trace("COMMUNICATIONS: Security error..");
		}
		
		private function generateKey(size:int):ByteArray
		{
			var d:Date = new Date();
			var b:ByteArray = new ByteArray();
			b.writeFloat(d.getTime());
			
			for (var i:int = 0; i < size; i++)
			{
				b.writeFloat(Math.random());
			}
			
			return b;
		}
		
		private function handleMonitorStatus(e:StatusEvent):void 
		{
			if (monitor.available)
			{
				dispatchEvent(new NetworkEvent(NetworkEvent.CONNECTING, ""));
				mysql();
			}
			else
			{
				dispatchEvent(new NetworkEvent(NetworkEvent.DISCONNECTED, ""));
				timerRefresh.stop();
				timerRefresh.removeEventListener(TimerEvent.TIMER, networkTimerRefresh);
			}
		}
		
		private function handleNetworkStatus(e:NetStatusEvent):void 
		{
			switch(e.info.code)
			{ 
				case "NetConnection.Connect.Success":
					trace("COMMUNICATIONS: Net connection successful. Init mysql connection.");
					_nearID = _netConnection.nearID;
					mysql();
					break; 
				case "NetConnection.Connect.Closed":
					dispatchEvent(new NetworkEvent(NetworkEvent.DISCONNECTED, _netConnection.nearID));
					break; 
				case "NetConnection.Connect.Failed":
					dispatchEvent(new NetworkEvent(NetworkEvent.ERROR, "none")); //Will be null on error
					trace("netconnection error: = " + e.info.error);
					break;
				case "NetGroup.Connect.Success":
					trace("Can we get some info on " + e.info.group);
					trace("COMMUNICATIONS: Connection to group " + groupNames[groups.indexOf(e.info.group)] + " successful");
					//Dispatch connected event. Send group name in event handler
					dispatchEvent(new NetworkGroupEvent(NetworkGroupEvent.CONNECTION_SUCCESSFUL, groupNames[groups.indexOf(e.info.group)]));
					break; 
				case "NetGroup.Connect.Failed":
					//Dispatch when group connection failed. Remove from index
					trace("Connection to group " + groupNames[groups.indexOf(e.target)] + " failed");
					dispatchEvent(new NetworkGroupEvent(NetworkGroupEvent.CONNECTION_FAILED, groupNames[groups.indexOf(e.info.group)]));
					groupNames.splice(groups.indexOf(e.info.group), 1); //Remove from groupnames index
					groups.splice(groups.indexOf(e.info.group), 1); //Remove from groups index
					break;
				case "NetGroup.Posting.Notify": 
					dispatchEvent(new NetworkGroupEvent(NetworkGroupEvent.POST, groupNames[groups.indexOf(e.info.group)], e.info.message));
					break;
				case "NetGroup.Replication.Fetch.SendNotify": //Send when this is about to send a request to neighbor who has the obejct
					break;
				case "NetGroup.Replication.Fetch.Result": //When a neighbor has sent a requested object.
					dispatchEvent(new NetworkGroupEvent(NetworkGroupEvent.OBJECT_RECIEVED, groupNames[groups.indexOf(e.info.group)], e.info.object, e.info.index));
					break;
				case "NetGroup.Replication.Request": //When communications has the object and recieved a request for the object
					dispatchEvent(new NetworkGroupEvent(NetworkGroupEvent.OBJECT_REQUEST, groupNames[groups.indexOf(e.info.group)], null, e.info.index));
					break;
			}
		}
		
		public function requestObject(publickey:ByteArray, args:String):void
		{
			fetchFarIDFromKey(publickey);
			this.addEventListener(NetworkActionEvent.SUCCESS, requestObjectWithFarID);
			tmpargs = args;
		}
		
		private function requestObjectWithFarID(e:NetworkActionEvent):void 
		{
			this.removeEventListener(NetworkActionEvent.SUCCESS, requestObjectWithFarID);
			getNetstreamFromFarID(e.info as String).send("objectRequest", tmpargs);
		}
		
		private function objectRequest(args:String):void
		{
			//Format:
			//Target: Target service to handle the object request
			//Args: Arguments for said service
			//Example: SpaceService,0.0.0.0.0.0,defaultspace
			
			var argArray:Array = args.split(",");
			argArray.reverse();
			var target:String = argArray.pop(); //Target service for handling the argument
			argArray.reverse();
			
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.OBJECT_REQUEST, target, argArray));
		}
		
		public function sendObject(object:Object, publicKey:ByteArray):void
		{
			fetchFarIDFromKey(publicKey);
			this.addEventListener(NetworkActionEvent.SUCCESS, sendObjectWithFarID);
		}
		
		private function sendObjectWithFarID(e:NetworkActionEvent):void 
		{
			this.removeEventListener(NetworkActionEvent.SUCCESS, sendObjectWithFarID);
			getNetstreamFromFarID(e.info as String).send("recieveObject", objectToSend);
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.OBJECT_SENDING, "", "sending object to " + e.info));
		}
		
		private function recieveObject(object:Object):void
		{
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.OBJECT_RECIEVED, "", object));
		}
		
		public function call(publicKey:ByteArray):void
		{
			fetchFarIDFromKey(publicKey);
			this.addEventListener(NetworkActionEvent.SUCCESS, makeCall);
		}
		//Should include answering machine..
		
		private function makeCall(e:NetworkActionEvent):void 
		{
			this.removeEventListener(NetworkActionEvent.SUCCESS, makeCall);
			var farNS:NetStream = getNetstreamFromFarID(e.info as String);
			farNS.send("incommingcall", _netConnection.nearID);
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.CALLING, farNS.farID, "ring ring"));
		}
		
		public function fetchFarIDFromKey(publicKey:ByteArray):void
		{
			var s:Statement = mysqlConnection.createStatement();
			s.sql = "SELECT `nearid` from `users` WHERE `publickey`=?;";
			s.setBinary(1, publicKey);
			var t:MySqlToken = s.executeQuery();
			t.addResponder(new AsyncResponder(fetchNearIDFromKeySuccess, fetchNearIDFromKeyError, t));
		}
		
		private function fetchNearIDFromKeyError(info:Object, token:MySqlToken):void
		{
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, info));
		}
		
		private function fetchNearIDFromKeySuccess(data:Object, token:MySqlToken):void 
		{
			var rs:ResultSet = new ResultSet(token);
			
			if (rs.next())
			{
				var farid:String = rs.getString("nearid");
				dispatchEvent(new NetworkActionEvent(NetworkActionEvent.SUCCESS, farid));
			}
			else
			{
				this.removeEventListener(NetworkActionEvent.SUCCESS, makeCall);
				trace("COMMUNICATIONS: COULDNT FIND TARGET");
				dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, data));
			}
		}
		
		private function incommingcall(farid:String):void
		{
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.INCOMMING_CALL, farid, "ring ring"));
		}
		
		
		private function handleIncommingBroadcast(user:String, message:String):void
		{
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.MESSAGE, user, message));
		}
		
		private function mysql():void
		{
			mysqlConnection = new Connection("-", 9001, "-", "-", "-");
			mysqlConnection.connect();
			mysqlConnection.addEventListener(Event.CONNECT, handleMysqlConnection);
			mysqlConnection.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			mysqlConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			trace("COMMUNICATIONS: Attemting to connect to mysql main server");
		}
		
		private function handleMysqlConnection(e:Event):void 
		{
			trace("COMMUNICATIONS: Connected.");
			mysqlConnection.removeEventListener(Event.CONNECT, handleMysqlConnection);
			
			var f:File = new File();
			f = File.applicationStorageDirectory.resolvePath(".s2key");
			var fs:FileStream = new FileStream();
			var st:Statement = mysqlConnection.createStatement();
			trace("COMMUNICATIONS: Checking key.");
			if (f.exists) //Update
			{
				trace("Exists.");
				fs.open(f, FileMode.READ);
				fs.readBytes(_privateKey, 0, 4000); //Read key into identity
				fs.readBytes(_publicKey, 0, 24); //Read public key into identity
				fs.close();
				
				st.sql = "UPDATE users "
				+ "SET `nearid`='"+_netConnection.nearID+"' "
				+ "WHERE `key`=?;";
				st.setBinary(1, _privateKey);
			}
			else //Register
			{
				trace("COMMUNICATIONS: Nonexistant. Registering..");
				_privateKey = generateKey(999);
				_publicKey = generateKey(5);
				_name = File.userDirectory.name;
				
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(_privateKey);
				fs.writeBytes(_publicKey);
				fs.close();
				
				st.sql = "INSERT INTO users (`name`, `nearid`, `key`, `publickey`)"
					+ " VALUES ('"+File.userDirectory.name+"','"+_netConnection.nearID+"',?,?);";
				st.setBinary(1, _privateKey);
				st.setBinary(2, _publicKey);
			}
			
			trace("COMMUNICATIONS: Sending query to server..");
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(mysqlNearIDUpdateSuccess, mysqlNearIDUpdateError, t));
			
			timerRefresh = new Timer(40000);
			timerRefresh.addEventListener(TimerEvent.TIMER, networkTimerRefresh);
			timerRefresh.start();
		}
		
		private function networkTimerRefresh(e:TimerEvent):void 
		{
			checkForUpdate();
		}
		
		private function checkForUpdate():void 
		{
			trace("COMMUNICATIONS: Checking for update..");
			try
			{
				versionCheckLoader.load(versionCheckSource);
			}
			catch(ioerror:IOError)
			{
				trace("COMMUNICATIONS: ioError from version checker. " + ioerror.message);
			}
			trace("End of check for update function..");
		}
		
		private function parseUpdateDetail(e:Event):void
		{
			applicationContent = new XML(versionCheckLoader.data);
			var ns:Namespace = applicationContent.namespace();
			var standardVersion:Number = new Number(parseFloat(applicationContent.ns::currentVersion));
			var source:String = new String(applicationContent.ns::source);
			
			trace("COMMUNICATIONS: Standard version = " + standardVersion);
			trace("COMMUNICATIONS: Current version = " + currentVersion);
			
			if (standardVersion > currentVersion)
			{
				dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE, standardVersion, source));
				trace("COMMUNICATIONS: New Version Avalible");
			}
		}
		
		private function mysqlNearIDUpdateError(info:Object, token:MySqlToken):void 
		{
			dispatchEvent(new NetworkEvent(NetworkEvent.ERROR, null));
			trace("COMMUNICATIONS: Update error.");
		}
		
		private function mysqlNearIDUpdateSuccess(data:Object, token:MySqlToken):void 
		{
			trace("COMMUNICATIONS: Update success.");
			dispatchEvent(new NetworkEvent(NetworkEvent.CONNECTED, _netConnection.nearID));
		}
		
		public function get privateKey():ByteArray 
		{
			return _privateKey;
		}
		
		public function get publicKey():ByteArray 
		{
			return _publicKey;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function set name(value:String):void 
		{
			_name = value;
		}
		
		public function get nearID():String 
		{
			return _nearID;
		}
		
		public function get netConnection():NetConnection 
		{
			return _netConnection;
		}
		
		public function nameChange(name:String):void
		{
			nameChangeRequest = name;
			var st:Statement = mysqlConnection.createStatement();
			st.sql = "UPDATE users "
				+ "SET `name`='"+name+"' "
				+ "WHERE `key`=?;";
			st.setBinary(1, _privateKey);
			
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(nameChangeResponderSuccess, nameChangeResponderError, t));
			trace("COMMUNICATIONS: Name change triggered.");
		}
		
		private function nameChangeResponderSuccess(data:Object, token:MySqlToken):void
		{
			trace("COMMUNICATIONS: Name change response success..");
			_name = nameChangeRequest;
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.SUCCESS, data));
		}
		
		private function nameChangeResponderError(info:Object, token:MySqlToken):void
		{
			trace("COMMUNICATIONS: Name change response error:" + info);
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, info));
		}
		
	}

}