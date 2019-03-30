<% Option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.reports"


' display list of messages
function display_reports(cat)

	dim content
	set content = GetTemplate("reports")

	dim oRs, query, oSpyRs

	query = "SELECT type, subtype, datetime, battleid, fleetid, fleet_name," &_
			" planetid, planet_name, galaxy, sector, planet," &_
			" researchid, 0, read_date," &_
			" planet_relation, planet_ownername," &_
			" ore, hydrocarbon, credits, scientists, soldiers, workers, username," &_
			" alliance_tag, alliance_name," &_
			" invasionid, spyid, spy_key, description, ownerid, invited_username, login, buildingid" &_
			" FROM vw_alliances_reports" &_
			" WHERE ownerallianceid = " & AllianceId

	'
	' Limit the list to the current category or only display 100 reports if no categories specified
	'
	if cat = 0 then
		query = query & " ORDER BY datetime DESC LIMIT 200"
	else
		query = query & " AND type = "& dosql(cat) & " ORDER BY datetime DESC LIMIT 200"
	end if
	
	set oRs = oConn.Execute(query)
	content.Parse "tabnav."&cat&"00.selected"
	if oRs.EOF then content.Parse "noreports"

	'
	' List the reports returned by the query
	'
	while not oRs.EOF

		with content
			.AssignValue "ownerid", oRs(29)
			.AssignValue "invitedusername", oRs(30)
			.AssignValue "nation", oRs(31)
			.Parse "message.nation"

			.AssignValue "type", oRs(0)*100+oRs(1)
			.AssignValue "date", oRs(2).Value

			.AssignValue "battleid", oRs(3)
			.AssignValue "fleetid", oRs(4)
			.AssignValue "fleetname", oRs(5)
			.AssignValue "planetid", oRs(6)

			select case oRs(14)
				case rHostile, rWar
					.AssignValue "planetname", oRs(15)
				case rFriend, rAlliance, rSelf
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

			'if isNull(oRs(13)) then .Parse "message.new"

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

			if not IsNull(oRs(32)) then .AssignValue "building", getBuildingLabel(oRs(32))

			.Parse "message." & oRs(0)*100+oRs(1)
			.Parse "message"
		end with

		oRs.movenext
	wend
	
	content.Parse "tabnav.000"
	content.Parse "tabnav.100"
	content.Parse "tabnav.200"
	content.Parse "tabnav.800"
	content.Parse "tabnav"

	content.Parse ""
	display(content)
end function

dim cat
cat = ToInt(Request.QueryString("cat"), 0)

if IsNull(AllianceId) then RedirectTo "alliance.asp"
if not oAllianceRights("can_see_reports") then RedirectTo "alliance.asp"

display_reports cat

%>