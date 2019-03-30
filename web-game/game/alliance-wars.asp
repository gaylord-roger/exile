<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.wars"

dim result, cease_success
result = ""
cease_success = ""

sub DisplayWars(content)
	dim col, reversed, orderby
	col = Request.QueryString("col")
	if col < 1 or col > 2 then col = 1

	select case col
		case 1
			orderby = "tag"
		case 2
			orderby = "created"
			reversed = true
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "wars.r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", tag"

	' List wars
	dim query, oRs
	query = "SELECT w.created, alliances.id, alliances.tag, alliances.name, cease_fire_requested, date_part('epoch', cease_fire_expire-now())::integer, w.can_fight < now() AS can_fight, true AS attacker, next_bill < now() + INTERVAL '1 week', sp_alliance_war_cost(allianceid2), next_bill"&_
			" FROM alliances_wars w" &_
			"	INNER JOIN alliances ON (allianceid2 = alliances.id)" &_
			" WHERE allianceid1=" & AllianceId &_
			" UNION " &_
			"SELECT w.created, alliances.id, alliances.tag, alliances.name, cease_fire_requested, date_part('epoch', cease_fire_expire-now())::integer, w.can_fight < now() AS can_fight, false AS attacker, false, 0, next_bill"&_
			" FROM alliances_wars w" &_
			"	INNER JOIN alliances ON (allianceid1 = alliances.id)" &_
			" WHERE allianceid2=" & AllianceId &_
			" ORDER BY " & orderby
	set oRs = oConn.Execute(query)

	dim i
	i = 0
	while not oRs.EOF
		content.AssignValue "place", i+1
		content.AssignValue "created", oRs(0).Value
		content.AssignValue "tag", oRs(2)
		content.AssignValue "name", oRs(3)

		if oAllianceRights("can_break_nap") then
			if isnull(oRs("cease_fire_requested")) then
				if oRs(7) then
					if oRs(8) then
						content.AssignValue "cost", oRs(9)
						content.Parse "wars.war.extend"
					end if

					content.Parse "wars.war.stop"
'				else
'					content.Parse "wars.war.surrender"
				end if
			elseif oRs("cease_fire_requested") = AllianceId then
				content.AssignValue "time", oRs(5)
				content.Parse "wars.war.ceasing"
			else
				content.AssignValue "time", oRs(5)
				content.Parse "wars.war.cease_requested"
			end if
		end if

		if oRs(6) then
			content.AssignValue "next_bill", oRs(10).value
			if not isnull(oRs(10).value) then
				content.Parse "wars.war.can_fight"
			end if
		else
			content.Parse "wars.war.cant_fight"
		end if

		content.Parse "wars.war"

		i = i + 1
		oRs.MoveNext
	wend

	if oAllianceRights("can_break_nap") and (i > 0) then content.Parse "wars.cease"

	if i = 0 then content.Parse "wars.nowars"

	if cease_success <> "" then
		content.Parse "wars.message." & cease_success
		content.Parse "wars.message"
	end if

	content.Parse "wars"
end sub

sub displayDeclaration(content)
	if Request.QueryString("a") = "new" then
		dim tag
		tag = Trim(Request.Form("tag"))

		dim oRs
		set oRs = oConn.Execute("SELECT id, tag, name, sp_alliance_war_cost(id) + (const_coef_score_to_war()*sp_alliance_value(" & AllianceId & "))::integer FROM alliances WHERE lower(tag)=lower(" & dosql(tag) & ")")
		if oRs.EOF then
			content.AssignValue "tag", tag

			content.Parse "newwar.message.unknown"
			content.Parse "newwar.message"
			content.Parse "newwar"
		else
			content.AssignValue "tag", oRs(1)
			content.AssignValue "name", oRs(2)
			content.AssignValue "cost", oRs(3)

			content.Parse "newwar_confirm"
		end if
	else
		if result <> "" then
			content.Parse "newwar.message." & result
			content.Parse "newwar.message"
		end if

		content.AssignValue "tag", tag

		content.Parse "newwar"
	end if
end sub

sub displayPage(cat)
	dim content, i
	set content = GetTemplate("alliance-wars")
	content.AssignValue "cat", cat

	select case cat
		case 1
			displayWars content
		case 2
			displayDeclaration content
	end select

	content.Parse "nav.cat" & cat & ".selected"

	content.Parse "nav.cat1"
	if oAllianceRights("can_create_nap") then content.Parse "nav.cat2"
	content.Parse "nav"
	content.Parse ""
	Display(content)
end sub

dim cat
cat = Request.QueryString("cat")
if cat < 1 or cat > 2 then cat = 1

if not (oAllianceRights("can_create_nap") or oAllianceRights("can_break_nap")) and cat <> 1 then cat = 1

'
' Process actions
'

' redirect the player to the alliance page if he is not part of an alliance
if IsNull(AllianceId) then
	Response.Redirect "/game/alliance.asp"
	Response.End
end if

dim action, tag
action = Request.QueryString("a")
tag = ""

dim oRs

select case action
	case "pay"
		tag = Trim(Request.QueryString("tag"))
		set oRs = oConn.Execute("SELECT sp_alliance_war_pay_bill(" & UserId & "," & dosql(tag) & ")")

		select case oRs(0)
			case 0
				cease_success = "ok"
			case 1
				cease_success = "norights"
			case 2
				cease_success = "unknown"
			case 3
				cease_success = "war_not_found"
		end select
	case "stop"
		tag = Trim(Request.QueryString("tag"))
		set oRs = oConn.Execute("SELECT sp_alliance_war_stop(" & UserId & "," & dosql(tag) & ")")

		select case oRs(0)
			case 0
				cease_success = "ok"
			case 1
				cease_success = "norights"
			case 2
				cease_success = "unknown"
			case 3
				cease_success = "war_not_found"
		end select
	case "new2"
		tag = Trim(Request.Form("tag"))

		set oRs = oConn.Execute("SELECT sp_alliance_war_declare(" & UserID & "," & dosql(tag) & ")")
		select case oRs(0)
			case 0
				result = "ok"
				tag = ""
			case 1
				result = "norights"
			case 2
				result = "unknown"
			case 3
				result = "already_at_war"
			case 9
				result = "not_enough_credits"
		end select
end select

displayPage(cat)

%>