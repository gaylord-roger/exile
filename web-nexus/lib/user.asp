<%
var User = {
	id: 0,
	name: '',
	lastUniverseID: null,
	lastVisit: null,
	isLogged: false,
	address: '',
	authID: '',
	privileges: {},
	save: function() {
		Session('user') = this;
	},
	setID: function(id) {
		if(!this.isLogged) {
			Application.lock();
			Application("users")++;
			Application.unlock();
		}
		this.id = id;
		this.isLogged = true;
		this.save();
	},
	setName: function(name) {
		this.name = name;
		this.save();
	},
	setLastUniverseID: function(universeID) {
		this.lastUniverseID = universeID;
		this.save();
	},
	setLastVisit: function(lastVisit) {
		this.lastVisit = lastVisit;
		this.save();
	},
	setAddress: function(address) {
		this.address = address;
		this.save();
	},
	setAuthID: function(authID) {
		this.authID = authID;
		this.save();
	},
	setPrivilege: function(name, value) {
		this.privileges[name] = value;
		this.save();
	}
}

User.session = Session('user');
if(User.session != null) {
	User.authID = User.session.authID;
	User.id = User.session.id;
	User.name = User.session.name;
	User.lastUniverseID = User.session.lastUniverseID;
	User.lastVisit = User.session.lastVisit;
	User.isLogged = User.session.isLogged;
	User.address = User.session.address;
	User.privileges = User.session.privileges;
}
%>