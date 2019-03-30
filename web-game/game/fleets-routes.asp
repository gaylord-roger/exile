<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "fleets.traderoutes"

' List the fleets owned by the player
sub ListRoutes()
	dim content, oRs, query
	set content = GetTemplate("fleets-traderoutes")

	' list the ships
	query = "SELECT id, name, int4((SELECT count(*) FROM routes_waypoints WHERE routeid=routes.id)), created, modified, 'loop'" & _
			" FROM routes" &_
			" WHERE ownerid=" & UserId & _
			" ORDER BY upper(name)"
	set oRs = oConn.Execute(query)

	if oRs.EOF then
		content.Parse "noroutes"
	else
		while not oRs.EOF
			content.AssignValue "id", oRs(0)
			content.AssignValue "name", oRs(1)
			content.AssignValue "orders", oRs(2)
			content.AssignValue "created", oRs(3).Value
			content.AssignValue "modified", oRs(4).Value

			if oRs(5).Value = true then
				content.Parse "route.looping"
			else
				content.Parse "route.notlooping"
			end if

			content.Parse "route"

			oRs.MoveNext
		wend
	end if
	
	content.Parse ""

	Display(content)
end sub

dim route_name, oRs, looping, routeid

route_name = Request.Form("name")
if route_name <> "" then
	set oRs = oConn.Execute("SELECT sp_create_route(" & UserId & "," & dosql(route_name) & ")")
	Response.Redirect "fleets-route.asp?id=" & oRs(0)
	Response.End
end if

routeid = ToInt(Request.QueryString("id"), 0)
looping = Request.QueryString("loop")
if looping <> "" and routeid > 0 then
	set oRs = oConn.Execute("SELECT sp_routes_toggle_loop(" & UserId & "," & routeid & ")")
	Response.Redirect "?"
	Response.End
end if

ListRoutes()

%>