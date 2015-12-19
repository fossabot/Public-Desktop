package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkErrorEvent extends Event 
	{
		public static const ERROR:String = new String("networkError");
		
		public function NetworkErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new NetworkErrorEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NetworkErrorEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}