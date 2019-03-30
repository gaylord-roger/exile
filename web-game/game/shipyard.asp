<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "shipyard_all"

showHeader = true

retrieveShipsCache
retrieveShipsReqCache

dim oPlanet, oPlayer
dim ShipFilter

' retrieve planet and player information
sub RetrieveData()
	dim query
	' Retrieve recordset of current planet
', GREATEST(workers-GREATEST(workers_busy,500,workers_for_maintenance/2), 0)" &_
	query = "SELECT ore_capacity, hydrocarbon_capacity, energy_capacity, workers_capacity"&_ 
			" FROM vw_planets WHERE id="&CurrentPlanet
	set oPlanet = oConn.Execute(query)

'	query = "SELECT credits FROM users WHERE id=" & UserId
'	set oPlayer = oConn.Execute(query)
end sub

sub displayQueue(content, planetid)
' list queued ships and ships under construction
	dim buildingcount, queuecount, query, oRs

	query = "SELECT id, shipid, remaining_time, quantity, end_time, recycle, required_shipid, int4(cost_ore*const_recycle_ore(ownerid)), int4(cost_hydrocarbon*const_recycle_hydrocarbon(ownerid)), cost_ore, cost_hydrocarbon, cost_energy, crew" &_
			" FROM vw_ships_under_construction" &_
			" WHERE planetid=" & planetid & _
			" ORDER BY start_time, shipid"

	set oRs = oConn.Execute(query)

	buildingcount = 0
	queuecount = 0

	while not oRs.EOF
		content.AssignValue "queueid", oRs(0)
		content.AssignValue "id", oRs(1)
		content.AssignValue "name", getShipLabel(oRs(1))

		if cDbl(oRs(2)) > 0 then
			content.AssignValue "remainingtime", oRs(2)
		else
			content.AssignValue "remainingtime", 0
		end if

		content.AssignValue "quantity", oRs(3)

		if oRs(5) then
			content.AssignValue "ore", oRs(3)*oRs(7)
			content.AssignValue "hydrocarbon", oRs(3)*oRs(8)
			content.AssignValue "energy", 0
			content.AssignValue "crew", 0
		else
			content.AssignValue "ore", oRs(3)*oRs(9)
			content.AssignValue "hydrocarbon", oRs(3)*oRs(10)
			content.AssignValue "energy", oRs(3)*oRs(11)
			content.AssignValue "crew", oRs(3)*oRs(12)
		end if


		if not isNull(oRs(6)) then content.AssignValue "required_ship_name", getShipLabel(oRs(6))

		if not isnull(oRs(4)) then
			if oRs(5) then
				content.Parse "underconstruction.ship.recycle"
			else
				content.Parse "underconstruction.ship.cancel"
			end if

			if not isNull(oRs(6)) then content.Parse "underconstruction.ship.required_ship"

			content.Parse "underconstruction.ship"
			buildingcount = buildingcount + 1
		else
			if oRs(5) then content.Parse "queue.ship.recycle"
			if not isNull(oRs(6)) then content.Parse "queue.ship.required_ship"

			content.Parse "queue.ship.cancel"
			content.Parse "queue.ship"
			queuecount = queuecount + 1
		end if
		oRs.MoveNext
	wend

	if buildingcount > 0 then content.Parse "underconstruction"
	if queuecount > 0 then content.Parse "queue"
end sub

