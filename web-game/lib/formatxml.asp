<%

function formatXml(xmlText, xslPath)
	'Load the XML
	dim xml
	set xml = Server.CreateObject("Microsoft.XMLDOM")
	xml.async = false
	xml.resolveExternals = false	' dont resolve dtd
	xml.validateOnParse = false 
	xml.loadxml xmlText

	'Load the XSL
	dim xsl
	set xsl = Server.CreateObject("Microsoft.XMLDOM")
	xsl.async = false
	xsl.load Server.MapPath(xslPath)

	formatXml = xml.transformNode(xsl)
end function

%>