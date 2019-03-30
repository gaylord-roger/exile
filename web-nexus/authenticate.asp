<!--#include virtual="/master.asp"-->
<!--#include virtual="/lib/json.asp"-->
<%

// check that the query comes from an authorized server address
var authorizedList = ['127.0.0.1', '10.0.0.116', '10.0.0.119', '87.98.200.116', '87.98.200.117', '87.98.200.119'];
var address = Request.ServerVariables("REMOTE_ADDR");
var authorized = false;
for(var i=0; i<authorizedList.length; i++)
	if(authorizedList[i] == address) {
		authorized = true;
		break;
	}

var id = ToStr(Request.QueryString('id').item);
var address = ToStr(Request.QueryString('address').item);

if(authorized) {
	var userid = Application('connect-' + id);

	if(userid == null)
		var result = {id:id, address:address, error:'credentials not found', userid:null};
	else
		var result = {error:'', userid:userid, lcid:Session.LCID};
}
else
	var result = {error:'unauthorized address', userid:null};

Response.Write(result.toJSON());

%>