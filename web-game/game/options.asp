<% Option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "options"

if Request.QueryString("frame") = "1" then
	oConn.Execute("UPDATE users SET inframe=true WHERE id="&userid)
	Response.end
end if


dim holidays_breaktime: holidays_breaktime = 7*24*60*60 ' time before being able to set the holidays again

dim changes_status: changes_status = ""
dim showSubmit: showSubmit = true

sub display_general(content)
	dim oRs, query

	query = "SELECT avatar_url, regdate, users.description, 0," &_
			" alliance_id, a.tag, a.name, r.label" &_
			" FROM users" &_
			" LEFT JOIN alliances AS a ON (users.alliance_id = a.id)" &_
			" LEFT JOIN alliances_ranks AS r ON (users.alliance_id = r.allianceid AND users.alliance_rank = r.rankid) " &_
			" WHERE users.id = "&userid
	set oRs = oConn.Execute(query)

	content.AssignValue "regdate", oRs(1)
	content.AssignValue "description", oRs(2)
	content.AssignValue "ip", Request.ServerVariables("remote_addr")

	if isNull(oRs(0)) or oRs(0) = "" then
		content.Parse "general.noavatar"
	else
		content.AssignValue "avatar_url", oRs(0)
		content.Parse "general.avatar"
	end if

	if not isNull(oRs(4)) then
		content.AssignValue "alliancename", oRs(6)
		content.AssignValue "alliancetag", oRs(5)
		content.AssignValue "rank_label", oRs(7)

		content.Parse "general.alliance"
	else
		content.Parse "general.noalliance"
	end if

	content.Parse "general"
end sub

sub display_options(content)
	dim oRs
	set oRs = oConn.Execute("SELECT int4(date_part('epoch', deletion_date-now())), timers_enabled, display_alliance_planet_name, email, score_visibility, skin FROM users WHERE id="&userid)

	if isNull(oRs(0)) then
		content.Parse "options.delete_account"
	else
		content.AssignValue "remainingtime", oRs(0)
		content.Parse "options.account_deleting"
	end if

	if oRs(1) then content.Parse "options.timers_enabled"
	if oRs(2) then content.Parse "options.display_alliance_planet_name"
	content.Parse "options.score_visibility_" & oRs(4)

	content.Parse "options.skin_" & oRs(5)

	content.AssignValue "email", oRs(3)

	content.Parse "options"
end sub

sub display_holidays(content)
	dim oRs, remainingtime

	' check if holidays will be activated soon
	set oRs = oConn.Execute("SELECT int4(date_part('epoch', start_time-now())) FROM users_holidays WHERE userid="&UserId)

	if not oRs.EOF then
		remainingtime = oRs(0)
	else
		remainingtime = 0
	end if

	if remainingtime > 0 then
		content.AssignValue "remaining_time", remainingtime
		content.Parse "holidays.start_in"
		showSubmit = false
	else

		' holidays can be activated only if never took any holidays or it was at least 7 days ago
		set oRs = oConn.Execute("SELECT int4(date_part('epoch', now()-last_holidays)) FROM users WHERE id="&UserId)

		if not isnull(oRs(0)) and oRs(0) < holidays_breaktime then
			content.AssignValue "remaining_time", holidays_breaktime-oRs(0)
			content.Parse "holidays.cant_enable"
			showSubmit = false
		else
			content.Parse "holidays.can_enable"
			content.Parse "submit.holidays"
		end if
	end if

	content.Parse "holidays"
end sub

sub display_reports(content)
	dim oRs
	set oRs = oConn.Execute("SELECT type*100+subtype FROM users_reports WHERE userid="&userid)
	while not oRs.EOF
		content.Parse "reports.c"&oRs(0)
		oRs.MoveNext
	wend

	content.Parse "reports"
end sub

sub display_mail(content)
	dim oRs
	set oRs = oConn.Execute("SELECT autosignature FROM users WHERE id="&userid)
	if not oRs.EOF then
		content.AssignValue "autosignature", oRs(0)
	else
		content.AssignValue "autosignature", ""
	end if

	content.Parse "mail"
end sub

sub display_signature(content)

	content.Parse "signature"
	showSubmit = false
end sub


dim optionCat

sub displayPage()
	dim content, oRs
	set content = GetTemplate("options")
	content.addAllowedImageDomain "*"

	content.AssignValue "cat", optionCat
	content.AssignValue "name", oPlayerInfo("login")
	content.AssignValue "universe", universe

	select case optionCat
		case 2
			display_options content
		case 3
			display_holidays content
		case 4
			display_reports content
		case 5
			display_mail content
		case 6
			display_signature content
		case else
			display_general content
	end select

	if changes_status <> "" then
		content.Parse "changes." & changes_status
		content.Parse "changes"
	end if

	content.Parse "nav.cat"&optionCat&".selected"
	content.Parse "nav.cat1"
	content.Parse "nav.cat2"
	if allowedHolidays then content.Parse "nav.cat3"
