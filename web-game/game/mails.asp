<% option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "mails"

'
' display mails received by the player
'
function display_mails
'	if session(sprivilege) < 100 then
'		response.write "en maintenance"
'		response.End
'	end if

	dim oRs, query, i

	selected_menu = "mails.inbox"

	dim content
	set content = GetTemplate("mail-list")
	'content.addAllowedImageDomain "https://*.zod.fr/*"
	'content.addAllowedImageDomain "https://img.exil.pw/*"
	content.addAllowedImageDomain "https://forum.exil.pw/img/*"

	dim displayed, offset, size, nb_pages
	displayed = 30 ' number of messages displayed per page

	'
	' Retrieve the offset from where to begin the display
	'
	offset = ToInt(Request.QueryString("start"), 0)
	if offset > 50 then offset=50

	dim search_cond
	search_cond = ""
	if Session(sPrivilege) < 100 then search_cond = "not deleted AND "

	' get total number of mails that could be displayed
	query = "SELECT count(1) FROM messages WHERE "&search_cond&" ownerid = " & userid
	set oRs = oConn.Execute(query)
	size = clng(oRs(0))
	nb_pages = Int(size/displayed)
	if nb_pages*displayed < size then nb_pages = nb_pages + 1
	if offset >= nb_pages then offset = nb_pages-1

	content.AssignValue "offset", offset

	if nb_pages > 50 then nb_pages=50

	'if nb_pages <= 10 then display all links only if there are a few pages
		for i = 1 to nb_pages
			content.AssignValue "page_id", i
			content.AssignValue "page_link", i-1
			
			if i <> offset+1 then
				content.Parse "nav.p.link"
			else
				content.Parse "nav.p.selected"
			end if
			content.AssignValue "offset", offset
			content.Parse "nav.p"
		next

		content.AssignValue "min", offset*displayed+1
		if offset+1 = nb_pages then
			content.AssignValue "max", size
		else 
			content.AssignValue "max", (offset+1)*displayed
		end if
		content.AssignValue "page_display", offset+1
	'end if


	'display only if there are more than 1 page
	if nb_pages > 1 then content.Parse "nav"

	query = "SELECT sender, subject, body, datetime, messages.id, read_date, avatar_url, users.id, messages.credits," &_
			" users.privilege, bbcode, owner, messages_ignore_list.added, alliances.tag"&_
			" FROM messages" &_
			"	LEFT JOIN users ON (upper(users.login) = upper(messages.sender) AND messages.datetime >= users.game_started)" &_
			"	LEFT JOIN alliances ON (users.alliance_id = alliances.id)" &_
			"	LEFT JOIN messages_ignore_list ON (userid=" & userid & " AND ignored_userid = users.id)" &_
			" WHERE " & search_cond & " ownerid = " & userid &_
			" ORDER BY datetime DESC, messages.id DESC" &_
			" OFFSET " & (offset*displayed) & " LIMIT "&displayed
	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF

		content.AssignValue "index", i
		content.AssignValue "from", oRs(0)
		content.AssignValue "subject", oRs(1)
		content.AssignValue "date", oRs(3).Value

		if oRs(10) then
			content.AssignValue "bodybb", oRs(2)
			content.Parse "mail.bbcode"
		else
			content.AssignValue "body", replace(server.HTMLEncode(oRs(2)), vbCRLF, "<br/>")
			content.Parse "mail.html"
		end if

		content.AssignValue "mailid", oRs(4)
		content.AssignValue "moneyamount" , oRs(8)

		if oRs(8) > 0 then content.Parse "mail.money" ' sender has given money

		if oRs(9) >= 500 then content.Parse "mail.from_admin"

		if isNull(oRs(6)) or oRs(6) = "" then 
			content.Parse "mail.noavatar"
		else
			content.AssignValue "avatar_url", oRs(6)
			content.Parse "mail.avatar"
		end if

		if isNull(oRs(5)) then content.Parse "mail.new_mail" ' if there is no value for read_date then it is a new mail

		if not isNull(oRs(7)) then
			' allow the player to block/ignore another player
			if not IsNull(oRs(12)) then
				content.Parse "mail.reply.ignored"
			else
				content.Parse "mail.reply.ignore"
			end if

			if not isNull(oRs(13)) then
				content.AssignValue "alliancetag", oRs(13)
				content.Parse "mail.reply.alliance"
			end if

			content.Parse "mail.reply"
		end if

		select case oRs(11)
			case ":admins"
				content.Parse "mail.to_admins"
			case ":alliance"
				content.Parse "mail.to_alliance"
		end select

		if Session(sPrivilege) > 100 then content.Parse "mail.admin"

		content.Parse "mail"

		i = i + 1

		oRs.movenext
	wend

	if i = 0 then content.Parse "nomails"

	if not IsImpersonating then
		set oRs = oConn.Execute("UPDATE messages SET read_date = now() WHERE ownerid = " & userid & " AND read_date is NULL" )
	end if

	content.Parse ""

	display(content)
