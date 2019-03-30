<% Option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = ""


function query(aQuery)
	dim oRs
	set oRs = oConn.Execute(aQuery)
	query = oRs(0)
end function

sub display_stats(content)

	dim oRs, query

	query = "SELECT date_trunc('day', battles.time), count(DISTINCT battles.id), sum(""before""-""after"")" &_
			"FROM battles" &_
			"	INNER JOIN battles_ships ON (battles.id=battles_ships.battleid)" &_
			"WHERE battles.time > now()-INTERVAL '1 month'" &_
			"GROUP BY date_trunc('day', battles.time)" &_
			"ORDER BY date_trunc('day', battles.time)"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "date", oRs(0).Value
		content.AssignValue "battles", oRs(1)
		content.AssignValue "shipsdestroyed", oRs(2)
'		content.AssignValue "invasions", oRs(3)

'		content.AssignValue "scientists", oRs(4)
'		content.AssignValue "soldiers", oRs(5)
'		content.AssignValue "workers", oRs(6)

		content.Parse "entry"

		oRs.MoveNext
	wend
end sub


if Session("privilege") < 100 then
	response.redirect "/"
	response.end
end if

'dim cat
'cat = ToInt(Request.QueryString("cat"), 0)

'if cat < 0 or cat > 2 then cat = 0


dim content
set content = GetTemplate("statistics")

'content.Parse "tabnav."&cat&".selected"
'content.Parse "tabnav.0"
'content.Parse "tabnav.1"
'content.Parse "tabnav.2"
'content.Parse "tabnav"

'select case cat
'	case 0
'		display_galaxies content
'	case 1
'		display_stats content
'	case 2
'		display_alliances_production content
'end select

display_stats content

content.Parse ""
display(content)

%>