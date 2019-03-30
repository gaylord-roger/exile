<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "mercenary"

const cost_lvl_0 = 2000
const cost_lvl_1 = 10000
const cost_lvl_2 = 30000
const cost_lvl_3 = 60000

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
	set content = GetTemplate("mercenary-spy-planet")
	
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
' Retrieve info about a planet
' 
sub SpyPlanet()

	dim g, s, p

	g = ToInt(Request.Form("g"), 0)
	s = ToInt(Request.Form("s"), 0)
	p = ToInt(Request.Form("p"), 0)


	'On Error Resume Next
	'err.clear

	typ = 3

'	if Session("privilege") > 100 then response.write "1"

	if Session("privilege") < 100 then

	set oRs = oConn.Execute("SELECT ownerid FROM nav_planet WHERE galaxy=" & g & " AND sector=" & s & " AND planet=" & p)

	if oRs.EOF then
		result_message = e_planet_not_exists
		exit sub
	elseif oRs(0) = UserId then
		result_message = e_own_nation_planet
		exit sub
	end if

	end if


'	if Session("privilege") > 100 then response.write "spy " & g & ":" & s & ":" & p & "<br/>"


	'
	' Begin transaction
	'
	oConn.BeginTrans

'	if Session("privilege") > 100 then response.write "2"

	set oRs = oConn.Execute("SELECT sp_create_spy('" & UserID & "', int2(" & typ & "), int2(" & level & ") )")
	reportid = oRs(0)
	if reportid < 0 then
		result_message = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

'	if Session("privilege") > 100 then response.write "spy id :" & reportid & "<br/>"

	select case level
		case 0
			spottedChance = 0.1
			getinfoModifier = 0.10
			cost = cost_lvl_0
			spyingTime = 15
		case 1
			spottedChance = 0.01
			getinfoModifier = 0.05
			cost = cost_lvl_1
			spyingTime = 30
		case 2
			spottedChance = 0.005
			getinfoModifier = 0.01
			cost = cost_lvl_2
			spyingTime = 45
		case 3
			spottedChance = 0.0025
			getinfoModifier = 0
			cost = cost_lvl_3
			spyingTime = 75
	end select

	if oPlayerInfo("credits") < cost then
		result_message = e_not_enough_money
		oConn.RollbackTrans
		exit sub
	end if

'	if Session("privilege") > 100 then response.write "3"

	' retrieve planet info list
	query = " SELECT id, name, ownerid, sp_get_user(ownerid), floor, space, floor_occupied, space_occupied,  " &_
				" COALESCE((SELECT SUM(quantity*signature) " &_
				" FROM planet_ships " &_
				" LEFT JOIN db_ships ON (planet_ships.shipid = db_ships.id) " &_
				" WHERE planet_ships.planetid=vw_planets.id),0), " &_
			" ore, hydrocarbon, ore_capacity, hydrocarbon_capacity, ore_production, hydrocarbon_production, " &_
			" energy_consumption, energy_production, " &_
			" radar_strength, radar_jamming, colonization_datetime, orbit_ore, orbit_hydrocarbon, " &_
			" workers, workers_capacity, scientists, scientists_capacity, soldiers, soldiers_capacity, " &_
			" pct_ore, pct_hydrocarbon" &_
			" FROM vw_planets " &_
			" WHERE galaxy=" & g & " AND sector=" & s & " AND planet=" & p
	
	set oRs = oConn.Execute(query)
	if oRs.EOF then
		result_message = e_planet_not_exists
		oConn.RollbackTrans
		exit sub
	end if

'	if Session("privilege") > 100 then response.write "spy : planet exists" & "<br/>"

	if not oRs.EOF then

		dim planet, qty, planetname

		planet = oRs(0)

'		if Session("privilege") > 100 then response.write "4"

		if not isNull(oRs(2)) then
		'
		' somebody owns this planet, so the spy can retrieve several info on it
		'
			' retrieve ownerid and planetname
			id = oRs(2)
			if not isNull(oRs(1)) then
				planetname = dosql(oRs(1))
			else
				planetname = "''"
			end if

'	if Session("privilege") > 100 then response.write "5"

			' set the owner of the planet as the target nation
			oConn.Execute "UPDATE spy SET target_id=" & id & " WHERE id=" & reportid,, AdExecuteNoRecords
			if err.Number <> 0 then
				result_message = e_general_error
				oConn.RollbackTrans
				exit sub
			end if

