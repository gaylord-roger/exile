<%
function formatXML(xmlText, xslPath) {
	// Load the XML
	var xml = Server.CreateObject("Microsoft.XMLDOM")
	xml.async = false;
	xml.resolveExternals = false;	// dont resolve dtd
	xml.validateOnParse = false;
	xml.loadXML(xmlText);

	// Load the XSL
	var xsl = Server.CreateObject("Microsoft.XMLDOM");
	xsl.async = false;
	xsl.load(Server.MapPath(xslPath));

	return xml.transformNode(xsl);
}

%>