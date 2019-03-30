Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

setDSN WScript.Arguments(0)

sub ResolveBattles(oConn)
	dim Rounds, queryFriends, i, j, query, data
	dim battle
	Rounds = 25

	log_debug false, "Check for battles"

	' list planets where there are battles
	query = "SELECT id, COALESCE(sp_get_user(ownerid), ''), galaxy, sector, planet FROM nav_planet WHERE next_battle <= now() LIMIT 1;"
	set oRs = createobject("ADODB.Recordset")
	oRs.open query, oconn

	if oRs.EOF then log_debug false, "No battles found"

	if not oRs.EOF then
		planetid = oRs(0)
		data = "planet:{owner:""" & oRs(1) & """,g:" & oRs(2) & ",s:" & oRs(3) & ",p:" & oRs(4) & "}"
		oRs.Close
		set oRs = Nothing

		' retrieve opponents relationships
		queryFriends = "SELECT f1.ownerid, f2.ownerid, sp_relation(f1.ownerid, f2.ownerid)" &_
						" FROM (SELECT ownerid, bool_or(attackonsight) AS attackonsight FROM fleets WHERE planetid=" & planetid & " AND engaged GROUP BY ownerid) as f1, (SELECT ownerid, bool_or(attackonsight) AS attackonsight FROM fleets WHERE planetid=" & planetid & " AND engaged GROUP BY ownerid) as f2" &_
						" WHERE f1.ownerid > f2.ownerid AND (sp_relation(f1.ownerid, f2.ownerid) >= 0 OR (sp_relation(f1.ownerid, f2.ownerid) = -1 AND NOT f1.attackonsight AND NOT f2.attackonsight) );"
		set oFriends = createobject("ADODB.Recordset")
		oFriends.open queryFriends, oConn

		if oFriends.EOF then
			friendsCount = -1
		else
			friendsArray = oFriends.GetRows()
			friendsCount = UBound(friendsArray, 2)
		end if

		oFriends.Close
		set oFriends = Nothing


		' retrieve fleets near the planet
'		query = "SELECT fleets.ownerid, fleets.id, db_ships.id, hull, shield, handling, weapon_ammo, weapon_power, weapon_tracking_speed, weapon_turrets, quantity, dest_planetid, 100+fleets.mod_shield, 100+fleets.mod_handling, 100+fleets.mod_tracking_speed, 100+fleets.mod_damage, attackonsight," &_
'				" weapon_dmg_em, weapon_dmg_explosive, weapon_dmg_kinetic, weapon_dmg_thermal," &_
'				" resist_em, resist_explosive, resist_kinetic, resist_thermal, tech" &_
'				" FROM (fleets INNER JOIN fleets_ships ON (fleetid = id))" &_
'				"	INNER JOIN db_ships ON (fleets_ships.shipid = db_ships.id)" &_
'				" WHERE fleets.planetid=" & planetid & " AND engaged" &_
'				" ORDER BY fleets.speed DESC, random();"
'		set oFleets = createobject("ADODB.Recordset")
'		oFleets.open query, oConn
'
'		fleetsArray = oFleets.GetRows()
'		fleetsCount = UBound(fleetsArray, 2)
'
'		oFleets.Close
'		set oFleets = Nothing


		' create the battlefield object
		set battle = Wscript.CreateObject("exilev3.battlefield")

		query = "SELECT fleets.ownerid, fleets.id, db_ships.id, hull, shield, handling, weapon_ammo, weapon_power, weapon_tracking_speed, weapon_turrets, quantity, dest_planetid, fleets.mod_shield, fleets.mod_handling, fleets.mod_tracking_speed, fleets.mod_damage, attackonsight," &_
				" weapon_dmg_em, weapon_dmg_explosive, weapon_dmg_kinetic, weapon_dmg_thermal," &_
				" resist_em, resist_explosive, resist_kinetic, resist_thermal, tech" &_
				" FROM (fleets INNER JOIN fleets_ships ON (fleetid = id))" &_
				"	INNER JOIN db_ships ON (fleets_ships.shipid = db_ships.id)" &_
				" WHERE fleets.planetid=" & planetid & " AND engaged" &_
				" ORDER BY fleets.speed DESC, random();"
		set oFleets = createobject("ADODB.Recordset")
		oFleets.open query, oConn

		' fill the battlefield with the fleets
		while not oFleets.EOF
			if isnull(oFleets(11)) then
				battle.AddShip oFleets(0), oFleets(1), oFleets(2), oFleets("hull"), oFleets(4), oFleets(5), oFleets("weapon_ammo"), oFleets(7), oFleets(8), oFleets(9), oFleets(10), oFleets(12), oFleets(13), oFleets(14), oFleets(15), True Or oFleets(16), oFleets("weapon_dmg_em"), oFleets(18), oFleets(19), oFleets(20), oFleets("resist_em"), oFleets(22), oFleets(23), oFleets(24), oFleets("tech")
			else
				' if the fleet is fleeing, divide the handling of the fleet by 1, its weapon_tracking_speed by 2 and reduce number of rounds that can occur
				battle.AddShip oFleets(0), oFleets(1), oFleets(2), oFleets("hull"), oFleets(4), oFleets(5), oFleets("weapon_ammo"), oFleets(7), oFleets(8), oFleets(9), oFleets(10), oFleets(12), oFleets(13) / 1, oFleets(14) / 2, oFleets(15), True Or oFleets(16), oFleets("weapon_dmg_em"), oFleets(18), oFleets(19), oFleets(20), oFleets("resist_em"), oFleets(22), oFleets(23), oFleets(24), oFleets("tech")

				Rounds = 25
			end if

			oFleets.MoveNext
		wend

		oFleets.Close
		set oFleets = Nothing

		' set the relations between players
		for i = 0 to friendsCount
			battle.SetFriend friendsArray(0, i), friendsArray(1, i)
		next

		log_debug true, "battle near planet " & planetid

		' let's the battle begin !
		while Rounds > 1 and battle.NextRound()
			Rounds = Rounds - 1
		wend
		battle.EndFight()

		if true then

			log_debug true, "battle near planet " & planetid & " : resolved"

	oConn.BeginTrans

			' retrieve number of rounds
			Rounds = battle.Rounds

			' create a new battle in database
			query = "SELECT sp_create_battle(" & planetid & "," & Rounds & ")"
'			log_debug true, query
			set oBattleRS = createobject("ADODB.Recordset")
			oBattleRS.open query, oConn
			BattleId = oBattleRS(0)
			oBattleRs.Close
			set oBattleRs = Nothing


			dim lastOwner: lastOwner = -1
			dim shipsDestroyed: shipsDestroyed = 0


			log_debug true, "battle near planet " & planetid & " : insert battles_relations"

			' store players relationships
			dim p1, p2

			for i = 0 to friendsCount
				if friendsArray(0, i) > friendsArray(1, i) then
					p1 = friendsArray(1, i)
					p2 = friendsArray(0, i)
				else
					p1 = friendsArray(0, i)
					p2 = friendsArray(1, i)
				end if

				query = "INSERT INTO battles_relations VALUES(" & BattleId & "," & p1 & "," & p2 & "," & friendsArray(2, i) & ")"
'		log_debug true, query
				oConn.Execute query, , 128
			next

			log_debug true, "battle near planet " & planetid & " : write battle result"

			'
			' write battle result
			'
			dim lastFleetid, lastBattleFleetId
			lastFleetid = ""
			lastBattleFleetId = ""

			for I = 0 to battle.ResultCount()-1
				dim ownerid, fleetid, shipid, before, after

				set res = battle.ResultGet(I)

				' create an entry for each shipid with before/after
				query = "INSERT INTO battles_ships(battleid, owner_id, owner_name, fleet_id, fleet_name, shipid, before, after, killed, won, damages, attacked)" &_
						" VALUES(" & BattleId & "," & res.Ownerid & ", (SELECT login FROM users WHERE id=" & res.Ownerid & " LIMIT 1), " & res.fleetid & ", (SELECT name FROM fleets WHERE id=" & res.Fleetid & " LIMIT 1)," & res.Shipid & "," & res.before & "," & res.after & "," & res.killed & "," & res.won & "," & res.damages & "," & "(SELECT attackonsight FROM fleets WHERE id=" & res.Fleetid & " LIMIT 1))" '& res.AttackOnSight & ")"

'		log_debug true, query
				oConn.Execute query, , 128

				' new way of saving battle

				if res.fleetid <> lastFleetId then
					' add a fleet in the battle report
					query = "SELECT sp_add_battle_fleet(" & BattleId & "," & res.Ownerid & "," & res.fleetid & "," & res.mod_shield & "," & res.mod_handling & "," & res.mod_tracking_speed & "," & res.mod_damage & "," & "(SELECT attackonsight FROM fleets WHERE id=" & res.Fleetid & " LIMIT 1), " & res.won & ")"'& res.AttackOnSight & "," & res.won & ")"
'		log_debug true, query
					set oFleets = createobject("ADODB.Recordset")
					oFleets.open query, oconn

					lastFleetId = res.fleetid
					lastBattleFleetId = oFleets(0)

					oFleets.close
					set oFleets = Nothing
				end if

				query = "INSERT INTO battles_fleets_ships(fleetid, shipid, before, after, killed, damages)" &_
						" VALUES(" & lastBattleFleetId & "," & res.Shipid & "," & res.before & "," & res.after & "," & res.killed & "," & res.damages & ")"
'		log_debug true, query
				oConn.Execute query, , 128


				for j = 0 to res.DestroyedShipsCount-1

					set kills = res.DestroyedShips(j)

					query = "INSERT INTO battles_fleets_ships_kills(fleetid, shipid, destroyed_shipid, count)" &_
							" VALUES(" & lastBattleFleetId & "," & res.Shipid & "," & kills.DestroyedShipId & "," & kills.quantity & ")"
'		log_debug true, query
					oConn.Execute query, , 128

					' count number of ships killed
					if kills.quantity > 0 then
						query = "INSERT INTO users_ships_kills(userid, shipid, killed)" &_
								" VALUES(" & res.OwnerId & "," & kills.DestroyedShipId & "," & kills.quantity & ")"
'		log_debug true, query
						oConn.Execute query, , 128
					end if

				next


				shipsDestroyed = shipsDestroyed + res.before - res.after

				' count number of ships the owner lost
				if res.before - res.after > 0 then
					query = "SELECT sp_destroy_ships(" & res.Fleetid & "," & res.shipid & "," & res.before - res.after & ")"
'		log_debug true, query
					oConn.Execute query, , 128

					query = "INSERT INTO users_ships_kills(userid, shipid, lost)" &_
							" VALUES(" & res.OwnerId & "," & res.shipid & "," & res.before - res.after & ")"
'		log_debug true, query
					oConn.Execute query, , 128
				end if

				if lastOwner <> res.Ownerid then
					dim battlesubtype
					if res.won then
						battlesubtype = 1
'					elseif Rounds = 1 then
'						battlesubtype = 2
					else
						battlesubtype = 0
					end if

					query = "SELECT ownerid FROM reports WHERE ownerid=" & res.Ownerid & " AND type=2 AND subtype=" & battlesubtype & " AND battleid=" & BattleId
					set reportRs = createobject("ADODB.Recordset")
'					log_debug true, query
					reportRs.open query, oconn

					insertReports = reportRs.EOF
					reportRs.close
					set reportRs = Nothing

					if insertReports then
						query = "INSERT INTO reports(ownerid, type, subtype, battleid, planetid, data)" &_
								" VALUES(" & res.Ownerid & ",2," & battlesubtype & "," & BattleId & "," & planetid & ",'{" & data & ",battleid:" & BattleId & ",ownerid:" & res.Ownerid & "}'" & ")"
						oConn.Execute query, , 128
					end if

					lastOwner = res.Ownerid
				end if
			next
		else
			BattleId = "#"

			log_debug true, "battle near planet " & planetid & " : error resolving"
		end if

		log_debug true, "battle near planet " & planetid & " : " & BattleId

		query = "UPDATE nav_planet SET next_battle = null WHERE id=" & planetid
'		log_debug true, query
		oConn.Execute query, , 128

		' set fleeing ships out of battle
'		oConn.Execute "UPDATE fleets SET engaged=false WHERE engaged AND (action=-1 OR action=1) AND planetid=" & planetid, , 128
		query = "UPDATE fleets SET engaged=false WHERE engaged AND action <> 0 AND planetid=" & planetid
'		log_debug true, query
		oConn.Execute query, , 128

		if shipsDestroyed > 0 then
			oConn.Execute "SELECT sp_check_battle(" & planetid & ")", , 128
		else
			query = "UPDATE fleets SET engaged=false, action=4, action_end_time=now()"

			' reset fleet's idle time (idle_since value) if battle had more than 10 round
			if Rounds > 5 then query = query & ", idle_since=now()"

			query = query & " WHERE engaged AND action=0 AND planetid=" & planetid

'			log_debug true, query
			oConn.Execute query, , 128
		end if

	oConn.CommitTrans

'		log_debug true, "battle near planet " & planetid & " : " & BattleId & ": finished"

		set battle = Nothing
	end if

'	log_debug true, "Check for battles:done"
end sub

sub process
	dim oConnection
	set oConnection = Nothing

	on error resume next
	while true
		Err.Clear

		if oConnection is nothing then
			set oConnection = Wscript.CreateObject("ADODB.Connection")
			oConnection.Open dbconn
		end if

		if Err.Number = 0 then ResolveBattles(oConnection)


		if Err.Number <> 0 then
			log_debug true, "error: " & Err.Number & " : " & Err.Description

			WScript.Sleep 10000
		else
			WScript.Sleep 5000
		end if

		oConnection.Close
		set oConnection = Nothing
	wend
end sub

process

Wscript.Quit(0)
