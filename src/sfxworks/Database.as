package sfxworks 
{
	import flash.data.SQLConnection;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class Database 
	{
		public var name:String;
		public var communicationLine:CommunicationLine;
		public var localConnection:SQLConnection; //Path to db
		public var recordConnection:SQLConnection; //Path to db of records
		public var dbInfoFile:File;
		private var step:Number;
		public var loadedSteps:Number;
		public var stepsToLoad:Number;
		
		//
		
		
		public function Database() 
		{
			super();
		}
		
		public function get step():uint 
		{
			var fs:FileStream = new FileStream();
			fs.open(dbInfoFile, FileMode.WRITE);
			var returnValue:uint = fs.readFloat();
			fs.close();
			
			return returnValue;
		}
		
		public function set step(value:Number):void 
		{
			_step = value;
			var fs:FileStream = new FileStream();
			fs.open(dbInfoFile, FileMode.WRITE);
			fs.writeFloat(value);
			fs.close();
		}
		
	}

}