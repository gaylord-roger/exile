<%option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "planet"

showHeader = true

const e_no_error = 0
const e_rename_bad_name = 1

dim planet_error : planet_error = e_no_error

sub DisplayPlanet()
	dim content
	set content = GetTemplate("planet")

	dim oRs, query, CmdReq, CmdId
	CmdReq=""

	query = "SELECT id, name, galaxy, sector, planet, " & _
			"floor_occupied, floor, space_occupied, space, workers, workers_capacity, mod_production_workers," & _
			"scientists, scientists_capacity, soldiers, soldiers_capacity, commanderid, recruit_workers," & _
			"planet_floor, COALESCE(buy_ore, 0), COALESCE(buy_hydrocarbon, 0)" &_
			" FROM vw_planets WHERE id=" & CurrentPlanet 

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		content.AssignValue "planet_id", oRs(0)
		content.AssignValue "planet_name", oRs(1)
		content.AssignValue "planet_img", planetimg(oRs(0), oRs(18))

		content.AssignValue "g", oRs(2)
		content.AssignValue "s", oRs(3)
		content.AssignValue "p", oRs(4)

		content.AssignValue "floor_occupied", oRs(5)
		content.AssignValue "floor", oRs(6)

		content.AssignValue "space_occupied", oRs(7)
		content.AssignValue "space", oRs(8)

		content.AssignValue "workers", oRs(9)
		content.AssignValue "workers_capacity", oRs(10)

		content.AssignValue "scientists", oRs(12)
		content.AssignValue "scientists_capacity", oRs(13)

		content.AssignValue "soldiers", oRs(14)
		content.AssignValue "soldiers_capacity", oRs(15)

		content.AssignValue "growth", oRs(11)/10

		if ors(17) then
			content.Parse "suspend"
		else
			content.Parse "resume"
		end if

		content.AssignValue "buy_ore", oRs(19)
		content.AssignValue "buy_hydrocarbon", oRs(20)

		' retrieve commander assigned to this planet
		if not isNull(oRs(16)) then
			dim oCmdRs : oCmdRs = oConn.Execute("SELECT name FROM commanders WHERE ownerid="&UserID&" AND id="&oRs(16))
			content.AssignValue "commander", oCmdRs(0)
			CmdId = oRs(16)
			content.Parse "commander"
		else 
			content.Parse "nocommander"
			CmdId = 0
		end if
	end if
	

	if CmdId = 0 then ' display "no commander" or "fire commander"
		content.Parse "none"
	else 
		content.Parse "unassign"
	end if

	' display commmanders
	
	query = " SELECT id, name, fleetname, planetname, fleetid " & _
			" FROM vw_commanders" &_
			" WHERE ownerid="&UserID & _
			" ORDER BY fleetid IS NOT NULL, planetid IS NOT NULL, fleetid, planetid "
	set oRs = oConn.Execute(query)

	dim lastItem, item, ShowGroup
	lastItem = ""
	item = ""
	ShowGroup = false

	while not oRs.EOF 
		if isNull(oRs(2)) and isNull(oRs(3)) then
			item = "none"
		elseif isNull(oRs(2)) then
			item = "planet"
		else
			item = "fleet"
		end if

		if item <> lastItem then
			if ShowGroup then content.Parse "optgroup"
			content.Parse "optgroup."&item
		end if
		
		if CmdId = oRs(0) then content.Parse "optgroup.cmd_option.selected"
		content.AssignValue "cmd_id", oRs(0)
		content.AssignValue "cmd_name", oRs(1)
		if item = "planet" then 
			content.AssignValue "name", oRs(3)
			content.Parse "optgroup.cmd_option.assigned"
		end if
		if item = "fleet" then 
			content.AssignValue "name", oRs(2)
			dim activityRs
			set activityRs = oConn.Execute("SELECT dest_planetid, engaged, action FROM fleets WHERE ownerid="&UserID&" AND id="&oRs(4))
			if isNull(activityRs(0)) and (not activityRs(1)) and activityRs(2)=0 then
				content.Parse "optgroup.cmd_option.assigned"
			else
				content.Parse "optgroup.cmd_option.unavailable"
			end if
		end if
		content.Parse "optgroup.cmd_option"
		oRs.MoveNext
		ShowGroup = true
		lastItem = item
	wend
	if ShowGroup then content.Parse "optgroup"


	' view current buildings constructions
	query = "SELECT buildingid, remaining_time, destroying" & _
			" FROM vw_buildings_under_construction2 WHERE planetid="&CurrentPlanet & _
			" ORDER BY remaining_time DESC"

	set oRs = oConn.Execute(query)

	dim i
	i = 0
	while not oRs.eof

		content.AssignValue "buildingid", oRs(0)
		content.AssignValue "building", getBuildingLabel(oRs(0))
		content.AssignValue "time", oRs(1)

		if oRs(2) then content.Parse "building.destroy"

		content.Parse "building"

		oRs.MoveNext
		i = i + 1
	wend

	if i=0 then content.Parse "nobuilding"


	query = "SELECT shipid, remaining_time, recycle" & _
			" FROM vw_ships_under_construction" & _
			" WHERE ownerid=" & userid & " AND planetid=" & CurrentPlanet & " AND end_time IS NOT NULL" &_
			" ORDER BY remaining_time DESC"

	' view current ships constructions
	Set oRs = oConn.Execute(query)

	i = 0

	while not oRs.eof

		content.AssignValue "shipid", oRs(0)
		content.AssignValue "ship", getShipLabel(oRs(0))
		content.AssignValue "time", oRs(1)

		if oRs(2) then content.Parse "ship.recycle"

		content.Parse "ship"

		oRs.MoveNext
		i = i + 1
	wend

	if i=0 then content.Parse "noship"


	' list the fleets near the planet
	query = "SELECT id, name, attackonsight, engaged, size, signature, commanderid, (SELECT name FROM commanders WHERE id=commanderid) as commandername," &_
			" action, sp_relation(ownerid, " & UserId & ") AS relation, sp_get_user(ownerid) AS ownername" & _
			" FROM fleets" & _
			" WHERE action <> -1 AND action <> 1 AND planetid=" & CurrentPlanet &_
			" ORDER BY upper(name)"

	set oRs = oConn.Execute(query)

	i = 0

	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "size", oRs(4)
		content.AssignValue "signature", oRs(5)

		if oRs("relation") > rFriend then
			content.AssignValue "name", oRs("name")
		else
			content.AssignValue "name", oRs("ownername")
		end if

		if not isNull(oRs(6)) then
			content.AssignValue "commanderid", oRs(6)
			content.AssignValue "commandername", oRs(7)
			content.Parse "fleet.commander"
		else
			content.Parse "fleet.nocommander"
		end if

		if oRs(3) then
			content.Parse "fleet.fighting"
		elseif oRs("action") = 2 then
			content.Parse "fleet.recycling"
		else
			content.Parse "fleet.patrolling"
		end if

		select case oRs("relation")
			case rHostile, rWar
				content.Parse "fleet.enemy"
			case rFriend
				content.Parse "fleet.friend"
			case rAlliance
				content.Parse "fleet.ally"
			case rSelf
				content.Parse "fleet.owner"
		end select

