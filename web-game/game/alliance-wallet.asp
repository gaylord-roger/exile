<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.wallet"


const e_no_error = 0
const e_not_enough_money = 1
const e_can_give_money_after_a_week = 2

dim money_error
money_error = e_no_error

function can_give_money()
	dim oRs
	set oRs = oConn.Execute("SELECT game_started < now() - INTERVAL '2 weeks' FROM users WHERE id=" & userid)

	can_give_money = not oRs.EOF and oRs(0)
end function

'
' Display the wallet page
'
sub DisplayPage(tpl, cat)
	dim content, oRs
	set content = GetTemplate("alliance-wallet")

	content.AssignValue "walletpage", cat

	set oRs = oConn.Execute("SELECT credits, tax FROM alliances WHERE id=" & AllianceId)
	content.AssignValue "credits", oRs(0)
	content.AssignValue "tax", oRs(1)/10

	if oPlayerInfo("planets") < 2 then content.Parse "notax"

	set oRs = oConn.Execute("SELECT COALESCE(sum(credits), 0) FROM alliances_wallet_journal WHERE allianceid=" & AllianceId & " AND datetime >= now()-INTERVAL '24 hours'")
	content.AssignValue "last24h", oRs(0)

	content.AssignValue "content", tpl.output

	select case money_error
		case e_not_enough_money
			content.Parse "not_enough_money"
		case e_can_give_money_after_a_week
			content.Parse "can_give_money_after_a_week"
	end select

	content.Parse "cat"&cat&".selected"

	content.Parse "cat1"
	if oAllianceRights("can_ask_money") then content.Parse "cat2"
	content.Parse "cat3"
	if oAllianceRights("can_change_tax_rate") then content.Parse "cat4"

	content.Parse ""
	
	display(content)
end sub

'
' Display a journal of the last money operations
' This is viewable by everybody
'
sub DisplayJournal(cat)
	dim content, i
	set content = GetTemplate("alliance-wallet-journal")
	content.AssignValue "walletpage", cat

	dim col, reversed, orderby
	col = Request.QueryString("col")
	if col < 1 or col > 4 then col = 1

	select case col
		case 1
			orderby = "datetime"
			reversed = true
		case 2
			orderby = "type"
			reversed = true
		case 3
			orderby = "upper(source)"
			reversed = true
		case 4
			orderby = "upper(destination)"
			reversed = true
		case 5
			orderby = "credits"
		case 6
			orderby = "upper(description)"
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", datetime DESC"

	dim oRs, query, displayGiftsRequests, displaySetTax, displayTaxes, displayKicksBreaks

	if Request.Form("refresh") <> "" then
		displayGiftsRequests = Request.Form("gifts") = 1
		displaySetTax = Request.Form("settax") = 1
		displayTaxes = Request.Form("taxes") = 1
		displayKicksBreaks = Request.Form("kicksbreaks") = 1

		query = "UPDATE users SET" &_
				" wallet_display[1]=" & displayGiftsRequests &_
				" ,wallet_display[2]=" & displaySetTax &_
				" ,wallet_display[3]=" & displayTaxes &_
				" ,wallet_display[4]=" & displayKicksBreaks &_
				" WHERE id=" & UserId
		oConn.Execute query, , adExecuteNoRecords
	else
		query = "SELECT COALESCE(wallet_display[1], true)," &_
				" COALESCE(wallet_display[2], true)," &_
				" COALESCE(wallet_display[3], true)," &_
				" COALESCE(wallet_display[4], true)" &_
				" FROM users" &_
				" WHERE id=" & UserId
		set oRs = oConn.Execute(query)

		displayGiftsRequests = oRs(0)
		displaySetTax = oRs(1)
		displayTaxes = oRs(2)
		displayKicksBreaks = oRs(3)
	end if

	if displayGiftsRequests then content.Parse "gifts_checked"
	if displaySetTax then content.Parse "settax_checked"
	if displayTaxes then content.Parse "taxes_checked"
	if displayKicksBreaks then content.Parse "kicksbreaks_checked"

	query = ""
	if not displayGiftsRequests then query = query & " AND type <> 0 AND type <> 3 AND type <> 20"
	if not displaySetTax then query = query & " AND type <> 4"
	if not displayTaxes then query = query & " AND type <> 1"
	if not displayKicksBreaks then query = query & " AND type <> 2 AND type <> 5 AND type <> 10 AND type <> 11"

	' List wallet journal
	query = "SELECT Max(datetime), userid, int4(sum(credits)), description, source, destination, type, groupid"&_
			" FROM alliances_wallet_journal"&_
			" WHERE allianceid=" & AllianceId & query & " AND datetime >= now()-INTERVAL '1 week'"&_
			" GROUP BY userid, description, source, destination, type, groupid"&_
			" ORDER BY Max(datetime) DESC"&_
			" LIMIT 500"

	set oRs = oConn.Execute(query)

	if oRs.EOF then content.Parse "noentries"

	i = 1
	while not oRs.EOF
		content.AssignValue "date", oRs(0).Value

		if oRs(2) > 0 then
			content.AssignValue "income", oRs(2)
			content.AssignValue "outcome", 0
		else
			content.AssignValue "income", 0
			content.AssignValue "outcome", -oRs(2)
		end if

		content.AssignValue "description", oRs(3).Value
		content.AssignValue "source", oRs(4).Value
		content.AssignValue "destination", oRs(5).Value

		select case oRs(6)
			case 0 ' gift
				content.Parse "entry.gift"
			case 1 ' tax
				content.Parse "entry.tax"
			case 2
				content.Parse "entry.member_left"
			case 3
				content.Parse "entry.money_request"
			case 4
				content.AssignValue "description", clng(oRs(3).Value)/10 & " %"
				content.Parse "entry.taxchanged"
			case 5
				content.Parse "entry.member_kicked"
			case 10
				content.Parse "entry.nap_broken"
			case 11
				content.Parse "entry.nap_broken"
			case 12
				content.Parse "entry.war_cost"
			case 20
				content.Parse "entry.tribute"
		end select
		
