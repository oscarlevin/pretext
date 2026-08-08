<?xml version='1.0'?>

<!--********************************************************************
Copyright (C) 2020-2026  Robert A. Beezer

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
    xmlns:pi="http://pretextbook.org/2020/pretext/internal"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
    exclude-result-prefixes="pi"
>

<!-- ################ -->
<!-- Course Calendars -->
<!-- ################ -->

<!-- An instructor reuses course materials every term, so no real date  -->
<!-- may appear in the source.  This stylesheet turns *symbolic* date   -->
<!-- references ("week6.wed", "class17", "exam1+2d") into real dates,   -->
<!-- using a per-offering calendar in the publication file and a        -->
<!-- relative schedule in "docinfo" which never changes between terms.  -->
<!--                                                                    -->
<!-- Everything here is consumed through one resolved node-set,         -->
<!-- $calendar, so a reference is parsed exactly once and every         -->
<!-- consumer is a lookup.  See  doc/course-calendar-roadmap.md.        -->
<!--                                                                    -->
<!-- Placement: this is all used *after* the "version" pass of          -->
<!-- assembly, so it may read $version-docinfo, which is the single,    -->
<!-- already-resolved "docinfo".  Nothing here feeds the version pass;  -->
<!-- $components-fenced never learns that calendars exist.  That is the -->
<!-- entire reason release gating uses its own @release-id attribute    -->
<!-- rather than riding along on @component.                            -->

<!-- The build's reference date, overriding calendar/@as-of.  Accepts  -->
<!-- "today", an ISO 8601 date, or any symbolic reference.  Supplied   -->
<!-- by  pretext build - -as-of.  Tests need this: without a fixed     -->
<!-- reference date every assertion about released material rots       -->
<!-- overnight.                                                        -->
<xsl:param name="as-of" select="''"/>

<!-- ############ -->
<!-- Basic Facts -->
<!-- ############ -->

<xsl:variable name="calendar-pub" select="$publication/calendar"/>

<!-- A calendar is "active" only with a @start.  Absent a calendar     -->
<!-- entirely, every behavior in this file is inert and nothing        -->
<!-- changes for existing documents.                                   -->
<xsl:variable name="b-calendar" select="boolean($calendar-pub/@start)"/>

<!-- Release gating may be switched off for one build, so an           -->
<!-- instructor can make a full private copy without editing the       -->
<!-- schedule.  Dates still resolve; only the gating is suspended.     -->
<xsl:variable name="b-calendar-releases" select="$b-calendar and not($calendar-pub/@releases = 'ignore')"/>

<!-- The current date (when building) -->
<xsl:variable name="calendar-today" select="substring(date:date-time(), 1, 10)"/>

<xsl:variable name="calendar-start" select="string($calendar-pub/@start)"/>

<!-- Meeting pattern over MTWRFSU, with R = Thursday and U = Sunday   -->
<!-- Defaults to MWF when no @meets attribute is specified.           -->
<xsl:variable name="calendar-meets">
    <xsl:choose>
        <xsl:when test="$calendar-pub/@meets">
            <xsl:value-of select="translate(normalize-space($calendar-pub/@meets), 'mtwrfsu', 'MTWRFSU')"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>MWF</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<!-- Week 1 begins on the latest @week-starts day on or before @start, -->
<!-- so a term beginning on a Wednesday has a short week 1             -->
<!-- NB: XSLT's "mod" takes the sign of the dividend, so the "+ 7"     -->
<!-- guard is required, not decorative.                                -->
<xsl:variable name="calendar-week-starts-dow">
    <xsl:call-template name="calendar-dow-of-name">
        <xsl:with-param name="name">
            <xsl:choose>
                <xsl:when test="$calendar-pub/@week-starts">
                    <xsl:value-of select="$calendar-pub/@week-starts"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>mon</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:with-param>
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="calendar-week1-shift" select="((date:day-in-week($calendar-start) - number($calendar-week-starts-dow)) + 7) mod 7"/>

<xsl:variable name="calendar-week1-begin">
    <xsl:if test="$b-calendar">
        <xsl:value-of select="substring(date:add($calendar-start, concat('-P', $calendar-week1-shift, 'D')), 1, 10)"/>
    </xsl:if>
</xsl:variable>

