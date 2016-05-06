package sfxworks.services.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class DatabaseServiceEvent extends Event 
	{
		
		public function DatabaseServiceEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new DatabaseServiceEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DatabaseServiceEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}