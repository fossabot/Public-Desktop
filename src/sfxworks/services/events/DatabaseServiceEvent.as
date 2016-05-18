package sfxworks.services.events 
{
	import flash.data.SQLResult;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class DatabaseServiceEvent extends Event 
	{
		public static const RESULT_DATA:String = "dbserviceResultData";
		public static const CONNECTED:String = "dbserviceConnected";
		
		private var _dbName:String;
		private var _result:SQLResult;
		
		public function DatabaseServiceEvent(type:String, dbName:String, result:SQLResult=null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			_result = result;
			_dbName = dbName;
			
			super(type, bubbles, cancelable);
		} 
		
		public override function clone():Event 
		{ 
			return new DatabaseServiceEvent(type, _dbName, _result, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DatabaseServiceEvent", "type", "dbName", "result", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get dbName():String 
		{
			return _dbName;
		}
		
		public function get result():SQLResult 
		{
			return _result;
		}
		
	}
	
}