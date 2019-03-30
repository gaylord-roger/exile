<%@ EnableSessionState=False %>
<%option explicit %>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->

<%
template_addsessioninfo = false

Response.ContentType="text/plain"

if maintenance then
	Response.Redirect "/"
	Response.End
end if

sub DisplayRankingByLogin(login)
	dim content, oRs, query
	set content = GetTemplate("exile-ranking-user")

	query = "SELECT 0, login, u1.score, planets, alliances.tag, alliances.name," &_
			" (SELECT count(1) FROM vw_players AS u2 WHERE u2.score >= u1.score)," &_
			" avatar_url, now(), score_visibility, alliances_ranks.label," &_
			" u1.score_prestige, (SELECT count(1) FROM vw_players AS u2 WHERE u2.score_prestige >= u1.score_prestige)" &_
			" FROM vw_players AS u1" &_
			"	LEFT JOIN alliances ON alliances.id=u1.alliance_id" &_
			"	LEFT JOIN alliances_ranks ON (alliances_ranks.allianceid=u1.alliance_id AND alliances_ranks.rankid=u1.alliance_rank)" &_
			" WHERE upper(login)=upper(" & dosql(login) & ")" &_
			" LIMIT 1"
	set oRs = oConn.Execute(query)

	if oRs.EOF then exit sub

	content.AssignValue "generated", oRs(8).value

	content.AssignValue "place", oRs(0)
	content.AssignValue "name", oRs(1)
	content.AssignValue "score", oRs(2)
	content.AssignValue "colonies", oRs(3)

	content.AssignValue "alliancetag", oRs(4)
	content.AssignValue "alliancename", oRs(5)
	content.AssignValue "alliancerank", oRs(10)
	content.AssignValue "rank", oRs(6)

	content.AssignValue "avatarurl", oRs(7)

	content.AssignValue "battlescore", oRs(11)
	content.AssignValue "battlerank", oRs(12)

	if oRs("score_visibility") = 2 then content.Parse "score"

	content.Parse ""

	Response.Write content.Output
end sub

sub DisplayRankingByRank(rank)
	dim content, oRs, query

	query = "SELECT login" &_
			" FROM vw_players" &_
			" ORDER BY score DESC, upper(login) ASC" &_
			" OFFSET " & dosql(rank) & " LIMIT 1"
	set oRs = oConn.Execute(query)

	if oRs.EOF then exit sub

	DisplayRankingByLogin(oRs(0))
end sub

dim player, rank

player = Request.QueryString("player")
rank = Request.QueryString("rank")

if rank = "" or not isNumeric(rank) then
	DisplayRankingByLogin player
else
	'DisplayRankingByRank rank-1
end if

%>