<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->

<%

if IsEmpty(Session(sUser)) then
	Session.Abandon ' Abandon session
	Response.Redirect "/" ' Redirect to home page
	Response.End
end if

%>

<!--#include file="cache.asp"-->

<%

dim tpl_header
dim AllianceId, AllianceRank, UserID, LogonUserID
dim SecurityLevel
dim CurrentPlanet, CurrentGalaxyId, CurrentSectorId
dim oPlayerInfo, oAllianceRights
dim scrollY: scrollY = 0 ' how much will be scrolled in vertical after the page is loaded
dim showHeader: showHeader = false
dim url_extra_params: url_extra_params = ""
dim pageTerminated: pageTerminated = false
dim displayAlliancePlanetName: displayAlliancePlanetName = true

dim selected_menu
dim current_chat

function hasRight(right)
	if IsNull(oAllianceRights) then
		hasRight = true
	else
		hasRight = oAllianceRights("leader") or oAllianceRights(right)
	end if
end function

function getPlanetName(relation, radar_strength, ownerName, planetName)
	if relation = rSelf then
		getPlanetName = planetName
	elseif relation = rAlliance then
		if displayAlliancePlanetName then
			getPlanetName = planetName
		else
			getPlanetName = ownerName
		end if
	elseif relation = rFriend then
		getPlanetName = ownerName
	else
		if radar_strength > 0 then
			getPlanetName = ownerName
		else
			getPlanetName = ""
		end if
	end if
end function

function IsPlayerAccount()
	IsPlayerAccount = Session(sPrivilege) > -50 and Session(sPrivilege) < 50
end function

function IsImpersonating()
	IsImpersonating = not isEmpty(Session("ImpersonatingUser")) and Session("ImpersonatingUser")
end function

sub Impersonate(new_userid)
	if Session(sPrivilege) >= 100 then
		UserId = new_userid
		Session.Contents(sUser) = new_userid
		Session("ImpersonatingUser") = Session(sLogonUserID) <> new_userid

		InvalidatePlanetList()

		CurrentPlanet = 0
		CurrentGalaxyId = 0
		CurrentSectorId = 0

		Response.Redirect "/game/overview.asp"
		Response.End
	end if
end sub

sub log_notice(title, details, level)
	dim query
	query = "INSERT INTO log_notices (username, title, details, url, level) VALUES(" &_
			dosql(oPlayerInfo("login")) & ", " &_
			dosql(title) & "," &_
			dosql(details) & "," &_
			dosql(scripturl) & "," &_
			dosql(level) &_
			")"
	oConn.Execute query
end sub

function Min(a, b)
	if a < b then Min = a else Min = b
end function

' Call this function when the name of a planet has changed or has been colonized or abandonned
sub InvalidatePlanetList()
	set Session(sPlanetList) = nothing
end sub

' return image of a planet according to its it and its floor
function planetimg(id,floor)
	planetimg = 1+(floor + id) mod 21
	if planetimg < 10 then planetimg = "0" & planetimg
end function

' return the percentage of the current value compared to max value
function getpercent(current, max, slice)
	if (current >= max) or (max = 0) then
		getpercent = 100
	else
		getpercent = slice*Int(100 * current / max / slice)
	end if
end function

