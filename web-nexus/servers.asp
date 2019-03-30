<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/json.asp"-->
<!--#include virtual="/lib/user.asp"-->
<%

var getstats = Number(Request.QueryString('getstats').item);
if(!isNaN(getstats)) {
	var rs = SQLConn.execute('SELECT url FROM universes WHERE id=' + getstats);
	
	var url = rs(0).value + '/statistics.asp';

	var xml = Server.CreateObject("MSXML2.ServerXMLHTTP");

	var resultData = '';

	try {
		xml.open("GET", url, true); // True specifies an asynchronous request
		xml.send();

		// Wait for up to 3 seconds if we've not gotten the data yet
		if(xml.readyState != 4)
			xml.waitForResponse(3);

		if(xml.readyState == 4 && xml.status == 200) {
			setExpiration(2);
			resultData = xml.responseText;
		}
		else {
			// Abort the XMLHttp request
			xml.abort();

			throw 0;
		}
	} catch(e) {
		resultData = '{error:"Problem communicating with remote server..."}';
	}

	Response.write(resultData);
	Response.end();
}


if(!User.isLogged) {
	Response.redirect('/');
	Response.end();
}

var setsrv = Number(Request.QueryString('setsrv').item);
if(!isNaN(setsrv)) {
	SQLConn.execute('SELECT sp_account_universes_set(' + [User.id, setsrv].toSQL() + ')');
	User.setLastUniverseID(setsrv);
	Response.end();
}

var content = loadTemplate('servers');

var query = 'SELECT id, name, description, created, url, login_enabled, players_limit, start_time, stop_time,'+
			' CASE WHEN start_time IS NOT NULL AND stop_time IS NOT NULL THEN 2 WHEN stop_time IS NOT NULL THEN 1 ELSE 0 END,'+
			' NOT has_fastconnect' +
			' FROM universes' +
			(User.privileges.see_hidden_universes?'':' WHERE visible') +
			' ORDER BY name';//created is not null, created';
var rs = SQLConn.execute(query);
while(!rs.EOF) {
	var server = {
					id:rs(0).value,
					name:rs(1).value,
					description:rs(2).value,
					created:rs(3).value,
					start:rs(7).value,
					stop:rs(8).value,
					url:rs(4).value,
					redirect:rs(10).value
				};
	content.AssignValue('id', rs(0).value);
	content.AssignValue('name', rs(1).value);
	content.AssignValue('description', rs(2).value);
	content.AssignValue('server', server.toJSON());

	content.Parse('item.type'+rs(9).value);

	content.Parse('item');
	rs.MoveNext();
}

content.AssignValue('sessionid', User.authID);
content.AssignValue('lastserverid', User.lastUniverseID);

display(content);

%>