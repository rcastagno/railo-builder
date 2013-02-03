<cfsetting requestTimeout="300">


<cfinclude template="build-railo.settings.cfml">    <!--- sets srcDir, dstDir, and compilerArgs --->



<cfset settings = {

      dstDir        = dstDir
    , srcDir        = srcDir
    , resDir        = resDir
    , password      = password

    , compilerType  = compilerType
    , compilerArgs  = compilerArgs

    , buildType     = build
}>



<cfset railoBuilder = new cfc.RailoBuilder( settings )>


<!--- railoBuilder.Build() calls flush() so set cookies before calling Build() !--->
<cfset cookie.rb_srcDir     = srcDir>
<cfset cookie.rb_dstDir     = dstDir>
<cfset cookie.rb_resDir     = resDir>
<cfset cookie.rb_password   = password>


<cfset railoBuilder.Build()>


<cfinclude template="footer.cfml">