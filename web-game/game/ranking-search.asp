<%option explicit %>

<!--#include file="global.asp"-->

<%

if Session(sPrivilege) < 100 then
	RedirectTo "/game/overview.asp"
	Response.end
end if

selected_menu = "ranking.search"

sub DisplayRankingSearch()
	dim content, oRs, i
	set content = GetTemplate("ranking-search")
	
	
	content.Parse ""

	Display(content)
end sub

dim searchfor, Nword, Aword
searchfor = Request.Form("type")
Nword = Trim(Request.Form("nationword"))
Aword = Trim(Request.Form("allianceword"))

if searchfor = "nation" then
	Response.Redirect "ranking-players.asp?n="&Nword&"&a="&Aword
	Response.End
elseif searchfor = "alliance" then
	Response.Redirect "ranking-alliances.asp?a="&Aword
	Response.End
end if

DisplayRankingSearch()

%>