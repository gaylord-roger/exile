<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "market.buyships"

' List the fleets owned by the player
sub ListStandby()
	dim content, oRs, query
	set content = GetTemplate("market-buy-ships")

	' list the ships
	query = "SELECT nav_planet.id, nav_planet.name, nav_planet.galaxy, nav_planet.sector, nav_planet.planet, db_ships.category, SUM(quantity)" & _
			" FROM nav_planet" &_
			"	LEFT JOIN planet_ships ON (planet_ships.planetid = nav_planet.id)" &_
			"	INNER JOIN db_ships ON (planet_ships.shipid = db_ships.id)" &_
			" WHERE nav_planet.ownerid =" & UserId & _
			" GROUP BY nav_planet.id, nav_planet.name, db_ships.category, nav_planet.galaxy, nav_planet.sector, nav_planet.planet" &_
			" ORDER BY nav_planet.id, db_ships.category"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		dim lastplanetid
		lastplanetid = oRs(0)

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

			content.AssignValue "quantity", oRs(6)

			content.Parse "planet.ship.category" & oRs(5)
			content.Parse "planet.ship.category"

			content.Parse "planet.ship"

			oRs.MoveNext
		wend

		content.Parse "planet"
	end if
	
	content.Parse ""

	Display(content)
end sub

ListStandby()

%>