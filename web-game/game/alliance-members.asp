<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.members"


if IsNull(AllianceId) then RedirectTo "/game/alliance.asp"
if not oAllianceRights("leader") and not oAllianceRights("can_see_members_info") then RedirectTo "/game/alliance.asp"

dim username
dim invitation_success
invitation_success = ""

sub DisplayMembers(content)
	dim col, reversed, orderby, i
	col = ToInt(Request.QueryString("col"), 1)
	if col < 1 or col > 7 then col = 1

	select case col
		case 1
			orderby = "upper(login)"
		case 2
			orderby = "score"
			reversed = true
		case 3
			orderby = "colonies"
			reversed = true
		case 4
			orderby = "credits"
			reversed = true
		case 5
			orderby = "lastactivity"
			reversed = true
		case 6
			orderby = "alliance_joined"
			reversed = true
		case 7
			orderby = "alliance_rank"
			reversed = false
	end select
	
	dim ParseR
	ParseR = false
	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		ParseR = true
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", upper(login)"

	dim query, oRs

	' list ranks
	query = "SELECT rankid, label" &_
			" FROM alliances_ranks" &_
			" WHERE enabled AND allianceid=" & AllianceId &_
			" ORDER BY rankid"
	set oRs = oConn.Execute(query)
	while not oRs.EOF
		content.AssignValue "rank_id", oRs(0)
		content.AssignValue "rank_label", oRs(1)
		content.Parse "members.rank"
		oRs.MoveNext
	wend


	' list members
	query = "SELECT login, CASE WHEN id="&UserId&" OR score_visibility >=1 THEN score ELSE 0 END AS score, int4((SELECT count(1) FROM nav_planet WHERE ownerid=users.id)) AS colonies," &_
			" date_part('epoch', now()-lastactivity) / 3600, alliance_joined, alliance_rank, privilege, score-previous_score AS score_delta, id," &_
			" sp_alliance_get_leave_cost(id), credits, score_visibility, orientation, COALESCE(date_part('epoch', leave_alliance_datetime-now()), 0)" &_
			" FROM users" &_
			" WHERE alliance_id=" & AllianceId &_
			" ORDER BY " & orderby
	set oRs = oConn.Execute(query)

	if oAllianceRights("can_kick_player") then
		content.Parse "members.recruit"
	else
		content.Parse "members.viewonly"
	end if

	if ParseR then content.Parse "members.r" & col

	dim totalColonies, totalCredits, totalScore, totalScoreDelta

	totalColonies = 0 
	totalCredits = 0
	totalScore = 0
	totalScoreDelta = 0
	i = 1
	while not oRs.EOF
		totalColonies = totalColonies + oRs(2)
		totalCredits = totalCredits + oRs(10)

		content.AssignValue "place", i
		content.AssignValue "name", oRs(0)
		content.AssignValue "score", oRs(1)
		content.AssignValue "score_delta", oRs(7)
		content.AssignValue "stat_colonies", oRs(2)
		content.AssignValue "hours", int(oRs(3))
		content.AssignValue "days", int(oRs(3) / 24)
		content.AssignValue "joined", oRs(4).Value
		content.AssignValue "rank", oRs(5)
		content.AssignValue "id", oRs(8)

		content.Parse "members.player.orientation" & oRs(12)

		if oRs(5) > AllianceRank and oAllianceRights("can_kick_player") then
			content.AssignValue "kick_price", oRs(9)
		else
			content.AssignValue "kick_price", 0
		end if

		content.AssignValue "credits", oRs(10)

		if oRs(10) < 0 then content.Parse "members.player.lowcredits"

		if oRs("score_visibility") >= 1 or oRs("id") = UserId then
			totalScore = totalScore + oRs(1)
			totalScoreDelta = totalScoreDelta + oRs(7)

			if oRs(7) > 0 then content.Parse "members.player.score.plus"
			if oRs(7) < 0 then content.Parse "members.player.score.minus"
			content.Parse "members.player.score"
		else
			content.Parse "members.player.score_na"
		end if

		if oRs(6) = -1 then
			content.Parse "members.player.banned"
		elseif oRs(6) = -2 Then
			content.Parse "members.player.onholidays"
		'less than 15mins ? = 1/4 h
		elseif oRs(3) < 0.25 Then
			content.Parse "members.player.online"		
		elseif oRs(3) < 1 then
			content.Parse "members.player.less1h"
		elseif oRs(3) < 1*24 then
			content.Parse "members.player.hours"
		elseif oRs(3) < 7*24 then
			content.Parse "members.player.days"
		elseif oRs(3) <= 14*24 then
			content.Parse "members.player.1weekplus"
		elseif oRs(3) > 14*24 then
			content.Parse "members.player.2weeksplus"
		end if

		if oAllianceRights("leader") then
			if oRs(5) > AllianceRank or oRs(8) = UserId then
				content.Parse "members.player.manage"
			else
				content.Parse "members.player.cant_manage"
			end if
		end if

		if oRs(13) > 0 then
			content.AssignValue "leaving_time", oRs(13)
			content.Parse "members.player.leaving"
		elseif oRs(13) = 0 then
			if oAllianceRights("can_kick_player") then
				if oRs(5) > AllianceRank then
					content.Parse "members.player.kick"
				else
					content.Parse "members.player.cant_kick"
				end if
			end if
		end if

		content.Parse "members.player"

		i = i + 1
		oRs.MoveNext
	wend

	content.AssignValue "total_colonies", totalColonies
	content.AssignValue "total_credits", totalCredits
	content.AssignValue "total_score", totalScore
	content.AssignValue "total_score_delta", totalScoreDelta

	if totalScore <> 0 then
		if totalScoreDelta > 0 then content.Parse "members.score.plus"
		if totalScoreDelta < 0 then content.Parse "members.score.minus"
		content.Parse "members.score"
	else
		content.Parse "members.score_na"
	end if

	content.Parse "members"
