<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- Grouped by subject in the class's `subjects[]` order, A-Z by title inside a group; exercises are listed with the word "Bài tập"; no search or filter.
- Rows are not tappable in phase 1.

# Shape brief: `student-library` (EduBox phase 1)

Mode: Operate (Android, Flutter, Material 3, Vietnamese). This is the student's catalogue of approved content, built inside the committed `achromatic-ledger` direction. No new visual world is needed.

## 1. Job and audience

- **Who and when:** a student on a tablet, in class or at home, who wants to see what the teacher has approved for their class. They may be young and the tablet may be old or shared, so legibility beats density.
- **The one question:** "What can I open?" (`docs/design/app-direction.md` section 2). The biggest block is the catalogue grouped by subject.
- **Primary task in phase 1:** scan and recognise. Nothing is opened, downloaded or started here. Opening arrives in phase 2 (`student-content-detail`).
- **Success:** the seeded student sees exactly the approved fixtures for their classes. The draft fixture and other classes' content are absent (roadmap exit criterion 1).
- **Product truth:** the catalogue is the "organized shelf, not a data-grid" from DESIGN.md. It is the *thẻ thư viện / mục lục* (library card catalogue) signature element from app-direction 1.2: a card catalogue grouped by subject, not a grid of tiles.

## 2. Direction (already decided; do not reopen)

- **Style:** `achromatic-ledger`. The catalogue is ink on paper, with **no dominant accent and no primary action** (section 2 table). Functional accents are allowed: the focus ring and the Thử lại text button's focus.
- **Surfaces:** ground is `paper`. Each subject group sits on a `sheet` panel with an 8dp radius and a 1dp `rule` edge, with no shadow. Rows inside a panel are separated by a 1dp `rule` hairline.
- **Student density:**
  - gap 24, panel padding 24
  - two-line rows 72dp
  - body 16sp
- **Tokens:** consume the theme (`EduPalette`, `EduDensity`, `TextTheme`). No hex literals.

## 3. Content and order

### Data in play

- Source: `content` docs where `status == approved` and `classIds` intersects the student's classes (the query must carry the `status == approved` filter or the rules deny it).
- Fields used: `title`, `type` (`ebook|video|exercise`), `subject`.
- Fields in the fixtures but not shown: `gradeLevel`. Every item is already for the student's class, so grade is redundant noise.
- Not in the phase 1 model: page count, duration, cover image, download state. Phase 2's `contentIngest` normalises page count and duration.

### Page order, top to bottom

1. **App bar (pinned):** h1 "Thư viện" (Bitter 24/32). Under it, in `muted` body, the total ("12 tài liệu"). This satisfies house rule 15: a full list screen states its total and keeps its header in view.
2. **Offline strip** (app-wide, 40dp, only while offline). This is the shell's component and is not owned by this screen.
3. **Subject groups.** Each group is:
   - a heading, `titleLarge` (Be Vietnam Pro 600, 18/26), showing the subject name only
   - a `sheet` panel of rows beneath it

### Grouping

By `subject`, one group per subject, each under its own heading.

### Group order

- Follow the order of `subjects[]` on the student's class, which is the teacher's own order.
- Any subject not found there goes after those, alphabetical in Vietnamese collation.
- Items with an empty `subject` go in a last group headed "Môn khác".

### Order within a group

- Alphabetical by `title`, using a diacritic-aware Vietnamese compare.
- Ties break on type: Sách, Video, Bài tập.
- Newest-first was rejected. A calm shelf should be stable and findable, not a feed that reshuffles.

### Filtering

None in phase 1.

- Fixtures are small (about 6 to 14 items, designed to a maximum of about 60).
- Subject grouping already does the filtering.
- A filter control is added later only if real class libraries exceed roughly 30 items.

### Row anatomy

Two lines, 72dp tall, the whole row being one reading unit:

