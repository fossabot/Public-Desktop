package sfxworks 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import sfxworks.NetworkUserEvent;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SpaceFiles extends MovieClip
	{
		//Feed ID
		//Posting Permission
		//Link = PublicKey:FileName
		
		private var _target:ByteArray; //The public key (the target) of the file listing
		private var _spaceName:String;
		private var _c:Communications;
		
		/*Request types
		space-files [space's name]
		space-file [file's name]
		
		*/
		
		//Temp
		private var locationToSave:File;
		private var recievedFile:ByteArray;
		private var selectedListing:FileListing;
		
		public function SpaceFiles(target:ByteArray, spaceName:String, c:Communications) 
		{
			_target = target;
			_spaceName = spaceName;
			_c = c;
			//browse others people spaces and other files in public listing
			if (_target != c.publicKey) //If it's setup to handle a foreign user's file listing
			{
				c.requestObject(target, "space-files," + spaceName); //Send a request of type "space-files" to the target
				c.addEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleRecievedObject);
			}
			
		}
		
		private function handleRecievedObject(e:NetworkUserEvent):void 
		{
			c.removeEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleRecievedObject);
			displayFileListing(e.message);
			//File Listing only shows files the requesting user has persmisison to see
		}
		
		private function displayFileListing(files:Object):void //Step 0: Init. Get list of avalibe files user can request
		{
			//Format of "files" object
			//Byte array
			//First number = number of files
			//[Path for host],[Path for host] etc
			var ba:ByteArray = files as ByteArray;
			var numberOfFiles:Number = ba.readDouble();
			
			for (var i:Number = 0; i < numberOfFiles; i++) //Handle each file path
			{
				var fl:FileListing = new FileListing(ba.readUTF()); //Create new bar
				container_mc.addChild(fl); //Add to stage
				fl.addEventListener(MouseEvent.CLICK, handleFileListingClick); //Handle click interaction
			}
		}
		
		private function handleFileListingClick(e:MouseEvent):void //Step 1 : User Clicks FileListing
		{
			_c.requestObject(_target, "space-file," + e.target.filePath); //Request object form communications using arg {space-file,[filepath]}
			_c.addEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleFileRecieved); //AddEventListener for when it's recieved
			selectedListing = e.target; //Register with private var for tmp index
		}
		
		private function handleFileRecieved(e:NetworkUserEvent):void //Step 2: File is recieved, User Selects location to save
		{
			_c.removeEventListener(NetworkUserEvent.OBJECT_RECIEVED, handleFileRecieved); //Remove event listener
			recievedFile = e.message as ByteArray(); //Register with private var for tmp index 
			locationToSave.browseForSave("Where should I put " + selectedListing.fileName); //Browse for save
			locationToSave.addEventListener(Event.SELECT, handleLocationToSaveSelection); //Handle selection
		}
		
		private function handleLocationToSaveSelection(e:Event):void //Step 3: File is saved
		{
			var fs:FileStream = new FileStream(); //Filestream
			fs.open(locationToSave, FileMode.WRITE);
			fs.writeBytes(recievedFile, 0, recievedFile.length); //Save the file
			fs.close(); 
			selectedListing.recieveSuccessful(); //Tell FileListing object that file has been recieved
		}
		
	}

}