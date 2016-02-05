package sfxworks.services 
{
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
		
		public function vsncdata(obj:Object):void
		{
			dispatchEvent(new NodeEvent(NodeEvent.INCOMMING_DATA, obj));
		}
		
	}

}