end function

'
' display mails sent by the player
'
function display_mails_sent
	dim oRs, query, i

	selected_menu = "mails.sent"

	dim content
	set content = GetTemplate("mail-sent")
	content.addAllowedImageDomain "https://*.zod.fr/*"
	content.addAllowedImageDomain "https://img.exil.pw/*"
	content.addAllowedImageDomain "https://forum.exil.pw/img/*"

	dim displayed, offset, size, nb_pages
	displayed = 30 ' number of nations displayed per page

	'
	' Retrieve the offset from where to begin the display
	'
	offset = ToInt(Request.QueryString("start"), 0)
	if offset > 50 then offset=50

	dim messages_filter
	messages_filter = "datetime > now()-INTERVAL '2 weeks' AND "
'	if Session(sPrivilege) >= 100 then messages_filter = ""

	' get total number of mails that could be displayed
	query = "SELECT count(1) FROM messages WHERE "&messages_filter&"senderid = " & userid
	set oRs = oConn.Execute(query)
	size = clng(oRs(0))
	nb_pages = Int(size/displayed)
	if nb_pages*displayed < size then nb_pages = nb_pages + 1

	if nb_pages > 50 then nb_pages=50

	'if nb_pages <= 10 then display all links only if there are a few pages
		for i = 1 to nb_pages
			content.AssignValue "page_id", i
			content.AssignValue "page_link", i-1
			
			if i <> offset+1 Then
				content.Parse "nav.p.link"
			else
				content.Parse "nav.p.selected"
			end if
			content.AssignValue "offset", offset
			content.Parse "nav.p"
		next

		content.AssignValue "min", offset*displayed+1
		if offset+1 = nb_pages then
			content.AssignValue "max", size
		else 
			content.AssignValue "max", (offset+1)*displayed
		end if
		content.AssignValue "page_display", offset+1
	'end if


	'display only if there are more than 1 page
	if nb_pages > 1 then content.Parse "nav"

	query = "SELECT messages.id, owner, avatar_url, datetime, subject, body, messages.credits, users.id, bbcode, alliances.tag"&_
			" FROM messages" &_
			"	LEFT JOIN users ON (/*upper(users.login) = upper(messages.owner)*/ users.id = messages.ownerid AND messages.datetime >= users.game_started)" &_
			"	LEFT JOIN alliances ON (users.alliance_id = alliances.id)" &_
			" WHERE "&messages_filter&"senderid = " & userid &_
			" ORDER BY datetime DESC"

	query = query + " OFFSET "&(offset*displayed)&" LIMIT "&displayed

	set oRs = oConn.Execute(query)

	i = 0
	while not oRs.EOF

		content.AssignValue "index", i
		content.AssignValue "sent_to", oRs(1)

		select case oRs(1).Value
			case ":admins"
				content.Parse "mail.admins"
			case ":alliance"
				content.Parse "mail.alliance"
			case else
				content.Parse "mail.nation"
		end select

		content.AssignValue "date", oRs(3).Value
		content.AssignValue "subject", oRs(4)

		if oRs("bbcode") then
			content.AssignValue "bodybb", oRs(5)
			content.Parse "mail.bbcode"
		else
			content.AssignValue "body", replace(server.HTMLEncode(oRs(5)), vbCRLF, "<br/>")
			content.Parse "mail.html"
		end if

		content.AssignValue "mailid", oRs(0)
		content.AssignValue "moneyamount", oRs(6)

		if oRs(6) > 0 then ' sender has given money
			content.Parse "mail.money"
		end if

		if isNull(oRs(2)) or oRs(2) = "" then 
			content.Parse "mail.noavatar"
		else
			content.AssignValue "avatar_url", oRs(2)
			content.Parse "mail.avatar"
		end if

		if not isNull(oRs(7)) then
			if not isNull(oRs(9)) then
				content.AssignValue "alliancetag", oRs(9)
				content.Parse "mail.reply.alliance"
			end if
			content.Parse "mail.reply"
		end if

		content.Parse "mail"

		i = i + 1

		oRs.movenext
	wend

	if i = 0 then content.Parse "nomails"

	content.Parse ""
	display(content)
