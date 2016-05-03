package sfxworks.services 
{
	import by.blooddy.crypto.MD5;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.GroupSpecifier;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkGroupEvent;
	import sfxworks.services.nodes.DatabaseServiceNodeClient;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DatabaseService extends EventDispatcher
	{
		public static const SERVICE_NAME:String = "DATABASE_SERVICE";
		public static const DATABASE_DIRECTORY:File = File.applicationStorageDirectory.resolvePath("database");
		
		private var communications:Communications;
		
		private var databaseName:Vector.<String>;
		private var gspecs:Vector.<GroupSpecifier>;
		private var netstreamI:Vector.<NetStream>;
		private var netstreamO:Vector.<NetStream>;
		//private var phase:Vector.<String>; //create | update
		//Create: Makes the database. Gets all objects before writing
		//Update: Someone either increased the max, or wants to update an object at a position 
		
		//SQL FORMAT:
		//Number | Object
		// int   | bytearray
		
		public function DatabaseService(c:Communications) 
		{
			communications = c;
			
			databaseName = new Vector.<String>();
			gspecs = new Vector.<GroupSpecifier>();
			netstreamI = new Vector.<NetStream>();
			netstreamO = new Vector.<NetStream>();
			
			communications.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			communications.addEventListener(NetworkActionEvent.SUCCESS, handleSuccessfulNetworkAction);
			communications.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
			communications.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
		}
		
		
		public function connectToDatabase(name:String, type:String) //TODO: TWO types. Syncronous (all databases are the stame) vs Mass (attemps to use as much space as possible with as much avalibility as possible prioritizing storage on highly active users and replicating on others)
		{	
			//1: Establish group connection
			var gspec:GroupSpecifier = new GroupSpecifier(name);
			gspec.multicastEnabled = true;
			gspec.serverChannelEnabled = true;
			gspec.objectReplicationEnabled = true;
			
			communications.addGroup(SERVICE_NAME + name, gspec);
			
			databaseName.push(name);
			gspecs.push(gspec);
			netstreamI.push(new NetStream());
			netstreamO.push(new NetStream());
			//2: Get updates
			//3: Stay in sync
		}
		
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			if (e.groupName.search(SERVICE_NAME) > -1)
			{
				//Listeners for publishing and responding to publishers
				netstreamI[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))] = new NetStream(communications.netConnection, gspecs[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))]);
				netstreamO[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))] = new NetStream(communications.netConnection, gspecs[databaseName.indexOf(e.groupName.split(SERVICE_NAME.length))]);
				
				//First object is max number
				communications.addWantObject(e.groupName.split(SERVICE_NAME.length), 0, 0);
				
			}
		}
		
		private function handleSuccessfulNetworkAction(e:NetworkActionEvent):void 
		{
			if (netstreamI.indexOf(e.info) > -1)
			{
				netstreamI[netstreamI.indexOf(e.info)].play("stream");
				netstreamI[netstreamI.indexOf(e.info)].client = new DatabaseServiceNodeClient(databaseName[netstreamI.indexOf(e.info)]);
			}
			else if (netstreamO.indexOf(e.info) > -1)
			{
				netstreamO[netstreamO.indexOf(e.info)].publish("stream");
				netstreamO[netstreamO.indexOf(e.info)].client = new DatabaseServiceNodeClient(databaseName[netstreamO.indexOf(e.info)]);
			}
		}
		
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			if (e.groupObjectNumber == 0)
			{
				
			}
		}
		
		private function handleObjectRecieved(e:NetworkGroupEvent):void 
		{
			if (e.groupObjectNumber == 0) //Meta data
			{
				//It's the metadata
				//Contains: Md5, max entries
				
				//TODO: No idea if when adobe air inserts something into a database, it adds a timestamp or something that would make the
				//content of the database the same but the md5s different, but lets see if this works
				
				var fs:FileStream = new FileStream();
				var database:File = new File(DATABASE_DIRECTORY.nativePath + File.separator + e.groupName.substr(SERVICE_NAME) + ".db");
				var raw:ByteArray = new ByteArray();
				
				fs.open(database, FileMode.READ)
					fs.readBytes(raw, 0, database.size);
					fs.close();
					
				if (e.groupObject.md5 != MD5.hashBytes(raw))
				{
					//Database raw file = object 1.
					//Get database.
					communications.addWantObject(e.groupName, 1, 1);
				}
				
			}
			else if (e.groupObjectNumber == 1) //.db file
			{
				//Write db file.
				var fs:FileStream = new FileStream();
				fs.open(new File(DATABASE_DIRECTORY.nativePath + File.separator + e.groupName.substr(SERVICE_NAME.length) + ".db"), FileMode.WRITE);
					fs.writeBytes(e.groupObject as ByteArray, 0, e.groupObject.length as ByteArray);
					fs.close();
				
				
				//Flush queries from Inbound stream
				(netstreamI[databaseName.indexOf(e.groupName.substr(SERVICE_NAME.length))].client as DatabaseServiceNodeClient).activate();
			}
		}
		
	}

}