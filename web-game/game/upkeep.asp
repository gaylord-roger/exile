<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "upkeep"

sub displayUpkeep()

	dim content, oRs, query
	set content = getTemplate("upkeep")

	dim hours
	hours = 24 - Hour(Now())


	query = "SELECT scientists,soldiers,planets,ships_signature,ships_in_position_signature,ships_parked_signature," &_
			" cost_planets2,cost_scientists,cost_soldiers,cost_ships,cost_ships_in_position,cost_ships_parked," &_
			" int4(upkeep_scientists + scientists*cost_scientists/24*"&hours&"),"&_
			" int4(upkeep_soldiers + soldiers*cost_soldiers/24*"&hours&"),"&_
			" int4(upkeep_planets + cost_planets2/24*"&hours&"),"&_
			" int4(upkeep_ships + ships_signature*cost_ships/24*"&hours&"),"&_
			" int4(upkeep_ships_in_position + ships_in_position_signature*cost_ships_in_position/24*"&hours&"),"&_
			" int4(upkeep_ships_parked + ships_parked_signature*cost_ships_parked/24*"&hours&"),"&_
			" commanders, commanders_salary, cost_commanders, upkeep_commanders + int4(commanders_salary*cost_commanders/24*"&hours&")" &_
			" FROM vw_players_upkeep" &_
			" WHERE userid=" & UserId
	set oRs = oConn.Execute(query)

	content.AssignValue "commanders_quantity", oRs(18)
	content.AssignValue "commanders_salary", oRs(19)
	content.AssignValue "commanders_cost", oRs(20)
	content.AssignValue "commanders_estimated_cost", oRs(21)

	content.AssignValue "scientists_quantity", oRs(0)
	content.AssignValue "soldiers_quantity", oRs(1)
	content.AssignValue "planets_quantity", oRs(2)
	content.AssignValue "ships_signature", oRs(3)
	content.AssignValue "ships_in_position_signature", oRs(4)
	content.AssignValue "ships_parked_signature", oRs(5)

	content.AssignValue "planets_cost", oRs(6)
	content.AssignValue "scientists_cost", oRs(7)
	content.AssignValue "soldiers_cost", oRs(8)
	content.AssignValue "ships_cost", oRs(9)
	content.AssignValue "ships_in_position_cost", oRs(10)
	content.AssignValue "ships_parked_cost", oRs(11)

	content.AssignValue "scientists_estimated_cost", oRs(12)
	content.AssignValue "soldiers_estimated_cost", oRs(13)
	content.AssignValue "planets_estimated_cost", oRs(14)
	content.AssignValue "ships_estimated_cost", oRs(15)
	content.AssignValue "ships_in_position_estimated_cost", oRs(16)
	content.AssignValue "ships_parked_estimated_cost", oRs(17)

	content.AssignValue "total_estimation", oRs(12) + oRs(13) + oRs(14) + oRs(15) + oRs(16) + oRs(17) + oRs(21)


	content.Parse ""

	FillHeaderCredits()
	display(content)
end sub

displayUpkeep
%>