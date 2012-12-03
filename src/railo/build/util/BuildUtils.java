package railo.build.util;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import railo.commons.io.res.Resource;
import railo.commons.io.res.ResourceProvider;
import railo.commons.io.res.ResourcesImpl;
import railo.commons.io.res.filter.ResourceFilter;
import railo.commons.io.res.util.ResourceUtil;


public class BuildUtils {


	public static void copyDirectoryTree( String src, String dst, ResourceFilter filter ) throws Exception {

		ResourceProvider frp = ResourcesImpl.getFileResourceProvider();

		Resource rSrc = frp.getResource( src );
    	Resource rDst = frp.getResource( dst );
    	
    	if ( filter != null )
    		ResourceUtil.copyRecursive( rSrc, rDst, filter );
    	else
    		ResourceUtil.copyRecursive( rSrc, rDst );
	}
	
	
	/** calls copyDirectoryTree( src, dst, null ); */
	public static void copyDirectoryTree( String src, String dst ) throws Exception {

		copyDirectoryTree( src, dst, null );
	}
	
	
	public static ResourceFilter createPrefixResourceFilter( final String prefixList, final boolean isExcludeFilter, final ResourceFilter chain ) {
		
		ResourceFilter filter = new ResourceFilter() {

			List<String> substrings = splitAndTrim( prefixList );
			
			@Override
			public boolean accept( Resource res ) {

				if ( chain != null && !chain.accept( res ) )
					return false;
				
				String filename = res.getName().toLowerCase();
				
				for ( String exc : this.substrings ) {
					
					if ( filename.startsWith( exc ) )
						return !isExcludeFilter;
				}
				
				return isExcludeFilter;
			}
		};
		
		return filter;
	}

	
	/** return createPrefixResourceFilter( prefixList, isExcludeFilter, null ); */
	public static ResourceFilter createPrefixResourceFilter( final String prefixList, final boolean isExcludeFilter ) {
	
		return createPrefixResourceFilter( prefixList, isExcludeFilter, null );
	}
	
	
	public static ResourceFilter createSuffixResourceFilter( final String suffixList, final boolean isExcludeFilter, final ResourceFilter chain ) {
		
		ResourceFilter filter = new ResourceFilter() {

			List<String> substrings = splitAndTrim( suffixList );
			
			@Override
			public boolean accept( Resource res ) {

				if ( chain != null && !chain.accept( res ) )
					return false;
				
				String filename = res.getName().toLowerCase();
				
				for ( String exc : this.substrings ) {
					
					if ( filename.endsWith( exc ) )
						return !isExcludeFilter;
				}
				
				return isExcludeFilter;
			}
		};
		
		return filter;
	}
	
	
	/** return createSuffixResourceFilter( suffixList, isExcludeFilter, null ); */
	public static ResourceFilter createSuffixResourceFilter( final String suffixList, final boolean isExcludeFilter ) {
		
		return createSuffixResourceFilter( suffixList, isExcludeFilter, null );
	}
	
	
	public static String getCurrentPath() throws IOException {
		
		String result = new java.io.File(".").getCanonicalPath();
		
		return result;
	}
	
	
	public static Properties readPropertiesFile( String path ) throws IOException {
	
		Properties props = new Properties();
		
		FileInputStream inStream = new FileInputStream( path );

		props.load( inStream );
		
		inStream.close();

		return props;
	}
	
	
	private static List<String> splitAndTrim( String input ) {
		
		String[] split = input.split( ",|;" );
		
		List<String> result = new ArrayList<String>( split.length );
		
		for ( String s : split ) {
			
			s = s.trim();
			
			if ( s.startsWith( "*" ) )
				s = s.substring( 1 );
			
			if ( s.endsWith( "*" ) )
				s = s.substring( 0, s.length() - 1 );
			
			if ( !s.isEmpty() )
				result.add( s );
		}
		
		return result;
	}
	
	
	public static void main(String[] args) throws Exception {
		
		ResourceFilter filter = createPrefixResourceFilter( "i", true );
		
		copyDirectoryTree( "C:/Apps/railo-express-4.0.0.013/webroot", "F:/test-resource-copy", filter );
		
		System.out.println( "." );
	}
	
	
}