'		content.Parse "entry.type" & oRs(5)
		content.Parse "entry"

		oRs.MoveNext
	wend

'	if session(sprivilege) > 100 then content.Parse "dev"

	content.Parse ""

	DisplayPage content, cat
end sub

'
' Display the requests page
' Allow a player to request money from his alliance
' Treasurer and Leader can see the list of request and accept/deny them
'
sub DisplayRequests(cat)
	dim content, i
	set content = GetTemplate("alliance-wallet-requests")
	content.AssignValue "walletpage", cat

	dim oRs, credits
	set oRs = oConn.Execute("SELECT credits FROM users WHERE id=" & UserId)
	credits = oRs(0)

	content.AssignValue "player_credits", credits

	dim query
	query = "SELECT credits, description, result" &_
			" FROM alliances_wallet_requests" &_
			" WHERE allianceid=" & AllianceId & " AND userid=" & UserId

	set oRs = oConn.Execute(query)

	if oRs.EOF then
		content.Parse "request.none"
	else
		content.AssignValue "credits", oRs(0)
		content.AssignValue "description", oRs(1)
		if not IsNull(oRs(2)) and not oRs(2) then content.Parse "request.denied" else content.Parse "request.submitted"
	end if
	content.Parse "request"


	if oAllianceRights("can_accept_money_requests") then
		' List money requests
		query = "SELECT r.id, datetime, login, r.credits, r.description" &_
				" FROM alliances_wallet_requests r" &_
				"	INNER JOIN users ON users.id=r.userid" &_
				" WHERE allianceid=" & AllianceId & " AND result IS NULL"

		set oRs = oConn.Execute(query)

		i = 0
		while not oRs.EOF
			content.AssignValue "id", oRs(0)
			content.AssignValue "date", oRs(1).Value
			content.AssignValue "nation", oRs(2).Value
			content.AssignValue "credits", oRs(3)
			content.AssignValue "description", oRs(4).Value

			content.Parse "list.entry"

			i = i + 1
			oRs.MoveNext
		wend

		if i = 0 then content.Parse "list.norequests"

		content.Parse "list"
	end if

	content.Parse ""

	DisplayPage content, cat
end sub

'
'
'
sub DisplayGifts(cat)
	dim content, i
	set content = GetTemplate("alliance-wallet-give")
	content.AssignValue "walletpage", cat

	dim oRs, credits
	set oRs = oConn.Execute("SELECT credits FROM users WHERE id=" & UserId)
	content.AssignValue "player_credits", oRs(0)

	if can_give_money() then
		content.Parse "give.can_give"
	else
		content.Parse "give.can_give_after_a_week"
	end if

	content.Parse "give"

	if oAllianceRights("can_accept_money_requests") then
		' list gifts for the last 7 days
		dim query
		query = "SELECT datetime, credits, source, description" &_
				" FROM alliances_wallet_journal" &_
				" WHERE allianceid="&AllianceId&" AND type=0 AND datetime >= now()-INTERVAL '1 week'" &_
				" ORDER BY datetime DESC"
		set oRs = oConn.Execute(query)

		if oRs.EOF then content.Parse "list.noentries"

		while not oRs.EOF
			content.AssignValue "date", oRs(0).Value
			content.AssignValue "credits", oRs(1)
			content.AssignValue "nation", oRs(2).Value
			content.AssignValue "description", oRs(3).Value
			content.Parse "list.entry"
			oRs.MoveNext
		wend

		content.Parse "list"
	end if

	content.Parse ""

	DisplayPage content, cat
