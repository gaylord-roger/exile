<% option explicit %>

<!--#include virtual="/lib/exile.asp"-->
<!--#include virtual="/lib/template.asp"-->
<!--#include virtual="/lib/accounts.asp"-->

<script language="JScript" runat="server">
function process() {
	if(!registration.enabled || (registration.until != null && new Date().getTime() > registration.until.getTime())) {
		var content = GetTemplate("start-closed");
		content.Parse("");
		Response.write(content.Output());
		Response.end();
	}

	var result = 0;

	var userId = Number(Session("user"));
	var galaxy = Number(Request.Form('galaxy').item);
	if(isNaN(galaxy)) galaxy = 0;

	if(isNaN(userId)) {
		Response.redirect("/");
		Response.end();
	}

	// check if it is the first login of the player
	var rs = oConn.Execute("SELECT login FROM users WHERE resets=0 AND id=" + userId);
	if(rs.EOF) {
		Response.redirect("/");
		Response.end();
	}

	var userName = rs(0).value;

	if(userName == null) {
		var newName = toStr(Request.Form('name').item);
		if(newName != "") {
			// try to rename user and catch any error
			try {
				if(isValidName(newName)) {
					oConn.Execute("UPDATE users SET login=" + dosql(newName) + " WHERE id=" + userId, null, adExecuteNoRecords);
					userName = newName;
				}
				else
					result = 11;
			} catch(e) {
				result = 10;
			}
		}
	}

	if(result == 0) {
		var orientation = Number(Request.Form("orientation").item);
		var allowed = false;

		for(var i = 0; i < allowedOrientations.length; i++)
			if(allowedOrientations[i] == orientation) {
				allowed = true;
				break;
			}

		if(allowed) {
			oConn.BeginTrans();

			oConn.Execute("UPDATE users SET orientation=" + orientation + " WHERE id=" + userId, null, adExecuteNoRecords);

			var rs = oConn.Execute("SELECT sp_reset_account(" + userId + "," + galaxy + ")");
			result = rs(0).value;

			try {
				if(result != 0)
					throw 0;

				switch(orientation) {
					case 1:	// merchant
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",10,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",11,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",12,1)", null, adExecuteNoRecords);
					break;

					case 2:	// military
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",20,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",21,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",22,1)", null, adExecuteNoRecords);
					break;

					case 3:	// scientist
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",30,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",31,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",32,1)", null, adExecuteNoRecords);
					break;

					case 4:	// war lord
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",40,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",12,1)", null, adExecuteNoRecords);
						oConn.Execute("INSERT INTO researches(userid, researchid, level) VALUES(" + userId + ",32,1)", null, adExecuteNoRecords);
					break;
				}

				oConn.Execute("SELECT sp_update_researches(" + userId + ")", null, adExecuteNoRecords);

				oConn.CommitTrans();

				Response.redirect("/game/overview.asp");
				Response.end();
			} catch(e) {
				oConn.RollbackTrans();
			}
		}
	}

	// display start page
	var content = GetTemplate("start");
	content.AssignValue("login", userName);

	for(var i = 0; i < allowedOrientations.length; i++)
		content.Parse("orientation_" + allowedOrientations[i]);

	var rs = oConn.Execute("SELECT id, recommended FROM sp_get_galaxy_info(" + userId + ")");

	while(!rs.EOF) {
		content.AssignValue("id", rs(0).value);
		content.AssignValue("recommendation", rs(1).value);
		content.Parse("galaxies.galaxy");
		rs.MoveNext();
	}

	content.Parse("galaxies");

	if(result != 0)
		content.Parse("error_" + result);

	content.Parse("");

	Response.write(content.Output());
}
</script>

<%
process
%>