<xsl:variable name="calendar-week1-daynum" select="floor(date:seconds(string($calendar-week1-begin)) div 86400)"/>

<!-- Absent @end the enumeration is capped at 30 weeks, so a malformed -->
<!-- calendar cannot spin.  A "classK" beyond the cap is an error.     -->
<xsl:variable name="calendar-end">
    <xsl:choose>
        <xsl:when test="$calendar-pub/@end">
            <xsl:value-of select="$calendar-pub/@end"/>
        </xsl:when>
        <xsl:when test="$b-calendar">
            <xsl:value-of select="substring(date:add(string($calendar-week1-begin), 'P210D'), 1, 10)"/>
        </xsl:when>
    </xsl:choose>
</xsl:variable>

<!-- ######## -->
<!-- Meetings -->
<!-- ######## -->

<!-- Stage 1 of resolution, depending only on the publication file:    -->
<!-- the ordered list of dates from @start through @end whose weekday  -->
<!-- is in @meets and which no holiday covers.  "classK" is the Kth    -->
<!-- entry; "weekN.dK" is the Kth entry inside week N's fixed 7-day    -->
<!-- block.  Both therefore skip holidays and slide, while a           -->
<!-- "weekN.<dayname>" reference does not - see "Rule A" in the        -->
<!-- roadmap.                                                          -->
<xsl:variable name="calendar-meetings-rtf">
    <xsl:if test="$b-calendar">
        <xsl:call-template name="calendar-enumerate-meetings">
            <xsl:with-param name="day" select="$calendar-start"/>
            <xsl:with-param name="last-daynum" select="floor(date:seconds(string($calendar-end)) div 86400)"/>
        </xsl:call-template>
    </xsl:if>
</xsl:variable>

<xsl:variable name="calendar-meetings" select="exsl:node-set($calendar-meetings-rtf)/pi:meeting"/>

<xsl:template name="calendar-enumerate-meetings">
    <xsl:param name="day"/>
    <xsl:param name="last-daynum"/>
    <xsl:param name="n" select="0"/>
    <xsl:param name="prev-week" select="0"/>
    <xsl:param name="wim" select="0"/>

    <xsl:variable name="daynum" select="floor(date:seconds($day) div 86400)"/>
    <xsl:if test="$daynum &lt;= $last-daynum">
        <!-- ISO dates must be compared as numbers: XPath 1.0 coerces  -->
        <!-- the operands of "&lt;=" to numbers, and "2026-09-07" is NaN. -->
        <xsl:variable name="isonum" select="number(translate($day, '-', ''))"/>
        <xsl:variable name="holiday" select="$calendar-pub/holiday[
                 number(translate(@on, '-', '')) = $isonum
              or (number(translate(@from, '-', '')) &lt;= $isonum
                  and number(translate(@through, '-', '')) &gt;= $isonum)]"/>
        <!-- day-in-week is 1-based from Sunday, so this indexes UMTWRFS -->
        <xsl:variable name="letter" select="substring('UMTWRFS', date:day-in-week($day), 1)"/>
        <xsl:variable name="week" select="floor(($daynum - $calendar-week1-daynum) div 7) + 1"/>
        <xsl:variable name="is-meeting" select="contains($calendar-meets, $letter) and not($holiday)"/>
        <xsl:variable name="same-week" select="$week = $prev-week"/>
        <xsl:variable name="new-wim" select="($wim + 1) * number($same-week) + number(not($same-week))"/>

        <xsl:if test="$is-meeting">
            <pi:meeting n="{$n + 1}" week="{$week}" wim="{$new-wim}" date="{$day}"/>
        </xsl:if>

        <xsl:call-template name="calendar-enumerate-meetings">
            <xsl:with-param name="day" select="substring(date:add($day, 'P1D'), 1, 10)"/>
            <xsl:with-param name="last-daynum" select="$last-daynum"/>
            <xsl:with-param name="n" select="$n + number($is-meeting)"/>
            <xsl:with-param name="prev-week" select="$week * number($is-meeting) + $prev-week * number(not($is-meeting))"/>
            <xsl:with-param name="wim" select="$new-wim * number($is-meeting) + $wim * number(not($is-meeting))"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- ######################## -->
<!-- The Effective Schedule -->
<!-- ######################## -->

