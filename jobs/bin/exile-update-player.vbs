Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

setDSN WScript.Arguments(0)

sub process
	dim oConn, oConn2, oRs, i
	set oConn = Nothing
	set oConn2 = Nothing
	i = 0

	dim StartTime, h

	h = hour(now())

	StartTime = Timer()

	on error resume next
	while true
		Err.Clear

		if oConn is nothing then
			set oConn = Wscript.CreateObject("ADODB.Connection")
			oConn.Open dbconn
		end if

		if oConn2 is nothing then
			set oConn2 = Wscript.CreateObject("ADODB.Connection")
			oConn2.Open dbconn
		end if

		if Err.Number = 0 then
			set oRs = oConn.Execute("SELECT id FROM users WHERE privilege = 0 AND planets > 0 AND credits_bankruptcy > 0 AND lastlogin IS NOT NULL ORDER BY id")

			while not oRs.EOF
				dim x
				x = 0

				while x < 2
					Err.Clear
					oConn2.Execute "SELECT sp_update_player(" & oRs(0) & "," & h & ");", , 128
					if Err.Number = 0 then x = 10
					x = x + 1
				wend

				if Err.Number <> 0 then log_debug true, Err.Number & " : update_player(" & oRs(0) & ") : " & Err.Description

				WScript.Sleep 20

				oRs.MoveNext
			wend
		end if


		log_debug true, "Took: " & Timer()-StartTime & "s"

		if Err.Number <> 0 then
			log_debug true, Err.Number & " : " & Err.Description

			oConn.Close
			set oConn = nothing
			oConn2.Close
			set oConn2 = nothing

			WScript.Sleep 5000
			i = i + 1
			if i > 10 then Wscript.Quit(0)
		else
			oConn.Close
			set oConn = nothing
			oConn2.Close
			set oConn2 = nothing

			Wscript.Quit(0)
		end if
	wend
end sub

process

Wscript.Quit(0)
