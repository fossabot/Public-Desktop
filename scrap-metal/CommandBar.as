package 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class CommandBar extends MovieClip 
	{
		private var executables:Vector.<File>; //Contains executables [In sync with filesnames]
		private var filenames:Vector.<String>; //Contains only file names [In sync with executables]
		
		private var fs:FileStream;
		private var datafile:File;
		
		private var progressChannel:MessageChannel;
		private var resultChannel:MessageChannel;
		
		public function CommandBar() 
		{
			var swfBytes:ByteArray = this.loaderInfo.bytes;
			datafile = File.applicationStorageDirectory.resolvePath(".execut");
			executables = new Vector.<File>();
			filenames = new Vector.<String>();
			fs = new FileStream();
			
			if (Worker.current.isPrimordial)
			{
				var bgWorker:Worker = WorkerDomain.current.createWorker(swfBytes);
				bgWorker.start();
				bgWorker.addEventListener(Event.WORKER_STATE, workerStateHandler);
				trace("Worker started.");
			}
			else //BG worker entry point
			{
				if (datafile.exists)
				{
					trace("I exist");
					fs.open(datafile, FileMode.READ); //Open file with executables
					var raw:String = new String();
					raw = fs.readUTFBytes(datafile.size); //Raw file (huge string)
					
					trace("Huge string size = " + raw.length);
					
					var exes:Array = new Array();
					exes = raw.split("||"); //Split the array
					raw = null; //Clear the RAM
					trace("Exe size = " + exes.length);
					
					var newFile:File = new File();
					for each (var paths:String in exes)
					{
						newFile = File.applicationStorageDirectory.resolvePath(paths);
						executables.push(newFile);
						filenames.push(newFile.name);
					}
					fs.close();
					
					trace("Example: " + executables[56].nativePath);
					trace("Length = " + executables.length);
					trace("ready for command");
				}
				else //FirstRun
				{
					//Set function
					trace("I dont exist");
					function getExecutables(f:File):void
					{
						var directoryContents:Array = f.getDirectoryListing();
						for each (var content:File in directoryContents)
						{
							if (content.isDirectory)
							{
								getExecutables(content);
							}
							else
							{
								if (content.extension == "exe")
								{
									executables.push(content); //File data and path
									filenames.push(content.name); //Filename
								}
							}
						}
					}
					
					var base:Array = File.getRootDirectories();
					fs.open(datafile, FileMode.WRITE);
					
					for each (var f:File in base)
					{
						getExecutables(f);
					}
					
					for each (var exe:File in executables)
					{
						//Save all executable paths for future use.
						fs.writeUTFBytes(exe.nativePath + "||");
					}
					
					fs.close();
					trace("ready for command");
				}
			}
			
			command_txt.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		}
		
		private function workerStateHandler(e:Event):void 
		{
			trace("worker state event");
			trace(e);
		}
		
		private function keyHandler(e:KeyboardEvent):void 
		{
			
			if (e.keyCode == 13)
			{
				//open selected on enter
				trace("Enter");
				var toExecute:File;
				
				if (filenames.indexOf(command_txt.text + ".exe") > -1)
				{
					trace("Found " + command_txt.text + ".exe");
					toExecute = executables[filenames.indexOf(command_txt.text + ".exe")];
					toExecute.openWithDefaultApplication();
					//stage.sidebar_mc.addShortcut(toExecute); //Tell sidebar to add the shortcut
					trace("Opening..");
				}
				else
				{
					//If can't find file.
					command_txt.text = "Not found";
					trace("not found");
				}
			}
		}
		
	}

}