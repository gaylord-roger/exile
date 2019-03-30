<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "player_penalty"

dim typ, submit
dim oRs, query


sub DisplayForm()
	dim content
	set content = GetTemplate("dev-options")

	content.AssignValue "name", oPlayerInfo("login")

	set oRs = oConn.Execute("SELECT privilege, ban_reason, ban_reason_public, admin_notes FROM users WHERE id="&UserId)
	if oRs(0) = -1 then content.Parse "unban"
	if oRs(0) = -2 then content.Parse "stopholidays"

	content.AssignValue "userid", UserId

	content.AssignValue "reason", oRs(1)
	content.AssignValue "reasonpublic", oRs(2)
	content.AssignValue "notes", oRs(3)

	query = "SELECT action, reason, reason_public, admin_notes, datetime FROM log_admin_actions WHERE userid=" & UserId
	set oRs = oConn.Execute(query)
	while not oRs.EOF

		content.AssignValue "h_reason", oRs(1)
		content.AssignValue "h_reason_public", oRs(2)
		content.AssignValue "h_admin_notes", oRs(3)
		content.AssignValue "h_date", oRs(4).value

		content.Parse "history.action" & oRs(0)
		content.Parse "history"

		oRs.MoveNext
	wend


'	content.Parse "type_" & typ
	content.Parse ""

	Display(content)
end sub

function sqlValue(val)
	if val = "" or IsNull(val) then
		sqlValue = "Null"
	else
		sqlValue = val
	end if
end function

if Session("privilege") < 100 then RedirectTo "/"

dim action, newname, reason, reasonpublic, redirecturl, user, notes
action = Trim(Request.QueryString("action"))
newname = Trim(Request.QueryString("newname"))
reason = Trim(Request.QueryString("reason"))
reasonpublic = Trim(Request.QueryString("reasonpublic"))
notes = Trim(Request.QueryString("notes"))
redirecturl = ""

user = Trim(Request.QueryString("userid"))

typ = ""

select case action
	case "penalty"
		typ = Trim(Request.QueryString("type"))
		select case typ
			case 0	' electromagnetic storms on all the player planets
				query = "SELECT sp_catastrophe_electromagnetic_storm(Ownerid,id, 24) FROM nav_planet WHERE ownerid="&User
			case 1	' account locked for 1 day
				query = "UPDATE users SET privilege=-1," &_
						" ban_reason="&dosql(reason)&", ban_reason_public="&dosql(reasonpublic)&", ban_datetime=now()," &_
						" ban_expire=now()+INTERVAL '1 day', ban_adminuserid=" & Session(sLogonUserID) &_
						" WHERE id="&User
			case 2	' account locked for 2 days
				query = "UPDATE users SET privilege=-1," &_
						" ban_reason="&dosql(reason)&", ban_reason_public="&dosql(reasonpublic)&", ban_datetime=now()," &_
						" ban_expire=now()+INTERVAL '2 days', ban_adminuserid=" & Session(sLogonUserID) &_
						" WHERE id="&User
			case 3	' account locked for 4 days
				query = "UPDATE users SET privilege=-1," &_
						" ban_reason="&dosql(reason)&", ban_reason_public="&dosql(reasonpublic)&", ban_datetime=now()," &_
						" ban_expire=now()+INTERVAL '4 days', ban_adminuserid=" & Session(sLogonUserID) &_
						" WHERE id="&User
			case 4	' account locked for 7 days
				query = "UPDATE users SET privilege=-1," &_
						" ban_reason="&dosql(reason)&", ban_reason_public="&dosql(reasonpublic)&", ban_datetime=now()," &_
						" ban_expire=now()+INTERVAL '7 days', ban_adminuserid=" & Session(sLogonUserID) &_
						" WHERE id="&User
			case 5	' holidays for 2 weeks immediately
				if oPlayerInfo("privilege") = 0 then
					query = "INSERT INTO users_holidays(userid, start_time, min_end_time, end_time) VALUES("&User&",now(), now()+INTERVAL '48 hours', now()+INTERVAL '2 weeks')"
				else
					
				end if
			case 6	' holidays for 3 weeks immediately
				if oPlayerInfo("privilege") = 0 then
					query = "INSERT INTO users_holidays(userid, start_time, min_end_time, end_time) VALUES("&User&",now(), now()+INTERVAL '48 hours', now()+INTERVAL '3 weeks')"
				else

				end if
		end select

		oConn.Execute query,, adExecuteNoRecords

	case "rename"
		query = "UPDATE users SET login="&dosql(newname)&" WHERE id="&User
		oConn.Execute query,, adExecuteNoRecords

		query = "UPDATE commanders SET name="&dosql(newname)&" WHERE ownerid="&User&" AND NOT can_be_fired"
		oConn.Execute query,, adExecuteNoRecords

		typ = -1

		redirecturl = "dev-playas.asp?player="&newname
		reason = oPlayerInfo("login")
		reasonpublic = newname

	case "ban"	' account locked forever : banned
		query = "UPDATE users SET privilege=-1," &_
				" ban_reason="&dosql(reason)&", ban_reason_public="&dosql(reasonpublic)&", ban_datetime=now()," &_
				" ban_expire=NULL, ban_adminuserid=" & Session(sLogonUserID) &_
				" WHERE id="&User
		oConn.Execute query,, adExecuteNoRecords

		typ = -2

	case "unban"
		query = "UPDATE users SET privilege=0 WHERE id="&User
		oConn.Execute query,, adExecuteNoRecords

		typ = -3

	case "stopholidays"
		query = "UPDATE users_holidays SET min_end_time=now(), end_time=now() WHERE userid="&User
		oConn.Execute query,, adExecuteNoRecords

		typ = -4

	case "notes"
		typ = -5
end select

if typ <> "" then
	' update admin notes
	query = "UPDATE users SET admin_notes=" & dosql(notes) & " WHERE id="&User
	oConn.Execute query,, adExecuteNoRecords

	query = "INSERT INTO log_admin_actions(adminuserid, userid, action, reason, reason_public, admin_notes)" &_
			"VALUES(" & Session(sLogonUserID) & "," & User & "," & typ & "," & dosql(reason) & "," & dosql(reasonpublic) & "," & dosql(notes) & ")"
	oConn.Execute query,, adExecuteNoRecords

	if redirecturl <> "" then RedirectTo redirecturl
end if

if Request.QueryString("close") = "" then DisplayForm()

%>