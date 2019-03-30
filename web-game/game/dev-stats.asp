<% Option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = ""

function query(aQuery)
	dim oRs
	set oRs = oConn.Execute(aQuery)
	query = oRs(0)
end function

sub display_galaxies(content)

	dim oRs, query

	query = "SELECT id, colonies, planets, float4(100.0*colonies / planets)," &_
			" visible, allow_new_players, (SELECT count(*) FROM nav_planet WHERE galaxy=nav_galaxies.id AND warp_to IS NOT NULL)" &_
			" FROM nav_galaxies" &_
			" ORDER BY id"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "galaxy", oRs(0)
		content.AssignValue "colonies", oRs(1)
		content.AssignValue "planets", oRs(2)
		content.AssignValue "colonies_pct", oRs(3).Value

		if oRs(4) then
			content.Parse "galaxies.galaxy.visible"
		else
			content.Parse "galaxies.galaxy.invisible"
		end if

		if oRs(5) then
			content.Parse "galaxies.galaxy.allow_new_players"
		else
			content.Parse "galaxies.galaxy.deny_new_players"
		end if

		content.AssignValue "vortex", oRs(6)

		content.Parse "galaxies.galaxy"

		oRs.MoveNext
	wend

	content.Parse "galaxies"
end sub

' display statistics
sub display_stats(content)

	dim oRs
	dim players, colonies, planets, buildings, buildings_pending, fleets, ships, ships_not_in_fleet

	players = clng(query("SELECT count(*) FROM users WHERE privilege=0 AND credits_bankruptcy > 0"))
	content.AssignValue "players", players
	content.AssignValue "recent_players", query("SELECT count(*) FROM users WHERE lastlogin > now()-INTERVAL '2 day'")

	colonies = clng(query("SELECT count(*) FROM nav_planet WHERE ownerid IS NOT NULL"))
	planets = clng(query("SELECT count(*) FROM nav_planet"))

	content.AssignValue "colonies", colonies
	content.AssignValue "planets", planets
	content.AssignValue "colonized", 100.0*colonies / planets

	content.AssignValue "colonies_per_player", 1.0*colonies / players

	set oRs = oConn.Execute("SELECT login, planets FROM users WHERE id > 100 ORDER BY planets DESC LIMIT 1")
	content.AssignValue "max_colonies_playername", oRs(0)
	content.AssignValue "max_colonies", oRs(1)

	buildings = clng(query("SELECT sum(quantity) FROM planet_buildings"))
	content.AssignValue "buildings", buildings
	content.AssignValue "buildings_average", 1.0*buildings / colonies

	buildings_pending = clng(query("SELECT count(*) FROM planet_buildings_pending"))
	content.AssignValue "buildings_pending", buildings_pending
	content.AssignValue "buildings_pending_average", 1.0*buildings_pending / colonies

	set oRs = oConn.Execute("SELECT sum(scientists), sum(soldiers), sum(workers) FROM vw_planets WHERE ownerid IS NOT NULL")
	set oRs = oConn.Execute("SELECT "&oRs(0)&"+sum(cargo_scientists), "&oRs(1)&"+sum(cargo_soldiers), "&oRs(2)&"+sum(cargo_workers) FROM fleets WHERE ownerid IS NOT NULL")

	content.AssignValue "scientists", oRs(0)
	content.AssignValue "soldiers", oRs(1)
	content.AssignValue "workers", oRs(2)


	fleets = clng(query("SELECT count(*) FROM fleets WHERE ownerid > 100"))
	ships = clng(query("SELECT sum(quantity) FROM fleets JOIN fleets_ships ON (fleets.id=fleets_ships.fleetid) WHERE fleets.ownerid > 100"))

	content.AssignValue "fleets", fleets
	content.AssignValue "ships", ships
	content.AssignValue "ships_signature", clng(query("SELECT sum(signature) FROM fleets WHERE fleets.ownerid > 100"))

	content.AssignValue "ships_average", 1.0*ships/fleets

	ships_not_in_fleet = clng(query("SELECT sum(quantity) FROM planet_ships"))

	content.AssignValue "ships_not_in_fleet", ships_not_in_fleet
	content.AssignValue "ships_not_in_fleet_signature", clng(query("SELECT sum(signature*quantity) FROM planet_ships INNER JOIN db_ships ON (db_ships.id=planet_ships.shipid)"))
	content.AssignValue "ships_not_in_fleet_percent", 1.0*(ships_not_in_fleet) / (ships_not_in_fleet+ships) * 100

	content.AssignValue "fleets_patrolling", clng(query("SELECT count(*) FROM fleets WHERE action=0 AND ownerid > 100"))
	content.AssignValue "fleets_moving", clng(query("SELECT count(*) FROM fleets WHERE action=1 or action=-1 AND ownerid > 100"))
	content.AssignValue "fleets_recycling", clng(query("SELECT count(*) FROM fleets WHERE action=2 AND ownerid > 100"))

	content.AssignValue "battles", clng(query("SELECT count(*) FROM battles WHERE time > now()-INTERVAL '1 days'"))
	content.AssignValue "invasions", clng(query("SELECT count(*) FROM invasions WHERE time > now()-INTERVAL '1 days'"))
	content.AssignValue "alerts", clng(query("SELECT count(*) FROM reports WHERE type=7 AND datetime > now()-INTERVAL '1 days'"))

	content.AssignValue "displayed_ads", query("SELECT sum(displays_ads) FROM users WHERE privilege=0 AND credits_bankruptcy > 0")
	content.AssignValue "displayed_pages", query("SELECT sum(displays_pages) FROM users WHERE privilege=0 AND credits_bankruptcy > 0")
	content.AssignValue "ads_pct", query("SELECT float4(1.0*sum(displays_ads)/sum(displays_pages)*100) FROM users WHERE privilege=0 AND credits_bankruptcy > 0")

	content.AssignValue "players_blocking_ads", query("SELECT count(1) FROM users WHERE privilege=0  AND credits_bankruptcy > 0 AND displays_ads < 0.9*displays_pages")
	content.AssignValue "players_blocking_ads_pct", query("SELECT float4(100.0*count(1)/" & players &") FROM users WHERE privilege=0  AND credits_bankruptcy > 0 AND displays_ads < 0.9*displays_pages")

	content.Parse "general"
