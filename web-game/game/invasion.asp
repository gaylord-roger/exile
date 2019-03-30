<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "invasion"

Sub DisplayReport(invasionid, readerid)
	dim content
	set content = GetTemplate("invasion")

	dim query, oRs
	query = "SELECT i.id, i.time, i.planet_id, i.planet_name, i.attacker_name, i.defender_name, " & _
			"i.attacker_succeeded, i.soldiers_total, i.soldiers_lost, i.def_soldiers_total, " & _
			"i.def_soldiers_lost, i.def_scientists_total, i.def_scientists_lost, i.def_workers_total, " & _
			"i.def_workers_lost, galaxy, sector, planet, sp_get_user("&readerid&") " & _
			"FROM invasions AS i INNER JOIN nav_planet ON nav_planet.id = i.planet_id WHERE i.id = "&invasionid
	set oRs = oConn.Execute(query)
	
	if oRs.EOF then
		Response.Redirect "overview.asp"
		Response.End
	end if

	dim viewername
	viewername = oRs(18)

	' compare the attacker name and defender name with the name of who is reading this report
	if oRs(4) <> viewername and oRs(5) <> viewername and not IsNull(AllianceId) then
		' if we are not the attacker or defender, check if we can view this invasion as a member of our alliance of we are ambassador
		if oAllianceRights("can_see_reports") then
			' find the name of the member that did this invasion, either the attacker or the defender
			query = "SELECT login" &_
					" FROM users" &_
					" WHERE (login="&dosql(oRs(4))&" OR login="&dosql(oRs(5))&") AND alliance_id="&AllianceId&" AND alliance_joined <= (SELECT time FROM invasions WHERE id="&invasionid&")"
			dim oRs2
			set oRs2 = oConn.Execute(query)
			if oRs2.EOF then
				Response.Redirect "overview.asp"
				Response.End
			end if
			viewername = oRs2(0)
		else
			Response.Redirect "overview.asp"
			Response.End
		end if
	end if

	content.AssignValue "planetid", oRs(2)
	content.AssignValue "planetname", oRs(3)
	content.AssignValue "g", oRs(15)
	content.AssignValue "s", oRs(16)
	content.AssignValue "p", oRs(17)
	content.AssignValue "planet_owner", oRs(5)
	content.AssignValue "fleet_owner", oRs(4)
	content.AssignValue "date", oRs(1)
	content.AssignValue "soldiers_total", oRs(7)
	content.AssignValue "soldiers_lost", oRs(8)
	content.AssignValue "soldiers_alive", oRs(7) - oRs(8)
	content.AssignValue "def_soldiers_total", oRs(9)
	content.AssignValue "def_soldiers_lost", oRs(10)
	content.AssignValue "def_soldiers_alive", oRs(9) - oRs(10)
	dim def_total : def_total = oRs(9)
	dim def_losts : def_losts = oRs(10)

	if oRs(4) = viewername then 'we are the attacker
		content.AssignValue "relation", rWar
		' display only troops encountered by the attacker's soldiers
		if oRs(9)-oRs(10) = 0 then
			' if no workers remain, display the scientists
			if oRs(13)-oRs(14) = 0 then
				def_total = def_total + oRs(11)
				def_losts = def_losts + oRs(12)
				content.AssignValue "def_scientists_total", oRs(11)
				content.AssignValue "def_scientists_lost", oRs(12)
				content.AssignValue "def_scientists_alive", oRs(11) - oRs(12)
				content.Parse "invasion_report.report.scientists"
			end if
			' if no soldiers remain, display the workers
			def_total = def_total + oRs(13)
			def_losts = def_losts + oRs(14)
			content.AssignValue "def_workers_total", oRs(13)
			content.AssignValue "def_workers_lost", oRs(14)
			content.AssignValue "def_workers_alive", oRs(13) - oRs(14)
			content.Parse "invasion_report.report.workers"
		end if

		content.AssignValue "planetname", oRs(5)

		content.AssignValue "def_alive", def_total - def_losts
		content.AssignValue "def_total", def_total
		content.AssignValue "def_losts", def_losts
		
		content.Parse "invasion_report.report.attacker.ally"
		content.Parse "invasion_report.report.attacker"
		content.Parse "invasion_report.report.defender.enemy"
		content.Parse "invasion_report.report.defender"
	else ' ...we are the defender
		content.AssignValue "relation", rFriend
		def_total = def_total + oRs(11)
		def_losts = def_losts + oRs(12)
		content.AssignValue "def_scientists_total", oRs(11)
		content.AssignValue "def_scientists_lost", oRs(12)
		content.AssignValue "def_scientists_alive", oRs(11) - oRs(12)
		content.Parse "invasion_report.report.scientists"
		def_total = def_total + oRs(13)
		def_losts = def_losts + oRs(14)
		content.AssignValue "def_workers_total", oRs(13)
		content.AssignValue "def_workers_lost", oRs(14)
		content.AssignValue "def_workers_alive", oRs(13) - oRs(14)
		content.Parse "invasion_report.report.workers"

		content.AssignValue "def_alive", def_total - def_losts
		content.AssignValue "def_total", def_total
		content.AssignValue "def_losts", def_losts
		
		content.Parse "invasion_report.report.defender.ally"
		content.Parse "invasion_report.report.defender"
		content.Parse "invasion_report.report.attacker.enemy"
		content.Parse "invasion_report.report.attacker"
	end if
	
	
	if fleetid <> 0 then
		' if a fleetid is specified, parse a link to redirect the user to the fleet
		content.AssignValue "fleetid", fleetid
		content.Parse "invasion_report.justdone"
	end if
	
	if oRs(6) then
		content.Parse "invasion_report.succeeded"
	else
		content.Parse "invasion_report.not_succeeded"
	end if


	content.Parse "invasion_report.report"
	content.Parse "invasion_report"

	content.Parse ""

	Display(content)
end sub

dim invasionid
invasionid = ToInt(Request.QueryString("id"), 0)

if invasionid = 0 then
	Response.Redirect "overview.asp"
	Response.end
end if

dim fleetid
fleetid = ToInt(Request.QueryString("fleetid"), 0)


DisplayReport invasionid, UserID

%>