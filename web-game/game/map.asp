<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "map"

showHeader = true

function GetSector(sector, shiftX, shiftY)
	dim s

	if (sector mod 10 = 0) and (shiftX > 0) then shiftX = 0
	if (sector mod 10 = 1) and (shiftX < 0) then shiftX = 0

	if (sector < 11) and (shiftY < 0) then shiftY = 0
	if (sector > 90) and (shiftY > 0) then shiftY = 0

	s = sector + shiftX + shiftY*10

	if s > 99 then s = 99

	GetSector = s
end function

sub displayRadar(content, galaxy, sector, radarstrength)
	dim oRs, query

	query = "SELECT v.id, v.name, attackonsight, engaged, size, signature, speed, remaining_time," &_
			" ownerid, owner_name, owner_relation, " &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet," &_
			" planet_ownerid, planet_owner_name, planet_owner_relation," &_
			" destplanetid, destplanet_name, destplanet_galaxy, destplanet_sector, destplanet_planet, " &_
			" destplanet_ownerid, destplanet_owner_name, destplanet_owner_relation, total_time," &_
			" from_radarstrength, to_radarstrength, alliances.tag, radar_jamming, destplanet_radar_jamming" &_
			" FROM vw_fleets_moving v" &_
			"	LEFT JOIN alliances ON alliances.id = owner_alliance_id" &_
			" WHERE userid="&UserId&" AND ("&_
			"	(planetid >= sp_first_planet("&galaxy&","&sector&") AND planetid <= sp_last_planet("&galaxy&","&sector&")) OR"&_
			"	(destplanetid >= sp_first_planet("&galaxy&","&sector&") AND destplanetid <= sp_last_planet("&galaxy&","&sector&")))" &_
			" ORDER BY remaining_time"
	set oRs = oConn.Execute(query)

	dim relation: relation = -100 ' -100 = do not display the fleet
	dim loosing_time: loosing_time = 0 ' seconds before our radar loses the fleet
	dim remaining_time: remaining_time = 0 ' seconds before the fleet ends its travel
	dim display_from, display_to
	dim movement_type: movement_type = ""
	dim movingfleetcount: movingfleetcount = 0		' fleets moving inside the sector
	dim enteringfleetcount: enteringfleetcount = 0	' fleets entering the sector
	dim leavingfleetcount: leavingfleetcount = 0	' fleets leaving the sector

	while not oRs.EOF
		relation = oRs(10)
		remaining_time = oRs(7)
		loosing_time = -1

		display_from = true
		display_to = true

		' do not display NAP/enemy fleets moving to/from unknown planet if fleet is not within radar range
		if relation <= rFriend then
			' compute how far our radar can detect fleets
			' highest radar strength * width of a sector / speed * nbr of second in one hour
			dim radarSpotting: radarSpotting = sqr(radarstrength)*6*1000/oRs(6)*3600

			if oRs(28) = 0 then
				if oRs(7) < radarSpotting then
					' incoming fleet is detected by our radar
					display_from = false
				else
					relation = -100
				end if
			elseif oRs(29) = 0 then
				if oRs(27)-oRs(7) < radarSpotting then
					'outgoing fleet is still detected by our radar
					loosing_time = Int(radarSpotting-(oRs(27)-oRs(7)))
					display_to = false
				else
					relation = -100
				end if
			else
				remaining_time = oRs(7)
			end if
		end if

		if relation > -100 then

			content.AssignValue "id", oRs(8)
			content.AssignValue "name", oRs(9)

			content.AssignValue "fleetid", oRs(0)
			content.AssignValue "fleetname", oRs(1)
			content.AssignValue "signature", oRs(5)

			'
			' determine the type of movement : intrasector, intersector (entering, leaving)
			' also don't show signature of enemy fleets if we don't know or can't spy on the source AND target coords
			'
			'oRs(18)
			if oRs(13) = galaxy and oRs(14) = sector then
				if oRs(21) = galaxy and oRs(22) = sector then
					movement_type = "radar.moving"
					movingfleetcount = movingfleetcount + 1

					if ((oRs(31) >= oRs(28) and oRs(18) < rAlliance) or not display_from) and ((oRs(32) >= oRs(29) and oRs(26) < rAlliance) or not display_to) and oRs(10) < rAlliance then content.AssignValue "signature", 0
				else
					movement_type = "radar.leaving"
					leavingfleetcount = leavingfleetcount + 1

					if ((oRs(31) >= oRs(28) and oRs(18) < rAlliance) or not display_from) and ((oRs(32) >= oRs(29) and oRs(26) < rAlliance) or not display_to) and oRs(10) < rAlliance then content.AssignValue "signature", 0
				end if
			else
				movement_type = "radar.entering"
				enteringfleetcount = enteringfleetcount + 1

				if ((oRs(31) >= oRs(28) and oRs(18) < rAlliance) or not display_from) and ((oRs(32) >= oRs(29) and oRs(26) < rAlliance) or not display_to) and oRs(10) < rAlliance then content.AssignValue "signature", 0
			end if

			'
			' Assign remaining travel time
			'
			if loosing_time > -1 then
				content.AssignValue "time", loosing_time
				content.Parse movement_type & ".fleet.losing"
			else
				content.AssignValue "time", remaining_time
				content.Parse movement_type & ".fleet.timeleft"
			end if


			'
			' Assign From and To planets info
			'

			if display_from then
				' Assign the name of the owner if is not an ally planet
