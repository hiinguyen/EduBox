# EduBox app direction

Owner: art-director, build pipeline.
Date: 2026-10-29.
Applies to: the whole Flutter app (all six roadmap phases), Android tablet, landscape and portrait, Vietnamese UI.
Inputs: `PRODUCT.md`, the user-approved seed `DESIGN.md`, `docs/build/roadmap.md`, the phase 1 spec, and the design-taste-frontend skill in app-screen mode.
Dealt sheet: `.taste-skill/app/direction.json` (reprint with `node .agents/skills/design-taste-frontend/scripts/draw.mjs --show`).
Evidence for every font and contrast claim below: `.taste-skill/app/font-check.txt`.

This file translates the direction into Flutter terms.
Anything the draw script prints in CSS or pixels is reference only; this file is in dp and sp, and no HTML goes into the app.
`DESIGN.md` is not edited here; the documenter re-derives it from the shipped app later, using the resolved values in section 3.

## 1. Chosen style and why

Draw: `draw.mjs --app --kind workspace --screens home,list,detail,builder,inbox,analytics,report --keep palette,type --options 3`, seed 1963646856.
The library dealt two styles for this kind: `editorial-greeting` and `achromatic-ledger`.

**Chosen: `achromatic-ledger`.**
Its move is that the chrome holds no colour at all, figures are set in ink like a ledger's columns, and one hue marks the single thing on the screen that matters.
That is the North Star "The School Record Room" stated as a system: a report card, a gradebook and a library record are ink on paper with one mark that matters.
It also enforces the One Accent Rule by construction, keeps surfaces flat (Flat-By-Default Rule), and suits all three roles, because a ledger can be generous (a student's own record) or dense (a teacher's gradebook) without changing voice.

`editorial-greeting` was rejected: its move is a typeset greeting over a centred column of count tiles, which fits a personal home only and fights the teacher's table-forward screens, and its count tiles drift toward the engagement metrics PRODUCT.md forbids.

### 1.1 Adaptations to the dealt sheet (each with its reason)

1. **The primary action is filled in the accent, not near-black.**
   The seed binds the accent to primary actions.
   The ledger's spirit survives because the accent is a blue-black ink (`#1F4C8F`), not a brand colour: it reads as the pen, not as a logo.
   When a screen spends its one accent on data instead (a score, a gradebook column), its primary action is filled in ink `#191E29`, which is exactly the ledger's near-black primary.
2. **Three typefaces, not the skill's usual two.**
   The seed names three roles (display, body, label/mono), and the check in section 3.2 proves the mono is necessary: the chosen body face has proportional digits and no `tnum` feature, so every aligned or updating figure needs the mono.
   The ledger style itself lists "every figure in a mono" as one of its faces.
   Each face keeps one job (section 3.2), and the mono never sets prose or headings.
3. **The dealt `home` pattern is adapted.**
   Its four count tiles are dropped on every home: counts of finished work are an engagement device on a student surface and say nothing a teacher acts on.
   The home keeps the pattern's greeting (student only), its 12-column column arithmetic, and its panels of row cards.
4. **The shell "open plane" becomes a Material 3 `NavigationRail` on the paper ground** with no divider, which is the same archetype in Flutter terms (section 5).
5. **Index numbers appear only as data**: question numbers in an exercise or test, and the A, B, C, D of a multiple-choice option.

### 1.2 Its face and the product's own elements

The skill requires one face taken from the product, chosen before building, and one element only this product has.

- **The face: blue-black school ink on cool paper.**
  Vietnamese students write in blue ink; the accent is that ink, and the paper ground is tinted toward the same hue at very low chroma.
  The accent marks what the student writes (a selected answer) and what to do next (the one primary action), nothing else.
- **The teacher's red pen is reserved.**
  In Vietnamese schools red ink is the teacher's correction mark.
  So red (the negative family) appears only on teacher-facing exceptions (late, grading failed, rejected upload) and on real errors, never on a student's own wrong answer.
  A student's result shows the correct answer in the positive family and their own choice in neutral ink, in words.
  This is also why oxblood was rejected as the accent (section 3.1).
- **Signature elements, from the school's own paper:**
  - *Sổ điểm* (the gradebook): the teacher results dashboard is a student-by-assignment grid of scores in mono figures with status stamps in the cells.
  - *Sổ liên lạc* (the school-to-home contact book): the parent summary is a single dated column of entries, newest first, read-only.
  - *Thẻ thư viện / mục lục* (the library card catalogue): the product mark is an index card with a divider tab, and the student library is a catalogue grouped by subject, not a grid of tiles.
  - *Con dấu* (the stamp): every status is a stamped word (Stamped Status Rule, section 3.4).
- **The mark:** a 24dp index-card glyph (a 2dp outline rectangle, radius 4, with a raised tab on the top-left third) in the accent, followed by the wordmark "EduBox" in Bitter 600 at 20sp in ink.
  It ships as an SVG asset (rendered with `flutter_svg`) or a `CustomPainter`; never a letter in a filled square.

## 2. What every screen answers first

Each screen names one question; the biggest block answers it and is read first.
The accent column says where the screen's one dominant accent goes; everything else is ink, greys and status families.

