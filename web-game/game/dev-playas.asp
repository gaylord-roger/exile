<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "playas"

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-playas")

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

dim player
player = Trim(Request.QueryString("player"))

dim oRs

if player <> "" then
	set oRs = oConn.Execute("SELECT id FROM users WHERE upper(login)=upper(" & dosql(player) & ")")
	if not oRs.EOF then Impersonate oRs(0)
end if

DisplayForm()

%>