package sfxworks.services 
{
	import by.blooddy.crypto.MD5; //Awesome guy
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.GroupSpecifier;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.NetworkGroupEvent;
	import flash.errors.IOError;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FileSharingService extends EventDispatcher
	{
		//Fetch public file listing from mysqldb
		private var c:Communications;
		private var mysqlConnection:Connection;
		private var fileSharingInfo:File;
		
		private var filePaths:Vector.<String>;
		private var fileIDs:Vector.<Number>;
		private var fileStartIndex:Vector.<Number>;
		private var fileEndIndex:Vector.<Number>;
		private var groupIDs:Vector.<Number>;
		
		private var numberOfGroups:Number;
		private var numberOfConnectedGroups:Number;
		
		//Example
		//C:/awesome.mp4
		//5748
		
		//Calcualte end index by dividing filesize by 10MB. The rest, say 3MB is it's own object
		
		//First float = number of files 
		//Then string to file path, then groupNumber, then number to start index
		//By default file splitting is set to 10MB. endIndex is calculated based on this.
		
		
		//Compilng of files
		private var filesToHandle:Array;
		/* Format for inside files to handles
		filePartListing:Vector.<Number>;
		filePathListing:Vector.<String>;
		fileTotalListing:Vector.<String>;
		fileMD5Listing:Vector.<String>;
		fileNameListing:Vector.<String>;
		
		Example: 354 355 356 357
		       : $Path1 $Path2 $Path3 $Path4
			   : 357 357 357 357
			   Paths remain nulll until fuffiled
			   if all are not null, merges files and writes them.
		*/
		
		
		public static const SERVICE_NAME:String = "FILE-SHARING-SERVICE";
		private static const SPLIT_SIZE:Number = 10000000;
		
		public function FileSharingService(communications:Communications) 
		{
			c = communications;
			
			mysqlConnection = new Connection("-.sfxworks.net", 9001, "-", "-", "files");
			mysqlConnection.connect();
			mysqlConnection.addEventListener(Event.CONNECT, handleMysqlConnection);
			
			fileSharingInfo = File.applicationStorageDirectory.resolvePath("services" + File.separator + "filesharingservice" + File.separator + "info");
			
			
		}
		
		private function handleMysqlConnection(e:Event):void 
		{
			//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
			//18446744073709551615 per table :D
			mysqlConnection.removeEventListener(Event.CONNECT, handleMysqlConnection);
			
			//Get the last row in the table
			var st:Statement = mysqlConnection.createStatement();
			st.sql = "SELECT * FROM files"
				+ "ORDER BY `id` DESC"
				+ "LIMIT 1;";
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(getLastRowInitSuccess, getLastRowInitError, t));
		}
		
		private function getLastRowInitError(info:Object, token:MySqlToken):void
		{
			dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR));
		}
		
		private function getLastRowInitSuccess(data:Object, token:MySqlToken):void 
		{
			var rs:ResultSet = new ResultSet(token);
			numberOfGroups = parseFloat(rs.getString("groupID")); //The last row, in the groupID column will have the number of groups.
			
			//Create and connect to said groups.
			c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGroupConnectionSuccessful);
			for (var i:Number = 0; i < numberOfGroups; i++)
			{
				var gs:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + i.toString());
				gs.objectReplicationEnabled = true;
				
				c.addGroup(SERVICE_NAME + i.toString(), gs);
			}
		}
		
		private function handleGroupConnectionSuccessful(e:NetworkGroupEvent):void 
		{
			numberOfConnectedGroups++;
			if (numberOfGroups == numberOfConnectedGroups)
			{
				if (fileSharingInfo.exists)
				{
					//Search through files. Add each to have objects.
					//Stores file id locally. Should make a system to check db to make sure no one would change if they looked into the source code. 
					//MD5 will prevent false distribution, but no idea if the user will ever be able to download the right file.
					
					var fs:FileStream = new FileStream();
					fs.open(fileSharingInfo, FileMode.READ);
						var numberOfFiles:Number = fs.readFloat();
						
						for (var i:Number = 0; i < numberOfFiles; i++)
						{
							var sharedFile:File = new File(fs.readUTF()); //Example: C:/Users/Awesome/Documents/file.mp4
							var sharedFileGroupNumber:Number = fs.readFloat(); //  : 0
							var sharedFileStartIndex:Number = fs.readFloat();//    : 4145
							
							if (sharedFile.exists)
							{
								//Max file size = 4GB
								var endIndex:Number = Math.ceil(sharedFile.size / SPLIT_SIZE) + sharedFileStartIndex;
								/* Example:
								 * FileSize 
								 * 750,000,000 (750 MB)
								 * StartIndex = 4145                     750MB        100MB
								 * EndIndex   = 4153 [8 additional] (750,000,000 / 100,000,000) rounded up + 4145. The start of the file index
								 */ 
								
								c.addHaveObject(SERVICE_NAME + sharedFileGroupNumber.toString(), sharedFileStartIndex, endIndex); 
								//Adds the file to group for avalibility.
								
								
								for (var i:Number = sharedFileStartIndex; i < endIndex; i++)
								{
									//Index path, id, and group number seperated by 100MB
									filePaths.push(sharedFile.nativePath);
									fileIDs.push(i);
									groupIDs.push(sharedFileGroupNumber);
									fileStartIndex.push(sharedFileStartIndex);
									fileEndIndex.push(endIndex);
								}
							}
						}
				}
				else
				{
					var fs:FileStream = new FileStream();
					fs.open(fileSharingInfo, FileMode.WRITE);
						fs.writeFloat(0);
					fs.close();
				}
				
				dispatchEvent(new FileSharingEvent(FileSharingEvent.READY));
				c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
			}
		}
		
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			var objectToSend:ByteArray = new ByteArray();
			
			var sourceFile:File = new File(filePaths[fileIDs.indexOf(e.groupObjectNumber)]);
			if (sourceFile.exists)
			{
				var fs:FileStream = new FileStream();
				try
				{
					fs.open(sourceFile, FileMode.READ);
					//  Example:          476                                 474                             2 * 10MB
					fs.position = (e.groupObjectNumber - fileStartIndex[fileIDs.indexOf(e.groupObjectNumber)]) * SPLIT_SIZE;
					fs.readBytes(objectToSend, 0, SPLIT_SIZE);
					fs.close();
					
					c.satisfyObjectRequest(e.groupName, e.groupObjectNumber, objectToSend);
				}
				catch (error:IOError)
				{
					dispatchEvent(error);
				}
			}
			else
			{
				//User moved, or deleted file. Maybe do a thing where if it matches with an md5 and a name update the move location like that.
				//Or alternatives
				//Remove from "has list" for now
				//This would need be handled in addFile though. Checking for duplicates and such. No one likes duplicate, shitty videos. 
				
				c.removeHaveObject(e.groupName, e.groupObjectNumber, e.groupObjectNumber);
			}
			
		}
		
		
		public function addFile(file:File):void
		{
			//Gets last aval number from mysql table
			//Checks to see if max object number [9007199254740992] will be reached if it places this file.
			//If so, creates new group.
			//Registers objects.
			if (file.size > Number.MAX_VALUE)
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "File too large."));
				return;
			}
			
			//Get the last row in the table
			var st:Statement = mysqlConnection.createStatement();
			st.sql = "SELECT * FROM files"
				+ "ORDER BY `id` DESC"
				+ "LIMIT 1;";
			var t:MySqlToken = st.executeQuery();
			t.addResponder(new AsyncResponder(getLastRowAddFileSuccess, mysqlNearIDUpdateError, t));
			
			//It's inside a function so I can handle a ton of addFile() methods at once since it's asyncronous 
			function getLastRowAddFileSuccess(data:Object, token:MySqlToken):void
			{
				var rs:ResultSet = new ResultSet(token);
				var lastEndIndex:Number = parseFloat(rs.getString("groupID"));
				
				var numberOfSplits:Number = Math.ceil(file.size / SPLIT_SIZE);
				
				if (lastEndIndex + numberOfSplits > 9007199254740992)
				{
					//A new group must be made. Tell all clients.
					numberOfGroups ++;
				}
				
				//write to filesharinginfo
				var fs:FileStream = new FileStream();
				
				fs.open(fileSharingInfo, FileMode.WRITE);
					fs.writeUTF(file.nativePath);
					fs.writeFloat(numberOfGroups);
					fs.writeFloat(lastEndIndex + 1);
					fs.close();
				
				//write to index
				
				var startIndex:Number = lastEndIndex + 1;
				var endIndex:Number = startIndex + numberOfSplits;
				
				for (var i:Number = startIndex; i < endIndex; i++)
				{
					filePaths.push(file.nativePath);
					fileIDs.push(i);
					groupIDs.push(numberOfGroups);
					fileStartIndex.push(startIndex);
					fileEndIndex.push(endIndex);
				}
				
				//write to group
				c.addHaveObject(SERVICE_NAME + numberOfGroups.toString(), startIndex, endIndex); 
				
				//write to sql
				
				//generate md5s
				var md5s:String = new String()
				var fileData:ByteArray = new ByteArray();
				fs.open(file, FileMode.READ);
					for (var i:Number = 0; i < numberOfSplits; i++)
					{
						var tmp:ByteArray = new ByteArray();
						
						var toRead:Number = SPLIT_SIZE;
						if (fs.bytesAvailable < SPLIT_SIZE)
						{
							toRead = fs.bytesAvailable;
						}
						
						fs.readBytes(tmp, 0, toRead);
						md5s = md5s + MD5.hashBytes(tmp);
					}
				fs.close();
				
				//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
				var submitSt:Statement = mysqlConnection.createStatement();
				submitSt.sql = "INSERT INTO files (`filename`, `startindex`, `endindex`, `groupid`, `md5`)"
					+ " VALUES ('" + file.name + file.extension + "'," + startIndex.toString() + "," + endIndex.toString() + "," + numberOfGroups.toString() + ",'" + md5s + "');";
					
				var submitToken:MySqlToken = submitSt.executeQuery();
				submitToken.addResponder(new AsyncResponder(submitSuccess, submitFailure, submitToken));
				
				//Yo dawg I heard you like functions
				function submitSuccess(data:Object, token:MySqlToken):void
				{
					dispatchEvent(new FileSharingEvent(FileSharingEvent.FILE_ADDED, "Successfully added file " + file.name));
				}
				
				function submitFailure(data:Object, token:MySqlToken):void
				{
					dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "Failed to added file " + file.name + ". Couldn't submit to database..."));
				}
			}
		}
		
		
		public function getFile(groupNumber:Number, startIndex:Number, endIndex:Number, location:File):void
		{
			var statement:Statement = mysqlConnection.createStatement();
			statement.sql = "SELECT * from `files` WHERE `publickey`=" + groupNumber.toString() + " AND `startindex`=" + startIndex.toString() + ";";
			var token:MySqlToken = statement.executeQuery();
			
			submitToken.addResponder(new AsyncResponder(getFileInfoSuccess, getFileInfoFailure, token));
			
			function getFileInfoSuccess(data:Object, token:MySqlToken):void
			{
				var resultSet:ResultSet = new ResultSet(token);
				//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
				
				c.addWantObject(SERVICE_NAME + groupNumber.toString(), startIndex, endIndex);
				
				
				var filePartListing:Vector.<Number> = new Vector.<Number>();
				var filePathListing:Vector.<String> = new Vector.<String>();;
				var fileMd5Listing:Vector.<String> = new Vector.<String>();;
				
				var mdraw:Array = resultSet.getString("md5").split(",");
				
				for (var i:Number = startIndex; i < endIndex; i++)
				{
					filePartListing.push(i);
					filePathListing.push(null);
					fileMd5Listing.push(mdraw[endIndex - i]); //Last one is going first
				}
				
				//Order [idnumbers][paths] max | md5 | name | groupID | locationToSave
				filesToHandle.push(filePartListing); //idnumbers
				filesToHandle.push(filePathListing); //paths
				filesToHandle.push(resultSet.getInt("endindex"));
				filesToHandle.push(resultSet.getString("md5"));
				filesToHandle.push(resultSet.getString("filename"));
				filesToHandle.push(resultSet.getInt("groupID"));
				filesToHandle.push(location);
				
				c.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
			}
			function getFileInfoFailure(data:Object, token:MySqlToken):void
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "MYSQL Error: " + data));
			}
		}
		
		private function handleObjectRecieved(e:NetworkGroupEvent):void 
		{
			for (var i:Number = 0; i < filesToHandle.length; i += 7)
			{
				var filePartListing:Vector.<Number> = filesToHandle[i];
				
				if (filePartListing.indexOf(e.groupObjectNumber) > -1)
				{
					//It found the file id, so write the path       Example: asrfhawhatever              377   -    374 (3)
					//                                                             md5              maxlisting - objectnumber [Last is first]
					if (MD5.hashBytes(e.groupObject as ByteArray) == filesToHandle[i + 4][filesToHandle[i + 2] - e.groupObjectNumber])
					{
						trace("Matched md5 for recived file from record");
						
						//Write the file in a tmp dir
						var file:File = File.createTempFile();
						
						var fs:FileStream = new FileStream();
						fs.open(file, FileMode.WRITE);
							fs.writeBytes(e.groupObject as ByteArray, 0, SPLIT_SIZE);
							fs.close();
						
						filesToHandle[i + 1][filesToHandle[i + 2] - e.groupObjectNumber] = file.nativePath; //Set the path for that specific part
						
						dispatchEvent(new FileSharingEvent(FileSharingEvent.FILE_PART_DOWNLOADED, "Successfully downloaded filepart " + e.groupObjectNumber));
						
						if (filesToHandle[i + 1].indexOf(null) > -1)
						{
							//There's still a null value. Not all file parts have been downloaded.
						}
						else
						{
							//All files are complete. Combine them into one.
							var sourceFile:File = filesToHandle[7]; //This is a directory
							sourceFile.resolvePath(filesToHandle[6]); //Get the name [6] and resolve it from the directory location [7]
							var fs:FileStream = new FileStream();
							fs.open(sourceFile, FileMode.WRITE); //While opening a filestream to the target location........
							for each (var path:String in filesToHandle[i + 1]); //-------------this might need reverse()ing and needs testing
							{
								var tmp:ByteArray = new ByteArray(); //Load each bytearray from the tmp file
								
								var filePart:File = new File(path);
								var ifs:FileStream = new FileStream();
								ifs.open(filePart, FileMode.READ); //and write each part to the target location!
									fs.readBytes(tmp, 0, filePart.size);
									fs.close();
								
								fs.writeBytes(tmp, 0, tmp.bytesAvailable);
							}
							fs.close();
							
							//Add for sharing / seeding
							
							fs.open(fileSharingInfo, FileMode.WRITE);
								fs.writeUTF(sourceFile.nativePath);
								fs.writeFloat(numberOfGroups);
								fs.writeFloat(filesToHandle[3]);
								fs.close();
							//                                calculated start index                                      endindex
							var startIndex:Number = (Math.ceil(sourceFile.size / SPLIT_SIZE) - filesToHandle[3]) * -1;
							for (var i:Number = startIndex; i < filesToHandle[3]; i++)
							{
								filePaths.push(sourceFile.nativePath);
								fileIDs.push(i);
								groupIDs.push(filesToHandle[6]);
								fileStartIndex.push(startIndex);
								fileEndIndex.push(filesToHandle[3]);
							}
							//Notify Group
							c.addHaveObject(SERVICE_NAME + filesToHandle[6], startIndex, endIndex);
							
							//Remove from filelisting
							filesToHandle.splice(i, 7);
							
							dispatchEvent(new FileSharingEvent(FileSharingEvent.FILE_DOWNLOADED, "File successfully downloaded and saved to " + sourceFile.nativePath));
							
							
							//Through with that.
						}
					}
					else
					{
						dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "MD5 did not match with recieved file"));
						//I could have it try to redownload it..
						c.addWantObject(e.groupName, e.groupObjectNumber, e.groupObjectNumber);
						
						//Or something else maybe..
					}
				}
			}
		}
		
		
	}

}