<!-- The schedule lives in "docinfo" because relative positions are    -->
<!-- course design and survive the term.  The publication file holds   -->
<!-- per-offering facts and may override individual entries by @id.    -->
<!--                                                                   -->
<!-- Flattening both sources into one node-set here means the          -->
<!-- resolution recursions below walk a single ordered list and never  -->
<!-- re-apply the override rule.  Document order within a result tree  -->
<!-- fragment is exactly the order of emission, which a union of two   -->
<!-- separate documents would not guarantee.                           -->
<xsl:variable name="calendar-schedule" select="$version-docinfo/calendar"/>

<xsl:variable name="calendar-effective-rtf">
    <xsl:for-each select="$calendar-schedule/event">
        <xsl:variable name="id" select="string(@id)"/>
        <xsl:variable name="override" select="$calendar-pub/event[@id = $id]"/>
        <pi:event id="{$id}">
            <xsl:attribute name="at">
                <xsl:choose>
                    <xsl:when test="$override"><xsl:value-of select="$override/@at"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="@at"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </pi:event>
    </xsl:for-each>
    <xsl:for-each select="$calendar-pub/event">
        <xsl:variable name="id" select="string(@id)"/>
        <xsl:if test="not($calendar-schedule/event[@id = $id])">
            <pi:event id="{$id}" at="{@at}"/>
        </xsl:if>
    </xsl:for-each>

    <xsl:for-each select="$calendar-schedule/release">
        <xsl:variable name="id" select="string(@id)"/>
        <xsl:variable name="override" select="$calendar-pub/release[@id = $id]"/>
        <xsl:variable name="rule" select="$override | self::*[not($override)]"/>
        <pi:release id="{$id}">
            <xsl:if test="$rule/@from">
                <xsl:attribute name="from"><xsl:value-of select="$rule/@from"/></xsl:attribute>
            </xsl:if>
            <xsl:if test="$rule/@through">
                <xsl:attribute name="through"><xsl:value-of select="$rule/@through"/></xsl:attribute>
            </xsl:if>
        </pi:release>
    </xsl:for-each>
    <xsl:for-each select="$calendar-pub/release">
        <xsl:variable name="id" select="string(@id)"/>
        <xsl:if test="not($calendar-schedule/release[@id = $id])">
            <pi:release id="{$id}">
                <xsl:copy-of select="@from|@through"/>
            </pi:release>
        </xsl:if>
    </xsl:for-each>
</xsl:variable>

<xsl:variable name="calendar-effective" select="exsl:node-set($calendar-effective-rtf)"/>

<!-- ###### -->
<!-- Events -->
<!-- ###### -->

<!-- Stage 2: named events, resolved in document order.  An event may  -->
<!-- reference only events defined before it, which keeps this a       -->
<!-- single forward pass with no dependency graph to sort, and matches -->
<!-- how a schedule is written top to bottom.                          -->
<!--                                                                   -->
<!-- The accumulator is a fenced string, "|id=date|id=date|", rather   -->
<!-- than a node-set, because XSLT 1.0 cannot query a result tree      -->
<!-- fragment that is still being built.                               -->
<xsl:variable name="calendar-events-rtf">
    <xsl:if test="$b-calendar">
        <xsl:call-template name="calendar-resolve-events"/>
    </xsl:if>
</xsl:variable>

<xsl:variable name="calendar-events" select="exsl:node-set($calendar-events-rtf)/pi:event"/>

<xsl:template name="calendar-resolve-events">
    <xsl:param name="index" select="1"/>
    <xsl:param name="acc" select="'|'"/>

    <xsl:variable name="event" select="$calendar-effective/pi:event[position() = $index]"/>
    <xsl:if test="$event">
        <xsl:variable name="resolved">
            <xsl:call-template name="calendar-resolve">
                <xsl:with-param name="ref" select="$event/@at"/>
                <xsl:with-param name="events" select="$acc"/>
                <xsl:with-param name="context" select="concat('event &quot;', $event/@id, '&quot;')"/>
            </xsl:call-template>
        </xsl:variable>
        <pi:event id="{$event/@id}" at="{$event/@at}" date="{$resolved}"/>
        <xsl:call-template name="calendar-resolve-events">
            <xsl:with-param name="index" select="$index + 1"/>
            <xsl:with-param name="acc" select="concat($acc, $event/@id, '=', $resolved, '|')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- The complete event index, for every consumer after stage 2. -->