' List all the available ships for construction
sub ListShips()
	dim oRs, query
	dim underConstructionCount, notenoughresources, can_build

	' list ships that can be built on the planet
	query = "SELECT id, category, name, cost_ore, cost_hydrocarbon, cost_energy, workers, crew, capacity," &_
			" construction_time, hull, shield, weapon_power, weapon_ammo, weapon_tracking_speed, weapon_turrets, signature, speed," &_
			" handling, buildingid, recycler_output, droppods, long_distance_capacity, quantity, buildings_requirements_met, research_requirements_met," &_
			" required_shipid, required_ship_count, COALESCE(new_shipid, id) AS shipid, cost_prestige, upkeep, required_vortex_strength, mod_leadership" &_
			" FROM vw_ships WHERE planetid=" & CurrentPlanet

	if ShipFilter = 1 then
		selected_menu = "shipyard_military"
		query = query & " AND weapon_power > 0 AND required_shipid IS NULL" ' military ships only
	elseif ShipFilter = 2 then
		selected_menu = "shipyard_unarmed"
		query = query & " AND weapon_power = 0 AND required_shipid IS NULL" ' non-military ships
	elseif ShipFilter = 3 then
		selected_menu = "shipyard_upgrade"
		query = query & " AND required_shipid IS NOT NULL" ' upgrade ships only
	end if

	set oRs = oConn.Execute(query)

	dim content
	set content = GetTemplate("shipyard")

	content.AssignValue "planetid", CurrentPlanet
	content.AssignValue "filter", ShipFilter

	dim category, lastCategory, itemCount, buildable, ShipId

	' number of items in category
	itemCount = 0

	' number of ships types that can be built
	buildable = 0

	if not oRs.EOF then
		if (oRs("quantity") > 0) or oRs("research_requirements_met") then
			category = oRs("category")
			lastCategory = category 
		end if
	end if

	dim count
	count = 0
	while not oRs.EOF
		if (oRs("quantity") > 0) or oRs("research_requirements_met") then
			dim id, quantity
			category = oRs("category")

			if category <> lastCategory then
				if itemCount > 0 then
					content.Parse "category.category" & lastcategory
					content.Parse "category"
				end if

				lastCategory = category

				itemCount = 0
			end if

			itemCount = itemCount + 1

			ShipId = oRs("shipid")

			content.AssignValue "id", oRs(0)
			content.AssignValue "name", getShipLabel(ShipId)

			if not IsNull(oRs("required_shipid")) then
				content.AssignValue "required_ship_name", getShipLabel(oRs("required_shipid"))
				content.AssignValue "required_ship_available", oRs("required_ship_count")
				if oRs("required_ship_count") = 0 then content.Parse "category.ship.required_ship.none_available"
				content.Parse "category.ship.required_ship"
			end if

			if oRs("cost_prestige") > 0 then
				content.AssignValue "required_pp", oRs("cost_prestige")
				content.AssignValue "pp", oPlayerInfo("prestige_points")
				if oRs("cost_prestige") > oPlayerInfo("prestige_points") then content.Parse "category.ship.required_pp.not_enough"
				content.Parse "category.ship.required_pp"
			end if

			content.AssignValue "ore", oRs("cost_ore")
			content.AssignValue "hydrocarbon", oRs("cost_hydrocarbon")
			content.AssignValue "energy", oRs("cost_energy")
			content.AssignValue "workers", oRs("workers")
			content.AssignValue "crew", oRs("crew")
			content.AssignValue "upkeep", oRs("upkeep")

			content.AssignValue "quantity", oRs("quantity")

			content.AssignValue "time", oRs("construction_time")

			' assign ship description
			content.AssignValue "description", getShipDescription(oRs("shipid"))

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
			content.AssignValue "ship_required_vortex_strength", oRs("required_vortex_strength")

			content.AssignValue "ship_leadership", oRs("mod_leadership")


			if oRs("research_requirements_met") then
				content.Parse "category.ship.construction_time"

				notenoughresources = false

				if oRs("cost_ore") > oPlanet(0) then
					content.Parse "category.ship.not_enough_ore"
					notenoughresources = true
				end if

				if oRs("cost_hydrocarbon") > oPlanet(1) then
					content.Parse "category.ship.not_enough_hydrocarbon"
					notenoughresources = true
				end if

				if oRs("cost_energy") > oPlanet(2) then
					content.Parse "category.ship.not_enough_energy"
					notenoughresources = true
				end if

				if oRs("crew") > oPlanet(3) then
					content.Parse "category.ship.not_enough_crew"
					notenoughresources = true
				end if

				can_build = true

				if not oRs("buildings_requirements_met") then
					content.Parse "category.ship.buildings_required"
					can_build = false
				end if

				if notenoughresources then
					content.Parse "category.ship.notenoughresources"
					can_build = false
				end if

				if can_build then
					content.Parse "category.ship.build"
					buildable = buildable + 1
				end if
			else
				content.Parse "category.ship.no_construction_time"
				content.Parse "category.ship.cant_build"
			end if

			if Session("privilege") >= 100 then content.Parse "category.ship.dev"


			dim i
			for i = 0 to dbShipsReqCount
				if dbShipsReqArray(0, i) = ShipId then
					content.AssignValue "building", getBuildingLabel(dbShipsReqArray(1, i))
					content.Parse "category.ship.buildingsrequired"
				end if
			next


			content.Parse "category.ship"

			count = count + 1
		end if

		oRs.MoveNext
	wend

	if itemCount > 0 then
		content.Parse "category.category" & category
	end if

	if buildable > 0 then
		content.AssignValue "shipnumber", buildable
		content.Parse "category.build"
	else
		content.Parse "category.nobuild"
	end if

	if count > 0 then content.Parse "category"

	if count = 0 then content.Parse "no_shipyard"

	displayQueue content, CurrentPlanet

	content.Parse ""

	Display(content)
end sub

