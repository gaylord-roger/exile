PID = -1

sScriptFullName = wscript.scriptFullName
sScriptName = wscript.scriptName

for each oProc in getObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2").instancesOf("Win32_Process") 
	if lcase(oProc.name) = "wscript.exe" or lcase(oProc.name) = "cscript.exe" then 
		sCmdLine = oProc.commandLine 

		if instr(1, sCmdLine, sScriptFullName, vbTextCompare) > 0 then 
			PID = oProc.processId

			if WScript.Arguments.Count > 0 then
				if instr(1, sCmdLine, WScript.Arguments(0), vbTextCompare) > 0 then
					exit for
				end if
			end if
		end if
	end if
next

function dosql(ch)
	dosql = replace(ch, "\", "\\")
	dosql = replace(dosql, "'", "''")
	dosql = "'" & dosql & "'"
end function

function getDate()
	getDate = time'weekdayname(weekday(date)) & " " & day(date) & " " & monthname(month(date))  & " " & year(date) & " " & time
end function

dim dbconn
dim fso:set fso = CreateObject("Scripting.FileSystemObject")
dim log_file
dim log_file_err

function log_debug(writelog, info)
	dim f

	if writelog then
		set f = fso.OpenTextFile(log_file, 8, True)
		f.WriteLine(getDate() & " : " & info)
		f.Close
	end if

	on error resume next

	Err.clear

	set oConnDebug = Wscript.CreateObject("ADODB.Connection")
	oConnDebug.Open dbconn
	if Err.Number = 0 then
		oConnDebug.Execute "SELECT sp_job_update(" & dosql(sScriptName) & "," & PID & "," & dosql(Left(info,100)) & ")",, 128
		oConnDebug.Close
	end if
	set oConnDebug = Nothing

	if Err.Number <> 0 then
		set f = fso.OpenTextFile(log_file_err, 8, True)

		f.WriteLine(getDate() & " : " & Err.description)
		f.Close
	end if

	on error goto 0
end function

sub setDSN(dsn)
	dbconn = "DSN=" & dsn
	log_file = fso.GetParentFolderName(sScriptFullName) & "\log\" & dsn & "-" & sScriptName & ".log"
	log_file_err = fso.GetParentFolderName(sScriptFullName) & "\log\" & dsn & "-" & sScriptName & "-error.log"

	log_debug true, "Started (" & PID & ")"
end sub

'
' beginWork / endWork procedures logs update activity to the log file
'
dim StartTime, RecreateConnection, CurrentWork

sub beginWork(work)
	CurrentWork = work
	StartTime = timer()
	log_debug false, work
end sub

sub endWork()
	dim s: s=""
	if Timer()-StartTime > 1 then s=", more than 1 second"
	log_debug true, CurrentWork & ", took : " & Timer()-StartTime & "s"&s
end sub

sub checkError(e)
	if e.Number <> 0 then
		log_error e.Number & " : " & e.Description
		RecreateConnection = true
	end if
	e.Clear
end sub