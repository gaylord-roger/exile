<%option explicit %>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "orbit"

showHeader = true

const e_no_error = 0
const e_bad_name = 1
const e_already_exists = 2

dim fleet_creation_error : fleet_creation_error = ""

sub DisplayFleets()
	dim content
	set content = GetTemplate("orbit")

	content.AssignValue "planetid", CurrentPlanet

	dim oRs, query

	' list the fleets near the planet
	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
		    " destplanetid, destplanet_name, destplanet_galaxy, destplanet_sector, destplanet_planet, destplanet_ownerid, destplanet_owner_name, destplanet_owner_relation," &_
			" action, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers" &_
			" FROM vw_fleets " &_
			" WHERE planetid="& CurrentPlanet &" AND action <> 1 AND action <> -1" &_
			" ORDER BY upper(name)"
	set oRs = oConn.Execute(query)

	dim manage, trade

	if oRs.EOF then
		content.Parse "nofleets"
	else
		while not oRs.EOF
			manage = false
			trade = false

			content.AssignValue "id", oRs(0)
			content.AssignValue "name", oRs(1)
			content.AssignValue "size", oRs(4)
			content.AssignValue "signature", oRs(5)

			content.AssignValue "ownerid", oRs(20)
			content.AssignValue "ownername", oRs(21)

			content.AssignValue "cargo", oRs(27)+oRs(28)+oRs(29)+oRs(30)+oRs(31)
			content.AssignValue "cargo_ore", oRs(27)
			content.AssignValue "cargo_hydrocarbon", oRs(28)
			content.AssignValue "cargo_scientists", oRs(29)
			content.AssignValue "cargo_soldiers", oRs(30)
			content.AssignValue "cargo_workers", oRs(31)


			if oRs(8) then
				content.AssignValue "commanderid", oRs(8)
				content.AssignValue "commandername", oRs(9)
				content.Parse "fleet.commander"
			else
				content.Parse "fleet.nocommander"
			end if

			if oRs(26) = 2 then
				content.Parse "fleet.recycling"
			elseif oRs(3) then
				content.Parse "fleet.fighting"
			else
				content.Parse "fleet.patrolling"
			end if

			select case oRs(17)
				case rHostile, rWar
					content.Parse "fleet.enemy"
				case rAlliance
					content.Parse "fleet.ally"
				case rFriend
					content.Parse "fleet.friend"
				case rSelf
					if oRs(26) = 0 then
					'	manage = true
				'		trade = true
					end if

					content.Parse "fleet.owner"
			end select

			if manage then
				content.Parse "fleet.manage"
			else
				content.Parse "fleet.cant_manage"
			end if

			if trade then
				content.Parse "fleet.trade"
			else
				content.Parse "fleet.cant_trade"
			end if

			content.Parse "fleet"

			oRs.MoveNext
		wend
	end if



	' list the ships on the planet to create a new fleet
	query = "SELECT shipid, quantity," &_
			" signature, capacity, handling, speed, (weapon_dmg_em + weapon_dmg_explosive + weapon_dmg_kinetic + weapon_dmg_thermal) AS weapon_power, weapon_turrets, weapon_tracking_speed, hull, shield, recycler_output, long_distance_capacity, droppods" & _
			" FROM planet_ships LEFT JOIN db_ships ON (planet_ships.shipid = db_ships.id)" &_
			" WHERE planetid=" & CurrentPlanet & _
			" ORDER BY category, label"

	set oRs = oConn.Execute(query)
	if oRs.EOF then
		content.Parse "noships"
	else
		while not oRs.EOF
			content.AssignValue "id", oRs(0)
			content.AssignValue "quantity", oRs(1)

			content.AssignValue "name", getShipLabel(oRs(0))

			if fleet_creation_error <> "" then content.AssignValue "ship_quantity", Request.Form("s" & oRs(0))

			' assign ship description
			content.AssignValue "description", getShipDescription(oRs(0))

			content.AssignValue "ship_signature", oRs("signature")
			content.AssignValue "ship_cargo", oRs("capacity")
			content.AssignValue "ship_handling", oRs("handling")
			content.AssignValue "ship_speed", oRs("speed")

			if oRs("weapon_power") > 0 then
				content.AssignValue "ship_turrets", oRs("weapon_turrets")
				content.AssignValue "ship_power", oRs("weapon_power")
				content.AssignValue "ship_tracking_speed", oRs("weapon_tracking_speed")
				content.Parse "new.ship.attack"
			end if

			content.AssignValue "ship_hull", oRs("hull")

			if oRs("shield") > 0 then
				content.AssignValue "ship_shield", oRs("shield")
				content.Parse "new.ship.shield"
			end if

			if oRs("recycler_output") > 0 then
				content.AssignValue "ship_recycler_output", oRs("recycler_output")
				content.Parse "new.ship.recycler_output"
			end if

			if oRs("long_distance_capacity") > 0 then
				content.AssignValue "ship_long_distance_capacity", oRs("long_distance_capacity")
				content.Parse "new.ship.long_distance_capacity"
			end if

			if oRs("droppods") > 0 then
				content.AssignValue "ship_droppods", oRs("droppods")
				content.Parse "new.ship.droppods"
			end if

			content.Parse "new.ship"

			oRs.MoveNext
		wend
		content.Parse "new"
	end if

	' Assign the fleet name passed in form body
	if fleet_creation_error <> "" then
		content.AssignValue "fleetname", Request.Form("name")

		content.Parse "error." & fleet_creation_error
		content.Parse "error"
	end if

	content.Parse ""

	Display(content)
