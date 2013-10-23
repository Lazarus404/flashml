package com.designrealm.flashml {
	
	public class Cell {
		
		private var upperBounds:Array;
		private var lowerBounds:Array;
		private var prevSibling:Cell;
		private var nextSibling:Cell;
		private var absolutePos:Number = 0;
		
		public function Cell(p:Cell){
			
			upperBounds = new Array();
			lowerBounds = new Array();
			
			if (p != null){
				prevSibling = p;
				p.setNextSibling(this);
			}
		}
		
		public function setSpan(cell:Cell, amt:Number):void{
			if (!isNaN(amt))
				if (cell == null)
					this.absolutePos = amt;
				else
				{
					upperBounds.push({cell:cell, amount:amt});
					cell.setLowerSpan(this, amt);
				}
		}
		
		public function setLowerSpan(cell:Cell, amt:Number):void{
			lowerBounds.push({cell:cell, amount:amt});
		}
		
		public function primeLocation():void {		
		
			for (var i:uint = 0; i<upperBounds.length; i++)
				if (upperBounds[i].cell.AbsolutePos > 0)
					absolutePos = Math.max(upperBounds[i].cell.AbsolutePos + upperBounds[i].amount, absolutePos);
			for (i = 0; i<lowerBounds.length; i++)
				if (lowerBounds[i].cell.AbsolutePos > 0)
					absolutePos = Math.max(lowerBounds[i].cell.AbsolutePos - lowerBounds[i].amount, absolutePos);
			if (nextSibling != null) 
				nextSibling.primeLocation();
				
		}
		
		public function getLocation(cell:Cell):void{

			if (absolutePos <= 0) {
				for (var i:uint = 0; i<upperBounds.length; i++)
					if (upperBounds[i].cell != cell && upperBounds[i].cell.AbsolutePos > 0)
						absolutePos = upperBounds[i].cell.AbsolutePos + upperBounds[i].amount;
				for (i = 0; i<lowerBounds.length; i++)
					if (lowerBounds[i].cell != cell && lowerBounds[i].cell.AbsolutePos > 0)
						absolutePos = lowerBounds[i].cell.AbsolutePos - lowerBounds[i].amount;
				if (!(absolutePos > 0))	{
					var prev:Object = getPrevAbsPos(0);
					var next:Object = getNextAbsPos(0);
					var pap:Number = (prev.cell == null) ? 0 : prev.cell.AbsolutePos;
					var nap:Number = next.cell.AbsolutePos;
					var tmp:Number = (((nap - pap) / (prev.pos + next.pos)) * prev.pos) + pap;
					var nextt:Object = getNextFltPos(0);
					if (nextt.pos < next.pos)	{
						var tot:Number = getLastCell().AbsolutePos;
						var nap2:Number = tot - nextt.size;
						var tmp2:Number = (((nap2 - pap) / (prev.pos + nextt.pos)) * prev.pos) + pap;
						absolutePos = Math.min(tmp, tmp2);
					}
					else
						absolutePos = tmp;
				}
			}
			
			for (i = 0; i<lowerBounds.length; i++)
				if (lowerBounds[i].cell != cell && lowerBounds[i].cell.AbsolutePos == 0 || isNaN(lowerBounds[i].cell.AbsolutePos))
					lowerBounds[i].cell.AbsolutePos = absolutePos + lowerBounds[i].amount;
			
			if (nextSibling != null) nextSibling.getLocation(this);

		}
		
		public function set AbsolutePos(amt:Number):void{
			absolutePos = amt;
		}
		
		public function get AbsolutePos():Number	{
			return absolutePos;
		}
		
		public function setNextSibling(n:Cell):void{
			nextSibling = n;
		}
		
		public function getLastCell():Cell{
			if (nextSibling == null) return this;
			return nextSibling.getLastCell();
		}
		
		public function getFirstCell():Cell{
			if (prevSibling == null) return this;
			return prevSibling.getFirstCell();
		}
		
		public function getNextFltPos(cnt:Number):Object{
			if (lowerBounds.length > 0 || nextSibling == null) return {size:getMaxLength(lowerBounds), pos:cnt};
			cnt++;
			return nextSibling.getNextFltPos(cnt);
		}
		
		public function getMaxLength(arr:Array):Number	{
			var tmp:Number = 0;
			for (var i:Number=0; i<arr.length; i++)
				if (arr[i].amount > tmp) tmp = arr[i].amount;
			return tmp;
		}
		
		public function getNextAbsPos(cnt:Number):Object{
			if (absolutePos > 0) return {cell:this, pos:cnt};
			cnt++;
			return nextSibling.getNextAbsPos(cnt);
		}
		
		public function getPrevAbsPos(cnt:Number):Object{
			if (absolutePos > 0) return {cell:this, pos:cnt};
			cnt++;
			if (prevSibling == null) return {cell:null, pos:cnt};
			return prevSibling.getPrevAbsPos(cnt);
		}
	}
}