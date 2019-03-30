<%
Response.clear();	// Clear buffer to only send this 500 page
var lastError = Server.GetLastError();
%>
<!--#include virtual="/lib/exile.asp"-->

<html>
<head>
<title>Oups ...</title>

<link href="/styles/exile/exile.css" rel="stylesheet" type="text/css" media="all"/>
<script language="JavaScript" type="text/javascript">
function shakewnd(n) {
	if(self.moveBy)
	for(i=10; i>0; i--)
		for(x=0; x<n; x++) {
			self.moveBy(i,i);
			self.moveBy(0,-i);
			self.moveBy(-i,i);
			self.moveBy(0,-i);
		}
}
</script>
</head>
<body onload="shakewnd(1)">

<div align="center">
<table width="100%" height="100%">
<tr>
    <td width="100%" height="80%" align="center" valign="middle"><img src="assets/error500.jpg" width="250" height="216"><br/>
	<br/>
	Une erreur est survenue sur la page que vous avez demand&eacute;e.<br/>
	Merci de bien vouloir nous en excuser.<br/>
			<%
			if(Request.QueryString("err_debug").item != null) {
				var s = '<br/><table class="default"><tr><td class="grey">' +
						'Date: ' + new Date() + '<br/>' +
						'Cat&eacute;gorie: ' + lastError.Category + '<br/>' +
						'Fichier: ' + lastError.File + '<br/>' +
						'Ligne: ' + lastError.Line + '<br/>' +
						'Description: ' + lastError.Description + '<br/>' +
						'</td></tr></table>';

				Response.write(s);
				Response.end();
			}
			else
			if(!maintenance) {
				var query = 'INSERT INTO log_http_errors(http_error_code, err_asp_code, err_number, err_source, err_category, err_file, err_line, err_column, err_description, err_aspdescription, details, url, "user") VALUES(' +
							[500, lastError.ASPCode, lastError.Number, lastError.Source, lastError.Category, lastError.File, lastError.Line, lastError.Column, lastError.Description, lastError.ASPDescription, 
							Session("details"), Request.ServerVariables("SCRIPT_NAME") + '?' + Request.ServerVariables("QUERY_STRING")].toSQL() +
							', (SELECT login FROM users WHERE id=' + dosql(Session("user")) + ')' + ')';

				try {
					SQLConn.execute(query);
				} catch(e) {
					// prevent any error here
				}
			}
			%>
	</td>
</tr>
</table>
</div>
<div class="hidden"><%
Application.lock();
Application("errors")++;
Response.write(Application("errors"));
Application.unlock();
%>
</div>
</body>
</html>