		</div>

		<cfoutput>

			<div style="margin:2.5em 1.25em;">
				<p><a href="/">Build</a> 
					&middot; <a href="/compare.cfm">Compare</a>
					&middot; <a href="/hash.cfm">MD5</a>
					&middot; <a href="/railo-context/admin/server.cfm">Admin</a>

				<p>Railo #Server.railo.version# running in #Server.servlet.name# from #getDirectoryFromPath( CGI.CF_TEMPLATE_PATH )#</div>
			
			<!--- #getRequestUrl()# !--->
		</cfoutput>
		
		<script src="/res/js/jquery-1.8.3.min.js"></script>

		<cfparam name="Request.js" default="">

		<cfif len( Request.js )>
			
			<cfoutput>

				<script>

					#Request.js#
				</script>
			</cfoutput>
		</cfif>
	</body>
</html>
