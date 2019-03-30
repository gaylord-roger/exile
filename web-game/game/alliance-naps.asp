<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.naps"

dim invitation_success, break_success, nap_success

invitation_success = ""
break_success = ""
nap_success = ""

sub DisplayNAPs(content)
	dim col, reversed, orderby
	col = Request.QueryString("col")
	if col < 1 or col > 4 then col = 1
	if col = 2 then col = 1

	select case col
		case 1
			orderby = "tag"
'		case 2
'			orderby = "score"
'			reversed = true
		case 3
			orderby = "created"
			reversed = true
		case 4
			orderby = "break_interval"
		case 5
			orderby = "share_locs"
		case 6
			orderby = "share_radars"
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "naps.r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", tag"

	' List Non Aggression Pacts
	dim query, oRs
	query = "SELECT n.allianceid2, tag, name, "&_
			" (SELECT COALESCE(sum(score)/1000, 0) AS score FROM users WHERE alliance_id=allianceid2), n.created, date_part('epoch', n.break_interval)::integer, date_part('epoch', break_on-now())::integer," &_
			" share_locs, share_radars" &_
			" FROM alliances_naps n" &_
			"	INNER JOIN alliances ON (allianceid2 = alliances.id)" &_
			" WHERE allianceid1=" & AllianceId &_
			" ORDER BY " & orderby
	set oRs = oConn.Execute(query)

	dim i
	i = 0
	while not oRs.EOF
		content.AssignValue "place", i+1
		content.AssignValue "tag", oRs(1)
		content.AssignValue "name", oRs(2)
		content.AssignValue "score", oRs(3)
		content.AssignValue "created", oRs(4).Value

		if isnull(oRs(6)) then
			content.AssignValue "break_interval", oRs(5)
			content.Parse "naps.nap.time"
		else
			content.AssignValue "break_interval", oRs(6)
			content.Parse "naps.nap.countdown"
		end if


		if oRs(7) then
			content.Parse "naps.nap.locs_shared"
		else
			content.Parse "naps.nap.locs_not_shared"
		end if

		if oAllianceRights("can_create_nap") then
			content.Parse "naps.nap.toggle_share_locs"
		end if

		if oRs(8) then
			content.Parse "naps.nap.radars_shared"
		else
			content.Parse "naps.nap.radars_not_shared"
		end if

		if oAllianceRights("can_create_nap") then
			content.Parse "naps.nap.toggle_share_radars"
		end if

		if oAllianceRights("can_break_nap") then
			if isnull(oRs(6)) then
				content.Parse "naps.nap.break"
			else
				content.Parse "naps.nap.broken"
			end if
		end if

		content.Parse "naps.nap"

		i = i + 1
		oRs.MoveNext
	wend

	if oAllianceRights("can_break_nap") and (i > 0) then content.Parse "naps.break"

	if i = 0 then content.Parse "naps.nonaps"

	if break_success <> "" then
		content.Parse "naps.message." & break_success
		content.Parse "naps.message"
	end if

	content.Parse "naps"
end sub

sub displayPropositions(content)
	dim i, query, oRs

	' List NAPs that other alliances have offered
	query = "SELECT alliances.tag, alliances.name, alliances_naps_offers.created, recruiters.login, declined, date_part('epoch', break_interval)::integer" &_
			" FROM alliances_naps_offers" &_
			"			INNER JOIN alliances ON alliances.id = alliances_naps_offers.allianceid" &_
			"			LEFT JOIN users AS recruiters ON recruiters.id = alliances_naps_offers.recruiterid" &_
			" WHERE targetallianceid=" & AllianceId & " AND NOT declined" &_
			" ORDER BY created DESC"
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		content.AssignValue "tag", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "date", oRs(2).Value
		content.AssignValue "recruiter", oRs(3)

		if oRs(4) then content.Parse "newnaps.proposition.declined" else content.Parse "newnaps.proposition.waiting"

		content.AssignValue "break_interval", oRs(5)

		content.Parse "propositions.proposition"

		i = i + 1
		oRs.MoveNext
	wend

	if i = 0 then content.Parse "propositions.nopropositions"

	if nap_success <> "" then
		content.Parse "propositions.message." & nap_success
		content.Parse "propositions.message"
	end if

	content.Parse "propositions"
end sub

