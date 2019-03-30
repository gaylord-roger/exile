<%

var SQLConn = null;

// retrieve universe
//var universe = String(Request.ServerVariables("SERVER_NAME"));
//universe = universe.substring(0, universe.indexOf('.'));

SQLConn = new SQLConnection(Application('cs_nexus'));

Number.prototype.toSQL = function() {
	return this;
}

String.prototype.toSQL = function() {
	return '\'' + this.replace(/\\/g, '\\\\').replace(/'/g, '\'\'') + '\'';
}

Array.prototype.toSQL = function() {
	for(var i=0,len=this.length;i<len;i++) {
		this[i] = dosql(this[i]);
	}

	return this.join(',');
}

// return a quoted string for sql queries
function dosql(o) {
	if(o == null) return 'Null';
	if(typeof o.toSQL == 'function') return o.toSQL();
	if(typeof o != 'string' && typeof o != 'number') o = String(o);
	return o.toSQL();
}

var adExecuteNoRecords = 128;
var notnull = new Object();
var sqlTime = 0;


// Class SQLConnection
function SQLConnection(connectionString) {
	this.connectionString = connectionString;
	this.conn = null;
	this.inTransaction = false;

	this.connect = function() {
		if(this.conn == null) {
			this.conn = Server.CreateObject("ADODB.Connection");
			this.conn.Open(connectionString);
		}
	};

	this.close = function() {
		if(this.conn != null) {
			this.conn.Close();
			this.conn = null;
			this.inTransaction = false;
		}
	},

	this.execute = function(query) {	// tries to execute a query up to 3 times if it fails the first times
		var start = new Date();
		this.connect();
	//	return { EOF: function() { return false; } };
		var i = 0;
		while(i < 5) {
			try {
				var res = this.conn.Execute(query);
				sqlTime += new Date().getTime()-start.getTime();
				return res;
			} catch(e) {
				if(i > 2) {
					e.description = query + '\n' + e.description;
					sqlTime += new Date().getTime()-start.getTime();
					throw e;
				}
			}

			i++;
		}

		if(!this.inTransaction)
			this.close();
	};

	this.beginTrans = function() {
		this.connect();
		this.conn.beginTrans();
		this.inTransaction = true;
	};

	this.commitTrans = function() {
		this.inTransaction = false;
		this.conn.commitTrans();
		this.close();
	};

	this.rollbackTrans = function() {
		this.inTransaction = false;
		this.conn.rollbackTrans();
		this.close();
	};
}
/*
function SQLInsert(sql, params) {
	var columns = [];
	var values = [];

	for(var x in params.values) {
		columns.push(x);
		values.push(params.values[x]);
	}

	this.query = 'INSERT INTO ' + params.table + '("' + columns.join('","') + '")' +
				' VALUES(' + values.toSQL() + ')';

	if(params.returning && params.returning.length > 0) {
		this.query += ' RETURNING ' + params.returning.join(',');
	}

	this.execute = function() {
		return sqlExec(this.query);
	}
}

function SQLUpdate(sql, params) {
	var values = [];
	var where = [];

	for(var x in params.values) {
		values.push(x + '=' + dosql(params.values[x]));
	}

	for(var x in params.where) {
		var v = params.where[x];
		if(v == null)
			v = ' IS NULL';
		else
		if(v == notnull) 
			v = ' IS NOT NULL';
		else
			v = '=' + dosql(params.where[x]);
		where.push(x + v);
	}

	this.query = 'UPDATE ' + params.table + ' SET ' +
					values.join(',') +
				(where.length > 0?' WHERE ' + where.join(' AND '):'');

	if(params.returning && params.returning.length > 0) {
		this.query += ' RETURNING ' + params.returning.join(',');
	}

	this.execute = function() {
		return sqlExec(this.query);
	}
}

function SQLDelete(sql, params) {
	var where = [];

	for(var x in params.where) {
		where.push(x + '=' + dosql(params.where[x]));
	}

	this.query = 'DELETE FROM ' + params.table+
				(where.length > 0?' WHERE ' + where.join(' AND '):'');

	this.execute = function() {
		return sqlExec(this.query);
	}
}
*/
%>