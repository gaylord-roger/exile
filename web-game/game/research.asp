<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "research"

function HasEnoughFunds(credits)
	HasEnoughFunds = credits <= 0 or oPlayerInfo("credits") >= credits
end function

' List all the available researches
sub ListResearches()
	dim query, oRs
	dim underResearchCount

	' count number of researches pending
	set oRs = oConn.Execute("SELECT int4(count(1)) FROM researches_pending WHERE userid=" & UserId & " LIMIT 1")
	underResearchCount = oRs(0)

	' list things that can be researched
	query = "SELECT researchid, category, total_cost, total_time, level, levels, researchable, buildings_requirements_met, status," &_
			" (SELECT looping FROM researches_pending WHERE researchid = t.researchid AND userid=" & UserId & ") AS looping," &_
			" expiration_time IS NOT NULL" &_
			" FROM sp_list_researches(" & UserId & ") AS t" &_
			" WHERE level > 0 OR (researchable AND planet_elements_requirements_met)"
	set oRs = oConn.Execute(query)

	dim content
	set content = GetTemplate("research")

	content.AssignValue "userid", UserId

	dim category, lastCategory, itemCount
	if not oRs.EOF then
		category = oRs(1)
		lastCategory = category
	end if

	' number of items in category
	itemCount = 0

	while not oRs.EOF
		category = oRs(1)

		if category <> lastCategory then
			content.Parse "category.category" & lastcategory
			content.Parse "category"
			lastCategory = category
			itemCount = 0
		end if

		itemCount = itemCount + 1

		content.AssignValue "id", oRs(0)
		content.AssignValue "name", getResearchLabel(oRs(0))
		content.AssignValue "credits", oRs(2)
		content.AssignValue "nextlevel", oRs(4)+1
		content.AssignValue "level", oRs(4)
		content.AssignValue "levels", oRs(5)
		content.AssignValue "description", getResearchDescription(oRs(0))

		dim status
		status = oRs(8)

		' if status is not null then this research is under way
		if status then
			if status < 0 then status = 0

			content.Parse "category.research.leveling"

			content.AssignValue "remainingtime", status

			if oRs(9) then
				content.Parse "category.research.auto"
			else
				content.Parse "category.research.manual"
			end if

			content.Parse "category.research.cost"
			content.Parse "category.research.countdown"
			content.Parse "category.research.researching"
		else
			content.Parse "category.research.level"

			if (oRs(4) < oRs(5) or oRs(10)) then
				content.AssignValue "time", oRs(3)
				content.Parse "category.research.researchtime"

				if not oRs(6) or not oRs(7) then
					content.Parse "category.research.notresearchable"
				elseif underResearchCount > 0 then
					content.Parse "category.research.busy"
				elseif not HasEnoughFunds(oRs(2)) then
					content.Parse "category.research.notenoughmoney"
				else
					content.Parse "category.research.research"
				end if

				content.Parse "category.research.cost"
			else
				content.Parse "category.research.nocost"
				content.Parse "category.research.noresearchtime"
				content.Parse "category.research.complete"
			end if
		end if

		content.Parse "category.research"

		oRs.MoveNext
	wend

	if itemCount > 0 then content.Parse "category.category" & category

	content.Parse "category"
	content.Parse ""

	FillHeaderCredits

	Display(content)
end sub

sub StartResearch(ResearchId)
	oConn.Execute "SELECT * FROM sp_start_research(" & UserId & ", " & ResearchId & ", false)", , adExecuteNoRecords
end sub

sub CancelResearch(ResearchId)
	oConn.Execute "SELECT * FROM sp_cancel_research(" & UserId & ", " & ResearchId & ")", , adExecuteNoRecords
end sub

oConn.Execute("SELECT sp_update_researches(" & UserID & ")")

dim Action, ResearchId
Action = lcase(Request.QueryString("a"))
ResearchId = ToInt(Request.QueryString("r"), 0)

if ResearchId <> 0 then

	select case Action
		case "research"
			StartResearch(ResearchId)
		case "cancel"
			CancelResearch(ResearchId)
		case "continue"
			oConn.Execute "UPDATE researches_pending SET looping=true WHERE userid=" & UserId & " AND researchid=" & ResearchId, , adExecuteNoRecords
		case "stop"
			oConn.Execute "UPDATE researches_pending SET looping=false WHERE userid=" & UserId & " AND researchid=" & ResearchId, , adExecuteNoRecords
	end select
end if

ListResearches()

%>