component {


	this.name 	= "BuildRailo";
	

	public function onRequestStart( targetPage ) {

		Request.isHttpPost = CGI.REQUEST_METHOD == 'POST';

		setting requestTimeout=600;

		param name="cookie.rb_dstDir" 	default="";
		param name="cookie.rb_resDir" 	default="";
		param name="cookie.rb_srcDir" 	default="";
		param name="cookie.rb_password"	default="server";

	}


}