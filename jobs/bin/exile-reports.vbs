'
' exile-repors.vbs
' Launched once at system startup
' This script retrieves and send the reports to mail to users
'
Dim fso:set fso = CreateObject("Scripting.FileSystemObject")
ExecuteGlobal fso.OpenTextFile("funcs.vbs", 1).ReadAll()

dim universe: universe = WScript.Arguments(0)
setDSN "exile_" & universe

dim senderMail: senderMail = "Exile-" & universe & "<reports@exile.fr>"
dim reportsPath: reportsPath = "reports\"


function get_file_content(file)
	dim fs, thisfile

	Set fs = CreateObject("Scripting.FileSystemObject")
	Set thisfile = fs.OpenTextFile(file, 1, False)

	get_file_content = thisfile.ReadAll

	thisfile.Close
	set thisfile=nothing
	set fs=nothing
end function

function sendmail(mailfrom, mailto, subject, message)
	dim Osmtp
	sendmail = ""

	set oSmtp = WScript.CreateObject("CDO.Message")
	with oSmtp
		.From = mailfrom
		.To = mailto

		.Subject = subject
		.TextBody = message

		.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing")=2
		.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver")="127.0.0.1"
		.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport")=25 
		.Configuration.Fields.Update
		
		.Fields.Update()

		On Error Resume Next
		.Send
		if Err <> 0 then sendmail = "Error : "  & Err & ":" & Err.Description
		
		on error goto 0
	end with

	set oSmtp = nothing
end function

function Rep(s, substr, val)
	if isnull(val) then
		Rep = Replace(s, substr, "")
	else
		Rep = Replace(s, substr, val)
	end if
end function

sub process
	dim oConn, oRs, query
	oConn = null

	dim msg, subject, res, username, count

	' create a counter to reset the sql connection after a few calls
	dim loop_count
	loop_count = 0

	on error resume next

	while true
		Err.Clear

		'
		' Open DB connection if not connected
		'	
		if oConn is Nothing then
			log_debug true, "Creating connection"
			set oConn = Wscript.CreateObject("ADODB.Connection")
			oConn.CommandTimeout = 10
			oConn.Open dbconn
		end if

		log_debug false, "Check new reports to send"

		if Err.Number = 0 then
			beginWork "Sending reports"
			count = 0

			query = "SELECT v.id, u.login, u.lcid, email, type*100+subtype, battleid, fleetid, fleet_name," &_
				" planetid, planet_name, galaxy, sector, planet," &_
				" researchid, research_label, " &_
				" planet_relation, planet_ownername," &_
				" ore, hydrocarbon, v.credits, v.scientists, v.soldiers, v.workers," &_
				" alliance_tag, alliance_name," &_
				" invasionid, spyid, spy_key," &_
				" building_name, username, v.description" &_
				" FROM vw_reports_queue v" &_
				"	INNER JOIN users u ON v.ownerid=u.id"
			set oRs = oConn.Execute(query)

			do while not oRs.EOF
				msg = ""
				msg = get_file_content(reportsPath & oRs(2) & "\report_" & oRs(4) & ".txt") + get_file_content(reportsPath & oRs(2) & "\report_footer.txt")

				if Err.Number <> 0 then
					log_debug true, Err.Number & " : " & Err.Description
					exit do
				end if

				if msg <> "" then
					msg = Rep(msg, "%battleid%", oRs(5))
					msg = Rep(msg, "%fleetid%", oRs(6))
					msg = Rep(msg, "%fleetname%", oRs(7))
					msg = Rep(msg, "%planetid%", oRs(8))

					if oRs(15) < 0 then
						msg = Rep(msg, "%planetname%", oRs(16))
					else
						msg = Rep(msg, "%planetname%", oRs(9))
					end if

					' assign planet coordinates
					if not isNull(oRs(10)) then
						msg = Rep(msg, "%g%", oRs(10))
						msg = Rep(msg, "%s%", oRs(11))
						msg = Rep(msg, "%p%", oRs(12))
					end if

					msg = Rep(msg, "%researchid%", oRs(13))
					msg = Rep(msg, "%researchname%", oRs(14))

					msg = Rep(msg, "%ore%", oRs(17))
					msg = Rep(msg, "%hydrocarbon%", oRs(18))
					msg = Rep(msg, "%credits%", oRs(19))

					msg = Rep(msg, "%scientists%", oRs(20))
					msg = Rep(msg, "%soldiers%", oRs(21))
					msg = Rep(msg, "%workers%", oRs(22))

					msg = Rep(msg, "%alliancetag%", oRs(23))
					msg = Rep(msg, "%alliancename%", oRs(24))

					msg = Rep(msg, "%invasionid%", oRs(25))
					msg = Rep(msg, "%spyid%", oRs(26))
					msg = Rep(msg, "%spykey%", oRs(27))

					msg = Rep(msg, "%buildingname%", oRs(28))
					msg = Rep(msg, "%username%", oRs(29))

					msg = Rep(msg, "%description%", oRs(30))

					msg = Rep(msg, "%datetime%", now)
					msg = Rep(msg, "%year%", year(date))
					msg = Rep(msg, "%mm%", month(date))
					msg = Rep(msg, "%dd%", day(date))
					msg = Rep(msg, "%hh%", hour(date))
					msg = Rep(msg, "%nn%", minute(date))
					msg = Rep(msg, "%ss%", second(date))

					msg = Rep(msg, "%login%", oRs(1))
					msg = Rep(msg, "%email%", oRs(3))

					msg = Rep(msg, "%universe%", universe)

					subject = "[Exile-" & universe & "] " & Mid(msg, 1, InStr(msg, vbCRLF)-1)
					msg = Mid(msg, InStr(msg, vbCRLF)+2)

					res = sendmail(senderMail, oRs(1) & "<" & oRs(3) & ">", subject, msg)
					if res <> "" then log_debug true, res
				end if

				count = count + 1
				oConn.Execute "DELETE FROM reports_queue WHERE id=" & oRs(0)

				oRs.MoveNext
			loop

			endWork
			if count > 0 then log_debug true, count & " reports sent"
		end if


		'
		' check error and reset db connection every X times
		'
		if Err.Number <> 0 then 
			log_debug true, Err.Number & " : " & Err.Description

			oConn.Close
			set oConn = Nothing

			WScript.Sleep 10000
		else
			WScript.Sleep 5000

			if loop_count > 60 Then
				oConn.Close
				set oConn = Nothing
				loop_count = 0
			end if

			loop_count = loop_count + 1
		end if
	wend
end sub

process

Wscript.Quit(0)