' List all the available ships for recycling
sub ListRecycleShips()

	selected_menu = "shipyard_recycle"

	dim oRs, query
	dim underConstructionCount, notenoughresources, can_build

	' list ships that are on the planet
	query = "SELECT id, category, name, int4(cost_ore * const_recycle_ore(planet_ownerid)) AS cost_ore, int4(cost_hydrocarbon * const_recycle_hydrocarbon(planet_ownerid)) AS cost_hydrocarbon, cost_credits, workers, crew, capacity," &_
			" int4(const_ship_recycling_multiplier() * construction_time) as construction_time, hull, shield, weapon_power, weapon_ammo, weapon_tracking_speed, weapon_turrets, signature, speed," &_
			" handling, buildingid, recycler_output, droppods, long_distance_capacity, quantity, true, true," &_
			" null, 0, COALESCE(new_shipid, id) AS shipid" &_
			" FROM vw_ships" &_
			" WHERE quantity > 0 AND planetid=" & CurrentPlanet

	set oRs = oConn.Execute(query)

	dim content
	set content = GetTemplate("shipyard-recycle")

	content.AssignValue "planetid", CurrentPlanet
	content.AssignValue "filter", ShipFilter

	dim category, lastCategory, itemCount, buildable

	' number of items in category
	itemCount = 0

	' number of ships types that can be built
	buildable = 0

	if not oRs.EOF then
		category = oRs("category")
		lastCategory = category 
	end if

	dim count
	count = 0
	while not oRs.EOF
			dim id, quantity
			category = oRs("category")

			if category <> lastCategory then
				if itemCount > 0 then
					content.Parse "category.category" & lastcategory
					content.Parse "category"
				end if

				lastCategory = category

				itemCount = 0
			end if

			itemCount = itemCount + 1

			content.AssignValue "id", oRs(0)
			content.AssignValue "name", getShipLabel(oRs("shipid"))

			content.AssignValue "ore", oRs("cost_ore")
			content.AssignValue "hydrocarbon", oRs("cost_hydrocarbon")
			content.AssignValue "credits", oRs("cost_credits")
			content.AssignValue "workers", oRs("workers")
			content.AssignValue "crew", oRs("crew")

			content.AssignValue "quantity", oRs("quantity")

			content.AssignValue "time", oRs("construction_time")

			' assign ship description
			content.AssignValue "description", getShipDescription(oRs("shipid"))

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


			content.Parse "category.ship.construction_time"

			can_build = true

			content.Parse "category.ship.build"
			buildable = buildable + 1

			if Session("privilege") >= 100 then content.Parse "category.ship.dev"

			content.Parse "category.ship"

			count = count + 1

		oRs.MoveNext
	wend

	if itemCount > 0 then
		content.Parse "category.category" & category
	end if

	if buildable > 0 then
		content.AssignValue "shipnumber", buildable
		content.Parse "category.build"
	else
		content.Parse "category.nobuild"
	end if

	if count > 0 then content.Parse "category"

	if count = 0 then content.Parse "no_shipyard"


	displayQueue content, CurrentPlanet

	content.Parse ""

	Display(content)
end sub


' build ships

sub StartShip(ShipId, quantity)
	connExecuteRetryNoRecords "SELECT sp_start_ship(" & CurrentPlanet & "," & ShipId & "," & quantity & ", false)"
end sub

sub BuildShips()
	dim i, quantity, shipid

	for i = 0 to dbShipsCount
		shipid = dbShipsArray(0, i)

		quantity = ToInt(Request.Form("s" & shipid), 0)
		if quantity > 0 then StartShip shipid, quantity
	next

	Response.Redirect "?f="&ShipFilter
	Response.End
end sub


' recycle ships

sub RecycleShip(ShipId, quantity)
	connExecuteRetryNoRecords "SELECT sp_start_ship_recycling(" & CurrentPlanet & "," & ShipId & "," & quantity & ")"
end sub

sub RecycleShips()
	dim i, quantity, shipid

	for i = 0 to dbShipsCount
		shipid = dbShipsArray(0, i)

		quantity = ToInt(Request.Form("s" & shipid), 0)
		if quantity > 0 then RecycleShip shipid, quantity
	next

	Response.Redirect "?recycle=1"
	Response.End
end sub


sub CancelQueue(QueueId)
	connExecuteRetryNoRecords "SELECT sp_cancel_ship(" & CurrentPlanet & ", " & QueueId & ")"
	if Request.QueryString("recycle") <> "" then
		Response.Redirect "?recycle=1"
	else
		Response.Redirect "?f="&ShipFilter
	end if

	Response.end
end sub

dim Action
Action = lcase(Request.QueryString("a"))


' retrieve which page to display
ShipFilter = ToInt(Request.QueryString("f"), "")

if ShipFilter = "" then
	ShipFilter = ToInt(Session("shipyardfilter"), 0)
end if

if ShipFilter < 0 or ShipFilter > 3 then ShipFiler = 0

Session("shipyardfilter") = ShipFilter


if Action = "build" or Action = "bui1d" then
	if Action <> "bui1d" then
		scripturl = Request.ServerVariables("SCRIPT_NAME") & "?..."
		log_notice "shipyard.asp", "used BAD 'build' action", 2
	end if
	BuildShips()
end if

if Action = "recycle" then RecycleShips()

if Action = "cancel" then
	dim QueueId
	QueueId = ToInt(Request.QueryString("q"),0)

	if QueueId <> 0 then CancelQueue(QueueId)
end if

RetrieveData()

if Request.QueryString("recycle") <> "" then
	ListRecycleShips()
else
	ListShips()
end if
%>