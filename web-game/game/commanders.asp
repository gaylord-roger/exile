<%option explicit %>

<!--#include file="global.asp"-->

<%

const max_ore = 2.0
const max_hydrocarbon = 2.0
const max_energy = 2.0
const max_workers = 2.0

const max_speed = 1.3
const max_shield = 1.4
const max_handling = 1.75
const max_targeting = 1.75
const max_damages = 1.3
const max_signature = 1.2

const max_recycling = 1.1

const max_build = 3
const max_ship = 3

selected_menu = "commanders"

dim section

sub DisplayBonus(content, value)
	if value > 0 then
		content.AssignValue "bonus", "+" & value
		content.Parse section & ".commander.bonus.positive"
	elseif value < 0 then
		content.AssignValue "bonus", value
		content.Parse section & ".commander.bonus.negative"
	else
		content.AssignValue "bonus", value
	end if
	
	content.Parse section & ".commander.bonus"
end sub


' List the commanders owned by the player
sub ListCommanders()
	dim content, oRs, query
	set content = GetTemplate("commanders")

	content.AssignValue "planetid", CurrentPlanet


	' generate new commanders if needed for the player
	oConn.Execute "SELECT sp_commanders_check_new_commanders(" & UserId & ")", , adExecuteNoRecords

	dim can_engage_commander

	' retrieve how many commanders are controled by the player
	set oRs = oConn.Execute("SELECT int4(count(1)) FROM commanders WHERE recruited <= now() AND ownerid=" & UserId)
	can_engage_commander = oRs(0) < oPlayerInfo("mod_commanders")


	' Retrieve all the commanders belonging to the player
	query = "SELECT c.id, c.name, c.recruited, points, added, salary, can_be_fired, " &_
			" p.id, p.galaxy, p.sector, p.planet, p.name, " &_
			" f.id, f.name, " &_
			" c.mod_production_ore, c.mod_production_hydrocarbon, c.mod_production_energy, " &_
			" c.mod_production_workers, c.mod_fleet_speed, c.mod_fleet_shield, " &_
			" c.mod_fleet_handling, c.mod_fleet_tracking_speed, c.mod_fleet_damage, c.mod_fleet_signature, "  &_
			" c.mod_construction_speed_buildings, c.mod_construction_speed_ships, last_training < now()-interval '1 day', sp_commanders_prestige_to_train(c.ownerid, c.id), salary_increases < 20" &_
			" FROM commanders AS c" &_
			"	LEFT JOIN fleets AS f ON (c.id=f.commanderid)" &_
			"	LEFT JOIN nav_planet AS p ON (c.id=p.commanderid)" &_
			" WHERE c.ownerid=" & UserID &_
			" ORDER BY upper(c.name)"
	set oRs = oConn.Execute(query)

	dim available_commanders_count, commanders_count
	available_commanders_count = 0
	commanders_count = 0

	while not oRs.EOF

		content.AssignValue "id", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "recruited", oRs(2).Value
		content.AssignValue "added", oRs(4).Value
		content.AssignValue "salary", oRs(5)


		if IsNull(oRs(2)) then
			section = "available_commanders"
			available_commanders_count = available_commanders_count + 1

			if can_engage_commander then
				content.Parse section & ".commander.can_engage"
			else
				content.Parse section & ".commander.cant_engage"
			end if
		else
			section = "commanders"
			commanders_count = commanders_count + 1

			if oRs(6) then
				content.Parse section & ".commander.can_fire"
			else
				content.Parse section & ".commander.cant_fire"
			end if
		end if


		if isNull(oRs(7)) then ' commander is not assigned to a planet
			if isNull(oRs(12)) then ' nor to a fleet
				content.Parse section & ".commander.not_assigned"
			else
				content.AssignValue "fleetid", oRs(12)
				content.AssignValue "commandment", oRs(13)
				content.Parse section & ".commander.fleet_command"				
			end if
		else
			content.AssignValue "planetid", oRs(7)
			content.AssignValue "g", oRs(8)
			content.AssignValue "s", oRs(9)
			content.AssignValue "p", oRs(10)
			content.AssignValue "commandment", oRs(11)
			content.Parse section & ".commander.planet_command"
		end if

		'
		' browse the possible bonus
		'
		dim i
		for i = 14 to 25
			if oRs(i) <> 1.0 then
				content.Parse section & ".commander.bonus.description" & i
				DisplayBonus content, Round((oRs(i)-1.0)*100)
			end if
		next

		if oRs(26) and oRs(28) then
			content.AssignValue "prestige", oRs(27)
			content.Parse section & ".commander.train"
		else
			if oRs(28) then
				content.Parse section & ".commander.cant_train"
			else
				content.Parse section & ".commander.cant_train_anymore"
			end if
		end if

		if oRs(3) > 0 then
			content.AssignValue "points", oRs(3)
			content.Parse section & ".commander.levelup"
		end if

		content.Parse section & ".commander"

		oRs.MoveNext
	wend

	content.AssignValue "commanders", commanders_count
	content.AssignValue "max_commanders", oPlayerInfo("mod_commanders")

	if available_commanders_count = 0 then content.Parse "available_commanders.nocommander"
	if commanders_count = 0 then content.Parse "commanders.nocommander"

	content.Parse "commanders"
	content.Parse "available_commanders"

	content.Parse ""

	FillHeaderCredits

	Display(content)
