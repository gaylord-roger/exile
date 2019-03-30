<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "planets"

sub ListPlanets()
	dim content
	set content = GetTemplate("planets")

	'
	' Setup column ordering
	'
	dim col, orderby, reversed
	col = ToInt(Request.QueryString("col"), 0)

	if col < 0 or col > 4 then col = 0

	select case col
		case 0
			orderby = "id"
		case 1
			orderby = "upper(name)"
		case 2
			orderby = "ore_production"
		case 3
			orderby = "hydrocarbon_production"
		case 4
			orderby = "energy_consumption/(1.0+energy_production)"
		case 5
			orderby = "mood"
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", upper(name)"


	dim oRs, query

	query = "SELECT t.id, name, galaxy, sector, planet," &_
			"ore, ore_production, ore_capacity," &_
			"hydrocarbon, hydrocarbon_production, hydrocarbon_capacity," &_
			"workers-workers_busy, workers_capacity," &_
			"energy_production - energy_consumption, energy_capacity," &_
			"floor, floor_occupied," &_
			"space, space_occupied," &_
			"commanderid, (SELECT name FROM commanders WHERE id = t.commanderid) AS commandername," &_
			"mod_production_ore, mod_production_hydrocarbon, workers, t.soldiers, soldiers_capacity," &_
			"t.scientists, scientists_capacity, workers_for_maintenance, planet_floor, mood," & _
			"energy, mod_production_energy, upkeep, energy_consumption," &_
			" (SELECT int4(COALESCE(sum(scientists), 0)) FROM planet_training_pending WHERE planetid=t.id) AS scientists_training," &_
			" (SELECT int4(COALESCE(sum(soldiers), 0)) FROM planet_training_pending WHERE planetid=t.id) AS soldiers_training," &_
			" credits_production, credits_random_production, production_prestige" &_
			" FROM vw_planets AS t" &_
			" WHERE planet_floor > 0 AND planet_space > 0 AND ownerid="&UserID&_
			" ORDER BY "&orderby

	set oRs = oConn.Execute(query)

	dim ore_level, hydrocarbon_level, energy_level, mood_delta

	with content
		while not oRs.EOF
			mood_delta = 0

			.AssignValue "planet_img", planetimg(oRs(0), oRs(29))

			.AssignValue "planet_id", oRs(0)
			.AssignValue "planet_name", oRs(1)

			.AssignValue "g", oRs(2)
			.AssignValue "s", oRs(3)
			.AssignValue "p", oRs(4)

			' ore
			.AssignValue "ore", oRs(5)
			.AssignValue "ore_production", oRs(6)
			.AssignValue "ore_capacity", oRs(7)

			' compute ore level : ore / capacity
			ore_level = getpercent(oRs(5), oRs(7), 10)

			if ore_level >= 90 then
				.Parse "planet.high_ore"
			elseif ore_level >= 70 then
				.Parse "planet.medium_ore"
			else
				.Parse "planet.normal_ore"
			end if


			' hydrocarbon
			.AssignValue "hydrocarbon", oRs(8)
			.AssignValue "hydrocarbon_production", oRs(9)
			.AssignValue "hydrocarbon_capacity", oRs(10)

			' compute hydrocarbon level : hydrocarbon / capacity
			hydrocarbon_level = getpercent(oRs(8), oRs(10), 10)

			if hydrocarbon_level >= 90 then
				.Parse "planet.high_hydrocarbon"
			elseif hydrocarbon_level >= 70 then
				.Parse "planet.medium_hydrocarbon"
			else
				.Parse "planet.normal_hydrocarbon"
			end if


			' energy
			.AssignValue "energy", oRs(31)
			.AssignValue "energy_production", oRs(13)
			.AssignValue "energy_capacity", oRs(14)
			
			' compute energy level : energy / capacity
			energy_level = getpercent(oRs(31), oRs(14), 10)

			.Parse "planet.normal_energy"

			dim credits
			credits = oRs("credits_production") + (oRs("credits_random_production") / 2)' - (oRs("upkeep") / 24)

			.AssignValue "credits", credits
			if credits < 0 then
				.Parse "planet.credits_minus"
			else
				.Parse "planet.credits_plus"
			end if

			.AssignValue "prestige", oRs("production_prestige")

			if oRs(13) < 0 then
				.Parse "planet.negative_energy_production"
			elseif oRs(32) >= 0 and oRs(23) >= oRs(28) then
				.Parse "planet.normal_energy_production"
			else
				.Parse "planet.medium_energy_production"
			end if


			' workers
			.AssignValue "workers", oRs(23)
			.AssignValue "workers_idle", oRs(11)
			.AssignValue "workers_capacity", oRs(12)

			' soldiers
			.AssignValue "soldiers", oRs(24)
			.AssignValue "soldiers_capacity", oRs(25)
			.AssignValue "soldiers_training", oRs("soldiers_training")
			if oRs("soldiers_training") > 0 then .Parse "planet.soldiers_training"

			 ' scientists
			.AssignValue "scientists", oRs(26)
			.AssignValue "scientists_capacity", oRs(27)
			.AssignValue "scientists_training", oRs("scientists_training")
			if oRs("scientists_training") > 0 then .Parse "planet.scientists_training"

			if oRs(23) < oRs(28) then .Parse "planet.workers_low"

			if oRs(24)*250 < oRs(23)+oRs(26) then .Parse "planet.soldiers_low"


			' mood
			if oRs(30) > 100 then
				.AssignValue "mood", 100
			else
				.AssignValue "mood", oRs(30)
			end if

			dim moodlevel
			moodlevel = round(oRs(30) / 10) * 10
			if moodlevel > 100 then moodlevel = 100

			.AssignValue "mood_level", moodlevel

			if not isnull(oRs(19)) then mood_delta = mood_delta + 1

			if oRs(24)*250 >= oRs(23)+oRs(26) then
				mood_delta = mood_delta + 2
			else
				mood_delta = mood_delta - 1
			end if

			.AssignValue "mood_delta", mood_delta
			if mood_delta > 0 then
				.Parse "planet.mood_plus"
			else
				.Parse "planet.mood_minus"
			end if


			' planet stats
			.AssignValue "floor_capacity", oRs(15)
			.AssignValue "floor_occupied", oRs(16)

			.AssignValue "space_capacity", oRs(17)
			.AssignValue "space_occupied", oRs(18)

			if oRs(19) then
				.AssignValue "commander_id", oRs(19)
				.AssignValue "commander_name", oRs(20)
				.Parse "planet.commander"
			else
				.Parse "planet.nocommander"
			end if


			if oRs(21) >= 0 and oRs(23) >= oRs(28) then
				.Parse "planet.normal_ore_production"
			else
				.Parse "planet.medium_ore_production"
			end if

			if oRs(22) >= 0 and oRs(23) >= oRs(28) then
				.Parse "planet.normal_hydrocarbon_production"
			else
				.Parse "planet.medium_hydrocarbon_production"
			end if

			.AssignValue "upkeep_credits", oRs("upkeep")
			.AssignValue "upkeep_workers", oRs("workers_for_maintenance")
			.AssignValue "upkeep_soldiers", fix((oRs(23)+oRs(26)) / 250)

			if oRs(0) = CurrentPlanet then .Parse "planet.highlight"

			.Parse "planet"
			oRs.MoveNext
		wend

		.Parse ""
	end with

	Display(content)
end sub

ListPlanets()

%>