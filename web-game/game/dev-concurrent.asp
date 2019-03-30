<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "dev_error"

sub DisplayForm()
	dim content
	set content = GetTemplate("dev-concurrent")

	dim oRs, query

	query = "select userid1, sp_get_user(userid1), userid2, sp_get_user(userid2), count(*), min(datetime), max(datetime)" &_
			"from admin_view_multi_simultaneous" &_
			"group by userid1, sp_get_user(userid1), userid2, sp_get_user(userid2)" &_
			"order by lower(sp_get_user(userid1)), lower(sp_get_user(userid2))"

	set oRs = oConn.Execute(query)

	while not oRs.EOF
		
		content.AssignValue "timestamp", oRs(0)
		content.AssignValue "userid", oRs(1)
		content.AssignValue "login", oRs(2)
		

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