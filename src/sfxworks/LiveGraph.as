package sfxworks 
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Samuel Jacob Walker
	 */
	public class LiveGraph extends Sprite 
	{
		//Not so dynamic 100x100 default graph
		//Tracks 2 values. kinda dynamic.
		
		//Thickness, lineColor, lineAlpha, shapeColor, shapeAlpha
		private var setInfo:Vector.<Array>;
		//Contains shape displayobjects
		private var setShapes:Vector.<Shape>;
		//Contains shape display info (6 array of latest numbers)
		private var setData:Vector.<Vector.<int>>;
		
		public function LiveGraph(thickness:int, color:Number, alpha:Number) 
		{
			this.graphics.lineStyle(thickness, color, alpha);
			//Draw background
			this.graphics.lineTo(0,100);
			this.graphics.lineTo(100,100);
			this.graphics.lineTo(100,0);
			this.graphics.lineTo(0, 0);
			
			//Draw lines for graph
			for (var i:int = 1; i < 6; i++)
			{
				this.graphics.moveTo(i*20, 0);
				this.graphics.lineTo(i*20, 100);
			}
			setInfo = new Vector.<Array>();
			setShapes = new Vector.<Shape>();
			setData = new Vector.<Vector.<int>>();
		}
		
		public function addSet(thickness:int, lineColor:Number, lineAlpha:Number, fillColor:Number, fillAlpha:Number):void
		{
			var array:Array = new Array();
			array.push(thickness);
			array.push(lineColor);
			array.push(lineAlpha);
			array.push(fillColor);
			array.push(fillAlpha);
			setInfo.push(array);
			
			var shape:Shape = new Shape();
			setShapes.push(shape);
			addChild(shape);
			
			var data:Vector.<int> = new Vector.<int>([0,0,0,0,0,	0]);
			setData.push(data);
		}
		//Must contain same number of values as nuber of sets
		//Newest number of values
		public function updateValues(values:Vector.<int>):void
		{
			//Update values
			var k:int = 0;
			for each (var dataSet:Vector.<int> in setData)
			{
				dataSet.reverse();
				dataSet.pop();
				dataSet.reverse();
				dataSet.push(values[k]);
				k++;
			}
			
			var i:int = 0;
			for each (var shape:Shape in setShapes)
			{
				shape.graphics.clear();
				var info:Array = setInfo[i];
				shape.graphics.lineStyle(info[0], info[1], info[2]);
				shape.graphics.beginFill(info[3], info[4]);
				
				shape.graphics.moveTo(0, 100);
				for (var j:int = 0; j < 6; j++)
				{
					shape.graphics.lineTo(j * 20, (setData[i][j] - 100) * -1);
				}
				shape.graphics.lineTo(100, 100);
				shape.graphics.endFill();
				i++;
			}
		} 
		
	}

}