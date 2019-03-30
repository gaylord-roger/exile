<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "mercenary"

const nation_cost_lvl_0 = 5000
const nation_cost_lvl_1 = 15000
const nation_cost_lvl_2 = 45000
const nation_cost_lvl_3 = 120000

const e_no_error = 0
const e_general_error = 1
const e_not_enough_money = 2
const e_planet_not_exists = 3
const e_player_not_exists = 4
const e_own_nation_planet = 5

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
	content.AssignValue "nation_cost_lvl_0", nation_cost_lvl_0
	content.AssignValue "nation_cost_lvl_1", nation_cost_lvl_1
	content.AssignValue "nation_cost_lvl_2", nation_cost_lvl_2
	content.AssignValue "nation_cost_lvl_3", nation_cost_lvl_3

	' display message
	if result_message <> "" then
		content.Parse "message." & result_message
		content.Parse "message"
	end if

	content.Parse ""
	display(content)
end sub

' action : type of order
' level : level of the recruited spy, determine spottedChance and -Modifier values
'  - spottedChance : chance that the spy has to be spotted per planet/fleet/building spied
'  - getinfoModifier : chance that the spy retrieve common info
'  - getmoreModifier : chance the the spy retrieve rare info
' spotted : set to TRUE if spy has been spotted
' id : spied user id
' nation : spied user name
dim action, level, spottedChance, getinfoModifier, getmoreModifier, spotted, id, nation, spyingTime

' category : intelligence category id for reports.asp
' type : action id for reports.asp
' cost : action cost ; determined by action & level
dim reportid, category, typ, cost

dim query, oRs, rand1, rand2, i, k, h, j


'
' Retrieve info about a nation
'
sub SpyNation()

	On Error Resume Next
	err.clear

	typ = 1

	nation = Request.Form("nation_name")
	set oRs = oConn.Execute("SELECT id FROM users WHERE upper(login) = upper(" & dosql(nation) & ")")
	if oRs.EOF then
		intell_error = e_player_not_exists
		exit sub
	else
		id = oRs(0)
		if id = UserId then
			intell_error = e_own_nation_planet
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
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	oConn.Execute "UPDATE spy SET target_id=" & id & " WHERE id=" & reportid,, AdExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	select case level
		case 0
			spottedChance = 0.04
			getinfoModifier = 0.10
			cost = nation_cost_lvl_0
			spyingTime = 30
		case 1
			spottedChance = 0.02
			getinfoModifier = 0.05
			cost = nation_cost_lvl_1
			spyingTime = 45
		case 2
			spottedChance = 0.009
			getinfoModifier = 0.01
			cost = nation_cost_lvl_2
			spyingTime = 60
		case 3
			spottedChance = 0.005
			getinfoModifier = 0
			cost = nation_cost_lvl_3
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
	query = " SELECT id, name, floor, space, " &_
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
			query = " INSERT INTO spy_planet(spy_id,  planet_id,  planet_name,  floor,  space,  ground) " &_
					" VALUES("& reportid &", " & oRs(0) &", '" & oRs(1) &"', " & oRs(2) &", " & oRs(3) &", " & oRs(4) &") "
			oConn.Execute query , , adExecuteNoRecords
			if err.Number <> 0 then
				intell_error = e_general_error
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
				" WHERE level > 0 OR researchable " &_
				" ORDER BY researchid "
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			' test is the spy is spotted
			if rand2 < spottedChance then spotted = true

			' add research info to spy report
			query = " INSERT INTO spy_research(spy_id,  research_id,  research_level) " &_
					" VALUES("& reportid &", " & oRs(0) &", " & oRs(1) &") "
			oConn.Execute query , , adExecuteNoRecords
			if err.Number <> 0 then
				intell_error = e_general_error
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
		intell_error = e_general_error
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
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if


		' add report in spied nation's report list
		query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, userid) " &_
				" VALUES(" & id & ", " & category & ", " & typ & ", now()+" & spyingTime+nb_planet & "*interval '30 seconds', " & reportid & ", " & UserID & ") "

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if
	end if
	
	'
	' withdraw the operation cost from player's credits account
	'
	query = "UPDATE users SET" &_
			" credits=credits-" & cost &_
			" WHERE id=" & UserID 

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_not_enough_money
		oConn.RollbackTrans
		exit sub
	end if
	

	'
	' Commit transaction
	'
	oConn.CommitTrans
end sub


