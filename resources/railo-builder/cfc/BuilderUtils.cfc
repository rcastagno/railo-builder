component {


	java = {

		  PrintWriter	: createObject( 'java', 'java.io.PrintWriter' )
		, StringWriter	: createObject( 'java', 'java.io.StringWriter' )

		, BatchCompiler	: createObject( 'java', 'org.eclipse.jdt.core.compiler.batch.BatchCompiler' )
	};



	/**
	 * calls the BatchCompiler.compile() methods with the passed args
	 * 
	 * @param commandLine - the commandLine that is passed to the BatchCompiler
	 */
	function CompileCommand( commandLine ) {
	
		var out = java.StringWriter.init();
		
		var outWriter = java.PrintWriter.init( out, true );
		
		outWriter.println( "Compiler Command: " & commandLine );
		

		java.BatchCompiler.compile( commandLine, outWriter, outWriter, javaCast( 'null', '' ) );

		
		outWriter.println( "Done." );
		
		var result = out.getBuffer().toString().trim();
		
		return result;
	}
	
	
	/**
	 * calls the BatchCompiler.compile() methods with the passed args
	 * 
	 * @param srcDirectory - the directory with the source .java files 
	 * @param dstDirectory - the directory to save the .class files to
	 * @param compilerArgs - args that will be passed to the BatchCompiler, e.g. "-nowarn -1.6"
	 */
	function Compile( String srcDirectory, String dstDirectory, String compilerArgs ) {
		
		var commandLine = "#compilerArgs# -d #dstDirectory# #srcDirectory#";
		
		return CompileCommand( commandLine );
	}



	/** 
	* performs a recursive copy and allows to use a UDF as a filter that determines whether a file/dir 
	* should be copied or not.
	* 
	* it returns an array of strings, one for each file that was copied.
	* 
	* @srcDir - full path of source dir
	* @dstDir - full path of destination dir
	* @filter - a function with the following signature: boolean function( name, type ); type can be 'dir' or 'file'
	* @arrLog - used as reference object when calling recursively. do not pass a value.
	*/
	function DirCopy( required srcDir, required dstDir, filter="", arrLog=[] ) {

		var qContents = directoryList( srcDir, false, "query", "", "type desc, name" );		// breadth first

		if ( !directoryExists( dstDir ) ) 
			directoryCreate( dstDir, true );

		loop query=qContents {

			if ( isSimpleValue( filter ) || filter( name, type ) ) {

				if ( type == 'file' ) {

					fileCopy( srcDir & '/' & name, dstDir & '/' & name );

					arrLog.append( "copied #srcDir#/#name# to #dstDir#/#name#" );
				} else if ( type == 'dir' ) {

					DirCopy( srcDir & '/' & name, dstDir & '/' & name, filter, arrLog );	// recurse
				}
			}
		}

		return arrLog;
	}


	function CalcFileHash( required String filename, boolean createFile=false, boolean isBinary=true, String algorithm="md5" ) {

		var contents = 0;

		try {

			if ( isBinary ) {

				contents = fileReadBinary( filename );
			} else {

				contents = fileRead( filename );
			}

			var result = hash( contents, algorithm );

			if ( createFile )
				fileWrite( filename & '.' & lcase( algorithm ), result );

			return result;

		} catch ( ex ) {

			return ex.message;
		}
	}
	

	/** extracts the version number from Info.ini file */
	function ExtractVersionInfo( string path ) {

		var result = {};

		try {
		
			var props = listToArray( fileRead( path ), chr(10) );

			for ( var line in props ) {

				if ( listLen( line, '=' ) == 2 ) {

					var key = replace( trim( listFirst( line, '=' ) ), '-', '', 'all' );
					var val = trim( listLast( line, '=' ) );

					result[ key ] = val;
				}
			}
		} catch ( any ex ) {

			result.number = "";
		}

		return result;
	}

	
	function CompareArchives( required String archive1, required String archive2 ) {
	
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
		
		var arc1 = ConvertQueryToStruct( Local.qContents1, 'name' );
		var arc2 = ConvertQueryToStruct( Local.qContents2, 'name' );

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


	/** reads the contents of a file, performs a replace on it, and saves the file */
	function ReplaceInFile( string path, string find, string repl ) {

		var curFile = fileRead( path );

		var updFile = replaceNoCase( curFile, find, repl, 'all' );

		if ( updFile != curFile ) {

			fileWrite( path, updFile );
		}
	}


	/** returns version information from JIRA */
	function GetVersionInfoFromJira( string version="" ) {

		var empty = { id: 0, name: "", released: false, self: "" };

		try {

			http url="https://issues.jboss.org/rest/api/2/project/RAILO/versions" result="Local.http";

			var arr = deserializeJSON( http.fileContent );

			var result = {};

			for ( var ai in arr ) {

				var v = ai.name CT '(' ? listGetAt( ai.name, 2, "()" ) : ai.name;

				if ( len( arguments.version ) && v == arguments.version )
					return ai;

				result[ v ] = ai;
			}

			if ( len( arguments.version ) )
				return empty;

			return result;

		} catch( ex ) {

			return empty;
		}
	}


	/** retruns the Release Notes from JIRA
	* @version - the Railo version, e.g. 4.0.3.005
	*/
	function GetVersionReleaseNotes( string version ) {

		var urlTemplate = "https://issues.jboss.org/secure/ReleaseNote.jspa?version={version-id}&styleName=Text&projectId=12310683";

		var versionInfo = GetVersionInfoFromJira( version );

		if ( versionInfo.id ) {

			try {

				http url=replace( urlTemplate, "{version-id}", versionInfo.id ) result="Local.http";

				var raw = http.fileContent;

				var pos = find( "</textarea>", raw );

				raw = left( raw, pos - 1 );

				pos = find( "<textarea", raw );

				raw = mid( raw, pos );

				pos = find( ">", raw );

				raw = trim( mid( raw, pos + 1 ) );

				var arr = [];

				loop list=raw delimiters="#chr(13)##chr(10)#" index="Local.li" {

					pos = find( "[RAILO-", li );

					if ( pos )
						arr.append( trim( mid( li, pos ) ) );
				}

				var result = arrayToList( arr, "#chr(13)##chr(10)#" );

				return result;
			} catch ( ex ) {

				rethrow;
			}
		}
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
	 * converts a Query to a Struct of Structs
	 **/
	function ConvertQueryToStruct( required Query query, required String key ) {

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