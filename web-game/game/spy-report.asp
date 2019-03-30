<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "intelligence"


'if session("privilege") < 100 then
'	Response.Redirect "overview.asp"
'	Response.end
'end if

dim content, query, oRs, id, key
dim user, typ, level, spydate, credits, spotted, target

'
' display the spy report of a nation
'
sub DisplayNation()

	' load template
	set content = GetTemplate("spy-report")

	'
	' list spied planets
	'
	query = " SELECT spy_id, planet_id, planet_name, spy_planet.floor, spy_planet.space, ground, galaxy, sector, planet, spy_planet.pct_ore, spy_planet.pct_hydrocarbon " &_
			" FROM spy_planet " &_
			" LEFT JOIN nav_planet " &_
				" ON ( spy_planet.planet_id=nav_planet.id) " &_
			" WHERE spy_id=" & id

	set oRs = oConn.Execute(query)

	dim nbplanet
	nbplanet = 0

	while not oRs.EOF 
		if not isNull(oRs(2)) then
			content.AssignValue "planet", oRs(2)
		else
			content.AssignValue "planet", target
		end if
		content.AssignValue "g", oRs(6)
		content.AssignValue "s", oRs(7)
		content.AssignValue "p", oRs(8)

		content.AssignValue "floor", oRs(3)
		content.AssignValue "space", oRs(4)
		content.AssignValue "ground", oRs(5)

		content.AssignValue "pct_ore", oRs(9)
		content.AssignValue "pct_hydrocarbon", oRs(10)
		
		nbplanet = nbplanet + 1

		content.Parse "nation.planet"

		oRs.MoveNext
	wend
	
	'
	' list spied technologies
	'
	query = " SELECT category, db_research.id, research_level, levels " &_
			" FROM spy_research " &_
			" LEFT JOIN db_research " &_
				" ON ( spy_research.research_id=db_research.id) " &_
			" WHERE spy_id=" & id  &_
			" ORDER BY category, db_research.id "

	set oRs = oConn.Execute(query)

	dim nbresearch
	nbresearch = 0

	dim category, lastCategory, itemCount
	if not oRs.EOF then
		category = oRs(0)
		lastCategory = category
	end if

	while not oRs.EOF
		category = oRs(0)

		if category <> lastCategory then
			content.Parse "nation.researches.category.category" & lastcategory
			content.Parse "nation.researches.category"
			lastCategory = category
			itemCount = 0
		end if
		itemCount = itemCount + 1


		content.AssignValue "research", getResearchLabel(oRs(1))
		content.AssignValue "level", oRs(2)
		content.AssignValue "levels", oRs(3)
		
		nbresearch = nbresearch + 1

		content.Parse "nation.researches.category.research"

		oRs.MoveNext
	wend

	if itemCount > 0 then
		content.Parse "nation.researches.category.category" & category
		content.Parse "nation.researches.category"
	end if

	' display spied nation credits if possible
	if not isEmpty(credits) then
		content.AssignValue "credits", credits
		content.Parse "nation.credits"
	end if


	if nbresearch <> 0 then
		content.AssignValue "nb_research", nbresearch
		content.Parse "nation.researches"
	end if

	content.AssignValue "date", spydate
	content.AssignValue "nation", target
	content.AssignValue "nb_planet", nbplanet
	content.Parse "nation.spy_" & level

	' spotted is true if our spy has been spotted while he was doing his job
	if spotted then content.Parse "nation.spotted"

	content.Parse "nation"

	content.Parse ""

	display(content)
end sub


sub DisplayFleets()
	Set content = GetTemplate("spy-report")
	
	if level > 1 then
		query = " SELECT fleet_name, galaxy, sector, planet, signature, size, dest_galaxy, dest_sector, dest_planet " &_
				" FROM spy_fleet " &_
				" WHERE spy_id=" & id &_
				" ORDER BY galaxy, sector, planet, fleet_name"
	else
		query = " SELECT fleet_name, galaxy, sector, planet, signature " &_
				" FROM spy_fleet " &_
				" WHERE spy_id=" & id &_
				" ORDER BY galaxy, sector, planet, fleet_name"
	end if

	set oRs = oConn.Execute(query)

	dim nbfleet
	nbfleet = 0

	while not oRs.EOF
		content.AssignValue "fleet", oRs(0)
		content.AssignValue "location", oRs(1) & "." & oRs(2) & "." & oRs(3)
		content.AssignValue "signature", oRs(4)

		if level > 1 then
			if not isNull(oRs(5)) then
				content.AssignValue "size", oRs(5)
				content.Parse "fleets.fleet.size"
			else
				content.Parse "fleets.fleet.nosize"
			end if
			if not isNull(oRs(6)) then
				content.AssignValue "destination", oRs(6) & "." & oRs(7) & "." & oRs(8)
				content.Parse "fleets.fleet.dest"
			else
				content.Parse "fleets.fleet.nodest"
			end if
		else
			content.Parse "fleets.fleet.nosize"
			content.Parse "fleets.fleet.nodest"
		end if

		content.Parse "fleets.fleet"

		nbfleet = nbfleet + 1
		oRs.MoveNext
	wend

	content.AssignValue "date", spydate
	content.AssignValue "nation", target

	content.AssignValue "nb_fleet", nbfleet
	
	content.Parse "fleets.spy_" & level

	' spotted is true if our spy has been spotted while he was doing his job
	if spotted then content.Parse "fleets.spotted"

	content.Parse "fleets"

	content.Parse ""

	display(content)
end sub

