<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/functions.asp"-->
<!--#include virtual="/lib/email.asp"-->
<%

// validate email change
if(Request.QueryString('email').item != null) {
	var userid = ToStr(Request.QueryString('id').item);
	var email = ToStr(Request.QueryString('email').item);
	var key = ToStr(Request.QueryString('key').item);

	var rs = SQLConn.execute('SELECT sp_account_email_validate(' + [userid, email, key].toSQL() + ')');
	if(rs(0).value)
		Server.Transfer('/account-options-email-validation-succeeded.asp');
	else
		Server.Transfer('/account-options-email-validation-failed.asp');
}


if(!User.isLogged) {
	Response.redirect('/');
	Response.end();
}


// check if the email domain is banned
function isEmailBanned(email) {
	var rs = SQLConn.execute('SELECT 1 FROM banned_domains WHERE ' + dosql(email) + ' ~* domain LIMIT 1');
	return !rs.EOF;
}

// check if the email address is already used by someone
function isEmailUsed(email) {
	var rs = SQLConn.execute('SELECT 1 FROM users WHERE lower(email)=lower(' + dosql(email) + ') LIMIT 1');
	return !rs.EOF;
}

var content = loadTemplate('account-options');
var error = null;

if(Request.Form('changeemail').item != null) {
	// get parameters from form
	var password = ToStr(Request.Form("old_password").item);
	var email = ToStr(Request.Form("email").item);

	content.AssignValue('email', email);

	if(!validateEmail(email))
		error = 'email_invalid'; // invalid email
	else
	if(isEmailBanned(email))
		error = 'email_banned'; // email domain is banned
	else
	if(isEmailUsed(email))
		error = 'email_exists'; // email domain is banned
	else {
		// retrieve the key to be able to assign the new email to this account
		var rs = SQLConn.execute('SELECT * FROM sp_account_email_change(' + [User.id, password, email].toSQL() + ')');
		if(!rs.EOF) {
			var mail = new Email();
			mail.from = senderMail;
			mail.to = User.name + '<' + email + '>';
			mail.setMail(getFileContent(Server.MapPath('/localization/' + Session.LCID + '/email_setemail.txt')));
			mail.setTag('%userid%', User.id);
			mail.setTag('%username%', User.name);
			mail.setTag('%email%', email);
			mail.setTag('%password%', password);
			mail.setTag('%key%', rs(0).value);

			try {
				mail.send();
				Server.Transfer('/account-options-email-changed.asp');
			} catch(e) {
				content.AssignValue('error', e.message);
				error = 'unknown';
			}
		}
		else
			error = 'password_invalid';
	}
}
else
if(Request.Form('changepassword').item != null) {
	// get parameters from form
	var oldPassword = ToStr(Request.Form("old_password").item);
	var newPassword = ToStr(Request.Form("new_password").item);
	var newPassword2 = ToStr(Request.Form("new_password2").item);

	content.AssignValue('validatePassword', validatePassword);

	if(newPassword != newPassword2)
		error = 'password_dont_match'; // invalid password
	else
	if(!validatePassword(newPassword))
		error = 'newpassword_invalid'; // invalid password
	else {
		// retrieve the key to be able to assign the new password to this account
		var rs = SQLConn.execute('SELECT sp_account_password_change(' + [User.id, oldPassword, newPassword].toSQL() + ')');
		if(!rs.EOF && rs(0).value) {
			Server.Transfer('/account-options-password-changed.asp');
		}
		else
			error = 'password_invalid';
	}
}

if(error != null) {
	content.Parse('error.' + error);
	content.Parse('error');
}

display(content);

%>