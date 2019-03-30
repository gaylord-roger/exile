<%
option explicit
On Error Resume Next
Response.clear	' Clear buffer to only send this 500 page
dim ASPErr : set ASPErr = Server.GetLastError()
%>
<!--#include virtual="/lib/config.asp"-->
<!--#include virtual="/lib/sql.asp"-->

<html>
<head>
<title>Oups ..</title>

<link href="https://data.exil.pw/styles/reset.css" rel="stylesheet" type="text/css" media="all">
<link href="https://data.exil.pw/styles/s_default/style.css" rel="stylesheet" type="text/css" media="all">
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
    <td width="100%" height="80%" align="center" valign="middle"><img src="/assets/error500.jpg" width="250" height="216"><br/>
	<br/>
	Une erreur est survenue sur la page que vous avez demand&eacute;e.<br/>
	Merci de bien vouloir nous en excuser.<br/>
			<%
			if Request.queryString("err_debug") <> "" then
				response.write "<br/>"
				response.write "<table class=default>"
				response.write "<tr>"
				response.write "<td class=grey>"
				response.write "Date : " & now & "<br/>"
				response.write "Cat&eacute;gorie : " & ASPErr.Category & "<br/>"
				response.write "Fichier : " & ASPErr.File & "<br/>"
				response.write "Ligne : " & ASPErr.Line & "<br/>"
				response.write "Description : " & ASPErr.Description & "<br/>"
				response.write "</td>"
				response.write "</tr>"
				response.write "</table>"
			elseif not maintenance then

				Err.Clear

				connectDB()

				dim myHTTPErrCode : myHTTPErrCode = 500

				dim ErrSQL

				with ASPErr
					ErrSQL = "INSERT INTO log_http_errors(http_error_code, err_asp_code, err_number, err_source, err_category, err_file, err_line, err_column, err_description, err_aspdescription, details, url, ""user"") VALUES(" &_
									dosql(myHTTPErrCode) & "," &_
									dosql(.ASPCode) & "," &_
									dosql(.Number) & "," &_
									dosql(.Source) & "," &_
									dosql(.Category) & "," &_
									dosql(.File) & "," &_
									dosql(.Line) & "," &_
									dosql(.Column) & "," &_
									dosql(.Description) & "," &_
									dosql(.ASPDescription) & "," &_
									dosql(Session("details")) & "," &_
									dosql(Request.ServerVariables("SCRIPT_NAME") & "?" & Request.ServerVariables("QUERY_STRING")) & "," &_
									"(SELECT login FROM users WHERE id=" & sqlValue(Session("user")) & ")" &_
								")"
				end with

				if false and Err.Number <> 0 then
					response.write "<br/>"
					response.write "<table class=default>"
					response.write "<tr>"
					response.write "<td class=grey>"
					response.write "Erreur<br/>"
					response.write "Date : " & now & "<br/>"
					response.write "Cat&eacute;gorie : " & Err.Category & "<br/>"
					response.write "Fichier : " & Err.File & "<br/>"
					response.write "Ligne : " & Err.Line & "<br/>"
					response.write "Description : " & Err.Description & "<br/>"
					response.write "</td>"
					response.write "</tr>"
					response.write "</table>"
				end if
			
				oConn.execute ErrSQL, , 128

				oConn.close
				Set oConn = nothing
				Set ASPErr = nothing

				On Error Goto 0
			end if
			%>
	</td>
</tr>
</table>
</div>
<div class="hidden"><%
Application.Lock
Application("errors")=Application("errors")+1
response.write Application("errors")
response.write Application("more_debug")
Application.UnLock%>
</div>
</body>
</html>