package 
{
	
	import by.blooddy.crypto.serialization.SerializationHelper;
	import com.coltware.airxzip.ZipEntry;
	import com.coltware.airxzip.ZipFileReader;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.events.FileListEvent;
	import flash.events.NativeDragEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import sfxworks.NetworkEvent;
	import sfxworks.NetworkUserEvent;
	import flash.display.MovieClip;
	import flash.display.Screen;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import sfxworks.Communications;
	import sfxworks.NetworkActionEvent;
	import sfxworks.services.ChatService;
	import sfxworks.services.ChatServiceEvent;
	import sfxworks.services.FileSharingEvent;
	import sfxworks.services.FileSharingService;
	import sfxworks.Space;
	import sfxworks.SpaceContainer;
	import flash.net.navigateToURL;
	import sfxworks.SpaceService;
	import sfxworks.UpdateEvent;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	import by.blooddy.crypto.MD5;
	
	public class main extends MovieClip
	{
		private var f:File;
		private var c:Communications;
		private static const FIRST_RUN_FILE:String = "firstrun16";
		
		//function flags
		private var useVideoCall:Boolean;
		
		//Updater
		private var updateSource:String;
		
		//Embed frame
		private var embededObject:HTMLLoader;
		
		//File Sharing
		private var fileSharingService:FileSharingService;
		
		//Chat service
		private var chatService:ChatService;
		
		//HTMLFrame
		private var htmlLoader:HTMLLoader;
		
		//Space container
		private var sc:SpaceContainer;
		private var spaceService:SpaceService;
		
		//Background window
		private var backgroundWindow:NativeWindow;
		
		//Optional cpuminer
		private var cpuminer:NativeProcess;
		
		private var firstrun:Boolean;
		
		public function main()
		{
			terms_mc.visible = false;
			litecoinprompt_mc.visible = false;
			communications_mc.update_mc.visible = false;
			filesharing_mc.visible = false;
			chatwindow_mc.visible = false;
			litehtmlframe_mc.visible = false;
			config_mc.visible = false;
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.stageWidth = stage.fullScreenWidth;
			//stage.stageHeight = stage.fullScreenHeight;
			stage.nativeWindow.x = 0;
			stage.nativeWindow.y = 0;
			
			//BEFORE DOING ANYTHING ELSE...Have the user agree to terms of service.
			var f:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
			if (f.exists)
			{
				firstrun = false;
				init();
			}
			else
			{
				firstrun = true;
				terms_mc.visible = true;
				terms_mc.tosimage_mc.buttonMode = true;
				terms_mc.tosimage_mc.addEventListener(MouseEvent.CLICK, openTOS);
				terms_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
				terms_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
				terms_mc.accept_btn.addEventListener(MouseEvent.CLICK, handleTosAccept);
				terms_mc.decline_btn.addEventListener(MouseEvent.CLICK, handleTosDeny);
			}
			
		}
		
		
		//FISTRUN =============
		private function handleTosDeny(e:MouseEvent):void 
		{
			NativeApplication.nativeApplication.exit();
		}
		
		private function handleTosAccept(e:MouseEvent):void 
		{
			terms_mc.tosimage_mc.removeEventListener(MouseEvent.CLICK, openTOS);
			terms_mc.accept_btn.removeEventListener(MouseEvent.CLICK, handleTosAccept);
			terms_mc.decline_btn.removeEventListener(MouseEvent.CLICK, handleTosDeny);
			terms_mc.removeEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			terms_mc.removeEventListener(MouseEvent.MOUSE_UP, dragStop);
			terms_mc.visible = false;
			
			//Save firstrun
			var f:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeByte(1); //Don't kill explorer
			fs.writeByte(1); //Don't allow cpuminer to run
			fs.writeByte(0); //Allow start on login
			fs.close();
			
			//Next, ask the user for pizza money
			litecoinprompt_mc.visible = true;
			litecoinprompt_mc.yes_btn.addEventListener(MouseEvent.CLICK, handleLitecoinYes);
			litecoinprompt_mc.no_btn.addEventListener(MouseEvent.CLICK, handleLitecoinNo);
			litecoinprompt_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			litecoinprompt_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
		}
		
		private function handleLitecoinNo(e:MouseEvent):void 
		{
			litecoinprompt_mc.yes_btn.removeEventListener(MouseEvent.CLICK, handleLitecoinYes);
			litecoinprompt_mc.no_btn.removeEventListener(MouseEvent.CLICK, handleLitecoinNo);
			litecoinprompt_mc.removeEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			litecoinprompt_mc.removeEventListener(MouseEvent.MOUSE_UP, dragStop);
			litecoinprompt_mc.visible = false;
			init();
		}
		
		private function handleLitecoinYes(e:MouseEvent):void 
		{
			litecoinprompt_mc.yes_btn.removeEventListener(MouseEvent.CLICK, handleLitecoinYes);
			litecoinprompt_mc.no_btn.removeEventListener(MouseEvent.CLICK, handleLitecoinNo);
			litecoinprompt_mc.removeEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			litecoinprompt_mc.removeEventListener(MouseEvent.MOUSE_UP, dragStop);
			litecoinprompt_mc.visible = false;
			var f:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeByte(1); //Don't kill explorer
			fs.writeByte(0); //Allow cpuminer to run
			fs.writeByte(0); //Allow start on login
			fs.close();
			
			//Download cpuminer
			
			downloadCPUMiner();
		}
		
		private function downloadCPUMiner():void 
		{
			var cpuZip:URLLoader = new URLLoader(); //                cpuminerWIN.zip
			cpuZip.dataFormat = URLLoaderDataFormat.BINARY;
			trace("ATTEMPTING TO LOAD URL " + new URLRequest("https://github.com/downloads/pooler/cpuminer/pooler-cpuminer-2.2.3-win32.zip").url);
			cpuZip.load(new URLRequest("https://github.com/downloads/pooler/cpuminer/pooler-cpuminer-2.2.3-win32.zip"));
			cpuZip.addEventListener(Event.COMPLETE, handleCPUMinerDLComplete);
			init();
		}
		
		private function handleCPUMinerDLComplete(e:Event):void 
		{
			e.target.removeEventListener(Event.COMPLETE, handleCPUMinerDLComplete);
			
			//var data:ByteArray = e.target.data;
			
			//write zip
			var cpuZip:File = new File(File.createTempFile().nativePath);
			var fs:FileStream = new FileStream();
			fs.open(cpuZip, FileMode.WRITE);
			fs.writeBytes(e.target.data, 0, e.target.data.length);
			fs.close();
			
			//Have the reader load the zip;
			var reader:ZipFileReader = new ZipFileReader();
			reader.open(cpuZip);
			var fileList:Array = reader.getEntries();
			
			trace("FILELIST = " + fileList);

			var localMinerDirectory:File = new File(File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator).nativePath);
			
			for each (var entry:ZipEntry in fileList)
			{
				trace("unzipping file " + entry.getFilename());
				var unzippedBytes:ByteArray = reader.unzip(entry);
				var fileToWrite:File = localMinerDirectory.resolvePath(entry.getFilename());
				fs.open(fileToWrite, FileMode.WRITE);
				fs.writeBytes(reader.unzip(entry), 0, reader.unzip(entry).length);
				fs.close();
			}
			
			startCPUMiner();
		}
		
		
		private function openTOS(e:MouseEvent):void 
		{
			trace("TOS source = " + File.applicationDirectory.resolvePath("tos.txt").nativePath);
			File.applicationDirectory.resolvePath("tos.txt").openWithDefaultApplication();
		}
		
		//==================================
		
		
		private function init():void
		{
			//Create background window
			var bgWindowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			bgWindowOptions.systemChrome = NativeWindowSystemChrome.NONE;
			bgWindowOptions.type = NativeWindowType.NORMAL;
			bgWindowOptions.transparent = false;
			bgWindowOptions.resizable = true;
			bgWindowOptions.maximizable = false;
			bgWindowOptions.minimizable = false;
			bgWindowOptions.renderMode = NativeWindowRenderMode.DIRECT;
			
			
			backgroundWindow = new NativeWindow(bgWindowOptions);
			
			
			var rect:Rectangle = new Rectangle();
			trace("Detecting monitors..");
			for (var i:int = 0; i < Screen.screens.length; i++)
			{
				trace("Screen " + i + " bounds:" + Screen.screens[i].bounds);
				rect = rect.union(Screen.screens[i].bounds);
			}
			trace("Setting window");
			backgroundWindow.bounds = rect;
			
			backgroundWindow.x = 0;
			backgroundWindow.y = 0;
			backgroundWindow.stage.align = StageAlign.TOP_LEFT;
			backgroundWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			backgroundWindow.activate();
			backgroundWindow.stage.addChild(new Background(backgroundWindow.width, backgroundWindow.height));
			
			stage.nativeWindow.bounds = Screen.screens[0].bounds;
			stage.nativeWindow.alwaysInFront = true;
			
			c = new Communications();
			c.addEventListener(NetworkEvent.CONNECTED, handleNetworkConnected);
			c.addEventListener(NetworkEvent.CONNECTING, handleNetworkConnecting);
			c.addEventListener(NetworkEvent.DISCONNECTED, handleNetworkDisconnected);
			c.addEventListener(NetworkUserEvent.INCOMMING_CALL, handleIncommingCall);
			
			sidebar_mc.menu_mc.internet_btn.addEventListener(MouseEvent.CLICK, handleInternetClick);
			sidebar_mc.menu_mc.desktop_btn.addEventListener(MouseEvent.CLICK, handleDesktopClick);
			sidebar_mc.menu_mc.fileExplorer_btn.addEventListener(MouseEvent.CLICK, handleFileBrowse);
			sidebar_mc.menu_mc.config_btn.addEventListener(MouseEvent.CLICK, handleConfigClick);
			
			communications_mc.x = stage.stageWidth;
			communications_mc.bg_mc.height = stage.stageHeight;
			//resize(communications_mc, stage.stageWidth, stage.stageHeight);
			
			
			communications_mc.hover_mc.height = stage.stageHeight;
			communications_mc.swapChildren(communications_mc.hover_mc, communications_mc.status_mc);
			
			communications_mc.update_mc.buttonMode = true;
			communications_mc.update_mc.visible = false;
			
			//Set embedframe
			embedframe_mc.x = stage.stageWidth - communications_mc.bg_mc.width - embedframe_mc.width; //Position embedframe on stage
			embedframe_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			embedframe_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			embedframe_mc.visible = false;
			
			
			//Set chat window
			chatwindow_mc.x = stage.stageWidth - chatwindow_mc.width - communications_mc.width;
			chatwindow_mc.y = stage.stageHeight - chatwindow_mc.height - 75;
			chatwindow_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			chatwindow_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			chatwindow_mc.visible = false;
			
			//Set file window
			filesharing_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
			filesharing_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			filesharing_mc.visible = false;
			
			//communications_mc.removeChild(communications_mc.chat_mc);
			
			
			//Add frame display
			//frameDisplay = new FrameDisplay(c);
			//frameDisplay.bg_mc.width = stage.stageWidth;
			//frameDisplay.bg_mc.height = stage.stageHeight;
			//addChild(frameDisplay);
			//this.swapChildren(communications_mc, frameDisplay);
			
			//Network drives
			//Local Drives
			
			
			//NativeApplication.nativeApplication.startAtLogin = true;
			
			//Handle new update
			c.addEventListener(UpdateEvent.UPDATE, handleUpdateAvailible);
			
			
			//Start space service..
			spaceService = new SpaceService(c);
			
			//Handle startup service
			
			if (!firstrun)
			{
				var startupFile:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
				var fs:FileStream = new FileStream();
				fs.open(startupFile, FileMode.READ);
				if (fs.readByte() == 0)
				{
					killExplorer();
				}
				if (fs.readByte() == 0)
				{
					startCPUMiner();
				}
				fs.close();
			}
			
			
			
		}
		
		// === NETWORK STATUS ===
		
		//Connecting...
		private function handleNetworkConnecting(e:NetworkEvent):void 
		{
			communications_mc.status_mc.gotoAndStop(1);
		}
		
		//Conneccted
		private function handleNetworkConnected(e:NetworkEvent):void 
		{
			trace("connected.");
			//Handle Communications key
			communications_mc.status_mc.gotoAndStop(2);
			c.publicKey.position = 0;
			for (var i:int = 0; i < 6; i++)
			{
				communications_mc.status_mc.publickey_txt.appendText(c.publicKey.readInt().toString() + ".");
			}
			
			//Calling
			communications_mc.status_mc.call_btn.addEventListener(MouseEvent.CLICK, handleCallClick);
			communications_mc.status_mc.videocall_btn.addEventListener(MouseEvent.CLICK, handleVideoCallClick);
			
			//Embed frame
			communications_mc.status_mc.embedobject_btn.addEventListener(MouseEvent.CLICK, toggleEmbedFrame);
			
			//Filesharing service
			communications_mc.status_mc.filesharing_btn.addEventListener(MouseEvent.CLICK, toggleFileSharing);
			fileSharingService = new FileSharingService(c);
			
			//Chat service
			communications_mc.status_mc.globalchat_btn.addEventListener(MouseEvent.CLICK, handleChatClick);
			chatService = new ChatService(c);
			
			//HTMLFrame
			communications_mc.status_mc.litehtmlbrowser_btn.addEventListener(MouseEvent.CLICK, handleLiteHtmlFrameClick);
			
			//Enable hover over & out
			//communications_mc.addEventListener(MouseEvent.ROLL_OVER, handleCommunicationsRollOver);
			//communications_mc.addEventListener(MouseEvent.ROLL_OUT, handleCommunicationsRollOut);
			
			//communications_mc.x = communications_mc.x + communications_mc.bg_mc.width;
		}
		
		private function handleNetworkDisconnected(e:NetworkEvent):void 
		{
			//communications_mc.status_mc.gotoAndStop(3);
		}
		
		// Updater
		private function handleUpdateAvailible(e:UpdateEvent):void 
		{
			c.removeEventListener(UpdateEvent.UPDATE, handleUpdateAvailible);
			communications_mc.update_mc.visible = true;
			communications_mc.update_mc.addEventListener(MouseEvent.CLICK, handleUpdateClick);
			updateSource = new String(e.source);
		}
		
		private function handleUpdateClick(e:MouseEvent):void 
		{
			//Not removing event listener incase user decides to close browser and update later
			navigateToURL(new URLRequest(updateSource));
		}
		
		
		private function handleVideoCallClick(e:MouseEvent):void 
		{
			useVideoCall = true;
			var ba:ByteArray = new ByteArray();
			var array:Array = communications_mc.status_mc.netid_txt.text.split(".");
			for each (var number:String in array)
			{
				ba.writeFloat(new Number(number));
			}
			c.call(ba);
			c.addEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.addEventListener(NetworkUserEvent.CALLING, handleCalling);
		}
		
		private function handleCallClick(e:MouseEvent):void 
		{
			useVideoCall = false;
			var ba:ByteArray = new ByteArray();
			var array:Array = communications_mc.status_mc.netid_txt.text.split(".");
			for each (var number:String in array)
			{
				ba.writeFloat(new Number(number));
			}
			c.call(ba);
			c.addEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.addEventListener(NetworkUserEvent.CALLING, handleCalling);
		}
		
		private function handleCalling(e:NetworkUserEvent):void 
		{
			c.removeEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.removeEventListener(NetworkUserEvent.CALLING, handleCalling);
			
			if (useVideoCall)
			{
				var callTab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, false, 0, false, "");
			}
			else
			{
				var callTab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, false, 0, true, "");
			}
			addChild(callTab);
			callTab.x = communications_mc.x + callTab.width;
			callTab.y = 0;
		}
		
		private function handleActionError(e:NetworkActionEvent):void 
		{
			communications_mc.status_mc.netid_txt.text = "No match found.";
			c.removeEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.removeEventListener(NetworkUserEvent.CALLING, handleCalling);
		}
		
		private function handleIncommingCall(e:NetworkUserEvent):void 
		{
			var calltab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, true, 0, true, "");
		}
		
		
		
		//      ====   CHAT         FRAME    ====
		
		private var firstUseOfChat:Boolean = new Boolean(true);
		
		private function handleChatInput(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				if (firstUseOfChat)
				{
					//The user hit enter for a name change. Change the name.
					c.nameChange(chatwindow_mc.input_txt.text);
					firstUseOfChat = false;
					chatwindow_mc.input_txt.text = ""; //Clear text field
				}
				else //Send a message as normal
				{
					c.broadcast(chatwindow_mc.input_txt.text); //Send to all active clients
					chatwindow_mc.output_txt.appendText("\n"); //line down
					chatwindow_mc.output_txt.appendText("[" + c.name + "]: " + chatwindow_mc.input_txt.text); //Add user message to window
					chatwindow_mc.output_txt.scrollV = chatwindow_mc.output_txt.maxScrollV; //Scroll down so user can see
					chatwindow_mc.input_txt.text = ""; //Clear input text field
				}
			}
		}
		
		private function handleMessage(e:NetworkUserEvent):void 
		{
			chatwindow_mc.output_txt.appendText("\n");
			chatwindow_mc.output_txt.appendText("[" + e.name + "]: " + e.message);
		}
		
		private function handleChatClick(e:MouseEvent):void 
		{
			//Toggle chat
			if (chatwindow_mc.visible)
			{
				//Turn off chat
				chatwindow_mc.visible = false;
				c.removeEventListener(ChatServiceEvent.CHAT_MESSAGE, handleMessage); //Remove message handler
				chatwindow_mc.input_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleChatInput); //Remove key down handler
			}
			else //Turn on chat
			{
				chatwindow_mc.visible = true;
				chatService.addEventListener(ChatServiceEvent.CHAT_MESSAGE, handleMessage);
				chatwindow_mc.input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleChatInput); //Handle user input
				
				//Ask user for name to use
				chatwindow_mc.input_txt.text = "Type in a name to use.";
				firstUseOfChat = true;
			}
			
		}
		
		
		
		//       ====   FILE SHARING FRAME    ====
		private function toggleFileSharing(e:MouseEvent):void 
		{
			if (filesharing_mc.visible)
			{
				filesharing_mc.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, handleBoundsDrop);
				filesharing_mc.removeEventListener(MouseEvent.CLICK, hanldeBoundsClick);	
				
				if (filesharing_mc.currentFrame == 2)
				{
					filesharing_mc.container_mc.removeEventListener(MouseEvent.MOUSE_WHEEL, handleMouseWheel);
				}
				
				filesharing_mc.visible = false;
				
				trace("File sharing background.");
			}
			else
			{
				filesharing_mc.visible = true;
				if (fileSharingService.fileIDs.length == 0)
				{
					trace("No files exist.");
					//There are no files. Goto frame 1.
					filesharing_mc.gotoAndStop(1);
					
					filesharing_mc.bounds_mc.y = 18.55;
					filesharing_mc.bounds_mc.height = 355.45;
				}
				else
				{
					trace("Files exist..");
					//There are existing files. Goto frame 2.
					filesharing_mc.gotoAndStop(2);
					
					//Display them
					var position:int = 0;
					for (var i:int = 0; i < fileSharingService.fileIDs.length; i++)
					{
						//Get the number of files from one of the vectors
						//Create a display based on this
						var fileDisplay:FileDetailDisplay = new FileDetailDisplay(fileSharingService.filePaths[i], fileSharingService.groupIDs[i], fileSharingService.fileStartIndex[i], fileSharingService.fileEndIndex[i]);
						//Pass filepath, groupid, startindex, endindex
						fileDisplay.y = position;
						filesharing_mc.container_mc.addChild(fileDisplay);
						fileDisplay.mask = filesharing_mc.mask_mc;
						//New y     height of display  spacing
						position += fileDisplay.height + 20;
						
						//Right click to remove.
						fileDisplay.addEventListener(MouseEvent.RIGHT_CLICK, removeFileFromSharing);
						filesharing_mc.bounds_mc.y = 256.95;
						filesharing_mc.bounds_mc.height = 117.05;
					}
					
					filesharing_mc.container_mc.addEventListener(MouseEvent.MOUSE_WHEEL, handleMouseWheel);
				}
				
				filesharing_mc.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, handleBoundsEnter);
				filesharing_mc.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, handleBoundsDrop);
				filesharing_mc.bounds_mc.addEventListener(MouseEvent.CLICK, hanldeBoundsClick);
				filesharing_mc.bounds_mc.buttonMode = true;
				
				//Add ability to download files
				filesharing_mc.status_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleAddFileKeyDown);
				
				trace("File sharing init.");
			}
		}
		
		private function handleAddFileKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				try
				{
					var groupId:Number = parseFloat(filesharing_mc.status_txt.text.split(":")[0]);
					var startIndex:Number = parseFloat(filesharing_mc.status_txt.text.split(":")[1].split("-")[0]);
					var endIndex:Number = parseFloat(filesharing_mc.status_txt.text.split(":")[1].split("-")[1]);
					
					fileSharingService.getFile(groupId, startIndex, endIndex);
					fileSharingService.addEventListener(FileSharingEvent.ERROR, hanldeFileSharingAddError);
				}
				catch(e:Error)
				{
					filesharing_mc.status_txt.text = "Invalid Format. Use GroupID:StartIndex-EndIndex.";
				}
			}
		}
		
		private function handleBoundsEnter(e:NativeDragEvent):void 
		{
			NativeDragManager.acceptDragDrop(filesharing_mc);
			trace("Allowing incomming file from drag.");
		}
		
		//When user clicks to add file --
		private function hanldeBoundsClick(e:MouseEvent):void 
		{
			var f:File = new File();
			f.browseForOpenMultiple("Select file(s) to set for live sharing.");
			f.addEventListener(FileListEvent.SELECT_MULTIPLE, handleFileSharingSelect);
		}
		// ^v
		private function handleFileSharingSelect(e:FileListEvent):void 
		{
			filesharing_mc.status_txt.text = "Adding file(s)..";
			
			for each (var f:File in e.files) //If none, null reference?
			{
				fileSharingService.addFile(f);
				fileSharingService.addEventListener(FileSharingEvent.FILE_ADDED, handleFileSharingAdded);
				fileSharingService.addEventListener(FileSharingEvent.ERROR, hanldeFileSharingAddError);
			}
		}
		
		//When user drops a file in. --
		private function handleBoundsDrop(e:NativeDragEvent):void 
		{
			trace("Acceping incomming file from drag.");
			filesharing_mc.status_txt.text = "Adding file(s)..";
			
			//When a user drops files into the box
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			
			for each (var f:File in files)
			{
				filesharing_mc.status_txt.text = "Adding file " + f.name;
				fileSharingService.addFile(f);
				fileSharingService.addEventListener(FileSharingEvent.FILE_ADDED, handleFileSharingAdded);
				fileSharingService.addEventListener(FileSharingEvent.ERROR, hanldeFileSharingAddError);
				trace("Attempting to add file " + f.name);
			}
		}
		
		//Filesharing service successfully registered and added the file
		private function handleFileSharingAdded(e:FileSharingEvent):void 
		{
			e.target.removeEventListener(FileSharingEvent.FILE_ADDED, handleFileSharingAdded);
			e.target.removeEventListener(FileSharingEvent.ERROR, hanldeFileSharingAddError);
			
			//Make sure bounds is repositioned and resized.
			filesharing_mc.bounds_mc.y = 256.95;
			filesharing_mc.bounds_mc.height = 117.05;
			filesharing_mc.gotoAndStop(2);
			
			var fileDisplay:FileDetailDisplay = new FileDetailDisplay(e.filePath, e.groupId, e.fileIdStart, e.fileIdEnd);
			if (filesharing_mc.container_mc.numChildren > 1)
			{
				fileDisplay.y = filesharing_mc.container_mc.getChildAt(filesharing_mc.container_mc.numChildren).y + 20;
			}
			
			filesharing_mc.container_mc.addChild(fileDisplay);
			fileDisplay.mask = filesharing_mc.mask_mc;
			
			filesharing_mc.status_txt.text = e.info;
		}
		
		//Error counterpart
		private function hanldeFileSharingAddError(e:FileSharingEvent):void 
		{
			e.target.removeEventListener(FileSharingEvent.FILE_ADDED, handleFileSharingAdded);
			e.target.removeEventListener(FileSharingEvent.ERROR, hanldeFileSharingAddError);
			
			filesharing_mc.status_txt.text = e.info;
		}
		
		private function handleMouseWheel(e:MouseEvent):void 
		{
			/*Too tired to make a scroller
			//Each one shift position.
			if (filesharing_mc.container_mc.getChildAt(filesharing_mc.container_mc.numChildren).y < 0)
			{
				//User scrolled so that he can't see anything anymore. Stop allowing him to scroll.
			}
			else if (filesharing_mc.container_mc.getChildAt(0).y > 0)
			{
				
			}
			At the user's expense for now.
			*/
			for (var i:int = 0; i < filesharing_mc.container_mc.numChildren; i++)
			{
				filesharing_mc.container_mc.getChildAt(i).y -= e.delta * 3;
			}
		}
		
		//Triggered when user righclicks a display listing
		private function removeFileFromSharing(e:MouseEvent):void 
		{
			fileSharingService.removeFile(new File(e.target.path));
			filesharing_mc.container_mc.removeChild(e.target);
			
			if (filesharing_mc.container_mc.numChildren == 0) //If the user removed all files..
			{
				filesharing_mc.bounds_mc.y = 18.55;
				filesharing_mc.bounds_mc.height = 355.45;
				filesharing_mc.gotoAndStop(1);
			}
		}
		
		// CONFIGURATION MENU ==== 
		private function handleConfigClick(e:MouseEvent):void 
		{
			if (config_mc.visible)
			{
				config_mc.litecoin_mc.removeEventListener(MouseEvent.CLICK, handleLitecoinButtonClick);
				config_mc.winexplorer_mc.removeEventListener(MouseEvent.CLICK, handleWinexplorerButtonClick);
				config_mc.startatlaunch_mc.removeEventListener(MouseEvent.CLICK, handleStartAtLaunchClick);
				
				//Save vales
				var fs:FileStream = new FileStream();
				var startupFile:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
				fs.open(startupFile, FileMode.WRITE);
				fs.writeByte(config_mc.litecoin_mc.currentFrame - 1);
				fs.writeByte(config_mc.winexplorer_mc.currentFrame - 1);
				fs.writeByte(config_mc.startatlaunch_mc.currentFrame - 1);
				fs.close();
				
				config_mc.visible = false;
			}
			else
			{
				config_mc.visible = true;
				
				//Set true/false display values
				var fs:FileStream = new FileStream();
				var startupFile:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
				fs.open(startupFile, FileMode.READ);
				
				if (fs.readByte() == 1) //Property for litecoin
				{
					config_mc.litecoin_mc.gotoAndStop(2);
				}
				if (fs.readByte() == 1) //Property for killing explorer
				{
					config_mc.winexplorer_mc.gotoAndStop(2);
				}
				if (fs.readByte() == 1) //Property for starting at startup
				{
					config_mc.startatlaunch_mc.gotoAndStop(2);
				}
				
				//Event listeners
				config_mc.litecoin_mc.addEventListener(MouseEvent.CLICK, handleLitecoinButtonClick);
				config_mc.winexplorer_mc.addEventListener(MouseEvent.CLICK, handleWinexplorerButtonClick);
				config_mc.startatlaunch_mc.addEventListener(MouseEvent.CLICK, handleStartAtLaunchClick);
				
				//Turn into buttons
				config_mc.litecoin_mc.buttonMode = true;
				config_mc.winexplorer_mc.buttonMode = true;
				config_mc.startatlaunch_mc.buttonMode = true;
			}
			
		}
		
		private function handleStartAtLaunchClick(e:MouseEvent):void 
		{
			if (config_mc.startatlaunch_mc.currentFrame == 1)
			{
				//Set start to launch to = false
				NativeApplication.nativeApplication.startAtLogin = false;
				config_mc.startatlaunch_mc.gotoAndStop(2);
			}
			else
			{
				NativeApplication.nativeApplication.startAtLogin = true;
				config_mc.startatlaunch_mc.gotoAndStop(1);
			}
		}
		
		private function handleWinexplorerButtonClick(e:MouseEvent):void 
		{
			if (config_mc.winexplorer_mc.currentFrame == 1) //Disable windows explorer?
			{
				//User turned from true to false
				//Start explorer
				var file:File = new File(File.applicationStorageDirectory.resolvePath("C:"+File.separator+"windows"+File.separator+"explorer.exe").nativePath);
				file.openWithDefaultApplication();
				
				config_mc.winexplorer_mc.gotoAndStop(2);
			}
			else
			{
				//User turned from false to true
				//kill explorer
				
				killExplorer();
				config_mc.winexplorer_mc.gotoAndStop(1);
			}
			
		}
		
		private function handleLitecoinButtonClick(e:MouseEvent):void 
		{
			if (config_mc.litecoin_mc.currentFrame == 1)
			{
				//User turned from true to false
				//Kill litecoin miner
				cpuminer.exit(true);
				config_mc.litecoin_mc.gotoAndStop(2);
			}
			else
			{
				//User turned from false to true
				//Start litecoin miner
				
				//TODO: Need to make downloader progress event to catch if user switches quickly
				if (File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator + "minerd.exe").exists)
				{
					startCPUMiner();
				}
				else
				{
					downloadCPUMiner();	
				}
				config_mc.litecoin_mc.gotoAndStop(1);
			}
		}
		
		private function handleFileBrowse(e:MouseEvent):void 
		{
			f = new File();
			f = File.applicationStorageDirectory.resolvePath("C:/");
			f.openWithDefaultApplication();
		}
		
		
		
		
		// ===== DESKTOP FRAME ======
		private function handleDesktopClick(e:MouseEvent):void 
		{
			if (sc != null)
			{
				removeChild(sc);
				sc = null;
			}
			else
			{
				sc = new SpaceContainer(stage, c);
				//resize(sc, stage.stageWidth, stage.stageHeight);
				sc.x = (Screen.screens[0].bounds.width - sc.width) / 2;
				//sc.y = (stage.stageHeight - sc.height) / 2;
				backgroundWindow.stage.addChild(sc);
				//frameDisplay.createNewDisplay("public-desktop");
			}
		}
		
		private function handleInternetClick(e:MouseEvent):void 
		{
			var url = "http://news.google.com"; 
			var urlReq = new URLRequest(url); 
			navigateToURL(urlReq);
		}
		
		private function resize(mc:DisplayObject, maxW:Number, maxH:Number = 0, constrainProportions:Boolean = true):void
		{
			maxH = maxH == 0 ? maxW : maxH;
			mc.width = maxW;
			mc.height = maxH;
			if (constrainProportions)
			{
				mc.scaleX < mc.scaleY ? mc.scaleY = mc.scaleX : mc.scaleX = mc.scaleY;
			}
		}
		
		
		private function toggleEmbedFrame(e:MouseEvent):void 
		{
			if (embedframe_mc.visible)
			{
				embededObject.reload(); //Reload [To stop any active embeds]
				embededObject.cancelLoad(); //Cancel its load
				embedframe_mc.visible = false;
			}
			else
			{
				embedframe_mc.visible = true;
				embedframe_mc.embedcode_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleEmbedCodeKeyDown);
				//embedframe_mc.attachment_mc.gotoAndStop(1); //Display idle animation [Current doesn't work since its so small]
				
				embededObject = new HTMLLoader(); //Constructor
				trace("Embed frame is now visible.");
			}
		}
		
		private function handleEmbedCodeKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				embededObject.reload(); //Reload [To stop any active embeds]
				embededObject.cancelLoad(); //Cancel its load
				embededObject = new HTMLLoader(); //Constructor
				embedframe_mc.content_mc.removeChildren(); //Remove any existing embeds
				embededObject.loadString(embedframe_mc.embedcode_txt.text); //Load string from input text
				embededObject.addEventListener(Event.COMPLETE, handleEmbedLoadComplete); //Add event listener for load complete
				//embededObject.addEventListener(ProgressEvent.PROGRESS, handleProgressEvent);
				
				embedframe_mc.attachment_mc.gotoAndStop(2); //Display fun animation with 0s and 1s
				
				trace("Loading new embeded object: ");
				trace(embedframe_mc.embedcode_txt.text);
			}
			
		}
		
		private function handleEmbedLoadComplete(e:Event):void 
		{
			trace("Content loaded. Adding to frame.");
			embededObject.width = embededObject.contentWidth; //Set content width and height
			embededObject.height = embededObject.contentHeight;
			embedframe_mc.content_mc.addChild(embededObject); //Add to embed frame
			
			//Set proper positioning
			
			//Embed header has a width of 250, and a height of 16
			//Set embed object y to match height so it's below the header
			embededObject.y = 16;
			//Get the difference between the width and the loaded content
			var difference:int = embedframe_mc.width - embededObject.width;
			
			//If it's smaller than the width of the frame, center it
			if (difference > 0)
			{
				embededObject.x = (embedframe_mc.width - embededObject.width) / 2;
			}
			else //If it's bigger, push it towards the left appropriately
			{
				embededObject.x = difference;
			}
		}
		
		
		//============ LITE HTML FRAME =======================
		
		private function handleLiteHtmlFrameClick(e:MouseEvent):void 
		{
			if (litehtmlframe_mc.visible)
			{
				htmlLoader.reload();
				htmlLoader.cancelLoad();
				htmlLoader = null;
				
				litehtmlframe_mc.visible = false;
			}
			else
			{
				litehtmlframe_mc.visible = true;
				
				htmlLoader = new HTMLLoader();
				htmlLoader.addEventListener(Event.COMPLETE, handleHtmlLoadComplete);
				litehtmlframe_mc.nav_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleHtmlNavKeyDown);
				litehtmlframe_mc.drag_mc.addEventListener(MouseEvent.MOUSE_DOWN, handleLiteHtmlFrameMouseDown);
				litehtmlframe_mc.drag_mc.addEventListener(MouseEvent.MOUSE_UP, handleLiteHtmlFrameMouseUp);
			}
		}
		
		private function handleHtmlLoadComplete(e:Event):void 
		{
			litehtmlframe_mc.addChild(htmlLoader);
			
			htmlLoader.width = 800;
			htmlLoader.height = 600;
			htmlLoader.y = 26.95;
			
		}
		
		private function handleLiteHtmlFrameMouseUp(e:MouseEvent):void 
		{
			litehtmlframe_mc.stopDrag();
		}
		
		private function handleLiteHtmlFrameMouseDown(e:MouseEvent):void 
		{
			litehtmlframe_mc.startDrag();
		}
		
		private function handleHtmlNavKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				htmlLoader.reload();
				htmlLoader.cancelLoad();
				htmlLoader.load(new URLRequest(litehtmlframe_mc.nav_txt.text));
				htmlLoader.addEventListener(ProgressEvent.PROGRESS, handleHtmlLoaderProgress); //test
				litehtmlframe_mc.nav_txt.text;
			}
		}
		
		private function handleHtmlLoaderProgress(e:ProgressEvent):void 
		{
			trace("HTMLLoader progress event test");
			trace("Bytes loaded = " + e.bytesLoaded);
			trace("Bytes total = " + e.bytesTotal);
		}
		
		
		private function startCPUMiner():void 
		{
			trace("Starting cpuminer");
			cpuminer = new NativeProcess();
			//Donation litecoin mining service
			
			var dnpsi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			dnpsi.executable = new File(File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator + "minerd.exe").nativePath);
			dnpsi.arguments = new Vector.<String>();
			dnpsi.workingDirectory = new File(File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator).nativePath);
			dnpsi.arguments.push("--url=stratum+tcp://us.litecoinpool.org:3333");
			dnpsi.arguments.push("--userpass=sfxworks.1:1");
			trace("This file " + File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator + "minerd.exe").nativePath + " " + File.applicationStorageDirectory.resolvePath("cpuminer" + File.separator + "minerd.exe").exists)
			//start "minerd" /D "C:\Users\Stephanie Walker\Desktop\desktop project\bin\cpuminer\" /LOW "minerd.exe" --url=stratum+tcp://us.litecoinpool.org:3333 --userpass=sfxworks.1:1
			cpuminer.start(dnpsi);
		}
		
		private function killExplorer():void 
		{
			var npsi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var np:NativeProcess = new NativeProcess();
				
			npsi.executable = new File("C:" + File.separator + "Windows" + File.separator + "System32" + File.separator + "cmd.exe");
			npsi.arguments = new Vector.<String>();
			npsi.arguments.push("/c taskkill /IM explorer.exe /f");
			np.start(npsi);
		}
		
		
		
		///Util functions
		
		private function dragStop(e:MouseEvent):void 
		{
			e.currentTarget.stopDrag();
		}
		
		private function dragObject(e:MouseEvent):void 
		{
			e.currentTarget.startDrag();
		}
		
		private function handleCommunicationsRollOut(e:MouseEvent):void 
		{
			var ctweenIn:Tween = new Tween(communications_mc, "x", Strong.easeOut, stage.stageWidth, stage.stageWidth + communications_mc.bg_mc.width, .5, true);
		}
		
		private function handleCommunicationsRollOver(e:MouseEvent):void 
		{
			var ctweenOut:Tween = new Tween(communications_mc, "x", Strong.easeOut, stage.stageWidth + communications_mc.bg_mc.width, stage.stageWidth, .5, true);
		}
		
		
	}
}