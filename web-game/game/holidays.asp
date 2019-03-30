<% option explicit %>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->
<%

dim UserId

UserId = ToInt(Session("user"), "")

if UserId = "" then
	response.redirect "/"
	response.end
end if

dim query, oRs, action, content

set content = GetTemplate("holidays")

' retrieve remaining time
query = "SELECT login," &_
		" (SELECT int4(date_part('epoch', min_end_time-now())) FROM users_holidays WHERE userid=id)," &_
		" (SELECT int4(date_part('epoch', end_time-now())) FROM users_holidays WHERE userid=id)" &_
		" FROM users WHERE privilege=-2 AND id=" & UserId

set oRs = oConn.Execute(query)

if oRs.EOF then
	response.redirect "/"
	response.end
end if


' check to unlock holidays mode
action = Request.Form("unlock")

if action <> "" and oRs(1) < 0 then
	oConn.Execute "SELECT sp_stop_holidays("&UserId&")", , 128
	Response.Redirect "/game/overview.asp"
	Response.End
end if


' if remaining time is negative, return to overview page
if oRs(2) <= 0 then
	response.redirect "/game/overview.asp"
	response.end
end if

content.AssignValue "login", oRs(0)
content.AssignValue "remaining_time", oRs(2)

' only allow to unlock the account after 2 days of holidays
if oRs(1) < 0 then
	content.Parse "unlock"
else
	content.AssignValue "remaining_time_before_unlock", oRs(1)
	content.Parse "cant_unlock"
end if

content.Parse ""

Response.write content.Output

%>
