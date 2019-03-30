<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "player_expenses"

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-expenses")

	dim oRs, query

	query = "SELECT datetime, e.credits, credits_delta," &_
			" buildingid, shipid, researchid, quantity, fleetid, fleets.name AS fleetname," &_
			" e.planetid, nav_planet.name AS planetname, nav_planet.galaxy, nav_planet.sector, nav_planet.planet," &_
			" e.ore, e.hydrocarbon, to_alliance, to_user, users.login, leave_alliance, spyid, e.scientists, e.soldiers" &_
			" FROM users_expenses e" &_
			"	LEFT JOIN nav_planet ON e.planetid=nav_planet.id" &_
			"	LEFT JOIN fleets ON fleetid=fleets.id" &_
			"	LEFT JOIN users ON to_user=users.id" &_
			" WHERE userid=" & UserId &_
			" ORDER BY datetime DESC"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "timestamp", oRs(0)
		content.AssignValue "credits", oRs(1)
		content.AssignValue "credits_delta", oRs(2)

		content.AssignValue "planetname", oRs("planetname")
		content.AssignValue "g", oRs("galaxy")
		content.AssignValue "s", oRs("sector")
		content.AssignValue "p", oRs("planet")

		if not isnull(oRs("quantity")) then content.AssignValue "quantity", oRs("quantity")

		if not isnull(oRs("buildingid")) then
			content.AssignValue "building", GetBuildingLabel(oRs("buildingid"))
			content.Parse "expense.build_building"
		end if

		if not isnull(oRs("shipid")) then
			content.AssignValue "ship", GetShipLabel(oRs("shipid"))
			content.Parse "expense.build_ship"
		end if

		if not isnull(oRs("researchid")) then
			content.AssignValue "research", getResearchLabel(oRs("researchid"))
			content.Parse "expense.research"
		end if

		if not isnull(oRs("spyid")) then
			content.AssignValue "spyid", oRs("spyid")
			content.Parse "expense.spy"
		end if

		if not isnull(oRs("to_user")) then
			content.AssignValue "to_user", oRs("to_user")
			content.AssignValue "username", oRs("login")
			content.Parse "expense.sent"
		end if

		if not isnull(oRs("leave_alliance")) then
			content.Parse "expense.leave_alliance"
		end if

		if not isnull(oRs("scientists")) then
			content.AssignValue "scientists", oRs("scientists")
			content.AssignValue "soldiers", oRs("soldiers")
			content.Parse "expense.train"
		end if

		if not isnull(oRs("to_alliance")) then
			content.Parse "expense.to_alliance"
		end if

		if not isnull(oRs("ore")) then
			content.AssignValue "ore", oRs("ore")
			content.AssignValue "hydrocarbon", oRs("hydrocarbon")
			content.Parse "expense.buy"
		end if

		if not isnull(oRs("fleetid")) then
			content.AssignValue "fleetname", oRs("fleetname")
			content.Parse "expense.movefleet"
		end if

		content.Parse "expense"
		oRs.MoveNext
	wend

	content.Parse ""

	FillHeaderCredits

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

DisplayForm()

%>