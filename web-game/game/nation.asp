<% Option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "nation"


sub display_nation_search(nation)
	dim content, oRs, query

	set content = GetTemplate("nation-search")
	content.addAllowedImageDomain "*"

	query = "SELECT login" &_
			" FROM users" &_
			" WHERE upper(login) ILIKE upper(" & dosql( "%" & nation & "%") & ")" &_
			" ORDER BY upper(login)"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "nation", oRs(0)
		content.Parse "nation"

		oRs.MoveNext
	wend

	content.Parse ""
	display(content)
end sub

sub display_nation()
	dim content, oRs, query

	dim nation, nationId

	nation = Trim(Request.QueryString("name"))

	' if no nation is given then display info on the current player
	if nation = "" then	nation = oPlayerInfo("login")

	set content = GetTemplate("nation")
	content.addAllowedImageDomain "*"

	query = "SELECT u.login, u.avatar_url, u.description, sp_relation(u.id, "&UserID&"), " &_
			" u.alliance_id, a.tag, a.name, u.id, GREATEST(u.regdate, u.game_started) AS regdate, r.label," &_
			" COALESCE(u.alliance_joined, u.regdate), u.alliance_taxes_paid, u.alliance_credits_given, u.alliance_credits_taken," &_
			" u.id" &_
			" FROM users AS u" &_
			" LEFT JOIN alliances AS a ON (u.alliance_id = a.id) " &_
			" LEFT JOIN alliances_ranks AS r ON (u.alliance_id = r.allianceid AND u.alliance_rank = r.rankid) " &_
			" WHERE upper(u.login) = upper(" & dosql(nation) & ") LIMIT 1"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		if nation <> "" then
			display_nation_search(nation)
			'Response.Redirect "ranking-players.asp?n=" & Server.URLEncode(nation)
		else
			Response.Redirect "nation.asp"
		end if
		Response.End
	end if

	nationId = oRs("id")

	content.AssignValue "name", oRs(0)
	content.AssignValue "regdate", oRs(8)

	content.AssignValue "alliance_joined", oRs(10).Value

	if isNull(oRs(1)) or oRs(1) = "" then
		content.Parse "noavatar"
	else
		content.AssignValue "avatar_url", oRs(1)
		content.Parse "avatar"
	end if

	if oRs(7) <> UserId then content.Parse "sendmail"

	if not isNull(oRs(2)) and oRs(2) <> "" then
		content.AssignValue "description", oRs(2)
		content.Parse "description"
	end if

	if oRs(3) < rFriend then
		content.Parse "enemy"
	elseif oRs(3) = rFriend then
		content.Parse "friend"
	elseif oRs(3) > rFriend then  ' display planets & fleets of alliance members if has the rights for it
		dim show_details

		if oRs(3) = rAlliance then
			content.Parse "ally"
			show_details = oAllianceRights("leader") or oAllianceRights("can_see_members_info")
		else
			content.Parse "self"
			show_details = true
		end if

		if show_details then 
			if oRs(3) = rAlliance then
				if not oAllianceRights("leader") then
					show_details = false
				end if
			end if

			if show_details then'oRs(3) = rSelf or oAllianceRights("leader") ) then
				' view current nation planets
				dim oPlanetsRs
				query = "SELECT name, galaxy, sector, planet FROM vw_planets WHERE ownerid=" & oRs(7)

				query = query & " ORDER BY id"
				set oPlanetsRs = oConn.Execute(query)

				if oPlanetsRs.EOF then
					content.Parse "allied.noplanets"
				end if

				while not oPlanetsRs.EOF 
					content.AssignValue "planetname", oPlanetsRs(0)
					content.AssignValue "g", oPlanetsRs(1)
					content.AssignValue "s", oPlanetsRs(2)
					content.AssignValue "p", oPlanetsRs(3)
					content.Parse "allied.planet"
					oPlanetsRs.MoveNext
				wend
			end if

			' view current nation fleets
			dim oFleetsRs

			query = "SELECT id, name, attackonsight, engaged, remaining_time, " &_
				" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, sp_relation(planet_ownerid, ownerid)," &_
				" destplanetid, destplanet_name, destplanet_galaxy, destplanet_sector, destplanet_planet, destplanet_ownerid, destplanet_owner_name, sp_relation(destplanet_ownerid, ownerid)," &_
				" action, signature, sp_get_user_rs(ownerid, planet_galaxy, planet_sector), sp_get_user_rs(ownerid, destplanet_galaxy, destplanet_sector)" &_
				" FROM vw_fleets WHERE ownerid=" & oRs(7)

			if oRs(3) = rAlliance then
				if not oAllianceRights("leader") then
					query = query & " AND action <> 0"
				end if
			end if

			query = query & " ORDER BY planetid, upper(name)"

			set oFleetsRs = oConn.Execute(query)

			if oFleetsRs.EOF then content.Parse "allied.nofleets"

			while not oFleetsRs.EOF 
				content.AssignValue "fleetid", oFleetsRs(0)
				content.AssignValue "fleetname", oFleetsRs(1)
				content.AssignValue "planetid", oFleetsRs(5)
				content.assignValue "signature", oFleetsRs(22)
				content.AssignValue "g", oFleetsRs(7)
				content.AssignValue "s", oFleetsRs(8)
				content.AssignValue "p", oFleetsRs(9)
				if oFleetsRs(4) then
					content.AssignValue "time", oFleetsRs(4)
				else
					content.AssignValue "time", 0
				end if

				content.AssignValue "relation", oFleetsRs(12)
				content.AssignValue "planetname", getPlanetName(oFleetsRs(12), oFleetsRs(23), oFleetsRs(11), oFleetsRs(6))

	'			if oFleetsRs(12) < rAlliance and not IsNull(oFleetsRs(11)) then
	'				if oFleetsRs(23) > 0 or oFleetsRs(12) = rFriend then
	'					content.AssignValue "planetname", oFleetsRs(11)
	'				else
	'					content.AssignValue "planetname", ""
	'				end if
	'			else
	'				content.AssignValue "planetname", oFleetsRs(6)
	'			end if

				if oRs(3) = rAlliance then
					content.Parse "allied.fleet.ally"
				else
					content.Parse "allied.fleet.owned"
				end if


				if oFleetsRs(3) then
					content.Parse "allied.fleet.fighting"
				elseif oFleetsRs(21)=2 then				
					content.Parse "allied.fleet.recycling"
				elseif not isNull(oFleetsRs(13)) then
					' Assign destination planet
					content.AssignValue "t_planetid", oFleetsRs(13)
					content.AssignValue "t_g", oFleetsRs(15)
					content.AssignValue "t_s", oFleetsRs(16)
					content.AssignValue "t_p", oFleetsRs(17)
					content.AssignValue "t_relation", oFleetsRs(20)
					content.AssignValue "t_planetname", getPlanetName(oFleetsRs(20), oFleetsRs(24), oFleetsRs(19), oFleetsRs(14))

	'				if oFleetsRs(20) < rAlliance and not IsNull(oFleetsRs(19)) then
	'					if oFleetsRs(24) > 0 or oFleetsRs(20) = rFriend then
	'						content.AssignValue "t_planetname", oFleetsRs(19)
	'					else
	'						content.AssignValue "t_planetname", ""
	'					end if
	'				else
	'					content.AssignValue "t_planetname", oFleetsRs(14)
	'				end if
					content.Parse "allied.fleet.moving"
				else
					content.Parse "allied.fleet.patrolling"
				end if

				content.Parse "allied.fleet"
				oFleetsRs.MoveNext
			wend

			content.Parse "allied"
		end if
	end if
	
	if not isNull(oRs(4)) then
		content.AssignValue "alliancename", oRs(6)
		content.AssignValue "alliancetag", oRs(5)
		content.AssignValue "rank_label", oRs(9)

		select case oRs(3)
			case rSelf
				content.Parse "alliance.self"
			case rAlliance
				content.Parse "alliance.ally"
			case rFriend
				content.Parse "alliance.friend"
			case else
				content.Parse "alliance.enemy"
		end select 

		content.Parse "alliance"
	else
		content.Parse "noalliance"
	end if


	query = "SELECT alliance_tag, alliance_name, joined, ""left""" &_
			" FROM users_alliance_history" &_
			" WHERE userid = " & dosql(nationId) & " AND joined > (SELECT GREATEST(regdate, game_started) FROM users WHERE privilege < 100 AND id=" & dosql(nationId) & ")" &_
			" ORDER BY joined DESC"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "history_tag", oRs(0).value
		content.AssignValue "history_name", oRs(1).value
		content.AssignValue "joined", oRs(2).value
		content.AssignValue "left", oRs(3).value
		content.Parse "alliances.item"
		oRs.MoveNext
	wend

	content.Parse "alliances"


	content.Parse ""
	display(content)
end sub


display_nation

%>