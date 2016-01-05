package sfxworks 
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import mx.modules.ModuleManager;
	
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class LocalSidebar extends MovieClip
	{
		public static const ACTIVE_POSITION:int = 0;
		public static const DORMANT_POSITION:int = 0 - bg_mc.width;
		
		private var cpuGpuGraph:LiveGraph;
		private var diskReadWriteGraph:LiveGraph;
		private var statGetter:NativeProcess;
		
		public function LocalSidebar() 	
		{
			//Configure hover
			hover_mc.height = stage.stageHeight;
			hover_mc.addEventListener(MouseEvent.ROLL_OVER, handleRollOver);
			hover_mc.addEventListener(MouseEvent.ROLL_OUT, handleRollOut);
			tweenObject(this, ACTIVE_POSITION, DORMANT_POSITION);
			
			//Configure background
			bg_mc.height = stage.stageHeight;
			
			//Configure graphs
			cpuGpuGraph = new LiveGraph(1, 0x999999, 0.75);
			diskReadWriteGraph = new LiveGraph(1, 0x999999, 0.75);
			
			var statGetterStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			statGetterStartupInfo.executable = File.applicationDirectory.resolvePath("statgetter" + File.separator + "stats.exe")
			statGetter = new NativeProcess();
			statGetter.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, handleStatGetterOutput);
			statGetter.start(statGetterStartupInfo);
		}
		
		private function handleStatGetterOutput(e:ProgressEvent):void 
		{
			//Format: cpu:gpu:diskread:diskwrite [as percentage]
			var latestStat:String = statGetter.standardOutput.readUTF();
			cpuGpuGraph.updateValues(new Vector.<int>([latestStat.split(":")[0], latestStat.split(":")[1]]));
			diskReadWriteGraph.updateValues(new Vector.<int>([latestStat.split(":")[2], latestStat.split(":")[3]]));
		}
		
		private function browseToAddIcon(e:MouseEvent):void 
		{
			var applicationToAdd:File = new File();
			applicationToAdd.browseForOpen("Browse for a file to launch.");
			applicationToAdd.addEventListener(Event.SELECT, handleBrowseSelection);
		}
		
		private function handleBrowseSelection(e:Event):void 
		{
			
		}
		
		private function handleRollOut(e:MouseEvent):void 
		{
			tweenObject(this, "x", ACTIVE_POSITION, DORMANT_POSITION);
		}
		
		private function handleRollOver(e:MouseEvent):void 
		{
			tweenObject(this, "x", DORMANT_POSITION, ACTIVE_POSITION);
		}
		
		public function tweenObject(object:DisplayObject, property:String, start:int, end:int);
		{
			var tween:Tween = new Tween(object, property, Strong.easeOut, start, end, .5, true);
		}
		
	}

}