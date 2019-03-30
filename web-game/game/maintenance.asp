<%option explicit %>

<!--#include virtual="/lib/config.asp"-->
<!--#include virtual="/lib/template.asp"-->

<%

function sqlValue(value)
	if isNull(value) then
		sqlValue = "NULL"
	else
		sqlValue = "'" & value & "'"
	end if
end function

'
' display page
'
sub DisplayPage()
	dim content
	set content = GetTemplate("maintenance")
	content.AssignValue "skin", "s_transparent"

'	dim query, oRs
'	query = "SELECT id, max_commanders, max_planets FROM db_security_levels"
'	set oRs = oConn.Execute(query)

'	while not oRs.EOF
'		content.AssignValue "security" & oRs(0).value & "_max_commanders", oRs(1).value
'		content.AssignValue "security" & oRs(0).value & "_max_planets", oRs(2).value

'		oRs.MoveNext
'	wend
	
	content.Parse ""
	Response.write content.Output
end sub


'
' process page
'

DisplayPage


%>