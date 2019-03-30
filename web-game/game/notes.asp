<% Option explicit%>

<!--#include file="global.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<%
selected_menu = "notes"

dim notes_status: notes_status = ""

sub display_notes
	dim content
	set content = GetTemplate("notes")

	content.AssignValue "maxlength", 5000

	dim oRs
	set oRs = oConn.Execute("SELECT notes FROM users WHERE id = " & UserId & " LIMIT 1" )

	content.AssignValue "notes", oRs(0)

	if notes_status <> "" then
		content.Parse "error." & notes_status
		content.Parse "error"
	end if

	content.Parse ""
	display(content)
end sub

dim notes

notes = Trim(Request.Form("notes"))

if Request.Form("submit") <> "" then

	if len(notes) <= 5100 then ' ok save info
		oConn.Execute "UPDATE users SET notes=" & dosql(notes) & " WHERE id = " & userid, , adExecuteNoRecords
		notes_status = "done"
	else
		notes_status = "toolong"
	end if
end if

display_notes

%>