| Part | Spec |
| --- | --- |
| Cover slot | 48 x 64dp, radius 4, `sheet` with a 1dp `rule` edge. Holds a 24dp outline type glyph in `muted`, because there is no cover data yet. It is decorative (`ExcludeSemantics`). When phase 2 ships covers, the same slot takes the image. |
| Title | `titleMedium` (16/24, 600, ink). Up to 2 lines, then ellipsis. At text scale 1.5x or more, up to 3 lines. The row grows in height and never clips. |
| Type word | Under the title in `muted` 14sp body: "Sách", "Video" or "Bài tập". This is the visible, readable type word. The glyph never carries meaning alone. A type is not a status, so it is not a stamp. Phase 2 extends it to "Sách · 148 trang" and "Video · 12:40". |
| Trailing column | Nothing in phase 1. No stamp, chevron, menu or progress, and no reserved blank space. Phase 2 adds the availability stamp column ("Đã tải về máy" / "Cần kết nối mạng để mở"). |

## 4. Tapping an item in phase 1

**ASSUMPTION: rows are not interactive in phase 1.** The whole row has no ripple, no chevron, no focus stop and no snackbar, and a tap does nothing.
- Nothing in the row looks tappable, so it makes no false promise. A "coming soon" snackbar would be a dead end dressed as a feature.
- The row is built so phase 2 can wrap it as one full-row 72dp target that pushes `student-content-detail`.
- Alternatives: a tap shows an explanatory snackbar; or a visible muted note under the total ("Mở tài liệu sẽ có ở bản sau").

## 5. Layout per breakpoint

Width decides the layout, never orientation (app-direction section 5).

| Class | Width | Shell | Gutter | Library layout |
| --- | --- | --- | --- | --- |
| compact | < 600 | Bottom `NavigationBar` | 16 | One column. Panel padding drops to 16 and row gap stays 72dp. |
| medium | 600-839 (portrait 800: 88 rail + 24 + 664 + 24) | Rail 88dp | 24 | One column, 664dp wide. |
| expanded | 840-1199 (960 landscape) | Rail 88dp | 32 | Two equal columns, about 392dp each with a 24dp column gap. |
| large | >= 1200 (1280: 240 rail + 32 + 976 + 32) | Extended rail 240dp | 32 | Two equal columns, about 476dp each with a 24dp column gap. |

- **Cap on width:** the catalogue is exempt from the 760dp reading cap, as app-direction 6.1 states for the library. It uses the full content width in two columns. In one-column classes it is capped at 760dp and centred.
- **Heading and columns:** the subject heading spans the full width. Rows flow into the columns beneath it.
- **Column order:** column-major (down the first column, then the second). Build each group as two columns split at `ceil(n/2)`, which is cheap at these counts.
- **Large text:** at text scale 1.5x or more, force one column so titles have room.
- **Height check, landscape 1280 x 800 (about 728dp usable):**
  - app bar and total take about 72dp
  - the first group's heading and its first rows fit in the same view
  - at least one subject heading and three rows are visible without scrolling
- **Scroll:** the page scrolls (a lazy sliver per group); the app bar stays pinned.
- **Navigation:** Thư viện is the active destination, shown as the neutral `active` pill. System Back leaves the app or returns to the home destination as the shell defines. This screen has no back control of its own because it is a rail or bar destination.
- **System bars:** wrap in `SafeArea` so the screen works with system bars visible or hidden (phase 2 kiosk readiness).

## 6. States

Each state keeps the h1 and the panel frame.

| State | What shows |
| --- | --- |
| **Loading** (first snapshot pending) | The final layout with skeleton bars. The h1 is shown at once. The total is an `active` bar. There are two groups of three rows: a heading bar, a cover-slot block, a title bar at about 60% width, a type bar at about 25%. All bars are flat `active`, with no shimmer and no spinner. The skeleton is excluded from semantics and a single live-region label "Đang tải thư viện" is announced. Data lands with no layout shift. |
| **Full** | As in sections 3 and 5. |
| **Empty** (the query returned zero approved items and the data is from the server) | The h1 and one `sheet` panel containing one sentence in `muted`: "Thư viện của lớp chưa có tài liệu nào." The total is not shown, or reads "0 tài liệu". Printing a real zero is house rule. No illustration. |
| **Offline, cache has data** | The list renders normally from the Firestore cache. The app-wide strip tells the user they are offline ("Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được."). Nothing per-row changes in phase 1, because no item has an availability state yet. |
| **Offline, no cached data** | A cold cache while offline looks like an empty result to Firestore. Treat a snapshot that is empty, `isFromCache`, and offline as this state, never as `libraryEmpty` (that would be a false "nothing here"). It shows a `cloud_off` glyph and one neutral sentence: "Máy chưa lưu danh sách tài liệu. Kết nối mạng để xem thư viện." The list fills in by itself on reconnect. No retry button, because nothing is for the student to do. |
| **Error with retry** (stream error: `unavailable` with no cache, or `permission-denied`) | Inside the block: negative 18dp glyph, then "Không tải được thư viện. Cập nhật lần cuối 09:14." (the time only if a good snapshot was seen this session; otherwise the sentence without it), then a "Thử lại" `TextButton` in ink. Retry re-subscribes, and the button shows "Đang thử lại…" with the one allowed in-button spinner while busy. Never a full-screen error. |
| **Error after data was shown** | Keep the old rows on screen. Put the same error line in a one-row `sheet` band above the groups. Do not blank the list. |
| **Reconnect** | The strip collapses per the shell's rule, and new rows arrive with a 150ms fade. Rows are not re-announced. |

