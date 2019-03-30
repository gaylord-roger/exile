<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "production"

showHeader = true

dim cat, action

dim BonusCount, content

' Display bonus given by a commander (typ=0), building (typ=1) or a research (typ=2)
sub DisplayBonus(oRs, typ)
	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "name", oRs(1)

		content.AssignValue "mod_production_ore", Round(oRs(2)*100)
		if oRs(2) > 0 then
			content.AssignValue "mod_production_ore", "+" & Round(oRs(2)*100)
			content.Parse "overview.bonus.item.ore_positive"
		elseif oRs(2) < 0 then
			content.Parse "overview.bonus.item.ore_negative"
		end if

		content.AssignValue "mod_production_hydrocarbon", Round(oRs(3)*100)
		if oRs(3) > 0 then
			content.AssignValue "mod_production_hydrocarbon", "+" & Round(oRs(3)*100)
			content.Parse "overview.bonus.item.hydrocarbon_positive"
		elseif oRs(3) < 0 then
			content.Parse "overview.bonus.item.hydrocarbon_negative"
		end if

		content.AssignValue "mod_production_energy", Round(oRs(4)*100)
		if oRs(4) > 0 then
			content.AssignValue "mod_production_energy", "+" & Round(oRs(4)*100)
			content.Parse "overview.bonus.item.energy_positive"
		elseif oRs(4) < 0 then
			content.Parse "overview.bonus.item.energy_negative"
		end if

		if typ = 0 then
			content.Parse "overview.bonus.item.commander"
		elseif typ = 1 then
			content.AssignValue "name", getBuildingLabel(oRs(0))
			content.AssignValue "description", getBuildingDescription(oRs(0))
			content.Parse "overview.bonus.item.building"
		else
			content.AssignValue "name", getResearchLabel(oRs(0))
			content.AssignValue "description", getResearchDescription(oRs(0))
			content.AssignValue "level", oRs(5)
			content.Parse "overview.bonus.item.research"
		end if

		content.Parse "overview.bonus.item"

		BonusCount = BonusCount + 1
		oRs.MoveNext
	wend
end sub

