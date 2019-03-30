<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/functions.asp"-->
<!--#include virtual="/lib/user.asp"-->
<!--#include virtual="/lib/constants.asp"-->
<%

var username = ToStr(Request.Form("username").item);
var password = ToStr(Request.Form("password").item);

if(username == '' || password == '') {
	Session('lastloginerror') = 'credentials_invalid';
}
else {
	var address = Request.ServerVariables("REMOTE_ADDR");
	var addressForwarded = Request.ServerVariables("HTTP_X_FORWARDED_FOR");
	var userAgent = Request.ServerVariables("HTTP_USER_AGENT");

	// try to log on
	var rs = SQLConn.execute('SELECT id, username, last_visit, last_universeid, privilege_see_hidden_universes FROM sp_account_login(' + [username, password, address, addressForwarded, userAgent].toSQL() + ')');
	if(!rs.EOF) {
		User.setID(rs(0).value);
		User.setName(rs(1).value);
		User.setLastVisit(rs(2).value);
		User.setLastUniverseID(rs(3).value);
		User.setAddress(address);
		try {
			User.setPrivilege('see_hidden_universes', rs(4).value);
		} catch(e) {
			if(User.address == '82.246.213.111') Response.write(e.message);
		}

		User.setAuthID(makePassword(4) + Session.SessionID + makePassword(4));

		Response.Cookies('authID') = User.authID;
		Response.Cookies('authID').domain = cookieDomain;
		Response.Cookies('authID').expires = expireDate;

		Application('connect-' + User.authID) = rs(0).value;
	}
	else {
		Session('lastloginerror') = 'credentials_invalid';
	}
}

Server.Transfer('servers.asp');

%>