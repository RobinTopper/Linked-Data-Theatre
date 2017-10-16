<!--

    NAME     rdf2ttl.xsl
    VERSION  1.19.0
    DATE     2017-10-16

    Copyright 2012-2017

    This file is part of the Linked Data Theatre.

    The Linked Data Theatre is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    The Linked Data Theatre is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.

-->
<!--
    DESCRIPTION
	Transformation of RDF document to turtle format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"

	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="fn"
	exclude-result-prefixes="xs fn"
>

<xsl:key name="bnodes" match="results/rdf:RDF[1]/rdf:Description|xmlresult/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>

<xsl:variable name="spaces">. .</xsl:variable>

<xsl:function name="fn:spaces" as="xs:string">
	<xsl:param name="tab" as="xs:integer"/>
	<xsl:variable name="result">
		<xsl:for-each select="2 to $tab"><xsl:value-of select="substring($spaces,2,1)"/></xsl:for-each>
	</xsl:variable>
	<xsl:value-of select="$result"/>
</xsl:function>

<xsl:variable name="prefix">
	<!-- Default prefixes -->
	<xsl:choose>
		<xsl:when test="exists(xmlresult/container/stage)">
			<xsl:for-each select="xmlresult/container/stage">
				<prefix name="stage"><xsl:value-of select="."/>#</prefix>
				<prefix name="container"><xsl:value-of select="substring-before(.,'stage')"/>container/</prefix>
				<prefix name="elmo">http://bp4mc2.org/elmo/def#</prefix>
			</xsl:for-each>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="xmlresult/container/url">
				<prefix name="container"><xsl:value-of select="."/>/</prefix>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
	<prefix name="xsd">http://www.w3.org/2001/XMLSchema#</prefix>
	<!-- Prefixes used in properties -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description/*|xmlresult/rdf:RDF[1]/rdf:Description/*" group-by="substring-before(name(),':')">
		<xsl:variable name="prefix" select="substring-before(name(),':')"/>
		<xsl:choose>
			<xsl:when test="$prefix!=''"><prefix name="{substring-before(name(),':')}"><xsl:value-of select="namespace-uri()"/></prefix></xsl:when>
			<xsl:otherwise>
				<xsl:for-each-group select="current-group()" group-by="namespace-uri()">
					<xsl:if test="namespace-uri()!=''">
						<prefix name="ns{position()}"><xsl:value-of select="namespace-uri()"/></prefix>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each-group>
	<!-- Prefixes used in about -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description|xmlresult/rdf:RDF[1]/rdf:Description" group-by="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')"><xsl:sort select="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')" order="descending"/>
		<xsl:variable name="prefix" select="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')"/>
		<xsl:if test="$prefix!='' and substring-after(@rdf:about,$prefix)!=''">
			<prefix name="n{position()}"><xsl:value-of select="$prefix"/></prefix>
		</xsl:if>
	</xsl:for-each-group>
</xsl:variable>

<xsl:template match="@rdf:about|@rdf:resource" mode="uri">
	<xsl:variable name="fulluri" select="."/>
	<xsl:variable name="uriprefix" select="$prefix/prefix[substring-after($fulluri,.)!=''][1]"/>
	<xsl:variable name="localname"><xsl:value-of select="substring-after($fulluri,$uriprefix)"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$uriprefix/@name!='' and matches($localname,'^[0-9A-Za-z-_~.]+$')">
			<xsl:value-of select="$uriprefix/@name"/>:<xsl:value-of select="$localname"/>
		</xsl:when>
		<xsl:otherwise>&lt;<xsl:value-of select="."/>></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="property">
	<xsl:choose>
		<xsl:when test="contains(name(),':') or namespace-uri()=''"><xsl:value-of select="name()"/></xsl:when>
		<xsl:otherwise>
			<xsl:variable name="ns" select="namespace-uri()"/>
			<xsl:value-of select="$prefix/prefix[.=$ns]/@name"/>:<xsl:value-of select="name()"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="literalvalue">
	<xsl:value-of select="replace(.,'\\','\\\\')"/>
</xsl:template>

<xsl:template match="*" mode="literal">
	<xsl:choose>
		<xsl:when test="contains(.,'&#10;') or contains(.,'&quot;')">'''<xsl:apply-templates select="." mode="literalvalue"/>'''<xsl:apply-templates select="." mode="datatype"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#integer'"><xsl:apply-templates select="." mode="literalvalue"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#decimal'"><xsl:apply-templates select="." mode="literalvalue"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#boolean'"><xsl:apply-templates select="." mode="literalvalue"/></xsl:when>
		<xsl:otherwise>"<xsl:apply-templates select="." mode="literalvalue"/>"<xsl:apply-templates select="." mode="datatype"/></xsl:otherwise>
	</xsl:choose>
	<xsl:if test="not(@rdf:datatype!='') and @xml:lang!=''">@<xsl:value-of select="@xml:lang"/></xsl:if>
</xsl:template>

<xsl:template match="*" mode="datatype">
	<xsl:if test="@rdf:datatype!=''">
		<xsl:text>^^</xsl:text>
		<xsl:choose>
			<xsl:when test="matches(@rdf:datatype,'^http://www\.w3\.org/2001/XMLSchema#.+')">xsd:<xsl:value-of select="replace(@rdf:datatype,'^http://www\.w3\.org/2001/XMLSchema#(.+)','$1')"/></xsl:when>
			<xsl:otherwise>&lt;<xsl:value-of select="@rdf:datatype"/>&gt;</xsl:otherwise>
		</xsl:choose>
	</xsl:if>
</xsl:template>

<xsl:template match="*" mode="listrec">
	<xsl:for-each select="rdf:first">
		<xsl:choose>
			<!-- NOTE: blank nodes and lists not supported within a list yet -->
			<xsl:when test="exists(@rdf:resource)"><xsl:apply-templates select="@rdf:resource" mode="uri"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="literal"/></xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="key('bnodes',rdf:rest/@rdf:nodeID)" mode="listrec"/>
</xsl:template>

<xsl:template match="*" mode="list">
	<xsl:text>(</xsl:text><xsl:apply-templates select="." mode="listrec"/><xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="*" mode="triple"><xsl:param name="tab" as="xs:integer"/>
<xsl:apply-templates select="." mode="property"/><xsl:text> </xsl:text><xsl:choose><xsl:when test="exists(@rdf:resource)"><xsl:apply-templates select="@rdf:resource" mode="uri"/></xsl:when><xsl:when test="exists(@rdf:nodeID) and exists(key('bnodes',@rdf:nodeID)/rdf:first)"><xsl:apply-templates select="key('bnodes',@rdf:nodeID)" mode="list"/></xsl:when><xsl:when test="exists(@rdf:nodeID)">[
<xsl:for-each select="key('bnodes',@rdf:nodeID)/*"><xsl:if test="position()!=1">;
</xsl:if><xsl:value-of select="fn:spaces($tab)"/><xsl:apply-templates select="." mode="triple"><xsl:with-param name="tab" select="$tab+4"/></xsl:apply-templates></xsl:for-each><xsl:text>
</xsl:text><xsl:value-of select="fn:spaces(-4+$tab)"/>]</xsl:when><xsl:otherwise><xsl:apply-templates select="." mode="literal"/></xsl:otherwise></xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF">
<xsl:for-each-group select="$prefix/prefix" group-by=".">@prefix <xsl:value-of select="@name"/>: &lt;<xsl:value-of select="."/>>.
</xsl:for-each-group>
<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
<xsl:apply-templates select="@rdf:about" mode="uri"/><xsl:for-each select="current-group()/*"><xsl:choose><xsl:when test="position()!=1">;
    </xsl:when><xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise></xsl:choose><xsl:apply-templates select="." mode="triple"><xsl:with-param name="tab">8</xsl:with-param></xsl:apply-templates></xsl:for-each>
.
</xsl:for-each-group>
</xsl:template>

<xsl:template match="/">
	<xsl:apply-templates select="results/rdf:RDF[1]"/>
	<xsl:for-each select="xmlresult">
		<turtle>
			<xsl:apply-templates select="rdf:RDF[1]"/>
		</turtle>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>