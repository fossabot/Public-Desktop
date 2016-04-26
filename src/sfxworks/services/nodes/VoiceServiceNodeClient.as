package sfxworks.services.nodes 
{
	import flash.events.EventDispatcher;
	import sfxworks.services.events.NodeEvent;
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