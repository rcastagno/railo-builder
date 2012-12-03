component {


	function init() {

		return this;
	}

	
	function Compare( required String archive1, required String archive2 ) {
	
		try {
		
			zip action="list" file=archive1 name="Local.qContents1";
		} catch ( any ex ) {
		
			throw( "FileException", "Failed to open archive [#archive1#]. Make sure that the file exists and that it is a valid ZIP archive." );
		}
		
		try {
		
			zip action="list" file=archive2 name="Local.qContents2";
		} catch ( any ex ) {
		
			throw( "FileException", "Failed to open archive [#archive2#]. Make sure that the file exists and that it is a valid ZIP archive." );
		}
		
		var arc1 = convertQueryToStructArray( Local.qContents1, 'name' );
		var arc2 = convertQueryToStructArray( Local.qContents2, 'name' );

		var arrFiles1 = structKeyArray( arc1 );
		var arrFiles2 = structKeyArray( arc2 );

		arraySort( arrFiles1, 'textNoCase' );
		arraySort( arrFiles2, 'textNoCase' );
		
		var query = queryNew( "name, isSame, change, size, modified, size1, size2, modified1, modified2, crc1, crc2"
							, "varchar, boolean, varchar, int, double, int, int, varchar, varchar, int, int" );
		
		for ( var fname in arrFiles1 ) {
		
			queryAddRow( query );
			querySetCell( query, 'name', fname );	
		
			if ( structKeyExists( arc2, fname ) ) {
			
				var f1 = arc1[ fname ];
				var f2 = arc2[ fname ];
				
				var dSize = f2.size - f1.size;
				var dModified = f2.dateLastModified - f1.dateLastModified;
				
				if ( f1.type == f2.type && dSize == 0 && f1.crc == f2.crc ) {
				
					result.same[ fname ] = true;
					
					querySetCell( query, 'change', 'unchanged' );
					querySetCell( query, 'isSame', true );
					
				} else {	// comp.diff.size == 0 || dModified == 0
					
					var isSame = dSize == 0 && f1.crc == f2.crc;
					
					querySetCell( query, 'isSame', isSame );
					querySetCell( query, 'change', isSame ? '' : 'modified' );
					querySetCell( query, 'size', dSize == 0 ? '' : dSize > 0 ? 'larger' : 'smaller' );
					querySetCell( query, 'modified', dModified == 0 ? '' : dModified > 0 ? 'newer' : 'older' );
					querySetCell( query, 'modified1', listGetAt( f1.dateLastModified, 2, "'" ) );
					querySetCell( query, 'modified2', listGetAt( f2.dateLastModified, 2, "'" ) );
					querySetCell( query, 'size1', f1.size );
					querySetCell( query, 'size2', f2.size );
					querySetCell( query, 'crc1', f1.crc );
					querySetCell( query, 'crc2', f2.crc );
				}
				
			} else {	// structKeyExists( arc2, fname ) )
			
				var f1 = arc1[ fname ];
				
				querySetCell( query, 'change', 'removed' );
				querySetCell( query, 'isSame', false );
				querySetCell( query, 'size1', f1.size );
				querySetCell( query, 'modified1', f1.dateLastModified );
					
				result.removed[ fname ] = arc1[ fname ];
			}
		}
		
		for ( var fname in arrFiles2 ) {
		
			if ( !structKeyExists( arc1, fname ) ) {
				
				var f2 = arc2[ fname ];
				
				queryAddRow( query );
				querySetCell( query, 'isSame', false );
				querySetCell( query, 'name', fname );
				querySetCell( query, 'change', 'added' );
				querySetCell( query, 'size2', f2.size );
				querySetCell( query, 'modified2', f2.dateLastModified );
			}
		}
		
		var result = query;
		
		return result;
	}	
	

	/* TODO: add support for Directory; need to resolve CRC?
	function GetFileList( required String path ) {

		if ( fileExists( path ) || directoryExists( path ) ) {

			var fileInfo = getFileInfo( path );

			if ( fileInfo.type == file ) {

				zip action="list" file=archive1 name="Local.qDir";
			} else {

				directory action="list" directory=path name="Local.qDir" recurse="true";
			}
		} else {

			throw( "FileException", "[#path#] does not exist." );
		}
	}	//*/


	/**
	 * converts a Query Row (default row number is 1) to a Struct
	 **/
	function convertQueryToStructArray( required Query query, required String key ) {

		var result	= {};

		var arrCols	= listToArray( query.getColumnList( false ) );

		for ( var row = 1; row <= query.recordCount; row++ ) {
		
			var rowData = {};
		
			for ( var col in arrCols ) {

				rowData[ col ] = query[ col ][ row ];
			}
			
			result[ query[ key ][ row ] ] = rowData;
		}

		return result;
	}
	
	
}