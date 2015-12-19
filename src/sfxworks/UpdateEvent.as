package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class UpdateEvent extends Event 
	{
		private var _version:Number;
		private var _source:String;
		
		public static const UPDATE:String = new String("update");
		
		public function UpdateEvent(type:String, version:Number, source:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_version = version;
			_source = source;
		} 
		
		public override function clone():Event 
		{ 
			return new UpdateEvent(type, _version, _source, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("UpdateEvent", "type", "version", "source", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get version():Number 
		{
			return _version;
		}
		
		public function get source():String 
		{
			return _source;
		}
		
	}
	
}