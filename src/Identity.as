package 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Samuel Walker
	 */
	public class Identity 
	{
		private var _name:String; //What they want to go by
		private var _nearID:String;
		public var key:ByteArray; //Key generated for user. Used for updating personal information with server.
		public var publicKey:ByteArray; //Used for fetching public information. Shorter, unique identifier.
		
		public function Identity() 
		{
			_name = new String();
			_nearID = new String();
			key = new ByteArray();
			publicKey = new ByteArray();
			
			
			//First lets setup your identity
			//Great! Your identity any anything you post will appear on your public desktop. You can choose not to display this, however your feed will still display on your friend's heads up display.
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function set name(value:String):void 
		{
			_name = value;
		}
		
		public function get nearID():String 
		{
			return _nearID;
		}
		
		public function set nearID(value:String):void 
		{
			_nearID = value;
		}
		
	}

}