<%
' this script is made to cache some data from the sql server that doesn't change often

const cachever = 2

dim dbBuildingsArray, dbBuildingsCount
dim dbBuildingsReqArray, dbBuildingsReqCount

dim dbShipsArray, dbShipsCount
dim dbShipsReqArray, dbShipsReqCount

dim dbResearchArray, dbResearchCount

dim PlanetListArray, PlanetListCount


sub retrieveBuildingsCache()

	if not isEmpty(dbbuildingsCount) then
		exit sub
	end if

	dim reload
	reload = Application("db_buildings.cache_version") <> cachever

	dim query, oRs
	if not reload and IsArray(Application("db_buildings.array")) then
		dbbuildingsArray = Application("db_buildings.array")
		dbbuildingsCount = Application("db_buildings.count")
	else
		' retrieve general buildings info
		query = "SELECT id, storage_workers, energy_production, storage_ore, storage_hydrocarbon, workers, storage_scientists, storage_soldiers, label, description, energy_consumption, workers*maintenance_factor/100, upkeep FROM db_buildings"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			dbbuildingsCount = -1
		else
			dbbuildingsArray = oRs.GetRows()
			dbbuildingsCount = UBound(dbbuildingsArray, 2)
		end if

		Application.Lock
		Application("db_buildings.array") = dbbuildingsArray
		Application("db_buildings.count") = dbbuildingsCount
		Application("db_buildings.cache_version") = cachever
		Application("db_buildings.retrieved") = Application("db_buildings.retrieved") + 1
		Application("db_buildings.last_retrieve") = now()
		Application.Unlock
	end if
end sub

sub retrieveBuildingsReqCache()

	if not isEmpty(dbBuildingsReqCount) then
		exit sub
	end if

	dim reload
	reload = Application("db_buildings_req.cache_version") <> cachever

	dim query, oRs
	if not reload and IsArray(Application("db_buildings_req.array")) then
		dbBuildingsReqArray = Application("db_buildings_req.array")
		dbBuildingsReqCount = Application("db_buildings_req.count")
	else
		' retrieve buildings requirements
		' planet elements can't restrict the destruction of a building that made their construction possible
		query = "SELECT buildingid, required_buildingid" &_
				" FROM db_buildings_req_building" &_
				"	INNER JOIN db_buildings ON (db_buildings.id=db_buildings_req_building.buildingid)" &_
				" WHERE db_buildings.destroyable"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			dbBuildingsReqCount = -1
		else
			dbBuildingsReqArray = oRs.GetRows()
			dbBuildingsReqCount = UBound(dbBuildingsReqArray, 2)
		end if

		Application.Lock
		Application("db_buildings_req.array") = dbBuildingsReqArray
		Application("db_buildings_req.count") = dbBuildingsReqCount
		Application("db_buildings_req.cache_version") = cachever
		Application("db_buildings_req.retrieved") = Application("db_buildings_req.retrieved") + 1
		Application("db_buildings_req.last_retrieve") = now()
		Application.Unlock
	end if
end sub


sub retrieveShipsCache()

	if not isEmpty(dbShipsCount) then
		exit sub
	end if

	dim reload
	reload = Application("db_ships.cache_version") <> cachever

	dim query, oRs
	if not reload and IsArray(Application("db_ships.array")) then
		dbShipsArray = Application("db_ships.array")
		dbShipsCount = Application("db_ships.count")
	else
		' retrieve general Ships info
		query = "SELECT id, label, description FROM db_Ships ORDER BY category, id"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			dbShipsCount = -1
		else
			dbShipsArray = oRs.GetRows()
			dbShipsCount = UBound(dbShipsArray, 2)
		end if

		Application.Lock
		Application("db_ships.array") = dbShipsArray
		Application("db_ships.count") = dbShipsCount
		Application("db_ships.cache_version") = cachever
		Application("db_ships.retrieved") = Application("db_ships.retrieved") + 1
		Application("db_ships.last_retrieve") = now()
		Application.Unlock
	end if
end sub

sub retrieveShipsReqCache()

	if not isEmpty(dbShipsReqCount) then
		exit sub
	end if

	dim reload
	reload = Application("db_ships_req.cache_version") <> cachever

	dim query, oRs
	if not reload and IsArray(Application("db_ships_req.array")) then
		dbShipsReqArray = Application("db_ships_req.array")
		dbShipsReqCount = Application("db_ships_req.count")
	else
		' retrieve buildings requirements for ships
		query = "SELECT shipid, required_buildingid FROM db_ships_req_building"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			dbShipsReqCount = -1
		else
			dbShipsReqArray = oRs.GetRows()
			dbShipsReqCount = UBound(dbShipsReqArray, 2)
		end if

		Application.Lock
		Application("db_ships_req.array") = dbShipsReqArray
		Application("db_ships_req.count") = dbShipsReqCount
		Application("db_ships_req.cache_version") = cachever
		Application("db_ships_req.retrieved") = Application("db_ships_req.retrieved") + 1
		Application("db_ships_req.last_retrieve") = now()
		Application.Unlock
	end if