<xsl:variable name="calendar-event-index">
    <xsl:text>|</xsl:text>
    <xsl:for-each select="$calendar-events">
        <xsl:value-of select="concat(@id, '=', @date, '|')"/>
    </xsl:for-each>
</xsl:variable>

<!-- ##################### -->
<!-- Reference Date, as-of -->
<!-- ##################### -->

<!-- Stage 3a.  The CLI wins over the publication file, which wins  -->
<!-- over the default of "today".                                   -->
<xsl:variable name="calendar-as-of-raw">
    <xsl:choose>
        <xsl:when test="not($as-of = '')">
            <xsl:value-of select="$as-of"/>
        </xsl:when>
        <xsl:when test="$calendar-pub/@as-of">
            <xsl:value-of select="$calendar-pub/@as-of"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>today</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:variable>

<xsl:variable name="calendar-as-of">
    <xsl:if test="$b-calendar">
        <xsl:call-template name="calendar-resolve">
            <xsl:with-param name="ref" select="$calendar-as-of-raw"/>
            <xsl:with-param name="context" select="'the reference date (as-of)'"/>
        </xsl:call-template>
    </xsl:if>
</xsl:variable>

<xsl:variable name="calendar-as-of-num" select="number(translate(string($calendar-as-of), '-', ''))"/>

<!-- ######## -->
<!-- Releases -->
<!-- ######## -->

<!-- Stage 3b.  Ranges are inclusive at both ends, because the        -->
<!-- granularity is a whole day.  If a time of day is ever added      -->
<!-- these become "start of the @from day" and "end of the @through   -->
<!-- day", which keeps existing documents correct.                    -->
<xsl:variable name="calendar-releases-rtf">
    <xsl:if test="$b-calendar">
        <xsl:for-each select="$calendar-effective/pi:release">
            <xsl:variable name="from">
                <xsl:if test="@from">
                    <xsl:call-template name="calendar-resolve">
                        <xsl:with-param name="ref" select="@from"/>
                        <xsl:with-param name="context" select="concat('release &quot;', @id, '&quot; @from')"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="through">
                <xsl:if test="@through">
                    <xsl:call-template name="calendar-resolve">
                        <xsl:with-param name="ref" select="@through"/>
                        <xsl:with-param name="context" select="concat('release &quot;', @id, '&quot; @through')"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="started" select="($from = '') or (number(translate($from, '-', '')) &lt;= $calendar-as-of-num)"/>
            <xsl:variable name="ended" select="not($through = '') and (number(translate($through, '-', '')) &lt; $calendar-as-of-num)"/>
            <pi:release id="{@id}" from="{$from}" through="{$through}">
                <xsl:attribute name="released">
                    <xsl:choose>
                        <xsl:when test="$started and not($ended)">yes</xsl:when>
                        <xsl:otherwise>no</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </pi:release>
        </xsl:for-each>
    </xsl:if>
</xsl:variable>

<xsl:variable name="calendar-releases" select="exsl:node-set($calendar-releases-rtf)/pi:release"/>

<!-- ####################### -->
<!-- Reference Resolution -->
<!-- ####################### -->

