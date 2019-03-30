<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "alliance.tributes"

dim invitation_success, cease_success
invitation_success = ""
cease_success = ""

sub DisplayTributesReceived(content)
	dim col, reversed, orderby
	col = Request.QueryString("col")
	if col < 1 or col > 2 then col = 1

	select case col
		case 1
			orderby = "tag"
		case 2
			orderby = "created"
			reversed = true
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "tributes_received.r" & col
	end if

	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", tag"

	' List
	dim query, oRs
	query = "SELECT w.created, alliances.id, alliances.tag, alliances.name, w.credits, w.next_transfer"&_
			" FROM alliances_tributes w" &_
			"	INNER JOIN alliances ON (allianceid = alliances.id)" &_
			" WHERE target_allianceid=" & AllianceId &_
			" ORDER BY " & orderby
	set oRs = oConn.Execute(query)

	dim i
	i = 0
	while not oRs.EOF
		content.AssignValue "place", i+1
		content.AssignValue "created", oRs(0).Value
		content.AssignValue "tag", oRs(2)
		content.AssignValue "name", oRs(3)
		content.AssignValue "credits", oRs(4)
		content.AssignValue "next_transfer", oRs(5).Value

		content.Parse "tributes_received.item"

		i = i + 1
		oRs.MoveNext
	wend

	if i = 0 then content.Parse "tributes_received.none"

	content.Parse "tributes_received"
end sub

sub DisplayTributesSent(content)
	dim col, reversed, orderby
	col = Request.QueryString("col")
	if col < 1 or col > 2 then col = 1

	select case col
		case 1
			orderby = "tag"
		case 2
			orderby = "created"
			reversed = true
	end select

	if Request.QueryString("r") <> "" then
		reversed = not reversed
	else
		content.Parse "tributes_sent.r" & col
	end if

	if reversed then orderby = orderby & " DESC"
	orderby = orderby & ", tag"

	' List
	dim query, oRs
	query = "SELECT w.created, alliances.id, alliances.tag, alliances.name, w.credits"&_
			" FROM alliances_tributes w" &_
			"	INNER JOIN alliances ON (target_allianceid = alliances.id)" &_
			" WHERE allianceid=" & AllianceId &_
			" ORDER BY " & orderby
	set oRs = oConn.Execute(query)

	dim i
	i = 0
	while not oRs.EOF
		content.AssignValue "place", i+1
		content.AssignValue "created", oRs(0).Value
		content.AssignValue "tag", oRs(2)
		content.AssignValue "name", oRs(3)
		content.AssignValue "credits", oRs(4)

		if oAllianceRights("can_break_nap") then content.Parse "tributes_sent.item.cancel"

		content.Parse "tributes_sent.item"

		i = i + 1
		oRs.MoveNext
	wend

	if oAllianceRights("can_break_nap") and (i > 0) then content.Parse "tributes_sent.cancel"

	if i = 0 then content.Parse "tributes_sent.none"

	if cease_success <> "" then
		content.Parse "tributes_sent.message." & cease_success
		content.Parse "tributes_sent.message"
	end if

	content.Parse "tributes_sent"
end sub


sub displayNew(content)
	dim i, query, oRs

	if invitation_success <> "" then
		content.Parse "new.message." & invitation_success
		content.Parse "new.message"
	end if

	content.AssignValue "tag", tag
	content.AssignValue "credits", credits

	content.Parse "new"
end sub

sub displayPage(cat)
	dim content, i
	set content = GetTemplate("alliance-tributes")
	content.AssignValue "cat", cat

	select case cat
		case 1
			displayTributesReceived content
		case 2
			displayTributesSent content
		case 3
			displayNew content
	end select

	content.Parse "nav.cat" & cat & ".selected"

	content.Parse "nav.cat1"
	content.Parse "nav.cat2"
	if oAllianceRights("can_create_nap") then content.Parse "nav.cat3"
	content.Parse "nav"
	content.Parse ""
	Display(content)
end sub

dim cat
cat = Request.QueryString("cat")
if cat < 1 or cat > 3 then cat = 1

if not (oAllianceRights("can_create_nap") or oAllianceRights("can_break_nap")) and cat = 3 then cat = 1

'
' Process actions
'

' redirect the player to the alliance page if he is not part of an alliance
if IsNull(AllianceId) then
	Response.Redirect "/game/alliance.asp"
	Response.End
end if

dim action
action = Request.QueryString("a")

dim tag

tag = ""

dim oRs

select case action
	case "cancel"
		tag = Trim(Request.QueryString("tag"))
		set oRs = oConn.Execute("SELECT sp_alliance_tribute_cancel(" & UserId & "," & dosql(tag) & ")")

		select case oRs(0)
			case 0
				cease_success = "ok"
			case 1
				cease_success = "norights"
			case 2
				cease_success = "unknown"
		end select
	case "new"
		dim credits

		tag = Trim(Request.Form("tag"))
		credits = ToInt(Request.Form("credits"), 0)


		set oRs = oConn.Execute("SELECT sp_alliance_tribute_new(" & UserID & "," & dosql(tag) & "," & dosql(credits) & ")")
		select case oRs(0)
			case 0
				invitation_success = "ok"
				tag = ""
			case 1
				invitation_success = "norights"
			case 2
				invitation_success = "unknown"
			case 3
				invitation_success = "already_exists"
		end select
end select

displayPage(cat)

%>