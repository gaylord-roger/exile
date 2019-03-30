// todo : a script function that displays resources quantity and is updated every minute
var resourcesnbr = 0;

function updateres(objname, totaltime, startdatetime, content2)
{
	var obj = document.getElementById(objname);
	var s = totaltime - Math.floor((new Date().getTime()-startdatetime)/1000);

	if(s > 0)
		if (timers_enabled)
			window.setTimeout('updatetime2("' + objname + '", ' + totaltime + ', "' + startdatetime + '", "' + content2 + '")', 900);
		else
			window.setTimeout('updatetime2("' + objname + '", ' + totaltime + ', "' + startdatetime + '", "' + content2 + '")', s*1000);
	else
	if(obj.innerHTML != content2) obj.innerHTML = unescape(content2);
}

function resource(quantity, production)
{
	document.write("<span id='res" + resourcenbr + "'>" + quantity + "</span>");
	updateres("cntdwn" + countdownnbr, seconds, new Date().getTime(), escape(content2));
	countdownnbr++; 
}