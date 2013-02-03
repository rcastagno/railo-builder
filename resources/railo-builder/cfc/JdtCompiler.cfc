/** a wrapper for the JDT Batch Compiler */
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
	

}