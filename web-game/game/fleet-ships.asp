<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets"

const e_no_error = 0
const e_bad_destination = 1

dim fleet_error : fleet_error = e_no_error
dim fleet_planet : fleet_planet = 0

' display fleet info
sub DisplayFleet(fleetid)
	dim content
	set content = GetTemplate("fleet-ships")

	dim oRs, query

	' retrieve fleet name, size, position, destination
	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
			" cargo_capacity, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers" & _
			" FROM vw_fleets WHERE ownerid="&UserID&" AND id="&fleetid

	set oRs = oConn.Execute(query)

	' if fleet doesn't exist, redirect to the list of fleets
	if oRs.EOF then
		Response.Redirect "fleets.asp"
		Response.End
	end if

	' if fleet is moving or engaged, go back to the fleets
	if oRs(7) or oRs(3) then
		Response.Redirect "fleet.asp?id=" & fleetid
		Response.End
	end if


	content.AssignValue "fleetid", fleetid
	content.AssignValue "fleetname", oRs(1)
	content.AssignValue "size", oRs(4)
	content.AssignValue "speed", oRs(6)

	content.AssignValue "fleet_capacity", oRs(18)
	content.AssignValue "fleet_load", oRs(19) + oRs(20) + oRs(21) + oRs(22) + oRs(23)


	dim shipCount
	shipCount = 0

	if oRs(17) = rSelf then
		' retrieve the list of ships in the fleet
		query = "SELECT db_ships.id, db_ships.capacity," & _
				"COALESCE((SELECT quantity FROM fleets_ships WHERE fleetid=" & fleetid & " AND shipid = db_ships.id), 0)," & _
				"COALESCE((SELECT quantity FROM planet_ships WHERE planetid=(SELECT planetid FROM fleets WHERE id=" & fleetid & ") AND shipid = db_ships.id), 0)" & _
				" FROM db_ships" & _
				" ORDER BY db_ships.category, db_ships.label"

		set oRs = oConn.Execute(query)

		while not oRs.EOF
			if oRs(2) > 0 or oRs(3) > 0 then
				shipCount = shipCount + 1

				content.AssignValue "id", oRs(0)
				content.AssignValue "name", getShipLabel(oRs(0))
				content.AssignValue "cargo_capacity", oRs(1)
				content.AssignValue "quantity", oRs(2)
				content.AssignValue "available", oRs(3)

				content.Parse "ship"
			end if

			oRs.MoveNext
		wend

		content.Parse "shiplist.can_manage"
	end if

	content.Parse "shiplist"
	content.Parse ""

	Display(content)
end sub

' Transfer ships between the planet and the fleet
sub TransferShips(fleetid)
	dim oRs, query
	dim ShipsRemoved: ShipsRemoved = 0

	' if units are removed, the fleet may be destroyed so retrieve the planetid where the fleet is
	dim fleet_planet
	if fleet_planet = 0 then
		set oRs = oConn.Execute("SELECT planetid FROM fleets WHERE id=" & fleetid)

		if oRs.EOF then
			fleet_planet = -1
		else
			fleet_planet = oRs(0)
		end if
	end if

	' retrieve the list of all existing ships
	dim shipsCount, shipsArray
	set oRs = oConn.Execute("SELECT id FROM db_ships")

	if oRs.EOF then
		shipsCount = -1
	else
		shipsArray = oRs.GetRows()
		shipsCount = UBound(shipsArray, 2)
	end if


	dim i, quantity, shipid


	' for each ship id, check if the player wants to add ships of this kind
	for i = 0 to shipsCount
		shipid = shipsArray(0,i)

		quantity = ToInt(Request.Form("addship" & shipid), 0)

		if quantity > 0 then
			oConn.Execute "SELECT sp_transfer_ships_to_fleet(" & UserID & "," & fleetid & "," & shipid & "," & quantity & ")", , adExecuteNoRecords
		end if
	next

	' for each ship id, check if the player wants to remove ships of this kind
	for i = 0 to shipsCount
		shipid = shipsArray(0,i)

		quantity = ToInt(Request.Form("removeship" & shipid), 0)
		if quantity > 0 then
			ShipsRemoved = ShipsRemoved + quantity
			oConn.Execute "SELECT sp_transfer_ships_to_planet(" & UserID & "," & fleetid & "," & shipid & "," & quantity & ")", , adExecuteNoRecords
		end if
	next

	if ShipsRemoved > 0 then
		set oRs = oConn.Execute("SELECT id FROM fleets WHERE id=" & fleetid)

		if oRs.EOF then
			if fleet_planet > 0 then
				Response.Redirect "orbit.asp?planet=" & fleet_planet
			else
				Response.Redirect "fleets.asp"
			end if
		end if
	end if
end sub


sub ExecuteOrder(fleetid)
	if Request.Form("transfer_ships") = 1 then
		TransferShips(fleetid)
	end if
end sub

dim fleetid: fleetid = Request.QueryString("id")

if fleetid = "" or not isNumeric(fleetid) then
	Response.Redirect "fleets.asp"
	Response.End
end if

fleetid = CLng(fleetid)

ExecuteOrder(fleetid)

DisplayFleet(fleetid)

%>