'
' Parse the header, list the planets owned by the player and show the resources of the current planet
'
sub FillHeader()
	if CurrentPlanet = 0 then
		exit sub
	end if

	' Initialize the header
	set tpl_header = GetTemplate("header")

	dim query, oRs

	' retrieve player credits and assign the value, don't use oPlayerInfo as the info may be outdated
	query = "SELECT credits, prestige_points FROM users WHERE id=" & UserId & " LIMIT 1"
	set oRs = oConn.Execute(query)
	tpl_header.AssignValue "money", oRs(0)
	tpl_header.AssignValue "pp", oRs(1)


	' assign current planet ore, hydrocarbon, workers and energy
	query = "SELECT ore, ore_production, ore_capacity," & _
			"hydrocarbon, hydrocarbon_production, hydrocarbon_capacity," & _ 
			"workers, workers_busy, workers_capacity," & _
			"energy_consumption, energy_production," & _
			"floor_occupied, floor," & _
			"space_occupied, space, workers_for_maintenance," & _
			"mod_production_ore, mod_production_hydrocarbon, energy, energy_capacity, soldiers, soldiers_capacity, scientists, scientists_capacity" &_ 
			" FROM vw_planets WHERE id="&CurrentPlanet
	set oRs = oConn.Execute(query)

	tpl_header.AssignValue "ore", oRs(0)
	tpl_header.AssignValue "ore_production", oRs(1)
	tpl_header.AssignValue "ore_capacity", oRs(2)

	' compute ore level : ore / capacity
	dim ore_level, hydrocarbon_level
	ore_level = getpercent(oRs(0), oRs(2), 10)

	if ore_level >= 90 then
		tpl_header.Parse "high_ore"
	elseif ore_level >= 70 then
		tpl_header.Parse "medium_ore"
	else
		tpl_header.Parse "normal_ore"
	end if


	tpl_header.AssignValue "hydrocarbon", oRs(3)
	tpl_header.AssignValue "hydrocarbon_production", oRs(4)
	tpl_header.AssignValue "hydrocarbon_capacity", oRs(5)

	hydrocarbon_level = getpercent(oRs(3), oRs(5), 10)

	if hydrocarbon_level >= 90 then
		tpl_header.Parse "high_hydrocarbon"
	elseif hydrocarbon_level >= 70 then
		tpl_header.Parse "medium_hydrocarbon"
	else
		tpl_header.Parse "normal_hydrocarbon"
	end if


	tpl_header.AssignValue "workers", oRs(6)
	tpl_header.AssignValue "workers_capacity", oRs(8)
	tpl_header.AssignValue "workers_idle", oRs(6) - oRs(7)

	if oRs(6) < oRs(15) then tpl_header.Parse "workers_low"


	tpl_header.AssignValue "soldiers", oRs(20)
	tpl_header.AssignValue "soldiers_capacity", oRs(21)

	if oRs(20)*250 < oRs(6)+oRs(22) then tpl_header.Parse "soldiers_low"

	tpl_header.AssignValue "scientists", oRs(22)
	tpl_header.AssignValue "scientists_capacity", oRs(23)


	tpl_header.AssignValue "energy_consumption", oRs(9)
	tpl_header.AssignValue "energy_totalproduction", oRs(10)
	tpl_header.AssignValue "energy_production", oRs(10)-oRs(9)

	tpl_header.AssignValue "energy", oRs(18)
	tpl_header.AssignValue "energy_capacity", oRs(19)

	if oRs(9) > oRs(10) then tpl_header.Parse "energy_low"

	if oRs(9) > oRs(10) then tpl_header.Parse "energy_production_minus" else tpl_header.Parse "energy_production_normal"

	tpl_header.AssignValue "floor_occupied", oRs(11)
	tpl_header.AssignValue "floor", oRs(12)

	tpl_header.AssignValue "space_occupied", oRs(13)
	tpl_header.AssignValue "space", oRs(14)

	' ore/hydro production colors
	if oRs(16) >= 0 and oRs(6) >= oRs(15) then
		tpl_header.Parse "normal_ore_production"
	else
		tpl_header.Parse "medium_ore_production"
	end if

	if oRs(17) >= 0 and oRs(6) >= oRs(15) then
		tpl_header.Parse "normal_hydrocarbon_production"
	else
		tpl_header.Parse "medium_hydrocarbon_production"
	end if


	'
	' Fill the planet list
	'
	if url_extra_params <> "" then
		tpl_header.AssignValue "url", "?" & url_extra_params & "&planet="
	else
		tpl_header.AssignValue "url", "?planet="
	end if

	dim planetListArray, planetListCount

	' cache the list of planets as they are not supposed to change unless a colonization occurs
	' in case of colonization, let the colonize script reset the session value
	if IsArray(Session(sPlanetList)) then
		planetListArray = Session(sPlanetList)
		planetListCount = Session(sPlanetListCount)
	else
		' retrieve planet list
		query = "SELECT id, name, galaxy, sector, planet" & _
				" FROM nav_planet" & _
				" WHERE planet_floor > 0 AND planet_space > 0 AND ownerid=" & UserId & _
				" ORDER BY id"
		set oRs = oConn.Execute(query)

		if oRs.EOF then
			planetListCount = -1
		else
			planetListArray = oRs.GetRows()
			planetListCount = UBound(planetListArray, 2)
		end if

		Session(sPlanetList) = planetListArray
		Session(sPlanetListCount) = planetListCount
	end if

	dim i

	for i = 0 to planetListCount
		dim id
		id = planetListArray(0,i)

		tpl_header.AssignValue "id", Id
		tpl_header.AssignValue "name", planetListArray(1,i)
		tpl_header.AssignValue "g", planetListArray(2,i)
		tpl_header.AssignValue "s", planetListArray(3,i)
		tpl_header.AssignValue "p", planetListArray(4,i)

		if id = CurrentPlanet then tpl_header.Parse "planet.selected"

		tpl_header.Parse "planet"
	next

	query = "SELECT buildingid" &_
			" FROM planet_buildings INNER JOIN db_buildings ON (db_buildings.id=buildingid AND db_buildings.is_planet_element)" &_
			" WHERE planetid="&CurrentPlanet&_
			" ORDER BY upper(db_buildings.label)"
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF
		tpl_header.AssignValue "name", getBuildingLabel(oRs(0))
		'tpl_header.AssignValue "description", getBuildingDescription(oRs(0))

		if i mod 3 = 0 then
			tpl_header.Parse "special.special1"
		elseif i mod 3 = 1 then
			tpl_header.Parse "special.special2"
		else
			tpl_header.Parse "special.special3"
			tpl_header.Parse "special"
		end if

		i = i + 1
		oRs.MoveNext
	wend

	if i mod 3 <> 0 then tpl_header.Parse "special"

	tpl_header.Parse ""
