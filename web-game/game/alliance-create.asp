<%option explicit %>

<!--#include file="global.asp"-->

<%
selected_menu = "noalliance.create"

'
' return if the given name is valid for an alliance
'
function isValidAllianceName(myName)
	dim regEx

	if myName = "" or len(myName) < 4 or len(myName) > 32 then
		isValidAllianceName = false
	else
		set regEx = New RegExp 
		regEx.IgnoreCase = False 
		regEx.Pattern = "^[a-zA-Z0-9]+([ ]?[.]?[\-]?[ ]?[a-zA-Z0-9]+)*$"

		isValidAllianceName = regEx.Test(myName)
	end if
end function

'
' return if the given tag is valid
'
function isValidAllianceTag(tag)
	dim regEx

	if tag = "" or len(tag) < 2 or len(tag) > 4 then
		isValidAllianceTag = false
	else
		set regEx = New RegExp 
		regEx.IgnoreCase = False 
		regEx.Pattern = "^[a-zA-Z0-9]+$"

		isValidAllianceTag = regEx.Test(tag)
	end if
end function

function isValidDescription(description)
	isValidDescription = len(description) < 8192
end function


dim name, tag, description
name = ""
tag = ""
description = ""

dim valid_name, valid_tag, valid_description, create_result
valid_name = true
valid_tag = true
valid_description = true
create_result = 0

sub DisplayAllianceCreate()
	dim content
	set content = GetTemplate("alliance-create")

	if oPlayerInfo("can_join_alliance") then
		if create_result = -2 then content.Parse "create.name_already_used"
		if create_result = -3 then content.Parse "create.tag_already_used"

		if not valid_name then content.Parse "create.invalid_name"

		if not valid_tag then content.Parse "create.invalid_tag"

		content.AssignValue "name", name
		content.AssignValue "tag", tag
		content.AssignValue "description", description

		content.Parse "create"
	else
		content.Parse "cant_create"
	end if

	content.Parse ""

	Display(content)
end sub

if Request.QueryString("a") = "new" then
	name = Trim(Request.Form("alliancename"))
	tag = Trim(Request.Form("alliancetag"))
	description = Trim(Request.Form("description"))

	valid_name = isValidAllianceName(name)
	valid_tag = (Session(sprivilege) > 100) or isValidAllianceTag(tag)
	valid_description = isValidDescription(description)

	if valid_name and valid_tag then
		dim oRs
		set oRs = oConn.Execute("SELECT sp_create_alliance(" & UserId & "," & dosql(name) & "," & dosql(tag) & "," & dosql(description) & ")")

		create_result = oRs(0)
		if create_result >= -1 then
			Response.Redirect "alliance.asp"
			Response.End
		end if
	end if
end if

DisplayAllianceCreate()

%>