end sub


sub retrieveResearchCache()
	if not isEmpty(dbResearchCount) then
		exit sub
	end if

	dim reload
	reload = Application("db_research.cache_version") <> cachever

	dim query, oRs
	if not reload and IsArray(Application("db_research.array")) then
		dbResearchArray = Application("db_research.array")
		dbResearchCount = Application("db_research.count")
	else
		' retrieve Research info
		query = "SELECT id, label, description FROM db_Research"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			dbResearchCount = -1
		else
			dbResearchArray = oRs.GetRows()
			dbResearchCount = UBound(dbResearchArray, 2)
		end if

		Application.Lock
		Application("db_research.array") = dbResearchArray
		Application("db_research.count") = dbResearchCount
		Application("db_research.cache_version") = cachever
		Application("db_research.retrieved") = Application("db_research.retrieved") + 1
		Application("db_research.last_retrieve") = now()
		Application.Unlock
	end if
end sub


sub checkPlanetListCache()
	dim query, oRs
	if IsArray(Session("planetlist.array")) then
		PlanetListArray = Session("planetlist.array")
		PlanetListCount = Session("planetlist.count")
	else
		' retrieve Research info
		query = "SELECT id, name, galaxy, sector, planet FROM nav_planet WHERE planet_floor > 0 AND planet_space > 0 AND ownerid=" & Session("user") & " ORDER BY id"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			PlanetListCount = -1
		else
			PlanetListArray = oRs.GetRows()
			PlanetListCount = UBound(PlanetListArray, 2)
		end if

		Session("planetlist.array") = PlanetListArray
		Session("planetlist.count") = PlanetListCount
	end if
end sub

'checkPlanetListCache


function getAllianceTag(allianceid)
	if IsNull(allianceid) then
		getAllianceTag = ""
		exit function
	end if

	getAllianceTag = Application("AllianceTag_" & allianceid)

	if IsEmpty(getAllianceTag) then
		dim oRs
		set oRs = oConn.Execute("SELECT tag FROM alliances WHERE id=" & allianceid)
		if not oRs.EOF then
			Application("AllianceTag_" & allianceid) = oRs(0)
			getAllianceTag = oRs(0)
		else
			Application("AllianceTag_" & allianceid) = ""
			getAllianceTag = ""
		end if
	end if
end function


function getBuildingLabel(buildingid)
	getBuildingLabel = ""

	retrieveBuildingsCache()

	dim i
	for i = 0 to dbbuildingsCount
		if BuildingId = dbbuildingsArray(0, i) then
			getBuildingLabel = dbbuildingsArray(8, i)
			exit function
		end if
	next
end function

function getBuildingDescription(buildingid)
	getBuildingDescription = ""

	retrieveBuildingsCache()

	dim i
	for i = 0 to dbbuildingsCount
		if BuildingId = dbbuildingsArray(0, i) then
			getBuildingDescription = dbbuildingsArray(9, i)
			exit function
		end if
	next
end function


function getShipLabel(ShipId)
	getShipLabel = ""

	retrieveShipsCache()

	dim i
	for i = 0 to dbShipsCount
		if ShipId = dbShipsArray(0, i) then
			getShipLabel = dbShipsArray(1, i)
			exit function
		end if
	next
end function

function getShipDescription(ShipId)
	getShipDescription = ""

	retrieveShipsCache()

	dim i
	for i = 0 to dbShipsCount
		if ShipId = dbShipsArray(0, i) then
			getShipDescription = dbShipsArray(2, i)
			exit function
		end if
	next
end function


function getResearchLabel(ResearchId)
	getResearchLabel = ""

	retrieveResearchCache()

	dim i
	for i = 0 to dbResearchCount
		if ResearchId = dbResearchArray(0, i) then
			getResearchLabel = dbResearchArray(1, i)
			exit function
		end if
	next
end function

function getResearchDescription(Researchid)
	getResearchDescription = ""

	retrieveResearchCache()

	dim i
	for i = 0 to dbResearchCount
		if ResearchId = dbResearchArray(0, i) then
			getResearchDescription = dbResearchArray(2, i)
			exit function
		end if
	next
end function
%>