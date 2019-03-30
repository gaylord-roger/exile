<% Option explicit %>

<!--#include file="lib\exile.asp"-->

<script language="JScript" runat="server">
function connect()
{
	var url = urlNexus + 'authenticate.asp?id=' + Request.Cookies('authID') + '&address=' + Request.ServerVariables("REMOTE_ADDR");

	var xml = Server.CreateObject("MSXML2.ServerXMLHTTP");

	var resultData = {};

	try {
		xml.open("GET", url, true); // True specifies an asynchronous request
		xml.send();

		// Wait for up to 3 seconds if we've not gotten the data yet
		if(xml.readyState != 4)
			xml.waitForResponse(3);

		if(xml.readyState == 4 && xml.status == 200) {
			resultData = eval('(' + xml.responseText + ')');
		}
		else {
			// Abort the XMLHttp request
			xml.abort();

			resultData = {userid:null, error:'Problem communicating with remote server...' }
		}
	} catch(e) {
		resultData = {userid:null, error:e.message }
	}

	if(resultData.userid != null) {
		Session.LCID = resultData.lcid;

		var rs = connExecuteRetry('SELECT id, lastplanetid, privilege, resets FROM sp_account_connect(' + resultData.userid + ',' + Session.LCID + ',' + dosql(ipaddress) + ',' + dosql(forwardedfor) + ',' + dosql(useragent) + ',' + dosql(browserid) + ')');

		Session(sUser) = rs(0).value;
		Session(sPlanet) = rs(1).value;
		Session(sPrivilege) = rs(2).value;
		Session(sLogonUserID) = rs(0).value;

		if(!Session("isplaying")) {
			Session("isplaying") = true;
			Application.lock();
			Application("players") = Application("players") + 1;
			Application.unlock();
		}

		Application("usersession" + rs(0).Value) = Session.SessionID;

		if(rs(2).value == -3)
			response.Redirect("/game/wait.asp");
		else
		if(rs(2).value == -2)
			Response.Redirect("/game/holidays.asp");
		else
		if(rs(2).value < 100 && rs(3).value == 0)
			Response.Redirect("/game/start.asp");
		else
			Response.Redirect("/game/overview.asp");
	}

	Response.Redirect(urlNexus);
}
</script>

<%
connect()
%>