'	if Session("privilege") > 100 then response.write "spy : retrieve basic <br/>"

			' basic info retrieved by all spies
			query = " INSERT INTO spy_planet(spy_id,  planet_id,  planet_name, owner_name, floor, space, pct_ore, pct_hydrocarbon, ground ) " &_
					" VALUES ("& reportid &", " & sqlValue(oRs(0)) & "," & planetname &"," & sqlValue(oRs(3)) &"," &_
					sqlValue(oRs(4)) & "," & sqlValue(oRs(5)) & "," & sqlValue(oRs(28)) & "," & sqlValue(oRs(29)) & "," & sqlValue(oRs(8)) & ")"

'	if Session("privilege") > 100 then response.write "spy : basic retrieved <br/>"

			oConn.Execute query, , adExecuteNoRecords
			if err.Number <> 0 then
				result_message = e_general_error
				oConn.RollbackTrans
				exit sub
			end if

'	if Session("privilege") > 100 then response.write "spy : basic retrieved <br/>"

			' common info retrieved by spies which level >= 0 (actually, all)
			if level >= 0 then
				query = " UPDATE spy_planet SET"&_
						" radar_strength=" & sqlValue(oRs(17)) & ", radar_jamming=" & sqlValue(oRs(18)) &_
						", orbit_ore=" & sqlValue(oRs(20)) & ", orbit_hydrocarbon=" & sqlValue(oRs(21)) &_
						" WHERE spy_id=" & reportid & " AND planet_id=" & sqlValue(oRs(0))

				oConn.Execute query,, adExecuteNoRecords
				if err.Number <> 0 then
					result_message = e_general_error
					oConn.RollbackTrans
					exit sub
				end if
			end if

			' uncommon info retrieved by skilled spies with level >= 1 : ore, hydrocarbon, energy
			if level >= 1 then 
				query = "UPDATE spy_planet SET"&_
						" ore=" & sqlValue(oRs(9)) & ", hydrocarbon=" & sqlValue(oRs(10)) &_
						", ore_capacity=" & sqlValue(oRs(11)) & ", hydrocarbon_capacity=" & sqlValue(oRs(12)) &_
						", ore_production=" & sqlValue(oRs(13)) & ", hydrocarbon_production=" & sqlValue(oRs(14)) &_
						", energy_consumption=" & sqlValue(oRs(15)) & ", energy_production=" & sqlValue(oRs(16)) &_
						" WHERE spy_id=" & reportid & " AND planet_id=" & sqlValue(oRs(0))

				oConn.Execute query,, adExecuteNoRecords
				if err.Number <> 0 then
					result_message = e_general_error
					oConn.RollbackTrans
					exit sub
				end if
			end if


			if level >= 3 then
				'
				' rare info that can be retrieved by veteran spies only : workers, scientists, soldiers
				'
				query = "UPDATE spy_planet SET"&_
						" workers=" & sqlValue(oRs(22)) & ", workers_capacity=" & sqlValue(oRs(23)) & ", " &_
						" scientists=" & sqlValue(oRs(24)) & ", scientists_capacity=" & sqlValue(oRs(25)) & ", " &_
						" soldiers=" & sqlValue(oRs(26)) & ", soldiers_capacity=" & sqlValue(oRs(27)) &_
						" WHERE spy_id=" & reportid & " AND planet_id=" & sqlValue(oRs(0))

				oConn.Execute query,, adExecuteNoRecords
				if err.Number <> 0 then
					result_message = e_general_error
					oConn.RollbackTrans
					exit sub
				end if

