import com.designrealm.flashml.PaintPro;
import com.designrealm.flashml.ImagePanel;

class com.designrealm.flashml.PaintDeluxe extends com.designrealm.flashml.PaintPro
{
	
	public function paint(mc:MovieClip, x:Number, y:Number, width:Number, height:Number, vstrength:Number, vborderColor:Number, vfill:Number, borderOffset:Number, parameters:Object)
	{
		var tstrength = (!isNaN(vstrength)) ? vstrength : 0;
		var tborderColor = (!isNaN(vborderColor)) ? vborderColor : 0x999999;
		var tfill = (!isNaN(vfill)) ? vfill : null;
		if (parameters.bgimage != undefined)
		{
			
			var bgmc:MovieClip = mc.attachMovie('ImagePanel', 'bgimage', mc.getNextHighestDepth(), {skin:parameters.bgimage});
			bgmc.width = width;
			bgmc.height = height;
			if (!isNaN(Number(parameters.bgmargin))) bgmc.margin = Number(parameters.bgmargin);
			if (!isNaN(Number(parameters.bgtopmargin))) bgmc.topMargin = Number(parameters.bgtopmargin);
			if (!isNaN(Number(parameters.bgbottommargin))) bgmc.bottomMargin = Number(parameters.bgbottommargin);
			if (!isNaN(Number(parameters.bgleftmargin))) bgmc.leftMargin = Number(parameters.bgleftmargin);
			if (!isNaN(Number(parameters.bgrightmargin))) bgmc.rightMargin = Number(parameters.bgrightmargin);
			bgmc.invalidate();
		}
		else
			super.paint(mc, x, y, width, height, tstrength, tborderColor, tfill, borderOffset, parameters);
	}
}