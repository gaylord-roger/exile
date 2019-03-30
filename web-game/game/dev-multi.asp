<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "log_multi"

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-multi")

	dim oRs, query

	query = "SELECT datetime, userid, login, sp__itoa(address), forwarded_address, browser," &_
			" datetime2, userid2, login2, sp__itoa(address2), forwarded_address2, browser2," &_
			" sent_to, received_from, samepassword," &_
			" regdate, email, regdate2, email2, samealliance, a_given1, a_taken1, a_given2, a_taken2," &_
			" browserid, disconnected, browserid2, disconnected2, browserid = browserid2," &_
			" privilege, privilege2, tag, tag2" &_
			" FROM admin_view_multi_accounts" &_
			" WHERE datetime > now()-INTERVAL '2 days' LIMIT 2000"

	set oRs = oConn.Execute(query)

	while not oRs.EOF
		
		content.AssignValue "timestamp", oRs(0)
		content.AssignValue "userid", oRs(1)
		content.AssignValue "login", oRs(2)
		content.AssignValue "address", oRs(3)
		content.AssignValue "forwarded_address", oRs(4)
		content.AssignValue "browser", oRs(5)
		content.AssignValue "timestamp2", oRs(6)
		content.AssignValue "userid2", oRs(7)
		content.AssignValue "login2", oRs(8)
		content.AssignValue "address2", oRs(9)
		content.AssignValue "forwarded_address2", oRs(10)
		content.AssignValue "browser2", oRs(11)
		content.AssignValue "sent_to", oRs(12)
		content.AssignValue "received_from", oRs(13)

		content.AssignValue "regdate", oRs(15)
		content.AssignValue "email", oRs(16)
		content.AssignValue "regdate2", oRs(17)
		content.AssignValue "email2", oRs(18)

		content.AssignValue "alliance1", oRs(31)
		content.AssignValue "alliance2", oRs(32)

		if oRs(14) then content.Parse "item.samepassword"
		if oRs(19) then 
			content.AssignValue "given1", oRs(20)
			content.AssignValue "taken1", oRs(21)
			content.AssignValue "given2", oRs(22)
			content.AssignValue "taken2", oRs(23)

			content.Parse "item.samealliance"
		end if

		content.AssignValue "browserid", oRs(24)
		if not isnull(oRs(25)) then
			content.AssignValue "disconnected", oRs(25).Value
			content.Parse "item.disconnected"
		end if

		content.AssignValue "browserid2", oRs(26)
		if not isnull(oRs(27)) then
			content.AssignValue "disconnected2", oRs(27).Value
			content.Parse "item.disconnected2"
		end if

		if oRs(28) and oRs(29) = 0 and oRs(30) = 0 then content.Parse "item.samebrowserid"

		if oRs(29) = 0 then content.Parse "item.can_ban_multi"
		if oRs(30) = 0 then content.Parse "item.can_ban_multi2"

		content.Parse "item"
		oRs.MoveNext
	wend

	content.Parse ""

	Display(content)
end sub

if Session("privilege") < 100 then
	response.Redirect "/"
	response.End
end if

DisplayForm()

%>