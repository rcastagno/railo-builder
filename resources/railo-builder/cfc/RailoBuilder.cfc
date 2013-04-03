component {


	this.settings	= {

		  buildType 	: 'primary'
		, compilerArgs	: '-1.6 -nowarn'
		, password		: 'server'

		, dstDir		: ''
		, srcDir		: ''
		, resDir 		: ''

		, jettyVersion	: 'jetty-8.1.9'
//		, jreVersion	: 'jre-1.7.0_15'
//		, jreVersion	: 'jre-1.6.0_41'

		, isDebug 		: true
	}


	this.buildTypes	= {

		  patch			:  1
		, primary		:  3
		, jar			:  7
		, war			: 15
		, express		: 31
		, installer		: 63
		, all			: 63
	};


	dirCopyFilters = {

		  ExcDotPrefix  : function( name, type ) { return left( name, 1 ) != '.'; }
		, ExcJavaSource : function( name, type ) { 
			if ( left( name, 1 ) == '.' ) return false; 
			if ( type == 'dir' ) return true; 
			return ( right( name, 5 ) != ".java" && right( name, 3 ) != ".rc" );
		}
	};

	utils = new BuilderUtils();

	
	public function init( settings={} ) {

		structAppend( this.settings, settings );

		if ( !len( this.settings.dstDir ) )
			throw( type="InvalidArgument", message="the required arg settings.dstDir was not passed" );

		if ( !len( this.settings.srcDir ) || !directoryExists( this.settings.srcDir & "/railo-cfml" ) || !directoryExists( this.settings.srcDir & "/railo-java" ) )
			throw( type="InvalidArgument", message="the required arg settings.srcDir was not passed or does not point to the Railo source directory" );

		this.settings.srcDir = fixDir( this.settings.srcDir );
		this.settings.dstDir = fixDir( this.settings.dstDir );

		dirs = {

			  src 		= this.settings.srcDir
			, core		= this.settings.srcDir & "/railo-java/railo-core/src"
			, lib		= this.settings.srcDir & "/railo-java/libs"
			, loader	= this.settings.srcDir & "/railo-java/railo-loader/src"
			, admin		= this.settings.srcDir & "/railo-cfml/railo-admin"

			, dst 		= this.settings.dstDir
			, tmpCoreSrc= this.settings.dstDir & "/__railo-core-src"
			, tmpCoreBin= this.settings.dstDir & "/__railo-core-bin"
			, tmpLoadBin= this.settings.dstDir & "/__railo-loader-bin"
			, tmpRA		= this.settings.dstDir & "/__railo-context-ra"
			, tmpJar	= this.settings.dstDir & "/__railo-jar-distro/railo-{version}-jars"
			, tmpWar	= this.settings.dstDir & "/__railo-war-distro"
			, tmpExpress= this.settings.dstDir & "/__railo-express-jetty"
			, tmpExpressT= this.settings.dstDir & "/__railo-express-tomcat"
			
			, server 	= getDirectoryFromPath( expandPath( '{railo-server}' ) )
		};

		if ( len( this.settings.resDir ) ) {

			dirs.resources = fixDir( this.settings.resDir );
		} else {

			dirs.resources = this.settings.srcDir & '/railo-builder/resources';
		}


		dirs.rsrcWar 	= dirs.resources & "/railo-war";
		dirs.rsrcExpress= dirs.resources & "/railo-express";
		dirs.rsrcJRE 	= dirs.rsrcExpress & '/jre';

		for ( var key in dirs ) {					// remove File.separator from end of path
	
			dirs[ key ] = fixDir( dirs[ key ] );
		}

		paths = {

			  core 		= dirs.dst & "/{version}/{version}.rc"
			, notes		= dirs.dst & "/{version}/{version}.txt"
			, primary 	= dirs.dst & "/railo.jar"
			, jarDistro = dirs.dst & "/railo-{version}-jars.zip"
			, warDistro = dirs.dst & "/railo-{version}.war"
			, expressJ 	= dirs.dst & "/railo-express-{version}-{jre}.zip"
			, expressT 	= dirs.dst & "/railo-express-{version}-tomcat-{jre}.zip"
		};


		if ( len( this.settings.buildType ) ) {

			if ( structKeyExists( this.buildTypes, this.settings.buildType ) ) {

				this.buildType = this.buildTypes[ this.settings.buildType ];
			} else {

				throw( type="InvalidArgument", message="[#this.settings.buildType#] is not a valid build type. allowed build types: #listSort( structKeyList( this.buildTypes ), 'text' )#" );
			}
		}

		if ( this.settings.compilerArgs NCT "-extdirs" )
			this.settings.compilerArgs &= ' -extdirs "#dirs.lib##server.separator.path##expandPath( "/WEB-INF/railo/lib/compile" )#"';
		
		return this;
	}


	public function Build() {

		var t1 = getTickCount();

		_echo( "src: #dirs.src#; dst: #dirs.dst#" );
		_echo( "resources: #dirs.resources#" );

		var system = createObject( 'java', 'java.lang.System' );

		var javaVersion = system.getProperty( 'java.version' );
		var javaVersionMaj = listFirst( javaVersion, '.' ) & '.' & listGetAt( javaVersion, 2, '.' );

		_echo( "Railo #server.railo.version# running in Java #javaVersion#" );

		if ( javaVersionMaj != "1.6" )
			_echo( "<b class='error'>Building Railo requires Java 1.6</b> - You might experience errors with version #javaVersionMaj#" );


		this.versionInfo= utils.ExtractVersionInfo( dirs.core & "/railo/runtime/Info.ini" );
		

		if ( !isDefined( "this.versionInfo.number" ) || !len( this.versionInfo.number ) )
			throw( type="InvalidVersion", message="failed to extract version from " & dirs.core & "/railo/runtime/Info.ini" );


		this.version 	= this.versionInfo.number;

		this.versionInfo.versionId 	= replace( this.version, '.', '', 'all' ) & ':' & parseDateTime( this.versionInfo.releaseDate ).getTime();

		this.versionInfo.versionBig	= listFirst( this.version, '.' ) & '.' & listGetAt( this.version, 2, '.' );
		

		_echo( "Build #ucase( this.settings.buildType )#; version: <b>#this.version#</b>" );

		populateValues( dirs, '{version}', this.version );
		
		populateValues( paths, '{version}', this.version );


		deleteTempDirectories();				// delete temp folders if exist from previous run


		var lastPatch = getLastInstalledPatch();

		if ( listLast( lastPatch, '.' ) == '999' ) {

			_echo( "temporary patch exists at #dirs.server#/patches/#lastPatch#.rc" );
		}


		var isNewBuildRequiredForRA = false;

		try {

			compileAdmin();
			
		} catch( any ex ) {

			isNewBuildRequiredForRA = true;

			// TODO: buildCore( true ); patch with version .999; restart Railo; compileAdmin(); delete temp patch;

			rethrow;
		}

		buildCore();

		if ( isBuildRequired( 'primary' ) ) {

			buildPrimary();

			if ( isBuildRequired( 'jar' ) ) {


				this.webXmlDefs = fileRead( dirs.resources & '/web-servlet-definitions.xml' );


				buildJarDistro();

				if ( isBuildRequired( 'war' ) ) {

					buildWarDistro();
				}

				if ( isBuildRequired( 'express' ) ) {

					buildExpressJetty();

	//				buildExpressTomcat();
				}

				if ( isBuildRequired( 'installer' ) ) {

					// TODO:
				}
			}
		}

		_echo( "Deleting temporary folders..." );

		deleteTempDirectories();

		_echo( "Done in #numberFormat( ( getTickCount() - t1 ) / 1000, '9,999.9' )# seconds" );
	}


	/** creates the v.e.r.sion.rc file, e.g. 4.0.0.123.rc */
	function buildCore( boolean excludeRa=false ) {
	
		try {
		
			_echo( "Compile Railo Core..." );
			
			// copy railo-core/src to temp directory and build there so that we don't "dirty" the src folder			
			utils.DirCopy( dirs.core, dirs.tmpCoreSrc, dirCopyFilters.ExcDotPrefix );

			var compileLog = utils.Compile( dirs.tmpCoreSrc, dirs.tmpCoreBin, this.settings.compilerArgs & " -sourcepath #dirs.loader#[-d none]" );
			
			if ( find( "ERROR", compileLog ) || find( "java.lang.NullPointerException", compileLog ) ) {

				throw( type="CompilationError", message="Compilation Error(s) encountered. <pre>#compileLog#</pre>" );
			}

			if ( this.Settings.isDebug )
				_echo( "<pre>#trim( compileLog )#</pre>" );

			_echo( "Compiled Railo Core version to #toDisplayDir( dirs.tmpCoreBin )#" );
			
			_echo( "Copy resources from #toDisplayDir( dirs.core )#" );
			
			utils.DirCopy( dirs.core, dirs.tmpCoreBin, dirCopyFilters.ExcJavaSource );

			if ( !excludeRa ) {

				utils.DirCopy( dirs.tmpRA, dirs.tmpCoreBin, dirCopyFilters.ExcDotPrefix );
			}


			_echo( "Package #toDisplayDir( dirs.tmpCoreBin )#" );

			deleteDirectory( getDirectoryFromPath( paths.core ) );
			directoryCreate( getDirectoryFromPath( paths.core ) );
			
			zip action="zip" file=paths.core source=dirs.tmpCoreBin;

			var fileInfo = getFileInfo( paths.core );
			
			_echo( "Built core.rc to <b>#paths.core#</b> (#numberFormat( fileInfo.size / 1048576, '9.99' )#mb)" );

			_echo( "Retrieving release notes from JIRA for version #this.version#" );

			var releaseNotes = utils.GetVersionReleaseNotes( this.version );

			if ( len( releaseNotes ) ) {

				fileWrite( paths.notes, releaseNotes );

				_echo( "Created release notes at #paths.notes#" );
			} else {

				_echo( "Failed to retrieve release notes from JIRA for version #this.version#" );
			}

		} catch ( ex ) {
		
			_echo( "<b class='error'>Failed</b> #ex.message#" );
			
			result.error = ex;

			rethrow;
		}
		
		return true;
	}


	function buildExpressTomcat() {
		
		var resourceTomcat= dirs.rsrcExpress & '/tomcat';
		
		var resourceScript= dirs.rsrcExpress & '/tomcat-res';

		var expressNameTemplate = replace( replace( paths.expressT, '#dirs.dst#/', '' ), '.zip', '' );

		var expressName = replace( expressNameTemplate, '{jre}', 'nojre', 'all' );

		var tmpExpressDir = dirs.tmpExpressT & '/' & expressName;

		utils.DirCopy( resourceTomcat, tmpExpressDir, dirCopyFilters.ExcDotPrefix );

		utils.DirCopy( dirs.resources & '/railo-world', tmpExpressDir & '/webapps/www', dirCopyFilters.ExcDotPrefix );

		utils.DirCopy( dirs.tmpJar, tmpExpressDir & '/lib/ext', dirCopyFilters.ExcDotPrefix );

		utils.replaceInFile( tmpExpressDir & '/conf/web.xml', '<!-- {web-servlet-definitions.xml} !-->', this.webXmlDefs );

		compress( "zip", tmpExpressDir, '#dirs.dst#/#expressName#.zip' );

		_echo( "Built Express Tomcat distro at <b>#dirs.dst#/#expressName#.zip</b>" );
		
		compress( "tgz", tmpExpressDir, '#dirs.dst#/#expressName#.tar.gz' );
		
		_echo( "Built Express Tomcat distro at <b>#dirs.dst#/#expressName#.tar.gz</b>" );
	}
	

	/** builds Railo-Express a-la-Jetty */
	function buildExpressJetty() {

		var resourceJetty = dirs.rsrcExpress & '/' & this.settings.jettyVersion;
		var resourceScript= dirs.rsrcExpress & '/jetty-res';

		var expressNameTemplate = replace( replace( paths.expressJ, '#dirs.dst#/', '' ), '.zip', '' );

		var expressName = replace( expressNameTemplate, '{jre}', 'nojre', 'all' );

		var tmpExpressDir = dirs.tmpExpress & '/' & expressName;

		utils.DirCopy( resourceJetty, tmpExpressDir, dirCopyFilters.ExcDotPrefix );

		for ( var dir in [ 'contexts-available', 'contexts', 'javadoc', 'webapps' ] ) {

			deleteDirectory( tmpExpressDir & '/' & dir );
		}

		for ( var file in [ 'start', 'start.bat', 'start.ini', 'stop', 'stop.bat', '_-Railo-Getting-Started-_.html' ] ) {

			fileCopy( resourceScript & '/' & file, tmpExpressDir & '/' & file );

			_echo( "Copy file #toDisplayDir( resourceScript & '/' & file )# to #toDisplayDir( tmpExpressDir & '/' & file )#" );
		}

		utils.DirCopy( resourceScript & '/contexts', tmpExpressDir & '/contexts' );
		utils.DirCopy( resourceScript & '/etc', tmpExpressDir & '/etc' );

		utils.DirCopy( dirs.resources & '/railo-world', tmpExpressDir & '/webapps/www', dirCopyFilters.ExcDotPrefix );
		utils.DirCopy( dirs.tmpJar, tmpExpressDir & '/lib/ext', dirCopyFilters.ExcDotPrefix );

		utils.replaceInFile( tmpExpressDir & '/etc/webdefault.xml', '<!-- {web-servlet-definitions.xml} !-->', this.webXmlDefs );

		compress( "zip", tmpExpressDir, '#dirs.dst#/#expressName#.zip' );
		_echo( "Built Express distro at <b>#dirs.dst#/#expressName#.zip</b>" );
		
		compress( "tgz", tmpExpressDir, '#dirs.dst#/#expressName#.tar.gz' );
		_echo( "Built Express distro at <b>#dirs.dst#/#expressName#.tar.gz</b>" );
		

		/* Express macosx */
		expressName = replace( expressNameTemplate, '{jre}', 'macosx', 'all' );

		fileDelete( tmpExpressDir & "/start.bat" );
		fileDelete( tmpExpressDir & "/stop.bat" );

		var tmpExpressOld = tmpExpressDir;

		tmpExpressDir = dirs.tmpExpress & '/' & expressName;

		_echo( "Rename #toDisplayDir( tmpExpressOld )# to #toDisplayDir( tmpExpressDir )#");

		directoryRename( tmpExpressOld, tmpExpressDir );

		compress( "zip", tmpExpressDir, '#dirs.dst#/#expressName#.zip' );
		_echo( "Built Express distro at <b>#dirs.dst#/#expressName#.zip</b>" );

		var arrJREs = directoryList( dirs.rsrcJRE, false, 'name', 'jre*.zip', 'name desc' );

		var jreVer = arrJREs[ 1 ];

		jreVer = listGetAt( jreVer, ( left( jreVer, 4 ) == 'jre-' ? 2 : 1 ), '-' );

		_echo( "Continue to build Railo-Express with JREs version #jreVer#" );


		loop list="Linux32,Linux64,Win32,Win64" index="Local.jreDistro" {

			var isWindows = ( left( jreDistro, 1 ) == 'W' );

			expressName = replace( expressNameTemplate, '{jre}', 'jre-' & lcase( jreDistro ), 'all' );

			_echo( "Building #expressName#..." );

			var distroFullPath = '';

			if ( isWindows ) {

				distroFullPath = '#dirs.dst#/#expressName#.zip';

				deleteFile( tmpExpressDir & "/start" );
				deleteFile( tmpExpressDir & "/stop" );

				fileCopy( resourceScript & "/start-jre.bat", tmpExpressDir & "/start.bat" );
				fileCopy( resourceScript & "/stop-jre.bat",  tmpExpressDir & "/stop.bat" );
			} else {

				distroFullPath = '#dirs.dst#/#expressName#.tar.gz';

				deleteFile( tmpExpressDir & "/start.bat" );
				deleteFile( tmpExpressDir & "/stop.bat" );

				fileCopy( resourceScript & "/start-jre",     tmpExpressDir & "/start" );
				fileCopy( resourceScript & "/stop-jre",      tmpExpressDir & "/stop" );
			}

			tmpExpressOld = tmpExpressDir;

			tmpExpressDir = dirs.tmpExpress & '/' & expressName;

			_echo( "Rename #toDisplayDir( tmpExpressOld )# to #toDisplayDir( tmpExpressDir )#");

			directoryRename( tmpExpressOld, tmpExpressDir );		// rename dir so that we'll have a root dir with the correct name in the zip archive

			var tmpExpressJreDir = tmpExpressDir & '/jre';

			deleteDirectory( tmpExpressJreDir );					// delete jre if exists from previous iteration

			var resJreArchive = dirs.rsrcJRE & '/#jreVer#-#lcase( jreDistro )#.zip';

			_echo( "Extracting #toDisplayDir( resJreArchive )#" );					

			zip action="unzip" file=resJreArchive destination="#tmpExpressJreDir#";		// extract jre to dist/jre

			if ( isWindows ) {

				compress( "zip", tmpExpressDir, distroFullPath );
			} else {

				compress( "tgz", tmpExpressDir, distroFullPath );
			}

			_echo( "Built Express with JRE #jreDistro# distro at <b>#distroFullPath#</b>" );
		
		}
		
	}


	/** builds a WAR archive */	
	function buildWarDistro() {
	
		try {
		
			_echo( "Build WAR distro..." );
			
			utils.DirCopy( dirs.rsrcWar, dirs.tmpWar, dirCopyFilters.ExcDotPrefix );

			utils.replaceInFile( dirs.tmpWar & '/WEB-INF/web.xml', '<!-- {web-servlet-definitions.xml} !-->', this.webXmlDefs );

			utils.DirCopy( dirs.resources & '/railo-world', dirs.tmpWar & '/', dirCopyFilters.ExcDotPrefix );

			utils.DirCopy( dirs.tmpJar, dirs.tmpWar & "/WEB-INF/lib", dirCopyFilters.ExcDotPrefix );
			
			zip action="zip" file=paths.warDistro source=dirs.tmpWar;
			
			_echo( "Built WAR distro at <b>#paths.warDistro#</b>" );
			
		} catch ( ex ) {
		
			_echo( "<b class='error'>Failed</b> #ex.message#" );
		
			result.error = ex;

			rethrow;
		}
		
		return true;
	}


	/** builds a zip and tar archives of jars */
	function buildJarDistro() {
	
		try {
		
			_echo( "Build JAR distro..." );

			utils.DirCopy( dirs.lib, dirs.tmpJar, dirCopyFilters.ExcDotPrefix );
			
			/** delete jars required by Eclipse for Railo-Debug but shouldn't be deployed */
			if ( fileExists( "#dirs.tmpJar#/javax.servlet.jar" ) )
				fileDelete( "#dirs.tmpJar#/javax.servlet.jar" );

			if ( fileExists( "#dirs.tmpJar#/org.mortbay.jetty.jar" ) )
				fileDelete( "#dirs.tmpJar#/org.mortbay.jetty.jar" );
			

			utils.DirCopy( dirs.resources & '/railo-jars', dirs.tmpJar, dirCopyFilters.ExcDotPrefix );

			fileCopy( dirs.resources & '/License.txt', dirs.tmpJar & '/License.txt' );

			utils.replaceInFile( dirs.tmpJar & '/web.xml.sample', '<!-- {web-servlet-definitions.xml} !-->', this.webXmlDefs );
			
			fileCopy( paths.primary, "#dirs.tmpJar#/railo.jar" );
			
			compress( "zip", dirs.tmpJar, paths.jarDistro );
			
			_echo( "Built JAR distro at <b>#paths.jarDistro#</b>" );
			
			var tarPath = replace( paths.jarDistro, ".zip", ".tar.gz" );
			
			compress( "tgz", dirs.tmpJar, tarPath );
			
			_echo( "Built JAR distro at <b>#tarPath#</b>" );
			
		} catch ( ex ) {
		
			_echo( "<b class='error'>Failed</b> #ex.message#" );
			
			result.error = ex;

			rethrow;
		}
		
		return true;
	}


	/** compiles railo-loader java files */
	function buildPrimary() {
	
		try {
		
			_echo( "Compile Railo Loader..." );
			
			var compileLog = utils.Compile( dirs.loader, dirs.tmpLoadBin, this.settings.compilerArgs );

			if ( find( "ERROR", compileLog ) || find( "java.lang.NullPointerException", compileLog ) ) {

				throw( type="CompilationError", message="Compilation Error(s) encountered. <pre>#compileLog#</pre>" );
			}

//			_echo( "<pre>#compileLog#</pre>" );
			
			_echo( "Compiled #toDisplayDir( dirs.loader )# to #toDisplayDir( dirs.tmpLoadBin )#" );
			
			_echo( "Copy resources from #toDisplayDir( dirs.loader )#" );
			
//			copyResources( dirs.loader, dirs.tmpLoadBin, '*.java,*.rc' );
			utils.DirCopy( dirs.loader, dirs.tmpLoadBin, dirCopyFilters.ExcJavaSource );
			
			_echo( "Copy core from #toDisplayDir( paths.core )# to #toDisplayDir( dirs.tmpLoadBin )#/core/core.rc" );
		
			directoryCreate( "#dirs.tmpLoadBin#/core" );		
			fileCopy( paths.core, "#dirs.tmpLoadBin#/core/core.rc" );

			file action="write" file="#dirs.tmpLoadBin#/railo/version" output=this.versionInfo.versionId;
		
			zip action="zip" file=paths.primary source=dirs.tmpLoadBin;

			var fileInfo = getFileInfo( paths.primary );

			_echo( "Built railo.jar from #toDisplayDir( dirs.tmpLoadBin )# to <b>#paths.primary#</b> (#numberFormat( fileInfo.size / 1048576, '9.99' )#mb)" );
			
		} catch ( ex ) {
		
			_echo( "<b class='error'>Failed</b> #ex.message#" );
			
			rethrow;
		}
		
		return true;
	}


	/** creates the railo-context.ra */
	function compileAdmin() {
	
		_echo( "Compile Admin from #toDisplayDir( dirs.admin )#" );

		_echo( "<b class='warning'>Attention: if Admin pages use BIFs that were added after #Server.railo.version#</b> the compilation will go through but you will get runtime errors when accessing those pages!  Be sure to run the Builder in a Railo environment that contains all the code used by the Admin." );
		
		var tempVirtualDir = "/railo-context-compiled";

		try {
		
			admin action="updateMapping" type="web" password=this.settings.password virtual=tempVirtualDir
				physical="#dirs.admin#"
				primary="physical" 
				trusted=false
				archive="";

			admin action="createArchive" type="web" password=this.settings.password virtual=tempVirtualDir
				file="#dirs.tmpRA#/resource/context/railo-context.ra";


			utils.DirCopy( "#dirs.admin#/admin",     "#dirs.tmpRA#/resource/context/admin",     dirCopyFilters.ExcDotPrefix );
			utils.DirCopy( "#dirs.admin#/templates", "#dirs.tmpRA#/resource/context/templates", dirCopyFilters.ExcDotPrefix );
			
			_echo( "Built railo-context.ra to <b>#dirs.tmpRA#/railo-context.ra</b>" );

		} catch ( ex ) {
		
			_echo( "<b class='error'>Failed</b> #ex.message#" );
			
			result.error = ex;

			rethrow;
		}
		
		return true;
	}

	
	/** performs a find/replace in struct values */
	function populateValues( map, find, replace ) {

		for ( var key in map ) {				// fix version
	
			if ( map[ key ] CT find )
				map[ key ] = replace( map[ key ], find, replace, 'all' );
		}
	}


	/** returns the latest instaelled patch file from #dirs.server#/patches */
	function getLastInstalledPatch() {

		directory directory=dirs.server & '/patches' name="Local.qDir" filter="*.rc";

		var result = replace( qDir.name[ qDir.recordCount ], '.rc', '' );

		return result;
	}


	/** translates directory for display purposes */
	function toDisplayDir( string dir ) {
	
		dir = fixDir( dir );
		
		if ( findNoCase( dirs.src, dir ) == 1 )
			return replace( dir, dirs.src, '{src}' );
		
		if ( findNoCase( dirs.dst, dir ) == 1 )
			return replace( dir, dirs.dst, '{dst}' );

		if ( findNoCase( dirs.resources, dir ) == 1 )
			return replace( dir, dirs.resources, '{res}' );
			
		return dir;
	}



	function isBuildRequired( string buildName ) {

		return this.buildType >= this.buildTypes[ buildName ];
	}


	/** replaces all path separator to system path separator and ensures that last character is not a separator */
	function fixDir( dir ) {

		/*/
		if ( server.separator.file == '\' && dir CT '/'	) {
		
			dir = replace( dir, '/', server.separator.file, 'all' );
		} else if ( server.separator.file == '/' && dir CT '\'	) {
		
			dir = replace( dir, '\', server.separator.file, 'all' );
		}	//*/

		if ( dir CT '\' )
			dir = replace( dir, '\', '/', 'all' );
	
		if ( right( dir, 1 ) == '/' )
			return left( dir, len( dir ) - 1 );

		return dir;
	}

	
	/** deletes all (temp) folders that start with __ */
	function deleteTempDirectories() {
	
		directory action="list" directory=dirs.dst name="Local.qDir";
		
		loop query="qDir" {
		
			if ( type == "dir" && left( name, 2 ) == "__" )
				deleteDirectory( "#directory#/#name#" );
		}
	}
	
	
	/** deletes a folder if it exists */
	function deleteDirectory( string path ) {
	
		if ( directoryExists( path ) ) {

			_echo( "Deleting directory #toDisplayDir( path )#" );

			directoryDelete( path, true );
		}
	}
	

	/** deletes a file if it exists */
	function deleteFile( string path ) {

		if ( fileExists( path ) ) {

			_echo( "Deleting file #toDisplayDir( path )#" );

			fileDelete( path );
		}
	}

	
	function _echo( string ) {
	
		echo( "<p><span class='ts'>#listGetAt( now(), 2, "'" )#</span> #string#" );
		echo( "<script>window.scrollBy( 0, 9999 );</script>" );
		flush;
	}


	/** a remote function for use with ajax to validate directories */
	remote function validateDirs() returnFormat="JSON" {

		var result = { 

			  'srcDirValid': false
			, 'resDirValid': false
			, 'messsage': "" 
			, 'version': ""
		};

		var srcDir = fixDir( URL.srcDir );

		result.srcDirValid = directoryExists( srcDir );

		result.srcDirValid = result.srcDirValid && directoryExists( srcDir & "/railo-cfml" );
		result.srcDirValid = result.srcDirValid && directoryExists( srcDir & "/railo-java" );

		if ( result.srcDirValid ) {

			var versionInfo = utils.ExtractVersionInfo( srcDir & "/railo-java/railo-core/src/railo/runtime/Info.ini" );
			result.versionFile = srcDir & "/railo-java/railo-core/src/railo/runtime/Info.ini";

			result.version = versionInfo.number;

			param name="URL.resDir" default="";

			var resDir = URL.resDir;

			if ( !len( resDir ) )
				resDir = srcDir & this.settings.resDir;

			result.resDirValid = directoryExists( resDir & "/railo-express" );

			if ( !result.resDirValid )
				result.message = "Resources not found at #resDir#";
		}
		
		return result;
	}


}