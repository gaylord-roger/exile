<%
dim oConn, oNexusConn

' retrieve universe
dim universe
universe = LCase(Mid(Request.ServerVariables("SERVER_NAME"), 1, instr(1, Request.ServerVariables("SERVER_NAME"), ".")-1))

function openDB(connStr)
	set openDB = Server.CreateObject("ADODB.Connection")
	openDB.Open connStr
end function

sub connectDB()
	set oConn = openDB(connectionStrings.game)
end sub

sub connectNexusDB()
	set oNexusConn = openDB(connectionStrings.nexus)
end sub

' return a quoted string for sql queries
function dosql(ch)
	dosql = replace(ch, "\", "\\") 
	dosql = replace(dosql, "'", "''")
	dosql = "'" & dosql & "'"
end function

' return "null" if val is null or equals ''
function sqlValue(val)
	if IsNull(val) or val = "" then
		sqlValue = "Null"
	else
		sqlValue = val
	end if
end function

' tries to execute a query up to 3 times if it fails the first times
function connExecuteRetry(query)
	on error resume next

	dim i
	i = 0
	while i < 5
		set connExecuteRetry = oConn.Execute(query)
		i = i + 1

		if err.Number = 0 then
			i = 10	' leave loop
		elseif i > 2 then
			on error goto 0	' next time, let's raise the error
		end if
	wend

	if i <= 2 then on error goto 0
end function

sub connExecuteRetryNoRecords(query)
	on error resume next

	dim i
	i = 0
	while i < 5
		oConn.Execute query, , 128
		i = i + 1

		if err.Number = 0 then
			i = 10	' leave loop
		elseif i > 2 then
			on error goto 0	' next time, let's raise the error
		end if
	wend

	if i <= 2 then on error goto 0
end sub

%>