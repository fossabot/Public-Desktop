package sfxworks 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import org.bytearray.gif.player.GIFPlayer;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class SpaceObject extends MovieClip 
	{
		private var _actions:String; //Actions (scripts for object)
		private var _source:String;
		
		private var boundss:Rectangle;
		private var rot:int;
		private var matrix:Matrix;
		
		//Video Resources
		private var nc:NetConnection;
		private var ns:NetStream;
		private var v:Video;
		
		//HTMLResources
		private var htmlLoader:HTMLLoader;
		private var btrick:Boolean;
		private var t:Timer = new Timer(20000);
		private var htmlBm:Bitmap;
		
		private var editmodee:Boolean;
		//Tmp
		private var ba:ByteArray;
		
		public function SpaceObject(source:String, actions:String, bounds:Rectangle, rotation:int=0, matrixx:Matrix = null, editmode:Boolean=true, extension:String="") 
		{
			if (source != "embeddedobject")
			{
				var sourceFile:File = new File(source);
			}
			editmodee = editmode;
			_source = source;
			_actions = actions;
			boundss = bounds;
			rot = rotation;
			matrix = matrixx;
			//trace("Sourefile extension = " + sourceFile.extension);
			if (source == "embeddedobject")
			{
				htmlLoader = new HTMLLoader();
				htmlLoader.placeLoadStringContentInApplicationSandbox = true;
				htmlLoader.loadString(_actions);
				htmlLoader.addEventListener(Event.COMPLETE, handleHtmlLoadComplete);
			}
			else if (extension.toLocaleLowerCase() == "jpg" || extension.toLocaleLowerCase() == "gif" || extension.toLocaleLowerCase() == "png" || extension.toLocaleLowerCase() == "jpeg" || extension.toLocaleLowerCase() == "bmp")
			{
				//It's an image
				trace("it's an image");
				//Get source file data /[add cant find file to stream if neccesary]
				fs = new FileStream();
				ba = new ByteArray();
				
				var fs:FileStream = new FileStream();
				fs.open(sourceFile, FileMode.READ);
				fs.readBytes(ba, 0, sourceFile.size);
				fs.close();
				
				if (extension == "gif")
				{
					//Handle gif with gif player
					trace("It's a gif!");
					var gifplayer:GIFPlayer = new GIFPlayer();
					gifplayer.loadBytes(ba);
					gifplayer.play();
					addChild(gifplayer);
				}
				else //Handle objecet as normals
				{
					var l:Loader = new Loader();
					l.loadBytes(ba);
					l.contentLoaderInfo.addEventListener(Event.COMPLETE, handleImageLoadComplete);
				}
			}
			else if (extension == "mp4" || extension == "m4v" || extension == "f4v" || extension == "3gpp" || extension == "flv")
			{
				//It's a video
				trace("It's a video");
				
				var customClient:Object = new Object();
				customClient.onMetaData = metaDataHandler;
				 
				nc = new NetConnection();
				nc.connect(null);
				 
				ns = new NetStream(nc);
				ns.client = customClient;
				ns.play(_source);
				 
				v = new Video();
				v.attachNetStream(ns);
				this.buttonMode = true;
				addChild(v);
				
				//Add args to handle pause and play
				addEventListener(MouseEvent.CLICK, handleClick);
			}
			else
			{
				
			}
			
			//this.addEventListener(Event.REMOVED, handleRemoved);
			this.addEventListener(Event.REMOVED_FROM_STAGE, handleRemoved);
		}
		
		private function handleHtmlLoadComplete(e:Event):void 
		{
			htmlLoader.removeEventListener(Event.COMPLETE, handleHtmlLoadComplete);
			htmlLoader.width = htmlLoader.contentWidth;
			htmlLoader.height = htmlLoader.contentHeight;
			this.x = boundss.x;
			this.y = boundss.y;
			
			if (editmodee)
			{
				trace("in edit mode");
				btrick = new Boolean(true);
				htmlLoader.addEventListener(Event.HTML_RENDER, handleHtmlRender);
				t.addEventListener(TimerEvent.TIMER_COMPLETE, handleTrickComplete);
				t.start();
			}
			else
			{
				trace("added to stage");
				addChild(htmlLoader);
			}
		}
		
		private function handleTrickComplete(e:TimerEvent):void 
		{
			t.removeEventListener(TimerEvent.TIMER_COMPLETE, handleTrickComplete);
			btrick = false;
		}
		
		private function handleHtmlRender(e:Event):void 
		{
			if (btrick) //Redraw each render and then stop after 5 seconds. Presumably everything will be rendered by then.
			{
				var bmd:BitmapData = new BitmapData(htmlLoader.width, htmlLoader.height);
				bmd.draw(htmlLoader as DisplayObject);
				htmlBm = new Bitmap(bmd);
				//removeChildren();
				addChild(htmlBm);
			}
			else
			{
				htmlLoader.removeEventListener(Event.HTML_RENDER, handleHtmlRender);
			}
		}
		
		private function metaDataHandler(infoObject:Object):void 
		{
			if (boundss.width != 0 && boundss.height != 0)
			{
				v.width = boundss.width;
				v.height = boundss.height;
			}
			else
			{
				v.width = infoObject.width;
				v.height = infoObject.height;
			}
			
			//this.width = v.width;
			//this.height = v.height;
		}
		
		private function handleAsyncError(e:AsyncErrorEvent):void 
		{
			trace("Async error");
			trace(e.text);
		}
		
		private function handleClick(e:MouseEvent):void 
		{
			if (nc != null)
			{
				ns.togglePause();
			}
		}
		
		private function handleRemoved(e:Event):void 
		{
			if (htmlLoader != null)
			{
				htmlLoader.reload(); //Cant pause so Ill just trigger a reload and cancel
				htmlLoader.cancelLoad();
			}
			if (nc != null) //If there's a video on stage..
			{
				ns.pause();
			}
		}
		
		private function handleImageLoadComplete(e:Event):void 
		{
			addChild(e.target.content);
			ba = null;
			handleActions(); //For handling actions..
			setPosition(); //Set position after loading object
		}
		
		private function setPosition():void 
		{
			if (boundss.width != 0 && boundss.height != 0)
			{
				this.width = boundss.width;
				this.height = boundss.height;
			}
			this.x = boundss.x;
			this.y = boundss.y;
			
			this.rotation = rot;
			
			trace(this.transform.matrix);
			trace(matrix);
			
			if (matrix != null)
			{
				this.transform.matrix = new Matrix(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
			}
		}
		
		private function handleActions():void
		{
			
			
		}
		
		public function get actions():String 
		{
			return _actions;
		}
		
		public function set actions(value:String):void 
		{
			_actions = value;
		}
		
		public function get source():String 
		{
			return _source;
		}
		
	}

}