end sub


sub DisplayCommanderEdition(CommanderId)
	dim content
	set content = GetTemplate("commanders")

	content.AssignValue "commanderid", CommanderId

	if CommanderId <> 0 then
		dim query, oRs

		query = "SELECT mod_production_ore, mod_production_hydrocarbon, mod_production_energy," &_
				" mod_production_workers, mod_fleet_speed, mod_fleet_shield, mod_fleet_handling," &_
				" mod_fleet_tracking_speed, mod_fleet_damage, mod_fleet_signature," &_
				" mod_construction_speed_buildings, mod_construction_speed_ships," &_
				" points, name" &_
				" FROM commanders WHERE id=" & CommanderId & " AND ownerid=" & UserId
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			' commander not found !
			response.redirect "commanders.asp"
			response.end
		end if

		content.AssignValue "name", oRs("name")
		content.AssignValue "maxpoints", oRs("points")

		content.AssignValue "ore", Replace(oRs(0), ",", ".")
		content.AssignValue "hydrocarbon", Replace(oRs(1), ",", ".")
		content.AssignValue "energy", Replace(oRs(2), ",", ".")
		content.AssignValue "workers", Replace(oRs(3), ",", ".")

		content.AssignValue "speed", Replace(oRs(4), ",", ".")
		content.AssignValue "shield", Replace(oRs(5), ",", ".")
		content.AssignValue "handling", Replace(oRs(6), ",", ".")
		content.AssignValue "targeting", Replace(oRs(7), ",", ".")
		content.AssignValue "damages", Replace(oRs(8), ",", ".")
		content.AssignValue "signature", Replace(oRs(9), ",", ".")

		content.AssignValue "build", Replace(oRs(10), ",", ".")
		content.AssignValue "ship", Replace(oRs(11), ",", ".")

		content.AssignValue "max_ore", Replace(max_ore, ",", ".")
		content.AssignValue "max_hydrocarbon", Replace(max_hydrocarbon, ",", ".")
		content.AssignValue "max_energy", Replace(max_energy, ",", ".")
		content.AssignValue "max_workers", Replace(max_workers, ",", ".")

		content.AssignValue "max_speed", Replace(max_speed, ",", ".")
		content.AssignValue "max_shield", Replace(max_shield, ",", ".")
		content.AssignValue "max_handling", Replace(max_handling, ",", ".")
		content.AssignValue "max_targeting", Replace(max_targeting, ",", ".")
		content.AssignValue "max_damages", Replace(max_damages, ",", ".")
		content.AssignValue "max_signature", Replace(max_signature, ",", ".")

		content.AssignValue "max_build", Replace(max_build, ",", ".")
		content.AssignValue "max_ship", Replace(max_ship, ",", ".")

		content.AssignValue "max_recycling", Replace(max_recycling, ",", ".")
	end if

	content.Parse "editcommander"
	content.Parse ""

	Display(content)
end sub

function Max(a,b)
	if a<b then
		Max=b
	else
		Max=a
	end if
end function


