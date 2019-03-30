var Language = {
	LCID: 0,
	name: '',
	strings: {},
	longDayNames: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
	longMonthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
	shortMonthNames: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
	thousandSeparator: ' ',
	shortDay: 'd'
}

// return the string from the language package formatted with the arguments
function $L(stringId, args) {
	var str = Language.strings[stringId];

	if(typeof str == 'undefined')
		return '##' + stringId + '##';

	if(typeof args != 'undefined' && $A(args).size() > 0)
		return format(str, args);

	return str;
}