package sfxworks 
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkApplicationButton extends Sprite
	{
		
		private var moduleURL:String;
		public function NetworkApplicationButton(url:String) 
		{
			moduleURL = url;
			
			//Create Icon
			//32 x 32
			var icon:File = new File(url);
			icon.nativePath = icon.nativePath.split(icon.extension)[0];
			icon = new File(icon.nativePath + File.separator + "icon.png");
			
			
			//Place Icon
			if (icon.exists)
			{
				var l:Loader = new Loader();
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, handleIconLoad);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			}
			
			var tf:TextField = new TextField();
			
			//Get file name out of the url
			
			//url = Blah/,blah/,file.name
			var raw:Array = url.split(File.separator); //Blah/,blah/,file.ext
			tf.text = raw[raw.length - 1].split(".")[0]; //file<-,.ext
			
			
			
			
			addEventListener(MouseEvent.CLICK, handleClick);
		}
		
		private function handleIconLoad(e:Event):void 
		{
			addChild(e.target.data);
			//Just to be sure...
			e.target.data.width = 32;
			e.target.data.height = 32;
		}
		
		private function handleIOError(e:IOErrorEvent):void 
		{
			trace("IOError");
		}
		
		private function handleClick(e:MouseEvent):void 
		{
			
		}
		
	}

}