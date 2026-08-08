# Course Calendar: Date Authoring and Date-Driven Components

Status: design draft, decisions settled, nothing implemented.

## Problem

An instructor authors course materials in PreTeXt and reuses them every term.
The source refers to calendar dates ("Exam 1 is Monday, October 6") and gates
material on dates (solutions appear only after the assignment is due). No real
date may appear in the source, because the source outlives the term. Ideally the
publication file is the only thing that changes from term to term.

## Settled decisions

1. **Rule A for holidays.** Weeks are fixed 7-day blocks; holidays never move a
   week-and-weekday reference. Meeting-ordinal references skip holidays and
   slide. Details under "Resolution rules".
2. **The schedule lives in `docinfo`.** Relative positions are course design and
   survive the term. The publication file holds only per-offering facts and may
   override individual entries.
3. **Release timing is a mapping, not attribute syntax.** `@release-id` stays an
   opaque name; `<release>` rules carry the dates. Retiming a release is a
   publication-file or `docinfo` edit and never a source-body edit.
4. **Release gating is a separate attribute from versioning.** `@component`
   answers "which edition is this in?"; `@release-id` answers "is it visible
   yet?". They are different questions, so they get different attributes and
   compose by intersection. The version machinery — `$components-fenced`,
   the template at `pretext-assembly.xsl:803` — is not touched at all.

## Layering

| Layer | Contents | Lives in | Changes per term |
|---|---|---|---|
| **Calendar** | anchor date, meeting pattern, holidays | publication file | yes |
| **Schedule** | named events at *relative* positions, release rules | `docinfo` | no |
| **References** | `<date at="exam1"/>`, `@release-id` markings | source body | no |

There is precedent for this split. The `external` directory setting was recently
moved *out* of the publication file into `docinfo` on the grounds that it is "a
fact of the source" (see the deprecation note in `publication-schema.rnc`
around the `Directories` pattern). A relative schedule is likewise a fact of the
source; a start date is a fact of the offering.

## Calendar (publication file)

```xml
<publication>
  <calendar start="2026-08-24" end="2026-12-11" meets="MWF"
            week-starts="mon" as-of="today" releases="honor">
    <holiday on="2026-09-07" name="Labor Day"/>
    <holiday from="2026-11-25" through="2026-11-27" name="Thanksgiving"/>
    <!-- optional per-offering overrides of docinfo entries -->
    <event id="exam1" at="week7.wed"/>
  </calendar>
</publication>
```

- `@start` — first day of instruction, ISO 8601. Required. Absent `<calendar>`
  entirely, every behavior below is inert and nothing changes for existing
  documents.
- `@end` — last day of instruction. Optional; bounds the meeting enumeration.
  Absent, the enumeration is capped (30 weeks) and `classK` beyond the cap is an
  error.
- `@meets` — meeting pattern over `MTWRFSU`, with `R` = Thursday and `U` =
  Sunday, the convention instructors already use in registrar systems. Optional;
  absent means `MTWRF`.
- `@week-starts` — weekday that begins a numbered week. Default `mon`.
- `@as-of` — the reference "now" for the entire build. Default `today`. Accepts
  `today`, an ISO date, or any symbolic reference. Overridden by the CLI.
- `@releases` — `honor` (default) or `ignore`. `ignore` retains every
  `@release-id` element regardless of its window, which is how an instructor
  builds a full private copy without editing the schedule. Dates still resolve,
  so `<date>` output is unaffected.

## Schedule (docinfo)

```xml
<docinfo>
  <calendar>
    <event id="hw3-due" at="week3.fri"/>
    <event id="exam1"   at="week6.wed"/>
    <release id="hw3-solutions" from="hw3-due+2d"/>
    <release id="exam1-review"  from="week5.mon" through="exam1"/>
  </calendar>
</docinfo>
```

Never edited between terms. A `<calendar>` child in the publication file with a
matching `@id` replaces the corresponding `docinfo` entry.