| Phase | Screen | Its one question | Biggest block | Accent goes to | Primary action |
| --- | --- | --- | --- | --- | --- |
| 1 | `sign-in` | Can I get into my EduBox? | The sign-in sheet | "Đăng nhập" button | Đăng nhập |
| 1 | `account-not-set-up` | Why can't I go in? | The sentence `accountNotSetUp` | "Đăng xuất" button | Đăng xuất |
| 1 | `student-home` | What should I study next? | "Tiếp theo" panel: the next assignment or the last opened lesson | Its "Tiếp tục" button | Tiếp tục |
| 1 | `student-library` | What can I open? | The catalogue, grouped by subject | Nothing dominant (catalogue is ink) | none |
| 1 | `teacher-home` | What needs me today? | "Cần xử lý" queue (phase 1: my classes) | The queue's top action | Context-dependent |
| 1 | `parent-home` | Whose record is this? | The linked child's name and class | Nothing | none |
| 2 | `teacher-content-list` | What is waiting for me to approve or fix? | Content table, needs-action rows first | "Tải lên" button | Tải lên |
| 2 | `teacher-content-upload` | Did my file go up? | The form and its upload progress | "Tải lên" button | Tải lên |
| 2 | `teacher-content-detail` | Is this fit to approve? | The preview | "Duyệt" button | Duyệt |
| 2 | `student-content-detail` | Can I open this now, here? | Title, cover, availability stamp | "Mở" button | Mở |
| 2 | `student-ebook-reader` | (reading) | The page | Nothing; chrome recedes | none |
| 2 | `student-video-player` | (watching) | The video | Progress scrubber played part | none |
| 3 | `teacher-exercise-editor` | Is this exercise correct and complete? | The question list | "Lưu" button | Lưu |
| 3 | `teacher-assignment-editor` | Who gets what, by when? | The form | "Giao bài" button | Giao bài |
| 3 | `teacher-results-dashboard` | How did my class do on the latest work? | *Sổ điểm* gradebook grid | Header rule of the latest assignment column | "Giao bài mới" (ink) |
| 3 | `student-assignments` | What do I still have to do? | "Cần làm" group | Nothing dominant | none |
| 3 | `student-lesson-and-exercise` | Have I done the lesson, can I start? | Lesson row with its completion stamp | "Bắt đầu làm bài" | Bắt đầu làm bài |
| 3 | `student-exercise` | Which answer do I choose? | The current question and its options | The selected option | "Nộp bài" (ink) |
| 3 | `student-exercise-result` | How did I do? | The score figure | The score figure | "Về danh sách bài tập" (ink) |
| 4 | `student-ai-tutor` | What does the tutor say? | The transcript | "Gửi" button | Gửi |
| 5 | `student-test-lobby` | Can I start, and what are the rules? | Time limit and rules | "Bắt đầu" button | Bắt đầu |
| 5 | `student-test-room` | How much time is left, which answer? | The question | The selected option | "Nộp bài" (ink) |
| 5 | `student-test-submitted` | Did it go in? | Status stamp and score | The score figure (once graded) | none |
| 6 | `parent-summary` | How is my child doing? | *Sổ liên lạc* dated entries | Nothing dominant | none |
| 6 | `parent-ai-chat-log` | What did my child ask the tutor? | Transcript list by subject and date | Nothing | none |
| 6 | `teacher-ai-chat-review` | What did this student ask? | Transcript | Nothing | none |

## 3. Resolved DESIGN.md slots

### 3.1 Colour (light theme only in phase 1)

The seed's single "mid-gray for dividers, disabled states, and secondary metadata" is split into four values, because no one grey can do all three: a divider at 4.5:1 is a heavy line, and metadata at 1.3:1 is unreadable.

| Token | Hex | Role | Contrast (WCAG 2.1) |
| --- | --- | --- | --- |
| `paper` | `#F4F5F8` | Page ground (Scaffold, rail, app bar); hue 225, saturation 22%, lightness 96%: tinted toward the accent, far from the cream band | - |
| `sheet` | `#FFFFFF` | Cards, panels, tables, dialogs, inputs | paper on sheet 1.09:1 (a tone step, not a line) |
| `ink` | `#191E29` | Body text, titles, figures; also the filled primary when the accent is on data | 15.30:1 on paper, 16.68:1 on sheet, 13.71:1 on `active` |
| `muted` | `#4E5666` | Secondary text, metadata, timestamps, icons | 6.77:1 on paper, 7.38:1 on sheet, 6.07:1 on `active` |
| `accent` | `#1F4C8F` | Blue-black ink: the one dominant accent per screen | 8.44:1 on sheet, 7.74:1 on paper, white on accent 8.44:1, 6.94:1 on `active` |
| `accentPale` | `#E5ECF6` | Fill of a selected answer option | `accentInk` on it 11.00:1, ink on it 14.03:1 |
| `accentInk` | `#13305C` | Text on `accentPale` | 11.00:1 |
| `active` | `#E6E9EF` | Selected nav pill, selected list row, skeleton bars, student chat bubble | 1.22:1 on sheet (fill step) |
| `rule` | `#DFE3EA` | Dividers, card edges, table row rules | 1.29:1 on sheet, 1.18:1 on paper (inside the 1.1-1.3 band for structural lines) |
| `control` | `#7D8594` | Borders of interactive components (text field, checkbox, radio, outlined button) | 3.71:1 on sheet, 3.41:1 on paper (passes 1.4.11 non-text 3:1) |
| `disabled` | `#8C93A0` | Text of disabled controls only | 3.09:1 on sheet (WCAG-exempt for inactive components; the reason is always written next to it in `muted`) |
| `inverseAccent` | `#A8C1EA` | SnackBar action on the ink inverse surface | 9.12:1 on ink |

**Accent decision: ink-blue, not oxblood.**
This was not a toss-up.
Oxblood (`#7A2531`) sits 1.50:1 from the negative red, so the one accent and the error family would read as one colour, which breaks the Named State Rule's colour reinforcement.
It also carries the teacher's-red-pen meaning in Vietnamese schools, so a red-family primary button would feel like a correction on every student screen.
Blue ink is what the student writes with, stays clear of every status hue, and keeps the "institutional record" reading the seed asked for.
The school's purple ink (*mực tím*) was considered and rejected: violet is outside the skill's allowed palette and reads as the generic assistant palette.

### 3.2 Typography

Every face was checked on the actual Google Fonts files with fontTools against every precomposed Vietnamese letter (upper and lower case, including Đ and đ), the combining marks U+0300, 0301, 0302, 0303, 0306, 0309, 031B, 0323, digits, punctuation and the dong sign U+20AB.
All three have zero missing glyphs and GPOS `mark` positioning, and all three are SIL OFL 1.1.

| Slot | Face | Job (one each) | Weights shipped | Vietnamese | Figures |
| --- | --- | --- | --- | --- | --- |
| Display | **Bitter** (slab serif, The Bitter Project, v3.021) | Display and headline roles only: screen titles, subject titles, the test title, the student greeting, the wordmark | 600 | Full set, 0 missing | Has `tnum` (not needed in its job) |
| Body | **Be Vietnam Pro** (Be Vietnam Pro Project, v1.002) | Everything else: titles of rows and panels, body, buttons, nav labels, form labels | 400, 500, 600 | Full set, 0 missing; drawn for Vietnamese, with diacritics stacked for it | Proportional digits, **no `tnum`**: never used for aligned or updating figures |
| Label / mono | **IBM Plex Mono** (v2.3) | The record's entries: status stamps, scores, counts in tables, timestamps and dates in rows, page numbers, the test countdown, IDs | 400, 500 | Full set, 0 missing | Monospaced (all digits 600 units), so figures align and never jitter |

