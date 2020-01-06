<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Oscar Levin Andrew Rechnitzer, Steven Clontz, Robert A. Beezer

This file is part of PreTeXt.

PreTeXt is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 or version 3 of the
License (at your option).

PreTeXt is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<!-- Necessary to get some HTML constructions, -->
<!-- but want to be sure to override the entry -->
<!-- template to avoid chunking, etc.          -->
<xsl:import href="mathbook-html.xsl" />

<!-- text format -->
<xsl:output method="text" indent="no"/>

<!-- Switches -->
<!-- These switches should be in the publisher file,  -->
<!-- with more robust error-checking, once stabilized -->

<!-- Anything but 'no' (e.g 'yes') will create    -->
<!-- code assuming a local reveal.js installation -->
<!-- NB: this should be nore robust!              -->
<xsl:param name="local" select="'no'"/>

<!-- If desired CSS file is css/theme/solarized.css -->
<!-- then set "theme" parameter to "solarized".     -->
<!-- Default CSS/theme is css/theme/simple.css      -->
<xsl:param name="theme" select="'simple'"/>


<!-- We override the entry template, so as to avoid the "chunking"    -->
<!-- procedure, since we are going to *always* produce one monolithic -->
<!-- HTML file as the output/slideshow                                -->
<xsl:template match="/">
    <xsl:apply-templates select="pretext"/>
</xsl:template>

<xsl:template match="/pretext">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">Conversion to markdown presentations/slideshows (for pandoc to conver) is experimental&#xa;Requests for additional specific constructions welcome&#xa;Additional PreTeXt elements are subject to change</xsl:with-param>
    </xsl:call-template>
    <!--  -->
  <xsl:apply-templates select="slideshow" />
</xsl:template>

<!-- Kill creation of the index page from the -html -->
<!-- conversion (we just build one monolithic page) -->
<xsl:variable name="html-index-page" select="/.."/>

<!-- Write the infrastructure for a page -->
<xsl:template match="slideshow">
<!-- title information -->
  <xsl:text>%&#10;</xsl:text>
  <xsl:apply-templates select=".|frontmatter" mode="title-full"/>
  <xsl:text>&#xa;%&#10;</xsl:text>
  <xsl:apply-templates select=".|frontmatter" mode="author"/>
  <xsl:text>&#xa;&#xa;</xsl:text>
            <!-- For mathematics/MathJax -->
  <!-- <xsl:apply-templates select="/pretext/docinfo/macros"/> -->
  <!-- insert slides -->
  <!-- <xsl:apply-templates select="frontmatter/titlepage" mode="title-slide"/> -->
  <xsl:apply-templates select="section|slide"/>

</xsl:template>

<!-- Investigste named template "latex-macros" in -html -->
<xsl:template match="pretext/docinfo/macros">
  <!-- <div style="display: none;">
    <xsl:call-template name="begin-inline-math"/>
    <xsl:value-of select="."/>
    <xsl:call-template name="end-inline-math"/>
  </div> -->
</xsl:template>

<!-- A "section" contains multiple "slide", which we process,   -->
<!-- but first we make a special slide announcing the "section" -->
<xsl:template match="section">
  <xsl:text># </xsl:text>
  <xsl:apply-templates select="." mode="title-full"/>
  <xsl:text>&#xa;</xsl:text>
  <xsl:apply-templates select="slide"/>
</xsl:template>


<xsl:template match="slide">
    <xsl:text>## </xsl:text>
      <xsl:if test="@source-number">
      <xsl:value-of select="@source-label"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@source-number"/>:
    </xsl:if>
    <xsl:apply-templates select="." mode="title-full" />
    <xsl:text>&#xa; &#xa;</xsl:text>

    <xsl:apply-templates/>
    <xsl:text>----------------- &#xa;</xsl:text>
</xsl:template>

