package sfxworks.services 
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.GroupSpecifier;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.NetworkGroupEvent;
	import by.blooddy.crypto.MD5;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DesktopService extends EventDispatcher
	{
		private var c:Communications;
		private var gnames:Vector.<String>;
		private var gfiles:Vector.<File>;
		
		
		public static const SERVICE_NAME:String = "desktopservice";
		public static const RESOURCE_DIRECTORY:File = File.applicationStorageDirectory.resolvePath("space" + File.separator + "source" + File.separator);
		public static const SPACE_DIRECTORY:File = File.applicationStorageDirectory.resolvePath("space" + File.separator);
		public static const FILE_DIVIDE:Number = 10000; //10kb
		public static const SPACE_FILE_EXTENSION:String = "dspace";
		public static const RESOURCE_FILE_EXTENSION:String = "dsource";
		
		
		//Space address = PublicKey:MD5
		//Stored on folder on remote requester. Md5 is to ID. One directory. File paths eliminiated.
		
		//Each file has its own group.
		
		
		public function DesktopService(communications:Communications) 
		{
			c = communications;
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
			c.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
			
			//Constructors
			gnames = new Vector.<String>();
			gfiles = new Vector.<File>();
			
			//Create a group for each space.
			//Use md5.
			
			SPACE_DIRECTORY.createDirectory();
			
			var fs:FileStream = new FileStream(); //Util
			for each (var f:File in SPACE_DIRECTORY.getDirectoryListing())
			{
				if (f.extension == SPACE_FILE_EXTENSION)
				{
					addFileToListing(f, SPACE_FILE_EXTENSION);
				}
			}
			
			RESOURCE_DIRECTORY.createDirectory();
			
			for each (var f:File in RESOURCE_DIRECTORY.getDirectoryListing())
			{
				if (f.extension == RESOURCE_FILE_EXTENSION)
				{
					addFileToListing(f, RESOURCE_FILE_EXTENSION);
				}
			}
			
		}
		
		private function addFileToListing(f:File, type:String):void
		{
			var tmp:ByteArray = new ByteArray();
			fs.open(f, FileMode.READ)
				fs.readBytes(tmp, 0, f.size);
				fs.close();
			var hash:String = MD5.hashBytes(tmp);
			var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + hash + "." + type); //Tecnically if someone has the exact same video in the exact same position as someone, with the exact same matrix as someone, they'll be part of this group. Which actually helps as far as distribution goes.
			gspec.multicastEnabled = true;
			gspec.serverChannelEnabled = true;
			gspec.objectReplicationEnabled = true;
			
			//Index
			gnames.push(SERVICE_NAME + hash + "." + type);
			gfiles.push(f);
			
			//Send over to communications for handling.
			c.addGroup(SERVICE_NAME + hash + "." + type);
		}
		
		//Host: --
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			if (gnames.indexOf(e.groupName) > -1 && e.groupName.split(".")[1] == SPACE_FILE_EXTENSION) // Space file (owned)
			{
				//First File = Space File
				c.addHaveObject(e.groupName, 0, 0);
				//Next are as follows
				//Md5: Bytearray (Separated by 10kb)
				
				
				var fs:FileStream = new FileStream();
				fs.open(gfiles[gnames.indexOf(e.groupName)], FileMode.READ);
					var numberOfObjects:Number = fs.readDouble();
					fs.readUTF(); //Skip Permissions
					for (var i:Number = 0; i < numberOfObjects; i++)
					{
						//Get the object source file
						var source:String = fs.readUTF();
						
						if (source != "embeddedobject")
						{
							var objectSourceFile:File = new File(source);
							addFileToListing(objectSourceFile, RESOURCE_FILE_EXTENSION);
						}
						
						//Skip Rest
						fs.readUTF(); //Don't use saved MD5 if the file changed.
						fs.position += 8 * 12;
						fs.readUTF();
					}
					fs.close();
			}
			else if(gnames.indexOf(e.groupName) > -1 && e.groupName.split(".")[1] == RESOURCE_FILE_EXTENSION) //Source file (owned)
			{
				c.addHaveObject(e.groupName, 0, Math.ceil(gfiles[gnames.indexOf(e.groupName)].size / FILE_DIVIDE));
			}
			else if (e.groupName.split(".")[1] == SPACE_FILE_EXTENSION) //Space File (not owned)
			{
				c.addWantObject(e.groupName, 0, 0);
			}
			else if (e.groupName.split(".")[1] == RESOURCE_FILE_EXTENSION) //Source File (not owned)
			{
				c.addWantObject(e.groupName, 0, 0);
			}
			
		}
		
		//Host: -- Handle Object Request
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			var targetFile:File = gfiles[gnames.indexOf(e.groupName)];
			
			var dataToSend:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			fs.open(targetFile, FileMode.READ);
				fs.position = FILE_DIVIDE * e.groupObjectNumber;
				if (fs.bytesAvailable > FILE_DIVIDE)
				{
					fs.readBytes(dataToSend, 0, FILE_DIVIDE);
				}
				else
				{
					fs.readBytes(dataToSend, 0, fs.bytesAvailable);
				}
				fs.close();
			
			var objectToSend:Object = new Object();
			objectToSend.data = dataToSend;
			objectToSend.maxdata = Math.ceil(targetFile.size / FILE_DIVIDE) - 1;
			
			c.satisfyObjectRequest(e.groupName, e.groupObjectNumber, objectToSend);
		}
		
		public function getFile(md5Address:String):void //Spaces or Resources
		{
			if (gnames.indexOf(SERVICE_NAME + md5Address + SPACE_FILE_EXTENSION) > -1)
			{
				//Group exist.
				//Means you already have the file. Don't bother doing anything.
			}
			else
			{
				//If there's a newer version out, local sys will probably add a link to the updated version. Optionally stop hosting the older one.
				//This can lead to...a relative form of permanence.
				var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + md5Address + SPACE_FILE_EXTENSION);
				gspec.objectReplicationEnabled = true;
				gspec.multicastEnabled = true;
				gspec.serverChannelEnabled = true;
				c.addGroup(SERVICE_NAME + md5Address + SPACE_FILE_EXTENSION, gspec);
			}
		}
		
		
		private function handleObjectRecieved(e:NetworkGroupEvent):void 
		{
			if (e.groupName.split(".")[1] == SPACE_FILE_EXTENSION)
			{
				//It's a space file
				//e.groupName = desktopserviceHEWR8GR23HUI3C4234GU3YH4IU.dspace
				//Split off the desktop service to get MD5.dspace
				//Put it in space directory
				writeObject(e.groupObject.data, new File(SPACE_DIRECTORY.nativePath + e.groupName.substr(SERVICE_NAME.length)), e.groupObject.maxdata);
			}
			else if (e.groupName.split(".")[1] == RESOURCE_FILE_EXTENSION)
			{
				if (gnames.indexOf(e.groupName) > -1)
				{
					//Already knows the file
				}
				else
				{
					//Doesn't have details on the file.
					//Write object
					if (e.groupObject.maxdata > 0) //If it has more fetch the rest
					{
						c.addWantObject(e.groupName, 1, e.groupObject.maxdata);
					}
					
					//Index
					gnames.push(e.groupName);
					gfiles.push(incommingFile);
				}
				
				writeObject(e.groupObject.data, new File(RESOURCE_DIRECTORY.nativePath + e.groupName.substr(SERVICE_NAME.length)), e.groupObjectNumber, e.groupObject.maxdata);\
			}
		}
		
		private function writeObject(data:ByteArray, target:File, position:uint, max:Number):void
		{
			//Write to drive
			var fs:FileStream = new FileStream();
			fs.open(target, FileMode.WRITE);
				fs.writeBytes(data, position * FILE_DIVIDE, data.bytesAvailable);
				fs.close();
				
			//Add to index for any future object requests
			if (gnames.indexOf(SERVICE_NAME + target.name + target.extension) == -1)
			{
				gnames.push(SERVICE_NAME + target.name + target.extension);
				gfiles.push(target);
			}
			
			//Dispatch events for ui or other
			if (target.extension == RESOURCE_FILE_EXTENSION)
			{
				dispatchEvent(new DesktopServiceEvent(DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED, target.name, position, max));
			}
			else if (target.extension == SPACE_FILE_EXTENSION)
			{
				dispatchEvent(new DesktopServiceEvent(DesktopServiceEvent.SPACE_OBJECT_RECIEVED, target.name, position, max));
			}
			
		}
		
		
	}

}