Events use a plain `@id`, not `@xml:id`. PreTeXt's `xml:id` space belongs to
cross-reference targets — it is uniqueness-checked and turned into HTML anchors —
and a calendar event is neither. `<date at="...">` is a lookup into the schedule,
not an `<xref>`.

Events are resolved in document order and may reference only events defined
before them. That keeps resolution a single forward pass with no dependency
graph, and it matches how a schedule is written top to bottom.

## Date reference syntax

A *date reference* is a single token with no whitespace, so it is legal inside
the space-separated `version/@include` list and inside `@component`.

| Form | Meaning |
|---|---|
| `2026-10-06` | literal ISO date; always accepted as an escape hatch |
| `week6.wed` | Wednesday of week 6 — calendar-anchored |
| `w6.w` | same, abbreviated; day letters `m t w r f s u` |
| `week6.d3` | third *meeting* of week 6 — sequence-anchored within a fixed week |
| `class17` | seventeenth meeting of the term — sequence-anchored |
| `exam1` | a named `<event>` |
| `today` | the calendar's `as-of` date |
| `exam1+2d`, `week3.fri-1w` | calendar-day offset from any of the above |

`.` separates fields rather than `-`, leaving `-` free as the offset operator.
`week3.fri-1w` is unambiguous; `week3-fri-1w` is not.

The three-letter day form is canonical in documentation. The one-letter form
exists because it is how instructors actually write schedules, and both resolve
identically.

## Resolution rules

Let `dow(d)` be `date:day-in-week`, which libxslt numbers from Sunday = 1.

**Week boundaries.** Week 1 begins on the latest `@week-starts` day on or before
`@start`:

```
w1-begin = start - ((dow(start) - dow(week-starts)) mod 7) days
weekN    begins at  w1-begin + 7*(N-1) days
```

A term beginning on a Wednesday therefore has a short week 1, which is what
instructors mean by "the first week."

**`weekN.<dayname>` — calendar-anchored, Rule A.**

```
weekN.<day> = w1-begin + 7*(N-1) + ((dow(day) - dow(week-starts)) mod 7) days
```

Holidays never move this. If the result lands on a holiday, or on a day outside
`@meets`, resolution still succeeds and a warning is issued.

**Meeting sequence — sequence-anchored, Rule A.** The ordered list of dates from
`@start` through `@end` whose weekday is in `@meets` and which no `<holiday>`
covers.

- `classK` is the Kth entry of that list. A holiday earlier in the term shifts
  it one meeting later on the calendar.
- `weekN.dK` is the Kth entry of that list falling inside week N's fixed 7-day
  block. A holiday on the Monday of week 3 makes `week3.d1` resolve to
  Wednesday, while `week3.mon` still resolves to the holiday Monday.

If week N holds fewer than K meetings, or the term holds fewer than K meetings,
that is an error, not a warning — the reference cannot be given a value.

**Offsets** are calendar days, applied after resolution. `1w` normalizes to 7
days. Offsets do not skip holidays or non-meeting days; a meeting-relative
offset would be a separate operator and is deferred.

**Ranges** are inclusive at both ends (`from`/`through`) throughout, because the
granularity is a whole day. If time-of-day is added later these become "start of
the `from` day" and "end of the `through` day", which keeps existing documents
correct.

## Date output in source

```xml
<p>Exam 1 will be on <date at="exam1"/>.</p>
<p>Unit 2 runs <daterange from="week3.mon" through="week5.fri"/>.</p>
```

`<date>` already has two unrelated definitions in `pretext.rnc` — one in
frontmatter (`Date`, near line 273) and one for CSL bibliography entries (near
line 1399). RELAX NG allows a third contextual definition, and the file already
carries two, so the reuse is legal. Fallback name if the overload proves
confusing in practice: `<coursedate>`.

`@format` extends the vocabulary `<today>` established at
`pretext-common.xsl:2057` (`month-day-year`, `yyyy/mm/dd`) with
`weekday-month-day` for "Monday, October 6", which is the form the user story
asks for.

