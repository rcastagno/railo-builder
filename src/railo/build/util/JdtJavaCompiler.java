package railo.build.util;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;

import org.eclipse.jdt.core.compiler.CompilationProgress;
import org.eclipse.jdt.core.compiler.batch.BatchCompiler;


/**
 * @deprecated - now implemented in CFC as JdtCompiler.cfc
 * 
 * this class is a wrapper around org.eclipse.jdt.core.compiler.batch.BatchCompiler to simplify interaction with CFML
 * see http://help.eclipse.org/indigo/index.jsp?topic=%2Forg.eclipse.jdt.doc.user%2Ftasks%2Ftask-using_batch_compiler.htm
 */
@Deprecated
public class JdtJavaCompiler {
	
	
	/**
	 * calls the BatchCompiler.compile() methods with the passed args
	 * 
	 * @param commandLine - the commandLine that is passed to the BatchCompiler
	 * @param isVerbose - if true the returned string output is verbose
	 */
	public static String Compile( String commandLine, boolean isVerbose ) {
	
		StringWriter out = new StringWriter();
		
		PrintWriter outWriter = new PrintWriter( out, true );
		
		outWriter.println( "Compiler Command: " + commandLine );
		
		CompilationProgress progress = null;
		
		if ( isVerbose )
			progress = getDebugCompProgress( outWriter );
		
				
		BatchCompiler.compile( commandLine, outWriter, outWriter, progress );

		
		outWriter.println( "Done." );
		
		String result = out.getBuffer().toString().trim();
		
		return result;
	}
	
	
	/** return Compile( commandLine, false ) */
	public static String Compile( String commandLine ) {
		
		return Compile( commandLine, false );
	}
	
	
	/**
	 * calls the BatchCompiler.compile() methods with the passed args
	 * 
	 * @param srcDirectory - the directory with the source .java files 
	 * @param dstDirectory - the directory to save the .class files to
	 * @param compilerArgs - args that will be passed to the BatchCompiler, e.g. "-nowarn -1.6"
	 */
	public static String Compile( String srcDirectory, String dstDirectory, String compilerArgs, boolean isVerbose ) {
		
		String commandLine = String.format( "%s -d %s %s", compilerArgs, dstDirectory, srcDirectory );
		
		return Compile( commandLine, isVerbose );
	}
	
	
	/** return Compile( srcDirectory, dstDirectory, compilerArgs, false ) */
	public static String Compile( String srcDirectory, String dstDirectory, String compilerArgs ) {
		
		return Compile( srcDirectory, dstDirectory, compilerArgs, false );
	}
	
	
	public static CompilationProgress getDebugCompProgress( final PrintWriter out ) {
		
		CompilationProgress result = new CompilationProgress() {
			
			double done;
			double totalTasks;
			
			@Override
			public void worked(int arg0, int arg1) {

				done += arg0;
				
				print( arg1 + " tasks left\t" + ( (double)( (int)( done * 10000 / totalTasks ) ) / 100 ) + "%" );
			}
			
			@Override
			public void setTaskName(String arg0) {

				print( arg0 );
			}
			
			@Override
			public boolean isCanceled() {

				return false;
			}
			
			@Override
			public void done() {
				
				print( "done" );			
			}
			
			@Override
			public void begin(int arg0) {
				
				totalTasks = arg0;
				
				print( "Total of " + totalTasks + " tasks" );
			}
			
			void print( String s ) {
				
				out.println( "\tcompiler: " + s );
			}
		};
		
		return result;
	}
	
	
	/** test method */
	public static void main(String[] args) throws IOException {
		
		boolean debug = false;
		
		if ( debug ) {
			
			String commandLine = "-1.6 -nowarn -extdirs \"F:/Workspace/git/igal-getrailo/railo-java/libs;F:/Downloads/jetty-distribution-8.1.7.v20120910/jetty-8.1.7-test/webapps/railo/WEB-INF/railo/lib/compile\" -d F:/test/compiled-by-railo120a/__railo-core-bin F:/test/compiled-by-railo120a/__railo-core-src";

			String s = Compile( commandLine, true );
			
			System.out.println( s );
			
			args = new String[] {
					
			//	"F:/Workspace/git/igal-getrailo/railo-java/railo-core/src/",
				"F:/test/compiled-by-railo113b/__railo-core-src",
				"F:/test/compiled0",
				"-nowarn -1.6 -extdirs \"F:/Workspace/git/igal-getrailo/railo-java/libs/\""
			};
		}
		
		if ( args.length < 3 ) {
		
			System.out.println( "usage: java railo.build.util.JavaCompiler srcDirectory dstDirectory compilerArgs" );
			
			// \\igal-getrailo\railo-java\railo-build\bin>c:\apps\java\jre6\bin\java -cp ".;../../libs/org.eclipse.jdt.core.jar" railo.compile.Compiler F:/Workspace/git/igal-getrailo/railo-java/railo-core/src/ F:/compiled "-nowarn -1.6 -extdirs ""F:/Workspace/git/igal-getrailo/railo-java/libs/"""
			
			System.exit( 1 );
		}
		
		
		String result = JdtJavaCompiler.Compile( args[0], args[1], args[2] );
		
		System.out.println( result );
	}
}