<xsl:template match="subslide">
  <div class="fragment">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="ul|ol">
  <xsl:if test="@pause = 'yes'">
    <xsl:text>::: incremental &#xa;</xsl:text>
  </xsl:if>
  <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
  <xsl:text>&#xa; &#xa;</xsl:text>
  <xsl:if test="@pause = 'yes'">
    <xsl:text>::: &#xa;</xsl:text>
  </xsl:if>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ol/li">
  <xsl:text>1. </xsl:text>
    <xsl:apply-templates/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<xsl:template match="ul/li">

  <xsl:text>- </xsl:text>
  <xsl:apply-templates/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>

<!-- TODO: implement pauses -->
<xsl:template match="dl">
  <xsl:apply-templates select="li"/>
</xsl:template>

<xsl:template match="dl/li">
  <xsl:apply-templates select="." mode="title-full"/>
  <xsl:text>&#xa;  ~ </xsl:text>
  <xsl:apply-templates select="*"/>
  <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- TODO: implement pauses -->
<xsl:template match="p">
    <xsl:apply-templates/>
  <xsl:text>&#xa;</xsl:text>
</xsl:template>


<xsl:template match="image">
  <img>
    <xsl:attribute name="src">
        <xsl:value-of select="@source" />
    </xsl:attribute>
    <xsl:if test="@pause = 'yes'">
      <xsl:attribute name="class">
        <xsl:text>fragment</xsl:text>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </img>
</xsl:template>

<!-- Side-By-Side -->
<!-- Built by implementing two abstract   -->
<!-- templates from the -common templates -->

<!-- Overall wrapper of a sidebyside  -->
<xsl:template match="sidebyside" mode="compose-panels">
    <xsl:param name="layout" />
    <xsl:param name="panels" />

    <xsl:variable name="left-margin"  select="$layout/left-margin" />
    <xsl:variable name="right-margin" select="$layout/right-margin" />

    <div style="display: table;">
        <xsl:attribute name="style">
            <xsl:text>display:table;</xsl:text>
            <xsl:text>margin-left:</xsl:text>
            <xsl:value-of select="$left-margin" />
            <xsl:text>;</xsl:text>
            <xsl:text>margin-right:</xsl:text>
            <xsl:value-of select="$right-margin" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:copy-of select="$panels" />
    </div>
</xsl:template>



<xsl:template match="definition" mode="type-name">
  <xsl:text>Definition</xsl:text>
</xsl:template>
<xsl:template match="definition">
  <div class="boxed definition">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
    <xsl:apply-templates select="statement"/>
</div>
</xsl:template>


<xsl:template match="theorem" mode="type-name">
  <xsl:text>Theorem</xsl:text>
</xsl:template>
<xsl:template match="corollary" mode="type-name">
  <xsl:text>Corollary</xsl:text>
</xsl:template>
<xsl:template match="lemma" mode="type-name">
  <xsl:text>Lemma</xsl:text>
</xsl:template>
<xsl:template match="proposition" mode="type-name">
  <xsl:text>Proposition</xsl:text>
</xsl:template>
<xsl:template match="theorem|corollary|lemma|proposition">
  <div class="theorem">
  <div>
    <h3>
      <xsl:choose>
      <xsl:when test="@source-number">
        <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="type-name" />:
      </xsl:otherwise>
    </xsl:choose>
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates select="statement"/>
  </div>
  <xsl:if test="proof">
  <div class="proof">
    <xsl:apply-templates select="proof"/>
  </div>
</xsl:if>
</div>
</xsl:template>

<xsl:template match="example" mode="type-name">
  <xsl:text>Example</xsl:text>
</xsl:template>
<xsl:template match="activity" mode="type-name">
  <xsl:text>Activity</xsl:text>
</xsl:template>
<xsl:template match="note" mode="type-name">
  <xsl:text>Note</xsl:text>
</xsl:template>
<xsl:template match="example|activity|note">
  <div class="activity">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="fact" mode="type-name">
  <xsl:text>Fact</xsl:text>
</xsl:template>
<xsl:template match="fact">
  <div class="definition">
    <h3>
      <xsl:apply-templates select="." mode="type-name" /> (<xsl:value-of select="@source-number"/>):
      <xsl:apply-templates select="." mode="title-full" />
    </h3>
      <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="xref">
  [REF=TODO]
</xsl:template>

</xsl:stylesheet>