'				if (oRs(18) < rAlliance) and not IsNull(oRs(17)) then
'					if oRs(28) > 0 or oRs(18) = rFriend then
'						content.AssignValue "f_planetname", oRs(17)
'					else
'						content.AssignValue "f_planetname", ""
'					end if
'				else
'					content.AssignValue "f_planetname", oRs(12)
'				end if
				content.AssignValue "f_planetname", getPlanetName(oRs(18), oRs(28), oRs(17), oRs(12))
				content.AssignValue "f_planetid", oRs(11)
				content.AssignValue "f_g", oRs(13)
				content.AssignValue "f_s", oRs(14)
				content.AssignValue "f_p", oRs(15)
				content.AssignValue "f_relation", oRs(18)
			else
				content.AssignValue "f_planetname", ""
				content.AssignValue "f_planetid", ""
				content.AssignValue "f_g", ""
				content.AssignValue "f_s", ""
				content.AssignValue "f_p", ""
				content.AssignValue "f_relation", "0"
			end if


			if display_to then
				' Assign the planet name if possible otherwise the name of the owner
'				if (oRs(26) < rAlliance) and not IsNull(oRs(25)) then
'					if oRs(29) > 0 or oRs(26) = rFriend then
'						content.AssignValue "t_planetname", oRs(25)
'					else
'						content.AssignValue "t_planetname", ""
'					end if
'				else
'					content.AssignValue "t_planetname", oRs(20)
'				end if
				content.AssignValue "t_planetname", getPlanetName(oRs(26), oRs(29), oRs(25), oRs(20))
				content.AssignValue "t_planetid", oRs(19)
				content.AssignValue "t_g", oRs(21)
				content.AssignValue "t_s", oRs(22)
				content.AssignValue "t_p", oRs(23)
				content.AssignValue "t_relation", oRs(26)
			else
				content.AssignValue "t_planetname", ""
				content.AssignValue "t_planetid", ""
				content.AssignValue "t_g", ""
				content.AssignValue "t_s", ""
				content.AssignValue "t_p", ""
				content.AssignValue "t_relation", "0"
			end if

			content.AssignValue "relation", relation
			content.AssignValue "alliancetag", oRs(30)

			content.Parse movement_type&".fleet"
		end if

		oRs.MoveNext
	wend

	if movingfleetcount = 0 then content.Parse "radar.moving.nofleets"
	if enteringfleetcount = 0 then content.Parse "radar.entering.nofleets"
	if leavingfleetcount = 0 then content.Parse "radar.leaving.nofleets"

	content.Parse "radar.moving"
	content.Parse "radar.entering"
	content.Parse "radar.leaving"

	content.Parse "radar"
