<!--********************************************************************
Copyright (C) 2026  Robert A. Beezer

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
*****************************************************************-->

# `examples/calendar` — a course with a calendar

`main.ptx` is a small, fictional set of course notes whose purpose is to
exercise the course calendar: symbolic date references in the text, and content
gated on a date with `@release-id`. It is meant to be read as well as built —
the prose explains what each construction does and why, so the document is its
own documentation.

There is not one real date in `main.ptx`. Every date in the output is computed
from `@start` in a publication file, which is the single per-term edit the
feature exists to make possible.

The design this implements is described in `doc/course-calendar-roadmap.md`.

## Layout

| File | What it holds |
|---|---|
| `main.ptx` | the source: a `docinfo/calendar` schedule, and a body full of `date`, `daterange`, and `@release-id` |
| `publication.xml` | the student build, mid-term (`as-of="week8.wed"`) |
| `publication-early.xml` | the same term seen from week 1 (`as-of="week1.wed"`) |
| `publication-instructor.xml` | mid-term with `releases="ignore"`: a full private copy |
| `publication-wednesday.xml` | a term that begins mid-week, for the short-first-week case |
| `project.ptx` | one target per publication file, so the four builds can be diffed |

The four publication files differ only in the `calendar` element. That is the
point of the layering: the schedule in `docinfo` is course design and never
changes, so a different offering — or a preview of a future week — is a
publication-file edit and nothing else.

## Building

```
pretext build web            # student, mid-term
pretext build web-early      # student, week 1
pretext build web-instructor # everything retained
pretext build web-wednesday  # term begins on a Wednesday
pretext build print          # PDF, mid-term
```

The calendar is newer than the core commit the released CLI pins, so until that
pin moves, building this example needs the CLI pointed at a clone of this
repository — `python -m scripts.symlink_core /path/to/pretext` from a
`pretext-cli` checkout. `xsltproc` against `xsl/pretext-html.xsl` in this
repository works directly.

Every build prints a `PTX:CALENDAR` report naming the reference date, the week,
the number of meetings held, and the released and withheld rules by name. Read
it; it is the fastest check that a build is the one you meant to make.

`@as-of` is set explicitly in all four publication files, so these builds are
reproducible and the tables below do not rot overnight. Set it to `today` (or
delete it) for the behavior a real course wants.

One warning is expected in every build, and is deliberate:

```
PTX:WARNING: the calendar has a "release" with id "final-instructions", but no
element in the source carries @release-id="final-instructions".
```

`final-instructions` is a rule with no gated content anywhere in the source, so
that this direction of the orphan check fires on every build. It is only a
warning, because shared source legitimately carries schedule entries for
material a given book leaves out. The other direction — a `@release-id` matching
no rule — drops the content and is also reported; see "Things worth breaking" in
the document itself.

## The term

`publication.xml` sets `start="2026-08-24"`, `end="2026-12-04"`, `meets="MWF"`,
with Labor Day (2026-09-07) and a three-day Thanksgiving break
(2026-11-25 through 2026-11-27) removed. That is 42 meetings across 15 weeks.
2026-08-24 is a Monday, so week 1 is a full week.

Two weeks are worth knowing about, because everything interesting happens there:

| Week | Block | Meetings held |
|---|---|---|
| 3 | 2026-09-07 – 2026-09-13 | Wed 09-09, Fri 09-11 — the Monday is Labor Day |
| 14 | 2026-11-23 – 2026-11-29 | Mon 11-23 only — the Wed and Fri are the break |

### Rule A, which is the thing to understand

Week-and-weekday references are **calendar-anchored** and a holiday never moves
them. Meeting-ordinal references are **sequence-anchored** and slide past
holidays. Both exist because instructors make both kinds of claim: "exam 2 is
Wednesday of week 11" is a promise about the calendar, and "we cover trees on
class 12" is a promise about the sequence.

