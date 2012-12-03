<cfset pageTitle = "Compare Archives">


<cfinclude template="header.cfml">


<cfoutput>

	<cfif Request.isHttpPost>
		
		<cfparam name="archive1" default="">
		<cfparam name="archive2" default="">

		<cfset obj = new cfc.ZipDiff()>

		<cftry>

			<cfif !fileExists( archive1 ) || !fileExists( archive2 )>
				
				<cfthrow type="FileNotFound" message="at least one of the files ([#archive1#], [#archive2#]) specified was not found.  make sure that both files exist and are valid zip archives.">
			</cfif>

			<cfset fileInfo1 = getFileInfo( archive1 )>
			<cfset fileInfo2 = getFileInfo( archive2 )>

			<p>Comparing #fileInfo1.path# with #fileInfo2.path# 
				#fileInfo2.lastModified == fileInfo1.lastModified ? '' : fileInfo2.lastModified GT fileInfo1.lastModified ? '(newer)' : '(older)'#
				#fileInfo2.size == fileInfo1.size ? '' : fileInfo2.size GT fileInfo1.size ? '(larger)' : '(smaller)'#
			<p>This might take some time for large archives... Please wait...
			<cfflush>

			<cfset qCompare = obj.compare( archive1, archive2 )>

			<cfquery name="qDiff" dbtype="query">
				
				select	*
				from	qCompare
				where	isSame = 0
				order by name;
			</cfquery>

			<cfif qDiff.recordCount GT 0>

				<style>
					table td { padding: 0.2em 1em; }
					table.added td { color: ##AFA; }
					table.modified td { color: ##AAF; }
					table.removed td { color: ##FAA; }
				</style>
					
				<cfset add = []>
				<cfset mod = []>
				<cfset rem = []>

				<cfloop query="qDiff">
					
					<cfset rowData = { name=name, size=size, modified=modified, size1=size1, size2=size2, modified1=modified1, modified2=modified2 }>

					<cfswitch expression="#change#">
						
						<cfcase value="added">
							
							<cfset arrayAppend( add, rowData )>
						</cfcase>
						<cfcase value="modified">
							
							<cfset arrayAppend( mod, rowData )>
						</cfcase>
						<cfcase value="removed">
							
							<cfset arrayAppend( rem, rowData )>
						</cfcase>
					</cfswitch>
				</cfloop>

				<cfif arrayLen( rem )>
					
					<table class="removed">
						<tr><td colspan="3">removed #arrayLen( rem )# files</td></tr>
						<cfloop array="#rem#" index="row">
							<tr>
								<td>-</td>
								<td>#row.name#</td>
								<td>#row.size1#</td>
								<td>#row.modified1#</td>
							</tr>
						</cfloop>
					</table>
				</cfif>

				<cfif arrayLen( add )>
					
					<table class="added">
						<tr><td colspan="3">added #arrayLen( add )# files</td></tr>
						<cfloop array="#add#" index="row">
							<tr>
								<td>+</td>
								<td>#row.name#</td>
								<td>#row.size2#</td>
								<td>#row.modified2#</td>
							</tr>
						</cfloop>
					</table>
				</cfif>

				<cfif arrayLen( mod )>
					
					<table class="modified">
						<tr><td colspan="3">modified #arrayLen( mod )# files</td></tr>
						<cfloop array="#mod#" index="row">
							<tr>
								<td>*</td>
								<td>#row.name#</td>
								<td>#row.size#</td>
								<td>#row.size1#</td>
								<td>#row.size2#</td>
								<td>#row.modified#</td>
							</tr>
						</cfloop>
					</table>
				</cfif>

			<cfelse>	<!--- qDiff.recordCount GT 0 !--->

				<h3>The archives are the same</h3>
			</cfif>	<!--- qDiff.recordCount GT 0 !--->


			<cfcatch>

				<div class="error">
					<p>an error occured: #cfcatch.type#; #cfcatch.message#
					<p>#cfcatch.toString()#
				</div>
			</cfcatch>
		</cftry>

		<div>
			<a href="#CGI.SCRIPT_NAME#">Compare Another Set</a>
		</div>
	<cfelse>

		<form method="post">
			<fieldset>
				<legend>#pageTitle#</legend>

				<div class="clearfix field">
					<div class="label">First Archive:</div>
					<div><input type="text" name="archive1" class="path" value=""></div>
					<div class="hint">must be a valid zip archive, e.g. .zip, .jar, .war, .rc</div>
					<br/>
					<div class="label">Second Archive:</div>
					<div><input type="text" name="archive2" class="path" value="#cookie.rb_dstDir#/railo.jar"></div>
					<div class="hint">must be a valid zip archive, e.g. .zip, .jar, .war, .rc</div>
				</div>
				<div style="text-align: center">
					<input type="submit" value="Compare Archives" class="primaryButton">
				</div>
			</fieldset>
		</form>

	</cfif>

</cfoutput>


<cfinclude template="footer.cfml">