## 7. Interactions and motion

- Scroll and read; nothing else.
- Realtime: the Firestore listener is live, so there is no pull-to-refresh and no manual refresh. The only control on the screen is "Thử lại" in the error state.
- Motion is feedback only: a row arriving fades in over 150ms with the standard easing. When `disableAnimationsOf` is true it is instant. No entrance choreography.

## 8. Accessibility

- **Tap targets:** "Thử lại" is a 48 x 48dp minimum target. Nothing else is interactive, so `androidTapTargetGuideline` has nothing to flag.
- **Semantics:**
  - One list container labelled "Danh sách tài liệu".
  - Subject headings are `Semantics(header: true)`.
  - Each row is one merged node reading "<title>, <type>" (for example "Phân số, Sách"). The cover glyph is excluded.
  - Error and loading labels are live regions.
  - The semantics order is: h1, total, group heading, its rows, next group.
- **Contrast:** ink 16.7:1 on sheet and muted 7.4:1 on sheet, both AA. The negative glyph and sentence are 6.5:1.
- **Text scale to 200%:** reflows. Titles wrap to 3 lines, rows grow, the layout drops to one column at 1.5x or more, and nothing clips. Mind the Vietnamese stacked-mark headroom: line heights follow the type table and single-line boxes keep at least 4dp of padding above the text. The ẬẤỖỘỄ golden must include the row title and type styles.
- **Type is never carried by the glyph alone:** the type word is always visible text.
- Every string, including semantics labels and tooltips, comes from `AppLocalizations`.

## 9. Copy (key: proposed Vietnamese)

| Key | vi |
| --- | --- |
| `libraryTitle` (also the nav label) | Thư viện |
| `libraryTotal(count)` | {count} tài liệu |
| `libraryListSemantics` | Danh sách tài liệu |
| `librarySubjectOther` | Môn khác |
| `contentTypeEbook` | Sách |
| `contentTypeVideo` | Video |
| `contentTypeExercise` | Bài tập |
| `libraryItemSemantics(title, type)` | {title}, {type} |
| `libraryLoading` (semantics only) | Đang tải thư viện |
| `libraryEmpty` (fixed by app-direction) | Thư viện của lớp chưa có tài liệu nào. |
| `libraryOfflineNoData` | Máy chưa lưu danh sách tài liệu. Kết nối mạng để xem thư viện. |
| `libraryLoadError` | Không tải được thư viện. |
| `libraryLoadErrorWithTime(time)` | Không tải được thư viện. Cập nhật lần cuối {time}. |
| `retry` (existing) | Thử lại |
| `retrying` | Đang thử lại… |
| `networkOffline` (existing, shell) | Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được. |

The subject names come from content data, not l10n.

## 10. What is NOT on this screen

- Search, sort, filter chips, view toggle (grid or list), tabs by type.
- Per-subject or per-type counts, progress bars, "new" or "recent" markers, favourites, streaks, badges.
- Download buttons, availability stamps ("Đã tải về máy", "Cần kết nối mạng để mở") and any download or offline-cache UI. All of it is phase 2.
- Open, preview or detail navigation, chevrons, overflow menus, FAB.
- Draft, "awaiting approval" or rejected items. Students never see them, and the screen never mentions that other content exists.
- Padlock or "restricted" iconography and warning-grey banners (house rule 10).
- Illustrations, mascots, gradients, shadows on resting surfaces, icon-in-tinted-circle tiles, and a greeting (the home owns that).
- A back button, a bell or an avatar.

