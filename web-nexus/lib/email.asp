<%
function Email() {
	this.from = '';
	this.to = '';
	this.subject = '';
	this.body = '';
	this.tags = [];

	this.setMail = function(text) {
		this.subject = text.substring(0, text.indexOf('\r\n'));
		this.body = text.substring(text.indexOf('\r\n') + 2);
	};

	this.setTag = function(name, value) {
		if(value == null)
			delete this.tags[name];
		else
			this.tags[name] = {rx:new RegExp(name, 'gi'), value:value};
	};

	this.replaceTags = function(s) {
		for(var x in this.tags) {
			var tag = this.tags[x];
			s = s.replace(tag.rx, tag.value);
		}

		return s;
	};

	// send an email
	this.send = function() {
		var oSmtp = Server.CreateObject('CDO.Message');
		oSmtp.From = this.from;
		oSmtp.To = this.to;

		oSmtp.Subject = this.replaceTags(this.subject);
		oSmtp.TextBody = this.replaceTags(this.body);

		oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2;
		oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = '127.0.0.1';
		oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25;
		//oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1;
		//oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") = 'userName';
		//oSmtp.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") = 'password';
		oSmtp.Configuration.Fields.Update();
			
		oSmtp.Fields.Update();

		oSmtp.Send();
	};
}
%>