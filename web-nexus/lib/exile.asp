<%	
var startTime = new Date();
var scripturl = Request.ServerVariables("SCRIPT_NAME") + "?" + Request.ServerVariables("QUERY_STRING");
%>

<!--#include virtual="/lib/constants.asp"-->
<!--#include virtual="/lib/sql.asp"-->

<%

function ToStr(s) {
	return (typeof s != 'undefined')?String(s):'';
}

function setExpiration(minutes) {
	if(minutes == 0) {
		Response.Expires = -60;
		Response.AddHeader("pragma","no-cache");
		Response.AddHeader("cache-control","private");
		Response.CacheControl = "no-cache";
	}
	else
		Response.Expires = minutes;
}

// check if session is enabled on this page
var SessionEnabled = false;
try {
	Session("test") = "test";
	SessionEnabled = true;
} catch(e) {
}

// retrieve some server variables
var lang = Request.QueryString("lang");
var ipaddress = Request.ServerVariables("REMOTE_ADDR");
var forwardedfor = Request.ServerVariables("HTTP_X_FORWARDED_FOR");
var useragent = Request.ServerVariables("HTTP_USER_AGENT");

var browserid = "";
var expireDate = new Date();
expireDate.setYear(expireDate.getYear() + 1);
expireDate = (expireDate.getMonth() + 1) + "/" + expireDate.getDate() + "/" + expireDate.getFullYear();

if(SessionEnabled) {
	// retrieve/assign lcid
	if(lang = "") lang = Request.Cookies("lcid");

	switch(lang) {
		case "1036":
			Session.LCID = 1036;
			break;
		case "1033":
			Session.LCID = 1033;
			break;
	}

	Response.Cookies("lcid") = Session.LCID;
	Response.Cookies("lcid").expires = expireDate;

	// retrieve browser id from cookie
	browserid = Number(Request.Cookies("id"));

	if(isNaN(browserid) && !maintenance) {
		var oRs = oConn.Execute("SELECT nextval('stats_requests')");

		browserid = oRs(0).value;
		Response.Cookies("id") = browserid;
		Response.Cookies("id").Expires = expireDate;
	}
}

%>