| Reference | Resolves to | Why |
|---|---|---|
| `week3.mon` | 2026-09-07 | calendar-anchored; lands on the holiday |
| `week3.d1` | 2026-09-09 | first *meeting* of week 3's fixed 7-day block |
| `class7` | 2026-09-09 | would be 09-07 in a term with no holiday in week 3 |
| `week14.d1` | 2026-11-23 | week 14's only meeting |
| `week14.wed` | 2026-11-25 | calendar-anchored; a day with no class |
| `week14.d2` | *error* | week 14 holds one meeting, so there is no date to give |

## Events, and what they resolve to

Independently computed, and matched against a build. This is the table to check
a change against; the one inside the document is produced by the machinery under
test and so proves only self-consistency.

| Event | Written as | Resolves to | |
|---|---|---|---|
| `first-day` | `week1.mon` | 2026-08-24 | Mon |
| `add-drop` | `class5` | 2026-09-02 | Wed |
| `hw1-due` | `week2.fri` | 2026-09-04 | Fri |
| `project-proposal` | `week3.d1` | 2026-09-09 | Wed |
| `hw2-due` | `hw1-due+1w` | 2026-09-11 | Fri |
| `hw3-due` | `week5.fri` | 2026-09-25 | Fri |
| `exam1` | `week6.wed` | 2026-09-30 | Wed |
| `exam1-return` | `exam1+2d` | 2026-10-02 | Fri |
| `midpoint` | `class21` | 2026-10-12 | Mon |
| `hw4-due` | `week8.f` | 2026-10-16 | Fri |
| `review-session` | `w9.r` | 2026-10-22 | Thu, off-pattern |
| `guest-lecture` | `2026-10-30` | 2026-10-30 | Fri, literal |
| `exam2` | `w11.w`, **overridden** to `week11.fri` | 2026-11-06 | Fri |
| `hw5-due` | `week13.fri` | 2026-11-20 | Fri |
| `last-day` | `week15.fri` | 2026-12-04 | Fri |
| `final-project-due` | `last-day-2d` | 2026-12-02 | Wed |
| `final-exam` | `2026-12-09` | 2026-12-09 | Wed, literal |

`exam2` is the case worth following. It is written `w11.w` in `docinfo` and
retimed to `week11.fri` by the publication file, and the review window and the
answer key moved with it and needed no edit at all.

## Releases, and what each build should show

Windows below are as resolved in `publication.xml`; `publication-early.xml` and
`publication-instructor.xml` share them exactly, since only `@as-of` and
`@releases` differ. Both endpoints of a window are inclusive.

| Rule | Written as | Opens | Closes | mid-term<br>2026-10-14 | week 1<br>2026-08-26 |
|---|---|---|---|---|---|
| `syllabus-quiz` | `through="add-drop"` | — | 09-02 | expired | **shown** |
| `office-hours-note` | `first-day` … `week4.fri` | 08-24 | 09-18 | expired | **shown** |
| `project-guidelines` | `project-proposal-1w` | 09-02 | — | **shown** | until 09-02 |
| `hw1-solutions` | `hw1-due+1d` | 09-05 | — | **shown** | until 09-05 |
| `hw2-solutions` | `hw2-due+1d` | 09-12 | — | **shown** | until 09-12 |
| `hw3-solutions` | `hw3-due+2d`, **overridden** to `hw3-due` | 09-25 | — | **shown** | until 09-25 |
| `hw4-solutions` | `hw4-due+1d` | 10-17 | — | until 10-17 | until 10-17 |
| `hw5-solutions` | `hw5-due+1d` | 11-21 | — | until 11-21 | until 11-21 |
| `exam1-review` | `exam1-1w` … `exam1` | 09-23 | 09-30 | expired | until 09-23 |
| `exam1-key` | `exam1-return` | 10-02 | — | **shown** | until 10-02 |
| `exam2-review` | `exam2-1w` … `exam2` | 10-30 | 11-06 | until 10-30 | until 10-30 |
| `exam2-key` | `exam2+3d` | 11-09 | — | until 11-09 | until 11-09 |
| `unit3` | `week7.mon` | 10-05 | — | **shown** | until 10-05 |
| `unit3-advanced` | `week9.mon` | 10-19 | — | until 10-19 | until 10-19 |
| `unit4` | `week10.mon` | 10-26 | — | until 10-26 | until 10-26 |
| `midpoint-survey` | `midpoint` … `midpoint+4d` | 10-12 | 10-16 | **shown** | until 10-12 |
| `final-instructions` | `week14.mon` | 11-23 | — | until 11-23 | until 11-23 |
| `course-note` | `week8.mon`, publication only | 10-12 | — | **shown** | until 10-12 |

