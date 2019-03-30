<!--#include virtual="/master.asp"-->

<%

var content = loadTemplate("index");

if(!maintenanceNexus) {
	var rs = SQLConn.execute("SELECT id, xml FROM news");

	while(!rs.EOF) {
		content.AssignValue("news" + rs(0).value, formatXML(rs(1).value, "/templates/news.xsl"));
		rs.MoveNext();
	}
}

display(content);

%>