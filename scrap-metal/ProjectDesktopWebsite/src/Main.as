package
{
	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class Main extends MovieClip 
	{
		private var awdViewer:AWDViewerWeb;
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, handleResize);
			stage.align = StageAlign.TOP_LEFT;
			
			awdViewer = new AWDViewerWeb(stage.stageWidth, stage.stageHeight);
			addChild(awdViewer);
			awdViewer.showByURL("desktop.awd");
			
			header_mc.menuItems_mc.menu_mc.addEventListener(MouseEvent.ROLL_OVER, hanldeRollOver);
			header_mc.menuItems_mc.menu_mc.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			
			header_mc.menuItems_mc.download_mc.addEventListener(MouseEvent.ROLL_OVER, hanldeRollOver);
			header_mc.menuItems_mc.download_mc.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			
			swapChildren(header_mc, awdViewer);
			
			header_mc.bg_mc.width = stage.stageWidth;
			title_mc.x = stage.stageWidth / 2;
			header_mc.menuItems_mc.x = stage.stageWidth;
		}
		
		private function handleResize(e:Event):void 
		{
			awdViewer.view.width = stage.stageWidth;
			awdViewer.view.height = stage.stageHeight;
			header_mc.bg_mc.width = stage.stageWidth;
			title_mc.x = stage.stageWidth / 2;
			header_mc.menuItems_mc.x = stage.stageWidth;
		}
		
		
		private function handleRollOut(e:MouseEvent):void 
		{
			var tweenIn:Tween = new Tween(e.target.mask_mc, "height", Strong.easeOut, 90, 30, .5, true);
		}
		
		private function hanldeRollOver(e:MouseEvent):void 
		{
			var tweenOut:Tween = new Tween(e.target.mask_mc, "height", Strong.easeOut, 30, 90, .5, true);
		}
		
		
		
		
		//Version check -
		private function checkForUpdate():void
		{
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			var version:int = parseInt(appXML.ns::versionNumber);
			
			trace("Version = " + version);
		}
		
	}
	
}