class com.designrealm.utils.XMLDeserializerFactory
{
	public static var __x : XML;
	
	private function XMLDeserializerFactory(){}
	
	public static function deserialize( data : String, objTarget : Object ) : Void
	{				
		//trace( data + "|" + objTarget );
			__x = new XML();
		
		//parse the string data into an XML Document
			parseData( data );
		
		//Calls the recursive function which will apply all the objects
			var i : Number = 0;
			for ( i=0; i<__x.childNodes.length; i++ )deserializeRecursion( __x.childNodes[ i ], objTarget );
	}
	
	
	private static function parseData( StrXMLInput : String ) : Void
	{
		//this.ignoreWhite = true;
		var StrXMLOutput : String = "";
		var numTagIndexOpen : Number = StrXMLInput.indexOf( "<?" );
		var numTagIndexClose : Number = StrXMLInput.indexOf( "?>" );
	
		while( numTagIndexOpen > -1 && numTagIndexClose > -1 ) 
		{
			StrXMLOutput += StrXMLInput.substr( 0, numTagIndexOpen );
			StrXMLInput = StrXMLInput.substr( numTagIndexClose + 2 );
			numTagIndexOpen = StrXMLInput.indexOf( "<?" );
			numTagIndexClose = StrXMLInput.indexOf( "?>" );
		}
	
		StrXMLOutput += StrXMLInput;
		__x.ignoreWhite = true;
		__x.parseXML( StrXMLOutput );
	}
	
	
	
	private static function deserializeRecursion( xcopy : XML, obj : Object ) : Void
	{
		var i;
		for ( i=0; i<xcopy.childNodes.length; i++ )
		{
			var currentNode = xcopy.childNodes[i];
			//-------------------------------------------------------------------------
			// Setup Local Variables
			//-------------------------------------------------------------------------
				
				//Holds the Object Identifer for the node being Processed
					var objDataType : String = currentNode.nodeName.substr( 0, 1 ).toUpperCase() + currentNode.nodeName.substr( 1 );
					
				//Holds the Object Data Type for the node being Processed currentNode.attributes.instance
					var objIdenifier : String = ( currentNode.attributes["instance"] == null ) ? "null" : currentNode.attributes["instance"];
					
				//Holds the Object Data Type for the node being Processed
					var objNamespace : String = ( currentNode.attributes["namespace"] == null ) ? "" : currentNode.attributes["namespace"]+".";
				
				//Holds the Node Type for the c
					var XMLNodeType = currentNode.nodeType;
					

			//-------------------------------------------------------------------------
			// Process Data Types
			//-------------------------------------------------------------------------
				
				//Only Process valid elements
				if( objDataType != null )
				{	
					
					
					//-------------------------------------------------------------------------
					// Apply Data Types
					// Need to fix!!!  (Class instantiation)
					//-------------------------------------------------------------------------
						//if( flash.Lib.eval( objNamespace + objDataType ) != null && objDataType != "TextField" && objDataType != "MovieClip" && objDataType != "Button" )
						//{Reflect.setField( obj, objIdenifier, Reflect.createInstance( flash.Lib.eval( objNamespace + objDataType ), [] ) );}

						
					//-------------------------------------------------------------------------
					// Text Based XML Nodes
					//-------------------------------------------------------------------------
						if( XMLNodeType == 1 )
						{
							if( objDataType == "Number" )
							{
								addItem( obj, objIdenifier, Number( String( currentNode.childNodes ) ) );
							}
							else if( objDataType == "Boolean" )
							{
								addItem( obj, objIdenifier, ( String( currentNode.childNodes ).toLowerCase() == "true" ) ? true : false );
							}
							else if( objDataType == "String" )
							{
								addItem( obj, objIdenifier, String( currentNode.childNodes ) );
							}
							else if ( objDataType == "Array" )
							{
								var arrPos : Number = addItem( obj, objIdenifier, new Array() );
								deserializeRecursion( currentNode, recursion( arrPos, obj, objIdenifier ) );
							}
							else if ( objDataType == "Object" )
							{
								var arrPos : Number = addItem( obj, objIdenifier, {} );
								deserializeRecursion( currentNode, recursion( arrPos, obj, objIdenifier ) );
							}
							else trace( "unknown: " + objDataType );
						}
				}
		}
	}
	
	public static function addItem( obj : Object, id : String, val ) : Number
	{
		if ( obj instanceof Array )
		{
			obj.push( val );
			return obj.length - 1;
		}
		else
		{
			obj[ id ] = val;
			return -1;
		}
	}
	
	public static function recursion( arrPos, obj, objIdenifier ) : Object
	{
		if ( arrPos != -1 )
			return obj[ arrPos ];
		else
			return obj[ objIdenifier ];
	}
	
}