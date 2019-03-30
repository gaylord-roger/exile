<%option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "fleets.fleets"

dim action_result : action_result = ""
dim move_fleet_result : move_fleet_result = ""
dim can_command_alliance_fleets : can_command_alliance_fleets = -1

if not IsNull(AllianceId) and hasRight("can_order_other_fleets") then
	can_command_alliance_fleets = AllianceId
end if

dim fleet_owner_id : fleet_owner_id = UserID

sub RetrieveFleetOwnerId(fleetid)
	dim oRs, buildingsRs, query

	' retrieve fleet owner
	query = "SELECT ownerid" &_
			" FROM vw_fleets as f" &_
			" WHERE (ownerid=" & UserID & " OR (shared AND owner_alliance_id=" & can_command_alliance_fleets & ")) AND id=" & fleetid & " AND (SELECT privilege FROM users WHERE users.id = f.ownerid) = 0"
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		fleet_owner_id = oRs(0)
	end if
end sub

' display fleet info
sub DisplayFleet(fleetid)
	dim content

	set content = GetTemplate("fleet")

	dim oRs, buildingsRs, query

	' retrieve fleet name, size, position, destination
	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
		    " destplanetid, destplanet_name, destplanet_galaxy, destplanet_sector, destplanet_planet, destplanet_ownerid, destplanet_owner_name, destplanet_owner_relation," &_
		    " cargo_capacity, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers," &_
			" recycler_output, orbit_ore > 0 OR orbit_hydrocarbon > 0, action, total_time, idle_time, date_part('epoch', const_interval_before_invasion())," &_
			" long_distance_capacity, droppods, warp_to,"&_
			"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.planet_galaxy AND nav_planet.sector = f.planet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = "&UserId&")) AS from_radarstrength, " &_
			"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.destplanet_galaxy AND nav_planet.sector = f.destplanet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = "&UserId&")) AS to_radarstrength," &_
			"firepower > 0, next_waypointid, (SELECT routeid FROM routes_waypoints WHERE id=f.next_waypointid), now(), spawn_ore + spawn_hydrocarbon," &_
			"radar_jamming, planet_floor, real_signature, required_vortex_strength, upkeep, CASE WHEN planet_owner_relation IN (-1,-2) THEN const_upkeep_ships_in_position() ELSE const_upkeep_ships() END AS upkeep_multiplicator," &_
			" ((sp_commander_fleet_bonus_efficiency(size::bigint - leadership, 2.0)-1.0)*100)::integer AS commander_efficiency, leadership, ownerid, shared," &_
			" (SELECT prestige_points >= sp_get_prestige_cost_for_new_planet(planets) FROM users WHERE id=ownerid) AS can_take_planet," &_
			" (SELECT sp_get_prestige_cost_for_new_planet(planets) FROM users WHERE id=ownerid) AS prestige_cost" &_
			" FROM vw_fleets as f" &_
			" WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid
	set oRs = oConn.Execute(query)


	' if fleet doesnt exist, redirect to the last known planet orbit or display the fleets list
	if oRs.EOF then
		Response.Redirect "fleets.asp"
		Response.End
	end if

	if not IsNull(AllianceId) then
		if oRs("shared") then
			content.Parse "display.overview.shared"
		else
			content.Parse "display.overview.not_shared"
		end if

		'content.Parse "display.overview.actions.action.shareable"
	end if

	content.AssignValue "now", oRs(46).Value

	if not isnull(oRs(45)) then

		dim RouteRs, waypointscount

		query = "SELECT routes_waypoints.id, ""action"", p.id, p.galaxy, p.sector, p.planet, p.name, sp_get_user(p.ownerid), sp_relation(p.ownerid,"&UserId&")," &_
				" routes_waypoints.ore, routes_waypoints.hydrocarbon" &_
				" FROM routes_waypoints" &_
				"	LEFT JOIN nav_planet AS p ON (routes_waypoints.planetid=p.id)" &_
				" WHERE routeid=" & oRs(45) & " AND routes_waypoints.id >= " & oRs(44) &_
				" ORDER BY routes_waypoints.id"
		set RouteRs = oConn.Execute(query)

		waypointscount = 0
		while not RouteRs.EOF
			if not IsNull(RouteRs(2)) then
				content.AssignValue "planetid", RouteRs(2)
				content.AssignValue "g", RouteRs(3)
				content.AssignValue "s", RouteRs(4)
				content.AssignValue "p", RouteRs(5)
				content.AssignValue "relation", RouteRs(8)

				if RouteRs(6) >= rAlliance then
					content.AssignValue "planetname", RouteRs(6)
				elseif RouteRs(6) >= rUninhabited then
					content.AssignValue "planetname", RouteRs(7)
				else
					content.AssignValue "planetname", ""
				end if
			end if

			select case RouteRs(1)
				case 0
					if RouteRs(9) > 0 then
						content.Parse "display.overview.actions.action.loadall"
					else
						content.Parse "display.overview.actions.action.unloadall"
					end if
				case 1
					content.Parse "display.overview.actions.action.move"
				case 2
					content.Parse "display.overview.actions.action.recycle"
				case 4
					content.Parse "display.overview.actions.action.wait"
				case 5
					content.Parse "display.overview.actions.action.invade"
			end select

			content.Parse "display.overview.actions.action"

			RouteRs.MoveNext
			waypointscount = waypointscount + 1
		wend

		if waypointscount > 0 then content.Parse "display.overview.actions"
	end if

	'
	' list commmanders
	'
	dim oCmdListRs
	query = " SELECT c.id, c.name, c.fleetname, c.planetname, fleets.id AS available" &_
			" FROM vw_commanders AS c" &_
			"	LEFT JOIN fleets ON (c.fleetid=fleets.id AND c.ownerid=fleets.ownerid AND NOT engaged AND action=0)" &_
			" WHERE c.ownerid=" & fleet_owner_id & _
			" ORDER BY c.fleetid IS NOT NULL, c.planetid IS NOT NULL, c.fleetid, c.planetid "
	set oCmdListRs = oConn.Execute(query)

	dim lastItem, item, ShowGroup, activityRs
	lastItem = ""
	item = ""
	ShowGroup = false

	while not oCmdListRs.EOF
		if isNull(oCmdListRs(2)) then
			if isNull(oCmdListRs(3)) then
				item = "none"
			else
				item = "planet"
			end if
		else
			item = "fleet"
		end if

		if item <> lastItem then
			if ShowGroup then content.Parse "display.overview.optgroup"
			content.Parse "display.overview.optgroup."&item
		end if
		
		' check if the commander is the commander of the fleet we display
		if oRs(8) = oCmdListRs(0) then content.Parse "display.overview.optgroup.cmd_option.selected"

		content.AssignValue "cmd_id", oCmdListRs(0)
		content.AssignValue "cmd_name", oCmdListRs(1)

		if item = "planet" then 
			content.AssignValue "name", oCmdListRs(3)
			content.Parse "display.overview.optgroup.cmd_option.assigned"
		elseif item = "fleet" then
			content.AssignValue "name", oCmdListRs(2)

			if oCmdListRs(4) then
				content.Parse "display.overview.optgroup.cmd_option.assigned"
			else
				content.Parse "display.overview.optgroup.cmd_option.unavailable"
			end if
		end if

		content.Parse "display.overview.optgroup.cmd_option"
		oCmdListRs.MoveNext
		ShowGroup = true
		lastItem = item
	wend
	if ShowGroup then content.Parse "display.overview.optgroup"

	if IsNull(oRs(8)) then ' display "no commander" or "fire commander" in the combobox of commanders
		content.Parse "display.overview.none"
		content.Parse "display.overview.nocommander"
	else
		content.Parse "display.overview.unassign"

		content.AssignValue "commander", oRs(9)
		content.Parse "display.overview.commander"
	end if


	content.AssignValue "fleet_leadership", oRs("leadership")
	content.AssignValue "fleet_commander_efficiency", oRs("commander_efficiency")
	content.AssignValue "fleet_signature", oRs(5)
	content.AssignValue "fleet_real_signature", oRs("real_signature")
	content.AssignValue "fleet_upkeep", oRs("upkeep")
	content.AssignValue "fleet_upkeep_multiplicator", oRs("upkeep_multiplicator")
	content.AssignValue "fleet_long_distance_capacity", oRs(38)
	content.AssignValue "fleet_required_vortex_strength", oRs("required_vortex_strength")
	content.AssignValue "fleet_droppods", oRs(39)

	if oRs(39) <= 0 then content.Parse "display.overview.hide_droppods"

	if oRs(38) < oRs("real_signature") then content.Parse "display.overview.insufficient_long_distance_capacity"

	' display resources in cargo and its capacity
	content.AssignValue "fleet_ore", oRs(27)
	content.AssignValue "fleet_hydrocarbon", oRs(28)
	content.AssignValue "fleet_scientists", oRs(29)
	content.AssignValue "fleet_soldiers", oRs(30)
	content.AssignValue "fleet_workers", oRs(31)

	content.AssignValue "fleet_load", oRs(27) + oRs(28) + oRs(29) + oRs(30) + oRs(31)
	content.AssignValue "fleet_capacity", oRs(26)

	if oRs(26) <= 0 then
		content.Parse "display.overview.hide_cargo"
		content.Parse "display.hide_cargo"
	end if

	content.AssignValue "fleetid", fleetid
	content.AssignValue "fleetname", oRs(1)
	content.AssignValue "fleet_size", oRs(4)
	content.AssignValue "fleet_speed", oRs(6)
	content.AssignValue "recycler_output", oRs(32)

	if oRs(32) <= 0 then content.Parse "display.overview.hide_recycling"

	' Assign remaining time
	if not isnull(oRs(7)) then
		content.AssignValue "time", oRs(7)
	else
		content.AssignValue "time", 0
	end if


	'
	' display the fleet stance
	'
	if oRs(2) then
		content.Parse "display.overview.attack"
	else
		content.Parse "display.overview.defend"
	end if

	' if the fleet can be set to attack (firepower > 0)
	if oRs(43) then
		if oRs(2) then
			content.Parse "display.overview.setstance.defend"
		else
			content.Parse "display.overview.setstance.attack"
		end if

		content.Parse "display.overview.setstance"
	else
		content.Parse "display.overview.cant_setstance"
	end if


	'
	' display fleets that are near the same planet as this fleet
	' it allows to switch between the fleets and merge them quickly
	'
	dim oFleetsRs, fleetCount, displayFleet

	fleetCount = 0
	if oRs(34) <> -1 then
		query = "SELECT vw_fleets.id, vw_fleets.name, size, signature, speed, cargo_capacity-cargo_free, cargo_capacity, action, ownerid, owner_name, alliances.tag, sp_relation("&UserId&",ownerid)" &_
				" FROM vw_fleets" &_
				"	LEFT JOIN alliances ON alliances.id=owner_alliance_id" &_
				" WHERE planetid="&sqlvalue(oRs(10))&" AND vw_fleets.id <> "&oRs(0)&" AND NOT engaged AND action <> 1 AND action <> -1" &_
				" ORDER BY upper(vw_fleets.name)"
		set oFleetsRs = oConn.Execute(query)

		while not oFleetsRs.EOF
			content.AssignValue "id", oFleetsRs(0)
			content.AssignValue "name", oFleetsRs(1)
			content.AssignValue "size", oFleetsRs(2)

			' oRs(48) radar_jamming of planet
			if oRs(17) > rFriend or oFleetsRs(11) > rFriend or oRs(48) = 0 or oRs(41) > oRs(48) then
				content.AssignValue "signature", oFleetsRs(3)
			else
				content.AssignValue "signature", 0
			end if

			content.AssignValue "speed", oFleetsRs(4)
			content.AssignValue "cargo_load", oFleetsRs(5)
			content.AssignValue "cargo_capacity", oFleetsRs(6)

			if oFleetsRs(8) = UserId then
				if oRs(34) = 0 and oFleetsRs(7) = 0 then content.Parse "fleets.playerfleet.merge"

				content.Parse "fleets.playerfleet"
				fleetCount = fleetCount + 1
			else
				displayFleet = false

				content.AssignValue "owner", oFleetsRs(9)
				content.AssignValue "tag", oFleetsRs(10)

				select case oFleetsRs(11)
					case 1
						displayFleet = true
						content.Parse "fleets.fleet.ally"
					case 0
						displayFleet = true
						content.Parse "fleets.fleet.friend"
					case -1
						displayFleet = oRs(34) <> 1
						if displayFleet then content.Parse "fleets.fleet.enemy"
				end select

				' only display ally/nap fleets when leaving a planet
				if displayFleet then
					content.Parse "fleets.fleet"
					fleetCount = fleetCount + 1
				end if
			end if

			oFleetsRs.MoveNext
		wend
	end if

	if fleetCount = 0 then content.Parse "fleets.nofleets"
	content.Parse "fleets"


	'
	' assign fleet current planet
	'
	content.AssignValue "planetid", oRs(10)
	content.AssignValue "g", oRs(12)
	content.AssignValue "s", oRs(13)
	content.AssignValue "p", oRs(14)
	content.AssignValue "relation", oRs(17)
	content.AssignValue "planetname", getPlanetName(oRs(17), oRs(41), oRs(16), oRs(11))

