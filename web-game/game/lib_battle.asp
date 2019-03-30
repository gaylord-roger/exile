<%

function FormatBattle(battleid, creator, pointofview, ispubliclink)
	set FormatBattle = nothing

	dim query, oRs, i, killed

	' Retrieve/assign battle info
	query = "SELECT time, planetid, name, galaxy, sector, planet, rounds," &_
			"EXISTS(SELECT 1 FROM battles_ships WHERE battleid=" & battleid & " AND owner_id=" & creator & " AND won LIMIT 1), MD5(key||"&creator&")," & _
			"EXISTS(SELECT 1 FROM battles_ships WHERE battleid=" & battleid & " AND owner_id=" & creator & " AND damages > 0 LIMIT 1) AS see_details" &_
			" FROM battles" &_
			"	INNER JOIN nav_planet ON (planetid=nav_planet.id)" & _
			" WHERE battles.id = " & battleid
	set oRs = oConn.Execute(query)

	if oRs.EOF then exit function

	dim content
	set content = GetTemplate("battle")

	content.AssignValue "battleid", battleid
	content.AssignValue "userid", creator
	content.AssignValue "key", oRs(8)

	if not ispubliclink then
		' link for the freely viewable report of this battle
		content.AssignValue "baseurl", Request.ServerVariables("HTTP_HOST")
		content.Parse "publiclink"
	end if

	content.AssignValue "time", oRs(0).value
	content.AssignValue "planetid", oRs(1)
	content.AssignValue "planet", oRs(2)
	content.AssignValue "g", oRs(3)
	content.AssignValue "s", oRs(4)
	content.AssignValue "p", oRs(5)
	content.AssignValue "rounds", oRs(6)

	dim rounds: rounds = oRs(6)
	dim hasWon: hasWon = oRs(7)
	dim showEnemyDetails: showEnemyDetails = oRs(9) or hasWon or rounds > 1


	dim killsArray, killsCount

	query = "SELECT fleet_id, shipid, destroyed_shipid, sum(count)" &_
			" FROM battles_fleets" &_
			"	INNER JOIN battles_fleets_ships_kills ON (battles_fleets.id=fleetid)" &_
			" WHERE battleid=" & battleid &_
			" GROUP BY fleet_id, shipid, destroyed_shipid" &_
			" ORDER BY sum(count) DESC"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		killsCount = -1
	else
		killsArray = oRs.GetRows()
		killsCount = UBound(killsArray, 2)
	end if


	query = "SELECT owner_name, fleet_name, shipid, shipcategory, shiplabel, count, lost, killed, won, relation1, owner_id , relation2, fleet_id, attacked, mod_shield, mod_handling, mod_tracking_speed, mod_damage, alliancetag" &_
			" FROM sp_get_battle_result(" & battleid & "," & creator & "," & pointofview & ")"

	set oRs = oConn.Execute(query)

	dim tag, lastTag
	dim player, lastPlayer, lastPlayerRelation, lastPlayerAggressive, lastPlayerWon, player_ships, player_lost, player_killed
	dim fleet, fleetName, lastFleet, lastFleetName, fleet_ships, fleet_lost, fleet_killed, lastPlayerColorRelation, playerid, lastPlayerid
	dim category, lastCategory, cat_ships, cat_lost, cat_killed

	if not oRs.EOF then
		playerid = oRs(10)
		lastPlayerid = playerid
		lastPlayerColorRelation = oRs(11)

		player = oRs(0)
		lastPlayer = player

		tag = oRs("alliancetag")
		lastTag = tag

		lastPlayerWon = oRs(8)
		lastPlayerRelation = oRs(9)

		fleet = oRs(12)'oRs(1)
		lastFleet = fleet

		fleetName = oRs(1)
		lastFleetName = fleetName
		'lastFleetId = oRs(12)

		lastPlayerAggressive = oRs(13)

		content.AssignValue "mod_shield", oRs(14)
		content.AssignValue "mod_handling", oRs(15)
		content.AssignValue "mod_tracking_speed", oRs(16)
		content.AssignValue "mod_damage", oRs(17)

		if not showEnemyDetails and oRs(9) < rFriend then
			content.AssignValue "mod_shield", "?"
			content.AssignValue "mod_handling", "?"
			content.AssignValue "mod_tracking_speed", "?"
			content.AssignValue "mod_damage", "?"
		end if
	end if

	category = -1
	lastCategory = -1

	player_ships = 0
	player_lost = 0
	player_killed = 0

	fleet_ships = 0
	fleet_lost = 0
	fleet_killed = 0

	cat_ships = 0
	cat_lost = 0
	cat_killed = 0

	while not oRs.EOF
		playerid = oRs(10)
		player = oRs(0)
		tag = oRs("alliancetag")
		fleet = oRs(12)
		fleetName = oRs(1)
		category = oRs(3)

		if (lastCategory > -1) and (category <> lastCategory or fleet <> lastFleet or player <> lastPlayer) then

			content.AssignValue "ships", cat_ships
			content.AssignValue "lost", cat_lost
			content.AssignValue "killed", cat_killed
			content.AssignValue "after", cat_ships - cat_lost
			content.Parse "opponent.fleet.ship"

			lastCategory = -1
		end if

		' finish a fleet
		if (fleet <> lastFleet) or (player <> lastPlayer) then
			content.AssignValue "fleet", lastFleetName
			content.AssignValue "ships", fleet_ships
			content.AssignValue "lost", fleet_lost
			content.AssignValue "killed", fleet_killed
			content.AssignValue "after", fleet_ships - fleet_lost

			select case lastPlayerColorRelation
				case rSelf
					Content.Parse "opponent.fleet.self"
				case rAlliance
					Content.Parse "opponent.fleet.ally"
				case rFriend
					Content.Parse "opponent.fleet.friend"
				case else
					Content.Parse "opponent.fleet.enemy"
			end select

			content.Parse "opponent.fleet"

			content.AssignValue "mod_shield", oRs(14)
			content.AssignValue "mod_handling", oRs(15)
			content.AssignValue "mod_tracking_speed", oRs(16)
			content.AssignValue "mod_damage", oRs(17)

			if not showEnemyDetails and oRs(9) < rFriend then
				content.AssignValue "mod_shield", "?"
				content.AssignValue "mod_handling", "?"
				content.AssignValue "mod_tracking_speed", "?"
				content.AssignValue "mod_damage", "?"
			end if

			lastFleet = fleet
			lastFleetName = fleetName

			fleet_ships = 0
			fleet_lost = 0
			fleet_killed = 0
		end if

		' finish an opponent
		if player <> lastPlayer then
			if not isnull(lastTag) then
				content.AssignValue "alliancetag", lastTag
				content.Parse "opponent.alliance"
			end if
			content.AssignValue "opponent", lastPlayer
			content.AssignValue "ships", player_ships
			content.AssignValue "lost", player_lost
			content.AssignValue "killed", player_killed
			content.AssignValue "after", player_ships - player_lost

			select case lastPlayerColorRelation
				case rSelf
					Content.Parse "opponent.self"
				case rAlliance
					Content.Parse "opponent.ally"
				case rFriend
					Content.Parse "opponent.friend"
				case else
					Content.Parse "opponent.enemy"
			end select

			if lastPlayerWon then content.Parse "opponent.won"

			if lastPlayerAggressive then
				content.Parse "opponent.attack"
			else
				content.Parse "opponent.defend"
			end if

			lastPlayerAggressive = false

			content.AssignValue "view", lastPlayerid

			if ispubliclink then content.Parse "opponent.public"

			content.Parse "opponent"


			lastTag = tag
			lastPlayer = player
			lastPlayerid = playerid
			lastPlayerWon = oRs(8)
			lastPlayerColorRelation = oRs(11)
			lastPlayerRelation = oRs(9)

			player_ships = 0
			player_lost = 0
			player_killed = 0
		end if

		lastPlayerAggressive = lastPlayerAggressive or oRs(13)

		if showEnemyDetails or lastPlayerRelation >= rFriend then
			' if not a friend and there was no more than a fixed number of rounds, display ships by category and not their name
			if not hasWon and rounds <= 1 and lastPlayerRelation < rFriend then

				if lastCategory = -1 then
					' entering in a new category
					lastCategory = category

					content.Parse "opponent.fleet.ship.category" & lastCategory

					cat_ships = 0
					cat_lost = 0
					cat_killed = 0
				end if

				cat_ships = cat_ships + oRs(5)
				cat_lost = cat_lost + oRs(6)
				cat_killed = cat_killed + oRs(7)
			else
				content.AssignValue "label", oRs(4)
				content.AssignValue "ships", oRs(5)
				content.AssignValue "lost", oRs(6)
				content.AssignValue "killed", oRs(7)
				content.AssignValue "after", oRs(5)-oRs(6)

				killed = 0

				for i = 0 to killsCount
					if oRs(12) = killsArray(0, i) and oRs(2) = killsArray(1, i) then
						content.AssignValue "killed_name", getShipLabel(killsArray(2, i))
						content.AssignValue "killed_count", killsArray(3, i)
						content.Parse "opponent.fleet.ship.killed"
						killed = killed + 1 ' count how many different ships were destroyed
					end if
				next

				if killed = 0 then content.Parse "opponent.fleet.ship.killed_zero"
				if killed > 1 then content.Parse "opponent.fleet.ship.killed_total"

				content.Parse "opponent.fleet.ship.name"
				content.Parse "opponent.fleet.ship"

				lastCategory = -1
			end if

			player_ships = player_ships + oRs(5)
			player_lost = player_lost + oRs(6)
			player_killed = player_killed + oRs(7)

			fleet_ships = fleet_ships + oRs(5)
			fleet_lost = fleet_lost + oRs(6)
			fleet_killed = fleet_killed + oRs(7)
		end if

		oRs.MoveNext
	wend

	if lastCategory > -1 then
		content.AssignValue "ships", cat_ships
		content.AssignValue "lost", cat_lost
		content.AssignValue "killed", cat_killed
		content.AssignValue "after", cat_ships - cat_lost

