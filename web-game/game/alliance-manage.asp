<%option explicit %>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "alliance.manage"


dim changes_status

'
' Display alliance description page
'
sub displayGeneral(content)
	dim query, oRs

	' Display alliance tag, name, description, creation date, number of members
	query = "SELECT id, tag, name, description, created, (SELECT count(*) FROM users WHERE alliance_id=alliances.id), logo_url," &_
			" max_members" &_
			" FROM alliances" &_
			" WHERE id=" & AllianceId

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		content.AssignValue "tag", oRs(1)
		content.AssignValue "name", oRs(2)
		content.AssignValue "description", oRs(3)
		content.AssignValue "created", oRs(4).Value
		content.AssignValue "members", oRs(5)
		content.AssignValue "max_members", oRs(7)

		if oRs(6) <> "" then
			content.AssignValue "logo_url", oRs(6)
			content.Parse "general.logo"
		end if
	end if

	content.Parse "general"
end sub

'
' Display alliance MotD (message of the day)
'
sub displayMotD(content)
	dim query, oRs, i

	' Display alliance MotD (message of the day)
	query = "SELECT announce, defcon FROM alliances WHERE id=" & AllianceId
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		content.AssignValue "motd", oRs(0)
		content.Parse "motd.defcon_" & oRs(1)
	end if

	content.Parse "motd"
end sub

sub displayRanks(content)
	dim query, oRs, i

	' list ranks
	query = "SELECT rankid, label, leader, can_invite_player, can_kick_player, can_create_nap, can_break_nap, can_ask_money, can_see_reports, " &_
			" can_accept_money_requests, can_change_tax_rate, can_mail_alliance, is_default, members_displayed, can_manage_description, can_manage_announce, " &_
			" enabled, can_see_members_info, can_order_other_fleets, can_use_alliance_radars" &_
			" FROM alliances_ranks" &_
			" WHERE allianceid=" & AllianceId &_
			" ORDER BY rankid"
	set oRs = oConn.Execute(query)
	while not oRs.EOF
		content.AssignValue "rank_id", oRs(0)
		content.AssignValue "rank_label", oRs(1)

		if oRs("leader") then content.Parse "ranks.rank.disabled"

		if oRs("leader") or oRs("enabled") then content.Parse "ranks.rank.checked_enabled"

		if oRs("leader") or oRs("is_default") and not oRs("leader") then content.Parse "ranks.rank.checked_0"

		if oRs("leader") or oRs("can_invite_player") then content.Parse "ranks.rank.checked_1"
		if oRs("leader") or oRs("can_kick_player") then content.Parse "ranks.rank.checked_2"

		if oRs("leader") or oRs("can_create_nap") then content.Parse "ranks.rank.checked_3"
		if oRs("leader") or oRs("can_break_nap") then content.Parse "ranks.rank.checked_4"

		if oRs("leader") or oRs("can_ask_money") then content.Parse "ranks.rank.checked_5"
		if oRs("leader") or oRs("can_see_reports") then content.Parse "ranks.rank.checked_6"

		if oRs("leader") or oRs("can_accept_money_requests") then content.Parse "ranks.rank.checked_7"
		if oRs("leader") or oRs("can_change_tax_rate") then content.Parse "ranks.rank.checked_8"

		if oRs("leader") or oRs("can_mail_alliance") then content.Parse "ranks.rank.checked_9"

		if oRs("leader") or oRs("can_manage_description") then content.Parse "ranks.rank.checked_10"
		if oRs("leader") or oRs("can_manage_announce") then content.Parse "ranks.rank.checked_11"

		if oRs("leader") or oRs("can_see_members_info") then content.Parse "ranks.rank.checked_12"

		if oRs("leader") or oRs("members_displayed") then content.Parse "ranks.rank.checked_13"

		if oRs("leader") or oRs("can_order_other_fleets") then content.Parse "ranks.rank.checked_14"
		if oRs("leader") or oRs("can_use_alliance_radars") then content.Parse "ranks.rank.checked_15"

		content.Parse "ranks.rank"
		oRs.MoveNext
	wend

	content.Parse "ranks"
end sub

'
' Load template and display the right page
'
sub displayOptions(cat)
	dim content
	set content = GetTemplate("alliance-manage")
	content.AssignValue "cat", cat

	select case cat
		case 1
			displayGeneral content
		case 2
			displayMotD content
		case 3
			displayRanks content
	end select

	if changes_status <> "" then
		content.Parse "error." & changes_status
		content.Parse "error"
	end if

	content.Parse "nav.cat"&cat&".selected"
	if oAllianceRights("leader") or oAllianceRights("can_manage_description") then content.Parse "nav.cat1"
	if oAllianceRights("leader") or oAllianceRights("can_manage_announce") then content.Parse "nav.cat2"
	if oAllianceRights("leader") then content.Parse "nav.cat3"
	content.Parse "nav"

	content.Parse ""

	Display(content)