end sub

'
' Create the new fleet
'
sub NewFleet()
	dim fleetname
	fleetname = Trim(Request.Form("name"))

	if not isValidObjectName(fleetname) then
		fleet_creation_error = "fleet_name_invalid"
		exit sub
	end if

	' retrieve all ships id that exists in shipsArray
	dim shipsArray, shipsCount
	set oRs = oConn.Execute("SELECT id FROM db_ships")

	shipsArray = oRs.GetRows()
	shipsCount = UBound(shipsArray, 2)

	oRs.Close
	set oRs = Nothing


	' Begin transaction to create a new fleet
	oConn.BeginTrans

	' create a new fleet at the current planet with the given name
	dim oRs
	set oRs = oConn.Execute("SELECT sp_create_fleet(" & UserID & "," & CurrentPlanet & "," & dosql(fleetname) & ")")
	if oRs.EOF then
		oConn.RollbackTrans
		exit sub
	end if

	dim fleetid
	fleetid = oRs(0)

	oRs.Close
	set oRs = Nothing


	if fleetid < 0 then
		if fleetid = -3 then
			fleet_creation_error = "fleet_too_many"
		else
			fleet_creation_error = "fleet_name_already_used"
		end if

		oConn.RollbackTrans
		exit sub
	end if

	dim i, shipid, quantity, cant_use_ship

	cant_use_ship = false

	for i = 0 to shipsCount
		shipid = shipsArray(0,i)
		quantity = ToInt(Request.Form("s" & shipid), 0)

		' add the ships type by type
		if quantity > 0 then
			set oRs = oConn.Execute("SELECT * FROM sp_transfer_ships_to_fleet(" & UserId & ", " & fleetid & ", " & shipid & ", " & quantity & ")")
			cant_use_ship = cant_use_ship or oRs(0) = 3
		end if
	next

	'oConn.Execute "UPDATE fleets SET attackonsight=firepower>0 WHERE id=" & fleetid & " AND ownerid=" & UserID, , adExecuteNoRecords

	' delete the fleet if there is no ships in it
	oConn.Execute "DELETE FROM fleets WHERE size=0 AND id=" & fleetid & " AND ownerid=" & UserID, , adExecuteNoRecords

	' Commit transaction
	oConn.CommitTrans

	if cant_use_ship and fleet_creation_error = "" then fleet_creation_error = "ship_cant_be_used"
end sub


select case Request.QueryString("a")
	case "new"
		NewFleet()
end select

DisplayFleets()

%>