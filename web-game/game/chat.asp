<%option explicit %>

<!--#include file="global.asp"-->

<%

const onlineusers_refreshtime = 60

selected_menu = "chat"

function getChatId(id)
	getChatId = id

	dim query, oRs

	if id = 0 and not IsNull(AllianceId) then
		getChatId = Application("alliancechat_" & AllianceId)

		if getChatId = "" or not IsNumeric(getChatId) then
			query = "SELECT chatid FROM alliances WHERE id=" & AllianceId
			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				Application("alliancechat_" & AllianceId) = oRs(0)
				getChatId = oRs(0)
			end if
		end if
	end if
end function

sub addLine(chatid, msg)
	msg = Left(Trim(msg), 260)

	if msg <> "" then
		dim oRs
'		set oRs = connExecuteRetry("SELECT sp_chat_append
'		set oRs = connExecuteRetry("INSERT INTO chat_lines(chatid, allianceid, userid, login, message) VALUES(" & chatid & "," & sqlValue(AllianceId) & "," & dosql(UserId) & "," & dosql(oPlayerInfo("login")) & "," & dosql(msg) & ") RETURNING id")
'		Application("chat_lastmsg_" & getChatId(chatid)) = oRs(0)
		connExecuteRetryNoRecords "INSERT INTO chat_lines(chatid, allianceid, userid, login, message) VALUES(" & chatid & "," & sqlValue(AllianceId) & "," & dosql(UserId) & "," & dosql(oPlayerInfo("login")) & "," & dosql(msg) & ")"

'		chatid = getChatId(chatid)
'		connExecuteRetryNoRecords "INSERT INTO chat_onlineusers(chatid, userid) VALUES(" & chatid & "," & UserId & ")"
	end if

	Response.Write " " ' return an empty string : fix safari "undefined XMLHttpRequest.status" bug
end sub

sub refreshContent(chatid)
	if chatid <> 0 and Session("chat_joined_" & chatid) <> "1" then exit sub

	dim userChatId: userChatId = chatid

	chatid = getChatId(chatid)

	dim refresh_userlist, oRs
	refresh_userlist = Timer() - Session("lastchatactivity_" & chatid) > onlineusers_refreshtime

'	if IsEmpty(Application("chat_lastmsg_" & chatid)) then Application("chat_lastmsg_" & chatid) = "0"

'	if Session("lastchatmsg_" & chatid) <> Application("chat_lastmsg_" & chatid) then
		' retrieve new chat lines
		dim lastmsgid
		lastmsgid = Session("lastchatmsg_" & chatid)
		if lastmsgid = "" then lastmsgid = 0

		dim query
		query = "SELECT chat_lines.id, datetime, allianceid, login, message" &_
				" FROM chat_lines" &_
				" WHERE chatid=" & chatid & " AND chat_lines.id > GREATEST((SELECT id FROM chat_lines WHERE chatid="& chatid &" ORDER BY datetime DESC OFFSET 100 LIMIT 1), " & dosql(lastmsgid) & ")" &_
				" ORDER BY chat_lines.id"
		set oRs = oConn.Execute(query)

		if oRs.EOF then oRs = Empty
'	end if

	' if there's no line to send and no list of users to send, exit
	if IsEmpty(oRs) and not refresh_userlist then
		Response.Write " " ' return an empty string : fix safari "undefined XMLHttpRequest.status" bug
		exit sub
	end if


	' load the template
	dim content
	set content = GetTemplate("chat")
	content.AssignValue "login", oPlayerInfo("login")
	content.AssignValue "chatid", userChatId

	if not IsEmpty(oRs) then
		while not oRs.EOF
			session("lastchatmsg_" & chatid) = oRs(0)

			content.AssignValue "lastmsgid", oRs(0)
			content.AssignValue "datetime", oRs(1).value
			content.AssignValue "author", oRs(3)
			content.AssignValue "line", oRs(4)
			content.AssignValue "alliancetag", getAllianceTag(oRs(2))
			content.Parse "refresh.line"
			oRs.MoveNext
		wend
	end if

	' update user lastactivity in the DB and retrieve users online only every 3 minutes
	if refresh_userlist then
		if session(sprivilege) < 100 then	' prevent admin from showing their presence in chat
			on error resume next

			connExecuteRetryNoRecords "INSERT INTO chat_onlineusers(chatid, userid) VALUES(" & chatid & "," & UserId & ")"

			on error goto 0
		end if
		Session("lastchatactivity_" & chatid) = Timer()

		' retrieve online users in chat
		query = "SELECT users.alliance_id, users.login, date_part('epoch', now()-chat_onlineusers.lastactivity)" &_
				" FROM chat_onlineusers" &_
				"	INNER JOIN users ON (users.id=chat_onlineusers.userid)" &_
				" WHERE chat_onlineusers.lastactivity > now()-INTERVAL '10 minutes' AND chatid=" & chatid
		set oRs = oConn.Execute(query)

		while not oRs.EOF
			content.AssignValue "alliancetag", getAllianceTag(oRs(0))
			content.AssignValue "user", oRs(1)
			content.AssignValue "lastactivity", oRs(2)
			content.Parse "refresh.online_users.user"
			oRs.MoveNext
		wend

		content.Parse "refresh.online_users"
	end if

	content.Parse "refresh"
	content.Parse ""
	Response.Write content.Output
end sub


sub refreshChat(chatid)
'	if session(sprivilege) > 100 then RedirectTo "/"

	refreshContent chatid
end sub

