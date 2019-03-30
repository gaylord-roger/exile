<%option explicit %>

<!--#include virtual="/lib/accounts.asp"-->
<!--#include file="global.asp"-->

<%
selected_menu = "fleets"

const e_no_error = 0

const e_bad_name = 1
const e_already_exists = 2
const e_occupied = 3
const e_limit_reached = 4

dim fleet_split_error : fleet_split_error = e_no_error


' display fleet info
sub DisplayExchangeForm(fleetid)
	dim content
	if session(sprivilege) > 100 then
		set content = GetTemplate("fleet-split")
	else
		set content = GetTemplate("fleet-split_old")
	end if

	dim oRs, query

	' retrieve fleet name, size, position, destination
	query = "SELECT id, name, attackonsight, engaged, size, signature, speed, remaining_time, commanderid, commandername," &_
			" planetid, planet_name, planet_galaxy, planet_sector, planet_planet, planet_ownerid, planet_owner_name, planet_owner_relation," &_
		    " cargo_capacity, cargo_ore, cargo_hydrocarbon, cargo_scientists, cargo_soldiers, cargo_workers," & _
			" action " &_
			" FROM vw_fleets" &_
			" WHERE ownerid="&UserID&" AND id="&fleetid

	set oRs = oConn.Execute(query)

	' if fleet doesn't exist, redirect to the list of fleets
	if oRs.EOF then 'or session("privilege") <100 then
		Response.Redirect "fleets.asp"
		Response.End
	end if

	' if fleet is moving or engaged, go back to the fleets
	if oRs(24) <> 0 then
		Response.Redirect "fleet.asp?id=" & fleetid
		Response.End
	end if

	content.AssignValue "fleetid", fleetid
	content.AssignValue "fleetname", oRs(1)
	content.AssignValue "size", oRs(4)
	content.AssignValue "speed", oRs(6)


	content.AssignValue "fleet_capacity", oRs(18)
	content.AssignValue "available_ore", oRs(19)
	content.AssignValue "available_hydrocarbon", oRs(20)
	content.AssignValue "available_scientists", oRs(21)
	content.AssignValue "available_soldiers", oRs(22)
	content.AssignValue "available_workers", oRs(23)

	content.AssignValue "fleet_load", oRs(19) + oRs(20) + oRs(21) + oRs(22) + oRs(23)

	dim shipCount
	shipCount = 0
	' retrieve the list of ships in the fleet
	query = "SELECT db_ships.id, db_ships.label, db_ships.capacity, db_ships.signature," & _
				"COALESCE((SELECT quantity FROM fleets_ships WHERE fleetid=" & fleetid & " AND shipid = db_ships.id), 0)" & _
			" FROM fleets_ships" & _
			"	INNER JOIN db_ships ON (db_ships.id=fleets_ships.shipid)" &_
			" WHERE fleetid=" & fleetid &_
			" ORDER BY db_ships.category, db_ships.label"

	set oRs = oConn.Execute(query)

	while not oRs.EOF
		shipCount = shipCount + 1
		content.AssignValue "id", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "cargo_capacity", oRs(2)
		content.AssignValue "signature", oRs(3)
		content.AssignValue "quantity", oRs(4)

		if fleet_split_error <> e_no_error then
			content.AssignValue "transfer", Request.Form("transfership"&oRs(0))
		end if

		content.Parse "ship"

		oRs.MoveNext
	wend

	if fleet_split_error <> e_no_error then
		content.Parse "error"&fleet_split_error
		content.AssignValue "t_ore", Request.Form("load_ore")
		content.AssignValue "t_hydrocarbon", Request.Form("load_hydrocarbon")
		content.AssignValue "t_scientists", Request.Form("load_scientists")
		content.AssignValue "t_workers", Request.Form("load_workers")
		content.AssignValue "t_soldiers", Request.Form("load_soldiers")
	end if
			

	content.Parse ""

	Display(content)
end sub


