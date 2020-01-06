<?xml version='1.0'?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
  xmlns:xml="http://www.w3.org/XML/1998/namespace" 
  xmlns:exsl="http://exslt.org/common" 
  xmlns:date="http://exslt.org/dates-and-times" 
  xmlns:str="http://exslt.org/strings" extension-element-prefixes="exsl date str">

<xsl:param name="debug.chapter.start" select="'0'" />

<xsl:include href="mathbook-common.xsl"/>



<!-- Entry template: -->
<xsl:template match="/">
  <xsl:apply-templates select="*" mode="slides"/>
</xsl:template>

<!-- Default behavior is to move along unless told otherwise (below). -->
<xsl:template match="*" mode="slides">
  <xsl:apply-templates select="*" mode="slides"/>
</xsl:template>


<!-- Each section gets its own slideshow ptx file  -->
<xsl:template match="section" mode="slides">
  <xsl:call-template name="slideshow-files"/>
</xsl:template>

<!-- Introductions to chapters get their own ptx file as well -->
<xsl:template match="chapter" mode="slides">
  <xsl:call-template name="slideshow-files"/>
</xsl:template>

<!-- Subsections get recorded inside a sections slideshow: -->
<xsl:template match="subsection" mode="slides">
  <subsection>
    <title><xsl:value-of select="title"/></title>
    <xsl:if test="subtitle">
      <subtitle>
        <xsl:value-of select="subtitle"/>
      </subtitle>
    </xsl:if>
    <xsl:apply-templates select="*" mode="slides"/>
  </subsection>
</xsl:template>


<!-- Produce nice filenames: -->
<xsl:template name="type-and-number">
  <xsl:variable name="filename">
    <xsl:apply-templates select="." mode="type-name" />
    <xsl:text>_</xsl:text>
    <xsl:apply-templates select="." mode="number" />
    <xsl:text>_</xsl:text>
    <xsl:apply-templates select="." mode="title-simple" />
  </xsl:variable>
  <xsl:value-of select="translate(translate(translate(translate($filename, '!', ''), '?', ''), '.', '-'), ' ', '-')"/>
</xsl:template>

<!-- Create a ptx file for the docinfo, just to make each section's file cleaner -->
<xsl:template name="docinfo-copy">
  <exsl:document href="slidesinfo.ptx">
      <xsl:copy-of select="/pretext/docinfo" />
 </exsl:document>
</xsl:template>

<!-- Make a file named by its title to put a slideshow in -->
<xsl:template name="slideshow-files">
  <xsl:variable name="filename">
    <xsl:call-template name="type-and-number"/>
    <text>.ptx</text>
  </xsl:variable>
  <exsl:document href="{$filename}" method="xml" indent="yes">
    <pretext xmlns:xi="http://www.w3.org/2001/XInclude">
      <xi:include href="slidesinfo.ptx" />
      <xsl:call-template name="docinfo-copy"/>
      <slideshow>
      <title>
        <xsl:value-of select="title"/>
      </title>
      <xsl:if test="subtitle">
        <subtitle>
          <xsl:value-of select="subtitle"/>
        </subtitle>
      </xsl:if>
        <xsl:apply-templates select="*" mode="slides"/>
      </slideshow>
    </pretext>
  </exsl:document>
</xsl:template>

<!-- Copy elements that should be copied, each in their own slide -->
<!-- Currently any numbered elements, plus anything that has slide=true -->
<xsl:template match="&REMARK-LIKE;|&COMPUTATION-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&DEFINITION-LIKE;|&THEOREM-LIKE;|&AXIOM-LIKE;|assemblage|figure|table|list|*[@slide='true']" mode="slides">
  <xsl:if test="@slide!='false' or not(@slide)">
  <slide>
    <xsl:copy select=".">
      <xsl:if test="self::definition or self::example or self::activity or self::note or self::theorem or self::fact or self::lemma or self::corollary or self::proposition">
        <xsl:attribute name="source-number">
          <xsl:apply-templates select="." mode="number"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="self::p">
        <xsl:value-of select="."/>
      </xsl:if>
      <xsl:for-each select="*[self::p or self::sidebyside or self::me or self::ol or self::ul or self::title or self::statement or self::introduction or self::task]">
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:copy>
  </slide>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>