package 
{
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import mx.rpc.Responder;
	/**
	 * ...
	 * @author ...
	 */
	public class Something 
	{
		private var myID:Identity;
		
		private var myNetConnection:NetConnection;
		private var activeNetConnections:Vector.<String>;
		
		public function Something(nc:NetConnection) //Basically, eliminate name lookup, accept request in skype feature, and make it a public network [Assuming thats how they work]
		{
			myNetConnection.publish(myID.nearID); //Publish to server, allowing anyone to hook
		}
		
		public function refresh():void
		{
			//Get all net streams [For now, get all. In the future, get updated ones] (save server load)
			var conn:Connection = new Connection("project-desktop.sfxworks.net", 3306, "application", "v69q036c71059c812433#_$%55**02", "registry");
			var getAllConnectionsStatement:Statement = "SELECT nearID FROM users";
			var getAllConnectionsToken:MySqlToken = getAllConnectionsStatement.executeQuery();
			
			getAllConnectionsToken.addResponder(new Responder(handleAllStreams, error));
		}
		
		private function handleAllStreams(data:Object, token:Object):void
		{
			var rs:ResultSet = ResultSet(data);
			var allActiveConnections:String = rs.getString("nearID"); //Somehow split it based on an whatever it comes in as
			
			var raw:Array = new Array();
			for each (var farID:String in Array)
			{
				//Do a search to see if we already subscribed to them and are playing them.
				//Handle drops and reconnects later. [Or just recreate the list everytime]
				for each (var activeID:String in activeNetConnections)
				{
					if (activeID != farID)
					{
						//Subscribe to them
						var ns:NetStream = new NetStream(myNetConnection, farID); //Connect to their nearID
						ns.play(farID); //Subscribe to them. Name could be anything, but naming it their NearID now for identity purposes
						//Channel = FARID
						
						//Index it.
						activeNetConnections.push(farID);
					}
				}
			}
		}
		
		//Handling of mysql connection errors
		private function error(info:Object, token:Object):void
		{
			trace ("Error: " + info);
		}
		
	}

}