package com.designrealm.flashml{
	
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	
	public class Renderer  {	
			
		
		public function paint(mc:Sprite, x:Number, y:Number, width:Number, height:Number, parameters:Object){
			
			if (parameters == null) return;
			
			var border:Number = (parameters['border'] != null) ? Number(replace(parameters['border'], "#", "0x")) : 0;
			var bordercolor:Number = (parameters['bordercolor'] != null) ? Number(replace(parameters['bordercolor'], "#", "0x")) : NaN;
			var bgcolor:Number  = (parameters['bgcolor'] != null) ? Number(replace(parameters['bgcolor'], "#", "0x")) : NaN;
			var borderoffset:Number = (!isNaN(parameters['borderoffset'])) ? Number(parameters['borderoffset']) : 0;
		
			var obj:Object = new Object();
			obj.cornerradius = 0;
			obj.colorsArray = new Array();
			obj.ratiosArray = new Array();
			obj.alphasArray = new Array();
			obj.fillType = GradientType.RADIAL;
			
			
			if (parameters != null) {
				if (!isNaN(parameters['cornerradius'])) obj.cornerradius = Math.max(parameters['cornerradius'] - border,0);
				var j:uint = 0;
				while (parameters['bgcolor' + (j+1)] != undefined) j++;
				for (var i:uint = 1; i<=j; i++){
					var tmp:Array = parameters['bgcolor' + i].split(";");
					obj.colorsArray[i-1] = Number(replace(tmp[0], "#", "0x"));
					obj.ratiosArray[i-1] = (tmp[1] != undefined) ? Number(tmp[1]) * 2.55 : (255 / j) * i;
					obj.alphasArray[i-1] = (tmp[2] != undefined) ? Number(tmp[2]) : 1;
				}
				var radius:Number = (!isNaN(parameters['fillrotate'])) ? parameters['fillrotate'] % 360 : 0;
				obj.matrix = new Matrix();
				obj.matrix.createGradientBox((!isNaN(parameters.fillwidth)) ? Number(parameters.fillwidth) : width, 
						parameters.fillheight ? Number(parameters.fillheight) : height,
						radius/180*Math.PI,
						parameters.fillleft ? Number(parameters.fillleft) : x, 
						parameters.filltop ? Number(parameters.filltop) : y);
				obj.spreadMethod = SpreadMethod.PAD;

				obj.fillType = (String(parameters.filltype) == "radial") ? GradientType.RADIAL : GradientType.LINEAR;
		
			}
			
			if (border > 0) 
				mc.graphics.lineStyle(border, bordercolor);			
			
			var _startfill:Boolean = (!isNaN(bgcolor) || obj.colorsArray.length > 0)
			var _stopfill:Boolean = ((!isNaN(bgcolor) || obj.colorsArray.length > 0) && isNaN(borderoffset));			
			
			drawRect(mc, x, y, width, height, bgcolor, _startfill, _stopfill, obj);
			
			if (!isNaN(bgcolor) && !isNaN(borderoffset)) {
				_startfill = false;
				_stopfill = true;
				x+=borderoffset;
				y+=borderoffset;
				width-=borderoffset*2;
				height-=borderoffset*2;
				obj['cornerradius'] = !isNaN(Number(obj['cornerradius'])) ?  ((Number(obj['cornerradius']) - (borderoffset-1) > 0) ?  Number(obj['cornerradius']) - (borderoffset-1) : 0) : null;
				drawRect(mc, x, y, width, height, bgcolor, _startfill, _stopfill, obj);
			}
			
		}
		
		private function drawRect(mc:Sprite, x:Number, y:Number, width:Number, height:Number, bgcolor:Number, _startfill:Boolean, _stopfill:Boolean, parameters:Object)	{
			if (parameters != null && parameters.cornerradius > 0) {
				trace(parameters.cornerradius);
				// init vars
				var theta:Number, angle:Number, cx:Number, cy:Number, px:Number, py:Number;
				
				// make sure that w + h are larger than 2*cornerradius
				if ( parameters.cornerradius > Math.min(width,height)/2 ) {
					parameters.cornerradius = Math.min(width,height)/2;
				}
				
				// theta = 45 degrees in radians
				theta = Math.PI/4;
				// draw top line
				
				mc.graphics.moveTo(x+parameters.cornerradius, y);
				// set necessary fill
				if (_startfill && (!isNaN(bgcolor) || (parameters.colorsArray.length > 0))) startFill(mc, parameters, bgcolor);
				mc.graphics.lineTo(x+width-parameters.cornerradius, y);
				//angle is currently 90 degrees
				angle = -Math.PI/2;
				// draw tr corner in two parts
				cx = x + width - parameters.cornerradius + (Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				angle += theta;
				cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				// draw right line
				mc.graphics.lineTo(x+width, y+height-parameters.cornerradius);
				// draw br corner
				angle += theta;
				cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				angle += theta;
				cx = x+width-parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+width-parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				// draw bottom line
				mc.graphics.lineTo(x+parameters.cornerradius, y+height);
				// draw bl corner
				angle += theta;
				cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				angle += theta;
				cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+height-parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+height-parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				// draw left line
				mc.graphics.lineTo(x, y+parameters.cornerradius);
				// draw tl corner
				angle += theta;
				cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				angle += theta;
				cx = x+parameters.cornerradius+(Math.cos(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				cy = y+parameters.cornerradius+(Math.sin(angle+(theta/2))*parameters.cornerradius/Math.cos(theta/2));
				px = x+parameters.cornerradius+(Math.cos(angle+theta)*parameters.cornerradius);
				py = y+parameters.cornerradius+(Math.sin(angle+theta)*parameters.cornerradius);
				mc.graphics.curveTo(cx, cy, px, py);
				if (_stopfill && (!isNaN(bgcolor) || (parameters.colorsArray.length > 0))) stopFill(mc, parameters);
			} else {
				// cornerradius was not defined or = 0. This makes it easy.
				mc.graphics.moveTo(x, y);
				if (_startfill && (!isNaN(bgcolor) || (parameters.colorsArray.length > 0))) startFill(mc, parameters, bgcolor);
				mc.graphics.lineTo(x+width, y);
				mc.graphics.lineTo(x+width, y+height);
				mc.graphics.lineTo(x, y+height);
				mc.graphics.lineTo(x, y);
				if (_stopfill && (!isNaN(bgcolor) || (parameters.colorsArray.length > 0))) stopFill(mc, parameters);
			}
		}
		
		private function startFill(mc:Sprite, parameters:Object, bgcolor:Number):void{
			if (parameters != null && parameters.colorsArray.length > 0)
				mc.graphics.beginGradientFill( parameters.fillType, parameters.colorsArray, parameters.alphasArray, parameters.ratiosArray, parameters.matrix, parameters.spreadMethod );
			else
				mc.graphics.beginFill(bgcolor);
		}
		
		private function stopFill(mc:Sprite, parameters:Object):void{
				mc.graphics.endFill();
		}
		
		private function replace(string:String, from:String, to:String):String{
			return (string.split(from).join(to));
		}
	}
}