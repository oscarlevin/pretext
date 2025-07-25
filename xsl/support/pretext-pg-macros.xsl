<?xml version="1.0" encoding="UTF-8" ?>

<!-- ********************************************************************* -->
<!-- Copyright 2021                                                        -->
<!-- Robert A. Beezer                                                      -->
<!--                                                                       -->
<!-- This file is part of PreTeXt.                                         -->
<!--                                                                       -->
<!-- PreTeXt is free software: you can redistribute it and/or modify       -->
<!-- it under the terms of the GNU General Public License as published by  -->
<!-- the Free Software Foundation, either version 2 or version 3 of the    -->
<!-- License (at your option).                                             -->
<!--                                                                       -->
<!-- PreTeXt is distributed in the hope that it will be useful,            -->
<!-- but WITHOUT ANY WARRANTY; without even the implied warranty of        -->
<!-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         -->
<!-- GNU General Public License for more details.                          -->
<!--                                                                       -->
<!-- You should have received a copy of the GNU General Public License     -->
<!-- along with PreTeXt.  If not, see <http://www.gnu.org/licenses/>.      -->
<!-- ********************************************************************* -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
>

<!-- This style sheet creates a perl library (.pl) file with WeBWorK PG    -->
<!-- macros that support WeBWorK problems authored in a PreTeXt project.   -->
<!-- Eventually when used by the pretext script, the name of the perl      -->
<!-- library file will be generated from the project title.                -->

<!-- Standard conversion groundwork -->
<xsl:import href="../publisher-variables.xsl"/>
<xsl:import href="../pretext-assembly.xsl"/>
<xsl:import href="../pretext-common.xsl"/>

<!-- We need to alert the pretext-assembly.xsl stylesheet     -->
<!-- that it is being used in the very specific instance      -->
<!-- of extracting these objects for processing externally,   -->
<!-- with results collected in additional files, for          -->
<!-- consultation/collection in a more general use of this    -->
<!-- stylesheet for the purpose of actually building a useful -->
<!-- output format.  This variable declaration here overrides -->
<!-- the default setting of "false" in pretext-assembly.xsl.  -->
<!-- Look there for a more comprehensive discussion of the    -->
<!-- necessity of this scheme.                                -->
<xsl:variable name="b-extracting-pg" select="true()"/>

<!-- We are outputting perl code, and there is no reason to output         -->
<!-- anything other than "text"                                            -->
<xsl:output method="text" encoding="UTF-8" />

<!--#######################################################################-->
<!-- Entry Template                                                        -->
<!--#######################################################################-->

<xsl:template match="/">
    <xsl:variable name="macro-file-name">
        <xsl:choose>
            <xsl:when test="$docinfo/initialism">
                <xsl:value-of select="$docinfo/initialism"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$document-root" mode="title-filesafe"/>
            </xsl:otherwise>
        </xsl:choose>
        <text>.pl</text>
    </xsl:variable>
    <xsl:variable name="macro-file-content">
        <xsl:call-template name="header"/>
        <xsl:apply-templates select="$document-root" mode="latex-image-preamble"/>
    </xsl:variable>
    <exsl:document href="{$macro-file-name}" method="text">
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$macro-file-content" />
        </xsl:call-template>
    </exsl:document>
</xsl:template>

<xsl:template match="book|article" mode="latex-image-preamble">
    <xsl:if test="$docinfo/latex-image-preamble">
        <xsl:text># Return a string containing the latex-image-preamble contents.&#xa;</xsl:text>
        <xsl:text># To be used by LaTeXImage objects as in:&#xa;</xsl:text>
        <xsl:text># $image->addToPreamble(latexImagePreamble())&#xa;</xsl:text>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>sub latexImagePreamble {&#xa;</xsl:text>
        <xsl:text>return &lt;&lt;'END_LATEX_IMAGE_PREAMBLE'&#xa;</xsl:text>
        <xsl:call-template name="sanitize-text">
            <xsl:with-param name="text" select="$docinfo/latex-image-preamble" />
        </xsl:call-template>
        <xsl:text>&#xa;</xsl:text>
        <xsl:text>END_LATEX_IMAGE_PREAMBLE&#xa;</xsl:text>
        <xsl:text>}&#xa;&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<xsl:template name="header">
    <xsl:text>#############################################################################&#xa;</xsl:text>
    <xsl:text># This macro library supports WeBWorK problems from the PreTeXt project named&#xa;</xsl:text>
    <xsl:text># </xsl:text>
    <xsl:apply-templates select="$document-root" mode="title-full" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>#############################################################################&#xa;</xsl:text>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
