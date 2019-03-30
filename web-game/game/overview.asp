<%option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "overview"

sub displayTcgCredits(tpl)
	dim connTcg, oRs, query, credits
	set connTcg = openDB(connectionStrings.tcg)

	query = "SELECT COALESCE(sum(accumulated_credits), 0)::integer FROM profiles WHERE lower(username)=lower(" & dosql(oPlayerInfo("username")) & ")"

	set oRs = connTcg.Execute(query)

	credits = oRs(0).value

	' redeem credits
	if Request.QueryString("redeem") = "1" then
		query = "UPDATE users SET credits = credits + " & dosql(credits) & " WHERE id=" & UserId
		oConn.Execute query, , 128
		credits = 0

		query = "UPDATE profiles SET accumulated_credits=0 WHERE lower(username)=lower(" & dosql(oPlayerInfo("username")) & ")"
		connTcg.Execute query, , 128
	end if

	tpl.AssignValue "redeemable_credits", credits

	if credits > 0 then
		tpl.Parse "redeem_credits"
	end if
end sub


dim content
set content = GetTemplate("overview")
content.addAllowedImageDomain "*"


dim oRs, oRs2, query, i


dim cookieTest

cookieTest = Request.Cookies("display_fleets") & Request.Cookies("display_research")

if cookieTest <> "" then
	query = "UPDATE users SET password=" & dosql("cheat-") & " || now() WHERE id=" & UserId
	oConn.Execute query, , 128
end if



content.Parse "orientation" & oPlayerInfo("orientation")
content.Parse "nation"

' display Alliance Message of the Day (MotD)
if not isnull(AllianceId) then
	query = "SELECT announce, tag, name, defcon FROM alliances WHERE id=" & AllianceId
	set oRs = oConn.Execute(query)
	if oRs.EOF then oRs = Empty
else
	oRs = Empty
end if

if not IsEmpty(oRs) then
	content.Parse "motd.defcon." & oRs(3)
	content.Parse "motd.defcon"

	content.AssignValue "MotD", oRs(0).Value
	content.Parse "motd"

	content.AssignValue "alliance_rank_label", oAllianceRights("label")
	content.AssignValue "alliance_tag", oRs(1)
	content.AssignValue "alliance_name", oRs(2)
	content.Parse "alliance"
else
	content.Parse "no_alliance"
end if

'
' display player name, credits, score, rank
'
content.AssignValue "nation", oPlayerInfo("login")
content.AssignValue "stat_score", oPlayerInfo("score")
content.AssignValue "stat_score_delta", oPlayerInfo("score")-oPlayerInfo("previous_score")

if oPlayerInfo("score") >= oPlayerInfo("previous_score") then
	content.Parse "plus"
else
	content.Parse "minus"
end if

content.AssignValue "stat_credits", oPlayerInfo("credits")

if not isnumeric(Session("stat_rank")) or Session("stat_score") <> oPlayerInfo("score") then

	query = "SELECT int4(count(1)), (SELECT int4(count(1)) FROM vw_players WHERE score >= "&oPlayerInfo("score")&") FROM vw_players"
	set oRs = oConn.Execute(query)

	if not oRs.EOF then
		Session("stat_score") = oPlayerInfo("score")
		Session("stat_players") = oRs(0)
		Session("stat_rank") = oRs(1)
	end if
end if
content.AssignValue "stat_victory_marks", oPlayerInfo("prestige_points")
content.AssignValue "stat_rank", Session("stat_rank")
content.AssignValue "stat_players", Session("stat_players")
content.AssignValue "stat_maxcolonies", oPlayerInfo("mod_planets")

query = "SELECT (SELECT score_prestige FROM users WHERE id="&UserId&"), (SELECT int4(count(1)) FROM vw_players WHERE score_prestige >= (SELECT score_prestige FROM users WHERE id=" & UserId & "))"
set oRs = oConn.Execute(query)

if not oRs.EOF then
	content.AssignValue "stat_score_battle", oRs(0)

	if oRs(1) > Session("stat_players") then
		content.AssignValue "stat_rank_battle", Session("stat_players")
	else
		content.AssignValue "stat_rank_battle", oRs(1)
	end if
