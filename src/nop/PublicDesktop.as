package nop 
{
	import flash.display.MovieClip;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class PublicDesktop extends MovieClip 
	{
		private var nc:NetConnection;
		private var nssend:NetStream;
		private var nsrecieve:NetStream;
		
		private var myDesktop:MovieClip;
		
		public function PublicDesktop() 
		{
			nc = new NetConnection();
			nc.connect("rtmfp://p2p.rtmfp.net", "e0708320bf4003e01aa0bcd1-ee3e9ec0c03a");
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			
			
		}
		
		
		private function netStatusHandler(e:NetStatusEvent):void
		{ 
			switch(e.info.code)
			{ 
				case "NetConnection.Connect.Success":
					ns = new NetStream(nc, null);
					
					//The connection attempt succeeded. 
					break; 
				case "NetConnection.Connect.Closed":
					//The connection was closed successfully. 
					break; 
				case "NetConnection.Connect.Failed":
					//The connection attempt failed.
					break;  
			}
		}
		
		private function connect(nearID:String)
		{
			nsrecieve = new NetStream(nc, nearID);
			nssend = new NetStream(nc, nearID);
			
			nssend.send("requestDesktop"); //Send request to client for desktop on connecting
		}
		
		public function requestDesktop():void //Function to call if another user connects and requests desktop
		{
			nssend.send("recieveDesktop", myDesktop); //Send over mydesktop to the requesting client (fix later as far as request spamming and security goes)
		}
		
		public function recieveDesktop(desktop:MovieClip):void
		{
			this.addChild(desktop);
		}
	}

}