'		killed = 0

'		for i = 0 to killsCount
'			if oRs(2) = killsArray(1, i) then
'				content.AssignValue "killed_name", getShipLabel(killsArray(2, i))
'				content.AssignValue "killed_count", killsArray(3, i)
'				content.Parse "opponent.fleet.ship.killed"
'				killed = killed + 1 ' count how many different ships were destroyed
'			end if
'		next

'		if killed > 1 then content.Parse "opponent.fleet.ship.total"

		content.Parse "opponent.fleet.ship"
	end if


	content.AssignValue "fleet", lastFleetName
	content.AssignValue "ships", fleet_ships
	content.AssignValue "lost", fleet_lost
	content.AssignValue "killed", fleet_killed
	content.AssignValue "after", fleet_ships - fleet_lost

	select case lastPlayerColorRelation
		case rSelf
			Content.Parse "opponent.self"
			Content.Parse "opponent.fleet.self"
		case rAlliance
			Content.Parse "opponent.ally"
			Content.Parse "opponent.fleet.ally"
		case rFriend
			Content.Parse "opponent.friend"
			Content.Parse "opponent.fleet.friend"
		case else
			Content.Parse "opponent.enemy"
			Content.Parse "opponent.fleet.enemy"
	end select

	content.Parse "opponent.fleet"


	if not isnull(lastTag) then
		content.AssignValue "alliancetag", lastTag
		content.Parse "opponent.alliance"
	end if

	content.AssignValue "opponent", lastPlayer
	content.AssignValue "ships", player_ships
	content.AssignValue "lost", player_lost
	content.AssignValue "killed", player_killed
	content.AssignValue "after", player_ships - player_lost

	if lastPlayerWon then content.Parse "opponent.won"

	if lastPlayerAggressive then
		content.Parse "opponent.attack"
	else
		content.Parse "opponent.defend"
	end if

	content.AssignValue "view", lastPlayerid

	if ispubliclink then content.Parse "opponent.public"

	content.Parse "opponent"
	content.Parse ""

	set FormatBattle = content
end function

%>