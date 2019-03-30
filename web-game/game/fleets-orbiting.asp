<% Option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets.orbiting"


' list fleets not belonging to the player that are near his planets
sub listFleetsOrbiting()
	dim content
	set content = GetTemplate("fleets-orbiting")

	dim query, oRs
	query = "SELECT nav_planet.id, nav_planet.name, nav_planet.galaxy, nav_planet.sector, nav_planet.planet," &_
			" fleets.id, fleets.name, users.login, alliances.tag, sp_relation(fleets.ownerid, nav_planet.ownerid), fleets.signature" &_
			" FROM nav_planet" &_
			"	INNER JOIN fleets ON fleets.planetid=nav_planet.id" &_
			"	INNER JOIN users ON fleets.ownerid=users.id" &_
			"	LEFT JOIN alliances ON users.alliance_id=alliances.id" &_
			" WHERE nav_planet.ownerid=" & UserId & " AND fleets.ownerid <> nav_planet.ownerid AND action <> 1 AND action <> -1" &_
			" ORDER BY nav_planet.id, upper(alliances.tag), upper(fleets.name)"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		content.Parse "nofleets"
	else
		dim lastplanetid
		lastplanetid=oRs(0)
		
		while not oRs.EOF
			if oRs(0) <> lastplanetid then
				content.Parse "planet"
				lastplanetid = oRs(0)
			end if

			content.AssignValue "planetid", oRs(0)
			content.AssignValue "planetname", oRs(1)
			content.AssignValue "g", oRs(2)
			content.AssignValue "s", oRs(3)
			content.AssignValue "p", oRs(4)

			if not isnull(oRs(8)) then
				content.AssignValue "tag", oRs(8)
				content.Parse "planet.fleet.alliance"
			end if

			select case oRs(9)
				case -1
					content.Parse "planet.fleet.enemy"
				case 0
					content.Parse "planet.fleet.friend"
				case 1
					content.Parse "planet.fleet.ally"
			end select

			content.AssignValue "fleetname", oRs(6)
			content.AssignValue "fleetowner", oRs(7)
			content.AssignValue "fleetsignature", oRs(10)
			content.Parse "planet.fleet"

			oRs.MoveNext
		wend
		content.Parse "planet"
	end if

	content.Parse ""
	Display(content)
end sub

listFleetsOrbiting
%>