The source carries 34 elements with a `@release-id`, drawn from 17 of those 18
rules. The counts that follow are the assertion worth automating:

| Build | Rules open | Gated elements retained |
|---|---|---|
| `publication.xml` | 8 | 17 |
| `publication-early.xml` | 2 | 2 |
| `publication-instructor.xml` | 8 (gating suspended) | 34 |
| `publication-wednesday.xml` | 8 | 17 |

`sec-unit4` is gated on `unit4` and is therefore absent from the student build
entirely — no `sec-unit4.html`, no table-of-contents entry, no navigation link.
It is present in the instructor build. That pair of builds is the quickest check
that division-level gating works.

## Nesting

Gating composes by containment: an element survives only if it is released *and*
every element containing it is released. An inner rule can never rescue content
from an outer one. All four cases are in the document, under "Releases Inside
Releases", and in the mid-term build they should come out like this:

| Case | Outer | Inner | Mid-term result |
|---|---|---|---|
| 1 | open | open | both present |
| 2 | open | closed | outer present, inner gone |
| 3 | **closed** | open | both gone — the case worth pinning down |
| 4 | three levels | mixed | division and exercise present, `unit3-advanced` paragraph and `hw5-solutions` solution gone |

Case 3 leaves its subsection holding only prose, which is the correct output and
not a missing example.

Two related caveats, neither of them specific to nesting:

- An `xref` whose target is withheld will fail, since the target is gone by the
  time cross-references are resolved. This document deliberately contains no
  `xref` into gated content.
- Numbering shifts when a gated division or block disappears. Chunk level and
  table-of-contents level do not: they are computed from the full edition before
  any release is considered, so a document's files and URLs do not reshuffle
  partway through the term.

## The mid-week start

`publication-wednesday.xml` moves `@start` to Wednesday 2026-08-26 and changes
nothing else. Week 1 still begins on Monday 2026-08-24 — the latest
`@week-starts` day on or before `@start` — so week 1 is short, holding only the
Wednesday and the Friday, and weeks 2 onward line up with the ordinary calendar
instead of being two days out of phase for the whole term.

| | Monday start | Wednesday start |
|---|---|---|
| meetings in the term | 42 | 41 |
| `week1.mon` (`first-day`) | 2026-08-24 | 2026-08-24, *before instruction begins* |
| `week1.d1` | 2026-08-24 | 2026-08-26 |
| `class5` (`add-drop`) | 2026-09-02 | 2026-09-04 |
| `week2.fri` (`hw1-due`) | 2026-09-04 | 2026-09-04 |
| `class7` | 2026-09-09 | 2026-09-11 |

The first row of that table is the trap. `week1.mon` is calendar-anchored and
knows nothing about `@start`, so a schedule that must survive a mid-week start
should write `week1.d1` for the first day of class.

## Known gaps

- `pretext build --as-of <ref>` is described in the roadmap but is not yet wired
  through the CLI; only the `as-of` stylesheet parameter and `calendar/@as-of`
  exist. That is why previewing another week here means another publication file
  rather than a flag.
- `at="today"` resolves to the real current date, not to the calendar's
  reference date, so it is the one thing in the output that changes on a rebuild
  with no edit. The roadmap's reference table describes it as the `as-of` date.
- The derived schema files `schema/pretext.rnc` and `schema/pretext.rng` do not
  yet carry the calendar feature, which is present in the `pretext.xml`
  literate source they are generated from. Editors that validate against the
  derived schema will flag `date/@at`, `daterange`, `@release-id`, and
  `docinfo/calendar` in `main.ptx`. Regenerating with `schema/build.sh` clears
  it; this document validates against the regenerated schema.
