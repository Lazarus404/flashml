import com.designrealm.flashml.FMLObject;

class com.designrealm.flashml.ImagePanel extends com.designrealm.flashml.FMLObject
{
	
	private var margins:Array;
	private var bottomLeft:MovieClip;
	private var bottomMargin:Number;
	private var bottomMid:MovieClip;
	private var bottomRight:MovieClip;
	private var leftMargin:Number;
	private var midLeft:MovieClip;
	private var midMid:MovieClip;
	private var midRight:MovieClip;
	private var rightMargin:Number;
	private var skin:String;
	private var skinmc:MovieClip;
	private var topLeft:MovieClip;
	private var topMargin:Number;
	private var topMid:MovieClip;
	private var topRight:MovieClip;
	private var _tl:Number = 0;
	private var _tm:Number = 1;
	private var _tr:Number = 2;
	private var _ml:Number = 3;
	private var _mm:Number = 4;
	private var _mr:Number = 5;
	private var _bl:Number = 6;
	private var _bm:Number = 7;
	private var _br:Number = 8;
	public var clipParameters:Object = {topMargin: 1, bottomMargin: 1, leftMargin: 1, rightMargin: 1, skin: 1};
	static public var mergedClipParameters:Boolean = FMLObject.mergeClipParameters(ImagePanel.prototype.clipParameters, FMLObject.prototype.clipParameters);
   
    
	private function init(Void):Void
    {
        super.init();
		if (this.bottomMargin == undefined)
			this.bottomMargin = 20;
		if (this.topMargin == undefined)
			this.topMargin = 20;
		if (this.leftMargin == undefined)
			this.leftMargin = 20;
		if (this.rightMargin == undefined)
			this.rightMargin = 20;
		if (this.width == undefined)
			this.width = 100;
		if (this.height == undefined)
			this.height = 100;
    }
	
    private function createChildren(Void):Void
    {
		this.margins = new Array();
        this.margins[_tl] = this.createEmptyMovieClip("topLeft", _tl);
        this.margins[_tm] = this.createEmptyMovieClip("topMid", _tm);
        this.margins[_tr] = this.createEmptyMovieClip("topRight", _tr);
        this.margins[_ml] = this.createEmptyMovieClip("midLeft", _ml);
        this.margins[_mm] = this.createEmptyMovieClip("midMid", _mm);
        this.margins[_mr] = this.createEmptyMovieClip("midRight", _mr);
        this.margins[_bl] = this.createEmptyMovieClip("bottomLeft", _bl);
        this.margins[_bm] = this.createEmptyMovieClip("bottomMid", _bm);
        this.margins[_br] = this.createEmptyMovieClip("bottomRight", _br);
		for (var i=0; i<=8; i++)
		{
	        this.margins[i].createEmptyMovieClip("mask", 1);
		}
    }
	
    public function draw(Void):Void
    {
		for (var i=0; i<=8; i++)
		{
			this.margins[i].attachMovie(this.skin, "skin", 0);
			this.margins[i].skin.setMask(this.margins[i].mask);
		}
    }
    
	private function size(Void):Void
    {
        this.width = Math.max(this.width, this.leftMargin + this.rightMargin);
        this.height = Math.max(this.height, this.topMargin + this.bottomMargin);
        
		this.margins[_mm].skin._xscale = 100;
        this.margins[_mm].skin._yscale = 100;
        
		var midWidthOrig = margins[_mm].skin._width - this.leftMargin - this.rightMargin;
        var tmpW = this.width - this.leftMargin - this.rightMargin;
        var xscale = tmpW / midWidthOrig;
        
		var midheightOrig = margins[_mm].skin._height - this.topMargin - this.bottomMargin;
        var tmpH = this.height - this.topMargin - this.bottomMargin;
        var yscale = tmpH / midheightOrig;
        
		this.margins[_tm].skin._xscale = xscale * 100;
        this.margins[_tm].skin._x = -this.leftMargin * xscale;
        this.margins[_tm]._x = this.leftMargin;
        
		this.margins[_tr]._x = this.width - this.rightMargin;
        this.margins[_tr].skin._x = this.rightMargin - margins[_tr].skin._width;
        
		this.margins[_ml].skin._yscale = yscale * 100;
        this.margins[_ml].skin._y = -this.topMargin * yscale;
        this.margins[_ml]._y = this.topMargin;

		this.margins[_mm].skin._xscale = xscale * 100;
        this.margins[_mm].skin._x = -this.leftMargin * xscale;
		this.margins[_mm]._x = this.leftMargin;
        this.margins[_mm].skin._yscale = yscale * 100;
        this.margins[_mm].skin._y = -this.topMargin * yscale;
        this.margins[_mm]._y = this.topMargin;
        
		this.margins[_mr]._x = this.width - this.rightMargin;
        this.margins[_mr].skin._x = this.rightMargin - margins[_mr].skin._width;
        this.margins[_mr].skin._yscale = yscale * 100;
        this.margins[_mr].skin._y = -this.topMargin * yscale;
        this.margins[_mr]._y = this.topMargin;
        
		this.margins[_bl]._y = this.height - this.bottomMargin;
        this.margins[_bl].skin._y = this.bottomMargin - margins[_bl].skin._height;
        
		this.margins[_bm].skin._xscale = xscale * 100;
        this.margins[_bm].skin._x = -this.leftMargin * xscale;
        this.margins[_bm]._x = this.leftMargin;
        this.margins[_bm]._y = this.height - this.bottomMargin;
        this.margins[_bm].skin._y = this.bottomMargin - margins[_bm].skin._height;
		
		this.margins[_br]._x = this.width - this.rightMargin;
        this.margins[_br].skin._x = this.rightMargin - margins[_br].skin._width;
        this.margins[_br]._y = this.height - this.bottomMargin;
        this.margins[_br].skin._y = this.bottomMargin - margins[_br].skin._height;
        
		for (var i=0; i<=8; i++)
		{
			this.margins[i].mask.clear();
        	this.margins[i].mask.beginFill(0);
			this.margins[i].mask.lineTo(getRightCoord(tmpW, i), 0);
        	this.margins[i].mask.lineTo(getRightCoord(tmpW, i), getBottomCoord(tmpH, i));
        	this.margins[i].mask.lineTo(0, getBottomCoord(tmpH, i));
        	this.margins[i].mask.lineTo(0, 0);
        	this.margins[i].mask.endFill();
		}
    }
	
	private function getBottomCoord(tmpH:Number, num:Number):Number
	{
		var tmp = this;
		return (num >=0 && num <= 2) ? this.topMargin : (num >=3 && num <= 5) ? tmpH : this.bottomMargin;
	}
	
	private function getRightCoord(tmpW:Number, num:Number):Number
	{
		switch (num % 3)
		{
			case(0):
				return this.leftMargin;
			case(1):
				return tmpW;
			case(2):
				return this.rightMargin;
		}
	}
    
   

	public function set margin(m:Number)
    {
        this.topMargin = m;
        this.bottomMargin = m;
        this.leftMargin = m;
        this.rightMargin = m;
        invalidate();
    }
    
	public function get margin():Number
    {
		return (this.topMargin == this.bottomMargin && this.topMargin == this.leftMargin && this.topMargin == this.rightMargin) ? (this.topMargin) : (undefined);
    }

}