## Date-released content

Release gating is its own attribute, `@release-id`, and its own assembly pass.
The version machinery is untouched.

```xml
<solution release-id="hw3-solutions">…</solution>
```

Why not reuse `@component`. The two mechanisms answer different questions —
"which edition is this in?" versus "is it visible yet?" — and an element may
need both answers. Folding releases into `$components-fenced` forces a choice
between union and intersection semantics, and union is the only one that makes
the feature work: with `<version include="instructor-notes"/>` elected, a
release-managed component not named in `@include` would be dropped by the
version pass before any date was ever consulted. Union in turn means calendar
resolution has to run *before* the version pass, which drags in the whole
acyclicity problem described below. A separate attribute makes the composition
intersection — the natural reading — and dissolves all of it.

Semantics, in the order the pass tests them:

| Condition | Result |
|---|---|
| No `<calendar>` in the publication file | retained (feature inert) |
| `calendar/@releases='ignore'` | retained |
| `@release-id` matches no `<release>` | **dropped**, with a warning naming the id |
| matching `<release>` window contains `as-of` | retained |
| otherwise | dropped, silently — this is the normal case |

The orphan rule is deliberately fail-closed. The failure mode of this feature is
publishing an answer key early, so a typo must not default to "visible". The
warning is emitted once per distinct id, not once per element.

Because `<release>` takes both `@from` and `@through`, content can appear on a
date, disappear on a date, or both — exam material live only during the exam
window.

## Implementation

### Pass placement

The release pass runs **immediately after** the `version` pass, so calendar
resolution may read `$version-docinfo` — the single, already-resolved `docinfo`.
The multiple-`docinfo` problem that versions exist to solve
(`pretext-assembly.xsl:790`) is therefore already solved by the time the
calendar is read, and a `<calendar>` inside a component-gated `<docinfo>` is
perfectly legal. Two sections with different meeting patterns, selected by
`version/@include`, fall out for free.

This works only because nothing the calendar produces feeds the version pass.
That is the whole reason `@release-id` is a separate attribute: `$components-fenced`
(`publisher-variables.xsl:1501`) never learns that calendars exist, so the
constraint documented at `pretext-assembly.xsl:527-534` and
`publisher-variables.xsl:110-121` — passes up to and including `version` must
never consult a variable derived from the version tree — is not even approached.

**Divisions may be release-gated, and the structural contract survives it.**
Gating a whole section — an exam review that appears the week before the exam —
is a first-class use case, so `@release-id` is permitted exactly where
`@component` is, minus `docinfo`.

That deserves justification, because the contract at
`publisher-variables.xsl:2747-2753` says no assembly pass alters the book/article
type or the part/chapter/section hierarchy, and `$chunk-level-default` and
`$toc-level` depend on it. Two facts make the risk negligible.

First, every consumer of the version tree's structure is either `$version-doc-type`
— the name of the document element, which no realistic gating removes — or one of
six **booleans** at `publisher-variables.xsl:130-135` asking whether the document
has *any* parts, chapters, sections, subsections, or printouts. Nothing counts
divisions or reads a particular one. Gating one section of twelve changes nothing;
drift is observable only when the gated division is the *only* one of its kind.

Second, in that degenerate case the pre-release answer is arguably the better one.
Chunk level and toc level stay pinned to the full edition, so a document's
chunking and its URLs do not reshuffle mid-term as content releases. Stability
across the term is what a reader wants.

Note also that this is not a new exposure. Divisions already accept `@component`
— `chapter` and `section` open with `MetaDataLinedTitle`, which carries
`Component?` — so division-level gating, with all its consequences for numbering
and cross-references, is something PreTeXt already permits. The release pass
differs only in running after `$version-root` is fixed, and the paragraphs above
bound what that costs.

`docinfo` is the one exclusion: gating it would delete the calendar that drives
the gating.

The pass mirrors the elision idiom at `pretext-assembly.xsl:505-510`: with no
calendar the result tree fragment stays empty and `$version` is handed straight
to the next pass, so a document without a calendar pays nothing.

