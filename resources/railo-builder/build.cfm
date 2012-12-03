<cfset pageTitle = "Build Railo from Source">


<cfinclude template="header.cfml">


<cfoutput>

	<form action="build-railo.cfm">
	
		<fieldset class="wrapper">
			<legend>#pageTitle#</legend>

			<div class="clearfix field">
				<div class="label">Source Directory:</div>
				<div><input type="text" id="srcDir" name="srcDir" value="#cookie.rb_srcDir#" class="path"></div>
				<div class="hint">directory that contains railo-cfml and railo-java source code folders</div>
				<br/>
				<div class="label">Destination Directory:</div>
				<div><input type="text" id="dstDir" name="dstDir" value="#cookie.rb_dstDir#" class="path"></div>
				<div class="hint">directory in which to save the built files</div><br/>
				<div class="label">Resources Directory:</div>
				<div><input type="text" id="resDir" name="resDir" value="#cookie.rb_resDir#" class="path"></div>
				<div class="hint">directory with resources for WAR, Express, and other distros</div>
			</div>
			<div class="clearfix field">
				<div class="label">Admin Password:</div>
				<div><input type="text" name="password" value="#cookie.rb_password#"></div>
				<div class="hint">clear text password - for development environment only!</div>
			</div>
			<div class="clearfix field">
				<div class="label">Build Type:</div>
				<div>
					<label title="v.e.r.sion.rc"><input type="radio" name="build" value="patch" checked="checked"> Patch (v.e.r.sion.rc)</label>
					<label title="railo.jar"><input type="radio" name="build" value="primary"> Primary (railo.jar)</label>
					<label title="JAR and WAR distributions"><input type="radio" name="build" value="all"> All</label>
				</div>
			</div>
			<div style="text-align: center">
				<input type="submit" value="Build Railo" class="primaryButton">
			</div>

		</fieldset>
	</form>

</cfoutput>


<cfsavecontent variable="Request.js">


	<cfoutput>

		var server = { 
			  host: '#CGI.SERVER_NAME#'
			, port: #CGI.SERVER_PORT#
		}
	</cfoutput>
	

	server.url = "http://" + server.host + ":" + server.port + "/cfc/RailoBuilder.cfc";

	var isResDirRequired = false;

	var validationResult = {};


	function getDir( type ) {

		var result = $( '#' + type + 'Dir' ).val();

		if ( "/\\".indexOf( result.substr( result.length - 1, 1 ) ) > -1 )
			result = result.substr( 0, result.length - 1 );

		return result;
	}


	function updateUI() {

		if ( !isResDirRequired ) {

			$( '#resDir' ).removeClass( 'invalid' ).removeClass( 'valid' );
		}

		if ( validationResult.srcDirValid ) {

			$( '#srcDir' ).removeClass( 'invalid' ).addClass( 'valid' );

			if ( isResDirRequired ) {

				$( '#resDir' ).removeClass( validationResult.resDirValid ? 'invalid' : 'valid' ).addClass( validationResult.resDirValid ? 'valid' : 'invalid' );
			}
		} else {

			$( '#srcDir' ).removeClass( 'valid' ).addClass( 'invalid' );

			if ( isResDirRequired )
				$( '#resDir' ).removeClass( 'valid' ).addClass( 'invalid' );
		}
	}


	function validateDirs() {

		$.getJSON( 

			  server.url
			, { method: 'validateDirs', srcDir: getDir( 'src' ), resDir: getDir( 'res' ) }
			, function( data, textStatus, jqXHR ) { 

				validationResult = data;

				updateUI();
			} 
		);
	}


	$( function() {

		$( '#srcDir, #resDir' ).keyup( function(){ 

			validateDirs();
		} );


		$( 'input:radio[name=build]' ).change( function() {

			var selected = $( 'input:radio:checked[name=build]' ).val();

			switch ( selected ) {

				case "all":		// TODO: check resources folder
					isResDirRequired = true;
					break;

				default:
					isResDirRequired = false;
					break;
			}

			validateDirs();
		} );
	} );
</cfsavecontent>


<cfinclude template="footer.cfml">