end sub

sub FillHeaderCredits()
	dim oRs
	set tpl_header = GetTemplate("header-credits")
	set oRs = oConn.Execute("SELECT credits FROM users WHERE id="&UserId)
	tpl_header.AssignValue "credits", oRs(0)
	tpl_header.Parse ""
end sub

'
' Parse the menu
'
sub FillMenu(tpl_layout)
	' Initialize the menu template
	dim oRs, query, tpl
	
	set tpl = GetTemplate("menu")

	' retrieve number of new messages & reports
	query = "SELECT (SELECT int4(COUNT(*)) FROM messages WHERE ownerid=" & UserId & " AND read_date is NULL)," & _
			"(SELECT int4(COUNT(*)) FROM reports WHERE ownerid=" & UserId & " AND read_date is NULL AND datetime <= now());"
	set oRs = oConn.Execute(query)

	if oRs(0) > 0 then
		tpl.AssignValue "new_mail", oRs(0)
		tpl.Parse "new_mail"
	end if

	if oRs(1) > 0 then
		tpl.AssignValue "new_report", oRs(1)
		tpl.Parse "new_report"
	end if

	if not IsNull(oAllianceRights) then
		if oAllianceRights("leader") or oAllianceRights("can_manage_description") or oAllianceRights("can_manage_announce") then tpl.Parse "show_alliance.show_management"
		if oAllianceRights("leader") or oAllianceRights("can_see_reports") then tpl.Parse "show_alliance.show_reports"
		if oAllianceRights("leader") or oAllianceRights("can_see_members_info") then tpl.Parse "show_alliance.show_members"
	end if

	if SecurityLevel >= 3 then
		tpl.Parse "show_mercenary"
		tpl.Parse "show_alliance"
	end if

	'
	' Fill admin info
	'
	if Session("privilege") >= 100 then
		dim last_errorid, last_noticeid

		query = "SELECT int4(MAX(id)) FROM log_http_errors"
		set oRs = oConn.Execute(query)
		last_errorid = oRs(0)

		query = "SELECT int4(MAX(id)) FROM log_notices"
		set oRs = oConn.Execute(query)
		last_noticeid = oRs(0)

		query = "SELECT COALESCE(dev_lasterror, 0), COALESCE(dev_lastnotice, 0) FROM users WHERE id=" & Session(sLogonUserID)
		set oRs = oConn.Execute(query)
		if last_errorid > oRs(0) then
			tpl.AssignValue "new_error", last_errorid-oRs(0)
		end if

		if last_noticeid > oRs(1) then
			tpl.AssignValue "new_notice", last_noticeid-oRs(1)
		end if

		tpl.Parse "dev"
	end if

	tpl.AssignValue "planetid", CurrentPlanet

	tpl.AssignValue "g", CurrentGalaxyId
	tpl.AssignValue "s", CurrentSectorId
	tpl.AssignValue "p", ((CurrentPlanet-1) mod 25) + 1

	tpl.AssignValue "selectedmenu", Replace(selected_menu,".","_")

	if selected_menu <> "" then
		dim blockname, i
		blockname = selected_menu & "_selected"

		while blockname <> ""
			tpl.Parse blockname

			i = InStrRev(blockname, ".")
			if i > 0 then i = i - 1
			blockname = Left(blockname, i)
		wend
	end if

	tpl.Parse ""

	' Assign the menu
	tpl_layout.AssignValue "menu", tpl.Output

	set tpl = nothing
