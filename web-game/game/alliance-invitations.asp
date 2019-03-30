<%option explicit%>

<!--#include file="global.asp"-->

<%
if IsNull(AllianceId) then
	selected_menu = "noalliance.invitations"
else
	selected_menu = "alliance.invitations"
end if

dim sLeaveCost: sLeaveCost = "leavealliancecost"

dim oRs, leave_status, invitation_status
leave_status = ""
invitation_status = ""

sub DisplayInvitations()
	dim content, i
	set content = GetTemplate("alliance-invitations")

	set oRs = oConn.Execute("SELECT date_part('epoch', const_interval_before_join_new_alliance()) / 3600")
	content.AssignValue "hours_before_rejoin", oRs(0)

	dim query

	query = "SELECT alliances.tag, alliances.name, alliances_invitations.created, users.login" &_
			" FROM alliances_invitations" &_
			"		INNER JOIN alliances ON alliances.id = alliances_invitations.allianceid"&_
			"		LEFT JOIN users ON users.id = alliances_invitations.recruiterid"&_
			" WHERE userid=" & UserId & " AND NOT declined" &_
			" ORDER BY created DESC"

	set oRs = oConn.Execute(query)

	dim created

	i = 0
	while not oRs.EOF
		content.AssignValue "tag", oRs(0)
		content.AssignValue "name", oRs(1)

		created = oRs(2)
		content.AssignValue "date", created

		content.AssignValue "recruiter", oRs(3)

		if oPlayerInfo("can_join_alliance") then
			if not isNull(AllianceId) then
				content.Parse "invitation.cant_accept"
			else
				content.Parse "invitation.accept"
			end if
		else
			content.Parse "invitation.cant_join"
		end if

		content.Parse "invitation"

		i = i + 1
		oRs.MoveNext
	wend

	if invitation_status <> "" then content.Parse invitation_status

	if i = 0 then content.Parse "noinvitations"

	' Parse "cant_join" section if the player can't create/join an alliance
	if not oPlayerInfo("can_join_alliance") then content.Parse "cant_join"

	' Display the "leave" section if the player is in an alliance
	if not isNull(AllianceId) and oPlayerInfo("can_join_alliance") then

		dim oRs
		set oRs = oConn.Execute("SELECT sp_alliance_get_leave_cost(" & UserId & ")")

		Session(sLeaveCost) = oRs(0)
		if Session(sLeaveCost) < 2000 then Session(sLeaveCost) = 0

		content.AssignValue "credits", Session(sLeaveCost)

		if Session(sLeaveCost) > 0 then content.Parse "leave.charges"

		if leave_status <> "" then content.Parse "leave." & leave_status

		content.Parse "leave"
	end if

	content.Parse ""

	FillHeaderCredits

	Display(content)
end sub

dim action, alliance_tag
action = Trim(Request.QueryString("a"))
alliance_tag = Trim(Request.QueryString("tag"))

select case action
	case "accept"
		set oRs = oConn.Execute("SELECT sp_alliance_accept_invitation(" & UserId & "," & dosql(alliance_tag) & ")")

		select case oRs(0)
			case 0
				Response.Redirect "alliance.asp"
				Response.End
			case 4
				invitation_status = "max_members_reached"
			case 6
				invitation_status = "cant_rejoin_previous_alliance"
		end select

	case "decline"
		oConn.Execute "SELECT sp_alliance_decline_invitation(" & UserId & "," & dosql(alliance_tag) & ")", , adExecuteNoRecords
	case "leave"
		if not isnull(Session(sLeaveCost)) and Request.Form("leave") = 1 then
			set oRs = oConn.Execute("SELECT sp_alliance_leave(" & UserId & "," & Session(sLeaveCost) & ")")
			if oRs(0) = 0 then
				Response.Redirect "alliance.asp"
				Response.End
			else
				leave_status = "not_enough_credits"
			end if
		end if
end select

DisplayInvitations()

%>