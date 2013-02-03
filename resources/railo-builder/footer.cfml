		</div>

		<cfoutput>

			<div style="margin:2.5em 1.25em;">
				<p><a href="/">Build</a> &middot; <a href="/compare.cfm">Compare</a>

				<p>Railo #server.railo.version# running in #server.servlet.name# from #getDirectoryFromPath( cgi.cf_template_path )#</div>
			
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