```xml
<xsl:variable name="release-rtf">
    <xsl:if test="$b-calendar">
        <xsl:apply-templates select="$version" mode="release"/>
    </xsl:if>
</xsl:variable>
<xsl:variable name="release" select="exsl:node-set($release-rtf)[$b-calendar] | $version[not($b-calendar)]"/>
```

### The resolved calendar

Resolution builds one internal node-set that every consumer — the release pass,
`<date>`, `<daterange>`, diagnostics — reads instead of re-parsing.

```xml
<pi:calendar as-of="2026-10-06" start="2026-08-24" meets="MWF" week1-begin="2026-08-24">
  <pi:meeting n="17" week="7" wim="2" date="2026-10-07"/>
  <pi:event   id="exam1"         date="2026-10-07"/>
  <pi:release id="hw3-solutions" from="2026-09-13" released="yes"/>
</pi:calendar>
```

It is built in three stages, each depending only on the ones before it, which is
what keeps a single forward pass sufficient:

1. **meetings** — depends only on `$publication/calendar`; enumerates the term
2. **events** — depends on meetings; resolved in document order
3. **as-of, then releases** — depend on meetings and events

The `pi:` namespace is already established for internal, non-author elements and
is stripped during the version pass (`pretext-assembly.xsl:836`), so this tree
never reaches output.

### Parsing in XSLT 1.0

Tokenizing `week6.wed+2d` needs recursive `substring-before`/`substring-after`
templates; there is no regex and no `tokenize()`. Confining this to the single
resolution pass is the entire reason for the node-set above. Structure it as:

1. split the offset on the last `+` or `-`, normalizing `Nw` to `7N` days
2. split the base on `.`
3. dispatch on the base head: `weekN`, `classN`, ISO literal, `today`, or an
   event name

Meeting enumeration is a recursive template walking one day at a time from
`@start`, carrying an accumulator, testing `@meets` membership and holiday
coverage. Bounded by `@end` or the 30-week cap so a malformed calendar cannot
spin.

### EXSLT constraints, confirmed by probing libxslt

Both `xsltproc` and the CLI's lxml path use libxslt, so these apply everywhere.

- EXSLT dates-and-times is available and already in use
  (`pretext-common.xsl:2064`, `:10929`). `date:add`, `date:difference`,
  `date:seconds`, `date:day-in-week`, `date:day-name`, `date:month-name`,
  `date:day-in-month`, `date:year` all work.
- **`date:add($d, 'P1W')` returns empty.** libxslt does not implement the week
  designator. All arithmetic must be in days:
  `date:add($d, concat('P', $n, 'D'))`, which does work. This is why `1w`
  offsets normalize to `P7D` during parsing rather than passing through.
- `date:day-in-week` is 1-based from **Sunday**, so Monday is 2. The `mod 7`
  expressions above assume this.
- Negative day counts in `date:add` are expressed as `concat('-P', $n, 'D')`.

### Schema changes

`pretext.rnc` — `docinfo` uses an extensible pattern, so the schedule is
additive:

```
Configuration |=
    element calendar {
        (element event   { attribute id {text},
                           attribute at {text} } |
         element release { attribute id {text},
                           attribute from {text}?,
                           attribute through {text}? })+
    }

ReleaseId = attribute release-id {text}
```

`ReleaseId?` sits alongside every `Component?` occurrence except the one in
`DocInfo` — 39 sites to `@component`'s 40. Divisions are included deliberately;
see "Pass placement".

`publication-schema.rnc` — a new `Calendar` pattern alongside `Source`. The
existing `Version` pattern is **not** touched; there is no `@include-released`.

### Diagnostics

Worth building alongside the feature rather than after, because an instructor is
about to publish solutions and needs to see what they are publishing. An
`xsl:message` report under the existing diagnostic conventions:

