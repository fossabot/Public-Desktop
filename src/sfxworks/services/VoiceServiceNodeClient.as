package sfxworks.services 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class VoiceServiceNodeClient extends EventDispatcher
	{
		
		public function VoiceServiceNodeClient() 
		{
			
		}
		
		public function data(str:String):void
		{
			dispatchEvent(new NodeEvent(NodeEvent.INCOMMING_DATA, str));
		}
		
	}

}