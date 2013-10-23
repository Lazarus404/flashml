package com.designrealm.flashml{
	
	public class CellManager{

		public var cells:Array;		
		
		public function CellManager(){
			cells = new Array();
		}
		
		public function parseCells(tableSize:Number):Array{
			if (!isNaN(tableSize))
				cells[cells.length-1].AbsolutePos = tableSize;
			var newArr:Array = new Array();
			setLocationValues();
			normalizeValues();
			for (var i:uint = 0; i<cells.length; i++){
				newArr[i] = cells[i].AbsolutePos;
			}
			return newArr;
		}
		
		public function setLocationValues():void{
			cells[0].primeLocation();
			for (var i:uint = 0; i<cells.length; i++)
				cells[i].getLocation(null);
		}
		
		public function normalizeValues():void{
			for (var i:uint = cells.length-1; i>0; i--)
				cells[i].AbsolutePos -= cells[i-1].AbsolutePos;
		}
		
		public function setSpan(cell:Number, span:Number, size:Number):void{
			if (!isNaN(size))
				if (cell == 0)
					cells[(cell-1)+span].setSpan(null, size);
				else
					cells[(cell-1)+span].setSpan(cells[cell-1], size);
		}
		
		public function addCells(cnt:Number):void	{
			if (isNaN(cnt)) cnt = 1;
			for (var i:Number=0; i<cnt; i++)
				if (cells.length != 0)
					cells.push(new Cell(cells[cells.length-1]));
				else
					cells.push(new Cell(null));
		}
		
		public function get Count():Number{
			return cells.length;
		}
	}
}