<!-- Turn a single date reference into an ISO 8601 date.  A reference  -->
<!-- is one whitespace-free token, so it is legal anywhere an          -->
<!-- attribute value is.  "." separates fields, which leaves "-" free  -->
<!-- as the offset operator: "week3.fri-1w" is unambiguous where       -->
<!-- "week3-fri-1w" would not be.                                      -->
<xsl:template name="calendar-resolve">
    <xsl:param name="ref"/>
    <xsl:param name="events" select="$calendar-event-index"/>
    <xsl:param name="context" select="'a date reference'"/>

    <xsl:variable name="r" select="normalize-space($ref)"/>
    <xsl:variable name="len" select="string-length($r)"/>
    <xsl:variable name="unit" select="substring($r, $len)"/>

    <!-- An offset suffix is exactly [+-]<digits>[dw].  Testing for a  -->
    <!-- trailing "d" or "w" alone is not enough: "week3.wed" ends in  -->
    <!-- "d" and "w6.w" ends in "w".  Requiring at least one digit     -->
    <!-- before the unit, and a sign before those, separates them.     -->
    <xsl:variable name="digits">
        <xsl:choose>
            <xsl:when test="($unit = 'd') or ($unit = 'w')">
                <xsl:call-template name="calendar-trailing-digits">
                    <xsl:with-param name="s" select="substring($r, 1, $len - 1)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="nd" select="number($digits)"/>
    <xsl:variable name="sign" select="substring($r, $len - $nd - 1, 1)"/>
    <xsl:variable name="has-offset" select="($nd &gt; 0) and (($sign = '+') or ($sign = '-'))"/>

    <xsl:variable name="base">
        <xsl:choose>
            <xsl:when test="$has-offset">
                <xsl:value-of select="substring($r, 1, $len - $nd - 2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$r"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="base-date">
        <xsl:call-template name="calendar-resolve-base">
            <xsl:with-param name="base" select="$base"/>
            <xsl:with-param name="events" select="$events"/>
            <xsl:with-param name="context" select="$context"/>
        </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="$base-date = ''"/>
        <xsl:when test="$has-offset">
            <!-- libxslt's date:add silently returns empty for the week -->
            <!-- designator (P1W), so "1w" normalizes to 7 days here    -->
            <!-- rather than passing a week duration through.           -->
            <xsl:variable name="days" select="number(substring($r, $len - $nd, $nd)) * (1 + 6 * number($unit = 'w'))"/>
            <xsl:variable name="duration">
                <xsl:if test="$sign = '-'">-</xsl:if>
                <xsl:value-of select="concat('P', $days, 'D')"/>
            </xsl:variable>
            <xsl:value-of select="substring(date:add($base-date, string($duration)), 1, 10)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$base-date"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="calendar-resolve-base">
    <xsl:param name="base"/>
    <xsl:param name="events"/>
    <xsl:param name="context"/>

    <xsl:choose>
        <!-- literal ISO date, always accepted as an escape hatch -->
        <xsl:when test="(string-length($base) = 10) and (substring($base, 5, 1) = '-')
                        and (substring($base, 8, 1) = '-')
                        and not(string(number(translate($base, '-', ''))) = 'NaN')">
            <xsl:value-of select="$base"/>
        </xsl:when>
        <xsl:when test="$base = 'today'">
            <xsl:value-of select="$calendar-today"/>
        </xsl:when>
        <!-- weekN.<dayname> or weekN.dK -->
        <xsl:when test="contains($base, '.')">
            <xsl:variable name="head" select="substring-before($base, '.')"/>
            <xsl:variable name="tail" select="substring-after($base, '.')"/>
            <xsl:variable name="n">
                <xsl:choose>
                    <xsl:when test="starts-with($head, 'week')">
                        <xsl:value-of select="substring($head, 5)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($head, 'w')">
                        <xsl:value-of select="substring($head, 2)"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="string(number($n)) = 'NaN'">
                    <xsl:message>PTX:ERROR:   the date reference "<xsl:value-of select="$base"/>" (<xsl:value-of select="$context"/>) does not name a week.  Use "week6.wed", "w6.w", or "week6.d3".</xsl:message>
                </xsl:when>
                <!-- "dK": the Kth *meeting* inside week N's fixed 7-day  -->
                <!-- block, so it skips holidays.  No day letter is "d",  -->
                <!-- which is what makes this unambiguous.                -->
                <xsl:when test="starts-with($tail, 'd') and not(string(number(substring($tail, 2))) = 'NaN')">
                    <xsl:variable name="k" select="number(substring($tail, 2))"/>
                    <xsl:variable name="meeting" select="$calendar-meetings[@week = number($n)][@wim = $k]"/>
                    <xsl:choose>
                        <xsl:when test="$meeting">
                            <xsl:value-of select="$meeting/@date"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>PTX:ERROR:   the date reference "<xsl:value-of select="$base"/>" (<xsl:value-of select="$context"/>) asks for meeting <xsl:value-of select="$k"/> of week <xsl:value-of select="$n"/>, which holds only <xsl:value-of select="count($calendar-meetings[@week = number($n)])"/>.</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- "<dayname>": calendar-anchored.  Holidays never move -->
                <!-- this, which is "Rule A" in the roadmap.              -->
                <xsl:otherwise>
                    <xsl:variable name="dow">
                        <xsl:call-template name="calendar-dow-of-name">
                            <xsl:with-param name="name" select="$tail"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$dow = 0">
                            <xsl:message>PTX:ERROR:   the date reference "<xsl:value-of select="$base"/>" (<xsl:value-of select="$context"/>) does not name a day.  Use mon/tue/wed/thu/fri/sat/sun or m/t/w/r/f/s/u.</xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="shift" select="7 * (number($n) - 1) + ((number($dow) - number($calendar-week-starts-dow)) + 7) mod 7"/>
                            <xsl:value-of select="substring(date:add(string($calendar-week1-begin), concat('P', $shift, 'D')), 1, 10)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- classK: the Kth meeting of the term, so it skips holidays -->
        <xsl:when test="starts-with($base, 'class') and not(string(number(substring($base, 6))) = 'NaN')">
            <xsl:variable name="k" select="number(substring($base, 6))"/>
            <xsl:variable name="meeting" select="$calendar-meetings[@n = $k]"/>
            <xsl:choose>
                <xsl:when test="$meeting">
                    <xsl:value-of select="$meeting/@date"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the date reference "<xsl:value-of select="$base"/>" (<xsl:value-of select="$context"/>) asks for meeting <xsl:value-of select="$k"/>, but the term holds only <xsl:value-of select="count($calendar-meetings)"/>.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- a named event -->
        <xsl:otherwise>
            <xsl:variable name="hit" select="concat('|', $base, '=')"/>
            <xsl:choose>
                <xsl:when test="contains($events, $hit)">
                    <xsl:value-of select="substring-before(substring-after($events, $hit), '|')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>PTX:ERROR:   the date reference "<xsl:value-of select="$base"/>" (<xsl:value-of select="$context"/>) names no event.  Events are resolved in document order, so an event may only refer to one defined before it.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- ########### -->
