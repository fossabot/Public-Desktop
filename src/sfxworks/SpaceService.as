package sfxworks 
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SpaceService 
	{
		private var c:Communications;
		
		public function SpaceService(communications:Communications) 
		{
			c = communications;
			c.addEventListener(NetworkUserEvent.OBJECT_REQUEST, handleObjectRequest); //Handle incomming object requests
		}
		
		private function handleObjectRequest(e:NetworkUserEvent):void 
		{
			/*
			 * Argument format
			 * Target: Target service to handle the object request
			 * Args: Arguments for said service
			 * SpaceService,0.0.0.0.0.0,<spacename>
			 * 
			 */
			
			if (e.name.toLowerCase() == "spaceservice") 
			{
				var args:Array = e.message as Array;
				args.reverse();
				
				var returnAddress:String = args.pop();
				var requestPath:String = args.pop();
				
				var ra:ByteArray = new ByteArray(); //Converted return address to bytearray for communications
				var raArray:Array = returnAddress.split("."); //Tmp
				for (var i:int = 0; i < raArray.length; i++)
				{
					ra.writeFloat(parseFloat(raArray[i]));
				}
				
				var requestedSpace:File = File.applicationStorageDirectory.resolvePath("spaces" + File.separator + requestPath);
				if (requestedSpace.exists) //If it can find the space file
				{
					if (allowedToAccess(requestedSpace.nativePath, returnAddress)) //If it's allowed to access the space file
					{
						var ba:ByteArray = new ByteArray();
						
						ba.writeUTF("access granted"); //Later possibly get directly listing of avalible spaces and files
						//[Filesize][File]
						ba.writeFloat(requestedSpace.size);
						
						//Pack space file
						var fs:FileStream = new FileStream();
						fs.open(requestedSpace, FileMode.READ);
						fs.readBytes(ba, 0, requestedSpace.size); //Pack space file
						
						fs.position = 0;
						var numberOfSpaceFiles:Number = fs.readFloat();
						ba.writeFloat(numberOfSpaceFiles);
						fs.readUTF(); //Skip access
						
						var afs:FileStream = new FileStream();
						
						//Pack associated files
						for (var j:Number = 0; j < numberOfSpaceFiles; j++)
						{
							var sourceFile:File = new File(fs.readUTF()); //Source
							fs.readUTF(); //Skip actions
							fs.position += 88; //Skip object size and matrix data
							
							//Read image,video,or whatever into the bytearray
							var fileDataToSend:ByteArray;
							afs.open(sourceFile, FileMode.READ);
							afs.readBytes(fileDataToSend, 0, sourceFile.size);
							afs.close();
							
							ba.writeUTF(sourceFile.nativePath.split(":")[1]); //Truncate drive letter
							ba.writeFloat(fileDataToSend.length);
							ba.writeBytes(fileDataToSend, 0, fileDataToSend.length);
						}
						
						
						fs.close();
						
						c.sendObject(ba, ra); //Handle video streaming at later date vs sending entire video
						
						//Format [SpaceFileSize][SpaceFile][NumberOfObjects]
						//[NativePath][FileSize][File]
						//[NativePath][FileSize][File]Ect..
					}
					else
					{
						//Access denied by client.
						var ba:ByteArray = new ByteArray();
						ba.writeUTF("access denied");
						c.sendObject(ba, ra);
					}
				}
				else
				{
					//Couldn't find object. Send proper code.
					var ba:ByteArray = new ByteArray();
					ba.writeUTF("Four,Oh Four..");
					c.sendObject(ba, ra);
				}
				
			}
			else
			{
				//It's for another service.
				//The way this works, other plugins or services could intercept the same object request type for whatever reason
				//Say another plugin to log a history of object request
			}
		}
		
		private function allowedToAccess(pathOfSpace:String, returnAddress:String):Boolean 
		{
			var access:Boolean;
			
			//Check for permissions in space file
			var spaceFile:File = new File(pathOfSpace);
			var fs:FileStream = new FileStream();
			fs.open(spaceFile, FileMode.READ)
			fs.readDouble(); //Skip space size
			var accessDetail:String = fs.readUTF().toLowerCase();
			fs.close();
			
			//Format of access file
			
			//Allow: All [allows all users]
			//Allow: 0.0.0.0.0.0.0 //Allows only a certain list of users
			//Deny: 0.0.0.0.0.0.0 //Blocks only a certain list of user
			//Deny: All //Blocks all users
			
			//One line only
			var raw:Array = accessDetail.split(":");
			var type:String = raw[0];
			var users:Array = raw[1].split(",");
			
			if (type == "allow")
			{
				if (users.indexOf("all") > -1 || users.indexOf(returnAddress) > -1) //If all users are allowed or that specific user is
				{
					access = true; //Access allowed.
				}
				else
				{
					access = false; //Access denied.
				}
			}
			else if (type == "deny") //Else if, type == deny
			{
				if (users.indexOf("all") > -1 || users.indexOf(returnAddress) > -1) //If all users are denied or that specific user is
				{
					access = false; //Access denied.
				}
				else
				{
					access = true; //Access allowed since user isn't on a blocked list.
				}
			}
			return access;
		}
		
	}

}