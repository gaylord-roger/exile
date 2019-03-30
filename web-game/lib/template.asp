<%

dim template_addsessioninfo: template_addsessioninfo=true

' Return an initialized template
function GetTemplate(name)
	dim result
	set result = Server.CreateObject("G6WebLib.Template")
	result.TrimWhiteSpaces = true

	on error resume next
	err.clear
	result.Load Server.MapPath("templates\" & Session.LCID & "\" & name & ".html")
	if err.number <> 0 then result.Load Server.MapPath("templates\" & name & ".html")
	on error goto 0

	if template_addsessioninfo then
		' set LCID to the current session LCID
		result.SetLCID Session.LCID
		result.AssignValue "LCID", Session.LCID
		result.AssignValue "sessionid", Session.SessionID
	end if

	result.AssignValue "PATH_IMAGES", "/assets/"
	result.AssignValue "PATH_TEMPLATE", "/game/templates"

	set GetTemplate = result
end function

%>