'	content.Parse "nav.cat4"
	content.Parse "nav.cat5"
	content.Parse "nav.cat6"
	content.Parse "nav"

	if showSubmit then content.Parse "submit"

	content.Parse ""
	display(content)
end sub

dim query, oRs
dim avatar, email, password, confirm_password, deletingaccount, deleteaccount, description, timers_enabled, display_alliance_planet_name, score_visibility, autosignature, skin

avatar = Trim(Request.Form("avatar"))
'email = Trim(Request.Form("email"))
description = Trim(Request.Form("description"))
'password = Trim(Request.Form("password"))
'confirm_password = Trim(Request.Form("confirm_password"))

timers_enabled = cbool(Request.Form("timers_enabled"))
display_alliance_planet_name = cbool(Request.Form("display_alliance_planet_name"))
score_visibility = ToInt(Request.Form("score_visibility"), 0)
if score_visibility < 0 or score_visibility > 2 then score_visibility = 0
skin = ToInt(Request.Form("skin"), 0)

deletingaccount = Request.Form("deleting")
deleteaccount = Request.Form("delete")

autosignature = Request.Form("autosignature")

optionCat = ToInt(Request.QueryString("cat"), 1)

dim DoRedirect
DoRedirect = false

if optionCat < 1 or optionCat > 6 then optionCat = 1

if not allowedHolidays and optionCat = 3 then optionCat = 1 ' only display holidays formular if it is allowed
'if not oPlayerInfo("payed") and optionCat = 5 then optionCat = 1 ' mail formular is only available to registered/payed accounts
'if IsPlayerAccount() and optionCat = 6 then optionCat = 1 ' under development

if Request.Form("submit") <> "" then

	changes_status = "done"
	query = ""

	select case optionCat
		case 1
			if avatar <> "" and not isValidURL(avatar) then
				'avatar is invalid
				changes_status = "check_avatar"
			else
				' save updated information
				query = "UPDATE users SET" &_
						" avatar_url=" & dosql(avatar) & ", description=" & dosql(description) &_
						" WHERE id=" & UserId
			end if
		case 2
'			dim forwardedfor: forwardedfor = Request.ServerVariables("HTTP_X_FORWARDED_FOR")
'			dim ipaddress: ipaddress = Request.ServerVariables("REMOTE_ADDR")
'			dim useragent: useragent = Request.ServerVariables("HTTP_USER_AGENT")

			query = "UPDATE users SET" &_
					" timers_enabled=" & dosql(timers_enabled) &_
					" ,display_alliance_planet_name=" & dosql(display_alliance_planet_name) &_
					" ,score_visibility=" & dosql(score_visibility)

			if skin = 0 then
				skin = "s_default"
			else
				skin = "s_transparent"
			end if

			query = query & ", skin=" & dosql(skin)

			if deletingaccount and not deleteaccount then
				query = query & ", deletion_date=null"
			end if

			if not deletingaccount and deleteaccount then
				query = query & ", deletion_date=now() + INTERVAL '2 days'"
			end if

			query = query & " WHERE id=" & UserId
		case 3
			if Request.Form("holidays") then
				set oRs = oConn.Execute("SELECT COALESCE(int4(date_part('epoch', now()-last_holidays)), 10000000) AS holidays_cooldown, (SELECT 1 FROM users_holidays WHERE userid=users.id) FROM users WHERE id="&UserId)

				if oRs(0) > holidays_breaktime and isnull(oRs(1)) then
					query = "INSERT INTO users_holidays(userid, start_time, min_end_time, end_time) VALUES("&UserId&",now()+INTERVAL '24 hours', now()+INTERVAL '72 hours', now()+INTERVAL '22 days')"
					oConn.Execute query, , adExecuteNoRecords

					response.redirect "?cat=3"
					response.end
				end if
			end if
		case 4
			dim x, typ, subtyp

			oConn.Execute "DELETE FROM users_reports WHERE userid="&userid, , adExecuteNoRecords

			for each x in Request.Form("r")
				typ = fix(x / 100)
				subtyp = x mod 100
				oConn.Execute "INSERT INTO users_reports(userid, type, subtype) VALUES("&userid&","&dosql(typ)&","&dosql(subtyp)&")", , adExecuteNoRecords
			next
		case 5
			if autosignature <> "" then
				query = "UPDATE users SET" &_
						" autosignature=" & dosql(autosignature) &_
						" WHERE id=" & UserId

				oConn.Execute query, , adExecuteNoRecords
			end if
	end select

	if query <> "" then oConn.Execute query, , adExecuteNoRecords
	DoRedirect = true
end if

if DoRedirect then
	Response.Redirect "options.asp?cat=" & optionCat
else
	displayPage
end if

%>