'	if oRs(17) < rAlliance and not IsNull(oRs(16)) then
'		if oRs(41) > 0 or oRs(17) = rFriend then
'			content.AssignValue "planetname", oRs(16)
'		else
'			content.AssignValue "planetname", ""
'		end if
'	else
'		content.AssignValue "planetname", oRs(11)
'	end if



	if oRs(34) = -1 or oRs(34) = 1 then ' fleet is moving when dest_planetid is not null

		' Assign destination planet
		content.AssignValue "t_planetid", oRs(18)
		content.AssignValue "t_g", oRs(20)
		content.AssignValue "t_s", oRs(21)
		content.AssignValue "t_p", oRs(22)
		content.AssignValue "t_relation", oRs(25)
		content.AssignValue "t_planetname", getPlanetName(oRs(25), oRs(42), oRs(24), oRs(19))

'		if oRs(25) < rAlliance and not IsNull(oRs(24)) then
'			if oRs(42) > 0 or oRs(25) = rFriend then
'				content.AssignValue "t_planetname", oRs(24)
'			else
'				content.AssignValue "t_planetname", ""
'			end if
'		else
'			content.AssignValue "t_planetname", oRs(19)
'		end if
		
		' display Cancel Move orders if fleet has covered less than 100 units of distance, or during 2 minutes
		' and if from_planet is not null
		dim timelimit
		timelimit = int(100/oRs(6)*3600)
		if timelimit < 120 then	timelimit = 120

		if not oRs(3) and oRs(35)-oRs(7) < timelimit and not isnull(oRs(10)) then
			content.AssignValue "timelimit", timelimit-(oRs(35)-oRs(7))
			content.Parse "display.overview.cancel_moving"
		end if

		if not isnull(oRs(10)) then content.Parse "display.overview.moving.from"

		content.Parse "display.overview.moving"
	else
		if oRs(3) then 'if is engaged
			content.Parse "display.overview.fighting"
		elseif oRs(34) = 2 then
			content.Parse "display.overview.recycling"
		elseif oRs(34) = 4 then
			content.Parse "display.overview.waiting"
		else

			if not isnull(oRs(40)) then content.Parse "display.overview.warp"

			if oRs(32) = 0 or (not oRs(33) and oRs(47) = 0) then ' if no recycler or nothing to recycle
				content.Parse "display.overview.cant_recycle"
			else
				content.Parse "display.overview.recycle"
			end if


			dim can_install_building
			can_install_building = (isNull(oRs(15)) or (oRs(17) >= rHostile)) and isnull(oRs(40))

			' assign buildings that can be installed
			' only possible if not moving, not engaged, planet is owned by self or by nobody and is not a vortex

			if oRs(17) >= rFriend then
				content.Parse "unloadcargo"
			end if

			if oRs(17) = rSelf and oRs("planet_floor") > 0 then
				content.Parse "loadcargo"
				content.Parse "shiplist.manage"
			end if