sub displayOverview(RecomputeIfNeeded)
	BonusCount = 0

	dim oRs, query

	' Assign total production variables
	query = "SELECT workers, workers_for_maintenance, int4(workers/GREATEST(1.0, workers_for_maintenance)*100), int4(previous_buildings_dilapidation / 100.0)," &_
			" int4(production_percent*100)," &_
			" pct_ore, pct_hydrocarbon" &_
			" FROM vw_planets WHERE id=" & CurrentPlanet
	set oRs = oConn.Execute(query)

	content.AssignValue "workers", oRs(0)
	content.AssignValue "workers_required", oRs(1)
	content.AssignValue "production", oRs(2)

	if oRs(3) <= 1 then
		content.Parse "overview.condition_excellent"
	elseif oRs(3) < 20 then
		content.Parse "overview.condition_good"
	elseif oRs(3) < 45 then
		content.Parse "overview.condition_fair"
	elseif oRs(3) < 80 then
		content.Parse "overview.condition_bad"
	else
		content.Parse "overview.condition_catastrophic"
	end if

	if oRs(0) >= oRs(1) then
		content.Parse "overview.repairing"
	else
		content.Parse "overview.decaying"
	end if

	content.AssignValue "final_production", oRs(4)

	if RecomputeIfNeeded and oRs(4) > oRs(2) then
		oConn.Execute "SELECT sp_update_planet(" & CurrentPlanet & ")", , adExecuteNoRecords
		displayPage false
		Response.End
		exit sub
	end if

	content.AssignValue "a_ore", oRs(5)
	content.AssignValue "a_hydrocarbon", oRs(6)

	' List buildings that produce a resource : ore, hydrocarbon or energy
	query = "SELECT id, production_ore*working_quantity, production_hydrocarbon*working_quantity, energy_production*working_quantity, working_quantity"& _
			" FROM vw_buildings" &_
			" WHERE planetid="&CurrentPlanet&" AND (production_ore > 0 OR production_hydrocarbon > 0 OR energy_production > 0) AND working_quantity > 0;"
	set oRs = oConn.Execute(query)

	dim totalOre, totalHydrocarbon, totalEnergy, buildingCount

	totalOre = 0
	totalHydrocarbon = 0
	totalEnergy = 0
	buildingCount = 0


	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "name", getBuildingLabel(oRs(0))
		content.AssignValue "description", getBuildingDescription(oRs(0))
		content.AssignValue "production_ore", oRs(1)
		content.AssignValue "production_hydrocarbon", oRs(2)
		content.AssignValue "production_energy", oRs(3)
		content.AssignValue "quantity", oRs(4)

		totalOre = totalOre + oRs(1)
		totalHydrocarbon = totalHydrocarbon + oRs(2)
		totalEnergy = totalEnergy + oRs(3)

		buildingCount = buildingCount + 1
		
		content.Parse "overview.building"
		oRs.MoveNext
	wend 


	' Retrieve commander assigned to the planet if any
	query = "SELECT commanders.id, commanders.name," & _
			"commanders.mod_production_ore-1, commanders.mod_production_hydrocarbon-1, commanders.mod_production_energy-1" & _
			" FROM commanders INNER JOIN nav_planet ON (commanders.id = nav_planet.commanderid)" & _
			" WHERE nav_planet.id=" & CurrentPlanet

	set oRs = oConn.Execute(query)

	DisplayBonus oRs, 0


	' List production bonus given by buildings
	query = "SELECT buildingid, '', mod_production_ore*quantity, mod_production_hydrocarbon*quantity, mod_production_energy*quantity" & _
			" FROM planet_buildings" &_
			"	INNER JOIN db_buildings ON (db_buildings.id = planet_buildings.buildingid)" &_
			" WHERE planetid="&CurrentPlanet&" AND (mod_production_ore <> 0 OR mod_production_hydrocarbon <> 0 OR mod_production_energy <> 0)"

	set oRs = oConn.Execute(query)

	DisplayBonus oRs, 1


	' List researches that gives production bonus
	query = "SELECT researchid, '', level*mod_production_ore, level*mod_production_hydrocarbon, level*mod_production_energy, level" & _
			" FROM researches INNER JOIN db_research ON researches.researchid=db_research.id" & _
			" WHERE userid=" & UserID &" AND ((mod_production_ore > 0) OR (mod_production_hydrocarbon > 0) OR (mod_production_energy > 0)) AND (level > 0);"

	set oRs = oConn.Execute(query)

	DisplayBonus oRs, 2


	' Display buildings sub total if there are bonus and more than 1 building that produces resources
	if (BonusCount > 0) and (buildingCount > 1) then
			content.AssignValue "production_ore", totalOre
			content.AssignValue "production_hydrocarbon", totalHydrocarbon
			content.AssignValue "production_energy", totalEnergy
			content.Parse "overview.subtotal"
	end if

	' Retrieve energy received from antennas
	dim EnergyReceived
	query = "SELECT int4(COALESCE(sum(effective_energy), 0)) FROM planet_energy_transfer WHERE target_planetid=" & CurrentPlanet
	set oRs = oConn.Execute(query)
	EnergyReceived = oRs(0)


	' Assign total production variables
	query = "SELECT ore_production, hydrocarbon_production, energy_production-"&EnergyReceived&" FROM nav_planet WHERE id=" & CurrentPlanet
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		' display bonus sub-total
		if BonusCount > 0 then

			if RecomputeIfNeeded and (oRs(0)-totalOre < 0 or oRs(1)-totalHydrocarbon < 0 or oRs(2)-totalEnergy < 0) then
				oConn.Execute "SELECT sp_update_planet(" & CurrentPlanet & ")", , adExecuteNoRecords
				displayPage false
				Response.End
				exit sub
			end if

			content.AssignValue "production_ore", oRs(0)-totalOre
			content.AssignValue "production_hydrocarbon", oRs(1)-totalHydrocarbon
			content.AssignValue "production_energy", oRs(2)-totalEnergy
			content.Parse "overview.bonus"
		end if

		content.AssignValue "production_ore", oRs(0)
		content.AssignValue "production_hydrocarbon", oRs(1)
		content.AssignValue "production_energy", oRs(2)
	end if

	content.Parse "overview"
end sub