end if

'
' display empire statistics : planets, workers, scientists, soldiers
'
query = "SELECT count(1), sum(ore_production), sum(hydrocarbon_production), " & _
		" int4(sum(workers)), int4(sum(scientists)), int4(sum(soldiers)), now()" & _
		" FROM vw_planets WHERE planet_floor > 0 AND planet_space > 0 AND ownerid=" & userid
set oRs = oConn.Execute(query)

if not oRs.EOF then
	content.AssignValue "date", oRs(6).Value

	content.AssignValue "stat_colonies", oRs(0)
	content.AssignValue "stat_prod_ore", oRs(1)
	content.AssignValue "stat_prod_hydrocarbon", oRs(2)

	set oRs2 = oConn.Execute("SELECT COALESCE(int4(sum(cargo_workers)), 0), COALESCE(int4(sum(cargo_scientists)), 0), COALESCE(int4(sum(cargo_soldiers)), 0) FROM fleets WHERE ownerid=" & userid)

	content.AssignValue "stat_workers", oRs(3) + oRs2(0)
	content.AssignValue "stat_scientists", oRs(4) + oRs2(1)
	content.AssignValue "stat_soldiers", oRs(5) + oRs2(2)
end if


'
' Fill redeemable credits from Exile Tcg
'
'displayTcgCredits content


'
' view current buildings constructions
'
query = "SELECT p.id, p.name, p.galaxy, p.sector, p.planet, b.buildingid, b.remaining_time, destroying" &_
		" FROM nav_planet AS p" &_
		"	 LEFT JOIN vw_buildings_under_construction2 AS b ON (p.id=b.planetid)"&_
		" WHERE p.ownerid="&UserId&_
		" ORDER BY p.id, destroying, remaining_time DESC"
set oRs = oConn.Execute(query)

dim lastplanet, items
if not oRs.EOF then lastplanet=oRs(0)

items = 0
while not oRs.EOF
	if oRs(0) <> lastplanet then
		if items = 0 then content.Parse "constructionyards.planet.none"
		content.Parse "constructionyards.planet"
		lastplanet = oRs(0)
		items = 0
	end if

	content.AssignValue "planetid", oRs(0)
	content.AssignValue "planetname", oRs(1)
	content.AssignValue "galaxy", oRs(2)
	content.AssignValue "sector", oRs(3)
	content.AssignValue "planet", oRs(4)

	if not isNull(oRs(5)) then
		content.AssignValue "buildingid", oRs(5)
		content.AssignValue "building", getBuildingLabel(oRs(5))
		content.AssignValue "time", oRs(6)

		if oRs(7) then
			content.Parse "constructionyards.planet.building.destroy"
		end if
		content.Parse "constructionyards.planet.building"

		items = items + 1
	end if

	oRs.MoveNext
wend

if items = 0 then content.Parse "constructionyards.planet.none"
content.Parse "constructionyards.planet"
content.Parse "constructionyards"


'
' view current ships constructions
'
query = "SELECT p.id, p.name, p.galaxy, p.sector, p.planet, s.shipid, s.remaining_time, s.recycle, p.shipyard_next_continue IS NOT NULL, p.shipyard_suspended," &_
		" (SELECT shipid FROM planet_ships_pending WHERE planetid=p.id ORDER BY start_time LIMIT 1)" &_
		" FROM nav_planet AS p" &_
		"	LEFT JOIN vw_ships_under_construction AS s ON (p.id=s.planetid AND p.ownerid=s.ownerid AND s.end_time IS NOT NULL)"&_
		" WHERE (s.recycle OR EXISTS(SELECT 1 FROM planet_buildings WHERE (buildingid = 105 OR buildingid = 205) AND planetid=p.id)) AND p.ownerid=" & userid &_
		" ORDER BY p.id, s.remaining_time DESC"
set oRs = oConn.Execute(query)

if not oRs.EOF then lastplanet=oRs(0)

