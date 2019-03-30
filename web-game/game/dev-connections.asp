<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "player_connections"

sub DisplayConnections(browser, address, browserid, user1, user2)
	dim content
	set content = GetTemplate("dev-connections")

	dim oRs, query

	if browserid <> "" then
		query = "SELECT datetime, sp__itoa(address), forwarded_address, browser, users.login, browserid, disconnected" &_
				" FROM users_connections" &_
				"	INNER JOIN users ON users.id=userid" &_
				" WHERE browserid=" & dosql(browserid) &_
				" ORDER BY datetime DESC, upper(users.login) LIMIT 1000"
	elseif address <> "" then
		query = "SELECT datetime, sp__itoa(address), forwarded_address, browser, users.login, browserid, disconnected" &_
				" FROM users_connections" &_
				"	INNER JOIN users ON users.id=userid" &_
				" WHERE address=sp__atoi(" & dosql(address) & ")" &_
				" ORDER BY datetime DESC, upper(users.login) LIMIT 1000"
	elseif browser <> "" then
		query = "SELECT datetime, sp__itoa(address), forwarded_address, browser, users.login, browserid, disconnected" &_
				" FROM users_connections" &_
				"	INNER JOIN users ON users.id=userid" &_
				" WHERE lower(browser)=lower(" & dosql(browser) & ")" &_
				" ORDER BY users_connections.datetime DESC, upper(users.login)" &_
				" LIMIT 4000"
	elseif user1 <> "" then
		query = "SELECT datetime, sp__itoa(address), forwarded_address, browser, sp_get_user(userid), browserid, disconnected" &_
				" FROM users_connections" &_
				" WHERE userid=" & User1 & " OR userid=" & user2 &_
				" ORDER BY datetime DESC"
	else
		query = "SELECT datetime, sp__itoa(address), forwarded_address, browser," & dosql(oPlayerInfo("login")) & ", browserid, disconnected" &_
				" FROM users_connections" &_
				" WHERE userid=" & UserId &_
				" ORDER BY datetime DESC"
	end if

	set oRs = oConn.Execute(query)

	dim lastuser, c
	c = 1
	lastuser = ""

	while not oRs.EOF
		content.AssignValue "connected", oRs(0).Value
		content.AssignValue "address", oRs(1)
		content.AssignValue "forwarded_address", oRs(2)
		if oRs(2) <> "" then content.Parse "connection.forwarded"
		content.AssignValue "browser", oRs(3)
		content.AssignValue "username", oRs(4)
		content.AssignValue "browserid", oRs(5)
		content.AssignValue "disconnected", oRs(6).Value

		if lastuser = "" then lastuser = oRs(4)
		if lastuser <> oRs(4) then
			c = 1 + c mod 2
			lastuser = oRs(4)
		end if
		content.Parse "connection.user" & c

		content.Parse "connection"
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

DisplayConnections Request.QueryString("browser"), Request.QueryString("address"), Request.QueryString("browserid"), Request.QueryString("u1"), Request.QueryString("u2")

%>