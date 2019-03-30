<%option explicit %>

<!--#include file="global.asp"-->
<!--#include file="lib_battle.asp"-->

<%
selected_menu = "battles"


dim id, creator, fromview

id = ToInt(Request.QueryString("id"), 0)
if id = 0 then
	Response.Redirect "reports.asp"
	Response.End
end if

creator = UserId

fromview = ToInt(Request.QueryString("v"), UserId)

dim display_battle
display_battle = true

dim oRs, query

' check that we took part in the battle to display it
set oRs = oConn.Execute("SELECT battleid FROM battles_ships WHERE battleid=" & id & " AND owner_id=" & UserId & " LIMIT 1")
display_battle = not oRs.EOF

if not display_battle and not IsNull(AllianceId) then
	if oAllianceRights("can_see_reports") then
		' check if it is a report from alliance reports
		set oRs = oConn.Execute("SELECT owner_id FROM battles_ships WHERE battleid=" & id & " AND (SELECT alliance_id FROM users WHERE id=owner_id)=" & AllianceId & " LIMIT 1")
		display_battle = not oRs.EOF
		if not oRs.EOF then
			creator = oRs(0)'fromview
		end if
	end if
end if

if display_battle then
	dim content
	set content = FormatBattle(id, creator, fromview, false)
	Display content
else
	Response.Redirect "reports.asp"
	Response.End
end if

%>