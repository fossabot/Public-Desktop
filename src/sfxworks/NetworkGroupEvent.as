package sfxworks 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkGroupEvent extends Event 
	{
		public static const CONNECTION_SUCCESSFUL:String = "ngconnected";
		public static const CONNECTION_FAILED:String = "ngfailed";
		public static const POST:String = "ngpost";
		public static const OBJECT_RECIEVED:String = "ngobjectRecieved";
		public static const OBJECT_REQUEST:String = "ngobjectRequest";
		public static const USER_DATA:String = "ngeuserdata";
		public static const PUBLISH_START:String = "ngepublishstart";
		public static const PUBLISH_END:String = "ngepublishend";
		
		private var _groupName:String;
		private var _groupObject:Object; //info.message or shared group object
		private var _groupObjectNumber:Number;
		
		public function NetworkGroupEvent(type:String, groupName:String, groupObject:Object = null, groupObjectNumber:Number = -1, bubbles:Boolean = false, cancelable:Boolean = false) 
		{ 
			super(type, bubbles, cancelable);
			_groupName = groupName;
			_groupObject = groupObject;
			_groupObjectNumber = groupObjectNumber;
		} 
		
		public override function clone():Event 
		{ 
			return new NetworkGroupEvent(type, _groupName, _groupObject, _groupObjectNumber, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("NetworkGroupEvent", "type", "groupName", "groupObject", "groupObjectNumber", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get groupObject():Object 
		{
			return _groupObject;
		}
		
		public function get groupObjectNumber():Number 
		{
			return _groupObjectNumber;
		}
		
		public function get groupName():String 
		{
			return _groupName;
		}
		
	}
	
}