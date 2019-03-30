<%option explicit%>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->

<!--#include virtual="/game/cache.asp"-->

<%
if maintenance then response.end

dim UserId:UserId = ToInt(Session(sUser), "")
if UserId = "" then response.end

function getPlanetName(relation, radar_strength, ownerName, planetName)
	if relation = rSelf then
		getPlanetName = planetName
	elseif relation = rAlliance then
		getPlanetName = ownerName
	elseif relation = rFriend then
		getPlanetName = ownerName
	else
		if radar_strength > 0 then
			getPlanetName = ownerName
		else
			getPlanetName = ""
		end if
	end if
end function

' return if the given name if valid for a fleet, a planet
function isValidCategoryName(name)
	name = trim(name)

	dim regEx

	if name = "" or len(name) < 2 or len(name) > 32 then
		isValidCategoryName = false
	else
		set regEx = New RegExp 
		regEx.IgnoreCase = False
		regEx.Pattern = "^[a-zA-Z0-9\- ]+$"

		isValidCategoryName = regEx.Test(name)
	end if
end function

' List the fleets owned by the player
function GetFleetList()
	dim content
	set content = GetTemplate("fleets")

	dim oRs, query

	query = "SELECT fleetid, fleets_ships.shipid, quantity" &_
			" FROM fleets" &_
			"	INNER JOIN fleets_ships ON (fleets.id=fleets_ships.fleetid)" &_
			" WHERE ownerid=" & UserId &_
			" ORDER BY fleetid, fleets_ships.shipid"
	set oRs = oConn.Execute(query)

	dim ShipListArray, ShipListCount
	if oRs.EOF then
		ShipListCount = -1
	else
		ShipListArray = oRs.GetRows()
		ShipListCount = UBound(ShipListArray, 2)
	end if

	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
		    " destplanetid, destplanet_name, destplanet_galaxy, destplanet_sector, destplanet_planet, destplanet_ownerid, destplanet_owner_name, destplanet_owner_relation," &_
		    " cargo_capacity, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers," & _
			" recycler_output, orbit_ore > 0 OR orbit_hydrocarbon > 0, action," &_
			"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.planet_galaxy AND nav_planet.sector = f.planet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = "&UserId&")) AS from_radarstrength, " &_
			"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.destplanet_galaxy AND nav_planet.sector = f.destplanet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = "&UserId&")) AS to_radarstrength," &_
			" categoryid" &_
			" FROM vw_fleets as f WHERE ownerid=" & UserID
	set oRs = oConn.Execute(query)

	dim i

	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "category", oRs("categoryid")
		content.AssignValue "size", oRs(4)
		content.AssignValue "signature", oRs(5)
		content.AssignValue "cargo_load", oRs(27)+oRs(28)+oRs(29)+oRs(30)+oRs(31)
		content.AssignValue "cargo_capacity", oRs(26)

		content.AssignValue "cargo_ore", oRs(27)
		content.AssignValue "cargo_hydrocarbon", oRs(28)
		content.AssignValue "cargo_scientists", oRs(29)
		content.AssignValue "cargo_soldiers", oRs(30)
		content.AssignValue "cargo_workers", oRs(31)

		content.AssignValue "commandername", oRs(9)
		content.AssignValue "action", abs(oRs(34))

		if oRs(3) then content.AssignValue "action", "x"

		if oRs(2) then
			content.AssignValue "stance", 1
		else
			content.AssignValue "stance", 0
		end if

		if oRs(7) then
			content.AssignValue "time", oRs(7)
		else
			content.AssignValue "time", 0
		end if

		' Assign fleet current planet
		content.AssignValue "planetid", 0
		content.AssignValue "g", 0
		content.AssignValue "s", 0
		content.AssignValue "p", 0
		content.AssignValue "relation", 0
		content.AssignValue "planetname", ""

		if not IsNull(oRs(10)) then
			content.AssignValue "planetid", oRs(10)
			content.AssignValue "g", oRs(12)
			content.AssignValue "s", oRs(13)
			content.AssignValue "p", oRs(14)
			content.AssignValue "relation", oRs(17)
			content.AssignValue "planetname", getPlanetName(oRs(17), oRs(35), oRs(16), oRs(11))
		end if

		' Assign fleet destination planet
		content.AssignValue "t_planetid", 0
		content.AssignValue "t_g", 0
		content.AssignValue "t_s", 0
		content.AssignValue "t_p", 0
		content.AssignValue "t_relation", 0
		content.AssignValue "t_planetname", ""


		if not IsNull(oRs(18)) then
			content.AssignValue "t_planetid", oRs(18)
			content.AssignValue "t_g", oRs(20)
			content.AssignValue "t_s", oRs(21)
			content.AssignValue "t_p", oRs(22)
			content.AssignValue "t_relation", oRs(25)
			content.AssignValue "t_planetname", getPlanetName(oRs(25), oRs(36), oRs(24), oRs(19))
		end if

		for i = 0 to ShipListCount
			if ShipListArray(0, i) = oRs(0) then
				content.AssignValue "ship_label", getShipLabel(ShipListArray(1, i))
				content.AssignValue "ship_quantity", ShipListArray(2, i)
				content.Parse "list.fleet.ship"
			end if
		next

		content.AssignValue "res_id", 1
		content.AssignValue "res_quantity", oRs("cargo_ore")
		content.Parse "list.fleet.resource"

		content.AssignValue "res_id", 2
		content.AssignValue "res_quantity", oRs("cargo_hydrocarbon")
		content.Parse "list.fleet.resource"

		content.AssignValue "res_id", 3
		content.AssignValue "res_quantity", oRs("cargo_workers")
		content.Parse "list.fleet.resource"

		content.AssignValue "res_id", 4
		content.AssignValue "res_quantity", oRs("cargo_scientists")
		content.Parse "list.fleet.resource"

		content.AssignValue "res_id", 5
		content.AssignValue "res_quantity", oRs("cargo_soldiers")
		content.Parse "list.fleet.resource"


		content.Parse "list.fleet"

		oRs.MoveNext
	wend

	content.Parse "list"
	content.Parse ""

	GetFleetList = content.Output
