<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "noalliance."

sub DisplayAlliance(alliance_tag)
	dim content
	set content = GetTemplate("alliance")
	content.addAllowedImageDomain "*"

	selected_menu = "alliance.overview"

	dim oRs, created, alliance_id, NAPcount
	dim query

	query = "SELECT id, name, tag, description, created, (SELECT count(*) FROM users WHERE alliance_id=alliances.id)," &_
			" logo_url, website_url, max_members" &_
			" FROM alliances"

	if isNull(alliance_tag) then
		query = query & " WHERE id=" & AllianceId & " LIMIT 1"
	else
		query = query & " WHERE tag=upper(" & dosql(alliance_tag) & ") LIMIT 1"
		selected_menu = "ranking"
	end if

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		alliance_id = oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "tag", oRs(2)
		content.AssignValue "description", oRs(3)

		created = oRs(4)
		content.AssignValue "created", created
		content.AssignValue "members", oRs(5)
		content.AssignValue "max_members", oRs(8)

		if not isNull(oRs(3)) and oRs(3) <> "" then
			content.Parse "display.description"
		end if

		if not isNull(oRs(6)) and oRs(6) <> "" then
			content.AssignValue "logo_url", oRs(6)
			content.Parse "display.logo"
		end if


		'
		' Display Non Aggression Pacts (NAP)
		'
		NAPcount = 0

		query = "SELECT allianceid1, tag, name" &_
				" FROM alliances_naps INNER JOIN alliances ON (alliances_naps.allianceid1=alliances.id)" &_
				" WHERE allianceid2=" & alliance_id
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			content.AssignValue "naptag", oRs(1)
			content.AssignValue "napname", oRs(2)
			content.Parse "display.nap"
			NAPcount = NAPcount + 1
			oRs.MoveNext
		wend

		if NAPcount = 0 then
			content.Parse "display.nonaps"
		end if


		'
		' Display WARs
		'
		dim WARcount
		WARcount = 0

	query = "SELECT w.created, alliances.id, alliances.tag, alliances.name"&_
			" FROM alliances_wars w" &_
			"	INNER JOIN alliances ON (allianceid2 = alliances.id)" &_
			" WHERE allianceid1=" & alliance_id &_
			" UNION " &_
			"SELECT w.created, alliances.id, alliances.tag, alliances.name"&_
			" FROM alliances_wars w" &_
			"	INNER JOIN alliances ON (allianceid1 = alliances.id)" &_
			" WHERE allianceid2=" & alliance_id
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			content.AssignValue "wartag", oRs(2)
			content.AssignValue "warname", oRs(3)
			content.Parse "display.war"
			WARcount = NAPcount + 1
			oRs.MoveNext
		wend

		if WARcount = 0 then
			content.Parse "display.nowars"
		end if


		'
		' List members that should be displayed
		'
		dim members, oMembersRs

		query = "SELECT rankid, label" &_
				" FROM alliances_ranks" &_
				" WHERE members_displayed AND allianceid=" & alliance_id &_
				" ORDER BY rankid"
		set oRs = oConn.Execute(query)
		while not oRs.EOF
			members = 0
			content.AssignValue "rank_label", oRs(1)

			query = "SELECT login" &_
					" FROM users" &_
					" WHERE alliance_id=" & alliance_id & " AND alliance_rank = " & dosql(oRs(0)) &_
					" ORDER BY upper(login)"
			set oMembersRs = oConn.Execute(query)

			while not oMembersRs.EOF
				content.AssignValue "member", oMembersRs(0)
				if members = 0 then
					content.Parse "display.members.member"
				else
					content.Parse "display.members.other_member"
				end if

				members = members + 1

				oMembersRs.MoveNext
			wend

			if members > 0 then content.Parse "display.members"
			oRs.MoveNext
		wend

		content.Parse "display"
	end if

	content.Parse ""
	Display(content)
end sub

dim tag
tag = Request.QueryString("tag")

if not isNull(tag) and tag <> "" then
	DisplayAlliance tag
else
	if isNull(AllianceId) then
		Response.Redirect "alliance-invitations.asp"
	else
		'Response.Redirect "alliance-overview.asp"
		DisplayAlliance null
	end if
end if

%>