end sub

'
' Display the tax rates page, only viewable by treasurer and leader
'
sub DisplayTaxRates(cat)
	dim content
	set content = GetTemplate("alliance-wallet-taxrates")
	content.AssignValue "walletpage", cat

	dim oRs, tax
	set oRs = oConn.Execute("SELECT tax FROM alliances WHERE id=" & AllianceId)
	tax = oRs(0)

	' List available taxes
	dim i
	for i = 0 to 20
		content.AssignValue "tax", i*0.5
		content.AssignValue "taxrates", i*5

		if i*5 = tax then content.Parse "tax.selected"
		content.Parse "tax"
	next
	content.Parse ""

	DisplayPage content, cat
end sub

function log10(n)
	log10 = log(n) / log(100000)
end function

'
' Display credits income/outcome historic
'
sub DisplayHistoric(cat)
	dim content, query, oRs, rows
	set content = GetTemplate("alliance-wallet-historic")
	content.AssignValue "walletpage", cat

	query = "SELECT date_trunc('day', datetime), int4(sum(GREATEST(0, credits))), int4(-sum(LEAST(0, credits)))" &_
			" FROM alliances_wallet_journal" &_
			" WHERE allianceid=" & AllianceId &_
			" GROUP BY date_trunc('day', datetime)" &_
			" ORDER BY date_trunc('day', datetime)"
	set oRs = oConn.Execute(query)
	rows = oRs.GetRows()

	dim i, maxValue, avgValue
	maxValue = 0
	avgValue = 0
	for i = LBound(rows,2) to UBound(rows,2)
		if rows(1, i) > maxValue then maxValue = rows(1, i)
		if rows(2, i) > maxValue then maxValue = rows(2, i)

		avgValue = avgValue + rows(1, i) + rows(2, i)
	next

	avgValue = avgValue / (UBound(rows, 2)*2)

	for i = LBound(rows,2) to UBound(rows,2)

		content.AssignValue "income_height", fix(400 * rows(1,i) / maxValue)
		content.AssignValue "outcome_height", fix(400 * rows(2,i) / maxValue)
		content.AssignValue "income", rows(1, i)
		content.AssignValue "outcome", rows(2, i)
		content.AssignValue "datetime", rows(0, i)
		content.Parse "day"
	next

	content.Parse ""

	DisplayPage content, cat
end sub

if IsNull(AllianceId) then
	Response.Redirect "/game/overview.asp"
	Response.End
end if


'
' accept/deny money request
'
dim action, id, oRs
action = Request.QueryString("a")
id = Request.QueryString("id")

select case action
	case "accept"
		oConn.Execute "SELECT sp_alliance_money_accept(" & UserId & "," & dosql(id) & ")"
	case "deny"
		oConn.Execute "SELECT sp_alliance_money_deny(" & UserId & "," & dosql(id) & ")"
end select

'
' player gives or requests credits
'
dim credits, description
credits = ToInt(Request.Form("credits"), 0)
description = Trim(Request.Form("description"))

if Request.Form("cancel") <> "" then
	credits = 0
	description = ""
	oConn.Execute "SELECT sp_alliance_money_request("&UserId&","&dosql(credits)&","&dosql(description)&")", , adExecuteNoRecords
end if

if credits <> 0 then
	if Request.Form("request") <> "" then
		oConn.Execute "SELECT sp_alliance_money_request("&UserId&","&dosql(credits)&","&dosql(description)&")", , adExecuteNoRecords
	elseif Request.Form("give") <> "" and (credits > 0) then

		if can_give_money() then
			set oRs = oConn.Execute("SELECT sp_alliance_transfer_money("&UserId&","&dosql(credits)&","&dosql(description)&",0)")
			if oRs(0) <> 0 then	money_error = e_not_enough_money
		else
			money_error = e_can_give_money_after_a_week
		end if
	end if
end if

'
' change of tax rates
'
dim taxrates
taxrates = ToInt(Request.Form("taxrates"), "")

if taxrates <> "" then
	connExecuteRetryNoRecords "SELECT sp_alliance_set_tax("&UserId&","&dosql(taxrates)&")"
end if


'
' retrieve which page is displayed
'
dim category
category = ToInt(Request.QueryString("cat"), 1)

if not oAllianceRights("can_ask_money") and category = 2 then category = 1
if not oAllianceRights("can_change_tax_rate") and category = 4 then category = 1


select case category
	case 2
		DisplayRequests 2
	case 3
		DisplayGifts 3
	case 4
		DisplayTaxRates 4
	case 5
		DisplayHistoric 5
	case else
		DisplayJournal 1
end select

%>