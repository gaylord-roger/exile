'
' Do the cleaning and vacuuming of Exile databases
'
Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

setDSN "exile_nexus"

function processDB(dsn, computeScore)
	processDB = false

	dim oConn, oRs, i, StartTime

	i = 0

	StartTime = Timer()

	on error resume next
	Err.Clear

	set oConn = Wscript.CreateObject("ADODB.Connection")
	oConn.Open "DSN=" & dsn

	beginWork "sp_execute_daily_updates"
	oConn.Execute "SELECT sp_execute_daily_updates();", , 128
	checkError Err
	endWork

	beginWork "VACUUM"
	oConn.Execute "VACUUM ANALYZE", , 128
	checkError Err
	endWork

	oConn.Close
	set oConn = nothing

	log_debug true, "Process(" & dsn & ") end took: " & Timer()-StartTime & "s"

	processDB = true
end function


sub process()
	dim i

	set oNexusConn = Wscript.CreateObject("ADODB.Connection")
	oNexusConn.Open dbconn

	set oRs = oNexusConn.Execute("SELECT name, ranking_enabled FROM universes WHERE enabled")

	' process each server
	while not oRs.EOF
		i = 0
		while i < 5
			if processDB("exile_" & oRs(0), oRs(1)) then
				i = 10
			else
				WScript.Sleep 5000
			end if

			i = i + 1
		wend

		oRs.MoveNext
	wend
end sub

process

Wscript.Quit(0)