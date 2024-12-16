<?xml version='1.0'?>

<!--********************************************************************
Copyright 2020 Robert A. Beezer

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


<!-- WARNING: this is an experimental conversion for LaTeX -->
<!-- Use `pretext-latex.xsl` for the standard conversion.  -->


<!-- Conveniences for classes of similar elements -->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "./entities.ent">
    %entities;
]>

<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
>

<!-- We override specific templates of the common conversion   -->

<xsl:import href="./pretext-latex-common.xsl" />

<!-- Note (2024-11-14): This is the start of a new "classic"    -->
<!-- latex conversion that can be used to create journal-ready  -->
<!-- latex documents.  Currently it does nothing different than -->
<!-- pretext-latex.xsl, but this will change in the future.     -->


<xsl:template match="/">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">You are using (a version of) the pretext-latex-classic conversion, which is still experimental and under development.</xsl:with-param>
      </xsl:call-template>
  <xsl:apply-imports />
</xsl:template>

<!-- Currently there are no changes for a book (or letter or memo), so we note this and exit -->
<xsl:template match="book|letter|memo">
    <xsl:call-template name="banner-warning">
        <xsl:with-param name="warning">You have selected a latex style designed for articles, but are not building an article.  The resulting output will be identical to that of not specifying any latex style.</xsl:with-param>
      </xsl:call-template>
</xsl:template>


<!-- Defaults that can be overriden by style files -->
<xsl:variable name="documentclass" select="'amsart'"/>
<xsl:variable name="bibliographystyle" select="'amsplain'"/>

<!-- An article, LaTeX structure -->
<!--     One page, full of sections (with abstract, references)                    -->
<!--     Or, one page, totally unstructured, just lots of paragraphs, widgets, etc -->
<xsl:template match="article">
    <xsl:call-template name="converter-blurb-latex"/>
    <xsl:call-template name="snapshot-package-info"/>
    <xsl:text>\documentclass[</xsl:text>
    <xsl:call-template name="sidedness"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="$font-size"/>
    <xsl:text>,</xsl:text>
    <xsl:if test="$b-latex-draft-mode" >
        <xsl:text>draft,</xsl:text>
    </xsl:if>
    <xsl:text>]{</xsl:text>
    <xsl:value-of select="$documentclass" />
    <xsl:text>}&#xa;&#xa;</xsl:text>

    <xsl:call-template name="latex-preamble" />
    <!-- parameterize preamble template with "page-geometry" template conditioned on self::article etc -->
    <xsl:call-template name="title-page-info-article" />
    <xsl:text>\begin{document}&#xa;&#xa;</xsl:text>

    <!--<xsl:call-template name="topmatter-amsart"/>-->

    <!--<xsl:text>\maketitle&#xa;</xsl:text>-->

    <xsl:apply-templates />

    <xsl:text>\end{document}&#xa;&#xa;</xsl:text>
</xsl:template>




<xsl:template name="latex-preamble">
    <xsl:call-template name="preamble-early"/>
    <xsl:call-template name="cleardoublepage"/>
    <xsl:call-template name="standard-packages"/>
    <xsl:call-template name="latex-theorem-environments"/>
    <!--<xsl:call-template name="tcolorbox-init"/>-->
    <!--<xsl:call-template name="page-setup"/>-->
    <!--<xsl:call-template name="latex-engine-support"/>-->
    <xsl:call-template name="font-support"/>
    <xsl:call-template name="math-packages"/>
    <xsl:call-template name="pdfpages-package"/>
    <!--<xsl:call-template name="division-titles"/>-->
    <xsl:call-template name="semantic-macros"/>
    <xsl:call-template name="exercises-and-solutions"/>
    <!--<xsl:call-template name="chapter-start-number"/>-->
    <!--<xsl:call-template name="equation-numbering"/>-->
    <!--<xsl:call-template name="image-tcolorbox"/>-->
    <xsl:call-template name="tables"/>
    <!--<xsl:call-template name="footnote-numbering"/>-->
    <!--<xsl:call-template name="font-awesome"/>-->
    <xsl:call-template name="poetry-support"/>
    <xsl:call-template name="music-support"/>
    <xsl:call-template name="code-support"/>
    <!--<xsl:call-template name="list-layout"/>-->
    <xsl:call-template name="load-configure-hyperref"/>
    <!--<xsl:call-template name="create-numbered-tcolorbox"/>-->
    <xsl:call-template name="watermark"/>
    <xsl:call-template name="showkeys"/>
    <xsl:call-template name="latex-image-support"/>
    <xsl:call-template name="sidebyside-environment"/>
    <xsl:call-template name="kbd-keys"/>
    <xsl:call-template name="late-preamble-adjustments"/>