end sub

dim pagelogged
pagelogged = false

sub logpage()
'	if not pagelogged and Session(sprivilege) < 100 and Timer() - StartTime > 1 then'and UserId=2448 then
'		dim query, pageurl
'		pageurl = Request.ServerVariables("SCRIPT_NAME") & "?" & Request.ServerVariables("QUERY_STRING")
'		query = "INSERT INTO log_pages(userid, webpage, elapsed) VALUES(" & UserId & "," & dosql(pageurl) & "," & dosql(int((Timer() - StartTime)*1000)) & ")"
'		oConn.Execute query, , adExecuteNoRecords
'	end if
	pagelogged = true
end sub

sub RedirectTo(url)
	logpage()

	pageTerminated = true

	Response.Redirect url
	Response.End
end sub

sub displayXML(tpl)
	dim tpl_xml
	set tpl_xml = GetTemplate("layoutxml")

	dim oRs, query

	' retrieve number of new messages & reports
	query = "SELECT (SELECT int4(COUNT(*)) FROM messages WHERE ownerid=" & UserId & " AND read_date is NULL)," & _
			"(SELECT int4(COUNT(*)) FROM reports WHERE ownerid=" & UserId & " AND read_date is NULL AND datetime <= now());"
	set oRs = oConn.Execute(query)

	tpl_xml.AssignValue "new_mail", oRs(0)
	tpl_xml.AssignValue "new_report", oRs(1)

	tpl_xml.AssignValue "content", tpl.output
	tpl_xml.AssignValue "selectedmenu", Replace(selected_menu,".","_")
	tpl_xml.Parse ""

	response.contentType = "text/xml"

	Session("details") = "sending page"
	response.write tpl_xml.output
end sub

'
' Display the tpl content with the default layout template
'
sub Display(tpl)
	dim tpl_layout

	if Request.QueryString("xml") = "1" then
		displayXML tpl
	else
		set tpl_layout = GetTemplate("layout")

		' Initialize the layout
		if not isNull(oPlayerInfo("skin")) then
			tpl_layout.AssignValue "skin", oPlayerInfo("skin")
		else
			tpl_layout.AssignValue "skin", "s_transparent"
		end if

		'
		' Fill and parse the header template
		'
		if showHeader then FillHeader()

		'
		' Fill and parse the menu template
		'
		FillMenu(tpl_layout)

		'
		' Fill and parse the layout template
		'
		tpl_layout.AssignValue "timers_enabled", oPlayerInfo("timers_enabled")


		'Assign the context/header
		if not IsEmpty(tpl_header) then
			tpl_layout.AssignValue "contextinfo", tpl_header.Output
			tpl_layout.Parse "context"
		end if

		' Assign the scroll value if is assigned
		tpl_layout.AssignValue "scrolly", scrollY
		if scrollY <> 0 then tpl_layout.Parse "scroll"

		' Assign the content
		if not tpl is Nothing then tpl_layout.AssignValue "content", tpl.Output


		if not IsNull(oPlayerInfo("deletion_date")) then
			tpl_layout.AssignValue "delete_datetime", oPlayerInfo("deletion_date").Value
			tpl_layout.Parse "deleting"
		end if

		if oPlayerInfo("credits") < 0 then
			dim bankrupt_hours
			bankrupt_hours = oPlayerInfo("credits_bankruptcy").Value

