<script language="JScript" runat="server">

var connectionStrings = {
	tcg: "DSN=exile_tcg",
	nexus: "DSN=exile_nexus",
	game: ""
};

var registration = {
	enabled:true,
	until:null
};

var urlNexus = "http://www.monexile.lan/";

var allowedOrientations = [1,2,3];
var allowedRetry = true;
var allowedHolidays = true;

var hasAdmins = false;	// allow to send messages to administrators or not

var maintenance = false;			// enable/disable maintenance
var maintenance_msg = "Maintenance serveur ..."; //"Mise à jour logiciel ...";//"Maintenance serveur" //Migration de la base de donnée";

var supportMail = "info@exil.pw";
var senderMail = "exil.pw<invalid@exil.pw>";


var adExecuteNoRecords = 128;

// Players relationships constants (pas touche !)
var rUninhabited = -3;
var rWar = -2;
var rHostile = -1;
var rFriend = 0;
var rAlliance = 1;
var rSelf = 2;

// Session constant names
var sUser = "user";
var sPlanet = "planet";
var sLastLogin = "lastlogin";
var sPlanetList = "planetlist";
var sPlanetListCount = "planetlistcount";
var sPrivilege = "Privilege";
var sLogonUserID = "logonuserid"; // this is the userid when the user logged in, it won't change even if another user is impersonated

// Set response codepage to UTF-8
Response.CodePage = 65001;
Response.CharSet = "utf-8";

</script>

<!--#include virtual="/config/config.asp"-->