end function

sub display_ignore_list()
	selected_menu = "mails.ignorelist"

	dim oRs, query, content, i

	set content = GetTemplate("mail-ignorelist")

	set oRs = oConn.Execute("SELECT ignored_userid, sp_get_user(ignored_userid), added, blocked FROM messages_ignore_list WHERE userid=" & userid)

	i = 0
	while not oRs.EOF
		content.AssignValue "index", i
		content.AssignValue "userid", oRs(0)
		content.AssignValue "name", oRs(1)
		content.AssignValue "added", oRs(2).Value
		content.AssignValue "blocked", oRs(3)
		content.Parse "ignorednation"

		i = i + 1

		oRs.MoveNext
	wend

	if i = 0 then content.Parse "noignorednations"

	content.Parse ""

	Display(content)
end sub

sub return_ignored_users()
	dim oRs, query, content

	set content = GetTemplate("mails")

	set oRs = oConn.Execute("SELECT sp_get_user(ignored_userid) FROM messages_ignore_list WHERE userid=" & userid)
	while not oRs.EOF
		content.AssignValue "user", oRs(0)
		content.Parse "ignored_user"

		oRs.MoveNext
	wend

	content.Parse ""

	response.write content.Output
	response.End
end sub


' quote reply
function quote_mail(body)
	quote_mail = Replace(body, vbCRLF, vbCRLF & "> ") & vbCRLF & vbCRLF
end function


dim sendmail_status: sendmail_status=""

' fill combobox with previously sent to
function display_compose_form(mailto, subject, body, credits)

	selected_menu = "mails.compose"

	dim content
	set content = GetTemplate("mail-compose")

	' fill the recent addressee list
	dim oRs
	set oRs = oConn.Execute("SELECT * FROM sp_get_addressee_list(" & UserId & ")")

	while not oRs.EOF
		content.AssignValue "to_user", oRs(0)
		content.parse "to"

		oRs.movenext
	wend


	select case mailto
		case ":admins"
			content.Parse "sendadmins.selected"

			content.Parse "hidenation"
			content.Parse "send_credits.hide"
			mailto = ""
		case ":alliance"
			content.Parse "sendalliance.selected"

			content.Parse "hidenation"
			content.Parse "send_credits.hide"
			mailto = ""
		case else
			content.Parse "nation_selected"
	end select

	if not IsNull(oAllianceRights) then
		if oAllianceRights("can_mail_alliance") then content.Parse "sendalliance"
	end if

	if hasAdmins then content.Parse "sendadmins"

	' if is a payed account, append the autosignature text to message body
	if oPlayerInfo("paid") then
		set oRs = oConn.Execute("SELECT autosignature FROM users WHERE id="&userid)
		if not oRs.EOF then
			body = body  & oRs(0)
		end if
	end if



	' re-assign previous values
	content.AssignValue "mailto", mailto
	content.AssignValue "subject", subject
	content.AssignValue "message", body
	content.AssignValue "credits", credits

	'retrieve player's credits
	set oRs = oConn.Execute("SELECT credits, now()-game_started > INTERVAL '2 weeks' AND security_level >= 3 FROM users WHERE id="&UserID)
	content.AssignValue "player_credits", oRs(0)
	if oRs(1) then content.Parse "send_credits"

	if sendmail_status <> "" then
		content.Parse "error." & sendmail_status
		content.Parse "error"
	end if

	if bbcode then content.Parse "bbcode"

	content.Parse ""

	FillHeaderCredits

	display(content)
end function


dim oRs, query
dim id, compose, mailto, mailsubject, mailbody, moneyamount, bbcode

compose = false
mailto = ""
mailsubject = ""
mailbody = ""
moneyamount = 0
bbcode = false

