<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "gsc"

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
sub DisplayPage()
	dim content, query, oRs
	set content = GetTemplate("gsc")

	query = "SELECT id, max_commanders, max_planets FROM db_security_levels"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "security" & oRs(0).value & "_max_commanders", oRs(1).value
		content.AssignValue "security" & oRs(0).value & "_max_planets", oRs(2).value

		oRs.MoveNext
	wend
	
	content.Parse ""
	display(content)
end sub


'
' process page
'

DisplayPage()


%>