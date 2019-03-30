<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "log_notices"

sub DisplayForm(showall)
	dim content
	set content = GetTemplate("dev-log-notices")

	dim oRs, query, show

	query = "SELECT id, datetime, username, title, details, url, repeats, level" &_
			" FROM log_notices" &_
			" WHERE datetime > now()-INTERVAL '3 days' OR id > (SELECT COALESCE(dev_lastnotice, 0) FROM users WHERE id=" & Session(sLogonUserID) & ")" &_
			" ORDER BY datetime DESC" &_
			" LIMIT 400"

	set oRs = oConn.Execute(query)

	if not oRs.EOF then oConn.Execute "UPDATE users SET dev_lastnotice=" & oRs(0) & " WHERE id=" & Session(sLogonUserID)

	while not oRs.EOF
		content.AssignValue "timestamp", oRs(1)
		content.AssignValue "username", oRs(2)
		content.AssignValue "title", oRs(3)
		content.AssignValue "details", oRs(4)
		content.AssignValue "url", oRs(5)

		if oRs(6) > 1 then
			content.AssignValue "repeats", oRs(6)
			content.Parse "notice.repeats"
		end if

		if oRs(7) = 1 then
			content.Parse "notice.level1"
			show = true
		elseif oRs(7) = 2 then
			content.Parse "notice.level2"
			show = true
		elseif oRs(6) > 1 then
			content.Parse "notice.level1"
			show = true
		end if

		if showall or show then content.Parse "notice"
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

DisplayForm(true)

%>