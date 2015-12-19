package sfxworks 
{
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.Responder;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author ...
	 */
	public class Network extends EventDispatcher
	{
		//Mysql ------------------
		private static const MYSQL_SERVER:String = "mysql.sfxworks.net";
		private static const MYSQL_PORT:int = 3306;
		private static const MYSQL_USERNAME:String = "application";
		private static const MYSQL_PASSWORD:String = "X9834HFG5748Sii0**-/3$$k944332..0,ef842323WQRoo[@#4";
		
		private var conn:Connection;
		public var result:ResultSet;
		//-----------------------
		
		//Network Connection
		private var nc:NetConnection; //Main Net Connection
		private var ns:Vector.<NetStream>; //Active Net Streams
		
		//Event Tags
		public static const MYSQL_CONNECT:String = "mysqlConnect";
		public static const MYSQL_RESULT:String = "mysqlResult";
		public static const MYSQL_ERROR:String = "mysqlError";
		
		public static const NETCONNECTION_CONNECT:String = "netConnected";
		public static const NETCONNECTION_CLOSED:String = "netClosed";
		public static const NETCONNECTION_FAILED:String = "netFailed";
		
		public function Network() 
		{
			//Mysql:
			conn = new Connection(mysqlser, MYSQL_PORT, MYSQL_USERNAME, MYSQL_PASSWORD);
			conn.addEventListener(Event.CONNECT, handleMysqlConnection);
			conn.connect();
			
			
			//Net Connection:
			nc = new NetConnection();
			nc.connect("rtmfp://p2p.rtmfp.net", "e0708320bf4003e01aa0bcd1-ee3e9ec0c03a");
			nc.addEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
		}
		
		private function handleNetStatus(e:NetStatusEvent):void 
		{
			nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			switch(e.info.code)
			{ 
				case "NetConnection.Connect.Success":
					dispatchEvent(new Event(NETCONNECTION_CONNECT));
					break; 
				case "NetConnection.Connect.Closed": 
					dispatchEvent(new Event(NETCONNECTION_CLOSED));
					break; 
				case "NetConnection.Connect.Failed":
					dispatchEvent(new Event(NETCONNECTION_FAILED));
					break;  
			}
		}
		
		private function handleMysqlConnection(e:Event):void 
		{
			conn.removeEventListener(Event.CONNECT, handleMysqlConnection);
			dispatchEvent(new Event(MYSQL_CONNECT));
		}
		
		//Mysql SUBMIT STATEMENT
		public function submitStatement(statement:String, args:Vector.<ByteArray> = null):void
		{
			var s:Statement = conn.createStatement();
			s.sql = statement;
			
			var c:int = 1;
			for each (var ba:ByteArray in args)
			{
				trace("Adding binary.");
				s.setBinary(c, ba);
				c++;
			}
			
			var t:MySqlToken = s.executeQuery();
			t.addResponder(new Responder(handleResult, handleError);
		}
		
		//Mysql HANDLE RESULT
		private function handleResult(data:Object, token:MySqlToken):void
		{
			trace("Response:" + token.result);
			result = new ResultSet(token);
			
			dispatchEvent(new Event(MYSQL_RESULT));
		}
		
		//Mysql HANDLE ERROR
		private function handleError(info:Object, token:Object):void
		{
			trace("Mysql error");
			trace(info);
			
			dispatchEvent(new Event(MYSQL_ERROR));
		}
		
	}

}