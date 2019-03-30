<%option explicit %>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->

<!--#include virtual="/game/cache.asp"-->
<!--#include file="lib_battle.asp"-->

<%


dim id, creator, fromview, battlekey

battlekey = Request.QueryString("key")
if battlekey = "" then
	Response.Redirect "reports.asp"
	Response.End
end if

creator = ToInt(Request.QueryString("by"), "")
if creator = "" then
	Response.Redirect "reports.asp"
	Response.End
end if

fromview = ToInt(Request.QueryString("v"), "")
if fromview = "" then
	Response.Redirect "reports.asp"
	Response.End
end if

id = ToInt(Request.QueryString("id"), "")
if id = "" then
	Response.Redirect "reports.asp"
	Response.End
end if

' check if associated key is correct, and redirect if not
dim oKeyRs
set oKeyRs = oConn.Execute(" SELECT 1 FROM battles WHERE id="&id&" AND "&dosql(battlekey)&"=MD5(key||"&dosql(creator)&") ")
if oKeyRs.EOF then
	Response.Redirect "reports.asp"
	Response.End
end if

dim tpl_layout, tpl_battle
set tpl_layout = GetTemplate("layout")
tpl_layout.AssignValue "skin", "s_transparent"
tpl_layout.AssignValue "timers_enabled", "0"
set tpl_battle = FormatBattle(id, creator, fromview, true)

tpl_layout.AssignValue "content", tpl_battle.output
tpl_layout.Parse ""

Response.Write tpl_layout.output

%>