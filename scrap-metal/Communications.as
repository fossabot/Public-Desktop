package sfxworks 
{
	import air.net.URLMonitor;
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.desktop.NativeApplication;
	import flash.events.IOErrorEvent;
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
	import mx.rpc.AsyncResponder;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class Communications extends EventDispatcher
	{
		private var netConnection:NetConnection;
		private var netConnections:Vector.<NetStream>;
		private var mysqlConnection:Connection;
		private var _myNetConnection:NetStream;
		
		
		//MyIdentity
		private var _name:String;
		private var _privateKey:ByteArray;
		private var _publicKey:ByteArray;
		
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
		
		
		public function Communications() 
		{
			netConnection = new NetConnection();
			netConnections = new Vector.<NetStream>();
			_name = new String();
			_privateKey = new ByteArray();
			_publicKey = new ByteArray();
			
			nameChangeRequest = new String();
			tmpargs = new String();
			objectToSend = new Object();
			
			timerRefresh = new Timer(10000);
			
			netConnection.connect("rtmfp://p2p.rtmfp.net", "-");
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, handleNetworkStatus);
			/* Send objects
			 * Send messages
			 * Recieve Objects
			 * Recieve Messages
			 * 
			 * Service Monitor
			 * */
			
			monitor = new URLMonitor(new URLRequest("http://sfxworks.net"));
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
			
			trace("Applicaton Version = " + currentVersion);
		}
		
		private function handleIOError(e:IOErrorEvent):void 
		{
			trace("IO Error..");
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
					trace("Net connection successful. Init mysql connection.");
					_myNetConnection = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
					mysql();
					break; 
				case "NetConnection.Connect.Closed":
					dispatchEvent(new NetworkEvent(NetworkEvent.DISCONNECTED, netConnection.nearID));
					break; 
				case "NetConnection.Connect.Failed":
					dispatchEvent(new NetworkEvent(NetworkEvent.ERROR, netConnection.nearID)); //Will be null on error
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
			farNS.send("incommingcall", netConnection.nearID);
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.CALLING, farNS.farID, "ring ring"));
		}
		
		public function fetchFarIDFromKey(publicKey:ByteArray):void
		{
			var s:Statement = mysqlConnection.createStatement();
			s.sql = "SELECT * from `users` WHERE `publickey`=?;";
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
				trace("COULDNT FIND TARGET");
				dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, data));
			}
		}
		
		private function incommingcall(farid:String):void
		{
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.INCOMMING_CALL, farid, "ring ring"));
		}
		
		public function getNetstreamFromFarID(farid:String):NetStream
		{
			var returnNS:NetStream;
			for each (var ns:NetStream in netConnections)
			{
				if (ns.farID == farid)
				{
					returnNS = ns;
					break;
				}
			}
			return returnNS;
		}
		
		public function broadcast(message:String):void
		{
			for each (var ns:NetStream in netConnections)
			{
				ns.send("handleIncommingBroadcast", _name, message);
			}
		}
		
		private function handleIncommingBroadcast(user:String, message:String):void
		{
			dispatchEvent(new NetworkUserEvent(NetworkUserEvent.MESSAGE, user, message));
		}
		
		private function refreshNetworkConnections():void
		{
			var s:Statement = mysqlConnection.createStatement();
			s.sql = "SELECT `nearid` FROM `users`;";
			var t:MySqlToken = s.executeQuery();
			
			t.addResponder(new AsyncResponder(refreshNetworkConnectionSuccess, refreshNetworkConnectionError, t));
		}
		
		private function refreshNetworkConnectionError(info:Object, token:MySqlToken):void 
		{
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, info));
		}
		
		private function refreshNetworkConnectionSuccess(data:Object, token:MySqlToken):void 
		{
			var rs:ResultSet = new ResultSet(token);
			
			for (var i:int = 0; i < rs.size(); i++)
			{
				var ns:NetStream = new NetStream(netConnection, rs.getString("nearid"));
				ns.play("desktop");
				netConnections.push(ns);
				rs.next();
			}
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.REFRESH, data));
		}
		
		private function mysql():void
		{
			mysqlConnection = new Connection("-.sfxworks.net", 9001, "-", "-", "-");
			mysqlConnection.connect();
			mysqlConnection.addEventListener(Event.CONNECT, handleMysqlConnection);
		}
		
		private function handleMysqlConnection(e:Event):void 
		{
			trace("Connected.");
			mysqlConnection.removeEventListener(Event.CONNECT, handleMysqlConnection);
			
			var f:File = new File();
			f = File.applicationStorageDirectory.resolvePath(".s2key");
			var fs:FileStream = new FileStream();
			var st:Statement = mysqlConnection.createStatement();
			trace("Checking key.");
			if (f.exists) //Update
			{
				trace("Exists.");
				fs.open(f, FileMode.READ);
				fs.readBytes(_privateKey, 0, 4000); //Read key into identity
				fs.readBytes(_publicKey, 0, 24); //Read public key into identity
				fs.close();
				
				st.sql = "UPDATE users "
				+ "SET `nearid`='"+netConnection.nearID+"' "
				+ "WHERE `key`=?;";
				st.setBinary(1, _privateKey);
			}
			else //Register
			{
				trace("Nonexistant. Registering..");
				_privateKey = generateKey(999);
				_publicKey = generateKey(5);
				_name = File.userDirectory.name;
				
				fs.open(f, FileMode.WRITE);
				fs.writeBytes(_privateKey);
				fs.writeBytes(_publicKey);
				fs.close();
				
				st.sql = "INSERT INTO users (`name`, `nearid`, `key`, `publickey`)"
					+ " VALUES ('"+File.userDirectory.name+"','"+netConnection.nearID+"',?,?);";
				st.setBinary(1, _privateKey);
				st.setBinary(2, _publicKey);
			}
			
			trace("Sending query to server..");
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(mysqlNearIDUpdateSuccess, mysqlNearIDUpdateError, t));
			
			timerRefresh = new Timer(10000);
			timerRefresh.addEventListener(TimerEvent.TIMER, networkTimerRefresh);
			timerRefresh.start();
		}
		
		private function networkTimerRefresh(e:TimerEvent):void 
		{
			refreshNetworkConnections();
			checkForUpdate();
		}
		
		private function checkForUpdate():void 
		{
			trace("Checking for update..");
			versionCheckLoader.load(versionCheckSource);
		}
		
		private function parseUpdateDetail(e:Event):void
		{
			applicationContent = new XML(versionCheckLoader.data);
			var ns:Namespace = applicationContent.namespace();
			var standardVersion:Number = new Number(parseFloat(applicationContent.ns::currentVersion));
			var source:String = new String(applicationContent.ns::source);
			
			trace("Standard version = " + standardVersion);
			trace("Current version = " + currentVersion);
			
			if (standardVersion > currentVersion)
			{
				dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE, standardVersion, source));
				trace("New Version Avalible");
			}
		}
		
		private function mysqlNearIDUpdateError(info:Object, token:MySqlToken):void 
		{
			dispatchEvent(new NetworkEvent(NetworkEvent.ERROR, null));
			trace("Update error.");
		}
		
		private function mysqlNearIDUpdateSuccess(data:Object, token:MySqlToken):void 
		{
			trace("Update success.");
			dispatchEvent(new NetworkEvent(NetworkEvent.CONNECTED, netConnection.nearID));
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
		
		public function get myNetConnection():NetStream 
		{
			return _myNetConnection;
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
			trace("Name change triggered.");
		}
		
		private function nameChangeResponderSuccess(data:Object, token:MySqlToken):void
		{
			trace("Name change response success..");
			_name = nameChangeRequest;
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.SUCCESS, data));
		}
		
		private function nameChangeResponderError(info:Object, token:MySqlToken):void
		{
			trace("Name change response error:" + info);
			dispatchEvent(new NetworkActionEvent(NetworkActionEvent.ERROR, info));
		}
		
	}

}