```
PTX:CALENDAR: as-of 2026-10-06 (week 7, meeting 19)
PTX:CALENDAR: released: hw1-solutions, hw2-solutions, hw3-solutions
PTX:CALENDAR: withheld: hw4-solutions (until 2026-10-16), exam2-key (until 2026-11-11)
```

Warnings for a reference landing on a holiday or a non-meeting day, and for a
`@release-id` matching no `<release>` rule (once per distinct id). Errors for a
meeting ordinal past the end of its window, an unresolvable event name, and a
`<calendar>` present without `@start`. A `<release>` whose id appears nowhere in
the source is a warning, not an error — shared source legitimately carries
schedule entries for material a given book does not include.

### Localization

`date:month-name` and `date:day-name` are English-only, and the 18 files in
`xsl/localizations/` contain no month or day names — they are flat
`<localization string-id='...'>` entries, 211 of them in `en-US.xml`. Nineteen
new ids (12 months, 7 days) across 18 files, with `date:month-name` as the
fallback when an id is missing, per the file's stated rule that untranslated
strings stay commented out.

`<today>` has this bug already and quietly; a calendar feature makes it visible
on every page. Fixing it fixes `<today>` too.

### CLI

`pretext build --as-of <ref>`, accepting `today`, an ISO date, or a symbolic
reference, overriding `calendar/@as-of`. Passed as a stringparam through
`common.xsltproc` (`pretext/core/common.py:198`).

This is a prerequisite, not a nicety. An instructor must be able to preview the
week-5 build during week 2, and the test suite needs a fixed reference date or
every assertion rots overnight.

Consider also surfacing the diagnostic report as `pretext calendar`, listing
resolved events and release states for a given `--as-of`. Cheap once the node-set
exists, and it is the natural "what will my students see" command.

### Testing

A test project under `tests/examples/projects/` with a fixed `@start`, a holiday
positioned to exercise the Rule A split, and components on both sides of a
release boundary. Assertions run at several `--as-of` values, including exactly
on a boundary date, to pin the inclusive-endpoint semantics. Because `--as-of`
is explicit, these tests are deterministic.

Specific cases worth pinning: `week3.mon` and `week3.d1` diverging around the
holiday; `classK` shifting by exactly one meeting; a short first week when the
term starts mid-week; a document with `@release-id` but no calendar proving the
feature is inert; and an orphaned `@release-id` proving it fails closed.

## Phasing

1. **Resolution core.** `<calendar>` in the publication file, the `pi:calendar`
   node-set, reference parsing, Rule A, the diagnostic report. No output, no
   deletions — testable entirely through the report.
2. **Date-released content.** The `release` pass, `@release-id`,
   `docinfo/calendar`, `<release>`. Can follow immediately, because it no longer
   rests on date output or localization and does not touch `$components-fenced`.
3. **Date output.** `<date>`, `<daterange>`, `@format`, schema changes.
   Independent of everything above except resolution.
4. **Localization.** Month and day names across the 18 files; `<today>` fixed as
   a side effect.

## Open questions

1. Should a reference to a non-class day (`week3.tue` in an MWF course) warn, or
   is that too noisy for a course that holds review sessions off-pattern?
2. Is a generated schedule table — a `<schedule>` block rendering the whole term
   — in scope, or a later feature? It is the obvious next request.
3. Does `as-of` need a time of day? "Solutions at 5pm Friday" is a real request,
   but timezone handling in libxslt is thin, and the inclusive-endpoint choice
   above is designed to survive adding it later.