end sub

sub displayInvitations(content)
	dim query, oRs, i

	if oAllianceRights("can_invite_player") then
		query = "SELECT recruit.login, created, recruiters.login, declined" &_
				" FROM alliances_invitations" &_
				"		INNER JOIN users AS recruit ON recruit.id = alliances_invitations.userid" &_
				"		LEFT JOIN users AS recruiters ON recruiters.id = alliances_invitations.recruiterid" &_
				" WHERE allianceid=" & AllianceId &_
				" ORDER BY created DESC"

		set oRs = oConn.Execute(query)

		i = 0
		while not oRs.EOF
			content.AssignValue "name", oRs(0)
			content.AssignValue "date", oRs(1).Value
			content.AssignValue "recruiter", oRs(2)

			if oRs(3) then content.Parse "invitations.invitation.declined" else content.Parse "invitations.invitation.waiting"

			content.Parse "invitations.invitation"

			i = i + 1
			oRs.MoveNext
		wend

		if i = 0 then content.Parse "invitations.noinvitations"

		if invitation_success <> "" then 
			content.Parse "invitations.message." & invitation_success
			content.Parse "invitations.message"
		end if

		content.AssignValue "player", username

		content.Parse "invitations"
	end if
end sub

'
' Load template and display the right page
'
sub displayPage(cat)
	dim content
	set content = GetTemplate("alliance-members")

	content.AssignValue "cat", cat

	select case cat
		case 1
			displayMembers content
		case 2
			displayInvitations content
	end select

	if oAllianceRights("can_invite_player") then
		content.Parse "nav.cat" & cat & ".selected"
		content.Parse "nav.cat1"
		content.Parse "nav.cat2"
		content.Parse "nav"
	end if

	content.Parse ""

	Display(content)
end sub

sub SaveRanks()
	' retrieve alliance members' id and assign new rank
	dim query, oRs
	query = "SELECT id" &_
			" FROM users" &_
			" WHERE alliance_id=" & AllianceId
	set oRs = oConn.Execute(query)

	on error resume next

	while not oRs.EOF
		query = " UPDATE users SET" &_
				" alliance_rank=" & ToInt(Request.Form("player" & oRs(0)), 100) &_
				" WHERE id=" & oRs(0) & " AND alliance_id=" & AllianceId & " AND (alliance_rank > 0 OR id=" & UserId & ")"
		oConn.Execute query, , adExecuteNoRecords
		oRs.MoveNext
	wend

	' if leader demotes himself
	if ToInt(Request.Form("player" & UserId), 100) > 0 then RedirectTo "alliance.asp"
end sub

dim cat
cat = Request.QueryString("cat")
if cat <> 1 and cat <> 2 then cat = 1

'
' Process actions
'
dim action
action = Trim(Request.QueryString("a"))
username = Trim(Request.Form("name"))

if cat = 1 then
	if oAllianceRights("leader") and Request.Form("submit") <> "" then SaveRanks()

	if oAllianceRights("can_kick_player") then
		if action = "kick" then
			username = Trim(Request.QueryString("name"))
			oConn.Execute("SELECT sp_alliance_kick_member("&UserID&","&dosql(username)&")")
		end if
	end if
end if

if cat = 2 then
	if oAllianceRights("can_invite_player") then
		dim oRs
		set oRs = oConn.Execute("SELECT sp_alliance_invite(" & UserID & "," & dosql(username) & ")")
		select case oRs(0)
			case 0
				invitation_success = "ok"
				username = ""
			case 1
				invitation_success = "norights"
			case 2
				invitation_success = "unknown"
			case 3
				invitation_success = "already_member"
			case 5
				invitation_success = "already_invited"
			case 6
				invitation_success = "impossible"
		end select
	end if
end if

DisplayPage cat

%>