'			if bankrupt_hours < 36 then
				tpl_layout.AssignValue "bankruptcy_hours", bankrupt_hours
				tpl_layout.Parse "creditswarning.hours"
'			else
'				tpl_layout.AssignValue "bankruptcy_days", Round(bankrupt_hours / 24)
'				tpl_layout.Parse "creditswarning.days"
'			end if

			tpl_layout.Parse "creditswarning"
		end if


		'
		' Fill admin info
		'
		if Session(sPrivilege) > 100 then
			dim oRs

			if isImpersonating then
				tpl_layout.AssignValue "login", oPlayerInfo("login")
				tpl_layout.Parse "impersonating"
			end if


			' Assign the time taken to generate the page
			tpl_layout.AssignValue "render_time",  Timer() - StartTime

			' Assign number of logged players
			set oRs = oConn.Execute("SELECT int4(count(*)) FROM vw_players WHERE lastactivity >= now()-INTERVAL '20 minutes'")
			tpl_layout.AssignValue "players", oRs(0)
			tpl_layout.Parse "menu.dev"


			if oPlayerInfo("privilege") = -2 then
				set oRs = oConn.Execute("SELECT start_time, min_end_time, end_time FROM users_holidays WHERE userid="&UserId)

				if not oRs.EOF then
					tpl_layout.AssignValue "start_datetime", oRs(0).Value
					tpl_layout.AssignValue "min_end_datetime", oRs(1).Value
					tpl_layout.AssignValue "end_datetime", oRs(2).Value
					tpl_layout.Parse "onholidays"
				end if
			end if

			if oPlayerInfo("privilege") = -1 then
				tpl_layout.AssignValue "ban_datetime", oPlayerInfo("ban_datetime").Value
				tpl_layout.AssignValue "ban_reason", oPlayerInfo("ban_reason").Value
				tpl_layout.AssignValue "ban_reason_public", oPlayerInfo("ban_reason_public").Value

				if not IsNull(oPlayerInfo("ban_expire")) then
					tpl_layout.AssignValue "ban_expire_datetime", oPlayerInfo("ban_expire").Value
					tpl_layout.Parse "banned.expire"
				end if

				tpl_layout.Parse "banned"
			end if
		end if

		tpl_layout.AssignValue "userid", UserId
		tpl_layout.AssignValue "server", universe


		if not oPlayerInfo("paid") and Session(sPrivilege) < 100 then

			connectNexusDB
			set oRs = oNexusConn.Execute("SELECT sp_ad_get_code(" & UserId & ")")
			if not oRs.EOF then
				if not isnull(oRs(0)) then
					tpl_layout.AssignValue "ad_code", oRs(0)
					tpl_layout.Parse "ads.code"
				end if
			end if

			tpl_layout.Parse "ads"
			oConn.Execute "UPDATE users SET displays_pages=displays_pages+1 WHERE id=" & UserId, , adExecuteNoRecords
		end if

		tpl_layout.Parse "menu"

		if not oPlayerInfo("inframe") then
			tpl_layout.Parse "test_frame"
		end if

		tpl_layout.Parse ""

		'
		' Write the template to the client
		'
		Session("details") = "sending page"
		Response.Write tpl_layout.Output
	end if

	oPlayerInfo.Close
	set oPlayerInfo = Nothing

	logpage()

	oConn.Close
	set oConn = Nothing
end sub

'
' Check that our user is valid, otherwise redirect user to home page
'
sub CheckSessionValidity()
	UserID = Session(sUser)

