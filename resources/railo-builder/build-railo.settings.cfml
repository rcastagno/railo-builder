


<cfscript>

    /** default settings begin */

    defaults = {

          srcDir   = "F:/Workspace/git/igal-getrailo/"      // path to the Railo source code
    
        , dstDir   = "F:/test/built-by-railo84/"            // path for the built files

        , resDir   = ""                                     // path of resources for JARs, WAR, Express etc
    
        , password = "server"                               // web admin password for the context that runs this script
    }

    /** default settings end */
</cfscript>



<cfparam name="srcDir"      default="#defaults.srcDir#">
<cfparam name="dstDir"      default="#defaults.dstDir#">
<cfparam name="resDir"      default="#defaults.resDir#">
<cfparam name="password"    default="#defaults.password#">

<cfparam name="build"       default="patch">

<cfparam name="compilerType" default="railo.build.util.JdtJavaCompiler">    <!--- args that are passed to the jdt compiler --->
<cfparam name="compilerArgs" default="-1.6 -nowarn">                        <!--- args that are passed to the jdt compiler --->



<style> /** console look */
    body{ font-family:monospace; background-color:black; color:white; } 
    p   { margin:0.35em; }
    p b { color:#3C3; }
    p b.error { color:#F66; }
    p b.warning { color:#FF8C00; }
    span.ts { color:#ABC; margin-right:1em; }

    .util   { margin:2.5em 1.25em; }
    .util a { color: yellow; }
</style>
