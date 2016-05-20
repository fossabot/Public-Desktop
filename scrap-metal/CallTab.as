package 
{
	import com.maclema.mysql.ErrorHandler;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class CallTab extends MovieClip 
	{
		private var t:Timer = new Timer(1000, 10);
		
		private var myNS:NetStream;
		private var theirNS:NetStream;
		
		private var microphone:Microphone;
		private var cameraID:String;
		
		
		var v:Video;
		
		private var g:Graphics;
		private static const PLOT_HEIGHT:int = 200;
		private static const CHANNEL_LENGTH:int = 256;
		
		private var sc:SoundChannel;
		
		private var ao:Boolean;
		
		public function CallTab(theirNetstream:NetStream, myNetStream:NetStream, ring:Boolean, micID:int, audioOnly:Boolean, cameraID:String) 
		{
			stop();
			ao = audioOnly;
			
			myNS = myNetStream;
			theirNS = theirNetstream;
			
			microphone = new Microphone();
			microphone = Microphone.getEnhancedMicrophone(micID);
			
			if (ring)
			{
				accept_btn.addEventListener(MouseEvent.CLICK, handleAccept);
				deny_btn.addEventListener(MouseEvent.CLICK, handleDeny);
				
				t.addEventListener(TimerEvent.TIMER_COMPLETE, handleTimerComplete);
				t.start();
				
				theirNS.play("audio");
				
				if (!audioOnly)
				{
					v = new Video(199, 150);
					v.attachNetStream(theirNS);
					theirNS.play("video");
					v.x = 150;
				}
				
				sc = new SoundChannel();
			}
			else
			{
				initCall();
			}
			
		}
		
		private function handleAccept(e:MouseEvent):void 
		{
			accept_btn.removeEventListener(MouseEvent.CLICK, handleAccept);
			deny_btn.removeEventListener(MouseEvent.CLICK, handleDeny);
			initCall();
		}
		
		private function initCall():void
		{
			play();
			if (ao) //Audio
			{
				myNS.attachAudio(microphone);
				myNS.publish("audio");
			}
			else //Video
			{
				var camera:Camera;
				camera = new Camera();
				camera = Camera.getCamera(cameraID);
				myNS.attachCamera(camera);
				myNS.publish("video");
				
				addChild(v);
			}
			
			minimize_btn.addEventListener(MouseEvent.CLICK, minimize);
			mute_btn.addEventListener(MouseEvent.CLICK, mute);
			close_btn.addEventListener(MouseEvent.CLICK, close);
		}
		
		private function close(e:MouseEvent):void 
		{
			this.parent.removeChild(this);
		}
		
		private function mute(e:MouseEvent):void 
		{
			mute_btn.removeEventListener(MouseEvent.CLICK, mute);
			unmute_btn.addEventListener(MouseEvent.CLICK, unmute);
			unmute_btn.visible = true;
			
			theirNS.togglePause();
		}
		
		private function unmute(e:MouseEvent):void 
		{
			mute_btn.addEventListener(MouseEvent.CLICK, mute);
			unmute_btn.removeEventListener(MouseEvent.CLICK, unmute);
			unmute_btn.visible = false;
			theirNS.togglePause();
		}
		
		private function minimize(e:MouseEvent):void 
		{
			minimize_btn.removeEventListener(MouseEvent.CLICK, minimize);
			maximize_btn.addEventListener(MouseEvent.CLICK, maximize); //Doesnt exist yet on frame does it..
			
			v.visible = false;
			theirNS.togglePause(); //Uknown if it effects audio.
			play();
		}
		
		private function maximize(e:MouseEvent):void 
		{
			gotoAndStop(25);
		}
		
		private function handleDeny(e:MouseEvent):void 
		{
			//Self Destruct
			this.parent.removeChild(this);
		}
		
		private function handleTimerComplete(e:TimerEvent):void 
		{
			//Self Destruct
			this.parent.removeChild(this);
		}
		
	}

}