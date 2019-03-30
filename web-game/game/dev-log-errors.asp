<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "log_errors"

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-log-errors")

	dim oRs, query

	query = "SELECT id, err_asp_code, err_number, err_source, err_category, err_file, err_line, err_column, err_description, err_aspdescription, datetime, ""user"", details, url" &_
			" FROM log_http_errors" &_
			" WHERE datetime > now()-INTERVAL '3 days' OR id > (SELECT COALESCE(dev_lasterror, 0) FROM users WHERE id=" & Session(sLogonUserID) & ")" &_
			" ORDER BY datetime DESC" &_
			" LIMIT 400"

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		oConn.Execute "UPDATE users SET dev_lasterror=" & oRs(0) & " WHERE id=" & Session(sLogonUserID)
	end if

	while not oRs.EOF
		content.AssignValue "err_asp_code", oRs(1)
		content.AssignValue "err_number", oRs(2)
		content.AssignValue "err_source", oRs(3)
		content.AssignValue "err_category", oRs(4)
		content.AssignValue "err_file", oRs(5)
		content.AssignValue "err_line", oRs(6)
		content.AssignValue "err_column", oRs(7)
		content.AssignValue "err_description", oRs(8)
		content.AssignValue "err_aspdescription", oRs(9)
		content.AssignValue "timestamp", oRs(10)
		content.AssignValue "user", oRs(11)
		content.AssignValue "details", oRs(12)
		content.AssignValue "url", oRs(13)

		content.Parse "error"
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

DisplayForm()

%>