' split current fleet into 2 fleets
sub SplitFleet(fleetid)
	dim oRs, query

	dim newfleetname
	newfleetname = Request.Form("newname")

	if not isValidObjectName(newfleetname) then
		fleet_split_error = e_bad_name
		exit sub
	end if


	'
	' retrieve the planet where the current fleet is patrolling
	'
	dim fleetplanetid
	query = "SELECT planetid FROM vw_fleets WHERE ownerid="&UserID&" AND id="&fleetid
	set oRs = oConn.Execute(query)
	if oRs.EOF then	exit sub

	fleetplanetid = clng(oRs(0))

	oRs.Close
	set oRs = Nothing

	'
	' retrieve 'source' fleet cargo and action
	'
	dim ore, hydrocarbon, scientists, soldiers, workers

	query = " SELECT id, action, cargo_ore, cargo_hydrocarbon, " &_
			" cargo_scientists, cargo_soldiers, cargo_workers" &_
			" FROM vw_fleets" &_
			" WHERE ownerid="&UserID&" AND id="&fleetid
	set oRs = oConn.Execute(query)

	if oRs.EOF or (oRs(1) <> 0) then
		fleet_split_error = e_occupied
		exit sub
	end if

	ore = Min( ToInt(Request.Form("load_ore"), 0), oRs(2) )
	hydrocarbon = Min( ToInt(Request.Form("load_hydrocarbon"), 0), oRs(3) )
	scientists = Min( ToInt(Request.Form("load_scientists"), 0), oRs(4) )
	soldiers = Min( ToInt(Request.Form("load_soldiers"), 0), oRs(5) )
	workers = Min( ToInt(Request.Form("load_workers"), 0), oRs(6) )

	oRs.Close
	set oRs = Nothing

	'
	' begin transaction
	'
	oConn.BeginTrans

	On Error Resume Next
	err.clear

	'
	' 1/ create a new fleet at the current fleet planet with the given name
	'
	dim newfleetid
	set oRs = oConn.Execute("SELECT sp_create_fleet(" & UserID & "," & fleetplanetid & "," & dosql(newfleetname) & ")")
	if oRs.EOF then
		oConn.RollbackTrans
		exit sub
	end if

	newfleetid = clng(oRs(0))

	if newfleetid < 0 then
		if newfleetid = -1 then
			fleet_split_error = e_already_exists
		end if

		if newfleetid = -2 then
			fleet_split_error = e_already_exists
		end if

		if newfleetid = -3 then
			fleet_split_error = e_limit_reached
		end if

		oConn.RollbackTrans
		exit sub
	end if


	'
	' 2/ add the ships to the new fleet
	'

	' retrieve ships belonging to current fleet
	dim availableCount, availableArray
	query = "SELECT db_ships.id, " & _
				"COALESCE((SELECT quantity FROM fleets_ships WHERE fleetid=" & fleetid & " AND shipid = db_ships.id), 0)" & _
			" FROM db_ships" & _
			" ORDER BY db_ships.category, db_ships.label"
	set oRs = oConn.Execute(query)
	
	if oRs.EOF then
		availableCount = -1
	else
		availableArray = oRs.GetRows()
		availableCount = UBound(availableArray, 2)
	end if


	' for each available ship id, check if the player wants to add ships of this kind
	dim i, quantity, shipid
	for i = 0 to availableCount
		shipid = availableArray(0,i)

		quantity = Min( ToInt(Request.Form("transfership" & shipid), 0), availableArray(1,i) ) 

		if quantity > 0 then
			' add the ships to the new fleet
			query = " INSERT INTO fleets_ships (fleetid, shipid, quantity)" &_
					" VALUES (" & newfleetid &","& shipid &","& quantity & ")"
			oConn.Execute query, , adExecuteNoRecords
		end if
	next


	' reset fleets idleness, partly to prevent cheating and being able to do multiple invasions with only a fleet
	oConn.Execute "UPDATE fleets SET idle_since=now()" &_
					" WHERE ownerid =" & UserID & " AND (id="&newfleetid&" OR id="&fleetid&")", , adExecuteNoRecords

	'
	' 3/ Move the resources to the new fleet
	'   a/ Add resources to the new fleet
	'   b/ Remove resource from the 'source' fleet
	'

	' retrieve new fleet's cargo capacity
	set oRs = oConn.Execute("SELECT cargo_capacity FROM vw_fleets WHERE ownerid="&UserID&" AND id="&newfleetid)
	if Err.Number <> 0 then
			oConn.RollbackTrans
			exit sub
	end if

	dim newload
	newload = oRs(0)

	ore = Min( ore, newload)
	newload = newload - ore

	hydrocarbon = Min( hydrocarbon, newload)
	newload = newload - hydrocarbon

	scientists = Min( scientists, newload)
	newload = newload - scientists

	soldiers = Min( soldiers, newload)
	newload = newload - soldiers

	workers = Min( workers, newload)
	newload = newload - workers


	if ore <> 0 or hydrocarbon <> 0 or scientists <> 0 or soldiers <> 0 or workers <> 0 then
		' a/ put the resources to the new fleet
		oConn.Execute "UPDATE fleets SET" &_
					" cargo_ore="&ore&", cargo_hydrocarbon="&hydrocarbon&", " &_
					" cargo_scientists="&scientists&", cargo_soldiers="&soldiers&", " &_
					" cargo_workers="&workers &_
					" WHERE id =" & newfleetid & " AND ownerid =" & UserID, , adExecuteNoRecords
		if Err.Number <> 0 then
			oConn.RollbackTrans
			exit sub
		end if

		' b/ remove the resources from the 'source' fleet
		oConn.Execute "UPDATE fleets SET" &_
					" cargo_ore=cargo_ore-"&ore&", cargo_hydrocarbon=cargo_hydrocarbon-"&hydrocarbon&", " &_
					" cargo_scientists=cargo_scientists-"&scientists&", " &_
					" cargo_soldiers=cargo_soldiers-"&soldiers&", " &_
					" cargo_workers=cargo_workers-"&workers &_
					" WHERE id =" & fleetid & " AND ownerid =" & UserID, , adExecuteNoRecords
		if Err.Number <> 0 then
			oConn.RollbackTrans
			exit sub
		end if
	end if


	'
	' 4/ Remove the ships from the 'source' fleet
	'
	for i = 0 to availableCount
		shipid = availableArray(0,i)

		quantity = Min( ToInt(Request.Form("transfership" & shipid), 0), availableArray(1,i) ) 

		if quantity > 0 then
			' remove the ships from the 'source' fleet
			query = " UPDATE fleets_ships SET" &_
					" quantity=quantity-" & quantity &_
					" WHERE fleetid=" & fleetid & " AND shipid=" & shipid
			oConn.Execute query, , adExecuteNoRecords

			if Err.Number <> 0 then
				oConn.RollbackTrans
				exit sub
			end if
		end if
	next

	query = "DELETE FROM fleets WHERE ownerid=" & UserId & " AND size=0"
	oConn.Execute query, , adExecuteNoRecords

	oConn.CommitTrans
	Response.Redirect "fleet.asp?id="&newfleetid
	Response.End
end sub

sub ExecuteOrder(fleetid)
	if Request.Form("split") = "1" then
		SplitFleet fleetid
	end if
end sub

dim fleetid
fleetid = ToInt(Request.QueryString("id"), 0)

if fleetid = 0 then
	Response.Redirect "fleets.asp"
	Response.End
end if

ExecuteOrder(fleetid)

DisplayExchangeForm(fleetid)

%>