## 11. Constraints and open points for the builder

- **Rules:** the query must filter `status == approved`. `classIds arrayContainsAny` takes at most 30 ids, which is fine for a student's classes.
- **Offline detection:** use snapshot metadata (`isFromCache`) together with the `NetworkController` seam (roadmap Rulings) to tell "empty" from "offline with no cache" from "error".
- **Tests:** E2E exit criterion 1 asserts the exact approved set by title, looked up via `lookupAppLocalizations(Locale('vi'))`. Widget tests cover each state in section 6 and the breakpoints (800 x 1280, 1280 x 800, 960 x 600, <600). Accessibility guideline tests and the 200% text-scale golden are required (exit criterion 11).
- **Reusable components to build once, shared with phase 2 and `student-home`:** `CatalogueRow` (the cover slot is swappable) and `SubjectGroup`.

## ASSUMPTIONS

- ASSUMPTION: rows are non-interactive in phase 1 (no ripple, chevron or snackbar; a tap does nothing) (alternatives: tap shows an explanatory snackbar; a visible "coming in the next version" note under the total).
- ASSUMPTION: exercises (`type: exercise`) are listed in the library with the word "Bài tập", because the data model and E2E criterion say the library lists all approved content (alternatives: hide exercises until phase 3's `student-assignments`).
- ASSUMPTION: group by `subject`, ordered by the class's `subjects[]` order, then alphabetical, then "Môn khác" last (alternatives: alphabetical only; a fixed core-subject order).
- ASSUMPTION: within a group, order alphabetically by title with Vietnamese diacritic-aware compare, ties by type (alternatives: newest first by `createdAt`; by type then title).
- ASSUMPTION: no filtering, search or sort in phase 1 (alternatives: a type segmented control; a subject jump list once libraries exceed about 30 items).
- ASSUMPTION: the visible type word is shown in `muted` 14sp body text on the second line, not as a stamp (alternatives: a neutral stamp; a type-prefixed title).
- ASSUMPTION: no page count, duration or availability stamp in phase 1, and no reserved trailing blank column (alternatives: seed fixture lengths and show "Sách · 148 trang" now).
- ASSUMPTION: the cover slot holds a decorative 24dp outline type glyph in `muted` because fixtures have no cover (alternatives: a plain `active` block; hide the cover slot until phase 2).
- ASSUMPTION: `gradeLevel` is not shown, since every item is already for the student's class; if a student's classes span more than one grade, append "Lớp N" to the type line (alternatives: always show grade; never show it).
- ASSUMPTION: in expanded and large classes, subject headings span the full width and rows fill two columns column-major, and the layout collapses to one column at text scale 1.5x or more (alternatives: row-major order; keep two columns at every text scale).
- ASSUMPTION: the catalogue is exempt from the 760dp reading cap in two-column classes, as app-direction 6.1 states; in one-column classes it caps at 760dp and is centred.
- ASSUMPTION: the total is stated under the h1 in the pinned app bar as "{count} tài liệu", and subject headings carry no counts (alternatives: counts in each heading; total omitted).
- ASSUMPTION: the empty state is the single fixed sentence `libraryEmpty` only, with no hint line (alternatives: a second sentence "Khi thầy cô duyệt tài liệu, tài liệu sẽ hiện ở đây.").
- ASSUMPTION: an empty snapshot that is `isFromCache` while offline is treated as "offline, no cached data" with the `libraryOfflineNoData` sentence and no retry button, never as empty (alternatives: show the generic offline strip only, plus the empty sentence).
- ASSUMPTION: after an error that follows a successful load, keep the old rows and show the error line in a band above them (alternatives: replace the list with the error block).
- ASSUMPTION: there is no pull-to-refresh, because the Firestore listener is live (alternatives: add pull-to-refresh that re-subscribes).
- ASSUMPTION: expected content range is 0 to about 60 items, typical 6 to 14, titles up to about 80 characters (alternatives: larger libraries, which would bring back a filter).

No `DECISION` items. Every open choice above is reversible and cheap, and none changes the data model or the roadmap.
