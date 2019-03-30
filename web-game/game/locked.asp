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

' retrieve remaining time
query = "SELECT login, int4(date_part('epoch', ban_expire-now())), ban_reason_public, (SELECT email FROM users WHERE id=u.ban_adminuserid)" &_
		" FROM users AS u" &_
		" WHERE privilege=-1 AND id=" & UserId

set oRs = oConn.Execute(query)

if oRs.EOF then
	response.redirect "/"
	response.end
end if

set content = GetTemplate("locked")

' check to unlock holidays mode
action = Request.Form("unlock")

if action <> "" and oRs(1) <= 0 then
	oConn.Execute "UPDATE users SET privilege=0, ban_expire=NULL WHERE ban_expire <= now() AND privilege=-1 AND id="&UserId, , 128
	Response.Redirect "/game/overview.asp"
	Response.End
end if


content.AssignValue "login", oRs(0)
content.AssignValue "remaining_time_before_unlock", oRs(1)

'content.AssignValue "admin_email", oRs(3)
content.AssignValue "admin_email", supportMail

content.AssignValue "universe", Universe

if not IsNull(oRs(2)) and oRs(2) <> "" then
	content.AssignValue "reason", oRs(2)
	content.Parse "reason"
end if

if not IsNull(oRs(1)) then
	if oRs(1) < 0 then
		content.Parse "unlock"
	else
		content.AssignValue "remaining_time_before_unlock", oRs(1)
		content.Parse "cant_unlock"
	end if
end if

content.Parse ""

Response.write content.Output

%>
