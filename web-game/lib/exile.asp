<%
dim StartTime: StartTime = Timer()
dim scripturl: scripturl = Request.ServerVariables("SCRIPT_NAME") & "?" & Request.ServerVariables("QUERY_STRING")
%>

<!--#include virtual="/lib/config.asp"-->
<!--#include virtual="/lib/sql.asp"-->
<!--#include virtual="/lib/functions.asp"-->

<script language="JScript" runat="server">
</script>

<%

if not maintenance then
	connectDB()
else
	Response.Redirect "/game/maintenance.asp"
	Response.End
end if

dim browserid: browserid = ""

if SessionEnabled then
	' retrieve/assign lcid
	if lang = "" then lang = Request.Cookies("lcid")

	select case lang
		case "1036"
			Session.LCID = 1036
		case "1033"
			Session.LCID = 1033
	end select

	Response.Cookies("lcid") = Session.LCID
	Response.Cookies("lcid").Expires = Date+365


	' retrieve browser id from cookie
	browserid = ToInt(Request.Cookies("id"), "")

	if browserid = "" then
		dim reqRs
		set reqRs = oConn.Execute("SELECT nextval('stats_requests')")

		browserid = reqRs(0)
		Response.Cookies("id") = browserid
		Response.Cookies("id").Expires=now()+45
	end if
end if

Response.Expires = -60
Response.Expiresabsolute = Now() - 2
Response.AddHeader "pragma","no-cache"
Response.AddHeader "cache-control","private"
Response.CacheControl = "no-cache"

%>