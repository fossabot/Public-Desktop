package sfxworks.services.nodes 
{
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
		private var active:Boolean;
		
		public function DatabaseServiceNodeClient(name:String) 
		{
			databaseName = new String(name);
		}
		
		public function activate():void
		{
			active = true;
			//Fluch queries to db.
			
		}
		
		public function query(args:String):void
		{
			if (active)
			{
				//Flush query
			}
			else
			{
				//Store and flush on activation
				queries.push(args);
			}
		}
		
		
		
		
		
	}

}