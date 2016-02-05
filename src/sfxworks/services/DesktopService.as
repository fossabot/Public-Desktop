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
		private var gsourceFiles:Vector.<Vector.<File>>;
		private var gsourceRanges:Vector.<Vector.<Number>>;
		
		public static const SERVICE_NAME:String = "desktopservice";
		
		
		//Space address = PublicKey:MD5
		
		//Stored on folder on remote requester. Md5 is to ID. One directory. File paths eliminiated.
		
		
		public function DesktopService(communications:Communications) 
		{
			c = communications;
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleSuccessfulGroupConnection);
			c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
			//Constructors
			gnames = new Vector.<String>();
			gspecs = new Vector.<GroupSpecifier>();
			gfiles = new Vector.<File>();
			gsourceFiles = new Vector.<Vector.<File>>();
			gsourceRanges = new Vector.<Vector.<Number>>();
			
			//Create a group for each space.
			//Use md5.
			
			var spaceDirectory:File = File.applicationStorageDirectory.resolvePath("space");
			var fs:FileStream = new FileStream(); //Util
			for each (var f:File in spaceDirectory.getDirectoryListing())
			{
				if (f.extension == ".dspace")
				{
					var tmp:ByteArray = new ByteArray();
					fs.open(f, FileMode.READ)
						fs.readBytes(tmp, 0, f.size);
						fs.close();
					var hash:String = MD5.hashBytes(tmp);
					var gspec:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + hash); //Tecnically if someone has the exact same video in the exact same position as someone, with the exact same matrix as someone, they'll be part of this group. Which actually helps as far as distribution goes.
					gspec.multicastEnabled = true;
					gspec.serverChannelEnabled = true;
					gspec.objectReplicationEnabled = true;
					
					//Index
					gnames.push(SERVICE_NAME + hash);
					gfiles.push(f);
					gsourceFiles.push(new Vector.<File>());
					
					//Send over to communications for handling.
					c.addGroup(SERVICE_NAME + hash);
				}
			}
			
		}
		
		//Host: --
		private function handleSuccessfulGroupConnection(e:NetworkGroupEvent):void 
		{
			if (gnames.indexOf(e.groupName) > -1)
			{
				//First File = Space File
				c.addHaveObject(e.groupName, 0, 0);
				//Next are as follows
				//Md5: Bytearray (Separated by 10kb)
				//Ordered by order or appearance on display (front to back)
				
				var currentObjectIndex:Number = 1;
				
				var fs:FileStream = new FileStream();
				fs.open(gfiles[gnames.indexOf(e.groupName)], FileMode.READ);
					var numberOfObjects:Number = fs.readDouble();
					fs.readUTF(); //Skip Permissions
					for (var i:Number = 0; i < numberOfObjects; i++)
					{
						//Get the object source file
						var source:String = fs.readUTF();
						var objectSourceFile:File = new File(source);
						if (source != "embeddedobject")
						{
							c.addHaveObject(e.groupName, currentObjectIndex, Math.ceil(objectSourceFile.size / 10000) + currentObjectIndex);
							currentObjectIndex += Math.ceil(objectSourceFile / 10000);
						}
						
						//Skip Rest
						fs.readUTF();
						fs.position += 8 * 12;
						fs.readUTF();
						
						gsourceFiles[gnames.indexOf(e.groupName)].push(objectSourceFile);
						gsourceRanges[gnames.indexOf(e.groupName)].push(currentObjectIndex);
					}
			}
		}
		
		//Host: -- Handle Object Request
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			var target:int = 0;
			for each (var range:Number in gsourceRanges[gnames.indexOf(e.groupName)])
			{
				if (e.groupObjectNumber <= range)
				{
					var fs:FileStream = new FileStream();
					fs.open(gsourceFiles[gnames.indexOf(e.groupName)][target], FileMode.READ);
						if (target == 0) //If on the first source file
						{
							//Set the position to the number of bytes in a sector times the requested object number.
							fs.position = 10000 * e.groupObjectNumber;
						}
						else //If its the 2nd or greater source file
						{
							//Set the position to the difference of the object number and the source file's max range, multiplied by the number of bytes in a sector
							fs.position = 10000 * (e.groupObjectNumber - gsourceRanges[gnames.indexOf(e.groupName)][target - 1]);
						}
						
						var objectToSend:ByteArray = new ByteArray();
						//If at end of file.
						if (range == e.groupObjectNumber)
						{
							//Set the object to send to the number of bytes avalible. (Could be exactly 10kb or less)
							fs.readBytes(objectToSend, 0, objectToSend.bytesAvailable);
						}
						else //If pointer is somewhere in middle of file
						{
							//Read only the number of bytes in a sector
							fs.readBytes(objectToSend, 0, 10000);
						}
						
						//Send it to communications for export;
						c.satisfyObjectRequest(e.groupName, e.groupObjectNumber, objectToSend);
						fs.close();
					
					break;
				}
				target++;
			}
		}
		
		//TODO: Remote to Local request
		
		
	}

}