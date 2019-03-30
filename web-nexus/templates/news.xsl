<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/TR/WD-xsl">
<xsl:template match="/">
	<ul>
	<xsl:for-each select="rss/channel/item">
		<li>
		<a><xsl:attribute name="href"><xsl:value-of select="link"/></xsl:attribute>
		<xsl:attribute name="target">_blank</xsl:attribute>
		<xsl:value-of select="title"/></a>
		</li>
	</xsl:for-each>
	</ul>
</xsl:template>
</xsl:stylesheet>