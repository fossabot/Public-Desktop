package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NativeProcessEvent extends Event 
	{
		public static const OUTPUT_DATA:String = "outputdata";
		public static const ERROR_DATA:String = "errordata";
		
		private var _data:String;
		
		public function NativeProcessEvent(type:String, data:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_data = data;
		} 
		
		public override function clone():Event 
		{ 
			return new NativeProcessEvent(type, _data, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NativeProcessEvent", _data, "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}