'	if Session("privilege") > 100 then response.write "spy id : addind buildings <br/>"

				'
				' Add the buildings of the planet under construction
				'
				query = "SELECT planetid, id, build_status, quantity, construction_maximum " &_
						" FROM vw_buildings AS b " &_
						" WHERE planetid=" & planet & " AND build_status IS NOT NULL"

				set oRs = oConn.Execute(query)
				if err.Number <> 0 then
					result_message = e_general_error
					oConn.RollbackTrans
					exit sub
				end if

				i=0
				while not oRs.EOF 
					rand1 = Rnd
					rand2 = Rnd
					
					' test is the spy is spotted
					if rand2 < spottedChance then spotted = true

					' test if info is correctly retrieved by the spy (error probability increase for each new info)
					qty = oRs(3)

					if rand1 < ( getinfoModifier * i ) and oRs(4) <> 1 then
						' if construction_maximum = 1 then error is impossible : if there is 1 city, it can't exists more or less
						' info are always retrieved, but the spy may give a wrong number of constructions ( actually right number +/- 50% )

						' calculate maximum and minimum possible numbers of buildings
						rndmax = int(oRs(3)*1.5)
						if rndmax <= oRs(3) then rndmax = rndmax + 1
						rndmax = Min(rndmax, oRs(4))
						rndmin = int(oRs(3)*0.5)
						if rndmin < 1 then rndmin = 1
						qty = Int((rndmax-rndmin+1)*Rnd+rndmin)
					End if

					query = "INSERT INTO spy_building(spy_id, planet_id, building_id, endtime, quantity) " &_
							" VALUES (" & reportid & ", " & oRs(0) & ", " & oRs(1) & ", now() + " & oRs(2) & "* interval '1 second', " & qty & " )"

					oConn.Execute query, , adExecuteNoRecords
					if err.Number <> 0 then
						result_message = e_general_error
						oConn.RollbackTrans
						exit sub
					end if

					oRs.MoveNext
					i = i + 1
				wend
			end if


			if level >= 2 then

				'
				' Add the buildings of the planet
				'
				query = " SELECT planetid, id, quantity, construction_maximum " &_
						" FROM vw_buildings" &_
						" WHERE planetid=" & planet & " AND quantity <> 0 AND build_status IS NULL"
				set oRs = oConn.Execute(query)
				if err.Number <> 0 then
					result_message = e_general_error
					oConn.RollbackTrans
					exit sub
				end if

				while not oRs.EOF
					rand1 = Rnd
					rand2 = Rnd
					dim rand3, rndmax, rndmin
					
					' test if the spy is spotted
					if rand2 < spottedChance then spotted = true

					' test if info is correctly retrieved by the spy (error probability increase for each new info)
					qty = oRs(2)

					if rand1 < ( getinfoModifier * i ) and oRs(3) <> 1 then
						' if construction_maximum = 1 then error is impossible : if there is 1 city, it can't exists more or less
						' info are always retrieved, but the spy may give a wrong number of constructions ( actually right number +/- 50% )

						' calculate maximum and minimum possible numbers of buildings
						rndmax = int(oRs(2)*1.5)
						if rndmax <= oRs(2) then rndmax = rndmax + 1
						rndmax = Min(rndmax, oRs(3))
						rndmin = int(oRs(2)*0.5)
						if rndmin < 1 then rndmin = 1
						qty = Int((rndmax-rndmin+1)*Rnd+rndmin)
					end if

					query = " INSERT INTO spy_building(spy_id, planet_id, building_id, quantity) " &_
							" VALUES(" & reportid & ", " & oRs(0) & ", " & oRs(1) & ", " & qty & " )"

					oConn.Execute query, , adExecuteNoRecords
					if err.Number <> 0 then
						result_message = e_general_error
						oConn.RollbackTrans
						exit sub
					end if

					oRs.MoveNext
					i = i + 1
				wend

			end if

		else
			'
			' nobody own this planet
			'
			query = " INSERT INTO spy_planet(spy_id, planet_id, floor, space) " &_
					" VALUES("& reportid &", " & sqlValue(oRs(0)) &", " & sqlValue(oRs(4)) &", " & sqlValue(oRs(5)) &") "
			oConn.Execute query ,, adExecuteNoRecords
			if err.Number <> 0 then
				result_message = e_general_error
				oConn.RollbackTrans
				exit sub
			end if
		end if
	end if


	'
	' Add spy reports in report list
	'
	query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, planetid) " &_
			" VALUES(" & UserID & ", " & category & ", " & typ*10 & ", now()+" & spyingTime & "*interval '1 minute', " & reportid & ", " & planet & ") "

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		result_message = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	' update report if spy has been spotted
	if spotted and Session("privilege") < 100 then
		query = "UPDATE spy SET" &_
				" spotted=" & spotted &_
				" WHERE id=" & reportid & " AND userid=" & UserID 

		oConn.Execute query, , adExecuteNoRecords
		if err.Number <> 0 then
			result_message = e_general_error
			oConn.RollbackTrans
			exit sub
		end if


		' add report in spied nation's report list
		query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, planetid, userid) " &_
				" VALUES(" & id & ", " & category & ", " & typ & ", now()+" & spyingTime & "*interval '30 seconds', " & reportid &_
						", " & planet & ", " & UserID & ") "

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

if Request.QueryString("a") = "spy" then SpyPlanet

DisplayIntelligence

%>