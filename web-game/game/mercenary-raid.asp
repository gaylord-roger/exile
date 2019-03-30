<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "raid"

if session("privilege") < 100 then
	Response.Redirect "overview.asp"
	Response.end
end if

sub DisplayRaid()
	dim content
	set content = GetTemplate("mercenary-raid")

	content.Parse ""
	display(content)
end sub

DisplayRaid()
%>