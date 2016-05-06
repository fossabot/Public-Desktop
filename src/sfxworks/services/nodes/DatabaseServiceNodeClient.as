package sfxworks.services.nodes 
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DatabaseServiceNodeClient extends EventDispatcher 
	{
		private var databaseName:String;
		private var queries:Vector.<String>; //Later on, organize queries so that an add would come before an update in the case where the updaate query reached this client instead of an add
		private var _active:Boolean;
		private var sqlConnection:SQLConnection;
		
		public function DatabaseServiceNodeClient(name:String, connection:SQLConnection) 
		{
			databaseName = new String(name);
			sqlConnection = connection;
		}
		
		public function query(query:SQLStatement):void
		{
			if (active)
			{
				var statement:SQLStatement = new SQLStatement();
				statement.sqlConnection = sqlConnection;
				statement.text = query;
				statement.execute();
			}
			else
			{
				//Store and flush on activation
				queries.push(args);
			}
		}
		
		public function get active():Boolean 
		{
			return _active;
		}
		
		public function set active(value:Boolean):void 
		{
			_active = value;
			if (value)
			{
				//Flush query
			}
		}
		
	}

}