package sfxworks.services 
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.GroupSpecifier;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import sfxworks.CommunicationLine;
	import sfxworks.Communications;
	import sfxworks.Database;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.events.DatabaseServiceEvent;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class DatabaseService extends EventDispatcher //Needs to be its own thread
	{
		public static const SERVICE_NAME:String = "DATABASE_SERVICE";
		public static const DATABASE_DIRECTORY:File = File.applicationStorageDirectory.resolvePath("db" + File.separator);
		private var c:Communications;
		private var databases:Vector.<Database>;
		
		public function DatabaseService(communications:Communications, target:flash.events.IEventDispatcher=null) 
		{
			super(target);
			DATABASE_DIRECTORY.createDirectory();
			trace("DATABASE_SERVICE init");
			c = communications;
			c.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleGroupObjectRecieved);
			c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
			databases = new Vector.<Database>();
			
			registerClassAlias("flash.data.SqlStatement", SQLStatement);
			registerClassAlias("flash.events.EventDispatcher", EventDispatcher);
			registerClassAlias("flash.utils.ByteArray;", ByteArray);
		}
		
		//Row from record OBJECT REQUEST
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			if (e.groupName.indexOf(SERVICE_NAME) > -1) //If it's for this service
			{
				//Find database reference
				trace("DATABASE_SERVICE object request #" + e.groupObjectNumber);
				for each (var db:Database in databases)
				{
					if (e.groupName.indexOf(db.name) > -1)
					{
						//Access record connection.
						//Get the requseted record.
						
						var st:SQLStatement = new SQLStatement();
						st.text = "SELECT sql FROM steps WHERE step = " + e.groupObjectNumber + ";";
						st.execute();
						var result:SQLResult = st.getResult();
						var row = result.data[0];
						
						c.satisfyObjectRequest(e.groupName, e.groupObjectNumber, row.sql);
						trace("DATABASE_SERVICE Satisfying object request with " + row.sql);
					}
					return;
				}
			}
		}
		
		//Row from record OBJECT RECIEVED
		private function handleGroupObjectRecieved(e:NetworkGroupEvent):void 
		{
			if (e.groupName.indexOf(SERVICE_NAME) > -1) //If it's for this service
			{
				trace("DATABASE_SERVICE Row #" + e.groupObjectNumber + " recieved for database " + e.groupName + ".");
				if (e.groupObjectNumber == 0) //It's the max number of entries for the record database
				{
					//Find the right database
					for each (var db:Database in databases)
					{
						if (e.groupName.search(db.name) > -1)
						{
							trace("DATABASE_SERVICE Max row #" + e.groupObject + ". Current row #" + db.step);
							
							//If it doesn't have all the result data, get it
							if (e.groupObject as Number != db.step)
							{
								//Request all objects up to that point.
								c.addWantObject(e.groupName, db.step, e.groupObject as Number);
								trace("DATABASE_SERVICE requesting row #" + db.step + " through row # " + e.groupObject + " for db: " + db.name + ".");
								db.stepsToLoad = e.groupObject as Number;
							}
							else
							{
								trace("DATABASE_SERVICE " + db.name + " is conneted.");
								//db is ready
								dispatchEvent(new DatabaseServiceEvent(DatabaseServiceEvent.CONNECTED, db.name));
								//Add have objects for peers
								c.addHaveObject(e.groupName, 1, e.groupObject as Number);
							}
							
							return;
						}
					}
				}
				else //It has retrieved a row
				{
					//Find the right database
					for each (var db:Database in databases)
					{
						if (db.name == e.groupName)
						{
							trace("DATABASE_SERVICE retrieved row step #" + e.groupObjectNumber + ".");
							
							//Write the statement in the record database
							db.loadedSteps++;
							var st:SQLStatement = new SQLStatement();
							//Step | Sql | date
							st.text = "INSERT INTO steps (step, sql, date) VALUES (" + e.groupObjectNumber + ", @sqlStatement, @date);";
							st.parameters["@sqlStatement"] = e.groupObject;
							st.parameters["@date"] = new Date();
							st.sqlConnection = db.recordConnection;
							st.execute();
							
							trace("DATABASE_SERVICE submitted row to record log.");
							
							//Check to see if it has all the records.
							if (db.loadedSteps == db.stepsToLoad)
							{
								//Take all the statements from the records and apply them to the database
								trace("DATABASE_SERVICE gathering sql statements from record log");
								
								var state:SQLStatement = new SQLStatement();
								state.text = "SELECT sql FROM steps;";
								state.sqlConnection = db.recordConnection;
								state.execute();
								//Syncronous. ^Got all sql statements. v Submits them to primary database
								var result:SQLResult = state.getResult();
								var numResults = result.data.length;
								trace("DATABASE_SERVICE executing " + (numResults - db.step) + " new sql statements on the local database: " + db.name + ".");
								for (var i = db.step; i < numResults; i++)
								{ 
									var row = result.data[i]; 
									var sqlStatement:SQLStatement = row.sql as SQLStatement;
									sqlStatement.sqlConnection = db.localConnection;
									sqlStatement.execute();
								}
								db.step = db.loadedSteps;
								
								trace("DATABASE_SERVICE " + db.name + " is conneted.");
								dispatchEvent(new DatabaseServiceEvent(DatabaseServiceEvent.CONNECTED, db.name));
							}
						}
					}
				}
			}
		}
		
		public function connectToDatabase(name:String, encryptionKey:ByteArray=null):void
		{
			trace("DATABASE_SERVICE conneting to " + name + ".");
			
			var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + name);
			gspec.multicastEnabled = true;
			gspec.serverChannelEnabled = true;
			gspec.objectReplicationEnabled = true;
			var communicationLine:CommunicationLine = new CommunicationLine(c, SERVICE_NAME + name, gspec);
			communicationLine.addEventListener(NetworkActionEvent.SUCCESS, handleCommunicationLineSuccess);
			communicationLine.addEventListener(NetworkActionEvent.MESSAGE, handleMessage);
			
			var sqlConnection:SQLConnection = new SQLConnection();
			sqlConnection.open(DATABASE_DIRECTORY.resolvePath(name + ".db"), SQLMode.CREATE, true, 1024, encryptionKey);
			
			var recordSqlConnection:SQLConnection = new SQLConnection();
			recordSqlConnection.open(DATABASE_DIRECTORY.resolvePath(name + "_record.db"), SQLMode.CREATE, true, 1024, encryptionKey);
			
			var statement:SQLStatement = new SQLStatement();
			var sql:String = "CREATE TABLE IF NOT EXISTS steps (" +  
			"    step INTEGER, " +  
			"    sql Object, " +  
			"    date Date" +  
			");"; 
			statement.sqlConnection = recordSqlConnection;
			statement.text = sql;
			statement.execute(); //TODO: Error handling
			
			var dbInfoFile:File = new File(DATABASE_DIRECTORY.nativePath + File.separator + name + ".info");
			
			var database:Database = new Database();
			database.communicationLine = communicationLine;
			database.dbInfoFile = dbInfoFile;
			database.loadedSteps = 0;
			database.localConnection = sqlConnection;
			database.name = name;
			database.recordConnection = recordSqlConnection;
			
			databases.push(database);
		}
		
		private function handleCommunicationLineSuccess(e:NetworkActionEvent):void 
		{
			e.target.removeEventListener(NetworkActionEvent.SUCCESS, handleCommunicationLineSuccess);
			for each (var db:Database in databases)
			{
				if (SERVICE_NAME + db.name == e.info)
				{
					trace("DATABASE_SERVICE communication line for " + db.name + " established.");
					//get max number of entries from result db
					c.addWantObject(e.info as String, 0, 0);
					//If no one responds in 10 seconds, assume that youre the only one online and take over.
					//TODO: Make branch system for keeping of multible databases that may go offsync given 1 user isnt always online
					
					function handleDatabaseTimer(e:TimerEvent):void 
					{
						t.removeEventListener(TimerEvent.TIMER, handleDatabaseTimer);
						if (db.loadedSteps == 0)
						{
							trace("DATABASE_SERVICE max gather function time-out.");
							db.step = 0;
							//Assume that you're the only one online and take over
							c.addHaveObject(SERVICE_NAME + db.name, 0, db.step);
							db.loadedSteps = db.step;
						}
						
						trace("DATABASE_SERVICE " + db.name + " is conneted.");
						dispatchEvent(new DatabaseServiceEvent(DatabaseServiceEvent.CONNECTED, db.name));
					}
					trace("Timer triggered");
					var t:Timer = new Timer(10000);
					t.addEventListener(TimerEvent.TIMER, handleDatabaseTimer);
					t.start();
				}
			}
		}
		
		public function createDatabase(name:String, encryptionKey:ByteArray = null):void
		{
			trace("DATABASE_SERVICE creating database " + db.name + ".");
			
			var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + name);
			gspec.multicastEnabled = true;
			gspec.serverChannelEnabled = true;
			gspec.objectReplicationEnabled = true;
			
			var communicationLine:CommunicationLine = new CommunicationLine(c, SERVICE_NAME + name, gspec);
			communicationLine.addEventListener(NetworkActionEvent.MESSAGE, handleMessage);
			
			//Actual database
			var sqlConnection:SQLConnection = new SQLConnection();
			sqlConnection.open(DATABASE_DIRECTORY.resolvePath(name + ".db"), SQLMode.CREATE, true, 1024, encryptionKey);
			
			//Record database
			var recordSqlConnection:SQLConnection = new SQLConnection();
			recordSqlConnection.open(DATABASE_DIRECTORY.resolvePath(name + "_record.db"), SQLMode.CREATE, true, 1024, encryptionKey);
			
			//Is really going to suck if there are huge image bytearrays and they change a few times
			//Will take up a bit of space. Only way I can think of to keep everything in sync though.
			//Setup record database -- |step <key>| sql <object>| 
			//Or run based on date (and delete others. Decreasing number of overall steps. 
			//Sql autorun scrips for later TODO: [maybe at a certain UTC]
			
			var statement:SQLStatement = new SQLStatement();
			var sql:String = "CREATE TABLE IF NOT EXISTS steps (" +  
			"    step INTEGER, " +  
			"    sql Object, " +  
			"    date Date" +  
			");"; 
			statement.sqlConnection = recordSqlConnection;
			statement.text = sql;
			statement.execute(); //TODO: Error handling
			
			var dbInfoFile:File = new File(DATABASE_DIRECTORY.nativePath + name + ".info");
			
			var db:Database = new Database();
			db.name = name;
			db.dbInfoFile = dbInfoFile;
			db.loadedSteps = 0;
			db.communicationLine = communicationLine;
			db.localConnection = sqlConnection;
			db.recordConnection = recordSqlConnection;
			db.step = 0;
			
			databases.push(db);
			
			trace("DATABASE_SERVICE " + db.name + " is conneted.");
			dispatchEvent(new DatabaseServiceEvent(DatabaseServiceEvent.CONNECTED, db.name));
		}
		
		private function handleMessage(e:NetworkActionEvent):void 
		{
			//Find the database/
			for each (var db:Database in databases)
			{
				if (db.communicationLine == e.target)
				{
					trace("DATABASE_SERVICE new sql statement for " + db.name + ".");
					
					var st:SQLStatement = e.info as SQLStatement;
					//Transfer connection hook
					st.sqlConnection = db.localConnection;
					st.execute();
					//Log.
					db.step++;
					db.loadedSteps = db.step;
					
					trace("DATABASE_SERVICE logging statement #" + db.step + " for db:" + db.name + ".");
					
					var recordStatement:SQLStatement = new SQLStatement();
					recordStatement.sqlConnection = db.recordConnection;
					recordStatement.text "INSERT INTO steps (sql, date) VALUES (@sql, @date);";
					recordStatement.parameters["@sql"] = st;
					recordStatement.parameters["@date"] = new Date();
					recordStatement.execute();
					
					//Add have object for peers
					trace("DATABASE_SERVICE row to have list for db:" + db.name + ".");
					c.addHaveObject(SERVICE_NAME + db.name, db.step, db.step);
				}
			}
		}
		
		public function readFromDB(name:String, statement:SQLStatement):Object //Either result or error
		{
			for each (var db:Database in databases)
			{
				if (db.name == name)
				{
					trace("DATABASE_SERVICE executing statement " + statement.text + " on db:" + db.name + ".");
					statement.sqlConnection = db.localConnection;
					try
					{
						statement.execute();
						var result = statement.getResult();
						trace("DATABASE_SERVICE success:" + result);
						return result;
					}
					catch (error)
					{
						trace("DATABASE_SERVICE error:" + error);
						return error;
					}
				}
			}
			
			return -1;
		}
		
		public function writeToDB(name:String, statement:SQLStatement):Object
		{
			for each (var db:Database in databases)
			{
				if (db.name == name)
				{
					statement.sqlConnection = db.localConnection;
					trace("DATABASE_SERVICE executing statement " + statement.text + " on db:" + db.name + ".");
					try
					{
						statement.execute();
					}
					catch (error)
					{
						return error;
					}
					//Send statement
					db.communicationLine.send(statement);
					//Log statement
					db.step++;
					db.loadedSteps = db.step;
					
					trace("DATABASE_SERVICE logging statement #" + db.step + " for db:" + db.name + ".");
					
					var recordStatement:SQLStatement = new SQLStatement();
					recordStatement.sqlConnection = db.recordConnection;
					recordStatement.text = "INSERT INTO steps (sql, date) VALUES (@sql, @date);"; //possible todo: (md5 for statments and compare dates globally for better synchronization)
					recordStatement.parameters["@sql"] = statement;
					recordStatement.parameters["@date"] = new Date();
					recordStatement.execute();
					
					var result = statement.getResult();
					trace("DATABASE_SERVICE success:" + result);
					
					//Add have object for peers
					trace("DATABASE_SERVICE row to have list for db:" + db.name + ".");
					c.addHaveObject(SERVICE_NAME + db.name, db.step, db.step);
					
					return result;
				}
			}
			
			return -1;
		}
	}

}