' new email
if Request.Form("compose") <> "" then
	compose = true
elseif Request.QueryString("to") <> "" then
	mailto = Request.QueryString("to")
	mailsubject = Request.QueryString("subject")
	compose = true
elseif Request.QueryString("a") = "new" then

	mailto = Request.QueryString("b")
	if mailto = "" then mailto = Request.QueryString("to")
	mailsubject = Request.QueryString("subject")
	compose = true

' reply
elseif Request.QueryString("a") = "reply" then

	Id = ToInt(Request.QueryString("mailid"), 0)

	query = "SELECT sender, subject, body FROM messages WHERE ownerid=" & UserId & " AND id=" & Id & " LIMIT 1"
	Session("details") = query
	set oRs = oConn.Execute(query)

	if not oRs.EOF then

		mailto = oRs(0)
			
		' adds 'Re: ' to new reply
		
		if InStr(1, oRs(1), "Re:", 1) > 0 then 
			mailsubject = oRs(1)
		else
			mailsubject = "Re: " & oRs(1)
		end if
		
		mailbody = quote_mail("> " & oRs(2) & vbCRLF)

		compose = true
	end if

' send email
elseif Request.Form("sendmail") <> "" and not IsImpersonating() then

	compose = true

	mailto = Trim(Request.Form("to"))
	mailsubject = Trim(Request.Form("subject"))
	mailbody = Trim(Request.Form("message"))

	if Request.Form("sendcredits") = 1 then
		moneyamount = ToInt(Request.Form("amount"), 0)
	else
		moneyamount = 0
	end if

	bbcode = Request.Form("bbcode") = 1

	if mailbody = "" then
		sendmail_status = "mail_empty"
	else
		select case Request.Form("type")
			case "admins"
				mailto = ":admins"
				moneyamount = 0
			case "alliance"
				' send the mail to all members of the alliance except 
				mailto = ":alliance"
				moneyamount = 0
		end select

		if mailto = "" then
			sendmail_status = "mail_missing_to"
		else
			set oRs = oConn.Execute("SELECT sp_send_message("& userid & "," & dosql(mailto) & "," & dosql(mailsubject) & "," & dosql(mailbody) & "," & moneyamount & "," & bbcode & ")")

			if oRs(0) <> 0 then
				select case oRs(0)
				case 1
					sendmail_status = "mail_unknown_from" ' from not found
				case 2
					sendmail_status = "mail_unknown_to" ' to not found
				case 3
					sendmail_status = "mail_same" ' send to same person
				case 4
					sendmail_status = "not_enough_credits" ' not enough credits
				case 9
					sendmail_status = "blocked" ' messages are blocked
				end select

			else
				sendmail_status = "mail_sent"

				mailsubject = ""
				mailbody = ""
				moneyamount = 0
			end if
		end if

	end if

' delete selected emails
elseif Request.Form("delete") <> "" then

	dim mailid

	' build the query of which mails to delete
	query = "false"

	for each mailid in Request.Form("checked_mails")
		query = query & " OR id=" & dosql(mailid)
	next

	if query <> "false" then
		oConn.Execute "UPDATE messages SET deleted=true WHERE (" & query & ") AND ownerid = " & userid
	end if
end if

if Request.QueryString("a") = "ignore" then
	oConn.Execute "SELECT sp_ignore_sender(" & userid & "," & dosql(Request.QueryString("user")) & ")"

	return_ignored_users
	response.end
end if

if Request.QueryString("a") = "unignore" then
	oConn.Execute "DELETE FROM messages_ignore_list WHERE userid=" & userid & " AND ignored_userid=(SELECT id FROM users WHERE lower(login)=lower(" & dosql(Request.QueryString("user")) & "))"

	return_ignored_users()
	response.end
end if

if compose then
	display_compose_form mailto, mailsubject, mailbody, moneyamount
elseif Request.QueryString("a") = "ignorelist" then
	display_ignore_list
elseif Request.QueryString("a") = "unignorelist" then
	for each mailto in Request.Form("unignore")
		oConn.Execute "DELETE FROM messages_ignore_list WHERE userid=" & userid & " AND ignored_userid=" & dosql(mailto)
	next

	display_ignore_list
elseif Request.QueryString("a") = "sent" then
	display_mails_sent
else
	display_mails
end if

%>