</xsl:template>



<!-- Tables -->
<xsl:template name="tables">
    <xsl:if test="$document-root//tabular">
        <xsl:text>%% For improved tables&#xa;</xsl:text>
        <xsl:text>\usepackage{array}&#xa;</xsl:text>
        <xsl:text>%% Some extra height on each row is desirable, especially with horizontal rules&#xa;</xsl:text>
        <xsl:text>%% Increment determined experimentally&#xa;</xsl:text>
        <xsl:text>\setlength{\extrarowheight}{0.2ex}&#xa;</xsl:text>
        <xsl:text>%% Define variable thickness horizontal rules, full and partial&#xa;</xsl:text>
        <xsl:text>%% Thicknesses are 0.03, 0.05, 0.08 in the  booktabs  package&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
        <xsl:text>\newcommand{\hrulethin}  {\noalign{\hrule height 0.04em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulemedium}{\noalign{\hrule height 0.07em}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\hrulethick} {\noalign{\hrule height 0.11em}}&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/24549/horizontal-rule-with-adjustable-height-behaving-like-clinen-m -->
        <!-- Could preserve/restore \arrayrulewidth on entry/exit to tabular -->
        <!-- But we'll get cleaner source with this built into macros        -->
        <!-- Could condition \setlength debacle on the use of extpfeil       -->
        <!-- arrows (see discussion below)                                   -->
        <xsl:text>%% We preserve a copy of the \setlength package before other&#xa;</xsl:text>
        <xsl:text>%% packages (extpfeil) get a chance to load packages that redefine it&#xa;</xsl:text>
        <xsl:text>\let\oldsetlength\setlength&#xa;</xsl:text>
        <xsl:text>\newlength{\Oldarrayrulewidth}&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulethin}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.04em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}%&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulemedium}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.07em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
        <xsl:text>\newcommand{\crulethick}[1]%&#xa;</xsl:text>
        <xsl:text>{\noalign{\global\oldsetlength{\Oldarrayrulewidth}{\arrayrulewidth}}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{0.11em}}\cline{#1}%&#xa;</xsl:text>
        <xsl:text>\noalign{\global\oldsetlength{\arrayrulewidth}{\Oldarrayrulewidth}}}&#xa;</xsl:text>
        <!-- http://tex.stackexchange.com/questions/119153/table-with-different-rule-widths -->
        <xsl:text>%% Single letter column specifiers defined via array package&#xa;</xsl:text>
        <xsl:text>\newcolumntype{A}{!{\vrule width 0.04em}}&#xa;</xsl:text>
        <xsl:text>\newcolumntype{B}{!{\vrule width 0.07em}}&#xa;</xsl:text>
        <xsl:text>\newcolumntype{C}{!{\vrule width 0.11em}}&#xa;</xsl:text>
        <!-- naked tabulars work best in a tcolorbox -->
        <xsl:text>%% tcolorbox to place tabular outside of a sidebyside&#xa;</xsl:text>
        <!--<xsl:text>\tcbset{ tabularboxstyle/.style={bwminimalstyle,} }&#xa;</xsl:text>
        <xsl:text>\newtcolorbox{tabularbox}[3]{tabularboxstyle, left skip=#1\linewidth, width=#2\linewidth,}&#xa;</xsl:text>-->
    </xsl:if>
    <xsl:if test="$document-root//cell/line">
        <xsl:text>\newcommand{\tablecelllines}[3]%&#xa;</xsl:text>
        <xsl:text>{\begin{tabular}[#2]{@{}#1@{}}#3\end{tabular}}&#xa;</xsl:text>
    </xsl:if>
</xsl:template>



<!-- Theorems, Proofs, Definitions, Examples, Exercises -->

<!-- Theorems have statement/proof structure                    -->
<!-- Definitions have notation, which is handled elsewhere      -->
<!-- Examples have no structure, or have statement and solution -->
<!-- Exercises have hints, answers and solutions                -->

<!-- For preamble -->
<!-- For now, just include everything -->
<!-- TODO: respect rename. -->
<!-- TODO: limit which ones to include by what is in document? -->
<xsl:template name="latex-theorem-environments">
    <xsl:text>%% Theorem-like environments&#xa;</xsl:text>
    <xsl:text>\theoremstyle{plain}&#xa;</xsl:text>
    <xsl:text>\newtheorem{theorem}{Theorem}[section]&#xa;</xsl:text>
    <xsl:text>\newtheorem{lemma}[theorem]{Lemma}&#xa;</xsl:text>
    <xsl:text>\newtheorem{corollary}[theorem]{Corollary}&#xa;</xsl:text>
    <xsl:text>\newtheorem{proposition}[theorem]{Proposition}&#xa;</xsl:text>
    <xsl:text>\newtheorem{claim}[theorem]{Claim}&#xa;</xsl:text>
    <xsl:text>\newtheorem{fact}[theorem]{Fact}&#xa;</xsl:text>
    <xsl:text>\newtheorem{identity}[theorem]{Identity}&#xa;</xsl:text>
    <xsl:text>\newtheorem{conjecture}[theorem]{Conjecture}&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{definition}&#xa;</xsl:text>
    <xsl:text>\newtheorem{definition}[theorem]{Definition}&#xa;</xsl:text>
    <xsl:text>\newtheorem{axiom}[theorem]{Axiom}&#xa;</xsl:text>
    <xsl:text>\newtheorem{principle}[theorem]{Principle}&#xa;</xsl:text>
    <xsl:text>\newtheorem{heuristic}[theorem]{Heuristic}&#xa;</xsl:text>
    <xsl:text>\newtheorem{hypothesis}[theorem]{Hypothesis}&#xa;</xsl:text>
    <xsl:text>\newtheorem{assumption}[theorem]{Assumption}&#xa;</xsl:text>
    <xsl:text>\newtheorem{openproblem}[theorem]{Open problem}&#xa;</xsl:text>
    <xsl:text>\newtheorem{openquestion}[theorem]{Open question}&#xa;</xsl:text>
    <xsl:text>\newtheorem{algorithm}[theorem]{Algorithm}&#xa;</xsl:text>
    <xsl:text>\newtheorem{question}[theorem]{Question}&#xa;</xsl:text>
    <xsl:text>\newtheorem{activity}[theorem]{Activity}&#xa;</xsl:text>
    <xsl:text>\newtheorem{exercise}[theorem]{Exercise}&#xa;</xsl:text>
    <xsl:text>\newtheorem{investigation}[theorem]{Investigation}&#xa;</xsl:text>
    <xsl:text>\newtheorem{exploration}[theorem]{Exploration}&#xa;</xsl:text>
    <xsl:text>\newtheorem{problem}[theorem]{Problem}&#xa;</xsl:text>
    <xsl:text>\newtheorem{example}[theorem]{Example}&#xa;</xsl:text>
    <xsl:text>\newtheorem{project}[theorem]{Project}&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>

    <xsl:text>\theoremstyle{remark}&#xa;</xsl:text>
    <xsl:text>\newtheorem{convention}[theorem]{Convention}&#xa;</xsl:text>
    <xsl:text>\newtheorem{warning}[theorem]{Warning}&#xa;</xsl:text>
    <xsl:text>\newtheorem{remark}[theorem]{Remark}&#xa;</xsl:text>
    <xsl:text>\newtheorem{insight}[theorem]{Insight}&#xa;</xsl:text>
    <xsl:text>\newtheorem{note}[theorem]{Note}&#xa;</xsl:text>
    <xsl:text>\newtheorem{observation}[theorem]{Observation}&#xa;</xsl:text>
    <xsl:text>\newtheorem{computation}[theorem]{Computation}&#xa;</xsl:text>
    <xsl:text>\newtheorem{technology}[theorem]{Technology}&#xa;</xsl:text>
    <xsl:text>\newtheorem{data}[theorem]{Data}&#xa;</xsl:text>
    <xsl:text>&#xa;</xsl:text>
</xsl:template>



<!-- In document -->
<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;|&DEFINITION-LIKE;|&REMARK-LIKE;|&COMPUTATION-LIKE;|&OPENPROBLEM-LIKE;|&EXAMPLE-LIKE;|&PROJECT-LIKE;|&ASIDE-LIKE;|exercise[boolean(&INLINE-EXERCISE-FILTER;)]|assemblage" mode="block-options">
    <!-- <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="type-name"/>
    <xsl:text>}</xsl:text> -->
    <xsl:call-template name="env-title"/>

    <!-- <xsl:if test="&THEOREM-FILTER; or &AXIOM-FILTER;">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="creator-full" />
        <xsl:text>}</xsl:text>
    </xsl:if> -->
    <!-- unique-id destined for tcolorbox  phantomlabel=  option -->
    <xsl:text>\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
</xsl:template>

<xsl:template name="env-title">
    <xsl:if test="title|creator">
        <xsl:text>[</xsl:text>
        <xsl:if test="title">
            <xsl:apply-templates select="." mode="title-full"/>
        </xsl:if>
        <xsl:if test="(title) and (creator)">
            <xsl:text>&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="creator">
            <xsl:apply-templates select="." mode="creator-full"/>
        </xsl:if>
        <xsl:text>]</xsl:text>
    </xsl:if>
</xsl:template>


<xsl:template match="figure">
    <xsl:text>\begin{figure}\label{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\caption{</xsl:text>
    <xsl:apply-templates select="." mode="caption-full"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{figure}&#xa;&#xa;</xsl:text>
</xsl:template>

<xsl:template match="image[not(ancestor::sidebyside)]">
    <xsl:apply-templates select="." mode="image-inclusion" />
    <!--<xsl:text>&#xa;</xsl:text>-->
</xsl:template>

<xsl:template match="image[latex-image]" mode="image-inclusion">
    <xsl:apply-templates select="latex-image"/>
</xsl:template>

<xsl:template match="table">
    <xsl:text>\begin{table}&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>\end{table}&#xa;&#xa;</xsl:text>
</xsl:template>


<!-- Divisions -->

<xsl:template match="section|subsection|subsubsection">
    <xsl:text>\</xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>}&#xa;&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>% end of </xsl:text>
    <xsl:value-of select="local-name(.)"/>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="." mode="title-full"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- Introductions and Conclusions -->
<!-- Introductions and conclusions are just their contents at their position. -->
<xsl:template match="article/introduction|chapter/introduction|section/introduction|subsection/introduction|appendix/introduction|exercises/introduction|solutions/introduction|worksheet/introduction|reading-questions/introduction|references/introduction">
    <xsl:text>% Introduction&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>% end introduction&#xa;</xsl:text>
</xsl:template>

<xsl:template match="article/conclusion|chapter/conclusion|section/conclusion|subsection/conclusion|appendix/conclusion|exercises/conclusion|solutions/conclusion|worksheet/conclusion|reading-questions/conclusion|references/conclusion">
    <xsl:text>% Conclusion&#xa;</xsl:text>
    <xsl:apply-templates select="*"/>
    <xsl:text>% End conclusion&#xa;</xsl:text>
</xsl:template>

<xsl:template match="references">
    <xsl:text>\bibliographystyle{</xsl:text>
    <xsl:value-of select="$bibliographystyle"/>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:text>\begin{thebibliography}{99}&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{thebibliography}&#xa;&#xa;</xsl:text>
</xsl:template>

<!-- ################### -->
<!-- References Sections -->
<!-- ################### -->
<!-- We use description lists to manage bibliographies,  -->
<!-- and \bibitem seems comfortable there, so our source -->
<!-- is nearly compatible with the usual usage           -->

<!-- As an item of a description list, but       -->
<!-- compatible with thebibliography environment -->
<xsl:template match="biblio[@type='raw'] | biblio[@type='bibtex']">

    <xsl:text>\bibitem</xsl:text>
    <!-- "label" (e.g. Jud99), or by default serial number -->
    <!-- LaTeX's bibitem will provide the visual brackets  -->
    <xsl:text>[</xsl:text>
    <xsl:apply-templates select="." mode="serial-number" />
    <xsl:text>]</xsl:text>
    <!-- "key" for cross-referencing -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="." mode="unique-id"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="." mode="label" />
    <xsl:apply-templates/>
    <xsl:text>&#xa;</xsl:text>

</xsl:template>

<!-- We provide a very simple treatment of paragraphs, putting a blank line before and after each. -->
<xsl:template match="p">
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#xa;&#xa;</xsl:text>
</xsl:template>


</xsl:stylesheet>