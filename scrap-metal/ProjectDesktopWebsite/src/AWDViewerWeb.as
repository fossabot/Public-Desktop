package
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.events.LoaderEvent;
	import away3d.library.assets.AssetType;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.AWD2Parser;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import away3d.events.AssetEvent;
	
	/**
	 * The AWDViewer class shows a scene contained within an AWD file utalizing the away3d library.
	 * @author Phillip R. Cargo
	 */
	public class AWDViewerWeb extends Sprite 
	{
		public var view:View3D;
		protected var loader3D:Loader3D;
		public var camera:Camera3D;
		
		//Ok something with math that a fucking genious came up with
		private var paramObj:Object = { t:0 };
		private var tw:Tween;
		private var rad:int = 180;
		
		private var cameraW:int;
		private var cameraH:int;
		
		private var earthPos:Vector3D;
		
		public function AWDViewerWeb(cameraWidth:int, cameraHeight:int) 
		{
			cameraW = cameraWidth;
			cameraH = cameraHeight;
			earthPos = new Vector3D();
		}
		
		private function handleEarth(e:Mesh):void
		{
			var earth:Mesh = e;
			var t:Timer = new Timer(20, 0);
			//tw = new Tween(paramObj, "t", Strong.easeOut, 0, 360, 50, true);
			
			function orbitEarth(evt:TimerEvent):void
			{
				paramObj.t += .2;
				earth.x = rad * Math.cos(Math.PI * paramObj.t / 180);
				earth.z = rad * Math.sin(Math.PI * paramObj.t / 180);
				earth.rotationY += .5;
				earthPos.x = earth.x;
				earthPos.z = earth.z;
				earthPos.y = earth.y;
				view.render();
				
				if (paramObj.t > 360)
				{
					paramObj.t = 1;
				}
				if (earth.rotationY > 40000)
				{
					earth.rotationY = 0;
				}
			}
			
			t.addEventListener(TimerEvent.TIMER, orbitEarth);
			t.start();
		}
		
		
		
		
		private function initialize():void
		{
			// setup the view
			view = new View3D();
			view.antiAlias = 4;
			addChild(view);
			
			// setup the loader3D
			Loader3D.enableParser(AWD2Parser);
			loader3D = new Loader3D();
			loader3D.addEventListener(AssetEvent.ASSET_COMPLETE, handleAssetComplete);
			loader3D.addEventListener(LoaderEvent.RESOURCE_COMPLETE, handleLoaderComplete);
		}
		
		/**
		 * Display an AWD file.
		 * @param	inPath Path to the AWD file
		 */
		public function showByURL(inPath:String):void
		{
			initialize();
			loader3D.load( new URLRequest(inPath) );
		}
		
		/**
		 * Handles the ASSET_COMPLETE event from the loader3D, which is called as each asset within the AWD is loaded.
		 * @param	e
		 */
		private function handleAssetComplete(e:AssetEvent):void 
		{
			switch (e.asset.assetType)
			{
				case (AssetType.CAMERA):
					camera = (e.asset as Camera3D);
					view.width = cameraW;
					view.height = cameraH;
					view.camera = camera;
					break;
				case  (AssetType.MESH):
					if (e.asset.name == "EarthMesh")
					{
						handleEarth(e.asset as Mesh);
					}
					if (e.asset.name == "SunMesh")
					{
						handleSun(e.asset as Mesh);
					}
					if (e.asset.name == "MoonMesh")
					{
						handeMoon(e.asset as Mesh);
					}
					trace("Mesh found. " + e.asset.name);
					break;
			}
		}
		
		private function handeMoon(mesh:Mesh):void 
		{
			var moon:Mesh = mesh;
			var t:Timer = new Timer(20, 0);
			var moonRad:int = 25;
			var moonParam:int = 1;
			//tw = new Tween(paramObj, "t", Strong.easeOut, 0, 360, 50, true);
			
			function orbitEarth(evt:TimerEvent):void
			{
				moon.x = earthPos.x + (moonRad * Math.cos(Math.PI * moonParam / 180));
				moon.z = earthPos.z + (moonRad * Math.sin(Math.PI * moonParam / 180));
				moon.rotationY += .5;
				moonParam += 2;
				
				if (moonParam > 360)
				{
					moonParam = 2;
				}
				if (moon.rotationY > 4000)
				{
					moon.rotationY = 0;
				}
			}
			
			t.addEventListener(TimerEvent.TIMER, orbitEarth);
			t.start();
		}
		
		private function handleSun(mesh:Mesh):void 
		{
			var sun:Mesh = mesh;
			var t:Timer = new Timer(20, 0);
			//tw = new Tween(paramObj, "t", Strong.easeOut, 0, 360, 50, true);
			
			function rotateSun(evt:TimerEvent):void
			{
				sun.rotationX += .5;
				sun.rotationY += .2;
				sun.rotationZ += .3;
				
				if (sun.rotationX > 4000)
				{
					sun.rotationX = 0;
					sun.rotationY = 0;
					sun.rotationZ = 0;
				}
			}
			t.addEventListener(TimerEvent.TIMER, rotateSun);
			t.start();
		}
		
		/**
		 * Handles the RESOURCE_COMPLETE event from the loader3D, which is called when the entire AWD file has been parsed.
		 * @param	e
		 */
		private function handleLoaderComplete(e:LoaderEvent):void 
		{
			view.scene.addChild((e.currentTarget as ObjectContainer3D));
			view.render();
		}
		
	}

}