package 
{
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetStream;
	import flash.sampler.NewObjectSample;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class MainTest extends MovieClip 
	{
		
		private var mycam:Camera;
		private var mymic:Microphone;
		
		private var nc:NetConnection;
		private var myNS:NetStream;
		private var theirNS:NetStream;
		
		private var gspec:GroupSpecifier;
		private var switchh:Boolean = new Boolean(false);
		private var init:Boolean = new Boolean(true);
		
		private var t:Timer = new Timer(1000);
		
		public function MainTest() 
		{
			mycam = Camera.getCamera();
			mymic =  Microphone.getMicrophone();
			mymic.setSilenceLevel(50);
			
			var myvideo:Video = new Video(200, 200);
			myvideo.attachCamera(mycam);
			camera1_mc.addChild(myvideo);
			
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, handleNetStatus);
			nc.connect("rtmfp://p2p.rtmfp.net/" + "e0708320bf4003e01aa0bcd1-ee3e9ec0c03a");
			
			camera2_mc.addEventListener(MouseEvent.CLICK, handleCamera2Click);
			camera1_mc.addEventListener(MouseEvent.CLICK, handleCamera1);
			
			t.addEventListener(TimerEvent.TIMER, handleTimerEvent);
		}
		
		private function handleTimerEvent(e:TimerEvent):void 
		{
			trace(myNS.info.toString());
		}
		
		private function handleCamera1(e:MouseEvent):void 
		{
			myNS = new NetStream(nc, gspec.groupspecWithoutAuthorizations());
		}
		
		private function handleCamera2Click(e:MouseEvent):void 
		{
			switchh = true;
			theirNS = new NetStream(nc, gspec.groupspecWithoutAuthorizations());
		}
		
		private function handleNetStatus(e:NetStatusEvent):void 
		{
			log_txt.appendText("\n");
			log_txt.appendText(e.info.code);
			trace(e.info);
			
			switch(e.info.code)
			{
				case "NetConnection.Connect.Success":
					gspec = new GroupSpecifier("groupmain");
					gspec.objectReplicationEnabled = true;
					gspec.multicastEnabled = true;
					gspec.serverChannelEnabled = true;
					var group:NetGroup = new NetGroup(nc, gspec.groupspecWithoutAuthorizations());
					break;
				case "NetGroup.Connect.Success":
					
					break;
				case "NetStream.Connect.Success":
					trace("Connected to " + e.info.stream);
					if (switchh == false)
					{
						myNS.client = new MainTestClient();
						myNS.attachCamera(mycam);
						myNS.attachAudio(mymic);
						myNS.publish(stream1_txt.text);
						myNS.send("initTest", "Hello from " + nc.nearID + ".");
						t.start();
					}
					else
					{
						theirNS.client = new MainTestClient();
						switchh = false;
						var v:Video = new Video(200, 200);
						theirNS.play(stream_txt.text);
						
						v.attachNetStream(theirNS);
						camera2_mc.addChild(v);
					}
					break;
				case "NetGroup.MulticastStream.PublishNotify":
					log_txt.appendText("Publisher group = " + e.info.group);
					log_txt.appendText("Stream name = " + e.info.name);
					break;
				case "NetGroup.MulticastStream.UnpublishNotify":
					log_txt.appendText("Publisher group = " + e.info.group);
					log_txt.appendText("Stream name = " + e.info.name);
					break;
			}
		}
		
		private function handleGroupNetStatus(e:NetStatusEvent):void 
		{
			log_txt.appendText(e.info.code);
			log_txt.appendText("\n");
		}
		
	}
	

}