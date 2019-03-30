<%
fname=Request.Cookies("display_fleets")
response.write("Test=" & fname)
if fname <> "" then
	response.write("ok")
end if
%>