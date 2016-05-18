package sfxworks.services 
{
	import by.blooddy.crypto.MD5;
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.events.DatabaseServiceEvent;
	import sfxworks.services.nodes.DatabaseServiceNodeClient;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DatabaseService extends EventDispatcher
	{
		public static const SERVICE_NAME:String = "DATABASE_SERVICE";
		public static const DATABASE_DIRECTORY:File = File.applicationStorageDirectory.resolvePath("database" + File.separator);
		
		private var communications:Communications;
		
		private var databaseName:Vector.<String>;
		private var gspecs:Vector.<GroupSpecifier>;
		private var netstreamI:Vector.<NetStream>;
		private var netstreamO:Vector.<NetStream>;
		private var sqlConnection:Vector.<SQLConnection>;
		private var tableFormat:Vector.<String>;
		private var active:Vector.<Boolean>;
		
		//SQL FORMAT: //db [object number, md5, object (serialized), date]
		
		public function DatabaseService(c:Communications) 
		{
			communications = c;
			
			active = new Vector.<Boolean>();
			databaseName = new Vector.<String>();
			gspecs = new Vector.<GroupSpecifier>();
			netstreamI = new Vector.<NetStream>();
			netstreamO = new Vector.<NetStream>();
			sqlConnection = new Vector.<SQLConnection>();
			tableFormat = new Vector.<String>();
			
			communications.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			communications.addEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulNetworkAction);
			communications.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
			communications.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
		}
		
		
		public function connectToDatabase(name:String, type:String, tableFormat:SQLStatement, encryptionKey:ByteArray=null) //TODO: TWO types. Syncronous (all databases are the stame) vs Mass (attemps to use as much space as possible with as much avalibility as possible prioritizing storage on highly active users and replicating on others)
		{	
			//1: Establish group connection
			var gspec:GroupSpecifier = new GroupSpecifier(name);
			gspec.multicastEnabled = true;
			gspec.serverChannelEnabled = true;
			gspec.objectReplicationEnabled = true;
			
			communications.addGroup(SERVICE_NAME + name, gspec);
			
			//2: Establish local connection
			var dbFile:File = new File(DATABASE_DIRECTORY.nativePath + name + ".db");
			var conn:SQLConnection = new SQLConnection();
			//TODO: Handle error with improper encryption key
			conn.openAsync(dbFile, SQLMode.CREATE, null, true, 1024, encryptionKey);
			conn.addEventListener(SQLEvent.OPEN, handleNewLocalDatabase);
			
			sqlConnection.push(conn);
			databaseName.push(name);
			gspecs.push(gspec);
			netstreamI.push(new NetStream());
			netstreamO.push(new NetStream());
		}
		
		private function handleNewLocalDatabase(e:SQLEvent):void 
		{
			e.target.removeEventListener(SQLEvent.OPEN, handleNewLocalDatabase);
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = e.target;
			
			var sql:String = "CREATE TABLE IF NOT EXISTS Objects (" +  
			"    objectNumber INTEGER PRIMARY KEY, " +  
			"    md5 TEXT, " +  
			"    object Object, " +  
			"    date Date" +  
			")"; 
			
			statement.text = sql;
			statement.execute();
			
			statement.addEventListener(SQLEvent.RESULT, handleSuccessfulDatabaseSetup);
		}
		
		private function handleSuccessfulTableCreation(e:SQLEvent):void 
		{
			e.target.removeEventListener(SQLEvent.RESULT, handleSuccessfulDatabaseSetup);
			
			if (netstreamI[sqlConnection.indexOf(e.target)] != null)
			{
				(netstreamI[sqlConnection.indexOf(e.target)].client as DatabaseServiceNodeClient).active = true;
			}
			active[sqlConnection.indexOf(e.target)] = true;
		}
		
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			if (e.groupName.search(SERVICE_NAME) > -1)
			{
				//Listeners for publishing and responding to publishers
				netstreamI[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))] = new NetStream(communications.netConnection, gspecs[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))]);
				netstreamO[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))] = new NetStream(communications.netConnection, gspecs[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))]);
				
				//Get all possible objects [Objcets are split for faster initial retrieval of database]
				communications.addWantObject(e.groupName.split(SERVICE_NAME.length), 0, Number.MAX_VALUE);
			}
		}
		
		private function handleSuccessfulNetworkAction(e:NetworkActionEvent):void 
		{
			if (netstreamI.indexOf(e.info) > -1)
			{
				netstreamI[netstreamI.indexOf(e.info)].play("stream");
				netstreamI[netstreamI.indexOf(e.info)].client = new DatabaseServiceNodeClient(databaseName[netstreamI.indexOf(e.info)]);
				
				(netstreamI[netstreamI.indexOf(e.info)].client as DatabaseServiceNodeClient).active = active[netstreamI.indexOf(e.info)];
			}
			else if (netstreamO.indexOf(e.info) > -1)
			{
				netstreamO[netstreamO.indexOf(e.info)].publish("stream");
				netstreamO[netstreamO.indexOf(e.info)].client = new DatabaseServiceNodeClient(databaseName[netstreamO.indexOf(e.info)]);
			}
		}
		
		//                        == Object Request ===
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.sqlConnection = sqlConnection[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))]
			sqlStatement.text = "SELECT object, md5, date FROM object WHERE objectNumber = " + e.groupObjectNumber.toString() + ";";
			sqlStatement.addEventListener(SQLEvent.RESULT, handleSqlResult);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, handleSqlError);
		}
		
		private function handleSqlError(e:SQLErrorEvent):void 
		{
			e.target.removeEventListener(SQLEvent.RESULT, handleSqlResult);
			e.target.removeEventListener(SQLErrorEvent.ERROR, handleSqlError);
			
			trace(e.errorID + ":" + e.error);
			dispatchEvent(e);
			//TODO: Test whether or not the database will throw an error if it can't find the record
		}
		
		private function handleSqlResult(e:SQLEvent):void 
		{
			e.target.removeEventListener(SQLEvent.RESULT, handleSqlResult);
			e.target.removeEventListener(SQLErrorEvent.ERROR, handleSqlError);
			
			var result:SQLResult = e.target.getResult(); 
			var row:Object = result.data[0];
			communications.satisfyObjectRequest(SERVICE_NAME + databaseName[sqlConnection.indexOf(e.target.sqlConnection)], row.objectNumber, row.object);
		}
		
		//Is regiserClassAlies Global?
		//                      == Object Recieved == [Initial object retrieval (for downloading of database)]
		private function handleObjectRecieved(e:NetworkGroupEvent):void 
		{
			//db [object number, md5, object]
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection[databaseName.indexOf(e.groupName.substr(SERVICE_NAME.length))];
			statement.text = "insert or replace into Objects (objectNumber, md5, object, date) values"
				+ "((select objectNumber from Objects where objectNumber = " + e.groupObjectNumber.toString() + "), '" + MD5.hashBytes(e.groupObject as ByteArray) + "', @object, @date);";
			statement.parameters["@object"] = e.groupObject;
			statement.parameters["@date"] = new Date();
			
			statement.execute();
		}
		
		
		//Submittion of data
		public function submitData(dbName:String, tableName:String, sqlStatement:SQLStatement):void
		{
			//Connection should be null.
			
			//Send to network (All the databases in the network group)
			netstreamI[databaseName.indexOf(dbName)].send("query", sqlStatement);
			//Update local
			sqlStatement.sqlConnection = sqlConnection[databaseName.indexOf(dbName)];
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, handleSqlError);
			sqlStatement.execute();
		}
		
		public function queryLocalDB(dbName:String, sqlStatement:SQLStatement):void
		{
			function handleLocalDBResult(e:SQLEvent):void //function inside function to get proper dbname because asyncronous and unpredictability of which db was called in what order and which one would finish first
			{
				sqlStatement.removeEventListener(SQLEvent.RESULT, handleLocalDBResult);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR, handleSqlError);
				//Attach result to dse with database name
				dispatchEvent(new DatabaseServiceEvent(DatabaseServiceEvent.RESULT_DATA, dbName, e.target.getResult()));
			}
			
			sqlStatement.sqlConnection = sqlConnection[databaseName.indexOf(dbName)];
			sqlStatement.addEventListener(SQLEvent.RESULT, handleLocalDBResult);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, handleSqlError);
			sqlStatement.execute();
			
		}
		
		
		
		
	}

}