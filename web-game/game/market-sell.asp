<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "merchants.sell"

' display market for current player's planets
sub DisplayMarket()

	Session("details") = "Display market : retrieve prices"

	' get market template
	dim content
	set content = GetTemplate("market-sell")

	dim oRs, query, i, planet, count, total, subtotal

	planet = Trim(Request.QueryString("planet"))
	if planet <> "" then planet = " AND v.id=" & dosql(planet)

	Session("details") = "list planets"

	' retrieve ore, hydrocarbon, sales quantities on the planet

	query = "SELECT id, name, galaxy, sector, planet, ore, hydrocarbon, ore_capacity, hydrocarbon_capacity, planet_floor," &_
			" ore_production, hydrocarbon_production," &_
			" (sp_market_price((sp_get_resource_price(0, galaxy)).sell_ore, planet_stock_ore))," &_
			" (sp_market_price((sp_get_resource_price(0, galaxy)).sell_hydrocarbon, planet_stock_hydrocarbon))" &_
			" FROM vw_planets AS v" &_
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

		content.AssignValue "ore_price", oRs(12)
		content.AssignValue "hydrocarbon_price", oRs(13)

		content.AssignValue "ore_price2", Replace(oRs(12), ",", ".")
		content.AssignValue "hydrocarbon_price2", Replace(oRs(13), ",", ".")

		' if ore/hydrocarbon quantity reach their capacity in less than 4 hours
		if oRs(5) > oRs(7)-4*oRs(10) then content.Parse "planet.high_ore_capacity"
		if oRs(6) > oRs(8)-4*oRs(11) then content.Parse "planet.high_hydrocarbon_capacity"

		content.AssignValue "ore_max", min(10000, fix(oRs(5)/1000))
		content.AssignValue "hydrocarbon_max", min(10000, fix(oRs(6)/1000))


		'content.AssignValue "ore", Request.Form("o" & oRs(0))
		'content.AssignValue "hydrocarbon", Request.Form("h" & oRs(0))

		content.AssignValue "selling_price", 0

		count = count + 1

		if oRs(0) = CurrentPlanet then content.Parse "planet.highlight"

		content.Parse "planet"

		i = i + 1

		oRs.MoveNext
	wend


	if planet <> "" then
		showHeader = true
		selected_menu = "market.sell"

		content.Parse "planetid"
	else
		FillHeaderCredits
		content.AssignValue "total", total
		content.Parse "totalprice"
	end if


	if count > 0 then content.Parse "sell"

	content.Parse ""

	Display(content)
end sub


dim planetsArray, planetsCount

' execute sell orders
sub ExecuteOrder()
	dim query, oRs, i

	if Request.QueryString("a") <> "sell" then exit sub

	Session("details") = "Execute orders"

	dim planetid, ore, hydrocarbon, p_ore, p_hydro

	' retrieve the prices given when we last asked for the market prices
	'RetrievePrices()

	' for each planet owned, check what the player sells
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
			query = "SELECT sp_market_sell(" & UserID & "," & planetid & "," & ore*1000 & "," & hydrocarbon*1000 & ")"
			Session("details") = query
			oConn.Execute query, , adExecuteNoRecords
			Session("details") = "done:"&query
		end if
	next

	if Request.Form("rel") <> 1 then log_notice "market-sell.asp", "hidden value is missing from form data", 1
end sub

ExecuteOrder()

DisplayMarket()
%>