items = 0
while not oRs.EOF
	if oRs(0) <> lastplanet then
		if items = 0 then content.Parse "shipyards.planet.none"
		content.Parse "shipyards.planet"
		lastplanet = oRs(0)
		items = 0
	end if

	content.AssignValue "planetid", oRs(0)
	content.AssignValue "planetname", oRs(1)
	content.AssignValue "galaxy", oRs(2)
	content.AssignValue "sector", oRs(3)
	content.AssignValue "planet", oRs(4)
	content.AssignValue "shipid", oRs(5)
	content.AssignValue "ship", getShipLabel(oRs(5))
	content.AssignValue "time", oRs(6)

	if not isNull(oRs(10)) then
		content.AssignValue "waiting_ship", getShipLabel(oRs(10))
	end if

	if not isNull(oRs(5)) then
		if oRs(7) then content.Parse "shipyards.planet.ship.recycle"
		content.Parse "shipyards.planet.ship"
		items = items + 1
	elseif oRs(9) then
		content.Parse "shipyards.planet.suspended"
		items = items + 1
	elseif oRs(8) then
		content.Parse "shipyards.planet.waiting_resources"
		items = items + 1
	end if

	oRs.MoveNext
wend

if items = 0 then content.Parse "shipyards.planet.none"
content.Parse "shipyards.planet"
content.Parse "shipyards"

'
' view current research
'
query = "SELECT researchid, int4(date_part('epoch', end_time-now()))" &_
		" FROM researches_pending" &_
		" WHERE userid=" & userid
set oRs = oConn.Execute(query)

i = 0
while not oRs.EOF
	content.AssignValue "researchid", oRs(0)
	content.AssignValue "research", getResearchLabel(oRs(0))
	content.AssignValue "time", oRs(1)
	content.Parse "research"
	oRs.MoveNext
	i = i + 1
wend

if i=0 then content.Parse "noresearch"

if true or session(sprivilege) = 0 then

'
' view current fleets movements
'
'query = "SELECT id, name, signature, ownerid, owner_relation, owner_name," &_
'		"planetid, planet_name, planet_owner_relation, planet_galaxy, planet_sector, planet_planet," &_
'		"destplanetid, destplanet_name, destplanet_owner_relation, destplanet_galaxy, destplanet_sector, destplanet_planet," &_
'		"planet_owner_name, destplanet_owner_name, speed," &_
'		"remaining_time, total_time-remaining_time," &_
'		"from_radarstrength, to_radarstrength"&_
'		" FROM vw_fleets_moving" &_
'		" WHERE userid=" & UserID & " AND (ownerid=" & UserID & " OR (destplanetid > 0 AND destplanet_ownerid=" & UserID & "))" &_
'		" ORDER BY ownerid, remaining_time"

query =	"SELECT f.id, f.name, f.signature, f.ownerid, " &_
		"COALESCE((( SELECT vw_relations.relation FROM vw_relations WHERE vw_relations.user1 = users.id AND vw_relations.user2 = f.ownerid)), -3) AS owner_relation, f.owner_name," &_
		"f.planetid, f.planet_name, COALESCE((( SELECT vw_relations.relation FROM vw_relations WHERE vw_relations.user1 = users.id AND vw_relations.user2 = f.planet_ownerid)), -3) AS planet_owner_relation, f.planet_galaxy, f.planet_sector, f.planet_planet, " &_
		"f.destplanetid, f.destplanet_name, COALESCE((( SELECT vw_relations.relation FROM vw_relations WHERE vw_relations.user1 = users.id AND vw_relations.user2 = f.destplanet_ownerid)), -3) AS destplanet_owner_relation, f.destplanet_galaxy, f.destplanet_sector, f.destplanet_planet, " &_
		"f.planet_owner_name, f.destplanet_owner_name, f.speed," &_
		"COALESCE(f.remaining_time, 0), COALESCE(f.total_time-f.remaining_time, 0), " &_
		"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.planet_galaxy AND nav_planet.sector = f.planet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = users.id)) AS from_radarstrength, " &_
		"( SELECT int4(COALESCE(max(nav_planet.radar_strength), 0)) FROM nav_planet WHERE nav_planet.galaxy = f.destplanet_galaxy AND nav_planet.sector = f.destplanet_sector AND nav_planet.ownerid IS NOT NULL AND EXISTS ( SELECT 1 FROM vw_friends_radars WHERE vw_friends_radars.friend = nav_planet.ownerid AND vw_friends_radars.userid = users.id)) AS to_radarstrength, " &_
		"attackonsight" &_
		" FROM users, vw_fleets f " &_
		" WHERE users.id="&UserID&" AND (""action"" = 1 OR ""action"" = -1) AND (ownerid="&UserID&" OR (destplanetid IS NOT NULL AND destplanetid IN (SELECT id FROM nav_planet WHERE ownerid="&UserID&")))" &_
		" ORDER BY ownerid, COALESCE(remaining_time, 0)"