'		if oRs(22) >= 0 then
'			if oRs(18) then
'				content.Parse "fleet.attack"
'			else
'				content.Parse "fleet.defend"
'			end if

'		else
'			content.Parse "fleet.unknown_stance"
'			content.Parse "fleet.nocommander"
'		end if

		i = i + 1

		content.Parse "fleet"

		oRs.MoveNext
	wend

	if i=0 then content.Parse "nofleet"


	select case planet_error
		case e_rename_bad_name
			content.Parse "rename_bad_name"
	end select
	content.Parse "ondev"

	content.Parse ""

	Display(content)
end sub


dim query, amount

select case Request.Form("action")
	case "assigncommander"
		if Request.Form("commander") <> 0 then ' assign selected commander
			query = "SELECT * FROM sp_commanders_assign(" & UserId & "," & dosql(Request.Form("commander")) & "," & CurrentPlanet & ",null)"
			oConn.Execute query, , adExecuteNoRecords
		else
			' unassign current planet commander
			query = "UPDATE nav_planet SET commanderid=NULL WHERE ownerid=" & UserID & " AND id=" & CurrentPlanet
			oConn.Execute query, , adExecuteNoRecords
		end if
	case "rename"
		if not IsValidObjectName(Request.Form("name")) then
			planet_error = e_rename_bad_name
		else
			query = "UPDATE nav_planet SET name=" & dosql(Request.Form("name")) & _
					" WHERE ownerid=" & UserID & " AND id=" & CurrentPlanet

			oConn.Execute query, , adExecuteNoRecords

			InvalidatePlanetList()
		end if

	case "firescientists"
		amount = ToInt(Request.Form("amount"), 0)
		oConn.Execute "SELECT sp_dismiss_staff(" & UserID & "," & CurrentPlanet & "," & amount & ",0,0)", , adExecuteNoRecords
	case "firesoldiers"
		amount = ToInt(Request.Form("amount"), 0)
		oConn.Execute "SELECT sp_dismiss_staff(" & UserID & "," & CurrentPlanet & "," & "0," & amount & ",0)", , adExecuteNoRecords
	case "fireworkers"
		amount = ToInt(Request.Form("amount"), 0)
		oConn.Execute "SELECT sp_dismiss_staff(" & UserID & "," & CurrentPlanet & "," & "0,0," & amount & ")", , adExecuteNoRecords

	case "abandon"
		oConn.Execute "SELECT sp_abandon_planet(" & UserID & "," & CurrentPlanet & ")", , adExecuteNoRecords
		InvalidatePlanetList()
		Response.Redirect "/game/overview.asp"

	case "resources_price"
		query = "UPDATE nav_planet SET" &_
				" buy_ore = GREATEST(0, LEAST(1000, " & dosql(ToInt(Request.Form("buy_ore"), 0)) & "))" &_
				" ,buy_hydrocarbon = GREATEST(0, LEAST(1000, " & dosql(ToInt(Request.Form("buy_hydrocarbon"), 0)) & "))" &_
				" WHERE ownerid=" & UserID & " AND id=" & CurrentPlanet
		oConn.Execute query, , adExecuteNoRecords
end select

select case Request.QueryString("a")
	case "suspend"
		oConn.Execute "SELECT sp_update_planet_production(" & CurrentPlanet & ")", , adExecuteNoRecords
		oConn.Execute "UPDATE nav_planet SET mod_production_workers=0, recruit_workers=false WHERE ownerid=" & UserID & " AND id=" & CurrentPlanet , , adExecuteNoRecords
	case "resume"
		oConn.Execute "UPDATE nav_planet SET recruit_workers=true WHERE ownerid=" & UserID & " AND id=" & CurrentPlanet , , adExecuteNoRecords
		oConn.Execute "SELECT sp_update_planet(" & CurrentPlanet & ")", , adExecuteNoRecords
end select

DisplayPlanet()

%>