end function

dim action, name, catid
action = Request.QueryString("a")

dim content, oRs

' change category of a fleet
if action = "setcat" then
	dim fleetid, oldCat, newCat
	fleetid = ToInt(Request.QueryString("id"), 0)
	oldCat = ToInt(Request.QueryString("old"), 0)
	newCat = ToInt(Request.QueryString("new"), 0)

	set oRs = oConn.Execute("SELECT sp_fleets_set_category(" & UserId & "," & fleetid & "," & oldCat & "," & newCat & ")")
	if not oRs.EOF and oRs(0) then
		set content = GetTemplate("fleets")

		content.AssignValue "id", fleetid
		content.AssignValue "old", oldCat
		content.AssignValue "new", newCat
		content.Parse "fleet_category_changed"
		content.Parse ""

		response.write content.output
	end if

	response.end
end if

' create a new category
if action = "newcat" then
	name = Request.QueryString("name")

	set content = GetTemplate("fleets")

	if isValidCategoryName(name) then
		set oRs = oConn.Execute("SELECT sp_fleets_categories_add(" & UserId & "," & dosql(name) & ")")

		if not oRs.EOF then
			content.AssignValue "id", oRs(0)
			content.AssignValue "label", name
			content.Parse "category"
			content.Parse ""

			response.write content.output
		end if
	else
		content.Parse "category_name_invalid"
		content.Parse ""

		response.write content.output
	end if

	response.end
end if

' rename a category
if action = "rencat" then
	name = Request.QueryString("name")
	catid = ToInt(Request.QueryString("id"), 0)

	set content = GetTemplate("fleets")

	if name = "" then
		set oRs = oConn.Execute("SELECT sp_fleets_categories_delete(" & UserId & "," & catid & ")")
		if not oRs.EOF then
			content.AssignValue "id", catid
			content.AssignValue "label", name
			content.Parse "category"
			content.Parse ""

			response.write content.output
		end if
	elseif isValidCategoryName(name) then
		set oRs = oConn.Execute("SELECT sp_fleets_categories_rename(" & UserId & "," & catid & "," & dosql(name) & ")")

		if not oRs.EOF then
			content.AssignValue "id", catid
			content.AssignValue "label", name
			content.Parse "category"
			content.Parse ""

			response.write content.output
		end if
	else
		content.Parse "category_name_invalid"
		content.Parse ""

		response.write content.output
	end if

	response.end
end if

' retrieve list of fleets
if action = "list" then
	response.Write GetFleetList()
	response.end
end if

%>