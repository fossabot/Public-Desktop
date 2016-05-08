package sfxworks.services.nodes 
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.registerClassAlias;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class DatabaseServiceNodeClient extends EventDispatcher 
	{
		private var databaseName:String;
		private var queries:Vector.<SQLStatement>;
		private var _active:Boolean;
		private var sqlConnection:SQLConnection;
		
		public function DatabaseServiceNodeClient(name:String, connection:SQLConnection) 
		{
			databaseName = new String(name);
			sqlConnection = connection;
			registerClassAlias("flash.data.SqlStatement", SQLStatement);
			registerClassAlias("flash.events.EventDispatcher", EventDispatcher);
		}
		
		public function query(query:SQLStatement):void
		{
			if (active)
			{
				var statement:SQLStatement = new SQLStatement();
				statement.sqlConnection = sqlConnection;
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
				for each (var query:SQLStatement in queries)
				{
					query.sqlConnection = sqlConnection;
					query.execute();
				}
				queries = new Vector.<SQLStatement>();
			}
		}
		
	}

}