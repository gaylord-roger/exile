<%option explicit %>

<!--#include file="global.asp"-->

<%
	dim lcid
	lcid = ToInt(Request.QueryString("lcid"), "1036")

	if lcid <> 1033 and lcid <> 1036 then
		lcid = 1036
	end if

	connExecuteRetryNoRecords "UPDATE users SET lcid=" & dosql(lcid) & " WHERE id=" & dosql(UserId)

	Response.Redirect "overview.asp"
%>