'			if UserId = 1009 then
'				if oRs(17) = rSelf and false then
					' retrieve planet ore, hydrocarbon, workers, relation
'					dim oPlanetRs
'					query = "SELECT ore, hydrocarbon, scientists, soldiers," &_
'							" GREATEST(0, workers-GREATEST(workers_busy,workers_for_maintenance-workers_for_maintenance/2+1,500))," &_
'							" workers > workers_for_maintenance/2" &_
'							" FROM vw_planets WHERE id="&oRs(10)
'					set oPlanetRs = oConn.Execute(query)

'					content.AssignValue "planet_ore", oRs(0)
'					content.AssignValue "planet_hydrocarbon", oRs(1)
'					content.AssignValue "planet_scientists", oRs(2)
'					content.AssignValue "planet_soldiers", oRs(3)
'					content.AssignValue "planet_workers", oRs(4)
'				end if
'			end if

			if oRs(34) = 0 and oRs(4) > 1 and fleet_owner_id = UserID then
				content.Parse "display.overview.split"
				content.Parse "shiplist.split"
			end if


			if not isNull(oRs(15)) and oRs(17) < rFriend And oRs(30) > 0 then
				' fleet has to wait some time (defined in DB) before being able to invade
				' oRs(37) is the value returned by const_seconds_before_invasion() from DB
				dim t
				if oRs(36) < oRs(37) then t = oRs(37) - oRs(36) else t = 0 end if
				content.AssignValue "invade_time", t

				if oRs(39) = 0 then
					content.Parse "display.overview.cant_invade"
				else
					if oRs("can_take_planet") then
						content.AssignValue "prestige", oRs("prestige_cost")
						content.Parse "display.overview.invade.can_take"
					end if

					content.Parse "display.overview.invade"
				end if
			else
				content.Parse "display.overview.cant_invade"
			end if

			if oRs(34) = 0 then
				content.Parse "display.overview.patrolling" ' standing by/patrolling
				content.Parse "display.overview.idle"
			end if

		end if

		'
		' Fleet idling
		'
		if oRs(34) = 0 then
			if move_fleet_result <> "" then
				content.Parse "display.move_fleet.result." & move_fleet_result
				content.Parse "display.move_fleet.result"
			end if
			
			'
			' populate destination list, there are 2 groups : planets and fleets
			'

			' retrieve planet list

			dim list_oRs, i, hasAPlanetSelected
			hasAPlanetSelected = false

			if IsArray(planetListArray) then
				for i = 0 to planetListCount
					content.AssignValue "index", i
					content.AssignValue "name", planetListArray(1,i)
					content.AssignValue "to_g", planetListArray(2,i)
					content.AssignValue "to_s", planetListArray(3,i)
					content.AssignValue "to_p", planetListArray(4,i)

					if planetListArray(0,i) = oRs(10) then
						content.Parse "display.move_fleet.planetgroup.location.selected"
						hasAPlanetSelected = true
					end if

					content.Parse "display.move_fleet.planetgroup.location"
				next
				content.Parse "display.move_fleet.planetgroup"
			end if


			'
			' list planets where we have fleets not on our planets
			'
			query = " SELECT DISTINCT ON (f.planetid) f.name, f.planetid, f.planet_galaxy, f.planet_sector, f.planet_planet" &_
					" FROM vw_fleets AS f" &_
					"	 LEFT JOIN nav_planet AS p ON (f.planetid=p.id)" &_
					" WHERE f.ownerid="& UserID&" AND p.ownerid IS DISTINCT FROM "& UserID &_
					" ORDER BY f.planetid" &_
					" LIMIT 200"
			set list_oRs = oConn.Execute(query)

			showGroup = false
			while not list_oRs.EOF
				content.AssignValue "index", i
				content.AssignValue "fleet_name", list_oRs(0)
				content.AssignValue "to_g", list_oRs(2)
				content.AssignValue "to_s", list_oRs(3)
				content.AssignValue "to_p", list_oRs(4)

				if list_oRs(1) = oRs(10) and not hasAPlanetSelected then content.Parse "display.move_fleet.fleetgroup.location.selected"

				content.Parse "display.move_fleet.fleetgroup.location"
				showGroup = true

				i = i + 1
				list_oRs.MoveNext
			wend
			if showGroup then content.Parse "display.move_fleet.fleetgroup"


			'
			' list merchant planets in the galaxy of the fleet
			'
			query = " SELECT id, galaxy, sector, planet" &_
					" FROM nav_planet" &_
					" WHERE ownerid=3"

			if not IsNull(oRs(12)) then
				query = query + " AND galaxy=" & oRs(12)
			end if

			query = query + " ORDER BY id"

			set list_oRs = oConn.Execute(query)

			showGroup = false
			while not list_oRs.EOF
				content.AssignValue "index", i
				content.AssignValue "to_g", list_oRs(1)
				content.AssignValue "to_s", list_oRs(2)
				content.AssignValue "to_p", list_oRs(3)

				if list_oRs(0) = oRs(10) and not hasAPlanetSelected then content.Parse "display.move_fleet.merchantplanetsgroup.location.selected"

				content.Parse "display.move_fleet.merchantplanetsgroup.location"
				showGroup = true

				i = i + 1
				list_oRs.MoveNext
			wend
			if showGroup then content.Parse "display.move_fleet.merchantplanetsgroup"


			content.Parse "display.move_fleet"


			if session(sprivilege) > 100 then

				'
				' list routes
				'
				query = " SELECT id, name, repeat" &_
						" FROM routes" &_
						" WHERE ownerid="& UserID
				set list_oRs = oConn.Execute(query)

				if list_oRs.EOF then content.Parse "display.overview.route.none"

				while not list_oRs.EOF
					content.AssignValue "route_id", list_oRs(0)
					content.AssignValue "route_name", list_oRs(1)

					if list_oRs(0) = oRs(45) then content.Parse "display.overview.route.item.selected"

					content.Parse "display.overview.route.item"

					list_oRs.MoveNext
				wend

				content.Parse "display.overview.route.idle"
			end if
		end if
	end if

	if session(sprivilege) > 100 then
		content.Parse "display.overview.route"
	end if

	' display action error
	if action_result <> "" then content.Parse "display.overview." & action_result

	content.Parse "display.overview"


	dim planet_ownerid
	if not isnull(oRs(15)) then
		planet_ownerid = oRs(15)
	else
		planet_ownerid = UserId
	end if

	' display header
	if oRs(34) = 0 and oRs(17) = rSelf then
		SetCurrentPlanet oRs(10)
		FillHeader
	else
		FillHeaderCredits
	end if

	'
	' display the list of ships in the fleet
	'
	query = "SELECT db_ships.id, fleets_ships.quantity," &_
			" signature, capacity, handling, speed, weapon_turrets, weapon_dmg_em+weapon_dmg_explosive+weapon_dmg_kinetic+weapon_dmg_thermal AS weapon_power, weapon_tracking_speed, hull, shield, recycler_output, long_distance_capacity, droppods," & _
			" buildingid, sp_can_build_on(" & sqlValue(oRs(10)) & ", db_ships.buildingid," & planet_ownerid & ")=0 AS can_build" &_
			" FROM fleets_ships" &_
			"	LEFT JOIN db_ships ON (fleets_ships.shipid = db_ships.id)" &_
			" WHERE fleetid=" & fleetid & _
			" ORDER BY db_ships.category, db_ships.label"
	set oRs = oConn.Execute(query)

	dim shipCount
	shipCount = 0

	while not oRs.EOF
		shipCount = shipCount + 1

		content.AssignValue "id", oRs(0)
		content.AssignValue "quantity", oRs(1)

		' assign ship label, description & characteristics
		content.AssignValue "name", getShipLabel(oRs(0))
		content.AssignValue "description", getShipDescription(oRs(0))

		content.AssignValue "ship_signature", oRs("signature")
		content.AssignValue "ship_cargo", oRs("capacity")
		content.AssignValue "ship_handling", oRs("handling")
		content.AssignValue "ship_speed", oRs("speed")

		content.AssignValue "ship_turrets", oRs("weapon_turrets")
		content.AssignValue "ship_power", oRs("weapon_power")
		content.AssignValue "ship_tracking_speed", oRs("weapon_tracking_speed")

		content.AssignValue "ship_hull", oRs("hull")
		content.AssignValue "ship_shield", oRs("shield")

		content.AssignValue "ship_recycler_output", oRs("recycler_output")
		content.AssignValue "ship_long_distance_capacity", oRs("long_distance_capacity")
		content.AssignValue "ship_droppods", oRs("droppods")

		if not isnull(oRs("buildingid")) then
			if can_install_building and oRs("can_build") then
				content.Parse "shiplist.ship.install"
			else
				content.Parse "shiplist.ship.cant_install"
			end if
		end if

		content.Parse "shiplist.ship"

		oRs.MoveNext
	wend
	content.Parse "shiplist"


	content.Parse "display"

	if userid=1009 then content.Parse "dev"

	content.Parse ""

	Display(content)
