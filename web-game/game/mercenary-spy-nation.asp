<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "mercenary"

const cost_lvl_0 = 5000
const cost_lvl_1 = 15000
const cost_lvl_2 = 45000
const cost_lvl_3 = 120000

const e_general_error = "unexpected_error"
const e_not_enough_money = "not_enough_credits"
const e_planet_not_exists = "planet_not_found"
const e_own_nation_planet = "own_planet"

dim result_message
result_message = ""


function sqlValue(value)
	if isNull(value) then
		sqlValue = "NULL"
	else
		sqlValue = "'"&value&"'"
	end if
end function

'
' display mercenary service page
'
sub DisplayIntelligence()
	dim content, query, oRs
	set content = GetTemplate("mercenary-spy-nation")
	
	' Assign service costs
	content.AssignValue "cost_lvl_0", cost_lvl_0
	content.AssignValue "cost_lvl_1", cost_lvl_1
	content.AssignValue "cost_lvl_2", cost_lvl_2
	content.AssignValue "cost_lvl_3", cost_lvl_3

	' display message
	if result_message <> "" then
		content.Parse "message." & result_message
		content.Parse "message"
	end if

	content.Parse ""

	FillHeaderCredits

	display(content)
end sub

' level : level of the recruited spy, determine spottedChance and -Modifier values
'  - spottedChance : chance that the spy has to be spotted per planet/fleet/building spied
'  - getinfoModifier : chance that the spy retrieve common info
'  - getmoreModifier : chance the the spy retrieve rare info
' spotted : set to TRUE if spy has been spotted
' id : spied user id
' nation : spied user name
dim level, spottedChance, getinfoModifier, getmoreModifier, spotted, id, nation, spyingTime

' category : intelligence category id for reports.asp
' type : action id for reports.asp
' cost : action cost ; determined by action & level
dim reportid, category, typ, cost

dim query, oRs, rand1, rand2, i, k, h, j


'
' Retrieve info about a nation
'
sub SpyNation()

	'On Error Resume Next
	err.clear

	typ = 1

	nation = Request.Form("nation_name")
	set oRs = oConn.Execute("SELECT id FROM users WHERE (privilege=-2 OR privilege=0) AND upper(login) = upper(" & dosql(nation) & ")")
	if oRs.EOF then
		result_message = e_player_not_exists
		exit sub
	else
		id = oRs(0)
		if id = UserId then
			result_message = e_own_nation_planet
			exit sub
		end if
	end if


	'
	' Begin transaction
	'
	oConn.BeginTrans			

	set oRs = oConn.Execute("SELECT sp_create_spy('" & UserID & "', int2(" & typ & "), int2(" & level & ") )")
	reportid = oRs(0)
	if reportid < 0 then
		result_message = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	oConn.Execute "UPDATE spy SET target_id=" & id & " WHERE id=" & reportid,, AdExecuteNoRecords
	if err.Number <> 0 then
		result_message = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	select case level
		case 0
			spottedChance = 0.04
			getinfoModifier = 0.10
			cost = cost_lvl_0
			spyingTime = 30
		case 1
			spottedChance = 0.02
			getinfoModifier = 0.05
			cost = cost_lvl_1
			spyingTime = 45
		case 2
			spottedChance = 0.009
			getinfoModifier = 0.01
			cost = cost_lvl_2
			spyingTime = 60
		case 3
			spottedChance = 0.005
			getinfoModifier = 0
			cost = cost_lvl_3
			spyingTime = 90
	end select


	dim planet_limit, nb_planet
	nb_planet = 0
	select case level
		case 0
			planet_limit = 5
		case 1
			planet_limit = 15
		case 2
			planet_limit = 20
		case 3
			planet_limit = 0 ' means no limit
	end select


	'
	' retrieve nation planet list and fill report
	'
	query = " SELECT id, name, floor, space, pct_ore, pct_hydrocarbon, " &_
				" COALESCE((SELECT SUM(quantity*signature) " &_
				" FROM planet_ships " &_
				" LEFT JOIN db_ships ON (planet_ships.shipid = db_ships.id) " &_
				" WHERE planet_ships.planetid=vw_planets.id),0) " &_
			" FROM vw_planets " &_
			" WHERE ownerid=" & id &_
			" ORDER BY random() "
	
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		rand1 = Rnd
		rand2 = Rnd
		' test is the spy is spotted
		if rand2 < spottedChance then spotted = true

		' test if info is retrieved by the spy (failure probability increase for each new info)
		if rand1 < ( 1 - ( getinfoModifier * i ) ) and (planet_limit=0 or nb_planet < planet_limit) then
			' add planet to the spy report
			query = " INSERT INTO spy_planet(spy_id, planet_id, planet_name, floor, space, pct_ore, pct_hydrocarbon, ground) " &_
					" VALUES("& reportid &"," & oRs(0) &"," & dosql(oRs(1)) &"," & oRs(2) & "," & oRs(3) & "," & oRs(4) & "," & oRs(5) & "," & oRs(6) &")"
			oConn.Execute query , , adExecuteNoRecords
			if err.Number <> 0 then
				result_message = e_general_error
				oConn.RollbackTrans
				exit sub
			end if

			nb_planet = nb_planet + 1
		end if
		oRs.MoveNext
		i = i + 1
	wend

	'
	' For veteran spy, collect additionnal research infos
	'
	if level >= 3 then
		query = " SELECT researchid, level " &_
				" FROM sp_list_researches(" & id & ") " &_
				" WHERE level > 0" &_
				" ORDER BY researchid"
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			' test is the spy is spotted
			if rand2 < spottedChance then spotted = true

			' add research info to spy report
			query = " INSERT INTO spy_research(spy_id,  research_id,  research_level) " &_
					" VALUES("& reportid &", " & oRs(0) &", " & oRs(1) &") "
			oConn.Execute query , , adExecuteNoRecords
			if err.Number <> 0 then
				result_message = e_general_error
				oConn.RollbackTrans
				exit sub
			end if
			
			oRs.MoveNext
			i = i + 1
		wend
	end if

	'
	' Add spy reports in report list
	'
	query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, userid) " &_
			" VALUES(" & UserID & ", " & category & ", " & typ*10 & ", now()+" & spyingTime+nb_planet & "*interval '1 minute', " & reportid & ", " & id & ") "

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		result_message = e_general_error
		oConn.RollbackTrans
		exit sub
	end if
	
	if spotted and Session("privilege") < 100 then
		' update report if spy has been spotted
		query = " UPDATE spy " &_
				" SET spotted=" & spotted &_
				" WHERE id=" & reportid & " AND userid=" & UserID 

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			result_message = e_general_error
			oConn.RollbackTrans
			exit sub
		end if


		' add report in spied nation's report list
		query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, userid) " &_
				" VALUES(" & id & ", " & category & ", " & typ & ", now()+" & spyingTime+nb_planet & "*interval '30 seconds', " & reportid & ", " & UserID & ") "

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			result_message = e_general_error
			oConn.RollbackTrans
			exit sub
		end if
	end if
	
	'
	' withdraw the operation cost from player's credits account
	'
	query = "UPDATE users SET credits=credits-" & cost & " WHERE id=" & UserID

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		result_message = e_not_enough_money
		oConn.RollbackTrans
		exit sub
	end if
	

	'
	' Commit transaction
	'
	oConn.CommitTrans

	result_message = "spying"
end sub

exit

'
' process page
'
Randomize

category = 8

spotted = false

level = ToInt(Request.Form("level"), 0)

if Request.QueryString("a") = "spy" then SpyNation

DisplayIntelligence

%>