<!-- Diagnostics -->
<!-- ########### -->

<!-- Called once, from the root of the "release" pass.  An instructor  -->
<!-- is about to publish solutions and needs to see what they are      -->
<!-- publishing, so the released/withheld split is reported rather     -->
<!-- than being something to infer from the output.                    -->
<xsl:template name="calendar-report">
    <xsl:variable name="marked" select="$version//*[@release-id]"/>

    <xsl:variable name="as-of-daynum" select="floor(date:seconds(string($calendar-as-of)) div 86400)"/>
    <xsl:variable name="week" select="floor(($as-of-daynum - $calendar-week1-daynum) div 7) + 1"/>
    <xsl:variable name="held" select="count($calendar-meetings[number(translate(@date, '-', '')) &lt;= $calendar-as-of-num])"/>

    <xsl:message>PTX:CALENDAR: as-of <xsl:value-of select="$calendar-as-of"/> (week <xsl:value-of select="$week"/>, <xsl:value-of select="$held"/> of <xsl:value-of select="count($calendar-meetings)"/> meetings held)</xsl:message>

    <xsl:if test="not($b-calendar-releases)">
        <xsl:message>PTX:CALENDAR: releases="ignore", so every @release-id element is retained</xsl:message>
    </xsl:if>

    <xsl:if test="$calendar-releases[@released = 'yes']">
        <xsl:message>PTX:CALENDAR: released: <xsl:for-each select="$calendar-releases[@released = 'yes']"><xsl:if test="position() &gt; 1">, </xsl:if><xsl:value-of select="@id"/></xsl:for-each></xsl:message>
    </xsl:if>

    <xsl:if test="$calendar-releases[@released = 'no']">
        <xsl:message>PTX:CALENDAR: withheld: <xsl:for-each select="$calendar-releases[@released = 'no']"><xsl:if test="position() &gt; 1">, </xsl:if><xsl:value-of select="@id"/><xsl:choose><xsl:when test="not(@from = '') and (number(translate(@from, '-', '')) &gt; $calendar-as-of-num)"> (until <xsl:value-of select="@from"/>)</xsl:when><xsl:when test="not(@through = '')"> (expired <xsl:value-of select="@through"/>)</xsl:when></xsl:choose></xsl:for-each></xsl:message>
    </xsl:if>

    <!-- An orphaned @release-id is a typo, and it fails closed, so it -->
    <!-- must be visible.  Named once per distinct id: "preceding" and -->
    <!-- "ancestor" together cover every element that could have       -->
    <!-- reported it already.                                          -->
    <xsl:for-each select="$marked">
        <xsl:variable name="rid" select="normalize-space(@release-id)"/>
        <xsl:if test="not($calendar-releases[@id = $rid])
                      and not((preceding::*|ancestor::*)[normalize-space(@release-id) = $rid])">
            <xsl:message>PTX:WARNING: release-id "<xsl:value-of select="$rid"/>" matches no "release" element in the calendar, so the content marked with it has been dropped.  Add a "release" to docinfo/calendar, or correct the spelling.</xsl:message>
        </xsl:if>
    </xsl:for-each>

    <!-- The converse is only a warning: shared source legitimately    -->
    <!-- carries schedule entries for material a given book omits.     -->
    <xsl:for-each select="$calendar-releases">
        <xsl:variable name="id" select="string(@id)"/>
        <xsl:if test="not($marked[normalize-space(@release-id) = $id])">
            <xsl:message>PTX:WARNING: the calendar has a "release" with id "<xsl:value-of select="$id"/>", but no element in the source carries @release-id="<xsl:value-of select="$id"/>".</xsl:message>
        </xsl:if>
    </xsl:for-each>

    <!-- A named event landing on a holiday is usually a mistake in    -->
    <!-- the schedule, but it resolves successfully, so it warns.      -->
    <xsl:for-each select="$calendar-events">
        <xsl:variable name="isonum" select="number(translate(@date, '-', ''))"/>
        <xsl:variable name="holiday" select="$calendar-pub/holiday[
                 number(translate(@on, '-', '')) = $isonum
              or (number(translate(@from, '-', '')) &lt;= $isonum
                  and number(translate(@through, '-', '')) &gt;= $isonum)]"/>
        <xsl:if test="$holiday">
            <xsl:message>PTX:WARNING: event "<xsl:value-of select="@id"/>" (<xsl:value-of select="@at"/>) resolves to <xsl:value-of select="@date"/>, which the calendar marks as a holiday<xsl:if test="$holiday/@name">, <xsl:value-of select="$holiday/@name"/></xsl:if>.</xsl:message>
        </xsl:if>
    </xsl:for-each>