end sub


sub InstallBuilding(fleetid, shipid)
	dim planetid

	dim oRs
	set oRs = oConn.Execute("SELECT sp_start_ship_building_installation(" & fleet_owner_id & "," & fleetid & "," & shipid & ")")

	if oRs.EOF then exit sub

	if oRs(0) >= 0 then
		' set as the new planet in case it has been colonized, the player expects to see its new planet after colonization
		SetCurrentPlanet oRs(0)

		' invalidate planet list to reload it in case a planet has been colonized
		InvalidatePlanetList()
	elseif oRs(0) = -7 then
		action_result = "error_max_planets_reached"
	elseif oRs(0) = -8 then
		action_result = "error_deploy_enemy_ships"
	elseif oRs(0) = -11 then
		action_result = "error_deploy_too_many_safe_planets"
	end if
end sub


sub MoveFleet(fleetid)
	dim g, s, p

	g = ToInt(Request.Form("g"),-1)
	s = ToInt(Request.Form("s"),-1)
	p = ToInt(Request.Form("p"),-1)

	if g=-1 or s=-1 or p=-1 then
		move_fleet_result = "bad_destination"
		exit sub
	end if

	dim oRs, res
	set oRs = oConn.Execute("SELECT sp_move_fleet(" & fleet_owner_id & "," & fleetid & "," & g & "," & s & "," & p & ")")
	if not oRs.EOF then
		res = oRs(0)

		if res = 0 then
			select case Request.Form("movetype")
				case "1"
					oConn.Execute "UPDATE fleets SET next_waypointid = sp_create_route_unload_move(planetid) WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid
				case "2"
					oConn.Execute "UPDATE fleets SET next_waypointid = sp_create_route_recycle_move(planetid) WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid
			end select
		end if

	else
		res = 0
	end if

	select case res
		case 0
			move_fleet_result = "ok"
		case -1 ' fleet not found or busy
			log_notice "fleet.asp", "Move: cant move fleet", 0
		case -4 ' new player or holidays protection
			move_fleet_result = "new_player_protection"
		case -5 ' long travel not possible
			move_fleet_result = "long_travel_impossible"
		case -6 ' not enough money
			move_fleet_result = "not_enough_credits"
		case -7
			move_fleet_result = "error_jump_from_require_empty_location"
		case -8
			move_fleet_result = "error_jump_protected_galaxy"
		case -9
			move_fleet_result = "error_jump_to_require_empty_location"
		case -10
			move_fleet_result = "error_jump_to_same_point_limit_reached"
	end select
