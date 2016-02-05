package 
{
	import fl.transitions.easing.*;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class Sidebar extends MovieClip 
	{
		private var fs:FileStream;
		private var shortcuts:File;
		
		private var icons:Vector.<Iconn>;
		
		private var f:File;
		
		public function Sidebar() 
		{
			menu_mc.bg_mc.height = stage.fullScreenHeight;
			
			
			//fileExplorer_btn.addEventListener(MouseEvent.CLICK, handleFileExplorerClick);
			menu_mc.addApplication_btn.addEventListener(MouseEvent.CLICK, handleAddApllication);
			currentY = 132;
			shortcuts = File.applicationStorageDirectory.resolvePath(".shortcutsfinal");
			
			icons = new Vector.<Iconn>();
			
			if (shortcuts.exists)
			{
				trace("Shortcuts exist..adding");
				fs = new FileStream();
				fs.open(shortcuts, FileMode.READ);
				trace("READ = " + fs.readUTFBytes(shortcuts.size));
				fs.position = 0;
				var raw:Array = fs.readUTFBytes(shortcuts.size).split("||");
				fs.close();
				for (var i:int = 0; i < raw.length; i++)
				{
					f = new File();
					f = File.applicationStorageDirectory.resolvePath(raw[i]);
					trace("WRITTEN PATH = " + raw[i]);
					trace("PATH = " + f.nativePath);
					icons.push(new Iconn(f));
				}
				trace("icons = " + icons); //Null value
				trace("icons length  = " + icons.length); //Null value
				for each (var shortcut:Iconn in icons)
				{
					menu_mc.addChild(shortcut);
					shortcut.x += 5; //Spacing
					shortcut.y = currentY; //Vertical spacing
					currentY += 18; //Save for next round.
					if (currentY > this.height)
					{
						return; //Dont add anymore if it wont fit on the screen -_-
					}
					shortcut.addEventListener(MouseEvent.RIGHT_CLICK, removeIcon)
					trace("Added shortcut");
				}
			}
			else
			{
				trace("No shortcuts avalible.");
			}
			
			
			
			
			this.hitArea = over_mc;
			this.addEventListener(MouseEvent.ROLL_OUT, handleMouseOut);
			this.addEventListener(MouseEvent.ROLL_OVER, handleMouseOver);
			//over_mc.visible = false;
		}
		
		private function handleMouseOut(e:MouseEvent):void 
		{
			var tweenOut:Tween = new Tween(menu_mc, "x", Strong.easeOut, 0, -24, .5, true);

		}
		
		private function handleMouseOver(e:MouseEvent):void 
		{
			var tweenIn:Tween = new Tween(menu_mc, "x", Strong.easeOut, -24, 0 , .5, true);
		}
		
		private function handleAddApllication(e:MouseEvent):void 
		{
			f = new File();
			f = File.applicationDirectory.resolvePath(".." + File.separator);
			f.browseForOpen("Select an application to add.");
			f.addEventListener(Event.SELECT, handleShortcutSelection);
		}
		
		private function handleShortcutSelection(e:Event):void 
		{
			addShortcut(f);
		}
		
		public function addShortcut(f:File):void
		{
			var icon:Iconn = new Iconn(f);
			
			//Display on side
			icons.reverse(); //Add to the front so it displays on the top.
			icons.push(icon); //Use 16x16 bitmap
			
			menu_mc.addChild(icons[icons.length - 1]);
			icons.reverse();
			
			//Save object
			fs = new FileStream();
			fs.open(shortcuts, FileMode.APPEND);
			fs.writeUTFBytes(f.nativePath + "||");
			trace(f.nativePath + "ADDED.");
			fs.close();
			
			//Add handler to remove object
			icon.addEventListener(MouseEvent.RIGHT_CLICK, removeIcon)
			
			reorder(); //Orders the display of all icons.
		}
		
		private function removeIcon(e:MouseEvent):void 
		{
			e.target.removeEventListener(MouseEvent.RIGHT_CLICK, removeIcon);//Remove event listener
			icons.splice(icons.indexOf(e.target), 1); //Remove from index
			menu_mc.removeChild(e.target as DisplayObject); //Remove from stage
			rewrite(); //Rewirte icons file for save
			reorder(); //Reorder the icons on stage
		}
		
		private function rewrite():void
		{
			var fs:FileStream = new FileStream();
			shortcuts.deleteFile();
			fs.open(shortcuts, FileMode.WRITE);
			for each (var icon:Iconn in icons)
			{
				fs.writeUTFBytes(icon.path + "||");
			}
			fs.close();
		}
		
		//Orderes the display of all icons. Called when adding or removing a shortcut from the list
		private var currentY:int;
		private function reorder():void
		{
			currentY = 132;
			for each (var icon:Iconn in icons)
			{
				menu_mc.removeChild(icon);
				menu_mc.addChild(icon);
				icon.x = 5; //Spacing
				icon.y = currentY; //Vertical spacing
				currentY += 18; //Save for next round.
				if (currentY > this.height)
				{
					return; //Dont add anymore if it wont fit on the screen -_-
				}
			}
		}
	}

}