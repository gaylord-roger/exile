<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets.traderoutes"

' List the fleets owned by the player
sub displayRoute(routeid)
	dim content, oRs, query
	set content = GetTemplate("fleets-traderoute")

	'
	' populate destination list, there are 2 groups : planets and fleets
	'

	dim i
	for i = 0 to planetListCount

		content.AssignValue "index", i
		content.AssignValue "name", planetListArray(1,i)
		content.AssignValue "to_g", planetListArray(2,i)
		content.AssignValue "to_s", planetListArray(3,i)
		content.AssignValue "to_p", planetListArray(4,i)

		if i = 0 then
			content.AssignValue "g", planetListArray(2,i)
			content.AssignValue "s", planetListArray(3,i)
			content.AssignValue "p", planetListArray(4,i)
		end if

		content.Parse "planetgroup.planet"
	next
	content.Parse "planetgroup"


	'
	' list planets where we have fleets not on our planets
	'
	query = " SELECT DISTINCT ON (f.planetid) f.name, f.planetid, f.planet_galaxy, f.planet_sector, f.planet_planet" &_
			" FROM vw_fleets AS f" &_
			"	 LEFT JOIN nav_planet AS p ON (f.planetid=p.id)" &_
			" WHERE f.ownerid="& UserID&" AND p.ownerid IS DISTINCT FROM "& UserID &_
			" ORDER BY f.planetid" &_
			" LIMIT 200"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "fleetindex", i
		content.AssignValue "fleet_name", oRs(0)
		content.AssignValue "fleet_g", oRs(2)
		content.AssignValue "fleet_s", oRs(3)
		content.AssignValue "fleet_p", oRs(4)

		i = i + 1
		oRs.MoveNext
	wend
'	if ShowThis then content.Parse "fleetgroup"
	
	content.Parse ""

	Display(content)
end sub

displayRoute(ToInt(Request.QueryString("id"), 0))

%>