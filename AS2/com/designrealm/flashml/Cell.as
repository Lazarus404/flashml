class com.designrealm.flashml.Cell
{

	private var upperBounds:Array;
	private var lowerBounds:Array;
	private var prevSibling:Cell;
	private var nextSibling:Cell;
	private var absolutePos:Number = 0;
	
	public function Cell(p:Cell)
	{
		upperBounds = new Array();
		lowerBounds = new Array();
		if (p!=null)
		{
			prevSibling = p;
			p.setNextSibling(this);
		}
	}
	
	public function setSpan(cell:Cell, amt:Number)
	{
		if (!isNaN(amt))
			if (cell == null)
				this.absolutePos = amt;
			else
			{
				upperBounds.push({cell:cell, amount:amt});
				cell.setLowerSpan(this, amt);
			}
	}
	
	public function setLowerSpan(cell:Cell, amt:Number)
	{
		lowerBounds.push({cell:cell, amount:amt});
	}
	
	public function setNextSibling(n:Cell)
	{
		nextSibling = n;
	}
	
	public function primeLocation()
	{		
		for (var i:Number=0; i<upperBounds.length; i++)
			if (upperBounds[i].cell.AbsolutePos > 0)
				absolutePos = Math.max(upperBounds[i].cell.AbsolutePos + upperBounds[i].amount, absolutePos);
		for (var i:Number=0; i<lowerBounds.length; i++)
			if (lowerBounds[i].cell.AbsolutePos > 0)
				absolutePos = Math.max(lowerBounds[i].cell.AbsolutePos - lowerBounds[i].amount, absolutePos);
		nextSibling.primeLocation();
	}
	
	public function getLocation(cell:Cell)
	{
		var adv:Boolean = false;
		if (absolutePos > 0)
			adv = true;
		else
		{
			for (var i:Number=0; i<upperBounds.length; i++)
				if (upperBounds[i].cell != cell && upperBounds[i].cell.AbsolutePos > 0)
					absolutePos = upperBounds[i].cell.AbsolutePos + upperBounds[i].amount;
			for (var i:Number=0; i<lowerBounds.length; i++)
				if (lowerBounds[i].cell != cell && lowerBounds[i].cell.AbsolutePos > 0)
					absolutePos = lowerBounds[i].cell.AbsolutePos - lowerBounds[i].amount;
			if (!absolutePos > 0)
			{
				var prev = getPrevAbsPos(0);
				var next = getNextAbsPos(0);
				var pap = prev.cell.AbsolutePos;
				var nap = next.cell.AbsolutePos;
				if (prev.cell == null) pap = 0;
				var tmp:Number = (((nap - pap) / (prev.pos + next.pos)) * prev.pos) + pap;
				var nextt = getNextFltPos(0);
				if (nextt.pos < next.pos)
				{
					var tot = getLastCell().AbsolutePos;
					var nap2 = tot - nextt.size;
					var tmp2:Number = (((nap2 - pap) / (prev.pos + nextt.pos)) * prev.pos) + pap;
					absolutePos = Math.min(tmp, tmp2);
				}
				else
					absolutePos = tmp;
			}
		}
		for (var i:Number=0; i<lowerBounds.length; i++)
			if (lowerBounds[i].cell != cell && lowerBounds[i].cell.AbsolutePos == 0 || isNaN(lowerBounds[i].cell.AbsolutePos))
				lowerBounds[i].cell.AbsolutePos = absolutePos + lowerBounds[i].amount;
		if (adv)
			nextSibling.getLocation(this);
		else
			nextSibling.getLocation(this);
	}
	
	public function set AbsolutePos(amt:Number)
	{
		absolutePos = amt;
	}
	
	public function get AbsolutePos():Number
	{
		return absolutePos;
	}
	
	public function getMaxLength(arr:Array):Number
	{
		var tmp:Number = 0;
		for (var i:Number=0; i<arr.length; i++)
			if (arr[i].amount > tmp) tmp = arr[i].amount;
		return tmp;
	}
	
	public function getNextFltPos(cnt:Number):Object
	{
		if (lowerBounds.length > 0) return {size:getMaxLength(lowerBounds), pos:cnt};
		cnt++;
		return nextSibling.getNextFltPos(cnt);
	}
	
	public function getNextAbsPos(cnt:Number):Object
	{
		if (absolutePos > 0) return {cell:this, pos:cnt};
		cnt++;
		return nextSibling.getNextAbsPos(cnt);
	}
	
	public function getPrevAbsPos(cnt:Number):Object
	{
		if (absolutePos > 0) return {cell:this, pos:cnt};
		cnt++;
		if (prevSibling == null) return {cell:null, pos:cnt};
		return prevSibling.getPrevAbsPos(cnt);
	}
	
	public function getLastCell():Cell
	{
		if (nextSibling == null) return this;
		return nextSibling.getLastCell();
	}
	
	public function getFirstCell():Cell
	{
		if (prevSibling == null) return this;
		return prevSibling.getFirstCell();
	}
}