end sub


sub Invade(fleetid, droppods, take)
	dim oRs, res
	oRs = oConn.Execute("SELECT sp_invade_planet(" & fleet_owner_id & "," & fleetid & ","& droppods &")")

	res = oRs(0)
	
	select case res
		case -1
			action_result = "error_soldiers"
		case -2
			action_result = "error_fleet"
		case -3
			action_result = "error_planet"
		case -5
			action_result = "error_invade_enemy_ships"
	end select

	if res > 0 then
		InvalidatePlanetList()
		Response.Redirect "invasion.asp?id=" & res & "&fleetid=" & fleetid
		Response.End
	end if
end sub



sub ExecuteOrder(fleetid)
	dim destfleetid, shipid, droppods, fleetname, commanderid, oRs

	select case Request.Form("action")
		case "invade"
			droppods = ToInt(Request.Form("droppods"), 0)
			Invade fleetid, droppods, Request.Form("take") <> ""
		case "rename"
			fleetname = Trim(Request.Form("newname"))
			if isValidObjectName(fleetname) then
				on error resume next
				oConn.Execute "UPDATE fleets SET name="&dosql(fleetname)&" WHERE action=0 AND not engaged AND ownerid=" & UserID & " AND id=" & fleetid, , adExecuteNoRecords
				on error goto 0
			end if
		case "assigncommander"
			' assign new commander
			if Request.Form("commander") <> 0 then
				commanderid = dosql(Request.Form("commander"))
				oConn.Execute "SELECT sp_commanders_assign(" & fleet_owner_id & "," & commanderid & ",null," & fleetid & ")", , adExecuteNoRecords
			else
				' unassign current fleet commander
				oConn.Execute "UPDATE fleets SET commanderid=NULL WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid, , adExecuteNoRecords
			end if

			oConn.Execute "SELECT sp_update_fleet_bonus(" & fleetid & ")", , adExecuteNoRecords
		case "move"
			if Request.Form("loop") <> "0" then
				log_notice "fleet.asp", "Move: parameter missing", 1
				connectNexusDB
				oNexusConn.Execute("UPDATE users SET cheat_detected=now() WHERE id=" & UserId)
			end if

			MoveFleet(fleetid)
	end select


	select case Request.QueryString("action")
		case "share"
			oConn.Execute "UPDATE fleets SET shared=not shared WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid, , adExecuteNoRecords
		case "abandon"
			'response.write "SELECT sp_abandon_fleet(" & UserId & "," & fleetid & ")"
			oConn.Execute "SELECT sp_abandon_fleet(" & UserId & "," & fleetid & ")", , adExecuteNoRecords
		case "attack"
			oConn.Execute "UPDATE fleets SET attackonsight=firepower > 0 WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid, , adExecuteNoRecords
		case "defend"
			oConn.Execute "UPDATE fleets SET attackonsight=false WHERE ownerid=" & fleet_owner_id & " AND id=" & fleetid, , adExecuteNoRecords
		case "recycle"
			set oRs = oConn.Execute("SELECT sp_start_recycling(" & fleet_owner_id & "," & fleetid & ")")
			if oRs(0) = -2 then
				action_result = "error_recycling"
			end if
		case "stoprecycling"
			oConn.Execute "SELECT sp_cancel_recycling(" & fleet_owner_id & "," & fleetid & ")"
		case "stopwaiting"
			oConn.Execute "SELECT sp_cancel_waiting(" & fleet_owner_id & "," & fleetid & ")"
		case "merge"
			destfleetid = ToInt(Request.QueryString("with"), 0)
			oConn.Execute "SELECT sp_merge_fleets(" & UserID & "," & fleetid & ","& destfleetid &")", , adExecuteNoRecords
		case "return"
			oConn.Execute "SELECT sp_cancel_move(" & fleet_owner_id & "," & fleetid & ")"
		case "install"
			shipid = ToInt(Request.QueryString("s"), 0)
			InstallBuilding fleetid, shipid
		case "warp"
			oConn.Execute "SELECT sp_warp_fleet(" & fleet_owner_id & "," & fleetid & ")"
	end select
end sub

dim fleetid
fleetid = ToInt(Request.QueryString("id"), 0)

if ToInt(Request.QueryString("trade"), 0) = 9 then
	action_result = "error_trade"
end if

if fleetid = 0 then
	Response.Redirect "orbit.asp"
	Response.End
end if

RetrieveFleetOwnerId(fleetid)

ExecuteOrder(fleetid)

DisplayFleet(fleetid)

%>