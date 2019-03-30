<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "ranking.galaxies"


sub DisplayRanking(g)
	dim content, query, oRs, i
	set content = GetTemplate("ranking-galaxies")
	
	query = "SELECT id FROM nav_galaxies ORDER BY id"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "galaxyid", oRs(0)
		if oRs(0) = g then content.Parse "galaxy.selected"
		content.Parse "galaxy"
		oRs.MoveNext
	wend


	query = "SELECT ownerid, login, avatar_url, alliances.tag, alliances.name, int4(sum(nav_planet.score)/1024), count(*)" &_
			" FROM nav_planet" &_
			"	INNER JOIN users ON users.id=ownerid" &_
			"	LEFT JOIN alliances ON users.alliance_id=alliances.id" &_
			" WHERE ownerid > 100 AND galaxy=" & g &_
			" GROUP BY ownerid, login, avatar_url, alliances.tag, alliances.name" &_
			" ORDER BY sum(nav_planet.score) DESC" &_
			" LIMIT 5"
	set oRs = oConn.Execute(query)

	dim found
	found = false
	i = 1
	while not oRs.EOF
		content.AssignValue "place", i

		if oRs(0) = UserId then
			content.Parse "player.self"
			found = true
		end if

		content.AssignValue "id", oRs(0)
		content.AssignValue "name", oRs(1)

		if not isnull(oRs(2)) and oRs(2) <> "" then
			content.AssignValue "avatar_url", oRs(2)
			content.Parse "player.avatar"
		else
			content.Parse "player.noavatar"
		end if

		if not isnull(oRs(3)) and oRs(3) <> "" then
			content.AssignValue "alliancetag", oRs(3)
			content.AssignValue "alliancename", oRs(4)
			content.Parse "player.alliance"
		else
			content.Parse "player.noalliance"
		end if

		content.AssignValue "score", oRs(5)

		content.Parse "player"

		i = i + 1
		oRs.MoveNext
	wend

	if not found then
		' find score of player and number of colonies in the given galaxy
		query = "SELECT int4(sum(score)/1024), int4(count(*)) FROM nav_planet WHERE galaxy=" & g & " AND ownerid=" & UserId & " LIMIT 1"
		set oRs = oConn.Execute(query)

		if not oRs.EOF and oRs(1) > 0 then

			content.AssignValue "score", oRs(0)

			' find position of the player
			query = "SELECT int4(count(1)) FROM" &_
					" (SELECT ownerid, sum(score)" &_
					" FROM nav_planet" &_
					" WHERE ownerid > 100 AND galaxy=" & g &_
					" GROUP BY ownerid" &_
					" HAVING sum(score) >= "&oRs(0)&"*1024) as t"
			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				content.AssignValue "place", oRs(0)

				content.AssignValue "id", UserId
				content.AssignValue "name", oPlayerInfo("login")

				' retrieve player info
				query = "SELECT avatar_url, tag, name FROM users LEFT JOIN alliances ON alliances.id=users.alliance_id WHERE users.id=" & UserId
				set oRs = oConn.Execute(query)

				if not isnull(oRs(0)) and oRs(0) <> "" then
					content.AssignValue "avatar_url", oRs(0)
					content.Parse "player.avatar"
				else
					content.Parse "player.noavatar"
				end if

				if not isnull(oRs(1)) then
					content.AssignValue "alliancetag", oRs(1)
					content.AssignValue "alliancename", oRs(2)
					content.Parse "player.alliance"
				end if

				content.Parse "player.self"
				content.Parse "player"
			end if

		end if
	end if

	content.Parse ""

	Display(content)
end sub

if Session(sPrivilege) < 100 then RedirectTo "/game/overview.asp"

dim g
g = ToInt(Request.QueryString("g"), CurrentGalaxyId)

DisplayRanking(g)

%>