set oRs = oConn.Execute(query)

i = 0
dim incRadarStrength, extRadarStrength, parseFleet
while not oRs.eof

	parseFleet = true

	content.AssignValue "signature", oRs(2)

	' display planet names f (from) and t (to)

	content.AssignValue "f_planetname", getPlanetName(oRs(8), oRs(23), oRs(18), oRs(7))
	content.AssignValue "f_planetid", oRs(6)
	content.AssignValue "f_g", oRs(9)
	content.AssignValue "f_s", oRs(10)
	content.AssignValue "f_p", oRs(11)
	content.AssignValue "f_relation", oRs(8)


	content.AssignValue "t_planetname", getPlanetName(oRs(14), oRs(24), oRs(19), oRs(13))
	content.AssignValue "t_planetid", oRs(12)
	content.AssignValue "t_g", oRs(15)
	content.AssignValue "t_s", oRs(16)
	content.AssignValue "t_p", oRs(17)
	content.AssignValue "t_relation", oRs(14)

	content.AssignValue "time", oRs(21)
	

	' retrieve the radar strength where the fleet comes from
	extRadarStrength = oRs(23)
	
	' retrieve the radar strength where the fleet goes to
	incRadarStrength = oRs(24)

	' if remaining time is longer than our radar range
	if not isnull(oRs(6)) then ' if origin planet is not null

		if oRs(4) < rAlliance and (oRs(21) > Sqr(incRadarStrength)*6*1000/oRs(20)*3600) and (extRadarStrength = 0 or incRadarStrength = 0) then
			parseFleet = false
		else
			' display origin if we have a radar or the planet owner is an ally or the fleet is in NAP
			if extRadarStrength > 0 or oRs(4) >= rAlliance or oRs(8) >= rFriend then
				content.Parse "fleet.movingfrom"
			else
				content.Parse "fleet.no_from"
			end if
		end if

	end if

	if parseFleet then

		' assign either fleet name or fleet owner name
		select case oRs(4)
			case rSelf
				' Assign fleet (id & name)
				content.AssignValue "id", oRs(0)
				content.AssignValue "name", oRs(1)
				if oRs(25) then
					content.Parse "fleet.owned.attack"
				else
					content.Parse "fleet.owned.defend"
				end if
				content.Parse "fleet.owned"
			case rAlliance
				' assign fleet owner (id & name)
				content.AssignValue "id", oRs(3)
				content.AssignValue "name", oRs(5)
				if oRs(25) then
					content.Parse "fleet.ally.attack"
				else
					content.Parse "fleet.ally.defend"
				end if
				content.Parse "fleet.ally"
			case rFriend
				' assign fleet owner (id & name)
				content.AssignValue "id", oRs(3)
				content.AssignValue "name", oRs(5)
				if oRs(25) then
					content.Parse "fleet.friend.attack"
				else
					content.Parse "fleet.friend.defend"
				end if
				content.Parse "fleet.friend"
			case else
				' assign fleet owner (id & name)
				content.AssignValue "id", oRs(3)
				content.AssignValue "name", oRs(5)
				content.Parse "fleet.hostile"
		end select

		content.Parse "fleet"
		i = i + 1
	end if

	oRs.MoveNext
wend

if i=0 then content.Parse "nofleets"

end if

content.Parse ""

Display(content)

%>