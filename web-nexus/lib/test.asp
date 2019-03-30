function loadTemplate(name) {
	var LCID = 1036;

	var i = name.lastIndexOf('/');
	if(i == -1)
		name = "templates/" + name;
	else
		name = name.substring(0, i+1) + "templates/" + name.substr(i+1, 128);

	var result = Server.CreateObject("G6WebLib2.TemplateManager");
	var result = result.Load(Server.MapPath(name + ".html"), LCID, 60, true);

	if(SessionEnabled) {
		result.AssignValue("LCID", Session.LCID);
		result.AssignValue("sessionid", Session.SessionID);
	}

	result.AssignValue("PATH_IMAGES", "https://img.exil.pw");
//	result.AssignValue("PATH_TEMPLATE", "/game/templates");

	return result;
}
loadTemplate('map')