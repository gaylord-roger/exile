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

set content = GetTemplate("wait")

' retrieve remaining time
query = "SELECT login, COALESCE(date_part('epoch', ban_expire-now()), 0) AS remaining_time FROM users WHERE /*privilege=-3 AND*/ id=" & UserId

set oRs = oConn.Execute(query)

if oRs.EOF then
	response.redirect "/"
	response.end
end if

dim remainingTime: remainingTime = oRs(1)

' check to unlock holidays mode
action = Request.Form("unlock")

if action <> "" and remainingTime < 0 then
	oConn.Execute "UPDATE users SET privilege=0 WHERE ban_expire < now() AND id="&UserId, , 128
	Response.Redirect "/game/start.asp"
	Response.End
end if

content.AssignValue "login", oRs(0)
content.AssignValue "remaining_time_before_unlock", cLng(oRs(1))

if remainingTime < 0 then
	content.Parse "unlock"
else
	content.Parse "cant_unlock"
end if

content.Parse ""

Response.write content.Output

%>