end sub

sub display_alliances_production(content)

	dim oRs, query

	query = "SELECT alliances.tag, alliances.name," &_
			" sum(ore_production), float4(100.0*sum(ore_production)/(select sum(ore_production) from nav_planet where ownerid > 100))," &_
			" sum(hydrocarbon_production), float4(100.0*sum(hydrocarbon_production)/(select sum(hydrocarbon_production) from nav_planet where ownerid > 100))" &_
			" FROM nav_planet" &_
			"	INNER JOIN users on nav_planet.ownerid=users.id" &_
			"	LEFT JOIN alliances on users.alliance_id=alliances.id" &_
			" GROUP BY users.alliance_id, alliances.tag, alliances.name" &_
			" ORDER BY sum(ore_production) DESC"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "tag", oRs(0)
		content.AssignValue "name", oRs(1)

		content.AssignValue "ore", oRs(2)
		content.AssignValue "ore_pct", oRs(3).Value	' total univers production

		content.AssignValue "hydrocarbon", oRs(4) ' total univers production
		content.AssignValue "hydrocarbon_pct", oRs(5).Value ' total univers production

		content.Parse "alliances_production.alliance"

		oRs.MoveNext
	wend

	content.Parse "alliances_production"
end sub

sub display_server_stats(content)

	content.AssignValue "db_buildings", Application("db_buildings.retrieved")
	content.AssignValue "db_buildings_lastupdate", Application("db_buildings.last_retrieve")

	content.AssignValue "db_buildings_req", Application("db_buildings_req.retrieved")
	content.AssignValue "db_buildings_req_lastupdate", Application("db_buildings_req.last_retrieve")

	content.AssignValue "db_ships", Application("db_ships.retrieved")
	content.AssignValue "db_ships_lastupdate", Application("db_ships.last_retrieve")

	content.AssignValue "db_ships_req", Application("db_ships_req.retrieved")
	content.AssignValue "db_ships_req_lastupdate", Application("db_ships_req.last_retrieve")

	content.AssignValue "db_research", Application("db_research.retrieved")
	content.AssignValue "db_research_lastupdate", Application("db_research.last_retrieve")

	dim oRs, query

	query = "SELECT category, procedure, enabled, last_runtime, last_result, average_executiontime, last_runtime+run_every+INTERVAL '1 minute' <= now()" &_
			" FROM sys_executions"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "category", oRs(0)
		content.AssignValue "procedure", oRs(1)
		if not oRs(2) then content.Parse "server.procedure.disabled"
		content.AssignValue "last_runtime", oRs(3).Value
		content.AssignValue "last_result", oRs(4)
		content.AssignValue "average_executetime", oRs(5)

		if oRs(6) then content.Parse "server.procedure.error"

		content.Parse "server.procedure"
		oRs.MoveNext
	wend

	content.Parse "server"
end sub

if Session("privilege") < 100 then
	response.redirect "/"
	response.end
end if

dim cat
cat = ToInt(Request.QueryString("cat"), 0)

if cat < 0 or cat > 3 then cat = 0


dim content
set content = GetTemplate("dev-stats")

content.Parse "tabnav."&cat&".selected"
content.Parse "tabnav.0"
content.Parse "tabnav.1"
content.Parse "tabnav.2"
content.Parse "tabnav.3"
content.Parse "tabnav"

select case cat
	case 0
		display_galaxies content
	case 1
		display_stats content
	case 2
		display_alliances_production content
	case 3
		display_server_stats content
end select

content.Parse ""
display(content)

%>