sub displayManage()
	dim oRs, query, i, quantity

	if action = "submit" then
		query = "SELECT buildingid, quantity - CASE WHEN destroy_datetime IS NULL THEN 0 ELSE 1 END, disabled" &_
				" FROM planet_buildings" &_
				"	INNER JOIN db_buildings ON (planet_buildings.buildingid=db_buildings.id)" &_
				" WHERE can_be_disabled AND planetid=" & CurrentPlanet
		set oRs = oConn.Execute(query)
		while not oRs.EOF
			on error resume next

			quantity = oRs(1) - ToInt(Request.Form("enabled" & oRs(0)), 0)

			query = "UPDATE planet_buildings SET" &_
					" disabled=LEAST(quantity - CASE WHEN destroy_datetime IS NULL THEN 0 ELSE 1 END, " & quantity & ")" &_
					"WHERE planetid=" & CurrentPlanet & " AND buildingid =" & oRs(0)
			oConn.Execute query, , adExecuteNoRecords

			on error goto 0

			oRs.MoveNext
		wend

		Response.Redirect "?cat=" & cat
		Response.End
	end if


	query = "SELECT buildingid, quantity - CASE WHEN destroy_datetime IS NULL THEN 0 ELSE 1 END, disabled, energy_consumption, int4(workers*maintenance_factor/100.0), upkeep" &_
			" FROM planet_buildings" &_
			"	INNER JOIN db_buildings ON (planet_buildings.buildingid=db_buildings.id)" &_
			" WHERE can_be_disabled AND planetid=" & CurrentPlanet &_
			" ORDER BY buildingid"
	set oRs = oConn.Execute(query)

	dim enabled
	while not oRs.EOF
		if oRs(1) > 0 then
			enabled = oRs(1) - oRs(2)
			quantity = oRs(1) - oRs(2)*0.95

			content.AssignValue "id", oRs(0)
			content.AssignValue "building", getBuildingLabel(oRs(0))
			content.AssignValue "quantity", oRs(1)
			content.AssignValue "energy", oRs(3)
			content.AssignValue "maintenance", oRs(4)
			content.AssignValue "upkeep", oRs(5)
			content.AssignValue "energy_total", round(quantity * oRs(3))
			content.AssignValue "maintenance_total", round(quantity * oRs(4))
			content.AssignValue "upkeep_total", round(quantity * oRs(5))

			if oRs(2) > 0 then content.Parse "manage.building.not_all_enabled"

			for i = 0 to oRs(1)
				content.AssignValue "i", i
				if i = enabled then content.Parse "manage.building.enable.selected"
				content.Parse "manage.building.enable"
			next

			content.Parse "manage.building"
		end if

		oRs.MoveNext
	wend

	content.Parse "manage"
end sub