sub displayChatList()
	dim content
	set content = GetTemplate("chat")
	content.AssignValue "login", oPlayerInfo("login")

	dim oRs, query
	query = "SELECT name, topic, count(chat_onlineusers.userid)" &_
			" FROM chat" &_
			"	LEFT JOIN chat_onlineusers ON (chat_onlineusers.chatid = chat.id AND chat_onlineusers.lastactivity > now()-INTERVAL '10 minutes')" &_
			" WHERE name IS NOT NULL AND password = '' AND public" &_
			" GROUP BY name, topic" &_
			" ORDER BY length(name), name"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		content.AssignValue "name", oRs(0)
		content.AssignValue "topic", oRs(1)
		content.AssignValue "online", oRs(2)

		content.Parse "publicchats.chat"

		oRs.MoveNext
	wend

	content.Parse "publicchats"
	content.Parse ""
	Response.Write content.Output
end sub

' add a chat to the joined chat list
function addChat(chatid)
	addChat = true

	Session("lastchatactivity_" & chatid) = Timer()-onlineusers_refreshtime

	if Session("chat_joined_" & chatid) <> "1" then
		Session("chat_joined_count") = Session("chat_joined_count") + 1
		Session("chat_joined_" & chatid) = "1"

'		dim i
'		for i = 0 to 10
'			if Session("chat_" & i) = "" then
'				Session("chat_" & i) = chatid
'				exit for
'			end if
'		next

		addChat = true
	end if
end function

' remove a chat from list
sub removeChat(chatid)
	if Session("chat_joined_" & chatid) = "1" then
		Session("chat_joined_" & chatid) = ""
		Session("chat_joined_count") = Session("chat_joined_count") - 1
	end if
end sub


sub displayChat()
	Session("chatinstance") = Session("chatinstance") + 1

	dim content, chatid
	set content = GetTemplate("chat")
	content.AssignValue "login", oPlayerInfo("login")
	content.AssignValue "chatinstance", Session("chatinstance")

	if not IsNull(AllianceId) then
		chatid = getChatId(0)
		Session("lastchatmsg_" & chatid) = ""
		Session("lastchatactivity_" & chatid) = Timer()-onlineusers_refreshtime

		content.Parse "alliance"
	end if

	dim query, oRs

	query = "SELECT chat.id, chat.name, chat.topic" &_
			" FROM users_chats" &_
			"	INNER JOIN chat ON (chat.id=users_chats.chatid AND ((chat.password = '') OR (chat.password = users_chats.password)))" &_
			" WHERE userid = " & UserId &_
			" ORDER BY users_chats.added"
	set oRs = oConn.Execute(query)

	while not oRs.EOF
		if addChat(oRs(0)) then
			content.AssignValue "id", oRs(0)
			content.AssignValue "name", oRs(1)
			content.AssignValue "topic", oRs(2)
			content.Parse "join"

			Session("lastchatmsg_" & oRs(0)) = ""
		end if

		oRs.MoveNext
	wend

'	if session(sprivilege) > 100 then content.Parse "chat.dev"

	content.AssignValue "now", now()

	content.Parse "chat"
	content.Parse ""
	display(content)
end sub


sub joinChat()
	dim content
	set content = GetTemplate("chat")
	content.AssignValue "login", oPlayerInfo("login")

	dim query, oRs, chatid, pass
	pass = Trim(Request.QueryString("pass"))

	' join chat
	query = "SELECT sp_chat_join(" & dosql(Trim(Request.QueryString("chat"))) & "," & dosql(pass) & ")"
	set oRs = oConn.Execute(query)

	chatid = oRs(0)

	if not addChat(oRs(0)) then exit sub


	if chatid <> 0 then
		on error resume next
		Err.Clear

		' save the chatid to the user chatlist
		query = "INSERT INTO users_chats(userid, chatid, password) VALUES(" & UserId & "," & chatid & "," & dosql(pass) & ")"
		oConn.Execute query, , adExecuteNoRecords

		if Err.Number = 0 then

			query = "SELECT name, topic FROM chat WHERE id=" & chatid
			set oRs = oConn.Execute(query)

			if not oRs.EOF then
				content.AssignValue "id", chatid
				content.AssignValue "name", oRs(0)
				content.AssignValue "topic", oRs(1)
				content.Parse "join.setactive"
				content.Parse "join"

				Session("lastchatmsg_" & chatid) = ""
			end if
		else
			content.Parse "join_error"
		end if

		on error goto 0
	else
		content.Parse "join_badpassword"
	end if

	content.Parse ""
	Response.Write(content.Output)
end sub


sub leaveChat(chatid)
	Session("lastchatmsg_" & chatid) = ""

	removeChat chatid

	dim query
	query = "DELETE FROM users_chats WHERE userid=" & UserId & " AND chatid=" & chatid
	oConn.Execute query, , adExecuteNoRecords

	query = "DELETE FROM chat WHERE id > 0 AND NOT public AND name IS NOT NULL AND id=" & chatid & " AND (SELECT count(1) FROM users_chats WHERE chatid=chat.id) = 0"
	oConn.Execute query, , adExecuteNoRecords
end sub


dim chatid, action, contentOnly
chatid = ToInt(Request.QueryString("id"), 0)
action = Request.QueryString("a")

if action = "send" then
	addLine chatid, Request.QueryString("l")
	logpage()
	response.end
end if

if action = "refresh" then
	refreshChat chatid
	logpage()
	response.end
end if

if action = "join" then
	joinChat
	logpage()
	response.end
end if

if action = "leave" then
	leaveChat chatid
	logpage()
	response.end
end if

if action = "chatlist" then
	displayChatList
	logpage()
	response.end
end if

displayChat

%>