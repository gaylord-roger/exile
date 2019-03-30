<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/functions.asp"-->
<!--#include virtual="/lib/email.asp"-->
<%

// check if the login is banned
function isUsernameBanned(username) {
	var rs = SQLConn.execute("SELECT 1 FROM banned_logins WHERE " + dosql(username) + " ~* login LIMIT 1;");
	return !rs.EOF;
}

// check if the email domain is banned
function isEmailBanned(email) {
	var rs = SQLConn.execute("SELECT 1 FROM banned_domains WHERE " + dosql(email) + " ~* domain LIMIT 1;");
	return !rs.EOF;
}

var content = loadTemplate('register');
var error = null;

if(Request.Form('create').item != null) {
	// registration is disabled in constants.asp
	if(maintenance || register_disabled) {
		if(maintenance)
			error = 'register_disabled_maintenance';
		else {
			error = 'register_disabled';
			content.AssignValue("register_msg", register_msg);
		}
	}

	// get parameters from form
	var username = ToStr(Request.Form("username").item);
	var email = ToStr(Request.Form("email").item);
	var conditions = Request.Form("conditions").item;

	content.AssignValue("username", username);
	content.AssignValue("email", email);

	if(error != null) {
	}
	else
	if(!validateUserName(username))
		error = 'username_invalid'; // invalid username
	else
	if(!validateEmail(email))
		error = 'email_invalid'; // invalid email
	else
	if(!conditions)
		error = 'accept_conditions'; // conditions not accepted
	else 
	if(isEmailBanned(email))
		error = 'email_banned'; // email domain is banned
	else
	if(isUsernameBanned(username))
		error = 'username_banned'; // login is banned
	else {
		// create password
		var password = makePassword(8);
		
		// create the new account
		SQLConn.beginTrans();

		var userid = -4;

		var rs = SQLConn.execute("SELECT sp_account_create(" + dosql(username) + "," + dosql(password) + "," + dosql(email) + "," + Session.LCID + "," + dosql(Request.ServerVariables("REMOTE_ADDR")) + ")");
		if(!rs.EOF) userid = rs(0).value;

		if(userid > 0) {
			var mail = new Email();
			mail.from = senderMail;
			mail.to = username + '<' + email + '>';
			mail.setMail(getFileContent(Server.MapPath('/localization/' + Session.LCID + '/email_register.txt')));
			mail.setTag('%username%', username);
			mail.setTag('%password%', password);

			try {
				mail.send();
				SQLConn.commitTrans();
				Server.Transfer('/registered.asp');
			} catch(e) {
				content.AssignValue('error', e.message);
				error = 'unknown';
			}
		}
		else {
			switch(userid) {
				case -1: // duplicated login
					error = 'username_exists';
					break;
				case -2: // duplicated email
					error = 'email_exists';
					break;
				case -3: // duplicated registration address
					error = 'regaddress_exists';
					break;
				case -4: // unknown error
					error = 'unknown';
					break;
			}

			SQLConn.rollbackTrans();
		}
	}
}

if(error != null) {
	content.Parse('error.' + error);
	content.Parse('error');
}

display(content);

%>