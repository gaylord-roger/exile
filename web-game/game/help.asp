<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "help"

retrieveShipsReqCache

dim cat
cat = Request.QueryString("cat")

if cat = "" or cat <> "buildings" and cat <> "research" and cat <> "ships" and cat <> "tags" then
	cat = "general"
end if

function display_help(cat)

	dim content
	set content = GetTemplate("help")
	dim oRs, query, category, lastCategory

	if cat = "buildings" then' display help on buildings
			query = "SELECT id, category," &_
					"cost_ore, cost_hydrocarbon, workers, floor, space, production_ore, production_hydrocarbon, energy_production, workers*maintenance_factor/100.0, upkeep, energy_consumption," &_
					"storage_ore, storage_hydrocarbon, storage_energy" &_
					" FROM sp_list_available_buildings(" & userid & ") WHERE not is_planet_element"

			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				category = oRs(1)
				lastCategory = category
			end if

			while not oRs.EOF

				category = oRs(1)
	
				if category <> lastCategory then
					content.Parse cat & ".category.category" & lastcategory
					content.Parse cat & ".category"
					lastCategory = category
				end if
		
				content.AssignValue "id", oRs(0)
				content.AssignValue "category", oRs(1)
				content.AssignValue "name", getBuildingLabel(oRs(0))
				content.AssignValue "description", getBuildingDescription(oRs(0))

				content.AssignValue "ore", oRs(2)
				content.AssignValue "hydrocarbon", oRs(3)
				content.AssignValue "workers", oRs(4)

				content.AssignValue "floor", oRs(5)
				content.AssignValue "space", oRs(6)

				' production
				content.AssignValue "ore_production", oRs(7)
				if oRs(7) > 0 then content.Parse cat & ".category.building.produce_ore"

				content.AssignValue "hydrocarbon_production", oRs(8)
				if oRs(8) > 0 then content.Parse cat & ".category.building.produce_hydrocarbon"

				content.AssignValue "energy_production", oRs(9)
				if oRs(9) > 0 then content.Parse cat & ".category.building.produce_energy"

				' storage
				content.AssignValue "ore_storage", oRs(13)
				if oRs(13) > 0 then content.Parse cat & ".category.building.storage_ore"

				content.AssignValue "hydrocarbon_storage", oRs(14)
				if oRs(14) > 0 then content.Parse cat & ".category.building.storage_hydrocarbon"

				content.AssignValue "energy_storage", oRs(15)
				if oRs(15) > 0 then content.Parse cat & ".category.building.storage_energy"


				content.AssignValue "upkeep_workers", oRs(10)
				content.AssignValue "upkeep_credits", 0'oRs(11)
				content.AssignValue "upkeep_energy", oRs(12)

				content.Parse cat & ".category.building"

				oRs.movenext
			wend

			content.Parse cat & ".category.category" & category
			content.Parse cat & ".category"

	elseif cat = "research" then' display help on researches
			query = "SELECT researchid, category, total_cost, level, levels" &_ 
					" FROM sp_list_researches(" & userid & ") WHERE level > 0 OR (researchable AND planet_elements_requirements_met)" &_
					" ORDER BY category, researchid"

			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				category = oRs(1)
				lastCategory = category
			end if

			while not oRs.EOF
				category = oRs(1)

				if category <> lastCategory then
					content.Parse cat & ".category.category" & lastcategory
					content.Parse cat & ".category"
					lastCategory = category
				end if

				content.AssignValue "id", oRs(0)
				content.AssignValue "name", getResearchLabel(oRs(0))
				content.AssignValue "description", getResearchDescription(oRs(0))

				if oRs(3) < oRs(4) then
					content.AssignValue "cost_credits", oRs(2)
				else
					content.AssignValue "cost_credits", ""
				end if

				content.Parse cat & ".category.research_subject"
	
				oRs.movenext
			wend
			
			content.Parse cat&".category.category" & category
			content.Parse cat&".category"

	elseif cat = "ships" then' display help on ships
			query = "SELECT id, category, cost_ore, cost_hydrocarbon, crew," &_
					" signature, capacity, handling, speed, weapon_turrets, weapon_dmg_em + weapon_dmg_explosive + weapon_dmg_kinetic + weapon_dmg_thermal AS weapon_power, " &_
					" weapon_tracking_speed, hull, shield, recycler_output, long_distance_capacity, droppods, cost_energy, upkeep, required_vortex_strength, leadership" &_
					" FROM sp_list_available_ships(" & userid & ") WHERE new_shipid IS NULL"
			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				category = oRs(1)
				lastCategory = category
			end if

			while not oRs.eof 

				category = oRs(1)

				if category <> lastCategory then
					content.Parse cat&".category.category" & lastcategory
					content.Parse cat&".category"
					lastCategory = category
				end if

				dim ShipId
				ShipId = oRs(0)

				content.AssignValue "id", ShipId
				content.AssignValue "category", oRs(1)
				content.AssignValue "name", getShipLabel(oRs(0))
				content.AssignValue "description", getShipDescription(oRs(0))
			
				content.AssignValue "ore", oRs(2)
				content.AssignValue "hydrocarbon", oRs(3)
				content.AssignValue "crew", oRs(4)
				content.AssignValue "energy", oRs("cost_energy")

				content.AssignValue "ship_signature", oRs("signature")
				content.AssignValue "ship_cargo", oRs("capacity")
				content.AssignValue "ship_handling", oRs("handling")
				content.AssignValue "ship_speed", oRs("speed")

				content.AssignValue "ship_upkeep", oRs("upkeep")

				if oRs("weapon_power") > 0 then
					content.AssignValue "ship_turrets", oRs("weapon_turrets")
					content.AssignValue "ship_power", oRs("weapon_power")
					content.AssignValue "ship_tracking_speed", oRs("weapon_tracking_speed")
					content.Parse cat&".category.ship.attack"
				end if

				content.AssignValue "ship_hull", oRs("hull")

				if oRs("shield") > 0 then
					content.AssignValue "ship_shield", oRs("shield")
					content.Parse cat&".category.ship.shield"
				end if

				if oRs("recycler_output") > 0 then
					content.AssignValue "ship_recycler_output", oRs("recycler_output")
					content.Parse cat&".category.ship.recycler_output"
				end if

				if oRs("long_distance_capacity") > 0 then
					content.AssignValue "ship_long_distance_capacity", oRs("long_distance_capacity")
					content.Parse cat&".category.ship.long_distance_capacity"
				end if

				if oRs("droppods") > 0 then
					content.AssignValue "ship_droppods", oRs("droppods")
					content.Parse cat&".category.ship.droppods"
				end if

				content.AssignValue "ship_required_vortex_strength", oRs("required_vortex_strength")
				content.AssignValue "ship_leadership", oRs("leadership")

				dim i
				for i = 0 to dbShipsReqCount
					if dbShipsReqArray(0, i) = ShipId then
						content.AssignValue "building", getBuildingLabel(dbShipsReqArray(1, i))
						content.Parse cat&".category.ship.buildingsrequired"
					end if
				next

				content.Parse cat&".category.ship"
			
				oRs.movenext
			wend
			
			content.Parse cat&".category.category" & category
			content.Parse cat&".category"
	end if

	content.Parse cat
	content.Parse "tabnav."&cat
	content.Parse "tabnav"
	content.Parse ""
	display(content)

end function

display_help cat

%>