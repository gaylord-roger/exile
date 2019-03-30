<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "merchants.buy"

' display market for current player's planets
sub DisplayMarket()
	' get market template
	dim content
	set content = GetTemplate("market-buy")

	dim oRs, query, i, planet, count, total, subtotal

	planet = Trim(Request.QueryString("planet"))
	if planet <> "" then planet = " AND v.id=" & dosql(planet)

	Session("details") = "list planets"

	' retrieve ore, hydrocarbon, sales quantities on the planet

	query = "SELECT v.id, v.name, v.galaxy, v.sector, v.planet, v.ore, v.hydrocarbon, v.ore_capacity, v.hydrocarbon_capacity, v.planet_floor," &_
			" v.ore_production, v.hydrocarbon_production," &_
			" m.ore, m.hydrocarbon, m.ore_price, m.hydrocarbon_price," &_
			" int4(date_part('epoch', m.delivery_time-now()))," &_
			" sp_get_planet_blocus_strength(v.id) >= v.space," &_
			" workers, workers_for_maintenance," &_
			" (SELECT has_merchants FROM nav_galaxies WHERE id=v.galaxy) as has_merchants," &_
			" (sp_get_resource_price(" & UserId & ", v.galaxy)).buy_ore::real AS p_ore," &_
			" (sp_get_resource_price(" & UserId & ", v.galaxy)).buy_hydrocarbon AS p_hydrocarbon" &_
			" FROM vw_planets AS v" &_
			"	LEFT JOIN market_purchases AS m ON (m.planetid=v.id)" &_
			" WHERE floor > 0 AND v.ownerid="&UserId & planet &_
			" ORDER BY v.id"
	set oRs = oConn.Execute(query)

	total = 0
	count = 0
	i = 1
	while not oRs.EOF

		dim p_img
		p_img = 1+(oRs(9) + oRs(0)) mod 21
		if p_img < 10 then p_img = "0" & p_img

		content.AssignValue "index", i

		content.AssignValue "planet_img", p_img

		content.AssignValue "planet_id", oRs(0)
		content.AssignValue "planet_name", oRs(1)
		content.AssignValue "g", oRs(2)
		content.AssignValue "s", oRs(3)
		content.AssignValue "p", oRs(4)

		content.AssignValue "planet_ore", oRs(5)
		content.AssignValue "planet_hydrocarbon", oRs(6)

		content.AssignValue "planet_ore_capacity", oRs(7)
		content.AssignValue "planet_hydrocarbon_capacity", oRs(8)

		content.AssignValue "planet_ore_production", oRs(10)
		content.AssignValue "planet_hydrocarbon_production", oRs(11)

		' if ore/hydrocarbon quantity reach their capacity in less than 4 hours
		if oRs(5) > oRs(7)-4*oRs(10) then content.Parse "planet.high_ore_capacity"
		if oRs(6) > oRs(8)-4*oRs(11) then content.Parse "planet.high_hydrocarbon_capacity"

		content.AssignValue "ore_max", fix((oRs(7)-oRs(5))/1000)
		content.AssignValue "hydrocarbon_max", fix((oRs(8)-oRs(6))/1000)

		content.AssignValue "price_ore", Replace(oRs("p_ore"), ",", ".")
		content.AssignValue "price_hydrocarbon", Replace(oRs("p_hydrocarbon"), ",", ".")

		if not IsNull(oRs(12)) then
			content.AssignValue "buying_ore", oRs(12)
			content.AssignValue "buying_hydrocarbon", oRs(13)

			subtotal = oRs(12)/1000*oRs(14) + oRs(13)/1000*oRs(15)
			total = total + subtotal

			content.AssignValue "buying_price", subtotal

			content.Parse "planet.can_buy.buying"
			content.Parse "planet.can_buy"
		else
			content.AssignValue "ore", Request.Form("o" & oRs(0))
			content.AssignValue "hydrocarbon", Request.Form("h" & oRs(0))

			content.AssignValue "buying_price", 0

			if not oRs("has_merchants") then
				content.Parse "planet.cant_buy_merchants"
			elseif oRs(18) < oRs(19) / 2 then
				content.Parse "planet.cant_buy_workers"
			elseif oRs(17) then
				content.Parse "planet.cant_buy_enemy"
			else
				content.Parse "planet.can_buy.buy"
				content.Parse "planet.can_buy"

				count = count + 1
			end if
		end if

		if oRs(0) = CurrentPlanet then content.Parse "planet.highlight"

		content.Parse "planet"

		i = i + 1

		oRs.MoveNext
	wend


	if planet <> "" then
		showHeader = true
		selected_menu = "market.buy"

		content.Parse "planetid"
	else
		FillHeaderCredits
		content.AssignValue "total", total
		content.Parse "totalprice"
	end if


	if count > 0 then content.Parse "buy"

	content.Parse ""

	Display(content)
end sub


dim planetsArray, planetsCount

' execute buy orders
sub ExecuteOrder()
	dim query, oRs, i

	if Request.QueryString("a") <> "buy" then exit sub

	Session("details") = "Execute orders"

	dim planetid, ore, hydrocarbon, p_ore, p_hydro

	' for each planet owned, check what the player buys
	query = "SELECT id FROM nav_planet WHERE ownerid="&UserId
	set oRs = oConn.Execute(query)

	planetsArray = oRs.GetRows()
	planetsCount = UBound(planetsArray, 2)

	' set the timeout : 2 seconds per planet
	Server.ScriptTimeout = Server.ScriptTimeout + planetsCount*2

	for i = 0 to planetsCount
		planetid = planetsArray(0, i)

		' retrieve ore & hydrocarbon quantities
		ore = ToInt(Request.Form("o" & planetid), 0)
		hydrocarbon = ToInt(Request.Form("h" & planetid), 0)

		if ore > 0 or hydrocarbon > 0 then

			query = "SELECT * FROM sp_buy_resources(" & UserID & "," & planetid & "," & ore*1000 & "," & hydrocarbon*1000 & ")"
			Session("details") = query
			oConn.Execute query, , adExecuteNoRecords
			Session("details") = "done:"&query
		end if
	next
end sub

ExecuteOrder()

DisplayMarket()
%>