end sub

sub SaveGeneral()
	dim logo, description

	logo = Trim(Request.Form("logo"))
	description = Trim(Request.Form("description"))

	if logo <> "" and not isValidURL(logo) then
		'logo is invalid
		changes_status = "check_logo"
	else
		' save updated information
		oConn.Execute "UPDATE alliances SET logo_url=" & dosql(logo) & ", description=" & dosql(description) & " WHERE id = " & AllianceId, , adExecuteNoRecords

		changes_status = "done"
	end if
end sub

sub SaveMotD()
	dim MotD, defcon

	MotD = Trim(Request.Form("motd"))
	defcon = ToInt(Request.Form("defcon"), 5)

	' save updated information
	oConn.Execute "UPDATE alliances SET defcon=" & dosql(defcon) & ", announce=" & dosql(MotD) & " WHERE id = " & AllianceId, , adExecuteNoRecords
	changes_status = "done"
end sub

sub SaveRanks()
	dim query, oRs

	' list ranks
	query = "SELECT rankid, leader" &_
			" FROM alliances_ranks" &_
			" WHERE allianceid=" & AllianceId &_
			" ORDER BY rankid"
	set oRs = oConn.Execute(query)
	while not oRs.EOF
		dim name
		name = Trim(Request.Form("n" & oRs(0)))
		if Len(name) > 2 then
			query = "UPDATE alliances_ranks SET" &_
					" label=" & dosql(name) &_
					", is_default=NOT leader AND " & cbool(Request.Form("c" & oRs(0) & "_0")) &_
					", can_invite_player=leader OR " & cbool(Request.Form("c" & oRs(0) & "_1")) &_
					", can_kick_player=leader OR " & cbool(Request.Form("c" & oRs(0) & "_2")) &_
					", can_create_nap=leader OR " & cbool(Request.Form("c" & oRs(0) & "_3")) &_
					", can_break_nap=leader OR " & cbool(Request.Form("c" & oRs(0) & "_4")) &_
					", can_ask_money=leader OR " & cbool(Request.Form("c" & oRs(0) & "_5")) &_
					", can_see_reports=leader OR " & cbool(Request.Form("c" & oRs(0) & "_6")) &_
					", can_accept_money_requests=leader OR " & cbool(Request.Form("c" & oRs(0) & "_7")) &_
					", can_change_tax_rate=leader OR " & cbool(Request.Form("c" & oRs(0) & "_8")) &_
					", can_mail_alliance=leader OR " & cbool(Request.Form("c" & oRs(0) & "_9")) &_
					", can_manage_description=leader OR " & cbool(Request.Form("c" & oRs(0) & "_10")) &_
					", can_manage_announce=leader OR " & cbool(Request.Form("c" & oRs(0) & "_11")) &_
					", can_see_members_info=leader OR " & cbool(Request.Form("c" & oRs(0) & "_12")) &_
					", members_displayed=leader OR " & cbool(Request.Form("c" & oRs(0) & "_13")) &_
					", can_order_other_fleets=leader OR " & cbool(Request.Form("c" & oRs(0) & "_14")) &_
					", can_use_alliance_radars=leader OR " & cbool(Request.Form("c" & oRs(0) & "_15")) &_
					", enabled=leader OR EXISTS(SELECT 1 FROM users WHERE alliance_id=" & AllianceId & " AND alliance_rank=" & oRs(0)& " LIMIT 1) OR " & cbool(Request.Form("c" & oRs(0) & "_enabled")) & " OR " & cbool(Request.Form("c" & oRs(0) & "_0")) &_
					" WHERE allianceid=" & AllianceId & " AND rankid=" & oRs(0)

			connExecuteRetryNoRecords query
		end if

		oRs.MoveNext
	wend
end sub

if IsNull(AllianceId) then RedirectTo "alliance.asp"
if not (oAllianceRights("leader") or oAllianceRights("can_manage_description") or oAllianceRights("can_manage_announce")) then RedirectTo "alliance.asp"

dim cat
cat = ToInt(Request.QueryString("cat"), 1)
if cat < 1 or cat > 3 then cat = 1

if cat = 3 and not oAllianceRights("leader") then cat=1
if cat = 1 and not (oAllianceRights("leader") or oAllianceRights("can_manage_description")) then cat=2
if cat = 2 and not (oAllianceRights("leader") or oAllianceRights("can_manage_announce")) then cat=1

if Request.Form("submit") <> "" then
	select case cat
		case 1
			SaveGeneral()
		case 2
			SaveMotD()
		case 3
			SaveRanks()
	end select
end if

if not pageTerminated then DisplayOptions cat

%>