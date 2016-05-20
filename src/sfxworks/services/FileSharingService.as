package sfxworks.services 
{
	import by.blooddy.crypto.MD5; //Awesome guy
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
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
	import sfxworks.services.events.DatabaseServiceEvent;
	import sfxworks.services.events.FileSharingEvent;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class FileSharingService extends EventDispatcher
	{
		//Fetch public file listing from mysqldb
		private var c:Communications;
		private var fileSharingInfo:File;
		
		private var _filePaths:Vector.<String>;
		private var _fileIDs:Vector.<Number>;
		private var _fileStartIndex:Vector.<Number>;
		private var _fileEndIndex:Vector.<Number>;
		private var _groupIDs:Vector.<Number>;
		
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
			   
		
		//Tmp for browse for save
		private var resultSets:Vector.<SQLResult>;
		private var saveLocations:Vector.<File>;
		
		
		public static const SERVICE_NAME:String = "FILE-SHARING-SERVICE";
		private static const SPLIT_SIZE:Number = 10000000;
		
		public function FileSharingService(communications:Communications) 
		{
			c = communications;
			c.databaseService.connectToDatabase(SERVICE_NAME);
			c.databaseService.addEventListener(DatabaseServiceEvent.CONNECTED, handleDatabaseConnection);
			
			fileSharingInfo = File.applicationStorageDirectory.resolvePath("services" + File.separator + "filesharingservice" + File.separator + "infoE");
			
			_filePaths = new Vector.<String>();
			_fileIDs = new Vector.<Number>();
			_fileStartIndex = new Vector.<Number>();
			_fileEndIndex = new Vector.<Number>();
			_groupIDs = new Vector.<Number>();
			numberOfGroups = new Number(0);
			numberOfConnectedGroups = new Number(0);
		}
		
		private function handleDatabaseConnection(e:DatabaseServiceEvent):void 
		{
			//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
			//18446744073709551615 per table :D
			c.databaseService.removeEventListener(DatabaseServiceEvent.CONNECTED, handleDatabaseConnection);
			trace("File sharing service connected to peer database.");
			var check:SQLStatement = new SQLStatement();
			
			var sql:String = "CREATE TABLE IF NOT EXISTS files (" +  
				"    id PRIMARY KEY, " +  
				"    filename TEXT, " +  
				"    startindex NUMBER," +
				"    endindex NUMBER," +
				"    groupID NUMBER," +
				"    md5 TEXT" +
				");"; 
			check.text = sql;
			
			var checkResult = c.databaseService.writeToDB(SERVICE_NAME, check);
			if (checkResult is SQLError)
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, checkResult));
				return;
			}
			
			//Get the last row in the table
			var st:SQLStatement = new SQLStatement();
			st.text = "SELECT * FROM files "
				+ "ORDER BY `id` DESC "
				+ "LIMIT 1;";
			
			var fetchResult = c.databaseService.readFromDB(SERVICE_NAME, st);
			if (fetchResult is SQLError)
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, checkResult));
				return;
			}
			//t.addResponder(new AsyncResponder(getLastRowInitSuccess, getLastRowInitError, t));
			if ((fetchResult as SQLResult).data == null)
			{
				numberOfGroups = 0;
			}
			else
			{
				numberOfGroups = (fetchResult as SQLResult).data[0].groupID;
			}
			
			trace("Response successful.");
			trace("Number of groups = " + numberOfGroups);
			
			for (var i:Number = 0; i < numberOfGroups+1; i++)
			{
				var gs:GroupSpecifier = new GroupSpecifier(SERVICE_NAME + i.toString());
				gs.objectReplicationEnabled = true;
				gs.serverChannelEnabled = true;
				trace("Adding group " + SERVICE_NAME + i.toString());
				c.addGroup(SERVICE_NAME + i.toString(), gs);
				
				//Create and connect to said groups.
				c.addEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGroupConnectionSuccessful);
				c.addEventListener(NetworkGroupEvent.CONNECTION_FAILED, handleGroupConnectionFailed);
			}
			
		}
		
		private function handleGroupConnectionFailed(e:NetworkGroupEvent):void 
		{
			trace("The group connection failed..");
		}
		
		private function handleGroupConnectionSuccessful(e:NetworkGroupEvent):void 
		{
			trace("Successful group connection.");
			e.target.removeEventListener(NetworkGroupEvent.CONNECTION_SUCCESSFUL, handleGroupConnectionSuccessful);
			e.target.removeEventListener(NetworkGroupEvent.CONNECTION_FAILED, handleGroupConnectionFailed);
			if (numberOfGroups == numberOfConnectedGroups)
			{
				if (fileSharingInfo.exists)
				{
					trace("FILE SHARING SERVICE: File sharing info exists..");
					//Search through files. Add each to have objects.
					//Stores file id locally. Should make a system to check db to make sure no one would change if they looked into the source code. 
					//MD5 will prevent false distribution, but no idea if the user will ever be able to download the right file.
					
					var fs:FileStream = new FileStream();
					fs.open(fileSharingInfo, FileMode.READ);
					
						var numberOfFiles:Number = fs.readFloat();
						trace("FILE SHARING SERVICE: Number of files = " + numberOfFiles);
						for (var i:Number = 0; i < numberOfFiles; i++)
						{
							var sharedFile:File = new File(fs.readUTF()); //Example: C:/Users/Awesome/Documents/file.mp4
							var sharedFileGroupNumber:Number = fs.readFloat(); //  : 0
							var sharedFileStartIndex:Number = fs.readFloat();//    : 4145
							
							trace("FILE SHARING SERVICE: Checking file: " + sharedFile.nativePath);
							
							if (sharedFile.exists)
							{
								trace("FILE SHARING SERVICE: File exists.");
								//Max file size = 4GB
								var endIndex:Number = Math.ceil(sharedFile.size / SPLIT_SIZE) + sharedFileStartIndex;
								/* Example:
								 * FileSize 
								 * 750,000,000 (750 MB)
								 * StartIndex = 4145                    75MB        10MB
								 * EndIndex   = 4153 [8 additional] (75,000,000 / 10,000,000) rounded up + 4145. The start of the file index
								 */ 
								
								c.addHaveObject(SERVICE_NAME + sharedFileGroupNumber.toString(), sharedFileStartIndex, endIndex); 
								//Adds the file to group for avalibility.
								
								trace("FILE SHARING SERVICE: writing to index..");
								for (var i:Number = sharedFileStartIndex; i < endIndex; i++)
								{
									//Index path, id, and group number seperated by 10MB
									trace("FILE SHARING SERVICE: Index " + sharedFile.name + ": Part " + i);
									_filePaths.push(sharedFile.nativePath);
									_fileIDs.push(i);
									_groupIDs.push(sharedFileGroupNumber);
									_fileStartIndex.push(sharedFileStartIndex);
									_fileEndIndex.push(endIndex);
								}
							}
						}
				}
				else
				{
					numberOfConnectedGroups++;
				}
				
				dispatchEvent(new FileSharingEvent(FileSharingEvent.READY));
				c.addEventListener(NetworkGroupEvent.OBJECT_REQUEST, handleObjectRequest);
				c.addEventListener(NetworkGroupEvent.OBJECT_RECIEVED, handleObjectRecieved);
			}
		}
		
		private function handleObjectRequest(e:NetworkGroupEvent):void 
		{
			var objectToSend:ByteArray = new ByteArray();
			
			var sourceFile:File = new File(_filePaths[_fileIDs.indexOf(e.groupObjectNumber)]);
			if (sourceFile.exists)
			{
				var fs:FileStream = new FileStream();
				fs.open(sourceFile, FileMode.READ);
					//  Example:          476                                 474                             2 * 10MB
					fs.position = (e.groupObjectNumber - _fileStartIndex[_fileIDs.indexOf(e.groupObjectNumber)]) * SPLIT_SIZE;
					fs.readBytes(objectToSend, 0, SPLIT_SIZE);
					fs.close();
					
					c.satisfyObjectRequest(e.groupName, e.groupObjectNumber, objectToSend);
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
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "File too large.", file.nativePath));
				return;
			}
			
			//Get the last row in the table
			
			var st:SQLStatement = new SQLStatement();
			st.text = "SELECT * FROM files "
				+ "ORDER BY `id` DESC "
				+ "LIMIT 1;";
			var result = c.databaseService.readFromDB(SERVICE_NAME, st);
			
			if (result is SQLError)
			{
				trace("MYSQL ERROR: " + result);
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, result, file.name));
				return;
			}
			
			if ((result as SQLResult).data[0] == null)
			{
				lastEndIndex = 0;
			}
			else
			{
				var lastEndIndex:Number = (result as SQLResult).data[0].groupID;
			}
			
			
			var numberOfSplits:Number = Math.ceil(file.size / SPLIT_SIZE);
			
			if (lastEndIndex + numberOfSplits > 9007199254740992)
			{
				//A new group must be made. Tell all clients.
				numberOfGroups ++;
			}
			var startIndex:Number = lastEndIndex + 1;
			var endIndex:Number = startIndex + numberOfSplits;
			
			//write to sql --- 
			
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
					var newMd5:String = MD5.hashBytes(tmp);
					md5s = md5s + newMd5;
					trace("MD5 HASH:" + newMd5 + " for file sector " + i.toString());
				}
			fs.close();
			
			//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
			var submitSt:SQLStatement = new SQLStatement();
			submitSt.text = "INSERT INTO files (`filename`, `startindex`, `endindex`, `groupid`, `md5`)"
				+ " VALUES ('" + file.name + "'," + startIndex.toString() + "," + endIndex.toString() + "," + numberOfGroups.toString() + ",'" + md5s + "');";
				
			trace("Submitting file to p2p database..");
			var submitResult = c.databaseService.writeToDB(SERVICE_NAME, submitSt);
			
			if (submitResult is SQLError)
			{
				trace("Final submit failure. Mysql Error: " + submitResult);
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "Failed to added file " + file.name + ". Couldn't submit to database..."));
				return;
			}
			
			trace("Writing to group..");
			//write to group
			c.addHaveObject(SERVICE_NAME + numberOfGroups.toString(), startIndex, endIndex);
			
			//write to index
			trace("Writing to index..");
			for (var i:Number = startIndex; i < endIndex; i++)
			{
				_filePaths.push(file.nativePath);
				_fileIDs.push(i);
				_groupIDs.push(numberOfGroups);
				_fileStartIndex.push(startIndex);
				_fileEndIndex.push(endIndex);
			}
			
			trace("Writing to filesharing info..");
			//write to filesharinginfo
			var fs:FileStream = new FileStream();
			
			fs.open(fileSharingInfo, FileMode.WRITE);
				fs.writeFloat(new Number(_filePaths.length)) //Write number of files to first float
				fs.close();
			fs.open(fileSharingInfo, FileMode.APPEND);
				fs.writeUTF(file.nativePath);
				fs.writeFloat(numberOfGroups);
				fs.writeFloat(lastEndIndex + 1);
				fs.close();
			
			dispatchEvent(new FileSharingEvent(FileSharingEvent.FILE_ADDED, "Successfully added file " + file.name, file.nativePath, startIndex, endIndex, numberOfGroups));
		}
		
		
		public function getFile(groupNumber:Number, startIndex:Number, endIndex:Number):void
		{
			var file:File = new File();
			
			var statement:SQLStatement = new SQLStatement();
			statement.text = "SELECT * from `files` WHERE `publickey`=" + groupNumber.toString() + " AND `startindex`=" + startIndex.toString() + ";";
			
			var result = c.databaseService.readFromDB(SERVICE_NAME, statement);
			if (result is SQLError)
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "MYSQL Error: " + (result as SQLError).details));
				return;
			}
			
			//Mysql format: id(autogen) | FileName.ext | Start Index | EndIndex |  groupID | md5
			
			if ((result as SQLResult).data.length == -1)
			{
				dispatchEvent(new FileSharingEvent(FileSharingEvent.ERROR, "No file by that ID exists in the public database.."));
			}
			else
			{
				//Reference to file exists. Browse for save..
				file.browseForDirectory("Select a location to save the file..");
				file.addEventListener(Event.SELECT, handleBrowseForSaveSelection);
				//tmp index
				saveLocations.push(file);
				resultSets.push(result);
			}
		}
		
		private function handleBrowseForSaveSelection(e:Event):void 
		{
			e.target.removeEventListener(Event.SELECT, handleBrowseForSaveSelection);
			
			var resultSet:SQLResult = resultSets[saveLocations.indexOf(e.target)];
			resultSets.splice(resultSets.indexOf(resultSet),1);//Remove from tmp index
			saveLocations.splice(saveLocations.indexOf(e.target),1); //Remove from tmp index
			
			var groupNumber:Number = resultSet.data[0].groupid;
			var startIndex:Number = resultSet.data[0].startindex;
			var endIndex:Number = resultSet.data[0].endindex;
			
			var filePartListing:Vector.<Number> = new Vector.<Number>();
			var filePathListing:Vector.<String> = new Vector.<String>();;
			var fileMd5Listing:Vector.<String> = new Vector.<String>();;
			
			var mdraw:Array = resultSet.data[0].md5.split(",");
				
			for (var i:Number = startIndex; i < endIndex; i++)
			{
				filePartListing.push(i);
				filePathListing.push(null);
				fileMd5Listing.push(mdraw[endIndex - i]); //Last one is going first
			}
			
			//Order [idnumbers][paths] max | md5 | name | groupID | locationToSave
			filesToHandle.push(filePartListing); //idnumbers
			filesToHandle.push(filePathListing); //paths
			filesToHandle.push(resultSet.data[0].endindex);
			filesToHandle.push(resultSet.data[0].md5);
			filesToHandle.push(resultSet.data[0].filename);
			filesToHandle.push(resultSet..data[0].groupID);
			filesToHandle.push(e.target);
			
			c.addWantObject(SERVICE_NAME + groupNumber.toString(), startIndex, endIndex);
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
								_filePaths.push(sourceFile.nativePath);
								_fileIDs.push(i);
								_groupIDs.push(filesToHandle[6]);
								_fileStartIndex.push(startIndex);
								_fileEndIndex.push(filesToHandle[3]);
							}
							//Notify Group
							c.addHaveObject(SERVICE_NAME + filesToHandle[6], startIndex, filesToHandle[3]);
							
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
		
		public function removeFile(file:File):void
		{
			var localIndexNumber:int = _filePaths.indexOf(file.nativePath);
			
			//Remove from communications
			c.removeHaveObject(SERVICE_NAME + numberOfGroups.toString(), _fileStartIndex[localIndexNumber], _fileEndIndex[localIndexNumber]);
			
			//Remove form index
			_filePaths.splice(localIndexNumber, 1);
			_fileIDs.splice(localIndexNumber, 1);
			_fileStartIndex.splice(localIndexNumber, 1);
			_fileEndIndex.splice(localIndexNumber, 1);
			_groupIDs.splice(localIndexNumber, 1);
			
			//Delete the save index
			fileSharingInfo.deleteFile();
			//Rewrite save index.
			var fs:FileStream = new FileStream();
			fs.open(fileSharingInfo, FileMode.WRITE);
				//Write new number of files
				fs.writeFloat(new Number(_filePaths.length));
				//Index accordingly
				for (var i:int = 0; i < _filePaths.length; i++)
				{
					fs.writeUTF(_filePaths[i]);
					fs.writeFloat(_groupIDs[i]);
					fs.writeFloat(_fileStartIndex[i]);
				}
				fs.close();
		}
		
		/* TODO: Handle communication's events [connects and disconnects]
		 * 
		 * 
		 */
		
		public function get filePaths():Vector.<String> 
		{
			return _filePaths;
		}
		
		public function get fileIDs():Vector.<Number> 
		{
			return _fileIDs;
		}
		
		public function get fileStartIndex():Vector.<Number> 
		{
			return _fileStartIndex;
		}
		
		public function get fileEndIndex():Vector.<Number> 
		{
			return _fileEndIndex;
		}
		
		public function get groupIDs():Vector.<Number> 
		{
			return _groupIDs;
		}
		
		
	}

}