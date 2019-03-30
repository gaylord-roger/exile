'
' exile-news.vbs
' Launched once at system startup
' This script retrieve the url contents that are specified in the table "news"
'
Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

setDSN "exile_nexus"


dim oConn, oRs, loops
set oConn = Nothing

on error resume next

set oConn = Wscript.CreateObject("ADODB.Connection")
oConn.CommandTimeout = 10
oConn.Open dbconn

loops = 0

if Err.Number = 0 then
	set oRs = oConn.Execute("SELECT id, url FROM news")

	if Err.Number <> 0 then log_debug true, Err.Number & " : " & Err.Description

	while not oRs.EOF And loops < 10
		Err.Clear

		loops = loops + 1

		beginWork "Retrieving " & oRs(1)

		'
		' retrieve url and update "news" table
		'
		dim WinHttpReq
		set WinHttpReq = CreateObject("WinHttp.WinHttpRequest.5.1")
		WinHttpReq.SetTimeouts 500, 1000, 1000, 1000 ' settimeout resolve, connect, send, read in milliseconds
		WinHttpReq.Open "GET", oRs(1), false
		WinHttpReq.Send()

		oConn.Execute "UPDATE news SET xml=" & dosql(WinHttpReq.responseText) & " WHERE id=" & oRs(0), , 128

		if Err.Number <> 0 then log_debug true, Err.Number & " : " & Err.Description

		endWork

		oRs.MoveNext
	wend
else
	log_debug true, Err.Number & " : " & Err.Description
end if

log_debug true, "Done"

oConn.Close
set oConn = Nothing

Wscript.Quit(0)
