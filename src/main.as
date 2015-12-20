package 
{
	
	import com.fleo.irc.IRC;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
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
	import sfxworks.Space;
	import sfxworks.SpaceContainer;
	import flash.net.navigateToURL;
	import sfxworks.SpaceService;
	import sfxworks.UpdateEvent;
	
	public class main extends MovieClip
	{
		private var f:File;
		private var c:Communications;
		private var frameDisplay:FrameDisplay;
		
		//function flags
		private var useVideoCall:Boolean;
		
		//Updater
		private var updateSource:String;
		
		//Embed frame
		private var embededObject:HTMLLoader;
		
		//Space container
		private var sc:SpaceContainer;
		private var spaceService:SpaceService;
		
		public function main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.stageWidth = stage.fullScreenWidth;
			//stage.stageHeight = stage.fullScreenHeight;
			stage.nativeWindow.x = 0;
			stage.nativeWindow.y = 0;
			
			//Multimonitor support
			var rect:Rectangle = new Rectangle();
			trace("Detecting monitors..");
			for (var i:int = 0; i < Screen.screens.length; i++)
			{
				trace("Screen " + i + " bounds:" + Screen.screens[i].bounds);
				rect = rect.union(Screen.screens[i].bounds);
			}
			trace("Setting window");
			this.stage.nativeWindow.bounds = rect;
			
			
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
			
			communications_mc.update_mc.buttonMode = true;
			communications_mc.update_mc.visible = false;
			
			//Set embedframe
			embedframe_mc.x = stage.stageWidth - communications_mc.width - embedframe_mc.width; //Position embedframe on stage
			embedframe_mc.visible = false;
			
			
			//Set chat window
			chatwindow_mc.x = stage.stageWidth - chatwindow_mc.width - communications_mc.width;
			chatwindow_mc.y = stage.stageHeight - chatwindow_mc.height - 75;
			chatwindow_mc.visible = false;
			
			//communications_mc.removeChild(communications_mc.chat_mc);
			
			
			//Add frame display
			//frameDisplay = new FrameDisplay(c);
			//frameDisplay.bg_mc.width = stage.stageWidth;
			//frameDisplay.bg_mc.height = stage.stageHeight;
			//addChild(frameDisplay);
			//this.swapChildren(communications_mc, frameDisplay);
			
			
			//Network drives
			//Local Drives
			
			//Kill Explorer
			
			var npsi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var np:NativeProcess = new NativeProcess();
			
			npsi.executable = new File("C:" + File.separator + "Windows" + File.separator + "System32" + File.separator + "cmd.exe");
			npsi.arguments = new Vector.<String>();
			npsi.arguments.push("/c taskkill /IM explorer.exe /f");
			np.start(npsi);
			
			//NativeApplication.nativeApplication.startAtLogin = true;
			
			//Handle new update
			c.addEventListener(UpdateEvent.UPDATE, handleUpdateAvailible);
			
			
			//Start space service..
			spaceService = new SpaceService(c);
			
		}
		
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
		
		private function handleNetworkConnecting(e:NetworkEvent):void 
		{
			communications_mc.status_mc.gotoAndStop(1);
		}
		
		private function handleNetworkDisconnected(e:NetworkEvent):void 
		{
			communications_mc.status_mc.gotoAndStop(3);
		}
		
		private var firstUseOfChat:Boolean = new Boolean(true);
		
		private function handleChatClick(e:MouseEvent):void 
		{
			//Toggle chat
			if (chatwindow_mc.visible)
			{
				//Turn off chat
				chatwindow_mc.visible = false;
				c.removeEventListener(NetworkUserEvent.MESSAGE, handleMessage); //Remove message handler
				chatwindow_mc.input_txt.removeEventListener(KeyboardEvent.KEY_DOWN, handleChatInput); //Remove key down handler
			}
			else //Turn on chat
			{
				chatwindow_mc.visible = true;
				c.addEventListener(NetworkUserEvent.MESSAGE, handleMessage); //handle incomming messages
				chatwindow_mc.input_txt.addEventListener(KeyboardEvent.KEY_DOWN, handleChatInput); //Handle user input
				
				//Ask user for name to use
				chatwindow_mc.input_txt.text = "Type in a name to use.";
				firstUseOfChat = true;
			}
			
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
		
		private function handleMessage(e:NetworkUserEvent):void 
		{
			chatwindow_mc.output_txt.appendText("\n");
			chatwindow_mc.output_txt.appendText("[" + e.name + "]: " + e.message);
		}
		
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
			communications_mc.status_mc.globalchat_btn.addEventListener(MouseEvent.CLICK, handleChatClick);
			
			//Embed frame
			communications_mc.status_mc.embedobject_btn.addEventListener(MouseEvent.CLICK, toggleEmbedFrame);
		}
		
		private function handleConfigClick(e:MouseEvent):void 
		{
			//addChild(new ConfigMenu(c, bg_mc));
		}
		
		private function handleFileBrowse(e:MouseEvent):void 
		{
			f = new File();
			f = File.applicationStorageDirectory.resolvePath("C:/");
			f.openWithDefaultApplication();
		}
		
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
				addChild(sc);
				this.swapChildren(sc, sidebar_mc);
				this.swapChildren(sc, communications_mc);
				this.swapChildren(sc, embedframe_mc);
				this.swapChildren(sc, chatwindow_mc);
				//frameDisplay.createNewDisplay("public-desktop");
			}
		}
		
		private function handleInternetClick(e:MouseEvent):void 
		{
			var url = "http://sfxworks.net"; 
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
				embedframe_mc.attachment_mc.gotoAndStop(1); //Display idle animation [Current doesn't work since its so small]
				
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
		
		
	}
}