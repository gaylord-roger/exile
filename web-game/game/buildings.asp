<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "buildings"

showHeader = true

retrieveBuildingsReqCache

dim oRs, query


dim buildingsArray, buildingsCount
dim pOre, pHydrocarbon, pWorkers, pVacantWorkers, pEnergy, pFloor, pSpace, pOreCapacity, pHydrocarbonCapacity, pBonusEnergy
dim pScientists, pScientistsCapacity, pSoldiers, pSoldiersCapacity
dim OreBonus, HydroBonus, EnergyBonus

sub RetrievePlanetInfo()
	' Retrieve recordset of current planet
	query = "SELECT ore, hydrocarbon, workers-workers_busy, workers_capacity - workers, energy, " & _
			" floor - floor_occupied, space - space_occupied," & _
			" mod_production_ore, mod_production_hydrocarbon, mod_production_energy," & _
			" ore_capacity, hydrocarbon_capacity," &_
			" scientists, scientists_capacity, soldiers, soldiers_capacity, energy_production-energy_consumption" &_
			" FROM vw_planets" &_
			" WHERE id="&CurrentPlanet
	set oRs = oConn.Execute(query)

	if oRs.EOF then	Response.End

	OreBonus = oRs(7)
	HydroBonus = oRs(8)
	EnergyBonus = oRs(9)
	pOre = oRs(0)
	pHydrocarbon = oRs(1)
	pWorkers = oRs(2)
	pVacantWorkers = oRs(3)
	pEnergy = oRs(4)
	pFloor = oRs(5)
	pSpace = oRs(6)
	pBonusEnergy = oRs(9)
	pOreCapacity = oRs(10)
	pHydrocarbonCapacity = oRs(11)

	pScientists = oRs(12)
	pScientistsCapacity = oRs(13)
	pSoldiers = oRs(14)
	pSoldiersCapacity = oRs(15)


	' Retrieve buildings of current planet
	dim oPlanetBuildings
	query = "SELECT planetid, buildingid, quantity FROM planet_buildings WHERE quantity > 0 AND planetid=" & CurrentPlanet
	set oPlanetBuildings = oConn.Execute(query)

	if oPlanetBuildings.EOF then
		buildingsCount = -1
	else
		buildingsArray = oPlanetBuildings.GetRows()
		buildingsCount = UBound(buildingsArray, 2)
	end if
end sub

' check if we already have this building on the planet and return the number of this building on this planet
function BuildingQuantity(BuildingId)
	dim i

	BuildingQuantity = 0

	for i = 0 to buildingsCount
		if BuildingId = buildingsArray(1, i) then
			BuildingQuantity = int(buildingsArray(2, i))
			exit for
		end if
	next
end function

' check if some buildings on the planet requires the presence of the given building
function HasBuildingThatDependsOn(BuildingId)
	HasBuildingThatDependsOn = false

	dim i, requiredBuildId

	for i = 0 to dbBuildingsReqCount
		if BuildingId = dbBuildingsReqArray(1, i) then
			requiredBuildId = dbBuildingsReqArray(0, i)

			if BuildingQuantity(requiredBuildId) > 0 then
				HasBuildingThatDependsOn = true
				exit function
			end if
		end if
	next

	' if the building produces energy, check that there will be enough energy after
	' the building destruction
'	for i = 0 to dbbuildingsCount
'		if BuildingId = dbbuildingsArray(0, i) then
'			if (dbbuildingsArray(2, i) > 0) and (pEnergy < dbbuildingsArray(2, i)*pBonusEnergy/100-dbbuildingsArray(10, i)) then
'				HasBuildingThatDependsOn = true
'				exit function
'			end if
'		end if
'	next
end function

function HasEnoughWorkersToDestroy(BuildingId)
	HasEnoughWorkersToDestroy = true
	
	dim i

	for i = 0 to dbbuildingsCount
		if BuildingId = dbbuildingsArray(0, i) then
			if dbbuildingsArray(5, i)/2 > pWorkers then
				HasEnoughWorkersToDestroy = false
				exit function
			end if
		end if
	next