sub EditCommander(CommanderId)
	dim ore, hydrocarbon, energy, workers, fleetspeed, fleetshield, fleethandling, fleettargeting, fleetdamages, fleetsignature, build, ship, total

	ore = max(0, ToInt(Request.Form("ore"), 0))
	hydrocarbon = max(0, ToInt(Request.Form("hydrocarbon"), 0))
	energy = max(0, ToInt(Request.Form("energy"), 0))
	workers = max(0, ToInt(Request.Form("workers"), 0))

	fleetspeed = max(0, ToInt(Request.Form("fleet_speed"), 0))
	fleetshield = max(0, ToInt(Request.Form("fleet_shield"), 0))
	fleethandling = max(0, ToInt(Request.Form("fleet_handling"), 0))
	fleettargeting = max(0, ToInt(Request.Form("fleet_targeting"), 0))
	fleetdamages = max(0, ToInt(Request.Form("fleet_damages"), 0))
	fleetsignature = max(0, ToInt(Request.Form("fleet_signature"), 0))

	build = max(0, ToInt(Request.Form("buildindspeed"), 0))
	ship = max(0, ToInt(Request.Form("shipconstructionspeed"), 0))

	total = ore + hydrocarbon + energy + workers + fleetspeed + fleetshield + fleethandling + fleettargeting + fleetdamages + fleetsignature + build + ship


	dim query, oRs

	query = "UPDATE commanders SET" &_
			"	mod_production_ore=mod_production_ore + 0.01*" & ore &_
			"	,mod_production_hydrocarbon=mod_production_hydrocarbon + 0.01*" & hydrocarbon &_
			"	,mod_production_energy=mod_production_energy + 0.1*" & energy &_
			"	,mod_production_workers=mod_production_workers + 0.1*" & workers &_
			"	,mod_fleet_speed=mod_fleet_speed + 0.02*" & fleetspeed &_
			"	,mod_fleet_shield=mod_fleet_shield + 0.02*" & fleetshield &_
			"	,mod_fleet_handling=mod_fleet_handling + 0.05*" & fleethandling &_
			"	,mod_fleet_tracking_speed=mod_fleet_tracking_speed + 0.05*" & fleettargeting &_
			"	,mod_fleet_damage=mod_fleet_damage + 0.02*" & fleetdamages &_
			"	,mod_fleet_signature=mod_fleet_signature + 0.02*" & fleetsignature &_
			"	,mod_construction_speed_buildings=mod_construction_speed_buildings + 0.05*" & build &_
			"	,mod_construction_speed_ships=mod_construction_speed_ships + 0.05*" & ship &_
			"	,points=points-" & total &_
			" WHERE ownerid=" & UserId & " AND id=" & CommanderId & " AND points >= " & total
	oConn.BeginTrans

	oConn.Execute query, , adExecuteNoRecords

	query = "SELECT mod_production_ore, mod_production_hydrocarbon, mod_production_energy," &_
				" mod_production_workers, mod_fleet_speed, mod_fleet_shield, mod_fleet_handling," &_
				" mod_fleet_tracking_speed, mod_fleet_damage, mod_fleet_signature," &_
				" mod_construction_speed_buildings, mod_construction_speed_ships" &_
				" FROM commanders" &_
				" WHERE id=" & CommanderId & " AND ownerid=" & UserId
	set oRs = oConn.execute(query)

	if oRs(0) <= max_ore+0.0001 and oRs(1) <= max_hydrocarbon+0.0001 and oRs(2) <= max_energy+0.0001 and oRs(3) <= max_workers+0.0001 and _
		oRs(4) <= max_speed+0.0001 and oRs(5) <= max_shield+0.0001 and oRs(6) <= max_handling+0.0001 and oRs(7) <= max_targeting+0.0001 and oRs(8) <= max_damages+0.0001 and oRs(9) <= max_signature+0.0001 and _
		oRs(10) <= max_build+0.0001 and oRs(11) <= max_ship+0.0001 then

		oConn.CommitTrans

		query = "SELECT sp_update_fleet_bonus(id) FROM fleets WHERE commanderid=" & CommanderId
		oConn.Execute query, , adExecuteNoRecords

		query = "SELECT sp_update_planet(id) FROM nav_planet WHERE commanderid=" & CommanderId
		oConn.Execute query, , adExecuteNoRecords
	else		
		oConn.RollbackTrans
	end if

	redirectTo "commanders.asp"
end sub

sub RenameCommander(CommanderId, NewName)
	dim query
	query = "SELECT sp_commanders_rename(" & UserID & "," & CommanderId & "," & dosql(NewName) & ")"
	oConn.Execute query, , adExecuteNoRecords
	redirectTo "commanders.asp"
end sub

sub EngageCommander(CommanderId)
	dim query
	query = "SELECT sp_commanders_engage(" & UserID & "," & CommanderId & ")"
	oConn.Execute query, , adExecuteNoRecords
	redirectTo "commanders.asp"
end sub

sub FireCommander(CommanderId)
	dim query
	query = "SELECT sp_commanders_fire(" & UserID & "," & CommanderId & ")"
	oConn.Execute query, , adExecuteNoRecords
	redirectTo "commanders.asp"
end sub

sub TrainCommander(CommanderId)
	dim query
	query = "SELECT sp_commanders_train(" & UserID & "," & CommanderId & ")"
	oConn.Execute query, , adExecuteNoRecords
	redirectTo "commanders.asp"
end sub

'if isPlayerAccount() then
'	dim content
'	set content = GetTemplate("maintenance")
'	content.parse ""
'	display(content)
'	response.end
'end if

dim CommanderId, NewName
CommanderId = ToInt(Request.QueryString("id"), 0)
NewName = Request.QueryString("name")

select case Request.QueryString("a")
	case "rename"
		RenameCommander CommanderId, NewName
	case "edit"
	Response.write "0"
		EditCommander CommanderId
	case "fire"
		FireCommander CommanderId
	case "engage"
		EngageCommander CommanderId
	case "skills"
		DisplayCommanderEdition CommanderId
	case "train"
		TrainCommander CommanderId
	case else
		ListCommanders
end select

%>