4. Should there be a meeting-relative offset operator (`exam1+2c` for "two class
   meetings after") in addition to calendar-day offsets?

Settled since the first draft: releases are inert without a publication-file
calendar, but an orphaned `@release-id` *with* a calendar is dropped and warned
about. See the table under "Date-released content".

---

## Summary for the developer forum

**Subject: Proposal — course calendars, symbolic dates, and date-released components**

I would like to add calendar support to PreTeXt, aimed at instructors who reuse
course materials every term.

The motivating story: a professor writes "Exam 1 is Monday, October 6" and wants
solutions to appear only after each assignment is due. They teach the course
every semester, so no real date can appear in the source. Changing the term
should mean changing one date in the publication file.

The proposal has three layers, deliberately in three places. The **calendar**
goes in the publication file and holds the per-offering facts — start date,
meeting pattern, holidays. The **schedule** goes in `docinfo` and holds named
events at *relative* positions plus release rules; it is course design and never
changes between terms. The **source body** refers to events by name and marks
release-gated material with `@release-id`.

```xml
<!-- publication file: the per-term edit -->
<calendar start="2026-08-24" meets="MWF" as-of="today"/>

<!-- docinfo: stable across terms -->
<calendar>
  <event id="hw3-due" at="week3.fri"/>
  <release id="hw3-solutions" from="hw3-due+2d"/>
</calendar>

<!-- source -->
<p>Exam 1 will be on <date at="exam1"/>.</p>
<solution release-id="hw3-solutions">…</solution>
```

Dates are written symbolically: `week6.wed` or `w6.w` for a weekday in a
numbered week, `week6.d3` for the third meeting of week 6, `class17` for the
seventeenth meeting of the term, a named event, or a literal ISO date. Offsets
like `hw3-due+2d` work on any of these. `.` separates fields so that `-` stays
available for offsets.

Holidays follow one rule, which I would especially like reactions to.
Week-and-weekday references are calendar-anchored: `week5.wed` is the same date
whether or not a holiday fell in week 3. Meeting-ordinal references are
sequence-anchored: `class17` and `week3.d1` skip holidays and slide. The
reasoning is that "Exam 2 is week 9 Wednesday" and "we cover 3.4 on class 12"
are different kinds of claim and instructors make both. The alternative — a lost
meeting renumbering the whole term — makes every date in the document unstable,
which seemed worse.

Release gating is a **new attribute**, `@release-id`, rather than an extension of
`@component`. My first draft reused `@component` and folded release state into
`$components-fenced`, and it does not work cleanly: `@component` answers "which
edition is this in?" while a release answers "is it visible yet?", and an element
may need both answers. Two independent filters compose by intersection, which
would mean `<version include="instructor-notes"/>` silently kills every
release-managed component before a date is ever consulted. Forcing union instead
drags calendar resolution in front of the `version` pass and into a circularity
problem. A separate attribute makes the composition intersection — the natural
reading — and leaves the version machinery completely untouched.

I considered putting release timing directly in the attribute
(`component="after(week2)"`) and decided against it: that puts policy in the
source, so releasing solutions early for one section becomes a source edit,
which defeats the whole point.

Three implementation notes for anyone who wants to poke holes:

- Because nothing the calendar produces feeds the `version` pass, release
  resolution can run immediately *after* it and read the single, already-resolved
  `docinfo`. `<calendar>` can therefore itself be component-gated, so two
  sections with different meeting patterns come for free.
- `@release-id` goes everywhere `@component` goes except `docinfo`, divisions
  included, so a whole section can be held back until the week before the exam.
  That does mean a pass after `$version-root` can change gross structure, but
  every consumer of that structure is a *boolean* — "does this document have any
  sections at all" — so the answer only shifts when the gated division is the
  only one of its kind, and pinning chunk level to the full edition is the
  friendlier answer there anyway.
- libxslt's `date:add` silently returns empty for week durations (`P1W`), so all
  arithmetic has to be in days. Everything else we need from EXSLT works.
- EXSLT month and day names are English-only and our localization files have
  none, so localized date output means adding about 19 string ids across 18
  files. `<today>` has this bug today; this would fix it.

A `pretext build --as-of week5.fri` flag is part of the proposal rather than an
extra — instructors need to preview a future build, and tests need a fixed date.

Questions I would most like feedback on: is the holiday rule right in practice?
Is splitting calendar and schedule across two files worth the reuse it buys, or
should everything sit in the publication file? And is a generated schedule table
something to design for now rather than bolt on later?
