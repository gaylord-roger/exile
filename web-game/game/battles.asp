<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "battles"


sub DisplayBattles()
	dim query, oRs

	query = "SELECT battles.id, time, planetid, name, galaxy, sector, planet" & _
			" FROM battles INNER JOIN nav_planet ON (planetid=nav_planet.id)" & _
			" ORDER BY time DESC LIMIT 100"

	set oRs = oConn.Execute(query)

	dim content
	Set content = GetTemplate("battles")

	while not oRs.EOF
		dim btime
		btime = oRs(1)

		content.AssignValue "id", oRs(0)
		content.AssignValue "time", btime
		content.AssignValue "planetid", oRs(2)
		content.AssignValue "planet", oRs(3)
		content.AssignValue "g", oRs(4)
		content.AssignValue "s", oRs(5)
		content.AssignValue "p", oRs(6)
		
		content.Parse "battle"
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 500 then
	Response.Redirect "/"
	Response.End
end if

DisplayBattles()

%>