end function

function HasEnoughStorageAfterDestruction(BuildingId)
	HasEnoughStorageAfterDestruction = false

	dim i

	' 1/ if we want to destroy a building that increase max population then check that 
	' the population is less than the limit after the building destruction
	' 2/ if the building produces energy, check that there will be enough energy after
	' the building destruction
	' 3/ if the building increases the capacity of ore or hydrocarbon, check that there is not
	' too much ore/hydrocarbon
	for i = 0 to dbbuildingsCount
		if BuildingId = dbbuildingsArray(0, i) then
			if (dbbuildingsArray(1, i) > 0) and (pVacantWorkers < dbbuildingsArray(1, i)) then
				HasEnoughStorageAfterDestruction = true
				exit function
			end if

			' check if scientists/soldiers are lost
			if pScientists > pScientistsCapacity-dbbuildingsArray(6, i) then
				HasEnoughStorageAfterDestruction = true
				exit function
			end if

			if pSoldiers > pSoldiersCapacity-dbbuildingsArray(7, i) then
				HasEnoughStorageAfterDestruction = true
				exit function
			end if

			' check if a storage building is destroyed
			if pOre > pOreCapacity-dbbuildingsArray(3, i) then
				HasEnoughStorageAfterDestruction = true
				exit function
			end if

			if pHydrocarbon > pHydrocarbonCapacity-dbbuildingsArray(4, i) then
				HasEnoughStorageAfterDestruction = true
				exit function
			end if
		end if

	next
end function


function getBuildingMaintenanceWorkers(buildingid)
	getBuildingMaintenanceWorkers = 0

	dim i
	for i = 0 to dbbuildingsCount
		if BuildingId = dbbuildingsArray(0, i) then
			getBuildingMaintenanceWorkers = dbbuildingsArray(11, i)
			exit function
		end if
	next
end function