Why these:
Bitter is a slab built for reading on screens, sturdy and plain, which reads as a report card or ledger heading rather than an editorial magazine; it is outside the banned display list (Fraunces, Playfair Display, Cormorant, Lora, Crimson, Newsreader).
Be Vietnam Pro is the product's own world: a sans designed for Vietnamese by Vietnamese designers, with its stacked marks (ấ, ặ, ỗ) built in rather than bolted on; it is calm, open and legible at 14-18sp on older tablets.
IBM Plex Mono has the typewriter-and-stamp character of a library due-date stamp, and its slab details pair with Bitter.

Rejected after checking: Source Serif 4 (full Vietnamese, but reads as an editorial book face, against the seed's "not an editorial magazine").

**Stamps are sentence case**, not tracked uppercase: uppercase Vietnamese with stacked marks (ĐÃ CHẤM, ĐANG CHỜ ĐỒNG BỘ) is harder for young readers, and the skill bans tiny tracked uppercase labels.
The stamp character comes from the mono face, the box and the border, not from capitals.

**Vertical metrics and clipping (measured):**
Be Vietnam Pro's tallest Vietnamese capitals reach 1.155em above the baseline against a 1.0em ascent, and IBM Plex Mono's reach 1.097em against 1.025em; Bitter's stay inside (0.945 against 0.935, within rounding).
So: body styles use line height 1.5 for paragraphs, never below 1.33 anywhere; every `TextStyle` sets `leadingDistribution: TextLeadingDistribution.even`; single-line text inside a fixed-height box (buttons, stamps, chips, text fields) keeps at least 4dp of padding above the text; no container that holds Vietnamese text clips its children vertically.
A golden test renders "ẬẤỖỘỄ ặỵ" in every text style at 1.0x and 2.0x text scale and must show no clipped marks.

### 3.3 Type scale (sp)

Six sizes do the work: 12, 14, 16, 20, 24, 32 (plus 18 for student row titles and 28 for the student greeting).
App type is not display type: nothing reaches 34sp, and the largest figure (a score) is 32sp.

| Use | Face, weight | Size / line height | Tracking |
| --- | --- | --- | --- |
| Subject title, test title screen, score figure | Bitter 600 (score: Plex Mono 500) | 32 / 40 | -0.4 |
| Student home greeting | Bitter 600 | 28 / 36 | -0.3 |
| Screen title (h1), student and parent | Bitter 600 | 24 / 32 | -0.2 |
| Screen title (h1), teacher; dialog title | Bitter 600 | 20 / 28 | 0 |
| Panel and section title, student | Be Vietnam Pro 600 | 18 / 26 | 0 |
| Row title (book, lesson, assignment), student | Be Vietnam Pro 600 | 16 / 24 | 0 |
| Row title, teacher table identity | Be Vietnam Pro 600 | 14 / 20 | 0 |
| Body, student and parent (chat, instructions, questions) | Be Vietnam Pro 400 | 16 / 24 | 0 |
| Body and table cells, teacher | Be Vietnam Pro 400 | 14 / 20 | 0 |
| Meta, captions | Be Vietnam Pro 400 | 12 / 18 | 0 |
| Buttons | Be Vietnam Pro 600 | 16 / 24 student, 14 / 20 teacher | 0 |
| Nav labels, chips | Be Vietnam Pro 500 | 12 / 16 (rail extended: 14 / 20) | 0 |
| Stamp | Plex Mono 500 | 13 / 18 student and parent, 12 / 16 teacher | 0 |
| Figure in a row or table | Plex Mono 500 | 16 / 24 student, 14 / 20 teacher | 0 |
| Countdown | Plex Mono 500 | 24 / 32 | 0 |
| Timestamp, date in a row, page number | Plex Mono 400 | 12 / 18 | 0 |

Floor: nothing under 12sp anywhere, and nothing a student must read to act is under 14sp.
Prose that is the main content (tutor chat, questions, instructions) is capped at 68 characters per line, about 640dp at 16sp.
Locale formatting comes from `intl` with `vi`: decimal comma ("8,5"), thousands dot ("1.250"), dates `dd/MM/yyyy`, 24-hour time ("14:30"), weekday names in words for recency ("Hôm nay", "Hôm qua", "Thứ Sáu").
Scores are on the Vietnamese 10-point scale where the assignment is marked out of 10, shown as the figure in ink and the scale in `muted` ("8,5" then "/10").

### 3.4 Status families (Named State Rule, Stamped Status Rule)

Every status is a word.
Colour reinforces the word; it never replaces it, and an icon never stands alone.

| Family | Text / icon on paper or sheet | Stamp fill | Stamp text | Stamp border | Contrast |
| --- | --- | --- | --- | --- | --- |
| positive | `#1E6F45` | `#E2F2E8` | `#0E4026` | `#A9D5BA` | 6.15:1 on sheet, 5.64:1 on paper; stamp 10.17:1 |
| notice | `#8A5300` | `#FDF3D7` | `#5E3800` | `#E9CF8A` | 6.33:1 on sheet, 5.81:1 on paper; stamp 9.30:1 |
| negative | `#B3261E` | `#FBE9E7` | `#7A1A14` | `#EDB9B3` | 6.54:1 on sheet, 6.00:1 on paper; white on it 6.54:1; stamp 9.02:1 |
| neutral | `#4E5666` | `#ECEEF2` | `#2E3440` | `#CDD2DB` | 7.38:1 on sheet; stamp 10.75:1 |

The notice fill is a stamp colour only, never a ground or a panel.

**The stamp**: a rectangle, radius 4dp, 1dp border in the family border, family fill, family text, Plex Mono 500, padding 8dp horizontal and 4dp vertical (height 26dp student, 24dp teacher), an optional 14dp outline glyph 6dp before the word.
It never wraps and never shrinks (`softWrap: false`, intrinsic width); when a row is too narrow, the stamp moves under the row title instead.
One stamp per row.
Its semantics label is "Trạng thái: <word>".

| State | l10n key | vi | Family | Glyph |
| --- | --- | --- | --- | --- |
| To do | `statusToDo` (proposed) | Chưa làm | neutral | - |
| In progress (test) | `statusInProgress` (proposed) | Đang làm bài | neutral | `timer_outlined` |
| Submitted, awaiting grade | `statusSubmittedAwaitingGrade` | Đã nộp, đang chờ chấm | neutral | `schedule` |
| Pending sync | `submissionPendingSync` (sentence), `statusPendingSync` (proposed stamp) | Bài nộp đang chờ đồng bộ / Chờ đồng bộ | notice | `cloud_upload_outlined` |
| Graded | `statusGraded` | Đã chấm | positive | `check` |
| Late (teacher and parent) | `statusLate` | Nộp muộn | negative | `schedule` |
| Grading failed (teacher) | `statusGradingFailed` | Chưa chấm được | negative, plus Retry | `error_outline` |
| Lesson completed | `statusLessonDone` (proposed) | Đã học xong | positive | `check` |
| Content draft | `statusDraft` (proposed) | Bản nháp | neutral | - |
| Ingest processing | `statusProcessing` (proposed) | Đang xử lý | neutral | `hourglass_empty` |
| Ready, awaiting approval | `statusAwaitingApproval` (proposed) | Chờ duyệt | notice | - |
| Approved | `statusApproved` (proposed) | Đã duyệt | positive | `check` |
| Rejected by ingest | `statusRejected` (proposed) | Bị từ chối | negative, plus reason and Replace | `error_outline` |
| Downloaded | `contentAvailableOffline` | Đã tải về máy | positive | `download_done` |
| Needs internet | `contentNeedsInternet` | Cần kết nối mạng để mở | neutral | `cloud_off` |

### 3.5 Spacing

A 4dp base: 4, 8, 12, 16, 24, 32, 48, 64.
Each screen uses one gap value both ways (student and parent 24, teacher 16).
Inside a panel: padding 24 student and parent, 16 teacher.
Between a screen title and its first block: 24.
Between unrelated sections: 48 student and parent, 32 teacher.

### 3.6 Radii (tight pair, chosen once)

Cards, panels, tables, dialogs, bottom sheets (top corners), menus: 8dp.
Buttons, text fields, segmented buttons, answer options, chat bubbles: 6dp.
Stamps, chips, cover thumbnails, the focus ring corner on stamps: 4dp.
People (initials discs): full circle.
No pills, no 12-24dp "friendly" rounding, no stadium buttons; warmth comes from type and copy.

### 3.7 Elevation (Flat-By-Default Rule)

Everything at rest is elevation 0 with `surfaceTintColor: Colors.transparent`, so Material 3 never tints a surface.
A surface is separated by a tone step (paper to sheet) or a 1dp `rule` edge, never both a border and a shadow.
Only what truly floats over the page gets a shadow: dialogs, menus and dropdowns, the modal bottom sheet, tooltips, and the tutor chat when it opens as an overlay (it does not in phase 4; it is a full screen).
Their shadow is elevation 6 with `shadowColor` = ink at 18% opacity, and the modal barrier is ink at 40%.

## 4. Flutter token mapping

Build one `ThemeData(useMaterial3: true)` from an explicit `ColorScheme(...)`.
Never use `ColorScheme.fromSeed`: it generates tonal roles outside this palette.
Force `ThemeMode.light` in phase 1; dark tokens are not defined yet.
Tokens live in one place (for example `app/lib/theme/tokens.dart`) and every widget reads the theme, never a hex literal.

### 4.1 ColorScheme roles

| Role | Value | Used by |
| --- | --- | --- |
| `primary` | accent `#1F4C8F` | FilledButton, focus ring, text cursor and selection handles, checked radio and checkbox, determinate progress |
| `onPrimary` | `#FFFFFF` | Label on the filled accent button |
| `primaryContainer` | accentPale `#E5ECF6` | Selected answer option fill |
| `onPrimaryContainer` | accentInk `#13305C` | Text on a selected option |
| `secondary` | muted `#4E5666` | Fallback for components that pull secondary |
| `onSecondary` | `#FFFFFF` | - |
| `secondaryContainer` | active `#E6E9EF` | NavigationRail and NavigationBar indicator, selected list row, selected segment |
| `onSecondaryContainer` | ink `#191E29` | Selected nav icon and label |
| `tertiary`, `onTertiary` | muted `#4E5666`, `#FFFFFF` | Unused; set neutral so nothing leaks a third hue |
| `tertiaryContainer`, `onTertiaryContainer` | `#ECEEF2`, `#2E3440` | Unused; neutral |
| `error`, `onError` | `#B3261E`, `#FFFFFF` | Field errors, destructive text buttons |
| `errorContainer`, `onErrorContainer` | `#FBE9E7`, `#7A1A14` | Negative stamp (also in the status extension) |
| `surface` | paper `#F4F5F8` | Scaffold, AppBar, NavigationRail ground |
| `onSurface` | ink `#191E29` | Text and figures |
| `onSurfaceVariant` | muted `#4E5666` | Secondary text, icons, unselected nav labels |
| `surfaceContainerLowest` | sheet `#FFFFFF` | Cards, panels, tables, inputs |
| `surfaceContainerLow` | `#F9FAFB` | Hover fill on rows (pointer input only) |
| `surfaceContainer` | `#EFF1F4` | Fallback only |
| `surfaceContainerHigh` | active `#E6E9EF` | Skeleton bars, the student's own chat bubble |
| `surfaceContainerHighest` | `#DFE3EA` | Fallback only |
| `surfaceBright` / `surfaceDim` | `#FFFFFF` / `#E9EBF0` | Fallback only |
| `outline` | control `#7D8594` | Text field, checkbox, radio, outlined button borders |
| `outlineVariant` | rule `#DFE3EA` | Dividers, card edges, table rules |
| `shadow`, `scrim` | ink `#191E29` | Floating shadows; modal barrier at 40% |
| `inverseSurface`, `onInverseSurface` | ink, paper | SnackBar |
| `inversePrimary` | `#A8C1EA` | SnackBar action |
| `surfaceTint` | `Colors.transparent` | Disables M3 tonal elevation |

Material 3 component defaults pull several container roles (dialogs and menus use `surfaceContainerHigh`, the navigation bar uses `surfaceContainer`), so each of those component themes is set explicitly to `sheet` or `paper` as listed in section 7; the container roles above are only safe fallbacks.

### 4.2 TextTheme roles

| Role | Style |
| --- | --- |
| `displayLarge` | Bitter 600, 32/40, -0.4 |
| `displayMedium` | Bitter 600, 28/36, -0.3 (student greeting) |
| `displaySmall` | Bitter 600, 24/32, -0.2 |
| `headlineLarge` | Bitter 600, 24/32, -0.2 (student and parent h1) |
| `headlineMedium` | Bitter 600, 20/28 (teacher h1, dialog title) |
| `headlineSmall` | Bitter 600, 20/28 |
| `titleLarge` | Be Vietnam Pro 600, 18/26 (student panel title) |
| `titleMedium` | Be Vietnam Pro 600, 16/24 (student row title) |
| `titleSmall` | Be Vietnam Pro 600, 14/20 (teacher row title) |
| `bodyLarge` | Be Vietnam Pro 400, 16/24 (student and parent body; text field input) |
| `bodyMedium` | Be Vietnam Pro 400, 14/20 (teacher body and cells) |
| `bodySmall` | Be Vietnam Pro 400, 12/18 (meta) |
| `labelLarge` | Be Vietnam Pro 600, 14/20 (buttons; student buttons override to 16/24 through the density extension) |
| `labelMedium` | Be Vietnam Pro 500, 12/16 (nav labels, chips) |
| `labelSmall` | Be Vietnam Pro 500, 12/16 (Material's 11sp default is raised to the 12sp floor) |

Every role sets `color` from the scheme, `leadingDistribution: even`, and an explicit `height`.
`AppBarTheme.titleTextStyle` is `headlineLarge` (student, parent) or `headlineMedium` (teacher), because the app bar title is the screen's h1.

### 4.3 Theme extensions (the tokens Material has no role for)

- `EduStatusColors`: the four families of section 3.4, each with `fg`, `fill`, `ink`, `border`.
- `EduTypeExtras`: `stamp`, `figure`, `figureLarge` (score, 32/40), `countdown`, `timestamp` (section 3.3), all IBM Plex Mono.
- `EduDensity`: one instance per role (section 6): gap, panel padding, row heights, button height, body style, stamp size, rail mode.
  The role shell injects it with `Theme(data: base.copyWith(extensions: [...]))` so one widget renders at the right density for each role.
- `EduPalette`: paper, sheet, ink, muted, accent, accentPale, active, rule, control, disabled, for the few custom widgets that need a raw token.

### 4.4 Fonts as offline assets

- Ship the files in `app/assets/fonts/` and declare them under `flutter: fonts:` in `pubspec.yaml` with explicit `weight:` entries.
  Families: `Bitter` (600), `BeVietnamPro` (400, 500, 600), `IBMPlexMono` (400, 500).
- Do not use the `google_fonts` package or any runtime font fetch; the app must work offline and later in kiosk mode.
- Bitter on Google Fonts is a variable file; Flutter does not reliably map `FontWeight` onto a variable `wght` axis on Android, so ship a static SemiBold instance.
  Take it from the upstream release (github.com/solmatas/BitterPro) or cut it once with `fonttools varLib.instancer` (allowed: Bitter has no Reserved Font Name) and commit it.
  Be Vietnam Pro and IBM Plex Mono ship as unmodified static files (IBM Plex reserves the name "Plex", so never modify those files).
- Ship each family's `OFL.txt` and register them with `LicenseRegistry.addLicense` so they appear in the licence page.
- Expected size: about 1 MB for the six files; subsetting is unnecessary.

## 5. Layout and breakpoints

Width decides the layout, never orientation; read `MediaQuery.sizeOf(context).width` and map it to a window class (Material 3 classes, in dp).

| Window class | Width | Typical device | Navigation | Gutter | Panes |
| --- | --- | --- | --- | --- | --- |
| compact | < 600 | Phone, split screen, 8" tablet portrait in multi-window | Bottom `NavigationBar`, 3-5 destinations | 16 | One |
| medium | 600-839 | 10-11" tablet portrait (800 x 1280 dp), 8" portrait (600 x 960) | `NavigationRail`, labels always shown, 88dp | 24 | One; list-and-detail screens push |
| expanded | 840-1199 | 8" tablet landscape (960 x 600) | `NavigationRail`, labels shown, 88dp | 32 | Two where both panes stay at least 340dp |
| large | >= 1200 | 10-11" tablet landscape (1280 x 800), the `edubox_tablet` AVD | `NavigationRail(extended: true)`, 240dp, mark and scope at top | 32 | Two |

Arithmetic for the two target sizes (write it into the shell's code comment):
landscape 1280 = 240 rail + 32 + 976 content + 32;
portrait 800 = 88 rail + 24 + 664 content + 24.
In landscape about 728dp of height remains under the status and navigation bars, so every block a screen's question needs shows its header and first rows within that height.

Content width: student and parent screens cap reading content at 760dp and centre it in the canvas; teacher screens use the full canvas width.
A table of five columns or fewer, or a list of six rows or fewer, does not stretch past about 760dp; it pairs with the next block instead.
Two panels sit side by side only when each stays at least 340dp wide; otherwise they stack.
Cards that share a row share a bottom edge (`IntrinsicHeight` or `crossAxisAlignment: start` with the footer action pinned); a card never stretches over empty space.

Phase 2 kiosk readiness:
wrap every screen in `SafeArea`, and design for both visible and hidden system bars;
every pushed screen has an in-app back control in its app bar and never relies on the system back gesture alone;
nothing in the UI says the device is locked; the shell simply is the one place to work.
Text scaling up to 200% (`MediaQuery.textScalerOf`) must reflow, not clip: rows grow in height, stamps move under titles, and tables scroll inside their own frame.

## 6. The shell per role

Shared: the rail sits on `paper` with no divider; the canvas is `paper`, and content sits on `sheet` panels with an 8dp radius and a 1dp `rule` edge.
The extended rail's top holds the mark and wordmark, then the scope (the student's class "Lớp 7A", the teacher's name, the parent's linked child), then the destinations; the user row and "Đăng xuất" sit at the bottom.
The active destination is the neutral `active` pill with the label unchanged in ink; no accent in the nav, no left bar.
Nav icons are Material outlined icons (`Icons.*_outlined`, bundled with Flutter, so offline) at 20dp in `muted`.
Counts on nav destinations appear only on a queue that needs action, with the noun clear from the label.
There is no top search bar, no bell, and no avatar cluster.

### 6.1 Student: generous

- Destinations (4): Trang chủ, Thư viện, Bài tập, Gia sư AI (Gia sư AI arrives in phase 4; until then there are three).
- Density: gap 24, panel padding 24, two-line rows 72dp (48dp cover plus 24), single-line rows 56dp, buttons 48dp tall (primary 56dp on the home and test lobby), body 16sp, stamps 26dp.
- Touch: every target at least 48 x 48dp, the primary at least 56dp tall; answer options 64dp tall and full width up to 720dp.
- The home is the one place with a greeting: "Chào Minh" in `displayMedium` with the weekday and date under it in `muted`; no emoji, no counts, no streaks.
  Below it, the "Tiếp theo" panel holds one next thing and its "Tiếp tục" button, then "Bài tập sắp đến hạn" (at most 4 rows and "Xem tất cả"), then "Đọc gần đây".
- The library is a catalogue: grouped by subject under a `titleLarge` subject heading, each item a row with its cover thumbnail (48 x 64dp, radius 4), title, type and length in `muted` ("Sách · 148 trang", "Video · 12:40"), and its availability stamp in a fixed trailing column.
  In large and expanded classes the rows flow into two equal columns; in medium and compact, one.
- Exercise and test: one question per screen, the question in `bodyLarge` capped at 68 characters per line, options A to D as full-width 64dp rows (`sheet`, 1dp `control` border, letter in Plex Mono), the selected option takes `primaryContainer` with a 2dp `primary` border and a check glyph.
  A question navigator of numbered 40dp squares shows answered (ink fill, white figure) and unanswered (outline) as data.
  "Nộp bài" is ink-filled because the accent is spent on the selected answers.
- The test countdown sits at the app bar's right end: "Thời gian còn lại" in `bodySmall` over the figure in `countdown` style, ink, never red; under one minute a notice stamp "Còn dưới 1 phút" appears beside it.
  Screen readers hear it at fixed points (every 5 minutes, then at 1 minute and 30 seconds) through `SemanticsService.announce`, never every second.
- The tutor follows the dealt inbox pattern: in large and expanded classes, a 320dp left column (subject picker as a `DropdownMenu` or a `SegmentedButton` when there are four subjects or fewer, then past conversations as two-line rows: subject and date) and the transcript filling the rest; in medium and compact, one region at a time.
  Tutor messages sit on `sheet` with "Gia sư" as a `labelMedium` label; the student's own messages sit on `active`, right-aligned, max 560dp; no avatars, no mascot.
  The composer is a bottom-docked `sheet` bar: a multi-line text field and the accent "Gửi" button.
  While streaming, the reply grows in place under the label "Gia sư đang trả lời…" in `muted`.
- The e-book reader and video player recede: a 56dp app bar on `paper` with back, title, and the page number "12 / 148" in Plex Mono; nothing else on screen.

### 6.2 Teacher: denser, table-forward

- Destinations (5 by phase 6): Tổng quan, Nội dung, Bài tập, Kết quả, Trò chuyện AI.
- Density: gap 16, panel padding 16, table rows 48dp (the Android tap-target floor; never 36-44 even though the style allows it), header row 40dp, buttons 40dp tall with a 48dp hit area (`MaterialTapTargetSize.padded`), body 14sp, stamps 24dp.
- Tables: header in `bodySmall` 12sp `muted`, sentence case, no fill band, one 1dp `rule` under it; row rules 1dp `rule`; no zebra.
  The identity column (student or content title) gets a third to a half of the width and is never the one truncated.
  Figures (scores, counts, sizes, durations) are right-aligned in Plex Mono, with the header right-aligned over them; dates in Plex Mono 12, `dd/MM`.
  A missing value is a grey "-"; a real zero is printed "0".
  One status stamp per row in a fixed column; a row that needs doing gets its action as an ink `TextButton` in one fixed trailing column at the same pitch on every row.
  Use `TableView` from the `two_dimensional_scrollables` package (published by flutter.dev) for the gradebook (pinned first column and header row); a plain `Table` or `ListView` of rows elsewhere.
  `DataTable` is acceptable only for small, non-scrolling tables.
- *Sổ điểm* (`teacher-results-dashboard`): students down the pinned left column (initials disc in a pale per-person tint, name in `titleSmall`), assignments across as 96dp columns (short title over its due date in `muted`), each cell the score in Plex Mono or a compact stamp ("Chờ đồng bộ", "Nộp muộn", "Chưa chấm được"), or "-" when not submitted.
  The latest assignment's column header carries a 2dp `primary` rule under it: that is the screen's one accent.
  Above the grid, one line states the finding in words ("28 trên 32 em đã nộp · 3 bài nộp muộn"), computed from the rows.
- Editors (`teacher-exercise-editor`, `teacher-assignment-editor`, `teacher-content-upload`): labels above fields in `labelLarge` at 500 (never floating labels, never a placeholder as the label), fields 48dp, 16dp between fields, one Save at the panel's bottom right.
  A limit that remains (file types PDF, EPUB, MP4; the size cap) is written beside the field and tied to it in semantics.
  In large class the exercise editor is two panes: the question list (360dp) and the open question.
- List-and-detail screens (content, AI chat review) are two panes in large and expanded classes, the selected row in `active`; in medium and compact, the detail is pushed.

### 6.3 Parent: minimal

- No rail: two destinations do not earn one.
  A 64dp app bar on `paper` holds the mark, the child's name and class as the scope ("Nguyễn Minh An · Lớp 7A"), and an overflow menu with "Đăng xuất".
- One centred column, max 760dp, gap 24, panel padding 24, rows 64dp, body 16sp.
- Phase 1 `parent-home`: the child's name in `headlineLarge` and their class in `muted`, and nothing else; no placeholder dashboard, no "coming soon" tiles.
- Phase 6 *Sổ liên lạc* (`parent-summary`): dated entries newest first, each a row with the date in Plex Mono, the assignment title and type, the score in Plex Mono, and one stamp; then "Trò chuyện với gia sư AI" as rows by subject and date that open the read-only transcript.
  No create, edit or delete control appears anywhere in the parent role.

### 6.4 Before sign-in

`sign-in` and `account-not-set-up` have no shell: a 400dp `sheet` panel centred on `paper`, the mark and wordmark at its top, then the form or the message.
Email and password fields with labels above, the accent "Đăng nhập" button full panel width, and errors written under the form as a sentence with the negative glyph (`signInWrongCredentials`).
While the app resolves the signed-in user and role claim, the screen shows the mark and "Đang mở EduBox…" in `muted` under it; never a bare spinner.

## 7. Component inventory (Material 3 choices)

| Need | Flutter component | Settings |
| --- | --- | --- |
| Navigation, medium and up | `NavigationRail` | `backgroundColor: paper`, `indicatorColor: active`, indicator shape radius 6, `labelType: all` (collapsed) or `extended: true` (large), `useIndicator: true` |
| Navigation, compact | `NavigationBar` | `backgroundColor: paper`, `indicatorColor: active`, height 72, labels always shown, 1dp `rule` top edge |
| Screen title bar | `AppBar` | `backgroundColor: paper`, `elevation: 0`, `scrolledUnderElevation: 0`, `surfaceTintColor: transparent`, title is the h1, `centerTitle: false`, back always present on pushed routes |
| Primary action (one per screen) | `FilledButton` | Accent fill, or ink fill (`FilledButton` with an ink `style`) when the accent is on data; radius 6; 48 or 56dp student, 40dp teacher |
| Secondary action | `OutlinedButton` | `sheet` fill, 1dp `control` border, ink label |
| Tertiary action, Retry, row actions | `TextButton` | Ink label (accent only for an inline link), radius 6 |
| Icon-only action | `IconButton` | Always a `tooltip` (it is the accessible name), 48dp target |
| Panels and cards | `Card` (or a `DecoratedBox`) | `color: sheet`, `elevation: 0`, `surfaceTintColor: transparent`, 1dp `rule` side, radius 8, `margin: EdgeInsets.zero` |
| Rows | `ListTile` themed, or a custom row widget | Fixed heights from `EduDensity`; selected uses `active`; dividers 1dp `rule` |
| Tables | `TableView` (two_dimensional_scrollables), `Table` | See section 6.2 |
| Status | Custom `StatusStamp` widget | Section 3.4; never `Chip` (chips look tappable) |
| Filters, view switch | `SegmentedButton` (as wide as its options) or `FilterChip` row | Selected segment `active`, ink label, no accent |
| Secondary tabs | `TabBar` | Underline indicator 2dp ink, on a full-width 1dp `rule`; no pill tabs |
| Text input | `TextField`, `TextFormField` with a label `Text` above | `filled: true, fillColor: sheet`, `OutlineInputBorder` radius 6, 1dp `control`, focused 2dp `primary`, error 2dp `error`, `floatingLabelBehavior: never`, helper and error in `bodySmall` |
| Choice inside a form | `DropdownMenu`, `Radio`, `Checkbox`, `Switch` | Checked state `primary`; `Switch` on-track uses the positive family, not the accent |
| Answer options | Custom `AnswerOption` row | Section 6.1 |
| Determinate progress (upload, download, ingest) | `LinearProgressIndicator` | 6dp, radius 3, track `active`, fill `primary`, always with a label and percentage in Plex Mono ("Đang tải về · 42%") |
| Busy inside an action | `CircularProgressIndicator` 18dp, 2dp stroke, inside the button | The label changes with it ("Đang nộp…"); the button is disabled while busy |
| Dialog | `Dialog`, `AlertDialog` | `backgroundColor: sheet`, radius 8, elevation 6, ink shadow 18%; confirm names the object ("Duyệt "Toán 7 - Chương 3"?") |
| Bottom sheet (compact only) | `showModalBottomSheet` | `sheet`, top radius 8, drag handle |
| Transient confirmation | `SnackBar` | `inverseSurface`, floating, action `inversePrimary`; never for an error that needs action |
| Menu | `MenuAnchor`, `PopupMenuButton` | `sheet`, radius 8, elevation 6 |
| Tooltip | `Tooltip` | ink fill, paper text, radius 4 |
| Count on a nav destination | `Badge` | Only on a queue that needs action; negative fill with white figure |
| Icons | `Icons.*_outlined` | 20dp nav, 18dp inline, `muted`; never in a tinted circle or square |
| E-book | A PDF view plugin (chosen in phase 2) | Its chrome themed to `paper`, page number in Plex Mono |
| Video | `video_player` with custom controls | Scrubber played part `primary`, track `active`, time in Plex Mono |

Motion is feedback only: press, focus, a sheet or menu opening, a row arriving, 150-200ms with the standard easing; nothing performs an entrance.
When `MediaQuery.disableAnimationsOf(context)` is true, every transition is instant.

## 8. State patterns

Every block of every screen has its empty, loading, error and offline state designed, not only its full state.
The l10n key is the contract; the Vietnamese shown is proposed copy unless the roadmap already fixes it.

| State | Where it shows | Pattern |
| --- | --- | --- |
| **Loading** | Inside the block | The final layout with each value replaced by a flat `active` bar at its real size; labels and headers shown at once; no shimmer, no layout shift when data lands. A refresh keeps the old values on screen. |
| **App start / resolving role** | Full screen, once | The mark and "Đang mở EduBox…" (`appOpening`, proposed) on `paper`. |
| **Empty** | Inside the block, which keeps its frame and header | One sentence across the block in `muted`, in the trade's words: "Chưa có bài tập nào được giao." (`assignmentsEmpty`), "Thư viện của lớp chưa có tài liệu nào." (`libraryEmpty`). For teachers the sentence ends in the action ("Tải lên tài liệu đầu tiên"). No illustration, no mascot. |
| **Zero** | Figures | A real zero is printed ("0", "0/10"); a missing value is a grey "-". |
| **Error with retry** | Inside the block that failed | Negative 18dp glyph, one sentence saying what failed and, when known, when the data was last good ("Không tải được danh sách bài tập. Cập nhật lần cuối 09:14."), and a "Thử lại" `TextButton` (`retry`). Never a full-screen error, except `backendUnreachable` on sign-in and app start. |
| **Backend unreachable** | Sign-in and app start | `backendUnreachable` "Không kết nối được với EduBox" with "Thử lại". |
| **Offline (app-wide)** | A 40dp strip at the top of the canvas, under the app bar, on every screen while offline | Neutral fill `#ECEEF2`, `cloud_off` glyph, "Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được." (`networkOffline`, proposed), and on the right the pending count when there is one ("2 bài nộp chờ đồng bộ"). Not dismissible while offline. On reconnect it reads "Đã kết nối lại, đang đồng bộ…" and collapses after the queue empties. Never warning-grey, never a padlock. |
| **Needs internet (per item)** | The item's row and detail | Neutral stamp `contentNeedsInternet`; the open action is disabled with the reason written beside it, never a spinner. |
| **Downloaded** | The item's row and detail | Positive stamp `contentAvailableOffline`. Downloading shows the determinate bar with its percentage in place of the stamp. |
| **Pending sync** | The submission's row, the result screen, the offline strip count | Notice stamp "Chờ đồng bộ" in rows; the sentence `submissionPendingSync` on the student's result or submitted screen. It turns into the graded stamp by itself when the write lands; nothing asks the student to act. |
| **Submitted, awaiting grade** | Student rows and result | Neutral stamp `statusSubmittedAwaitingGrade`. |
| **Grading failed** | Teacher rows | Negative stamp `statusGradingFailed` and a "Thử lại" text action in the row; the student meanwhile sees `statusSubmittedAwaitingGrade`, never the failure. |
| **Late** | Teacher gradebook and rows, parent summary | Negative stamp `statusLate` "Nộp muộn"; the score still shows beside it. The student's own screens say "Đã nộp" and the score, not "late" in red. |
| **Upload failed** | Teacher upload form | `uploadFailed` sentence with "Thử lại"; the chosen file and form values are kept. |
| **Ingest rejected** | Teacher content row and detail | Negative stamp `statusRejected`, the reason as a sentence, and a "Thay tệp khác" action. |
| **AI tutor needs internet** | Tutor composer area | The composer is replaced by `aiTutorNeedsInternet` "Gia sư AI cần kết nối mạng" with the `cloud_off` glyph; past conversations stay readable if cached. |
| **AI tutor paused during a test** | Tutor screen | `aiTutorPausedDuringTest`, neutral, with when it returns ("Sẽ mở lại khi em nộp bài kiểm tra."); not an error. |
| **AI daily limit** | Tutor composer area | `aiDailyLimitReached` "Bạn đã dùng hết lượt hỏi hôm nay", neutral, with when it resets ("Lượt hỏi mới từ 0:00"). |
| **AI tutor error** | Under the failed message | `aiTutorError` sentence with "Thử lại"; the student's message stays in the transcript. |
| **Test needs internet to start** | Test lobby | `testNeedsInternetToStart`; "Bắt đầu" disabled with that sentence beside it. |
| **Disabled controls** | Anywhere | Stay legible (`disabled` text on `sheet`, 3.09:1) and always say why, in `muted`, next to the control. |

## 9. House rules for EduBox app screens

1. One h1 per screen, a noun ("Thư viện", "Kết quả", the object's name); the student home is the one greeting.
2. One dominant accent per screen, chosen from the table in section 2; functional accents (focus ring, cursor, a checked control, an inline link) are not dominant and are allowed anywhere.
3. The chrome (rail, app bar, tabs, segmented controls) never carries the accent.
4. Every status is a stamped word from section 3.4; one stamp per row; colour and glyph only reinforce it.
5. Red is the teacher's pen: negative appears only for real errors and teacher-facing exceptions, never on a student's own wrong answer.
6. Every aligned or updating figure is IBM Plex Mono, right-aligned in tables; prose figures stay in the body face.
7. Flat at rest: no shadow on any resting surface, `surfaceTintColor` transparent everywhere; shadows only on dialogs, menus, sheets and tooltips.
8. Radii are 8 / 6 / 4 and circles for people, nothing else.
9. No gradients, glows, blur, emoji, mascots, confetti, streaks, badges, leaderboards, points, or icon-in-a-tinted-circle tiles.
10. No padlock iconography and no warning-grey banners for the restricted nature of the device.
11. Labels above fields; no floating labels; no placeholder as a label.
12. Nothing under 12sp; nothing a student must read to act under 14sp; every tap target at least 48 x 48dp.
13. Every user-visible string comes from `AppLocalizations` (roadmap phase 1, criterion 9), including semantics labels and tooltips.
14. Loading is a skeleton of the final layout; a spinner appears only inside a busy button beside a changed label.
15. Overview lists cap at 4-6 rows with "Xem tất cả" and the total; full list screens state the total and keep the header in view.
16. Text scale up to 200% reflows without clipping; the Vietnamese mark golden test (section 3.2) passes.
17. Flutter accessibility guideline tests (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) pass on every screen; the palette in section 3 is built to pass them.

## 10. Notes for the builders and the documenter

- Seed DESIGN.md slots resolved here: primary accent, paper neutral, ink, the rule and metadata greys, status families, display/body/label faces, spacing, radii, elevation, shapes, layout.
  The documenter should carry these into `DESIGN.md` from the shipped tokens, not from this file, once code exists.
- Proposed l10n keys in this file are marked "(proposed)"; the contract architect confirms or renames them.
- Sample names used here (Minh, Nguyễn Minh An, Lớp 7A, Toán 7 - Chương 3) are illustration only; screens render from seeded fixtures.
- Package suggestions in this file (`flutter_svg`, `two_dimensional_scrollables`, `video_player`) are direction, not a dependency decision; the phase contract decides.
