<%option explicit%>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets.fleets"

sub DisplayFleetsPage()
	dim content
	set content = GetTemplate("fleets")

	dim oRs, query

	query = "SELECT category, label" &_
			" FROM users_fleets_categories" &_
			" WHERE userid=" & UserId &_
			" ORDER BY upper(label)"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "label", oRs(1)
		content.Parse "master.category"
		oRs.MoveNext
	wend

	content.Parse "master"
	content.Parse ""

	Display(content)
end sub

DisplayFleetsPage()

%>