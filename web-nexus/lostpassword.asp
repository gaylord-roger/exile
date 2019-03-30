<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/functions.asp"-->
<!--#include virtual="/lib/email.asp"-->
<%

var ipaddress = Request.ServerVariables("REMOTE_ADDR");
var forwardedfor = Request.ServerVariables("HTTP_X_FORWARDED_FOR");
var useragent = Request.ServerVariables("HTTP_USER_AGENT");

function newPasswordFrom(password) {
	var seekLetter = false;
	var s = '';
	for(var i = 1; s.length < 8; i++) {
		if((seekLetter && password.charAt(i).match(/[a-z]/gi)) || !seekLetter) {
			s += password.charAt(i);
			seekLetter = !seekLetter;
		}
		if(i >= password.length) {
			s += 'x';
			i = 0;
		}
	}
	return s;
}

function passwordKeyFrom(password) {
	var s = '';
	for(var i = 0; s.length < 8; i+=3) {
		s += password.charAt(i);
		if(i >= password.length) i = i % 4;
	}
	return s;
}

var content = loadTemplate('lostpassword');
var error = null;

if(Request.QueryString('id').item != null) {
	var userid = Number(Request.QueryString('id').item);
	var key = ToStr(Request.QueryString('key').item);

	var rs = SQLConn.execute('SELECT id, username, password, LCID FROM users WHERE id=' + dosql(userid));
	if(rs.EOF) {
		error = 'password_notchanged';
	}
	else {
		if(key == passwordKeyFrom(rs(2).value)) {
			var rs = SQLConn.execute('SELECT sp_account_password_set(' + [userid, newPasswordFrom(rs(2).value)].toSQL() + ')');
			if(!rs.EOF && rs(0).value) {
				Server.Transfer('/passwordreset.asp');
			}
			else
				error = 'password_notchanged';
		}
		else
			error = 'password_notchanged';
	}
}
else
if(Request.Form('resend').item != null) {
	// get parameters from form
	var email = ToStr(Request.Form("email").item).toLowerCase();

	content.AssignValue("email", email);

	if(error != null) {
	}
	else
	if(!validateEmail(email))
		error = 'email_invalid'; // invalid email
	else {
		var rs = SQLConn.execute('SELECT id, username, password, LCID FROM users WHERE lower(email)=' + dosql(email));
		if(rs.EOF) {
			error = 'email_notfound';
		}
		else {
			var mail = new Email();
			mail.from = senderMail;
			mail.to = rs(1).value + '<' + email + '>';
			mail.setMail(getFileContent(Server.MapPath('/localization/' + rs(3).value + '/email_newpassword.txt')));
			mail.setTag('%userid%', rs(0).value);
			mail.setTag('%username%', rs(1).value);
			mail.setTag('%password%', newPasswordFrom(rs(2).value));
			mail.setTag('%passwordkey%', passwordKeyFrom(rs(2).value));

			try {
				mail.send();
				Server.Transfer('/passwordsent.asp');
			} catch(e) {
				content.AssignValue('error', e.message);
				error = 'unknown';
			}
		}
	}
}

if(error != null) {
	content.Parse('error.' + error);
	content.Parse('error');
}

display(content);

%>