</xsl:template>

<!-- #################### -->
<!-- Small Pure Helpers -->
<!-- #################### -->

<!-- Count digits at the right-hand end of a string.  There is no      -->
<!-- regex and no tokenize() in XSLT 1.0, so this is a recursion.      -->
<!-- NB: contains($any, '') is true, hence the explicit length guard.  -->
<xsl:template name="calendar-trailing-digits">
    <xsl:param name="s"/>
    <xsl:param name="count" select="0"/>
    <xsl:choose>
        <xsl:when test="(string-length($s) = 0) or not(contains('0123456789', substring($s, string-length($s))))">
            <xsl:value-of select="$count"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="calendar-trailing-digits">
                <xsl:with-param name="s" select="substring($s, 1, string-length($s) - 1)"/>
                <xsl:with-param name="count" select="$count + 1"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Day name to EXSLT's day-in-week numbering, 1-based from Sunday.   -->
<!-- Both the three-letter form (canonical in documentation) and the   -->
<!-- one-letter form (how instructors actually write schedules)        -->
<!-- resolve identically.  Note "r" is Thursday, not "t".  Returns 0   -->
<!-- for an unrecognized name.                                        -->
<xsl:template name="calendar-dow-of-name">
    <xsl:param name="name"/>
    <xsl:variable name="d" select="translate(normalize-space($name), 'MONTUEWDHRFISA', 'montuewdhrfisa')"/>
    <xsl:choose>
        <xsl:when test="($d = 'sun') or ($d = 'u')">1</xsl:when>
        <xsl:when test="($d = 'mon') or ($d = 'm')">2</xsl:when>
        <xsl:when test="($d = 'tue') or ($d = 't')">3</xsl:when>
        <xsl:when test="($d = 'wed') or ($d = 'w')">4</xsl:when>
        <xsl:when test="($d = 'thu') or ($d = 'r')">5</xsl:when>
        <xsl:when test="($d = 'fri') or ($d = 'f')">6</xsl:when>
        <xsl:when test="($d = 'sat') or ($d = 's')">7</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
