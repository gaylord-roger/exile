<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "ranking.players"

sub DisplayRanking()
	dim content, query, oRs, i
	set content = GetTemplate("ranking-players")
	
	dim col, reversed, orderby, offset, size, nb_pages, displayed, index, myOffset
	dim searchbyN, searchbyA, searchby
	
	'
	' Setup search by Alliance and Nation query string
	'
	if false then
		searchbyA = Request.QueryString("a")
		if searchbyA <> "" then
			content.AssignValue "param_a", searchbyA

			searchbyA = dosql("%"&searchbyA&"%")
			searchbyA = " AND alliance_id IN (SELECT id FROM alliances WHERE upper(alliances.name) LIKE upper("&searchbyA&") OR upper(alliances.tag) LIKE upper("&searchbyA&"))"
		else
			searchbyA = ""
		end if

		searchbyN = ""'Request.QueryString("n")
		if searchbyN <> "" then
			content.AssignValue "param_n", searchbyN

			searchbyN = dosql("%"&searchbyN&"%")
			searchbyN = " AND upper(login) LIKE upper("&searchbyN&") "
		else
			searchbyN = ""
		end if
	end if

	searchby = searchbyA & searchbyN

	' if the page is a search result, add the search params to column ordering links
	if searchby <> "" then content.Parse "search_params"


	'
	' Setup column ordering
	'
	col = ToInt(Request.QueryString("col"), 3)
	if col < 1 or col > 4 then col = 3

	select case col
		case 1
			orderby = "CASE WHEN score_visibility=2 OR v.id="&UserId&" THEN upper(login) ELSE '' END, upper(login)"
		case 2
			orderby = "upper(alliances.name)"
		case 3
			orderby = "v.score"
			reversed = true
		case 4
			orderby = "v.score_prestige"
			reversed = true
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", upper(login)"

	content.Assignvalue "sort_column", col


	'
	' get the score of the tenth user to only show the avatars of the first 10 players
	'
	dim TenthUserScore
	query = "SELECT score" &_
			" FROM vw_players" &_
			" WHERE true "&searchby &_
			" ORDER BY score DESC OFFSET 9 LIMIT 1"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		TenthUserScore = 0
	else
		TenthUserScore = oRs(0)
	end if


	displayed = 100 ' number of nations displayed per page

	'
	' Retrieve the offset from where to begin the display
	'
	offset = ToInt(Request.QueryString("start"), -1)

	if offset < 0 then
		query = "SELECT v.id" &_
				" FROM vw_players v LEFT JOIN alliances ON alliances.id=v.alliance_id" &_
				" WHERE true "&searchby &_
				" ORDER BY "&orderby
		set oRs = oConn.Execute(query)

		index = 0
		dim found
		found = false
		do while not oRs.EOF
			if oRs(0) = UserId then
				found = true
				exit do
			end if
			index = index +1
			oRs.MoveNext
		loop
		myOffset = int(index/displayed)
		if not found then myOffset=0
		offset = myOffset
	end if

	' get total number of players that could be displayed
	query = "SELECT count(1) FROM vw_players WHERE true "&searchby
	set oRs = oConn.Execute(query)
	size = clng(oRs(0))
	nb_pages = Int(size/displayed)
	if nb_pages*displayed < size then nb_pages = nb_pages + 1
	if offset >= nb_pages then offset = nb_pages-1
	if offset < 0 then offset = 0

	content.AssignValue "page_displayed", offset+1
	content.AssignValue "page_first", offset*displayed+1
	content.AssignValue "page_last", min(size, (offset+1)*displayed)

	dim idx_from, idx_to

	idx_from = offset+1 - 10
	if idx_from < 1 then idx_from = 1

	idx_to = offset+1 + 10
	if idx_to > nb_pages then idx_to = nb_pages

	for i = 1 to nb_pages
		if (i=1) or (i >= idx_from and i <= idx_to) or (i mod 10 = 0) then
		content.AssignValue "page_id", i
		content.AssignValue "page_link", i-1

		if i-1 <> offset then 
			if searchby <> "" then content.Parse "nav.p.link.search_params"
			if Request.QueryString("r") <> "" then content.Parse "nav.p.link.reversed"

			content.Parse "nav.p.link"
		else
			content.Parse "nav.p.selected"
		end if

		content.Parse "nav.p"

		end if
	next


	'display only if there are more than 1 page
	if nb_pages > 1 then content.Parse "nav"


	' Retrieve players to display
	query = "SELECT login, v.score, v.score_prestige," &_
			"COALESCE(date_part('day', now()-lastactivity), 15), alliances.name, alliances.tag, v.id, avatar_url, v.alliance_id, v.score-v.previous_score AS score_delta," &_
			"v.score >= " & TenthUserScore & " OR score_visibility = 2 OR (score_visibility = 1 AND alliance_id IS NOT NULL AND alliance_id="&sqlvalue(AllianceId)&") OR v.id="&UserId &_
			" FROM vw_players v" &_
			"	LEFT JOIN alliances ON ((v.score >= " & TenthUserScore & " OR score_visibility = 2 OR v.id="&UserId&" OR (score_visibility = 1 AND alliance_id IS NOT NULL AND alliance_id="&sqlvalue(AllianceId)&")) AND alliances.id=v.alliance_id)" &_
			" WHERE true "&searchby &_
			" ORDER BY "&orderby&" OFFSET "&(offset*displayed)&" LIMIT "&displayed
	set oRs = oConn.Execute(query)

	if oRs.EOF then content.Parse "noresult"

	i = 1
	while not oRs.EOF
		content.AssignValue "place", offset*displayed+i
		content.AssignValue "name", oRs(0)

		dim visible
		visible = oRs(10) 'or Session(sprivilege) > 100' or TenthUserScore <= oRs(1)

		if visible and not isnull(oRs(4)) then
			content.AssignValue "alliancename", oRs(4)
			content.AssignValue "alliancetag", oRs(5)
			content.Parse "player.alliance"
		else
			content.Parse "player.noalliance"
		end if

		content.AssignValue "score", oRs(1)
		content.AssignValue "score_battle", oRs(2)
		if visible then
			content.AssignValue "score_delta", oRs(9)
			if oRs(9) > 0 then content.Parse "player.plus"
			if oRs(9) < 0 then content.Parse "player.minus"
		else
			content.AssignValue "score_delta", ""
		end if
		content.AssignValue "stat_colonies", oRs(2)
		content.AssignValue "last_login", oRs(3)


		if oRs(3) <= 7 then
			content.Parse "player.recently"
		elseif oRs(3) <= 14 then
			content.Parse "player.1weekplus"
		elseif oRs(3) > 14 then
			content.Parse "player.2weeksplus"
		end if

		if visible then
			if oRs(6) = UserID then
				content.Parse "player.self"
			elseif oRs(8) = AllianceId then
				content.Parse "player.ally"
			end if

			' show avatar only if top 10
			if oRs(1) >= TenthUserScore then
				if isNull(oRs(7)) or oRs(7) = "" then
					content.Parse "player.top10avatar.noavatar"
				else
					content.AssignValue "avatar_url", oRs(7)
					content.Parse "player.top10avatar.avatar"
				end if
				content.Parse "player.top10avatar"
			end if

			content.Parse "player.name"
		else
			content.Parse "player.name_na"
		end if

		content.Parse "player"

		i = i + 1
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

'if Session(sPrivilege) < 100 then
'	RedirectTo "/game/overview.asp"
'	Response.end
'end if

DisplayRanking()

%>