' List all the available buildings
sub ListBuildings()
	dim oRs
	dim underConstructionCount, index

	' count number of buildings under construction
	set oRs = oConn.Execute("SELECT int4(count(*)) FROM planet_buildings_pending WHERE planetid=" & CurrentPlanet & " LIMIT 1")
	underConstructionCount = oRs(0)

	' list buildings that can be built on the planet
	query = "SELECT id, category, cost_prestige, cost_ore, cost_hydrocarbon, cost_energy, cost_credits, workers, floor, space," & _
			"construction_maximum, quantity, build_status, construction_time, destroyable, '', production_ore, production_hydrocarbon, energy_production, buildings_requirements_met, destruction_time," & _
			"upkeep, energy_consumption, buildable" &_
			" FROM vw_buildings" &_
			" WHERE planetid=" & CurrentPlanet & " AND ((buildable AND research_requirements_met) or quantity > 0)"

	set oRs = oConn.Execute(query)

	dim content
	set content = GetTemplate("buildings")

	content.AssignValue "planetid", CurrentPlanet

	dim category, lastCategory

	if not oRs.EOF then
		category = oRs(1)
		lastCategory = category
	end if

	index = 1
	while not oRs.EOF
		' if can be built or has some already built, display it
		if oRs("buildings_requirements_met") or oRs("quantity") > 0 then

		dim BuildingId, quantity, maximum, status
		BuildingId = oRs(0)

		category = oRs(1)

		if category <> lastCategory then
			content.Parse "category.category" & lastcategory
			content.Parse "category"
			lastCategory = category
		end if

		content.AssignValue "id", BuildingId
		content.AssignValue "name", getBuildingLabel(oRs(0))

		content.AssignValue "ore", oRs(3)
		content.AssignValue "hydrocarbon", oRs(4)
		content.AssignValue "energy", oRs(5)
		content.AssignValue "credits", oRs(6)
		content.AssignValue "workers", oRs(7)
		content.AssignValue "prestige", oRs(2)

		content.AssignValue "floor", oRs(8)
		content.AssignValue "space", oRs(9)
		content.AssignValue "time", oRs(13)
		content.AssignValue "description", getBuildingDescription(oRs(0))

		dim OreProd, HydroProd, EnergyProd
		OreProd= oRs(16)
		HydroProd= oRs(17)
		EnergyProd= oRs(18)

		content.AssignValue "ore_prod", OreProd
		content.AssignValue "hydro_prod", HydroProd
		content.AssignValue "energy_prod", EnergyProd
		content.AssignValue "ore_modifier", Clng(OreProd*(OreBonus-100)/100)
		content.AssignValue "hydro_modifier", Clng(HydroProd*(HydroBonus-100)/100)
		content.AssignValue "energy_modifier", Clng(EnergyProd*(EnergyBonus-100)/100)

		if OreProd <> 0 or HydroProd <> 0 or EnergyProd <> 0 then
				if OreBonus < 100 and OreProd <> 0 then
					content.Parse "category.building.tipprod.ore.malus"
				else
					content.Parse "category.building.tipprod.ore.bonus"
				end if
				content.Parse "category.building.tipprod.ore"

				if HydroBonus < 100 and HydroProd <> 0 then
					content.Parse "category.building.tipprod.hydro.malus"
				else
					content.Parse "category.building.tipprod.hydro.bonus"
				end if
				content.Parse "category.building.tipprod.hydro"

				if EnergyBonus < 100 and EnergyProd <> 0 then
					content.Parse "category.building.tipprod.energy.malus"
				else
					content.Parse "category.building.tipprod.energy.bonus"
				end if
				content.Parse "category.building.tipprod.energy"
				content.Parse "category.building.tipprod"
		end if
		
		maximum = oRs(10)
		quantity = oRs(11)

		content.AssignValue "quantity", quantity

		status = oRs(12)

		content.AssignValue "remainingtime", ""
		content.AssignValue "nextdestroytime", ""

		if not isnull(status) then
			if status < 0 then status = 0

			content.AssignValue "remainingtime", status
			content.Parse "category.building.underconstruction"
			content.Parse "category.building.isbuilding"

		elseif not oRs("buildable") then
			content.Parse "category.building.limitreached"
		elseif (quantity > 0) and (quantity >= maximum) then
			if quantity = 1 then
				content.Parse "category.building.built"
			else
				content.Parse "category.building.limitreached"
			end if
		elseif not oRs("buildings_requirements_met") then

			content.Parse "category.building.buildings_required"

		else
			dim notenoughspace, notenoughresources
			notenoughspace = false
			notenoughresources = false

			if oRs(8) > pFloor then
				content.Parse "category.building.not_enough_floor"
				notenoughspace = true
			end if

			if oRs(9) > pSpace then
				content.Parse "category.building.not_enough_space"
				notenoughspace = true
			end if

			if oRs(2) > 0 and oRs(2) > oPlayerInfo("prestige_points") then
				content.Parse "category.building.not_enough_prestige"
				notenoughresources = true
			end if

			if oRs(3) > 0 and oRs(3) > pOre then
				content.Parse "category.building.not_enough_ore"
				notenoughresources = true
			end if

			if oRs(4) > 0 and oRs(4) > pHydrocarbon then
				content.Parse "category.building.not_enough_hydrocarbon"
				notenoughresources = true
			end if

			if oRs(5) > 0 and oRs(5) > pEnergy then
				content.Parse "category.building.not_enough_energy"
				notenoughresources = true
			end if