'if UserID = 5 then
'	Response.write allowedOrientations
'	Response.end
'end if

	' check that this session is still used
	' if a user tries to login multiple times, the first sessions are abandonned
	dim oRs, query

	query = "SELECT ""login"", privilege, lastlogin, credits, lastplanetid, deletion_date, score, planets, previous_score," &_
			"alliance_id, alliance_rank, leave_alliance_datetime IS NULL AND (alliance_left IS NULL OR alliance_left < now()) AS can_join_alliance," &_
			"credits_bankruptcy, mod_planets, mod_commanders," &_
			"ban_datetime, ban_expire, ban_reason, ban_reason_public, orientation, (paid_until IS NOT NULL AND paid_until > now()) AS paid," &_
			" timers_enabled, display_alliance_planet_name, prestige_points, (inframe IS NOT NULL AND inframe) AS inframe, COALESCE(skin, 's_default') AS skin," &_
			"lcid, security_level, (SELECT username FROM exile_nexus.users WHERE id=" & UserId & ") AS username" &_
			" FROM users" &_
			" WHERE id=" & UserId
	set oPlayerInfo = oConn.Execute(query)

	SecurityLevel = oPlayerInfo("security_level")
	displayAlliancePlanetName = oPlayerInfo("display_alliance_planet_name")

	Session.LCID = oPlayerInfo("lcid")

	if session(sprivilege) < 100 then
		if Request.Cookies("login") = "" then
			Response.Cookies("login") = oPlayerInfo("login")
			Response.Cookies("login").Expires = now()+1
		elseif Request.Cookies("login") <> oPlayerInfo("login") then
			log_notice "login cookie", "Last browser login cookie : """ & Request.Cookies("login") & """", 1

			Response.Cookies("login") = oPlayerInfo("login")
			Response.Cookies("login").Expires = now()+1
		end if
	end if


	' check account still exists or that the player didn't connect with another account meanwhile
	if oPlayerInfo.EOF or (Application("usersession" & UserId) <> Session.SessionID and Session(sprivilege) = 0) then'(oPlayerInfo("lastlogin") <> Session(sLastLogin) and Session(sprivilege) = 0) then
		Session.Abandon ' Abandon session
		Response.Redirect "/" ' Redirect to home page
		Response.End
	end if

	if IsPlayerAccount() then
		' Redirect to locked page
		if oPlayerInfo("privilege") = -1 then RedirectTo "locked.asp"

		' Redirect to holidays page
		if oPlayerInfo("privilege") = -2 then RedirectTo "holidays.asp"

		' Redirect to wait page
		if oPlayerInfo("privilege") = -3 then RedirectTo "wait.asp"

		' Redirect to game-over page
		if oPlayerInfo("credits_bankruptcy") <= 0 then RedirectTo "game-over.asp"
	end if


	AllianceId = oPlayerInfo("alliance_id")
	AllianceRank = oPlayerInfo("alliance_rank")
	oAllianceRights = Null

	if not IsNull(AllianceId) then
		query = "SELECT label, leader, can_invite_player, can_kick_player, can_create_nap, can_break_nap, can_ask_money, can_see_reports, can_accept_money_requests, can_change_tax_rate, can_mail_alliance," &_
				" can_manage_description, can_manage_announce, can_see_members_info, can_use_alliance_radars, can_order_other_fleets" &_
				" FROM alliances_ranks" &_
				" WHERE allianceid=" & AllianceId & " AND rankid=" & AllianceRank
		set oAllianceRights = oConn.Execute(query)

		if oAllianceRights.EOF then
			oAllianceRights = Null
			AllianceId = Null
		end if
	end if


	' log activity
	if not IsImpersonating then	connExecuteRetryNoRecords "SELECT sp_log_activity(" & UserId & "," & dosql(Request.ServerVariables("REMOTE_ADDR")) & "," & browserid & ")"
end sub

' set the new current planet, if the planet doesn't belong to the player then go back to the session planet
function SetCurrentPlanet(planetid)
	dim oRs, galaxyid, sectorid

	SetCurrentPlanet = false

	'
	' Check if a parameter is given and if different than the current planet
	' In that case, try to set it as the new planet : check that this planet belongs to the player
	'
	if (planetid <> "") and (planetid <> CurrentPlanet) then
		' check that the new planet belongs to the player
		set oRs = oConn.Execute("SELECT galaxy, sector FROM nav_planet WHERE planet_floor > 0 AND planet_space > 0 AND id=" & planetid & " and ownerid=" & UserID)
		if not oRs.EOF then
			CurrentPlanet = planetid
			CurrentGalaxyId = oRs(0)
			CurrentSectorId = oRs(1)
			Session.Contents(sPlanet) = planetid

			oRs.Close
			set oRs = Nothing

			' save the last planetid
			if not IsImpersonating then
				on error resume next
				oConn.Execute "UPDATE users SET lastplanetid=" & planetid & " WHERE id=" & UserId, , adExecuteNoRecords
				on error goto 0
			end if

			SetCurrentPlanet = true

			exit function
		end if

		InvalidatePlanetList()
	end if

	' 
	' retrieve current planet from session
	'
	CurrentPlanet = Session(sPlanet)

	if CurrentPlanet <> "" then
		' check if the planet still belongs to the player
		set oRs = oConn.Execute("SELECT galaxy, sector FROM nav_planet WHERE planet_floor > 0 AND planet_space > 0 AND id=" & CurrentPlanet & " AND ownerid=" & UserID)
		if not oRs.EOF then
			' the planet still belongs to the player, exit
			CurrentGalaxyId = oRs(0)
			CurrentSectorId = oRs(1)
			SetCurrentPlanet = true
			oRs.Close
			set oRs = Nothing
			exit function
		end if

		InvalidatePlanetList()
	end if

	' there is no active planet, select the first planet available
	set oRs = oConn.Execute("SELECT id, galaxy, sector FROM nav_planet WHERE planet_floor > 0 AND planet_space > 0 AND ownerid=" & UserID & " LIMIT 1")

	' if player owns no planets then the game is over
	if oRs.EOF then
		if IsPlayerAccount() then
			RedirectTo "game-over.asp"
		else
			CurrentPlanet = 0
			CurrentGalaxyId = 0
			CurrentSectorId = 0

			SetCurrentPlanet = true
			exit function
		end if
	end if

	' assign planet id
	CurrentPlanet = oRs(0)
	CurrentGalaxyId = oRs(1)
	CurrentSectorId = oRs(2)
	Session.Contents(sPlanet) = CurrentPlanet

	oRs.Close
	set oRs = Nothing

	' save the last planetid
	if not IsImpersonating then
		on error resume next
		oConn.Execute "UPDATE users SET lastplanetid=" & CurrentPlanet & " WHERE id=" & UserId, , adExecuteNoRecords
		on error goto 0
	end if

	' a player may wish to destroy a building on a planet that belonged to him
	' if the planet doesn't belong to him anymore, the action may be performed on another planet
	' so we redirect the user to the overview to prevent executing an order on another planet
	Response.Redirect "/game/overview.asp"
	Response.End

	SetCurrentPlanet = true
end function

'
' check if a planet is given in the querystring and that it belongs to the player
'
sub CheckCurrentPlanetValidity()
	dim id

	' retrieve planet parameter if any
	id = ToInt(Request.QueryString("planet"), "")

	SetCurrentPlanet id
end sub


Session("details") = ""


' Check that this session is still valid
CheckSessionValidity()

' Check for the planet querystring parameter and if the current planet belongs to the player
CheckCurrentPlanetValidity()

checkPlanetListCache()

dim referer
referer = Request.ServerVariables("HTTP_REFERER")

if referer <> "" then
	dim websitename, posslash

	' extract the website part from the referer url
	posslash = instr(8, referer, "/")
	if posslash > 0 then
		websitename = mid(referer, 8, posslash-8)
	else
		websitename = mid(referer, 8)
	end if

	if instr(LCase(referer), "exil.pw") = 0 and instr(LCase(referer), Request.ServerVariables("LOCAL_ADDR")) = 0 and instr(LCase(referer), "viewtopic") = 0 and instr(LCase(referer), "forum") = 0 then
		oConn.Execute "SELECT sp_log_referer("&UserId&","&dosql(referer) & ")", , adExecuteNoRecords
	end if
end if


if Session(sPrivilege) >= 100 then
'	set tpl_layout = GetTemplate("layout-dev")

	if Request.QueryString("impersonate") = "revert" then Impersonate Session(sLogonUserID)
end if

%>