<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets_ships_stats"

retrieveShipsCache

' List all the available ships for construction
sub ListShips()
	dim oRs, query

	' list ships that can be built on the planet
	query = "SELECT category, shipid, killed, lost" &_
			" FROM users_ships_kills" &_
			"	INNER JOIN db_ships ON (db_ships.id = users_ships_kills.shipid)" &_
			" WHERE userid=" & UserId &_
			" ORDER BY shipid"
	set oRs = oConn.Execute(query)

	dim content
	set content = GetTemplate("fleets-ships-stats")

	dim category, lastCategory, itemCount, ShipId

	' number of items in category
	itemCount = 0

	if not oRs.EOF then
		category = oRs("category")
		lastCategory = category 
	end if

	dim count, total_killed, total_lost
	count = 0
	total_killed = 0
	total_lost = 0
	while not oRs.EOF
		dim id, quantity
		category = oRs("category")

		if category <> lastCategory then
			if itemCount > 0 then
				content.Parse "category.category" & lastcategory
				content.Parse "category"
			end if

			lastCategory = category

			itemCount = 0
		end if

		ShipId = oRs("shipid")

		content.AssignValue "id", ShipId
		content.AssignValue "name", getShipLabel(ShipId)
		content.AssignValue "killed", oRs(2)
		content.AssignValue "lost", oRs(3)

		content.Parse "category.ship"

		total_killed = total_killed + oRs(2)
		total_lost = total_lost + oRs(3)
		count = count + 1
		itemCount = itemCount + 1

		oRs.MoveNext
	wend

	if itemCount > 0 then content.Parse "category.category" & category

	if count > 0 then
		content.Parse "category"

		content.AssignValue "kills", total_killed
		content.AssignValue "losses", total_lost
		content.Parse "total"
	end if

	if count = 0 then content.Parse "no_ship"

	content.Parse ""

	Display(content)
end sub

ListShips()
%>