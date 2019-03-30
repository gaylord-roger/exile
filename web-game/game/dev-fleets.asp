<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "player_fleets"

dim name, typ, g, s, p, to_g, to_s, to_p, submit, attack
dim oRs, query

sub GenName()
	dim p1(10), p2(10), p3(10)

	p1(0) = "Al"
	p1(1) = "Ol"
	p1(2) = "Il"
	p1(3) = "Ul"

	p2(0) = " ret "
	p2(1) = " nor "
	p2(2) = " mot "
	p2(3) = " bre "

	p3(0) = " Azr "
	p3(1) = "vyr "
	p3(2) = " Ber"
	p3(3) = "loty "
	
	Randomize
	naame = p1(3*Rnd) & p2(3*Rnd) & p3(3*Rnd)
end sub

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-fleets")

	content.AssignValue "name", name

	content.AssignValue "g", g
	content.AssignValue "s", s
	content.AssignValue "p", p

	content.AssignValue "to_g", to_g
	content.AssignValue "to_s", to_s
	content.AssignValue "to_p", to_p

	content.Parse "type_" & typ

	set oRs = oConn.Execute("SELECT id, label FROM db_ships ORDER BY category, id")
	while not oRs.EOF
		content.AssignValue "ship_id", oRs(0)
		content.AssignValue "ship_name", oRs(1)
		content.Parse "ship"
		oRs.MoveNext
	wend

	if attack then content.Parse "attack"

	content.Parse ""

	Display(content)
end sub

function sqlValue(val)
	if val = "" or IsNull(val) then
		sqlValue = "Null"
	else
		sqlValue = val
	end if
end function

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

name = Trim(Request.QueryString("name"))
typ = ToInt(Request.QueryString("type"), "99")

g = Trim(Request.QueryString("g"))
s = Trim(Request.QueryString("s"))
p = Trim(Request.QueryString("p"))
to_g = Trim(Request.QueryString("to_g"))
to_s = Trim(Request.QueryString("to_s"))
to_p = Trim(Request.QueryString("to_p"))
submit = Trim(Request.QueryString("submit"))

attack = Trim(Request.QueryString("attack")) = "1"

if name = "" then name = oplayerinfo("login")

if submit <> "" then
	query = "SELECT admin_generate_fleet("&UserId&","&dosql(name)&","&"sp_planet("&sqlValue(g)&","&sqlValue(s)&","&sqlValue(p)&"), sp_planet(" &sqlValue(to_g)& "," &sqlValue(to_s)& "," &sqlValue(to_p)& ")," &typ& ")"
	set oRs = oConn.Execute(query)
	if not oRs.EOF then
		dim fleetid
		fleetid = oRs(0)

		if typ="99" then
			dim quantity

			set oRs = oConn.Execute("SELECT id FROM db_ships order by id")
			while not oRs.EOF
				quantity = ToInt(Request.QueryString("q"&oRs(0)), 0)

				if quantity > 0 then
					query = "INSERT INTO fleets_ships(fleetid, shipid, quantity) VALUES("&fleetid&","&oRs(0)&","&quantity&")"

					oConn.Execute query, , adExecuteNoRecords
				end if

				oRs.MoveNext
			wend

			oConn.Execute "DELETE FROM fleets WHERE id="&fleetid&" AND size=0", adExecuteNoRecords
		end if

		if attack then oConn.Execute "UPDATE fleets SET attackonsight=true WHERE id="&fleetid, adExecuteNoRecords

		Response.Redirect "/game/fleet.asp?id=" & fleetid
		Response.End
	end if
end if

DisplayForm()

%>