'
' Retrieve info about a nation's fleets
'
sub SpyFleets()

	On Error Resume Next
	err.clear

	typ = 2

	nation = Request.Form("nation_name")
	set oRs = oConn.Execute("SELECT id FROM users WHERE upper(login)=upper(" & dosql(nation) & ")")
	if oRs.EOF then
		intell_error = e_player_not_exists
		oConn.RollbackTrans
		exit sub
	else
		id = oRs(0)

		if id = UserId then
			intell_error = e_own_nation_planet
			exit sub
		end if
	end if

	'
	' Begin transaction
	'
	oConn.BeginTrans

	set oRs = oConn.Execute("SELECT sp_create_spy('" & UserID & "', '" & typ & "', '" & level & "' )")
	reportid = oRs(0)
	if reportid < 0 then
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	oConn.Execute "UPDATE spy SET target_id=" & id & " WHERE id=" & reportid,, AdExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

	select case level
		case 0
			spottedChance = 0.1
			getinfoModifier = 0.10
			cost = fleets_cost_lvl_0
			spyingTime = 15
		case 1
			spottedChance = 0.04
			getinfoModifier = 0.05
			cost = fleets_cost_lvl_1
			spyingTime = 30
		case 2
			spottedChance = 0.01
			getinfoModifier = 0.01
			cost = fleets_cost_lvl_2
			spyingTime = 45
		case 3
			spottedChance = 0.05
			getinfoModifier = 0
			cost = fleets_cost_lvl_3
			spyingTime = 75
	end select

	dim sig_limit, sig
	sig = 0
	select case level
		case 0
			sig_limit = 10000
		case 1
			sig_limit = 30000
		case 2
			sig_limit = 100000
		case 3
			sig_limit = 0 ' means no limit
	end select

	'
	' retrieve nation fleets list and fill report
	'
	query = " SELECT id, name, planet_galaxy, planet_sector, planet_planet, size, signature, " &_
			" destplanet_galaxy, destplanet_sector, destplanet_planet " &_
			" FROM vw_fleets " &_
			" WHERE ownerid=" & id &_
			" ORDER BY random() "
	
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		rand1 = Rnd
		rand2 = Rnd

		' For veteran spy, collect additionnal destination info for moving fleets
		if level > 1 AND not isNull(oRs(7)) then
			query = " INSERT INTO spy_fleet(spy_id, fleet_id, fleet_name, galaxy, sector, planet, size, signature, dest_galaxy, dest_sector, dest_planet) " &_
					" VALUES ("& reportid &", " & oRs(0) &", '" & oRs(1) &"', " & oRs(2) &", " & oRs(3) &", " & oRs(4) &", " & oRs(5) &", " & oRs(6) &", " & oRs(7) &", " & oRs(8) &", " & oRs(9) &") "
		else
			query = " INSERT INTO spy_fleet(spy_id, fleet_id, fleet_name, galaxy, sector, planet, signature) " &_
					" VALUES ("& reportid &", " & oRs(0) &", '" & oRs(1) &"', " & oRs(2) &", " & oRs(3) &", " & oRs(4) &", " & oRs(6) &") "
		end if
		
		' test is the spy is spotted
		if rand2 < spottedChance then spotted = true
		' test if info is retrieved by the spy (failure probability increase for each new info)
		if rand1 < ( 1 - ( getinfoModifier * i ) ) and (sig_limit=0 or sig < sig_limit) then
			' add fleet to the spy report
			oConn.Execute query, , adExecuteNoRecords
			if err.Number <> 0 then
				intell_error = e_general_error
				oConn.RollbackTrans
				exit sub
			end if
			sig = sig + oRs(6)
		End if
		oRs.MoveNext
		i = i + 1
	wend


	'
	' Add spy reports in report list
	'
	query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, userid) " &_
			" VALUES (" & UserID & ", " & category & ", " & typ*10 & ", now()+" & round(Spyingtime+log(sig)/log(5)) & "*interval '1 minute', " & reportid & ", " & id & ") "

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if


	' update report if spy has been spotted
	if spotted and Session("privilege") < 100 then
		query = " UPDATE spy SET spotted=" & spotted &_
				" WHERE id=" & reportid & " AND userid=" & UserID 

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if


		' add report in spied nation's report list
		query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, userid) " &_
				" VALUES (" & id & ", " & category & ", " & typ & ", now()+" & round(Spyingtime+log(sig)/log(5)) & "*interval '30 seconds', " & reportid & ", " & UserID & ") "

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if
	end if


	'
	' withdraw the operation cost from player's credits account
	'
	query = "UPDATE users SET" &_
			" credits=credits-" & cost &_
			" WHERE id=" & UserID 

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_not_enough_money
		oConn.RollbackTrans
		exit sub
	end if


	'
	' Commit transaction
	'
	oConn.CommitTrans
end sub


'
' Retrieve info about a planet
' 
sub SpyPlanet()

	dim g, s, p

	g = ToInt(Request.Form("g"), 0)
	s = ToInt(Request.Form("s"), 0)
	p = ToInt(Request.Form("p"), 0)


	On Error Resume Next
	err.clear

	typ = 3

