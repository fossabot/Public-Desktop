package sfxworks.services.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NodeEvent extends Event 
	{
		public static const INCOMMING_DATA:String = "neIncommingData";
		private var _data:Object;
		
		public function NodeEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_data = data;
		} 
		
		public override function clone():Event 
		{ 
			return new NodeEvent(type, _data, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NodeEvent", "type", "data", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get data():Object 
		{
			return _data;
		}
		
	}
	
}