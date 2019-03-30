Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

setDSN WScript.Arguments(0)

sub process
	dim oConn
	set oConn = Nothing

	dim loop_count
	loop_count = 0

	on error resume next 
	while true
		Err.Clear

		if oConn is nothing then
			log_debug true, "creating connection"

			set oConn = Wscript.CreateObject("ADODB.Connection")
			oConn.CommandTimeout = 10
			oConn.Open dbconn
		end if

		if Err.Number = 0 then
			beginWork "sp_execute_events()"
			oConn.Execute "SELECT sp_execute_events();", , 128
			checkError Err
			endWork
		end if

		if Err.Number <> 0 or RecreateConnection then
			WScript.Sleep 3000
			RecreateConnection = False
			oConn.Close
			set oConn = Nothing
		else
			WScript.Sleep 1000

			if loop_count > 20 then
				oConn.Close
				set oConn = Nothing
				loop_count = 0
			end if

			loop_count = loop_count + 1
		end if
	wend

	oConn.Close
	set oConn = Nothing
end sub

process

Wscript.Quit(0)