'	if Session("privilege") > 100 then response.write "1"

	if Session("privilege") < 100 then

	set oRs = oConn.Execute("SELECT ownerid FROM nav_planet WHERE galaxy=" & g & " AND sector=" & s & " AND planet=" & p)

	if oRs.EOF then
		intell_error = e_planet_not_exists
		exit sub
	elseif oRs(0) = UserId then
		intell_error = e_own_nation_planet
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
		intell_error = e_general_error
		oConn.RollbackTrans
		exit sub
	end if

'	if Session("privilege") > 100 then response.write "spy id :" & reportid & "<br/>"

	select case level
		case 0
			spottedChance = 0.1
			getinfoModifier = 0.10
			cost = planet_cost_lvl_0
			spyingTime = 15
		case 1
			spottedChance = 0.01
			getinfoModifier = 0.05
			cost = planet_cost_lvl_1
			spyingTime = 30
		case 2
			spottedChance = 0.005
			getinfoModifier = 0.01
			cost = planet_cost_lvl_2
			spyingTime = 45
		case 3
			spottedChance = 0.0025
			getinfoModifier = 0
			cost = planet_cost_lvl_3
			spyingTime = 75
	end select

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
			" workers, workers_capacity, scientists, scientists_capacity, soldiers, soldiers_capacity " &_
			" FROM vw_planets " &_
			" WHERE galaxy=" & g & " AND sector=" & s & " AND planet=" & p
	
	set oRs = oConn.Execute(query)
	if oRs.EOF then
		intell_error = e_planet_not_exists
		oConn.RollbackTrans
		exit sub
	end if

'	if Session("privilege") > 100 then response.write "spy : planet exists" & "<br/>"

	if not oRs.EOF then

		dim planet, qty, planetname

		planet = oRs(0)

		if Session("privilege") > 100 then response.write "4"

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
				intell_error = e_general_error
				oConn.RollbackTrans
				exit sub
			end if

'	if Session("privilege") > 100 then response.write "spy : retrieve basic <br/>"

			' basic info retrieved by all spies
			query = " INSERT INTO spy_planet(spy_id,  planet_id,  planet_name, owner_name, floor,  space, ground ) " &_
					" VALUES ("& reportid &", " & sqlValue(oRs(0)) & "," & planetname &"," & sqlValue(oRs(3)) &"," &_
					sqlValue(oRs(4)) & "," & sqlValue(oRs(5)) & "," & sqlValue(oRs(8)) & ")"

'	if Session("privilege") > 100 then response.write "spy : basic retrieved <br/>"

			oConn.Execute query, , adExecuteNoRecords
			if err.Number <> 0 then
				intell_error = e_general_error
				oConn.RollbackTrans
				exit sub
			end if

'	if Session("privilege") > 100 then response.write "spy : basic retrieved <br/>"

			' common info retrieved by spies which level >= 0 (actually, all)
			if level >= 0 then
				query = " UPDATE spy_planet SET"&_
						" radar_strength=" & sqlValue(oRs(17)) & ", radar_jamming=" & sqlValue(oRs(18)) & ", " &_
						" orbit_ore=" & sqlValue(oRs(20)) & ", orbit_hydrocarbon=" & sqlValue(oRs(21)) &_
						" WHERE spy_id=" & reportid & " AND planet_id=" & sqlValue(oRs(0))

				oConn.Execute query,, adExecuteNoRecords
				if err.Number <> 0 then
					intell_error = e_general_error
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
					intell_error = e_general_error
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
					intell_error = e_general_error
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
					intell_error = e_general_error
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
						intell_error = e_general_error
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
					intell_error = e_general_error
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
						intell_error = e_general_error
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
				intell_error = e_general_error
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
		intell_error = e_general_error
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
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if


		' add report in spied nation's report list
		query = " INSERT INTO reports(ownerid, type, subtype, datetime, spyid, planetid, userid) " &_
				" VALUES(" & id & ", " & category & ", " & typ & ", now()+" & spyingTime & "*interval '30 seconds', " & reportid &_
						", " & planet & ", " & UserID & ") "

		oConn.Execute query , , adExecuteNoRecords
		if err.Number <> 0 then
			intell_error = e_general_error
			oConn.RollbackTrans
			exit sub
		end if
	end if
	
	'
	' withdraw the operation cost from player's credits account
	'
	query = "UPDATE users SET" &_
			" credits=credits-" & cost &_
			" WHERE id=" & UserID 

	oConn.Execute query , , adExecuteNoRecords
	if err.Number <> 0 then
		intell_error = e_not_enough_money
		oConn.RollbackTrans
		exit sub
	end if

	'
	' Commit transaction
	'
	oConn.CommitTrans
end sub

exit

'
' process page
'
Randomize

category = 8

spotted = false

action = Request.Form("spy")
level = ToInt(Request.Form("level"), 0)

select case action
	case "nation"
		SpyNation()

	case "fleets"
		SpyFleets()

	case "planet"
		SpyPlanet()
end select

DisplayIntelligence()


%>