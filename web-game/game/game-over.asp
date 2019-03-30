<% option explicit %>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->
<!--#include virtual="/lib/accounts.asp"-->
<%

dim query, oRs, content, UserId
dim reset_error
reset_error = 0

UserId = ToInt(Session("user"), "")

if UserId = "" then
	response.redirect "/"
	response.end
end if

dim planets

' check that the player has no more planets
set oRs = oConn.Execute("SELECT int4(count(1)) FROM nav_planet WHERE ownerid=" & UserId)
if oRs.EOF then
	response.redirect "/"
	response.end
end if

planets = oRs(0)

' retreive player username and number of resets
dim username, resets, bankruptcy, research_done

query = "SELECT login, resets, credits_bankruptcy, int4(score_research) FROM users WHERE id=" & UserId
set oRs = oConn.Execute(query)

username = oRs(0)
resets = oRs(1)
bankruptcy = oRs(2)
research_done = oRs(3)

' still have planets
if planets > 0 and bankruptcy > 0 then
	response.redirect "/"
	response.end
end if

if resets = 0 then
	response.redirect "start.asp"
	response.end
end if

dim changeNameError: changeNameError = ""

if allowedRetry then
	dim action
	action = Request.Form("action")

	if action = "retry" then
		' check if user wants to change name
		if Request.Form("login") <> username then

'			connectNexusDB()

			' check that the login is not banned
			set oRs = oConn.Execute("SELECT 1 FROM banned_logins WHERE " & dosql(username) & " ~* login LIMIT 1;")
			if oRs.EOF then

				' check that the username is correct
				if not isValidName(Request.Form("login")) then
					changeNameError = "check_username"
				else
					' try to rename user and catch any error
					on error resume next

					oConn.Execute "UPDATE users SET alliance_id=null WHERE id=" & UserId

					oConn.Execute "UPDATE users SET login=" & dosql(Request.Form("login")) & " WHERE id=" & UserId

					if err.Number <> 0 then
						changeNameError = "username_exists"
					else
						' update the commander name
						oConn.Execute "UPDATE commanders SET name=" & dosql(Request.Form("login")) & " WHERE name=" & dosql(username) & " AND ownerid=" & UserId
					end if

					on error goto 0
				end if
			end if
		end if

		if changeNameError = "" then
			set oRs = oConn.Execute("SELECT sp_reset_account(" & UserId & "," & ToInt(Request.Form("galaxy"), 1) & ")")
			if oRs(0) = 0 then
				Response.Redirect "/game/overview.asp"
				Response.End
			else
				reset_error = oRs(0)
			end if
		end if
	elseif action = "abandon" then
		oConn.Execute "UPDATE users SET deletion_date=now()/*+INTERVAL '2 days'*/ WHERE id=" & UserId, , 128
		Response.Redirect "/"
		Response.End
	end if
end if

' display Game Over page
set content = GetTemplate("game-over")
content.AssignValue "login", username

if changeNameError <> "" then action = "continue"

if action = "continue" then
	set oRs = oConn.Execute("SELECT id, recommended FROM sp_get_galaxy_info(" & UserId & ")")

	while not oRs.EOF
		content.AssignValue "id", oRs(0)
		content.AssignValue "recommendation", oRs(1)
		content.Parse "changename.galaxies.galaxy"
		oRs.MoveNext
	wend

	content.Parse "changename.galaxies"

	if changeNameError <> "" then
		content.Parse "changename.error." & changeNameError
		content.Parse "changename.error"
	end if

	content.Parse "changename"
else
	if allowedRetry then content.Parse "choice.retry"
	content.Parse "choice"

	if bankruptcy > 0 then
		content.Parse "gameover"
	else
		content.Parse "bankrupt"
	end if
end if

if reset_error <> 0 then
	if reset_error = 4 then
		content.Parse "no_free_planet"
	else
		content.AssignValue "userid", UserId
		content.AssignValue "reset_error", reset_error
		content.Parse "reset_error"
	end if
end if

content.Parse ""

Response.write content.Output

%>