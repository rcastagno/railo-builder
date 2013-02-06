<cfset pageTitle = "Calculate MD5">


<cfinclude template="header.cfml">


<cfoutput>

	<cfif Request.isHttpPost>
		
		
		<cfset utils = new cfc.BuilderUtils()>

		<cfset md5 = utils.CalcFileHash( filename )>

		<table>
			<tr>
				<td class="label">Filename:</td>
				<td>#filename#</td>
			</tr>
			<tr>
				<td class="label">MD5:</td>
				<td>#md5.toString()#</td>
			</tr>
		</table>

	</cfif>


	<form method="post">
		<fieldset>
			<legend>#pageTitle#</legend>

			<div class="clearfix field">
				<div class="label">Filename:</div>
				<div><input type="text" name="filename" class="path" value=""></div>
				<div class="hint">full path to the file</div>
			</div>
			<div style="text-align: center">
				<input type="submit" value="Generate MD5" class="primaryButton">
			</div>
		</fieldset>
	</form>


</cfoutput>


<cfinclude template="footer.cfml">