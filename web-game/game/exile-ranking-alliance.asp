<%option explicit %>

<!--#include virtual="/lib/constants.asp"-->
<!--#include virtual="/lib/sql.asp"-->
<!--#include virtual="/lib/template.asp"-->

<%

Response.ContentType="text/plain"

if Session(sUser) = "" then Session.Abandon

if maintenance then
	Response.Redirect "/"
	Response.End
end if

' connect to the database
connectDB()

sub DisplayRankingAllianceByTag(tag)
	dim content, oRs, oRs2, query
	Dim aScore, aMembers, aColonies
	set content = GetTemplate("exile-ranking-alliance")


	'get alliance info
	query = "SELECT id, name, logo_url, score," &_
			" (SELECT COUNT(*) FROM alliances AS u2 WHERE u2.score >= u1.score), created, now()" &_
			" FROM alliances AS u1" &_
			" WHERE upper(tag)=upper(" & dosql(tag) & ")" &_
			" LIMIT 1"

	set oRs = oConn.Execute(query)
	if oRs.EOF then exit sub

	'get player info
	query = "SELECT login, score, planets, " &_
			" (SELECT COUNT(*) FROM vw_players AS u2 WHERE u2.score >= u1.score_global)," &_
			" avatar_url" &_
			" FROM vw_players AS u1" &_
			" WHERE alliance_id=" & oRs(0) &_
			" ORDER BY upper(login)"

	Set oRs2 = oConn.Execute(query)
	if oRs2.EOF then exit sub
	
	while not oRs2.EOF
		content.AssignValue "name", oRs2(0)
		content.AssignValue "score", oRs2(1)
		content.AssignValue "colonies", oRs2(2)
		content.AssignValue "alliancetag", tag
		content.AssignValue "alliancename", oRs(1)
		content.AssignValue "rank", oRs2(3)
		content.AssignValue "avatarurl", Server.HTMLEncode(oRs2(4))
		content.Parse "player"

		'aScore = aScore + oRs2(1)
		aMembers = aMembers + 1
		aColonies = aColonies + oRs2(2)

		oRs2.Movenext
	wend

	'alliance content
	content.AssignValue "name", oRs(1)
	content.AssignValue "score", oRs(3)
	content.AssignValue "colonies", aColonies
	content.AssignValue "tag", tag
	content.AssignValue "rank", oRs(4)
	content.AssignValue "members", aMembers
	content.AssignValue "logourl", oRs(2)
	content.AssignValue "created", oRs(5).value
	content.AssignValue "generated", oRs(6).value

	content.Parse "alliance"
	content.Parse ""

	Response.Write content.Output
end sub

sub DisplayRankingAllianceByRank(rank)
	dim content, oRs, query

	query = "SELECT tag" &_
			" FROM alliances" &_
			" ORDER BY score DESC, upper(name) ASC" &_
			" OFFSET " & dosql(rank) & " LIMIT 1"
	set oRs = oConn.Execute(query)

	if oRs.EOF then exit sub

	DisplayRankingAllianceByTag(oRs(0))
end sub

Response.End

dim alliancetag, rank

alliancetag = ucase(Trim(Request.QueryString("tag")))
rank = Request.QueryString("rank")

if rank = "" or not isNumeric(rank) then
	DisplayRankingAllianceByTag(alliancetag)
else
'	DisplayRankingAllianceByRank(rank-1)
end if

'DisplayRankingAllianceByTag(alliancetag)

%>