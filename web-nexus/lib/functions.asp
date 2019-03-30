<%
// create a random password
function makePassword(len) {
	var letters = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ234567899';

	var s = '';

	for(var i=0; i<len; i++)
		s += letters.charAt(Math.floor(Math.random()*letters.length));

	return s;
}

// retrieve a file content
function getFileContent(filename) {
	var fs = Server.CreateObject('Scripting.FileSystemObject');
	var thisfile = fs.OpenTextFile(filename, 1, false);

	var content = thisfile.ReadAll();

	thisfile.Close();
	thisfile = null;
	fs = null;

	return content;
}


// validate username
function validateUserName(myName) {
	if(myName.length < 2 || myName.length > 12) return false;
	var rx = new RegExp('^[a-zA-Z0-9]+$', 'i');
	return rx.test(myName);
}


// validate an email
function validateEmail(myEmail) {
	var rx = new RegExp('^[\\w-+]+([\\.]?[\\w+-]+)*@([A-Za-z\\d]+?([-]*[A-Za-z\\d]+)*[\\.]?)+[A-Za-z]{2,4}$', 'i');
	return rx.test(myEmail);
}


function validatePassword(myPassword) {
	if(myPassword.length < 6 || myPassword.length > 16) return false;
	return true;
}
%>