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
						var fs:FileStream = new FileStream();
						fs.open(requestedSpace, FileMode.READ); //Read space file into a byte array
						fs.readBytes(ba, 0, requestedSpace.size);
						fs.close();
						
						//Send spacefile over to the requester.
						c.sendObject(ba, ra);
					}
				}
				else
				{
					//Couldn't find object. Send proper code.
					c.sendObject("Four,Oh Four..", ra);
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