sub displayReceiveSendEnergy()
	dim oRs, query
	dim max_receive, max_send, I, update_planet

	query = "SELECT energy_receive_antennas, energy_send_antennas FROM nav_planet WHERE id=" & CurrentPlanet
	set oRs = oConn.Execute(query)

	max_receive = oRs(0)
	max_send = oRs(1)

	update_planet = false

	if action = "cancel" then
		dim energy_from, energy_to
		energy_from = ToInt(Request.QueryString("from"), 0)
		energy_to = ToInt(Request.QueryString("to"), 0)

		if energy_from <> 0 then
			query = "DELETE FROM planet_energy_transfer WHERE planetid=" & energy_from & " AND target_planetid=" & CurrentPlanet
		else
			query = "DELETE FROM planet_energy_transfer WHERE planetid=" & CurrentPlanet & " AND target_planetid=" & energy_to
		end if

		oConn.Execute query, , adExecuteNoRecords

		update_planet = true

		Response.Redirect "?cat=" & cat
		Response.End
	elseif action = "submit" then
		dim g,s,p,energy

		query = "SELECT target_planetid, energy, enabled" &_
				" FROM planet_energy_transfer" &_
				" WHERE planetid=" & CurrentPlanet
		set oRs = oConn.Execute(query)
		while not oRs.EOF
			query = ""

			I = ToInt(Request.Form("energy_" & oRs(0)), 0)
			if I <> oRs(1) then
				query = query & "energy = " & I
			end if


			I = Request.Form("enabled_" & oRs(0))
			if I = "1" then
				I = true
			else
				I = false
			end if

			if I <> oRs(2) then
				if query <> "" then query = query & ","
				query = query & "enabled=" & dosql(I)
			end if

			if query <> "" then
				query = "UPDATE planet_energy_transfer SET " & query & " WHERE planetid=" & CurrentPlanet & " AND target_planetid=" & oRs(0)
				oConn.Execute query, , adExecuteNoRecords

				update_planet = true
			end if

			oRs.MoveNext
		wend


		for I = 1 to Request.Form("to_g").count
			g = ToInt(Request.Form("to_g").item(I), 0)
			s = ToInt(Request.Form("to_s").item(I), 0)
			p = ToInt(Request.Form("to_p").item(I), 0)
			energy = ToInt(Request.Form("energy").item(I), 0)

			if g <> 0 and s <> 0 and p <> 0 and energy > 0 then
				on error resume next
				query = "INSERT INTO planet_energy_transfer(planetid, target_planetid, energy) VALUES(" & CurrentPlanet & ", sp_planet(" & g & "," & s & "," & p & ")," & energy & ")"
				oConn.Execute query, , adExecuteNoRecords

				on error goto 0
				update_planet = true
			end if
		next

		if update_planet then
			query = "SELECT sp_update_planet(" & CurrentPlanet & ")"
			oConn.Execute query, , adExecuteNoRecords
		end if

		Response.Redirect "?cat=" & cat
		Response.End
	end if


	query = "SELECT t.planetid, sp_get_planet_name(" & UserId & ", n1.id), sp_relation(n1.ownerid," & UserId & "), n1.galaxy, n1.sector, n1.planet, " &_
			"		t.target_planetid, sp_get_planet_name(" & UserId & ", n2.id), sp_relation(n2.ownerid," & UserId & "), n2.galaxy, n2.sector, n2.planet, " &_
			"		t.energy, t.effective_energy, enabled" &_
			" FROM planet_energy_transfer t" &_
			"	INNER JOIN nav_planet n1 ON (t.planetid=n1.id)" &_
			"	INNER JOIN nav_planet n2 ON (t.target_planetid=n2.id)" &_
			" WHERE planetid=" & CurrentPlanet & " OR target_planetid=" & CurrentPlanet &_
			" ORDER BY not enabled, planetid, target_planetid"
	set oRs = oConn.Execute(query)

	dim receiving, sending, sending_enabled

	receiving = 0
	sending = 0
	sending_enabled = 0

	while not oRs.EOF
		content.AssignValue "energy", oRs(12)
		content.AssignValue "effective_energy", oRs(13)
		content.AssignValue "loss", getpercent(oRs(12)-oRs(13), oRs(12), 1)

		if oRs(0) = CurrentPlanet then
			sending = sending + 1
			if oRs(14) then sending_enabled = sending_enabled + 1
			content.AssignValue "planetid", oRs(6)
			content.AssignValue "name", oRs(7)
			content.AssignValue "rel", oRs(8)
			content.AssignValue "g", oRs(9)
			content.AssignValue "s", oRs(10)
			content.AssignValue "p", oRs(11)
			if oRs(14) then content.Parse "sendreceive.sent.enabled"
			content.Parse "sendreceive.sent"
		elseif oRs(14) then ' if receiving and enabled, display it
			receiving = receiving + 1
			content.AssignValue "planetid", oRs(0)
			content.AssignValue "name", oRs(1)
			content.AssignValue "rel", oRs(2)
			content.AssignValue "g", oRs(3)
			content.AssignValue "s", oRs(4)
			content.AssignValue "p", oRs(5)
			content.Parse "sendreceive.received"
		end if

		oRs.MoveNext
	wend

	content.AssignValue "planetid", ""
	content.AssignValue "name", ""
	content.AssignValue "rel", ""
	content.AssignValue "g", ""
	content.AssignValue "s", ""
	content.AssignValue "p", ""
	content.AssignValue "energy", 0
	content.AssignValue "effective_energy", 0
	content.AssignValue "loss", 0


	content.AssignValue "antennas_receive_used", receiving
	content.AssignValue "antennas_receive_total", max_receive

	content.AssignValue "antennas_send_used", sending_enabled
	content.AssignValue "antennas_send_total", max_send

	if max_send = 0 then content.Parse "sendreceive.send_no_antenna"
	if max_receive = 0 then content.Parse "sendreceive.receive_no_antenna"

	if receiving > 0 then
		content.Parse "sendreceive.cant_send_when_receiving"
		max_send = 0
	end if

	if sending_enabled > 0 then
		content.Parse "sendreceive.cant_receive_when_sending"
		max_receive = 0
	elseif receiving = 0 and max_receive > 0 then
		content.Parse "sendreceive.receiving_none"
	end if

	for I = receiving to max_receive-1
		content.Parse "sendreceive.receive"
	next

	for I = sending to max_send-1
		content.Parse "sendreceive.send"
	next

	if max_send > 0 then content.Parse "sendreceive.submit"

	content.Parse "sendreceive"
end sub



sub displayPage(RecomputeIfNeeded)
	action = Request.QueryString("a")
	cat = ToInt(Request.QueryString("cat"), 1)
	if cat < 1 or cat > 3 then cat = 1

	set content = GetTemplate("production")
	content.AssignValue "cat", cat

	select case cat
		case 1
			displayOverview RecomputeIfNeeded
			content.Parse "nav.cat1.selected"
		case 2
			displayManage
			content.Parse "nav.cat2.selected"
		case 3
			displayReceiveSendEnergy
			content.Parse "nav.cat3.selected"
	end select

	content.Parse "nav.cat1"
	content.Parse "nav.cat2"
	content.Parse "nav.cat3"
	content.Parse "nav"

	content.Parse ""

	url_extra_params = "cat=" & cat

	Display content
end sub

displayPage true

%>