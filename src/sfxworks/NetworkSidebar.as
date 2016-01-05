package sfxworks 
{
	import flash.display.MovieClip;
	import flash.filesystem.File;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class NetworkSidebar extends MovieClip
	{
		
		public function NetworkSidebar(c:Communications) 
		{
			
		}
		
		private function listModules():void
		{
			var moduleFolder:File = new File(File.applicationStorageDirectory.resolvePath("modules" + File.separator);
			
			var dirListing:Array = moduleFolder.getDirectoryListing();
			
			for each (var file:File in dirListing)
			{
				if (file.extension == ".swf")
				{
					loadModule(file.nativePath);
				}
			}
		}
		
		private function loadModule(url:String):void
		{
			var info:IModuleInfo = ModuleManager.getModule(url);
			
			info.addEventListener(ModuleEvent.READY, handleModuleReady);
			info.load(null, null, null, moduleFactory); //?? New object or just that?
			
		}
		
		private function handleModuleReady(e:ModuleEvent):void 
		{
			
		}
		
	}

}