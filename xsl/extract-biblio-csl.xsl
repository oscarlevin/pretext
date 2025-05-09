<?xml version='1.0'?>

<!--********************************************************************
Copyright 2014-2025 Robert A. Beezer

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

<!-- This stylesheet locates video/@youtube elements and -->
<!-- prepares a Python dictionary necessary to extract a -->
<!-- thumbnail for each video from the YouTube servers   -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:xml="http://www.w3.org/XML/1998/namespace"
                xmlns:pi="http://pretextbook.org/2020/pretext/internal"
>

<!-- exclude-result-prefixes="pi" -->

<!-- Get internal ID's for filenames, etc -->
<!-- Standard conversion groundwork       -->
<!-- Includes "escape-json-string"        -->
<xsl:import href="./publisher-variables.xsl"/>
<xsl:import href="./pretext-assembly.xsl"/>
<xsl:import href="./pretext-common.xsl"/>

<!-- Get a "subtree" xml:id value   -->
<!-- Then walk the XML source tree  -->
<!-- applying specializations below -->
<xsl:import href="./extract-identity.xsl" />

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:variable name="biblio-csl-extracting">
    <xsl:value-of select="true()"/>
</xsl:variable>

<!-- We create a structured file of bibliographic and citation  -->
<!-- information from the document.  Following is an outline of -->
<!-- this structure, likely all in the "pi" (PreTeXt Internal)  -->
<!-- namespace.  This is all subject to change, which may just  -->
<!-- be cosmetic changes.                                       -->
<!--                                                            -->
<!--   <pretext-biblio-csl>                                     -->
<!--       <biblio-csl>                                         -->
<!--          [JSON in CSL-JSON format, per "references"]       -->
<!--      </biblio-csl>                                         -->
<!--      <all-biblio-id>                                       -->
<!--          [collection of #biblio-id in use in the document] -->
<!--      </all-biblio-id>                                      -->
<!--   </pretext-biblio-csl>                                    -->

<xsl:template match="/">
    <!-- overall root container for this file -->
    <xsl:element name="pretext-biblio-csl" namespace="http://pretextbook.org/2020/pretext/internal">
        <!-- multiple "references" divisions, each with their own element -->
        <!-- only considering backmatter references now                   -->
        <xsl:apply-templates select="$document-root//backmatter/references" mode="biblio-to-json"/>
        <!-- single container of *every* biblio in the document -->
        <xsl:element name="all-biblio-id" namespace="http://pretextbook.org/2020/pretext/internal">
            <xsl:apply-templates select="$document-root//biblio" mode="biblio-singleton"/>
        </xsl:element>
    </xsl:element>
</xsl:template>

<!-- Eventually we want to identify citations, that is "xref"    -->
<!-- that point to a "biblio".  Unclear if this list is a start, -->
<!-- or neessary, or helpful.  Not much is invested here.        -->
<xsl:template match="biblio" mode="biblio-singleton">
    <xsl:choose>
        <xsl:when test="not(@xml:id)">
            <xsl:message>A "biblio" without an "@xml:id"</xsl:message>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="biblio-id" namespace="http://pretextbook.org/2020/pretext/internal">
                <xsl:value-of select="@xml:id"/>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- The "biblio-to-json" template will convert a single "references" division (just the           -->
<!-- "backmatter" instance right now) into a single JSON structure in CSL-JSON/citeproc-JSON       -->
<!-- format.  (Seems both names are in use, we will use the first.)                                -->
<!-- Note that the names of PreTeXt elements will mimic the names of JSON fields, so we can        -->
<!-- use the "local-name()" function to have a single template cover multiple possibilities.       -->
<!--                                                                                               -->
<!-- Overview:                                                                                     -->
<!-- https://citeproc-js.readthedocs.io/en/latest/csl-json/markup.html                             -->
<!--                                                                                               -->
<!-- CSL-JSON/citeproc-JSON:                                                                       -->
<!-- https://github.com/citation-style-language/schema?tab=readme-ov-file#csl-json-schema          -->
<!-- https://github.com/citation-style-language/schema/blob/master/schemas/input/csl-data.json     -->
<!-- https://github.com/citation-style-language/schema/blob/master/schemas/input/csl-citation.json -->

<!-- TODO: expand to multiple "references" divisions -->

<!-- First, a catch-all version of the template to intercept un-implemented markup -->
<!-- TODO: perhaps report content also, as a better assist, or the self/parent/ancestor biblio id -->
<!-- TODO: refine to include un-implemented bits of "citeproc-py" (e/g static-ordering) -->
<xsl:template match="*" mode="biblio-to-json">
    <xsl:message>BUG: PreTeXt "biblio" markup using a "<xsl:value-of select="local-name()"/>" element is not implemented</xsl:message>
</xsl:template>

<!-- Gross JSON array structure, duplicate an ID for the division -->
<xsl:template match="backmatter/references" mode="biblio-to-json">
    <xsl:element name="biblio-csl" namespace="http://pretextbook.org/2020/pretext/internal">
        <xsl:attribute name="biblio-id">
            <xsl:apply-templates select="." mode="assembly-id"/>
        </xsl:attribute>
        <xsl:text>[&#xa;</xsl:text>
        <xsl:apply-templates select="biblio" mode="biblio-to-json"/>
        <xsl:text>&#xa;]</xsl:text>
    </xsl:element>
</xsl:template>

<!-- Convert each "biblio" to an object, assume PreTeXt markup is 100% structured. -->
<!-- TODO: refine "select" to only match to-level possibilities -->
<xsl:template match="biblio" mode="biblio-to-json">
    <xsl:text>{&#xa;</xsl:text>
    <xsl:apply-templates select="@xml:id|@type" mode="biblio-to-json"/>
    <xsl:apply-templates select="*" mode="biblio-to-json"/>
     <xsl:text>&#xa;}</xsl:text>
    <xsl:if test="following-sibling::biblio">
        <xsl:text>,&#xa;</xsl:text>
        <!-- intra-biblio visual formatting help -->
        <xsl:text>&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Attributes -->
<!-- Happy accident that local-name(@xml:id) is JSON "id" key for CSL -->

<!-- TODO: are the following attributes in PreTeXt markup? -->
<!--   citation-key                                        -->
<!--   categories  (an array.  of?)                        -->
<!--   language                                            -->
<!--   journalAbbreviation                                 -->
<!--   shortTitle                                          -->

<xsl:template match="@xml:id|@type" mode="biblio-to-json">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>"</xsl:text>
    <xsl:text>: </xsl:text>
    <xsl:text>"</xsl:text>
    <!-- attribute value content -->
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>",&#xa;</xsl:text>
</xsl:template>

<!-- Simple string fields to key/value pair -->
<!-- NB: in the order presented in CSL-JSON schema, except as noted.                  -->
<!-- NB: simple fields for parts of a name are later, and grouped together.           -->
<!-- NB: simple fields for alternate date model are at the end, and grouped together. -->
<!-- TODO: many more, from "abstract" to "year-suffix", plus for names and dates.     -->
<xsl:template match="publisher|publisher-place|page|title|URL|name/family|name/given|name/static-ordering|season|circa" mode="biblio-to-json">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>"</xsl:text>
    <!-- separator w/ space -->
    <xsl:text>: </xsl:text>
    <xsl:text>"</xsl:text>
    <!-- plain text content -->
    <!-- apply-templates for math in titles??? -->
    <xsl:call-template name="escape-json-string">
        <xsl:with-param name="text">
            <xsl:value-of select="."/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
    <xsl:if test="following-sibling::*">
        <xsl:text>,</xsl:text>
        <xsl:choose>
            <!-- top-label get a newline, else a space -->
            <xsl:when test="parent::biblio">
                <xsl:text>&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Name structures -->
<!-- ############### -->

<!-- Structured name variables. -->
<!-- TODO: see  "$ref": "#/definitions/name-variable"  in CSL-JSON -->
<!-- schema to identify many more.  "author" through "translator". -->
<xsl:template match="biblio/author|biblio/editor" mode="biblio-to-json">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>"</xsl:text>
    <xsl:text>: </xsl:text>
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="name" mode="biblio-to-json"/>
    <xsl:text>]</xsl:text>
    <xsl:if test="following-sibling::*">
        <xsl:text>,&#xa;</xsl:text>
    </xsl:if>
</xsl:template>

<!-- Name structure -->
<xsl:template match="biblio/*/name" mode="biblio-to-json">
    <xsl:text>{</xsl:text>
    <!-- Name content model includes simple fields like -->
    <!--     family, given, suffix, etc.                -->
    <!-- They will use the simple template above, where -->
    <!-- fields are qualified with the "name" parent    -->
    <xsl:apply-templates select="*" mode="biblio-to-json"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="following-sibling::name">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

<!-- ############### -->
<!-- Date structures -->
<!-- ############### -->

<!-- Structured date variables. -->
<!-- TODO: see  "$ref": "#/definitions/date-variable"  in CSL-JSON -->
<!-- schema to identify many more. "accessed" through "submitted". -->
<xsl:template match="submitted|issued" mode="biblio-to-json">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>"</xsl:text>
    <xsl:text>: </xsl:text>
    <xsl:text>{&#xa;</xsl:text>
    <xsl:if test="date">
    <!-- Outer array structure, even if singleton -->
        <xsl:text>"date-parts": </xsl:text>
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="date" mode="biblio-to-json"/>
        <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;}</xsl:text>
    <xsl:if test="following-sibling::*">
        <xsl:text>,</xsl:text>
        <xsl:choose>
            <!-- likely always first test? -->
            <xsl:when test="parent::biblio">
                <xsl:text>&#xa;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- An array of length 1 to 3, with spaces after commas -->
<xsl:template match="date" mode="biblio-to-json">
    <xsl:text>[</xsl:text>
    <xsl:if test="@year">
        <xsl:value-of select="@year"/>
    </xsl:if>
    <xsl:if test="@month">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="@month"/>
    </xsl:if>
    <xsl:if test="@day">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="@day"/>
    </xsl:if>
    <xsl:text>]</xsl:text>
    <xsl:if test="following-sibling::date">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>
