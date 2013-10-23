class com.designrealm.flashml.PaintPro extends MovieClip
{	
	
	public function paint(mc:MovieClip, x:Number, y:Number, width:Number, height:Number, vstrength:Number, vborderColor:Number, vfill:Number, borderOffset:Number, parameters:Object)
	{
		var tstrength = (!isNaN(vstrength)) ? vstrength : 0;
		var tborderColor = (!isNaN(vborderColor)) ? vborderColor : 0x999999;
		var tfill = (!isNaN(vfill)) ? vfill : null;
		var obj:Object = new Object();
		obj.cornerradius = new Number((parameters.hasBorder) ? Number(parameters.cornerradius) - vstrength : Number(parameters.cornerradius));
		obj.colorsArray = new Array();
		obj.ratiosArray = new Array();
		obj.alphasArray = new Array();
		var j = 0;
		while (parameters['bgcolor' + (j+1)] != undefined)
			j++;
		for (var i=1; i<=j; i++)
		{
			var tmp:Array = parameters['bgcolor' + i].split(";");
			obj.colorsArray[i-1] = Number(replace(tmp[0], "#", "0x"));
			obj.ratiosArray[i-1] = (tmp[1] != undefined) ? Number(tmp[1]) * 2.55 : (255 / j) * i;
			obj.alphasArray[i-1] = (tmp[2] != undefined) ? Number(tmp[2]) : 100;
		}
		var radius:Number = (!isNaN(parameters.fillrotate)) ? parameters.fillrotate % 360 : 0;
		obj.matrix = new Object({ matrixType:"box", x:(!isNaN(parameters.fillleft)) ? Number(parameters.fillleft) : x, y:(!isNaN(parameters.filltop)) ? Number(parameters.filltop) : y, w:(!isNaN(parameters.fillwidth)) ? Number(parameters.fillwidth) : width, h:(!isNaN(parameters.fillheight)) ? Number(parameters.fillheight) : height, r:(radius/180)*Math.PI });
		obj.fillType = (String(parameters.filltype) == "radial") ? "radial" : "linear";
		obj.isFilled = new Boolean(!isNaN(vfill) || obj.gradient.colorsArray.length > 0);

		if (tstrength > 0) mc.lineStyle(tstrength, tborderColor);
		var sfill:Boolean = true;
		var efill:Boolean = (isNaN(borderOffset));
		drawRect(mc, x, y, width, height, tfill, sfill, efill, obj);
		if (!isNaN(borderOffset))
		{
			sfill = false;
			efill = true;
			x+=borderOffset;
			y+=borderOffset;
			width-=borderOffset*2;
			height-=borderOffset*2;
			obj['cornerradius'] = (!isNaN(Number(obj['cornerradius']))) ? ((Number(obj['cornerradius']) - (borderOffset-1) > 0) ? Number(obj['cornerradius']) - (borderOffset-1) : 0) : null;
			drawRect(mc, x, y, width, height, tfill, sfill, efill, obj);
		}
	}
	
	private function drawRect(mc:MovieClip, x:Number, y:Number, width:Number, height:Number, vfill:Number, sfill:Boolean, efill:Boolean, parameters:Object)
	{
		if (parameters.cornerradius>0) {
			// init vars
			var theta, angle, cx, cy, px, py;
			// make sure that w + h are larger than 2*cornerradius
			if (parameters.cornerradius>Math.min(width, height)/2) {
				parameters.cornerradius = Math.min(width, height)/2;
			}
			// theta = 45 degrees in radians
			theta = Math.PI/4;
			// draw top line
			mc.moveTo(x+parameters.cornerradius, y);
			// set necessary fill
			if (sfill && (!isNaN(vfill) || (parameters.colorsArray.length > 0))) startFill(mc, parameters, vfill);
			mc.lineTo(x+width-parameters.cornerradius, y);
			//angle is currently 90 degrees
			angle = -Math.PI/2;
			// draw tr corner in two parts
			cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			// draw right line
			mc.lineTo(x+width, y+height-parameters.cornerradius);
			// draw br corner
			angle += theta;
			cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			// draw bottom line
			mc.lineTo(x+parameters.cornerradius, y+height);
			// draw bl corner
			angle += theta;
			cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			// draw left line
			mc.lineTo(x, y+parameters.cornerradius);
			// draw tl corner
			angle += theta;
			cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			angle += theta;
			cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
			px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
			py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
			mc.curveTo(cx, cy, px, py);
			if (efill && (!isNaN(vfill) || (parameters.colorsArray.length > 0))) stopFill(mc, parameters);
		} else {
			// cornerradius was not defined or = 0. This makes it easy.
			mc.moveTo(x, y);
			if (sfill && (!isNaN(vfill) || (parameters.colorsArray.length > 0))) startFill(mc, parameters, vfill);
			mc.lineTo(x+width, y);
			mc.lineTo(x+width, y+height);
			mc.lineTo(x, y+height);
			mc.lineTo(x, y);
			if (efill && (!isNaN(vfill) || (parameters.colorsArray.length > 0))) stopFill(mc, parameters);
		}
	}
	
	private function startFill(mc:MovieClip, parameters:Object, fill:Number)
	{
		if (parameters.isFilled)
			if (parameters.colorsArray.length > 0)
				mc.beginGradientFill( parameters.fillType, parameters.colorsArray, parameters.alphasArray, parameters.ratiosArray, parameters.matrix );
			else
				mc.beginFill(fill);
	}
	
	private function stopFill(mc:MovieClip, parameters:Object)
	{
		if (parameters.isFilled)
			mc.endFill();
	}
	
	private function replace(string, from, to)
    {
        return (string.split(from).join(to));
    }
}