end sub


'
' Display the map : Galaxies, sectors or a sector
'
sub DisplayMap(galaxy, sector)
	'
	' Load the template
	'
	dim content
	set content = GetTemplate("map")

	dim oRs, query

	' Assign the displayed galaxy/sector
	content.AssignValue "galaxy", galaxy
	content.AssignValue "sector", sector

	if galaxy <> "" then
		if sector <> "" then content.Parse "nav.galaxy.sector"
		content.Parse "nav.galaxy"
	end if

	content.Parse "nav"

	'
	' Verify which map will be displayed
	'
	if galaxy = "" then
		'
		' Display map of galaxies with 8 galaxies per row
		'
		query = "SELECT n.id, "&_
				" n.colonies > 0,"&_
				" FALSE AND EXISTS(SELECT 1 FROM nav_planet WHERE galaxy=n.id AND ownerid IN (SELECT friend FROM vw_friends WHERE vw_friends.userid="&UserID&") LIMIT 1),"&_
				" EXISTS(SELECT 1 FROM nav_planet WHERE galaxy=n.id AND ownerid IN (SELECT ally FROM vw_allies WHERE vw_allies.userid="&UserID&") LIMIT 1),"&_
				" EXISTS(SELECT 1 FROM nav_planet WHERE galaxy=n.id AND ownerid = "&UserID&" LIMIT 1) AS hasplanets"&_
				" FROM nav_galaxies AS n"&_
				" ORDER BY n.id;"
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			content.AssignValue "galaxyid", oRs(0)

			' check if enemy or friendly planets are in the galaxies
			if oRs(4) then
				content.Parse "universe.galaxy.hasplanet"
			elseif oRs(3) then
				content.Parse "universe.galaxy.hasally"
			elseif oRs(2) then
				content.Parse "universe.galaxy.hasfriend"
			elseif oRs(1) then
				content.Parse "universe.galaxy.hasnothing"
			end if

			content.Parse "universe.galaxy"

			oRs.MoveNext
		wend

		content.Parse "universe"
		content.Parse ""

		Display(content)

		exit sub
	end if

	if sector = "" then
		'
		' Display map of sectors for the given galaxy
		'
		query = "SELECT sp_get_galaxy_planets(" & galaxy & "," & UserId & ")"
		set oRs = oConn.Execute(query)

		content.AssignValue "map", oRs(0)
		content.AssignValue "mapgalaxy", oRs(0)


		query = "SELECT alliances.tag, round(100.0 * sum(n.score) / (SELECT sum(score) FROM nav_planet WHERE galaxy=n.galaxy))" &_
				" FROM nav_planet AS n" &_
				"	INNER JOIN users ON (users.id = n.ownerid)" &_
				"	INNER JOIN alliances ON (users.alliance_id = alliances.id)" &_
				" WHERE galaxy=" & galaxy &_
				" GROUP BY galaxy, alliances.tag" &_
				" ORDER BY sum(n.score) DESC"
		set oRs = oConn.Execute(query)

		dim nb
		nb = 1

		while not oRs.EOF and nb < 4
			content.AssignValue "sov_tag_" & nb, oRs(0)
			content.AssignValue "sov_perc_" & nb, replace(oRs(1), ",", ".")

			nb = nb + 1
			oRs.MoveNext
		wend

		query = "SELECT date_part('epoch', protected_until-now()) FROM nav_galaxies WHERE id=" & galaxy
		set oRs = oConn.Execute(query)
		content.AssignValue "protected_until", fix(oRs(0).value)

		query = "SELECT sell_ore, sell_hydrocarbon FROM sp_get_resource_price(" & UserId & "," & galaxy & ", false)"
		set oRs = oConn.Execute(query)

		content.AssignValue "price_ore", Replace(oRs(0), ",", ".")
		content.AssignValue "price_hydrocarbon", Replace(oRs(1), ",", ".")

		content.Parse "galaxy"
		content.Parse "galaxy_link"
		content.Parse ""

		Display(content)

		exit sub
	end if

	'
	' Display the planets in the given sector
	'

	'
	' Assign the arrows values
	'
	content.AssignValue "sector0", GetSector(sector,-1,-1)
	content.AssignValue "sector1", GetSector(sector, 0,-1)
	content.AssignValue "sector2", GetSector(sector, 1,-1)
	content.AssignValue "sector3", GetSector(sector, 1, 0)
	content.AssignValue "sector4", GetSector(sector, 1, 1)
	content.AssignValue "sector5", GetSector(sector, 0, 1)
	content.AssignValue "sector6", GetSector(sector,-1, 1)
	content.AssignValue "sector7", GetSector(sector,-1, 0)

	'
	' Retrieve/Save fleets in the sector
	'
	dim fleetsCount, fleetsArray

	query = "SELECT f.planetid, f.id, f.name, sp_relation(f.ownerid, "&UserID&"), f.signature," &_
			"	EXISTS(SELECT 1 FROM fleets AS fl WHERE fl.planetid=f.planetid and fl.action <> 1 and fl.action <> -1 and fl.ownerid IN (SELECT ally FROM vw_allies WHERE userid="&UserID&") LIMIT 1)," &_
			" action=1 OR action=-1, (SELECT tag FROM alliances WHERE id=users.alliance_id), login, shared," &_
			"	EXISTS(SELECT 1 FROM fleets AS fl WHERE fl.planetid=f.planetid and fl.action <> 1 and fl.action <> -1 and fl.ownerid ="&UserID&" LIMIT 1)" &_
			" FROM fleets as f" &_
			"	INNER JOIN users ON (f.ownerid=users.id)" &_
			" WHERE ((action <> 1 AND action <> -1) OR engaged) AND" &_
			"	planetid >= sp_first_planet("&galaxy&","&sector&") AND planetid <= sp_last_planet("&galaxy&","&sector&")" &_
			" ORDER BY f.planetid, upper(f.name)"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		fleetsCount = -1
	else
		fleetsArray = oRs.GetRows()
		fleetsCount = UBound(fleetsArray, 2)
	end if


	'
	' Retrieve/Save planet elements in the sector
	'
	dim elementsCount, elementsArray

	query = "SELECT planetid, label, description" &_
			" FROM planet_buildings" &_
			"	INNER JOIN db_buildings ON db_buildings.id=buildingid" &_
			" WHERE planetid >= sp_first_planet("&galaxy&","&sector&") AND planetid <= sp_last_planet("&galaxy&","&sector&") AND is_planet_element" &_
			" ORDER BY planetid, upper(label)"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		elementsCount = -1
	else
		elementsArray = oRs.GetRows()
		elementsCount = UBound(elementsArray, 2)
	end if


	'
	' Retrieve biggest radar strength in the sector that the player has access to
	'
	query = "SELECT * FROM sp_get_user_rs("&UserID&","&galaxy&","&sector&")"
	set oRs = oConn.Execute(query)
	dim radarstrength: radarstrength = oRs(0)


	dim aid
	if IsNull(AllianceId) then
		aid = -1
	else
		aid = AllianceId
	end if
	'
	' Main query : retrieve planets info in the sector
	'
	query = "SELECT nav_planet.id, nav_planet.planet, nav_planet.name, nav_planet.ownerid,"&_
			" users.login, sp_relation(nav_planet.ownerid," & UserID & "), floor, space, GREATEST(0, radar_strength), radar_jamming," & _
			" orbit_ore, orbit_hydrocarbon, alliances.tag," &_
			" (SELECT SUM(quantity*signature) FROM planet_ships LEFT JOIN db_ships ON (planet_ships.shipid = db_ships.id) WHERE planet_ships.planetid=nav_planet.id), " & _
			" floor_occupied, planet_floor, production_frozen, warp_to IS NOT NULL OR vortex_strength > 0," &_
			" planet_pct_ore, planet_pct_hydrocarbon, spawn_ore, spawn_hydrocarbon, vortex_strength," &_
			" COALESCE(buy_ore, 0) AS buy_ore, COALESCE(buy_hydrocarbon, 0) as buy_hydrocarbon," &_
			" sp_locs_shared(COALESCE(" & aid & ", -1), COALESCE(users.alliance_id, -1)) AS locs_shared" &_
			" FROM nav_planet"&_
			"	LEFT JOIN users ON (users.id = ownerid)"&_
			"	LEFT JOIN alliances ON (users.alliance_id=alliances.id)" & _
			" WHERE galaxy=" & galaxy & " AND sector=" & sector & _
			" ORDER BY planet"
	set oRs = oConn.Execute(query)


	dim planets, i, fleetcount, allyfleetcount, friendfleetcount, enemyfleetcount
	planets = 1

	' in case there is no planets, redirect player to the map of the galaxies
	if oRs.EOF then
		Response.Redirect "?"
		Response.End
	end if

	while not oRs.EOF
		dim planetid
		planetid = oRs(0)

		dim rel
		rel = oRs(5)

		if rel = rAlliance and not hasRight("can_use_alliance_radars") then
			rel = rWar
		end if

		if rel = rFriend and not oRs("locs_shared") then
			rel = rWar
		end if

		dim displayElements: displayElements = false ' hasElements is true if the planet has some particularities like magnetic cloud or sun radiation ..
		dim displayPlanetInfo: displayPlanetInfo = false
		dim displayResources: displayResources = false ' displayResources is true if there is some ore/hydrocarbon on planet orbit
		dim hasPlanetInfo: hasPlanetInfo = true


		'
		' list all the fleets around the current planet
		'
		allyfleetcount = 0
		friendfleetcount = 0
		enemyfleetcount = 0
		fleetcount = 0
		for i = 0 to fleetsCount
			if fleetsArray(0, i) = planetid then

				' display fleets on : 
				'    alliance and own planets 
				'    planets where we got a fleet or (a fleet of an alliance member and can_use_alliance_radars)
				'    planets that our radar can detect
				if (hasRight("can_use_alliance_radars") and ( (rel >= rAlliance) or fleetsArray(5, i) )) or radarstrength > oRs(9) or fleetsArray(10, i) then

					fleetcount = fleetcount + 1

					content.AssignValue "fleetid", 0

					content.AssignValue "fleetname", fleetsArray(2, i)
					content.AssignValue "relation", fleetsArray(3, i)
					content.AssignValue "fleetowner", fleetsArray(8, i)

					if (oRs(5) > rFriend) or (fleetsArray(3, i) > rFriend) or (radarstrength > oRs(9)) or (fleetsArray(5, i) and oRs(9) = 0) then
						content.AssignValue "signature", fleetsArray(4, i)
					else
						content.AssignValue "signature", -1
					end if

					if fleetsArray(6, i) then content.Parse "sector.planet.orbit.fleet.fleeing"

					if isnull(fleetsArray(7, i)) then
						content.AssignValue "alliancetag", ""
					else
						content.AssignValue "alliancetag", fleetsArray(7, i)
					end if

					select case fleetsArray(3, i)
						case rSelf
							content.AssignValue "fleetid", fleetsArray(1, i)

							allyfleetcount = allyfleetcount + 1
							friendfleetcount = friendfleetcount + 1
						case rAlliance
							allyfleetcount = allyfleetcount + 1
							friendfleetcount = friendfleetcount + 1

							if hasRight("can_order_other_fleets") and fleetsArray(9, i) then
								content.AssignValue "fleetid", fleetsArray(1, i)
							end if

						case rFriend
							friendfleetcount = friendfleetcount + 1
						case else
							' if planet is owned by the player then increase enemy fleet
							enemyfleetcount = enemyfleetcount + 1
					end select

					content.Parse "sector.planet.orbit.fleet"
				end if
			end if
		next


		content.AssignValue "planetid", planetid
		content.AssignValue "planet", oRs(1)
		content.AssignValue "relation", oRs(5)
		content.AssignValue "alliancetag", oRs(12)

		content.AssignValue "buy_ore", oRs("buy_ore")
		content.AssignValue "buy_hydrocarbon", oRs("buy_hydrocarbon")

		'
		' assign the planet representation
		'
		if oRs(6) = 0 and oRs(7) = 0 then
			' if floor and space are null then it is either an asteroid field, empty square or a vortex
			content.AssignValue "planet_img", ""
			if oRs(17) then 'and (radarstrength > 0 or allyfleetcount > 0) then
				content.Parse "sector.planet.vortex"
			elseif oRs(20) > 0 then
				content.Parse "sector.planet.asteroids"
			elseif oRs(21) > 0 then
				content.Parse "sector.planet.clouds"
			else
				content.Parse "sector.planet.empty"
			end if

			hasPlanetInfo = false
		else
			hasPlanetInfo = true

			dim p_img
			p_img = 1+(oRs(15) + oRs(0)) mod 21
			if p_img < 10 then p_img = "0" & p_img

			content.AssignValue "planet_img", p_img
			content.Parse "sector.planet.planet"
		end if


		'
		' retrieve planets non assigned ships and display their signature if we/an ally own the planet or we have a radar,
		' which is more powerfull than jammer, or if we/an ally have a fleet on this planet
		'
		dim ShowGround, ground
		ShowGround = false		

		content.AssignValue "parked", 0
		
		if not isNull(oRs(13)) and ( radarstrength > oRs(9) or rel >= rAlliance or allyfleetcount > 0 ) then
			ground = clng(oRs(13))
			if ground <> 0 then
				ShowGround = true

				content.AssignValue "parked", ground
			end if
		end if

		if fleetcount > 0 or ShowGround then
			content.Parse "sector.planet.orbit"
		end if



		if isNull(oRs(3)) then
			' if there is no owner

			displayPlanetInfo = radarstrength > 0 or allyfleetcount > 0
			displayElements = displayPlanetInfo
			displayResources = displayPlanetInfo

			content.AssignValue "ownerid", ""
			content.AssignValue "ownername", ""
			content.AssignValue "planetname", ""

			if hasPlanetInfo then content.Parse "sector.planet.uninhabited"
			content.Parse "sector.planet.noradar"
		else
			content.AssignValue "ownerid", oRs(3)
			content.AssignValue "ownername", oRs(4)

			' display planet info
			select case rel
				case rSelf
					content.AssignValue "planetname", oRs(2)

					displayElements = true
					displayPlanetInfo = true
					displayResources = true
				case rAlliance
					if displayAlliancePlanetName then
						content.AssignValue "planetname", oRs(2)
					else
						content.AssignValue "planetname", ""
					end if

					displayElements = true
					displayPlanetInfo = true
					displayResources = true
				case rFriend
					content.AssignValue "planetname", ""

					displayElements = radarstrength > oRs(9) or allyfleetcount > 0
					displayPlanetInfo = displayElements
					displayResources = radarstrength > 0 or allyfleetcount > 0
				case else
					if radarstrength > 0 or allyfleetcount > 0 then
						content.AssignValue "planetname", oRs(4)

						displayElements = radarstrength > oRs(9) or allyfleetcount > 0
						displayPlanetInfo = displayElements
						displayResources = radarstrength > 0 or allyfleetcount > 0
					else
						content.AssignValue "relation", -1

						content.AssignValue "alliancetag", ""
						content.AssignValue "ownerid", ""
						content.AssignValue "ownername", ""
						content.AssignValue "planetname", ""
						displayElements = false
						displayPlanetInfo = false
						displayResources = false
					end if
			end select
		end if

		if rel >= rAlliance then
			content.AssignValue "radarstrength", oRs(8)
			content.AssignValue "radarjamming", oRs(9)
		else
			if radarstrength = 0 then
				content.AssignValue "radarstrength", -1
				content.AssignValue "radarjamming", 0
			elseif oRs(9) > 0 then
				if oRs(9) >= radarstrength then	' check if radar is jammed
					content.AssignValue "radarstrength", 1
					content.AssignValue "radarjamming", -1
				elseif radarstrength > oRs(9) then
					content.AssignValue "radarstrength", oRs(8)
					content.AssignValue "radarjamming", oRs(9)
				end if
			elseif oRs(8) = 0 then
				content.AssignValue "radarstrength", 0
				content.AssignValue "radarjamming", 0
			else
				content.AssignValue "radarstrength", oRs(8)
				content.AssignValue "radarjamming", oRs(9)
			end if
		end if

		if hasPlanetInfo and displayPlanetInfo then
			content.AssignValue "floor", oRs(6)
			content.AssignValue "space", oRs(7)
			content.AssignValue "a_ore", oRs(18)
			content.AssignValue "a_hydrocarbon", oRs(19)
			content.AssignValue "vortex_strength", oRs("vortex_strength")
			content.Parse "sector.planet.info"
		else
			content.AssignValue "floor", ""
			content.AssignValue "space", ""
			content.AssignValue "vortex_strength", oRs("vortex_strength")
			content.Parse "sector.planet.noinfo"
		end if

		if displayResources and (oRs(10) > 0 or oRs(11) > 0) then
			content.AssignValue "ore", oRs(10)
			content.AssignValue "hydrocarbon", oRs(11)
			content.Parse "sector.planet.resources"
		else
			content.AssignValue "ore", 0
			content.AssignValue "hydrocarbon", 0
			content.Parse "sector.planet.noresources"
		end if

		'
		' list all the planet elements
		'
		if displayElements then

			dim count: count = 0
			for i = 0 to elementsCount
				if elementsArray(0, i) = planetid then
					count = count + 1
					content.AssignValue "element", elementsArray(1, i)

					content.Parse "sector.planet.elements.element"
				end if
			next

			displayElements = count > 0
		end if

		if displayElements then
			content.Parse "sector.planet.elements"
		else
			content.Parse "sector.planet.noelements"
		end if

		if oRs(16) then
			content.Parse "sector.planet.frozen"
		else
			content.Parse "sector.planet.active"
		end if

		'
		' display planet
		'
		content.Parse "sector.planet"

		planets = planets + 1

		oRs.MoveNext
	wend

	if not IsPlayerAccount() then
		content.Parse "sector.dev"
	end if

	content.Parse "sector"
	content.Parse "galaxy_link"


	'
	' Display fleets movements according to player radar strength
	'

	if radarstrength > 0 then displayRadar content, galaxy, sector, radarstrength

	content.Parse ""

	Display(content)
end sub

' Retrieve galaxy/sector to display
dim galaxy, sector, planet,oRs, query

galaxy = Request.QueryString("g")
sector = Request.QueryString("s")


' If the player is on the map and change the current planet, find the galaxy/sector
planet = Request.QueryString("planet")
if planet <> "" then
	galaxy = CurrentGalaxyId
	sector = CurrentSectorId
else
	if galaxy <> "" then galaxy = ToInt(galaxy,CurrentGalaxyId)
	if sector <> "" then sector = ToInt(sector,CurrentSectorId)
end if

DisplayMap galaxy, sector

%>