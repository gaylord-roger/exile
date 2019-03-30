<!--#include file="lib\exile.asp"-->
<!--#include file="lib\template.asp"-->
<!--#include file="lib\formatxml.asp"-->
<!--#include file="lib\user.asp"-->

<%

setExpiration(0);

var master = loadTemplate("master");

master.AssignValue("visitors", Application("guests"));
master.Parse("advertisement1");


var footerButton = 'intro';

function display(content) {
	content.Parse('');
	master.AssignValue('content', content.Output());

	if(User.isLogged) {
		master.AssignValue('username', User.name);
		master.AssignValue('lastvisit', User.lastVisit);
		master.Parse('form-logged');
	}
	else {
		if(Session('lastloginerror') != null) {
			master.Parse('form-login.error_' + Session('lastloginerror'));
			Session('lastloginerror') = null;
		}
		master.Parse('form-login');
	}

	master.Parse('footer-' + footerButton);
	master.Parse('');
	Response.Write(master.Output());
}

%>