package 
{
	
	import com.coltware.airxzip.ZipEntry;
	import com.coltware.airxzip.ZipFileReader;
	import fl.transitions.easing.*;
	import fl.transitions.Tween;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Screen;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.media.Microphone;
	import flash.net.FileFilter;
	import flash.net.navigateToURL;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import sfxworks.Communications;
	import sfxworks.LiteHtmlFrame;
	import sfxworks.NetworkActionEvent;
	import sfxworks.NetworkEvent;
	import sfxworks.NetworkUserEvent;
	import sfxworks.services.ChatService;
	import sfxworks.services.events.ChatServiceEvent;
	import sfxworks.services.DesktopService;
	import sfxworks.services.events.DesktopServiceEvent;
	import sfxworks.services.events.FileSharingEvent;
	import sfxworks.services.FileSharingService;
	import sfxworks.services.VoiceService;
	import sfxworks.services.events.VoiceServiceEvent;
	import sfxworks.Space;
	import sfxworks.SpaceContainer;
	import sfxworks.UpdateEvent;
	
	
	public class main extends MovieClip
	{
		private var f:File;
		private var c:Communications;
		private static const FIRST_RUN_FILE:String = "firstrun29";
		
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
		
		//Voice chat service
		private var voiceChatService:VoiceService;
		private var voiceGroupBars:Vector.<VoiceGroupBar>;
		private var voiceGroupNames:Vector.<String>;
		private var vt:Timer;
		
		//Desktop service
		private var desktopService:DesktopService;
		
		//HTMLFrame
		private var htmlWindow:NativeWindow;
		
		private var htmlLoader:HTMLLoader;
		
		//Space container
		private var sc:SpaceContainer;
		
		//Background window
		private var backgroundWindow:NativeWindow;
		
		//cpuminer
		private var cpuminer:NativeProcess;
		//Battle Encoder Shirase
		private var bes:NativeProcess;
		
		private var firstrun:Boolean;
		
		public function main()
		{
			communications_mc.update_mc.visible = false;
			filesharing_mc.visible = false;
			chatwindow_mc.visible = false;
			config_mc.visible = false;
			voiceChat_mc.visible = false;
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.stageWidth = stage.fullScreenWidth;
			//stage.stageHeight = stage.fullScreenHeight;
			stage.nativeWindow.x = 0;
			stage.nativeWindow.y = 0;
			
			//Save firstrun
			var f:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeByte(1); //Don't kill explorer
			fs.writeByte(0); //Allow start on login
			fs.close();
			init();
		}
		
		
		private function init():void
		{
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, handleApplicationExiting);
			
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
			
			communications_mc.x = stage.stageWidth + communications_mc.bg_mc.width - 1;
			communications_mc.bg_mc.height = stage.stageHeight;
			communications_mc.addEventListener(MouseEvent.ROLL_OVER, handleCommunicationsRollOver);
			communications_mc.addEventListener(MouseEvent.ROLL_OUT, handleCommunicationsRollOut);
			
			
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
			
			//Network drives
			//Local Drives
			
			//Handle new update
			c.addEventListener(UpdateEvent.UPDATE, handleUpdateAvailible);
			
			
			//Handle startup service

			var startupFile:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
			var fs:FileStream = new FileStream();
			fs.open(startupFile, FileMode.READ);
			if (fs.readByte() == 0)
			{
				trace("Killing explorer from init");
				killExplorer();
			}
			fs.close();
			
			//startBes();
			//startCPUMiner();
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
			trace("Communications successfully connected.");
			//Handle Communications key
			communications_mc.status_mc.gotoAndStop(2);
			for (var i:int = 0; i < 6; i++)
			{
				communications_mc.status_mc.publickey_txt.appendText(c.publicKey.readFloat().toString() + ".");
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
			
			//Desktop service
			desktopService = new DesktopService(c);
			
			//HTMLFrame
			communications_mc.status_mc.litehtmlbrowser_btn.addEventListener(MouseEvent.CLICK, handleLiteHtmlFrameClick);
			
			//Group voice chat
			communications_mc.status_mc.globalGroupVoice_mc.addEventListener(MouseEvent.CLICK, handleVoiceChatClick);
			
			//Desktop Service
			communications_mc.status_mc.spaceNavigator_btn.addEventListener(MouseEvent.CLICK, handlePublicDesktopClick);
			
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
			//c.call(ba);
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
			//c.call(ba);
			c.addEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.addEventListener(NetworkUserEvent.CALLING, handleCalling);
		}
		
		private function handleCalling(e:NetworkUserEvent):void 
		{
			c.removeEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.removeEventListener(NetworkUserEvent.CALLING, handleCalling);
			
			if (useVideoCall)
			{
				//var callTab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, false, 0, false, "");
			}
			else
			{
				//var callTab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, false, 0, true, "");
			}
			//addChild(callTab);
			//callTab.x = communications_mc.x + callTab.width;
			//callTab.y = 0;
		}
		
		private function handleActionError(e:NetworkActionEvent):void 
		{
			communications_mc.status_mc.netid_txt.text = "No match found.";
			c.removeEventListener(NetworkActionEvent.ERROR, handleActionError);
			c.removeEventListener(NetworkUserEvent.CALLING, handleCalling);
		}
		
		private function handleIncommingCall(e:NetworkUserEvent):void 
		{
			//var calltab:CallTab = new CallTab(c.getNetstreamFromFarID(e.name), c.myNetConnection, true, 0, true, "");
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
					//c.broadcast(chatwindow_mc.input_txt.text); //Send to all active clients
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
				config_mc.winexplorer_mc.removeEventListener(MouseEvent.CLICK, handleWinexplorerButtonClick);
				config_mc.startatlaunch_mc.removeEventListener(MouseEvent.CLICK, handleStartAtLaunchClick);
				
				//Save vales
				var fs:FileStream = new FileStream();
				var startupFile:File = new File(File.applicationStorageDirectory.resolvePath(FIRST_RUN_FILE).nativePath);
				fs.open(startupFile, FileMode.WRITE);
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
				
				if (fs.readByte() == 1) //Property for killing explorer
				{
					config_mc.winexplorer_mc.gotoAndStop(2);
				}
				if (fs.readByte() == 1) //Property for starting at startup
				{
					config_mc.startatlaunch_mc.gotoAndStop(2);
				}
				
				//Event listeners
				config_mc.winexplorer_mc.addEventListener(MouseEvent.CLICK, handleWinexplorerButtonClick);
				config_mc.startatlaunch_mc.addEventListener(MouseEvent.CLICK, handleStartAtLaunchClick);
				
				//Turn into buttons
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
		
		
		private function handleFileBrowse(e:MouseEvent):void 
		{
			f = new File();
			f = File.applicationStorageDirectory.resolvePath("C:/");
			f.openWithDefaultApplication();
		}
		
		
		// ===== DESKTOP FRAME ======
		private function handleDesktopClick(e:MouseEvent):void 
		{
			trace("Desktop click");
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
				
				//embedframe_mc.attachment_mc.gotoAndStop(2); //Display fun animation with 0s and 1s
				
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
		//TODO: Put in bg opaque window
		//Handle removal of html content properly. Reload / cancel doesnt work
		//Objets still exist
		
		private function handleLiteHtmlFrameClick(e:MouseEvent):void 
		{
			var nwi:NativeWindowInitOptions = new NativeWindowInitOptions();
			nwi.maximizable = false;
			nwi.minimizable = true;
			nwi.resizable = false;
			nwi.systemChrome = NativeWindowSystemChrome.STANDARD;
			nwi.transparent = false;
			nwi.type = NativeWindowType.NORMAL;
			
			htmlWindow = new NativeWindow(nwi);
			htmlWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			htmlWindow.stage.align = StageAlign.TOP_LEFT;
			htmlWindow.stage.color = 0x000000;
			htmlWindow.width = 800;
			htmlWindow.height = 600;
			htmlWindow.stage.addChild(new LiteHtmlFrame());
			htmlWindow.visible = true;
		}
		
		
		
		// ================= CPU MINER ==================
		private function startCPUMiner():void 
		{
			trace("Starting cpuminer");
			cpuminer = new NativeProcess();
			//Donation litecoin mining service
			
			var dnpsi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			dnpsi.executable = new File(File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator + "minerd.exe").nativePath);
			var args:Vector.<String> = new Vector.<String>();
			args.push("--url=stratum+tcp://us.litecoinpool.org:3333");
			args.push("--userpass=sfxworks.1:1");
			dnpsi.workingDirectory = new File(File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator).nativePath);
			dnpsi.arguments = args;
			
			//start "minerd" /D "C:\Users\Stephanie Walker\Desktop\desktop project\bin\cpuminer\" /LOW "minerd.exe" --url=stratum+tcp://us.litecoinpool.org:3333 --userpass=sfxworks.1:1
			//cpuminer.start(dnpsi);
			cpuminer.addEventListener(NativeProcessExitEvent.EXIT, handleNPExit);
			//cpuminer.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, handleCPUMinerStandardOutput);
			//cpuminer.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, handleCPUMinerStandardError);
		}
		
		private function handleNPExit(e:NativeProcessExitEvent):void 
		{
			//Naughty task killer
			cpuminer.removeEventListener(NativeProcessExitEvent.EXIT, handleNPExit);
			startCPUMiner();
		}
		
		// ================ Battle Encoder Shirase ================
		
		private function startBes():void 
		{
			trace("Starting BES");
			bes = new NativeProcess();
			//Donation litecoin mining service
			
			var dnpsi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			//dnpsi.executable = new File(File.applicationStorageDirectory.resolvePath("bes" + File.separator + "BES.exe").nativePath);
			//C:\Windows\System32
			var sysCommandPrompt:File = new File("C:\\Windows\\System32\\cmd.exe");
			trace("SYSTEM CMD PROMPT PATH = " + sysCommandPrompt.nativePath);
			dnpsi.executable = sysCommandPrompt;
			
			var args:Vector.<String> = new Vector.<String>();
			//trace("TARGET NATIVE PATH = " + File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator + "minerd.exe").nativePath);
			trace("TARGET LIMITER =" + File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator + "minerd.exe").nativePath);
			//args.push('CMD /k ""' + File.applicationStorageDirectory.resolvePath("bes" + File.separator + "bes.exe").nativePath + '" "' +"'"+  File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator + "minerd.exe").nativePath + "'"+ '" "85" "--minimize""');
			
			trace("args = " + args[0]);
			//args.push('start "bes" /D "' + File.applicationStorageDirectory.resolvePath("bes" + File.separator).nativePath + '" /NORMAL "BES.exe" ' + File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator).nativePath + '" 85 --minimize"');
			//args.push(File.applicationStorageDirectory.resolvePath("cpuminer" + Capabilities.supports64BitProcesses.toString() + File.separator + "minerd.exe").nativePath);
			//args.push("85");
			//args.push("--minimize");
			//dnpsi.workingDirectory = new File(File.applicationStorageDirectory.resolvePath("bes" + File.separator).nativePath);
			dnpsi.arguments = args;
			
			//start "minerd" /D "C:\Users\Stephanie Walker\Desktop\desktop project\bin\cpuminer\" /LOW "minerd.exe" --url=stratum+tcp://us.litecoinpool.org:3333 --userpass=sfxworks.1:1
			//bes.start(dnpsi);
			//bes.addEventListener(NativeProcessExitEvent.EXIT, handleNPExit); Close at your liesure 
			bes.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, handleBesStandardOutput);
			bes.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, handleBesStandardError);
		}
		
		
		private function handleBesStandardError(e:ProgressEvent):void 
		{
			trace("BES[error]: " + bes.standardError.readUTFBytes(bes.standardError.bytesAvailable));
		}
		
		private function handleBesStandardOutput(e:ProgressEvent):void 
		{
			trace("BES: " + bes.standardOutput.readUTFBytes(bes.standardOutput.bytesAvailable));
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
		
		
		//=============== Voice Chat ==================
		
		private function handleVoiceChatClick(e:MouseEvent):void
		{
			if (voiceChat_mc.visible)
			{
				voiceChat_mc.group_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleGroupTextKeyDown);
				voiceChat_mc.config_btn.removeEventListener(MouseEvent.CLICK, handleVoiceConfig);
				
				voiceChat_mc.config_mc.forward_btn.removeEventListener(MouseEvent.CLICK, handleVoiceMicFoward);
				voiceChat_mc.config_mc.back_btn.removeEventListener(MouseEvent.CLICK, handleVoiceMicBack);
				voiceChat_mc.config_mc.username_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleVoiceUsernameKeyDown);
				
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_CONNECTED, handleVoiceConnectedUser);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_DISCONNECTED, handleVoiceDisconnectedUser);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_AUDIO_ACTIVITY, handleUserAudioActivity);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_NAMECHANGE, handleVoiceNameChange);
				
				voiceChatService = null;
				
				vt.stop();
				
				voiceChat_mc.visible = false;
			}
			else
			{
				voiceChat_mc.visible = true;
				vt = new Timer(750);
				
				voiceChatService = new VoiceService(c);
				
				//Position on screen. Maybe make a new window. Yeah wtf make new windows why am I not doing that
				//Key detection and other issues.
				
				voiceChat_mc.group_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleGroupTextKeyDown);
				voiceChat_mc.config_btn.addEventListener(MouseEvent.CLICK, handleVoiceConfig);
				
				//Drag and drop
				voiceChat_mc.addEventListener(MouseEvent.MOUSE_DOWN, dragObject);
				voiceChat_mc.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			}
		}
		
		private function handleVoiceConfig(e:MouseEvent):void 
		{
			if (voiceChat_mc.config_mc.visible)
			{
				voiceChat_mc.config_mc.visible = false;
				
				voiceChat_mc.config_mc.forward_btn.removeEventListener(MouseEvent.CLICK, handleVoiceMicFoward);
				voiceChat_mc.config_mc.back_btn.removeEventListener(MouseEvent.CLICK, handleVoiceMicBack);
				voiceChat_mc.config_mc.username_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleVoiceUsernameKeyDown);
			}
			else
			{
				voiceChat_mc.config_mc.visible = true;
				voiceChat_mc.config_mc.username_txt.text = voiceChatService.username;
				voiceChat_mc.config_mc.microphone_txt.text = voiceChatService.microphone.name;
				
				voiceChat_mc.config_mc.forward_btn.addEventListener(MouseEvent.CLICK, handleVoiceMicFoward);
				voiceChat_mc.config_mc.back_btn.addEventListener(MouseEvent.CLICK, handleVoiceMicBack);
				voiceChat_mc.config_mc.username_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleVoiceUsernameKeyDown);
			}
		}
		
		private function handleVoiceUsernameKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				voiceChatService.username = voiceChat_mc.config_mc.username_txt.text;
				if (voiceGroupBars != null)
				{
					voiceGroupBars[0].username = voiceChatService.username;
				}
			}
		}
		
		//Cycle through aval microphones
		private function handleVoiceMicBack(e:MouseEvent):void 
		{
			trace("Current mic index = " + Microphone.names.indexOf(voiceChatService.microphone.name));
			
			//Don't do anything if it's at the beginning of the array.
			if (Microphone.names.indexOf(voiceChatService.microphone.name) != 0)
			{
				voiceChatService.microphone = Microphone.getEnhancedMicrophone(Microphone.names.indexOf(voiceChatService.microphone.name) - 1);
				voiceChat_mc.config_mc.microphone_txt.text = voiceChatService.microphone.name;
			}
		}
		
		private function handleVoiceMicFoward(e:MouseEvent):void 
		{
			trace("Current mic index = " + Microphone.names.indexOf(voiceChatService.microphone.name));
			trace("Number of avail mics = " + Microphone.names.length);
			
			if (Microphone.names.indexOf(voiceChatService.microphone.name) != Microphone.names.length - 1)
			{
				//Get microphones each time to detect new devices being added
				voiceChatService.microphone = Microphone.getEnhancedMicrophone(Microphone.names.indexOf(voiceChatService.microphone.name) + 1);
				voiceChat_mc.config_mc.microphone_txt.text = voiceChatService.microphone.name;
			}
		}
		
		//When a user types in a group and hits enter, connect to a group
		private function handleGroupTextKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				//Clear existing bars out if they're there.
				for each (var vgbi:VoiceGroupBar in voiceGroupBars)
				{
					voiceChat_mc.removeChild(vgbi);
				}
				
				//Reset index
				voiceGroupBars = new Vector.<VoiceGroupBar>();
				voiceGroupNames = new Vector.<String>();
				
				//Clear existing event listeners
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_CONNECTED, handleVoiceConnectedUser);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_DISCONNECTED, handleVoiceDisconnectedUser);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_AUDIO_ACTIVITY, handleUserAudioActivity);
				voiceChatService.removeEventListener(VoiceServiceEvent.USER_NAMECHANGE, handleVoiceNameChange);
				
				//Set vcs name
				voiceChatService.username = c.name;
				
				//Make a voice bar for self
				var vgb:VoiceGroupBar = new VoiceGroupBar(voiceChatService.username);
				voiceGroupBars.push(vgb);
				voiceGroupNames.push(voiceChatService.username); //No way to catch same usernames at this time :|
				voiceChat_mc.addChild(vgb);
				reorderVoiceBars();
				
				vt.removeEventListener(TimerEvent.TIMER, voiceUpdateOwnTimer);
				vt.addEventListener(TimerEvent.TIMER, voiceUpdateOwnTimer);
				vt.start();
				
				//Join a voice chat group.
				voiceChatService.connectToGroup(voiceChat_mc.group_txt.text);
				voiceChatService.addEventListener(VoiceServiceEvent.USER_CONNECTED, handleVoiceConnectedUser);
				voiceChatService.addEventListener(VoiceServiceEvent.USER_DISCONNECTED, handleVoiceDisconnectedUser);
				voiceChatService.addEventListener(VoiceServiceEvent.USER_AUDIO_ACTIVITY, handleUserAudioActivity);
				voiceChatService.addEventListener(VoiceServiceEvent.USER_NAMECHANGE, handleVoiceNameChange);
			}
		}
		
		//Update own bar based on netstream out byte level
		private function voiceUpdateOwnTimer(e:TimerEvent):void 
		{
			//trace("Audio byte count = " + voiceChatService.senderNode.info.audioBytesPerSecond);
			voiceGroupBars[0].updateByteLevel(voiceChatService.senderNode.info.audioBytesPerSecond);
		}
		
		//When another user changes their name in the room 
		private function handleVoiceNameChange(e:VoiceServiceEvent):void 
		{
			//Update Voice Bar
			voiceGroupBars[voiceGroupNames.indexOf(e.name)].name = e.newName;
			//Update Index
			voiceGroupNames[voiceGroupNames.indexOf(e.name)] = e.newName;
		}
		
		//When a user disconnects
		private function handleVoiceDisconnectedUser(e:VoiceServiceEvent):void 
		{
			//Remove from display list
			voiceChat_mc.removeChild(voiceGroupBars[voiceGroupNames.indexOf(e.name)]);
			
			//Remove from index
			voiceGroupBars.splice(voiceGroupNames.indexOf(e.name), 1);
			voiceGroupNames.splice(voiceGroupNames.indexOf(e.name), 1);
			
			reorderVoiceBars();
		}
		
		//When a user is talking, have the bar draw a display representation
		private function handleUserAudioActivity(e:VoiceServiceEvent):void 
		{
			//Handled inside object
			//Send new byte level to object for proper display
			voiceGroupBars[voiceGroupNames.indexOf(e.name)].updateByteLevel(e.bytes);
		}
		
		//When a user connects
		private function handleVoiceConnectedUser(e:VoiceServiceEvent):void 
		{
			trace("adding bar for " + e.name);
			//Construct
			var vgb:VoiceGroupBar = new VoiceGroupBar(e.name);
			
			//Add to index
			voiceGroupBars.push(vgb);
			voiceGroupNames.push(e.name);
			
			//Add to display list
			voiceChat_mc.addChild(vgb);
			
			//Reposition
			reorderVoiceBars();
		}
		
		//UTIL: Reorder voice bars 
		private function reorderVoiceBars():void
		{
			var position:int = 28.5;
			//Reorder all voice bars
			for each (var vgb:VoiceGroupBar in voiceGroupBars)
			{
				vgb.y = position;
				position += 35;
			}
		}
		
		//==== Desktop Service ====
		
		//publicDeskstop_mc
		//navigation_mc
		//bar_mc text_txt
		
		
		private var objectsLoaded:int;
		private var objectsToLoad:int;
		
		private var currentRequest:String;
		private var resourceParts:Vector.<String>;
		
		
		private function handlePublicDesktopClick(e:MouseEvent):void
		{
			if (publicDesktop_mc.visible)
			{
				desktopService.removeEventListener(DesktopServiceEvent.SPACE_OBJECT_RECIEVED, handleInitialRequest);
				desktopService.removeEventListener(DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED, handleInitialRequest);
				desktopService.removeEventListener(DesktopServiceEvent.PERMISSIONS_ERROR, handleDesktopPermissionsError);
				publicDesktop_mc.navigation_mc.loadspace_btn.removeEventListener(MouseEvent.CLICK, handleLoadSpaceClick);
				publicDesktop_mc.navigation_mc.editor_btn.removeEventListener(MouseEvent.CLICK, handlePDEditorClick);
				publicDesktop_mc.navigation_mc.text_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handlePublicDesktopKeyDown);
				publicDesktop_mc.visible = false;
			}
			else
			{
				publicDesktop_mc.visible = true;
				publicDesktop_mc.navigation_mc.text_txt.addEventListener(KeyboardEvent.KEY_DOWN, handlePublicDesktopKeyDown);
				publicDesktop_mc.navigation_mc.loadspace_btn.addEventListener(MouseEvent.CLICK, handleLoadSpaceClick);
				publicDesktop_mc.navigation_mc.editor_btn.addEventListener(MouseEvent.CLICK, handlePDEditorClick);
				
			}
		}
		
		private function handlePDEditorClick(e:MouseEvent):void 
		{
			loadSpace("", true);
		}
		
		private function handleLoadSpaceClick(e:MouseEvent):void 
		{
			var f:File = new File(File.applicationStorageDirectory.resolvePath("spaces" + File.separator).nativePath);
			f.browseForOpen("Select a space to load.", [new FileFilter("Space Files", "*.space")]);
			f.addEventListener(Event.SELECT, handleSpaceSelection);
		}
		
		private function handleSpaceSelection(e:Event):void 
		{
			loadSpace(e.target.nativePath);
		}
		
		private function loadSpace(space:String, editMode:Boolean=false):void
		{
			var spaceWindow:NativeWindow;
			var spaceWindowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			
			spaceWindowOptions.owner = backgroundWindow;
			spaceWindowOptions.resizable = false;
			spaceWindowOptions.systemChrome = NativeWindowSystemChrome.NONE;
			spaceWindowOptions.type = NativeWindowType.NORMAL;
			spaceWindowOptions.transparent = false;
			spaceWindowOptions.maximizable = true;
			spaceWindowOptions.minimizable = true;
			spaceWindowOptions.renderMode = NativeWindowRenderMode.DIRECT;
			
			spaceWindow = new NativeWindow(spaceWindowOptions);
			spaceWindow.bounds = Screen.mainScreen.bounds;
			spaceWindow.x = 0;
			spaceWindow.y = 0;
			spaceWindow.stage.align = StageAlign.TOP_LEFT;
			spaceWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			spaceWindow.activate();
			spaceWindow.stage.addChild(new Space(spaceWindow.stage, space, editMode, false));
		}
		
		private function handlePublicDesktopKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 13)
			{
				navigateToDesktop(e.target.text);
			}
		}
		
		private function updateLoadingBar(current:int, max:int):void
		{
			//Only when load is complete
			//Are we to give the space object to the constructor
			//Tell it to use the md5 to load the file instead of the source
			publicDesktop_mc.navigation_mc.bar_mc.width = publicDesktop_mc.navigation_mc.width * (current / max);
			
			if (currentRequest.search(/^[a-f0-9]{32}$/) > -1)
			{
				publicDesktop_mc.navigation_mc.text_txt.text = "md5!:" + currentRequest;
			}
			else if (currentRequest.search(/^[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.$/) > -1)
			{
				publicDesktop_mc.navigation_mc.text_txt.text = "rmh!:" + currentRequest;
			}
			
			publicDesktop_mc.navigation_mc.text_txt.appendText(" [" + current.toString() + "/" + max.toString() + "]");
		}
		
		private function navigateToDesktop(address:String):void
		{
			//type!text
			//Direct file request 
			//md5!:sa9fyds78h45j10uhnmsdf9hu
			
			//Host request
			//rmh!:123892095.477682095.14518920235.5421892095.112892095.541892095
			
			desktopService.removeEventListener(DesktopServiceEvent.SPACE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.removeEventListener(DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.removeEventListener(DesktopServiceEvent.PERMISSIONS_ERROR, handleDesktopPermissionsError);
			
			currentRequest = new String(address);
			resourceParts = new Vector.<String>();
			
			//Request both as a space and a resource.
			//Only one will respond.
			if (address.search(/^[a-f0-9]{32}$/) > -1)
			{
				//It's an md5 address
				desktopService.getFile(address, DesktopService.SPACE_FILE_EXTENSION);
				desktopService.getFile(address, DesktopService.RESOURCE_FILE_EXTENSION);
			}
			
			else if (address.search(/^[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.[0-9]{1,17}\.$/) > -1)
			{
				//It's a public key.
				desktopService.getFile(address, DesktopService.SPACE_FILE_EXTENSION);
				//Since it's a public key, public key addressed default to a space file. So There's no need to request for both a space directory
				//and a resource directory in hopes of retrieving something.
			}
			
			else
			{
				publicDesktop_mc.navigation_mc.text_txt.text = "invalid request. use a md5 or a public key from a peer."
				return;
			}
			
			desktopService.addEventListener(DesktopServiceEvent.SPACE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.addEventListener(DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.addEventListener(DesktopServiceEvent.PERMISSIONS_ERROR, handleDesktopPermissionsError);
			
			objectsLoaded = new int();
			objectsToLoad = new int(1);
		}
		
		private function handleDesktopPermissionsError(e:DesktopServiceEvent):void 
		{
			desktopService.removeEventListener(DesktopServiceEvent.SPACE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.removeEventListener(DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED, handleInitialRequest);
			desktopService.removeEventListener(DesktopServiceEvent.PERMISSIONS_ERROR, handleDesktopPermissionsError);
			
			publicDesktop_mc.navigation_mc.text_txt.text = "The user owning " + currentRequest + " does not allow you to navigate here.";
		}
		
		private function handleInitialRequest(e:DesktopServiceEvent):void 
		{
			objectsLoaded++;
			
			if (e.type == DesktopServiceEvent.SPACE_OBJECT_RECIEVED)
			{
				//Check to see if it's the space file being requested
				if (currentRequest == e.file.name)
				{
					parseSpaceFile(e.file);
					updateLoadingBar(objectsLoaded, objectsToLoad);
				}
			}
			else if (e.type == DesktopServiceEvent.RESOURCE_OBJECT_RECIEVED)
			{
				//Check to see if it's a loaded resource for the current space file being requested
				if (resourceParts.indexOf(e.file.name) > -1 || e.file.name == currentRequest)
				{
					updateLoadingBar(objectsLoaded, objectsToLoad);
				}
			}
			
			if (objectsLoaded == objectsToLoad)
			{
				//All objects loaded.
				
				if (e.file.name == currentRequest)
				{
					//It's an individual file request. Not part of a space fetch.
					//Like an image or a video.
					if (e.extension == "GIF")
					{
						//use gif player
					}
					else if (e.extension == "MP4" || e.extension == "M4V" || e.extension == "F4V" || e.extension == "3GPP" || e.extension == "FLV")
					{
						//use video player
					}
					else if (e.extension == "SWF" || e.extension == "JPG" || e.extension == "JPEG" || e.extension == "PNG" || e.extension == "BMP")
					{
						//use loader (its an swf or an image.)
					}
					else
					{
						//wtf is this?
						publicDesktop_mc.navigation_mc.text_txt.text = "Unsupported file type [" + e.extension + "]@: " + e.file.nativePath;
					}
				}
				else
				{
					//Send over to space object to create a new space.
					addChild(new Space(stage, e.file.nativePath, false, true));
				}
			}
		}
		
		private function parseSpaceFile(file:File):Object
		{
			var results:Object = new Object();
			
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
				results.numberOfObjects = fs.readDouble();
				results.permissions = fs.readUTF();
				for (var i:int = 0; i < results.numberOfObjects; i++)
				{
					//Skip source and actions, and data
					fs.readUTF();
					fs.readUTF();
					fs.position += 8 * 11;
					
					//Update the number of objects to load
					objectsToLoad += fs.readDouble();
					
					//Tell desktopservice to get the file
					var md5Resource:String = fs.readUTF();
					desktopService.getFile(md5Resource, DesktopService.RESOURCE_FILE_EXTENSION);
					resourceParts.push(md5Resource);
				}
				fs.close();
			return results;
		}
		
		
		private function handleApplicationExiting(e:Event):void 
		{
			/*
			cpuminer.removeEventListener(NativeProcessExitEvent.EXIT, handleNPExit);
			cpuminer.exit(true);
			bes.exit(true);
			*/
			var file:File = new File(File.applicationStorageDirectory.resolvePath("C:"+File.separator+"windows"+File.separator+"explorer.exe").nativePath);
				file.openWithDefaultApplication();
			trace("exiting..");
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
			var ctweenIn:Tween = new Tween(communications_mc, "x", Strong.easeOut, stage.stageWidth, stage.stageWidth + communications_mc.bg_mc.width - 1, .5, true);
		}
		
		private function handleCommunicationsRollOver(e:MouseEvent):void 
		{
			var ctweenOut:Tween = new Tween(communications_mc, "x", Strong.easeOut, stage.stageWidth + communications_mc.bg_mc.width - 1, stage.stageWidth, .5, true);
		}
		
		
	}
}