<cfparam name="pageTitle" default="Build Railo from Source">

<html>
	<head>

		<cfoutput><title>#pageTitle#</title></cfoutput>

		<style>
			body, td	{ margin: 0; padding: 0; background-color: #222; color: #DDD; font-family: arial, sans-serif; font-size: 10.5pt; line-height: 1.5; }
			fieldset	{ width: 640px; margin: 1em auto 0.25em auto; border-radius: 5px; }
			fieldset legend { padding: 0.5em 1em; }
			form		{ padding: 0; margin: 0; }
			label		{ line-height: 2em; margin-right: 1em; cursor: pointer; }
			input.path 	{ width: 24em; }
			
			.label		{ float: left; width: 10em; text-align:right; margin: 0.25em; font-family: Georgia; }
			.hint		{ clear: left; text-indent: 10.5em; color: #999; }

			.clearfix:before,		/** modern clearfix */
			.clearfix:after { content: " "; display: table; }
			.clearfix:after { clear: both; }

			.field		{ margin: 0.5em; padding: 0.75em; border: 1px dotted #CCC; border-radius: 5px; }
			.wrapper	{  }
			.header		{ position: relative; background: #df4907 url(/res/images/bg-header-002.png) repeat-x; }
			.header h1 	{ position: absolute; bottom: 20px; right: 20px; margin: 0; padding: 0; font-family: Georgia; color: white; }	

			#logo		{ float: left; width: 150px; height: 100px; background: url(/res/images/id.png) no-repeat 20px 20px; }
			.primaryButton { color: green; font-size: 15pt; padding: 0.25em 1em; }

			a 		{ color: yellow; }
			.error	{ color: #FAA; margin: 2em; }

			.valid 		{ background-color: #99FF99; }
			.invalid 	{ background-color: #FF9999; }
		</style>
	</head>
	<body>

		<cfoutput>

			<div class="header clearfix">
				<div id="logo"></div>
				<h1>#pageTitle#</h1>
			</div>

		</cfoutput>

		<div style="margin: 2em;">