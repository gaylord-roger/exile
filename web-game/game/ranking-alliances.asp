<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "ranking"

sub DisplayRankingAlliances(search_tag, search_name)
	dim content, oRs, i
	set content = GetTemplate("ranking-alliances")

	dim col, reversed, orderby, offset, size, nb_pages, displayed, searchby

	'
	' search by parameter
	'
	searchby = Request.QueryString("a")
	if searchby <> "" then
		' if the page is a search result, add the search params to ordering column links
		content.AssignValue "param_a", searchby
		content.Parse "search_params"

		searchby = dosql("%"&searchby&"%")
		searchby = " AND alliance_id IN (SELECT id FROM alliances WHERE upper(alliances.name) LIKE upper("&searchby&") OR upper(alliances.tag) LIKE upper("&searchby&"))"
	else 
		searchby = ""
	end if


	'
	' ordering column
	'
	col = ToInt(Request.QueryString("col"), 1)
	if col < 1 or col > 7 then col = 1

	' hide scores
	if col = 2 or col = 5 then col = 1

	select case col
		case 1
			orderby = "upper(alliances.name)"
		'case 2
		'	orderby = "score"
		'	reversed = true
		case 3
			orderby = "members"
			reversed = true
		case 4
			orderby = "planets"
			reversed = true
		'case 5
		'	orderby = "score_average"
		'	reversed = true
		case 6
			orderby = "created"
		case 7
			orderby = "upper(alliances.tag)"
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "r" & col
	end if
	
	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", upper(alliances.name)"

	content.Assignvalue "sort_column", col


	'
	' start offset
	'

	'offset = Request.QueryString("start")
	offset = ToInt(Request.QueryString("start"), -1)

	if offset < 0 then offset = 0
	
	displayed = 25 ' number of nations on each page

	dim query

	' retrieve number of alliances
	query = "SELECT count(DISTINCT alliance_id) FROM users INNER JOIN alliances ON alliances.id=alliance_id WHERE alliances.visible"&searchby
	set oRs = oConn.Execute(query)
	size = clng(oRs(0))

	
	nb_pages = int(size/displayed)
	if nb_pages*displayed < size then nb_pages = nb_pages + 1
	if offset >= nb_pages then offset = nb_pages-1
	if offset < 0 then offset = 0
	
	query = "SELECT alliances.id, alliances.tag, alliances.name, alliances.score, count(*) AS members, sum(planets) AS planets," &_
			" int4(alliances.score / count(*)) AS score_average, alliances.score-alliances.previous_score as score_delta," &_
			" created, EXISTS(SELECT 1 FROM alliances_naps WHERE allianceid1=alliances.id AND allianceid2=" & sqlValue(AllianceId) & ")," &_
			" max_members, EXISTS(SELECT 1 FROM alliances_wars WHERE (allianceid1=alliances.id AND allianceid2=" & sqlValue(AllianceId) & ") OR (allianceid1=" & sqlValue(AllianceId) & " AND allianceid2=alliances.id))" &_
			" FROM users INNER JOIN alliances ON alliances.id=alliance_id" &_
			" WHERE alliances.visible"&searchby &_
			" GROUP BY alliances.id, alliances.name, alliances.tag, alliances.score, alliances.previous_score, alliances.created, alliances.max_members" &_
			" ORDER BY "&orderby&_
			" OFFSET "&(offset*displayed)&" LIMIT "&displayed
	set oRs = oConn.Execute(query)

	if oRs.EOF then content.Parse "noresult"


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

	i = 1
	while not oRs.EOF
		content.AssignValue "place", offset*displayed+i
		content.AssignValue "tag", oRs(1)
		content.AssignValue "name", oRs(2)
		content.AssignValue "score", oRs(3)
		content.AssignValue "score_average", oRs(6)
		content.AssignValue "score_delta", oRs(7)
		content.AssignValue "members", oRs(4)
		content.AssignValue "stat_colonies", oRs(5)
		content.AssignValue "created", oRs(8).Value
		content.AssignValue "max_members", oRs(10)

		if oRs(6) > 0 then content.Parse "alliance.plus"
		if oRs(6) < 0 then content.Parse "alliance.minus"

		if oRs(0) = AllianceId then content.Parse "alliance.playeralliance"
		if oRs(9) then
			content.Parse "alliance.nap"
		elseif oRs(11) then
			content.Parse "alliance.war"
		end if

		content.Parse "alliance"

		i = i + 1
		oRs.MoveNext
	wend

	oRs.Close
	set oRs = Nothing

	content.Parse ""

	Display(content)
end sub

DisplayRankingAlliances Request.QueryString("tag"), Request.QueryString("name")

%>