'			if oRs(6) > oPlayerInfo("credits") then
'				content.Parse "category.building.not_enough_credits"
'				notenoughresources = true
'			end if

			if oRs(7) > 0 and oRs(7) > pWorkers then
				content.Parse "category.building.not_enough_workers"
				notenoughresources = true
			end if

			if notenoughspace then content.Parse "category.building.not_enough.space"
			if notenoughresources then content.Parse "category.building.not_enough.resources"

			if notenoughspace or notenoughresources then
				content.Parse "category.building.not_enough"
			else
				content.Parse "category.building.build"
			end if
		end if

		if (quantity > 0) and oRs("destroyable") then

			if oRs("destruction_time") > 0 then
				content.AssignValue "nextdestroytime", oRs("destruction_time")
				content.Parse "category.building.next_destruction_in"
				content.Parse "category.building.isdestroying"
			elseif not HasEnoughWorkersToDestroy(BuildingId) then
				content.Parse "category.building.workers_required"
'			elseif pNextDestroyTime > 0 then
'				content.Parse "category.building.destroying"
'			elseif underConstructionCount > 0 then
'				content.Parse "category.building.alreadybuilding"
			elseif HasBuildingThatDependsOn(BuildingId) then
				content.Parse "category.building.required"
			elseif HasEnoughStorageAfterDestruction(BuildingId) then
				content.Parse "category.building.capacity"
			else
				content.Parse "category.building.destroy"
			end if
		else
			content.Parse "category.building.empty"
		end if

		content.AssignValue "index", index
		index = index + 1

		content.AssignValue "workers_for_maintenance", getBuildingMaintenanceWorkers(BuildingId)
		content.AssignValue "upkeep", oRs("upkeep")
		content.AssignValue "upkeep_energy", oRs("energy_consumption")

		content.Parse "category.building"

		end if

		oRs.MoveNext
	wend

	content.Parse "category.category" & category
	content.Parse "category"

	if session(sprivilege) > 100 then content.parse "dev"
	if UserId=1009 then content.parse "dev"

	content.Parse ""

	Display(content)
end sub

sub StartBuilding(BuildingId)
	dim oRs
	set oRs = connExecuteRetry("SELECT sp_start_building(" & UserId & "," & CurrentPlanet & ", " & BuildingId & ", false)")
	
	if not oRs.EOF and oRs(0) > 0 then
		select case oRs(0)
			case 1
				log_notice "buildings.asp", "can't build buildingid" & BuildingId, 1
			case 2
				log_notice "buildings.asp", "not enough energy, resources, money or space/floor", 0
			case 3
				log_notice "buildings.asp", "building or research requirements not met", 1
			case 4
				log_notice "buildings.asp", "already building this type of building", 0
		end select
	end if
end sub

sub CancelBuilding(BuildingId)
	connExecuteRetryNoRecords "SELECT sp_cancel_building(" & UserId & "," & CurrentPlanet & ", " & BuildingId & ")"
end sub

sub DestroyBuilding(BuildingId)
	connExecuteRetryNoRecords "SELECT sp_destroy_building(" & UserId & "," & CurrentPlanet & "," & BuildingId & ")"
end sub


dim Action, BuildingId
Action = lcase(Request.QueryString("a"))
BuildingId = ToInt(Request.QueryString("b"), "")


if BuildingId <> "" then
	BuildingId = BuildingId

	select case Action
		case "build"
			StartBuilding(BuildingId)

		case "cancel"
			CancelBuilding(BuildingId)

		case "destroy"
			DestroyBuilding(BuildingId)
	end select
end if

dim y, scriptname
y = ToInt(Request.QueryString("y"),"")
scriptname = Request.ServerVariables("SCRIPT_NAME")

if y <> "" then
	Session("scrollExpire") = now + 5/(24*3600) ' allow 5 seconds
	Session("scrollPage") = scriptname
	Session("scrolly") = y

	RedirectTo scriptname & "?planet=" & CurrentPlanet
else

	' if scrolly is stored in the session and is still valid, set the scrolly of the displayed page
	if Session("scrolly") <> "" and Session("scrollExpire") > now and Session("scrollPage") = scriptname then
		scrollY = Session("scrolly")
		Session("scrolly") = ""
	end if


	RetrievePlanetInfo()

	ListBuildings()
end if

%>