sub displayRequests(content)
	dim i, query, oRs

	' List NAPs we proposed to other alliances
	query = "SELECT alliances.tag, alliances.name, alliances_naps_offers.created, recruiters.login, declined, date_part('epoch', break_interval)::integer" &_
			" FROM alliances_naps_offers" &_
			"			INNER JOIN alliances ON alliances.id = alliances_naps_offers.targetallianceid" &_
			"			LEFT JOIN users AS recruiters ON recruiters.id = alliances_naps_offers.recruiterid" &_
			" WHERE allianceid=" & AllianceId &_
			" ORDER BY created DESC"

	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		content.AssignValue "tag", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "date", oRs(2).Value
		content.AssignValue "recruiter", oRs(3)

		if oRs(4) then content.Parse "newnaps.request.declined" else content.Parse "newnaps.request.waiting"

		content.AssignValue "break_interval", oRs(5)

		content.Parse "newnaps.request"

		i = i + 1
		oRs.MoveNext
	wend

	if i = 0 then content.Parse "newnaps.norequests"

	if invitation_success <> "" then
		content.Parse "newnaps.message." & invitation_success
		content.Parse "newnaps.message"
	end if

	content.AssignValue "tag", tag
	content.AssignValue "hours", hours


	content.Parse "newnaps"
end sub

sub displayPage(cat)
	dim content, i
	set content = GetTemplate("alliance-naps")
	content.AssignValue "cat", cat

	select case cat
		case 1
			displayNAPs content
		case 2
			displayPropositions content
		case 3
			displayRequests content
	end select

	if oAllianceRights("can_create_nap") or oAllianceRights("can_break_nap") then
		dim query
		query = "SELECT int4(count(*)) FROM alliances_naps_offers" &_
				" WHERE targetallianceid=" & AllianceId & " AND NOT declined"
		set oRs = oConn.Execute(query)
		content.AssignValue "propositions", oRs(0)
		if oRs(0) > 0 then content.Parse "nav.cat2.propositions"

		query = "SELECT int4(count(*)) FROM alliances_naps_offers" &_
				" WHERE allianceid=" & AllianceId & " AND NOT declined"
		set oRs = oConn.Execute(query)
		content.AssignValue "requests", oRs(0)
		if oRs(0) > 0 then content.Parse "nav.cat3.requests"

		content.Parse "nav.cat" & cat & ".selected"
		content.Parse "nav.cat1"
		content.Parse "nav.cat2"
		if oAllianceRights("can_create_nap") then content.Parse "nav.cat3"
		content.Parse "nav"
	end if

	content.Parse ""
	Display(content)
end sub

dim cat
cat = Request.QueryString("cat")
if cat < 1 or cat > 3 then cat = 1

if not oAllianceRights("can_create_nap") and cat = 3 then cat = 1
if not (oAllianceRights("can_create_nap") or oAllianceRights("can_break_nap")) and cat <> 1 then cat = 1

'
' Process actions
'

' redirect the player to the alliance page if he is not part of an alliance
if IsNull(AllianceId) then
	Response.Redirect "/game/alliance.asp"
	Response.End
end if

dim action, targetalliancetag
action = Request.QueryString("a")
targetalliancetag = Trim(Request.QueryString("tag"))

dim tag, hours

tag = ""
hours = 24

dim oRs

select case action
	case "accept"
		set oRs = oConn.Execute("SELECT sp_alliance_nap_accept(" & UserId & "," & dosql(targetalliancetag) & ")")
		select case oRs(0)
			case 0
				nap_success = "ok"
			case 5
				nap_success = "too_many"
		end select
	case "decline"
		oConn.Execute "SELECT sp_alliance_nap_decline(" & UserId & "," & dosql(targetalliancetag) & ")", , adExecuteNoRecords
	case "cancel"
		oConn.Execute "SELECT sp_alliance_nap_cancel(" & UserId & "," & dosql(targetalliancetag) & ")", , adExecuteNoRecords
	case "sharelocs"
		oConn.Execute "SELECT sp_alliance_nap_toggle_share_locs(" & UserId & "," & dosql(targetalliancetag) & ")", , adExecuteNoRecords
	case "shareradars"
		oConn.Execute "SELECT sp_alliance_nap_toggle_share_radars(" & UserId & "," & dosql(targetalliancetag) & ")", , adExecuteNoRecords
	case "break"
		set oRs = oConn.Execute("SELECT sp_alliance_nap_break(" & UserId & "," & dosql(targetalliancetag) & ")")

		select case oRs(0)
			case 0
				break_success = "ok"
			case 1
				break_success = "norights"
			case 2
				break_success = "unknown"
			case 3
				break_success = "nap_not_found"
			case 4
				break_success = "not_enough_credits"
		end select
	case "new"
		tag = Trim(Request.Form("tag"))

		hours = ToInt(Request.Form("hours"), 0)

		set oRs = oConn.Execute("SELECT sp_alliance_nap_request(" & UserID & "," & dosql(tag) & "," & dosql(hours) & ")")
		select case oRs(0)
			case 0
				invitation_success = "ok"
				tag = ""
				hours = 24
			case 1
				invitation_success = "norights"
			case 2
				invitation_success = "unknown"
			case 3
				invitation_success = "already_naped"
			case 4
				invitation_success = "request_waiting"
			case 6
				invitation_success = "already_requested"
		end select
end select

displayPage(cat)

%>