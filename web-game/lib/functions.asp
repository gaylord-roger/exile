<script language="JScript" runat="server">
var SessionEnabled = false;

try {
	Session("test") = "test";
	SessionEnabled = true;
} catch(e) {
}


function toStr(s) {
	return (!!s)?String(s):'';
}

function toInt(s, defaultValue) {
	if(s == "") return defaultValue;
	var i = Number(s);
	if(isNaN(i))
		return defaultValue;
	return i;
}

var lang = Request.QueryString("lang");
var ipaddress = Request.ServerVariables("REMOTE_ADDR");
var forwardedfor = Request.ServerVariables("HTTP_X_FORWARDED_FOR");
var useragent = Request.ServerVariables("HTTP_USER_AGENT");

</script>
