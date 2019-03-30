<%Option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "reports"


' display list of messages
function display_mails(cat)

	dim content
	set content = GetTemplate("reports")

	dim oRs, query, oSpyRs

	query = "SELECT type, subtype, datetime, battleid, fleetid, fleet_name," &_
			" planetid, planet_name, galaxy, sector, planet," &_
			" researchid, 0, read_date," &_
			" planet_relation, planet_ownername," &_
			" ore, hydrocarbon, credits, scientists, soldiers, workers, username," &_
			" alliance_tag, alliance_name," &_
			" invasionid, spyid, spy_key, description, buildingid," &_
			" upkeep_commanders, upkeep_planets, upkeep_scientists, upkeep_ships, upkeep_ships_in_position, upkeep_ships_parked, upkeep_soldiers," &_
			" name" &_
			" FROM vw_reports" &_
			" WHERE ownerid = " & UserID

	'
	' Limit the list to the current category or only display 100 reports if no categories specified
	'
	if cat = 0 then
		query = query & " ORDER BY datetime DESC LIMIT 100"
	else
		query = query & " AND type = "& cat & " ORDER BY datetime DESC LIMIT 1000"
	end if

	content.AssignValue "ownerid", UserId

	
	set oRs = oConn.Execute(query)
	content.Parse "tabnav."&cat&"00.selected"
	if oRs.EOF then content.Parse "noreports"

	dim reportType
	'
	' List the reports returned by the query
	'
	while not oRs.EOF

		reportType = oRs(0)*100+oRs(1)

		if reportType <> 140 and reportType <> 141 and reportType <> 133 then

		with content
			.AssignValue "type", reportType
			.AssignValue "date", oRs(2).Value

			.AssignValue "battleid", oRs(3)
			.AssignValue "fleetid", oRs(4)
			.AssignValue "fleetname", oRs(5)
			.AssignValue "planetid", oRs(6)

			select case oRs(14)
				case rHostile, rWar, rFriend
					.AssignValue "planetname", oRs(15)
				case rAlliance, rSelf
					.AssignValue "planetname", oRs(7)
				case else
					.AssignValue "planetname", ""
			end select

			' assign planet coordinates
			if not isNull(oRs(8)) then
				.AssignValue "g", oRs(8)
				.AssignValue "s", oRs(9)
				.AssignValue "p", oRs(10)
			end if

			.AssignValue "researchid", oRs(11)

			if not IsNull(oRs(11)) then .AssignValue "researchname", getResearchLabel(oRs(11))

			if isNull(oRs(13)) then .Parse "message.new"

			.AssignValue "ore", oRs(16)
			.AssignValue "hydrocarbon", oRs(17)
			.AssignValue "credits", oRs(18)

			.AssignValue "scientists", oRs(19)
			.AssignValue "soldiers", oRs(20)
			.AssignValue "workers", oRs(21)

			.AssignValue "username", oRs(22)
			.AssignValue "alliancetag", oRs(23)
			.AssignValue "alliancename", oRs(24)
			.AssignValue "invasionid", oRs(25)
			.AssignValue "spyid", oRs(26)
			.AssignValue "spykey", oRs(27)

			.AssignValue "description", oRs(28)

			if not IsNull(oRs(29)) then .AssignValue "building", getBuildingLabel(oRs(29))

			.AssignValue "upkeep_commanders", oRs(30)
			.AssignValue "upkeep_planets", oRs(31)
			.AssignValue "upkeep_scientists", oRs(32)
			.AssignValue "upkeep_ships", oRs(33)
			.AssignValue "upkeep_ships_in_position", oRs(34)
			.AssignValue "upkeep_ships_parked", oRs(35)
			.AssignValue "upkeep_soldiers", oRs(36)

			.AssignValue "commandername", oRs(37)

			.Parse "message." & reportType
			.Parse "message"
		end with

		end if

		oRs.movenext
	wend

	'
	' List how many new reports there are for each category
	'
	query = "SELECT r.type, int4(COUNT(1)) " &_
			" FROM reports AS r" &_
			" WHERE datetime <= now()" &_
			" GROUP BY r.type, r.ownerid, r.read_date" &_
			" HAVING r.ownerid = " & UserID & " AND read_date is NULL"
	set oRs = oConn.Execute(query)
	
	dim total_newreports
	total_newreports = 0
	while not oRs.EOF
		content.AssignValue "cat_newreports", oRs(1)
		content.Parse "tabnav."&oRs(0)&"00.new"

		total_newreports = total_newreports + oRs(1)
		oRs.MoveNext
	wend

	if total_newreports <> 0 then
		content.AssignValue "total_newreports", total_newreports
		content.Parse "tabnav.000.new"
	end if
	
	if not IsImpersonating then
		' flag only the current category of reports as read
		if cat <> 0 then
			oConn.Execute "UPDATE reports SET read_date = now() WHERE ownerid = " & userid & " AND type = "&cat& " AND read_date is NULL AND datetime <= now()", , adExecuteNoRecords
		end if

		' flag all reports as read
		if Request.QueryString("cat") = "0" then
			oConn.Execute "UPDATE reports SET read_date = now() WHERE ownerid = " & userid & " AND read_date is NULL AND datetime <= now()", , adExecuteNoRecords
		end if
	end if
	
	
	content.Parse "tabnav.000"
	content.Parse "tabnav.100"
	content.Parse "tabnav.200"
	content.Parse "tabnav.300"
	content.Parse "tabnav.400"
	content.Parse "tabnav.500"
	content.Parse "tabnav.600"
	content.Parse "tabnav.700"
	content.Parse "tabnav.800"
	content.Parse "tabnav"

	content.Parse ""
	display(content)
end function

dim cat
cat = ToInt(Request.QueryString("cat"), 0)

display_mails cat

%>