sub DisplayPlanet()
	Set content = GetTemplate("spy-report")

	query = " SELECT spy_id,  planet_id,  planet_name,  s.owner_name,  s.floor,  s.space,  s.ground,  s.ore,  s.hydrocarbon,  s.ore_capacity, " &_
			" s.hydrocarbon_capacity,  s.ore_production,  s.hydrocarbon_production,  s.energy_consumption,  s.energy_production,  s.workers,  s.workers_capacity,  s.scientists, " &_
			" s.scientists_capacity,  s.soldiers,  s.soldiers_capacity,  s.radar_strength,  s.radar_jamming,  s.orbit_ore,  " &_
			" s.orbit_hydrocarbon, galaxy, sector, planet, s.pct_ore, s.pct_hydrocarbon " &_
			" FROM spy_planet AS s" &_
			" LEFT JOIN nav_planet " &_
				" ON ( s.planet_id=nav_planet.id) " &_
			" WHERE spy_id=" & id	

	set oRs = oConn.Execute(query)

	if oRs.EOF then
		Response.Redirect "reports.asp"
		Response.End
	end if

	dim planet
	planet = oRs(1)

	' display basic info
	content.AssignValue "name", oRs(2)
	content.AssignValue "location", oRs(25) & ":" & oRs(26) & ":" & oRs(27)
	content.AssignValue "floor", oRs(4)
	content.AssignValue "space", oRs(5)
	content.AssignValue "ground", oRs(6)

	content.AssignValue "pct_ore", oRs(28)
	content.AssignValue "pct_hydrocarbon", oRs(29)

	if not isNull(oRs(3)) then
		content.AssignValue "owner", oRs(3)
		content.Parse "planet.owner"
	else
		content.Parse "planet.no_owner"
	end if

		

	if not isNull(oRs(7)) then ' display common info
		content.AssignValue "ore", oRs(7)
		content.AssignValue "hydrocarbon", oRs(8)
		content.AssignValue "ore_capacity", oRs(9)
		content.AssignValue "hydrocarbon_capacity", oRs(10)
		content.AssignValue "ore_prod", oRs(11)
		content.AssignValue "hydrocarbon_prod", oRs(12)
		content.AssignValue "energy_consumption", oRs(13)
		content.AssignValue "energy_prod", oRs(14)
		content.Parse "planet.common"
	end if

	if not isNull(oRs(15)) then ' display rare info
		content.AssignValue "workers", oRs(15)
		content.AssignValue "workers_cap", oRs(16)
		content.AssignValue "scientists", oRs(17)
		content.AssignValue "scientists_cap", oRs(18)
		content.AssignValue "soldiers", oRs(19)
		content.AssignValue "soldiers_cap", oRs(20)
		content.Parse "planet.rare"
	end if

	if not isNull(oRs(21)) then ' display uncommon info
		content.AssignValue "radar_strength", oRs(21)
		content.AssignValue "radar_jamming", oRs(22)
		content.AssignValue "orbit_ore", oRs(23)
		content.AssignValue "orbit_hydrocarbon", oRs(24)
		content.Parse "planet.uncommon"
	end if
	
	' display pending buildings
	query = " SELECT s.building_id, s.quantity, label, s.endtime, category " &_
			" FROM spy_building AS s " &_
			" LEFT JOIN db_buildings " &_
				" ON (s.building_id=id) " &_
			" WHERE spy_id=" & id & " AND planet_id=" & planet & " AND s.endtime IS NOT NULL " &_
			" ORDER BY category, label "

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		while not oRs.EOF
			content.AssignValue "building", oRs(2)
			content.AssignValue "qty", oRs(1)
			content.AssignValue "endtime", oRs(3)
			content.Parse "planet.buildings_pending.building"
			oRs.MoveNext
		wend
		content.Parse "planet.buildings_pending"
	end if

	' display built buildings
	query = " SELECT s.building_id, s.quantity, label, s.endtime, category " &_
			" FROM spy_building AS s " &_
			" LEFT JOIN db_buildings " &_
				" ON (s.building_id=id) " &_
			" WHERE spy_id=" & id & " AND planet_id=" & planet & " AND s.endtime IS NULL " &_
			" ORDER BY category, label "

	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		while not oRs.EOF
			content.AssignValue "building", oRs(2)
			content.AssignValue "qty", oRs(1)
			content.Parse "planet.buildings.building"
			oRs.MoveNext
		wend
		content.Parse "planet.buildings"
	end if

	
	content.AssignValue "date", spydate
	content.AssignValue "nation", target

	content.Parse "planet.spy_" & level

	' spotted is true if our spy has been spotted while he was doing his job
	if spotted then content.Parse "planet.spotted"

	content.Parse "planet"

	content.Parse ""

	display(content)
end sub

'
' process page
'

id = Request.QueryString("id")
if id = "" or not isNumeric(id) then
	Response.Redirect "reports.asp"
	Response.End
end if
id = clng(id)


key = Request.QueryString("key")
if key = "" then
	Response.Redirect "reports.asp"
	Response.End
end if

'
' retrieve report id and info
'

query = "SELECT id, key, userid, type, level, date, credits, spotted, target_name" &_
		" FROM spy" &_
		" WHERE id="&id&" AND key="&dosql(key)

set oRs = oConn.Execute(query)

' check if report exists and if given key is correct otherwise redirect to the reports
if oRs.EOF then
	Response.Redirect "reports.asp"
	Response.End
else
	'user = oRs(2)
	typ = oRs(3)
	level = oRs(4)
	spydate = oRs(5)

	if not isNull(oRs(6)) then credits = oRs(6)
	spotted = oRs(7)
	if not isNull(oRs(8)) then target = oRs(8)
end if

select case typ
	case 1
		DisplayNation()
	case 2
		DisplayFleets()
	case 3
		DisplayPlanet()
	case else
		Response.redirect "reports.asp"
		Response.end
end select

%>