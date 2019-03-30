var scriptPath = location.href;
var p = scriptPath.lastIndexOf('/');
if(p >= 0) scriptPath = scriptPath.substring(0, p);
scriptPath += '/';

var scriptFile = location.href;
p = scriptFile.indexOf('?');
if(p >= 0) scriptFile = scriptFile.substring(0, p);
p = scriptFile.indexOf('#');
if(p >= 0) scriptFile = scriptFile.substring(0, p);


function getval(name) {
	var obj = $(name);
	if(obj == null) return 0;

	var s = parseInt(obj.value, 10);
	if(isNaN(s) || (s < 0)) return 0; else return s;
}

function setval(name, val) {
	$(name).value = val;
}

function getWindowDimensions(){
	scrollX = document.documentElement.scrollLeft || document.body.scrollLeft;
	scrollY = document.documentElement.scrollTop || document.body.scrollTop;

	if(window.innerWidth) return {width: scrollX+window.innerWidth + scrollX, height: scrollY+window.innerHeight};
	if(document.documentElement && document.documentElement.clientHeight) return {width: scrollX+document.documentElement.clientWidth, height: scrollY+document.documentElement.clientHeight};
	if(document.body) return {width: scrollX+document.body.clientWidth, height: scrollY+document.body.clientHeight};
}

/*
 * format functions 
 */

// Returns a formatted string assembled from a format string and an array of values
// s is the string to be formated
// args is an array of values to replace in the format string
function format(s, args) {
	var rx = new RegExp('\\$([a-z0-9]+)(:[a-z]+|)', 'ig');
	var arr = null;

	while(arr = rx.exec(s)) {
		var value = args[arr[1]];

		switch(arr[2]){
			case ':n':
				value = formatNumber(value);
				break;
			case ':alliance':
				value = '<a href="alliance.asp?tag=' + value.tag + '">[' + value.tag + '] ' + value.name + '</a>';
				break;
			case ':player':
				value = '<a href="nation.asp?name=' + value + '">' + value + '</a>';
				break;
			case ':research':
				value = Exile.data.researches[value].name;
			default:
				break;
		}

		s = s.replace(arr[0], value);
	}

	return s;
}

var wbr = "<wbr/>";
if(navigator.userAgent.indexOf("Opera") != -1) wbr = "&#8203;";	

function addWbr(str) {
	if(str.length < 30) return str;

	var s = "";
	for(k=0;k<str.length;k+=2)
		s = s + str.substr(k,2) + wbr;
	return s;
}


function addThousands(nStr, outD, sep) {
	nStr += '';
	var dpos = nStr.indexOf(".");
	var nStrEnd = '';
	if (dpos != -1) {
		nStrEnd = outD + nStr.substring(dpos + 1, nStr.length);
		nStr = nStr.substring(0, dpos);
	}
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(nStr)) {
		nStr = nStr.replace(rgx, '$1' + sep + '$2');
	}
	return nStr + nStrEnd;
}

function formatNumber(n) {
	return addThousands(n,'.',' ');
}

Number.prototype.n = function() { return addThousands(this,'.',' '); }
Number.prototype.lz = function() { return (this < 10?"0":"") + this; }

function UTCDate(x) {
	return new Date(x - new Date().getTimezoneOffset()*60000);
}