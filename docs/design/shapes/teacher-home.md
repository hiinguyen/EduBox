<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

> Backend changed on 2026-10-29: Firebase is replaced by a Serverpod server with PostgreSQL (see the amended spec). Read every Firestore, snapshot, `isFromCache`, custom-claim, or Firebase error reference below as its equivalent in the phase 1 contract: the app's local store and outbox, the server-stored role, and the contract's error shapes. The screen behavior and states are unchanged.

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- Phase 1 content: the "Lớp của tôi" ledger (Lớp | Khối | Môn học | Học sinh), sorted by grade then name, rows not tappable; no class roster screen.

# Shape brief: `teacher-home` (phase 1)

Mode: **Operate**. The surface inherits the approved world in `docs/design/app-direction.md` (achromatic-ledger, ink-blue accent, Bitter / Be Vietnam Pro / IBM Plex Mono). No visual-world workshop applies. I made no discovery interview because there is no user; every choice is marked below.

No `DECISION:` is needed. Every open point is a builder-level choice that I resolved as an ASSUMPTION.

## 1. Job and audience

- **Who:** a seeded teacher who has just signed in. They are on a tablet at prep time or between classes, and want to confirm "this is my account, and these are my classes".
- **The screen's one question** is "What needs me today?" In phase 1 nothing can need action, because the teacher can't create content, assignments or grades yet.
- **Phase 1 answer:** the honest answer is "here are the classes you teach". The table shows each class with its grade, subjects and student count.
- **Why this matters beyond orientation:** `gradeLevel` and `subjects[]` are what later scope the AI tutor and the content, so the teacher sees the data that scopes their work.
- **Biggest block:** the class ledger, titled `Lớp của tôi`.
- **Accent:** no dominant accent in phase 1, because the screen has no primary action. The ink-blue appears only functionally (focus ring, the retry text button's focus). The One Accent Rule is satisfied by spending zero.
- **Primary action:** none.

## 2. Selected direction

- **Structural thesis:** a ledger page. There is a flat `sheet` panel on `paper` with a header, then a 4-column table of 48dp rows separated by 1dp `rule` lines, with no zebra, shadows or tiles.
- **Shell thesis:** the teacher shell is built once as a destination-driven shell, so phases 2, 3 and 6 add a destination and nothing moves.
  - It is a single registry (ordered list) of destinations, and phase 1's list has one entry.
  - Final order, from the direction: Tổng quan, Nội dung, Bài tập, Kết quả, Trò chuyện AI.
  - Unbuilt destinations do not exist. No disabled items and no "coming soon".
- **Growth path (design intent, not phase 1 scope):**
  - Phase 2 adds a `Cần xử lý` panel above the class ledger, only when something awaits approval or was rejected. When it has rows, it becomes the biggest block and the accent goes to its top row action. The ledger stays below it. With nothing to do, the panel is not rendered, because a permanently empty queue is noise.
  - Phase 3 adds late and grading-failed rows to that queue, and the "Giao bài mới" action in the panel-header right slot, which phase 1 reserves empty.
  - Phase 6 adds `Trò chuyện AI`.
  - The ledger's trailing fixed action column is not rendered in phase 1.

## 3. Content and order

Top to bottom, in one scrolling column:

1. **App bar** with `paper` ground, 56dp, and the h1 `Tổng quan` (Bitter 600, 20/28, teacher scale). See section 5 for the account control.
2. **Offline strip** (conditional, 40dp, app-wide pattern, see states).
3. **Panel `Lớp của tôi`** (`sheet`, 8dp radius, 1dp `rule` edge, padding 16):
   - **Panel header row:** title in `titleSmall` (14/20, 600) on the left, and the count `4 lớp` in Plex Mono 12 `muted` on the right. The count's figure is mono and its unit is body. The right side is a reserved slot for a later per-panel action.
   - **Table header row** (40dp, `bodySmall` 12 `muted`, sentence case, no fill, 1dp `rule` under it): `Lớp` | `Khối` | `Môn học` | `Học sinh` (right-aligned over its figures).
   - **Class rows** (min 48dp, rows grow with text scale):
     - **Lớp:** `class.name` in `titleSmall` (14/20, 600). It is the identity column, gets 35 to 45% of the width, and is never truncated (it wraps).
     - **Khối:** `gradeLevel` as a Plex Mono 14 figure, left-aligned (it is a category, not a measure).
     - **Môn học:** `subjects[]` joined with ", " in body 14, wrapping up to 3 lines. A missing or empty value shows a grey "-".
     - **Học sinh:** `studentUids.length` in Plex Mono 14, right-aligned. A real zero prints "0".
- **Order:** ASSUMPTION: classes are sorted by `gradeLevel` ascending (numeric), then `name` in `vi` collation, so "7A, 7B, 10A" is right.
- **Realistic ranges:**
  - 1 to 8 classes is typical, and about 15 is the maximum.
  - 1 to 4 subjects per class.
  - 20 to 45 students per class, and 0 is possible.
  - There is no cap or "Xem tất cả": this is the only screen where classes are listed, so it states the total and shows all rows.
- **Rows are not tappable.** There are no chevrons and no hover or press states, because no class-detail destination exists. Inert rows must not look interactive.

## 4. Layout per breakpoint

Width decides, never orientation (Material classes from the direction). Gap between blocks is 16 and panel padding is 16 (teacher density).

| Class | Width | Navigation | Gutter | Panel |
| --- | --- | --- | --- | --- |
| compact | <600 | No bottom bar in phase 1 (see assumption); app bar only | 16 | Full width, **stacked rows** |
| medium | 600 to 839 (800x1280 portrait: 88 rail + 24 + 664 + 24) | 88dp `NavigationRail`, labels shown, one destination | 24 | 664 wide, table fits |
| expanded | 840 to 1199 | 88dp rail | 32 | Max 760, left-aligned |
| large | >=1200 (1280x800 landscape: 240 + 32 + 976 + 32) | Extended 240dp rail | 32 | Max 760, left-aligned; the remaining ~216dp stays empty `paper` |

- **Why the panel is not stretched:** the direction says a table of five columns or fewer does not stretch past about 760dp. It would pair with a next block, but phase 1 has no honest next block, and I will not invent filler. ASSUMPTION below.
- **Stacked rows** (compact, and any width where the four columns' minimums do not fit, such as 150% or more text scale at 664):
  - Row is min 64dp, with two lines.
  - Line 1 is the class name on the left and `32 học sinh` on the right (mono figure plus body unit).
  - Line 2 is `Khối 7 · Toán, Vật lý` in `muted`, wrapping.
  - The table header row is dropped, because each value now carries its unit or label.
  - Text scale up to 200% reflows by growing row height and never clips.
- **Rail contents, by class:**
  - **Large (extended 240dp):**
    - Top: the 24dp index-card mark plus the "EduBox" wordmark (Bitter 600, 20).
    - Scope: teacher name (`titleSmall`) with `Giáo viên` in `muted` under it.
    - Destinations: `Tổng quan` (`dashboard_outlined`, 20dp, `muted`) in the neutral `active` pill. No accent and no left bar.
    - Bottom user row: email in `muted` 12, then a `Đăng xuất` TextButton (ink label, `logout_outlined` 18dp, 48dp target).
  - **Medium and expanded (88dp):**
    - Top: only the mark glyph, with semantics "EduBox".
    - Destination `Tổng quan` with its label.
    - No sign-out in the rail (see section 5).
  - **Compact:**
    - The mark glyph (24dp) sits at the app bar's left, with no back control because this is the root.
    - Add a `NavigationBar` (72dp) when a second destination exists.
- **Rail with one destination:**
  - From 600dp up the rail renders even with one item, so the canvas does not change width when phase 2 adds an entry.
  - It also houses the scope and mark per the binding direction.
  - Rejected alternative: the parent's "no rail" (parent never grows).
- **Kiosk readiness:** wrap in `SafeArea`, never rely on the system back gesture, and nothing on screen mentions locking.

## 5. Sign-out

- **One account control per window class, never two.**
  - **Large:** the extended rail's bottom user row, with the visible labelled `Đăng xuất` button. The name is in the rail scope.
  - **Compact, medium and expanded:**
    - An app-bar trailing `MenuAnchor` (`more_vert`, tooltip `Tài khoản`, 48dp).
    - Its menu (sheet, 8dp radius, elevation 6) holds a non-interactive header with the name and email in `muted`, a rule, then a 48dp `Đăng xuất` item with a glyph.
    - Medium and expanded use this same menu, because the 88dp rail has no room for the name or email.
- **Behaviour:**
  - No confirmation dialog, because phase 1 teachers have no unsent work.
  - Tap detaches the Firestore listeners first, then signs out, so the permission-denied error state never flashes.
  - The control shows `Đang đăng xuất…` and is disabled while busy.
  - The router then returns to `sign-in`.
  - Builder note: consider clearing Firestore persistence on sign-out, since this is a shared tablet.

## 6. States (every block)

All of these live in the panel, not as full-screen replacements. The panel keeps its frame and header in every state.

| State | Treatment |
| --- | --- |
| **Loading** | Final layout, with the title, count slot and column headers shown at once. 3 rows of flat `active` bars at real value sizes (name ~120, grade ~24, subjects ~160, count ~24dp). No shimmer, no spinner, no layout shift. Semantics: a polite live region reads `teacherClassesLoading`, then announces `teacherClassesLoaded` once. The rail scope name uses the same skeleton bar if the profile is not ready, falling back to the email. |
| **Loaded** | As in sections 3 to 4. |
| **Empty** (server-confirmed, 0 classes) | Count reads `0 lớp`. A one-sentence `muted` message across the panel body, with no illustration and no action button, because teachers cannot create classes in the app (admin-provisioned). The message tells them who can fix it. Header row is hidden. |
| **Offline, data cached** | The 40dp neutral strip (`cloud_off`, never warning-grey or padlock) sits under the app bar, and rows stay fully readable. On reconnect it reads "Đã kết nối lại, đang cập nhật…" and collapses once the snapshot is no longer from cache. |
| **Offline, no cached data** | Panel body: neutral `cloud_off` and a sentence. Not an error, and no Retry, because the realtime listener resolves it on reconnect. Never show the Empty state here: a cache-miss is not "no classes", so check snapshot metadata `isFromCache` before claiming empty. |
| **Error, nothing loaded yet** | Panel body: negative 18dp glyph, one sentence, and a `Thử lại` TextButton (ink, 48dp target). While retrying, it shows an 18dp spinner and `Đang thử lại…` and is disabled. Not a full-screen error. |
| **Error after data was shown** | Rows stay visible. A single inline line above the table (negative glyph, sentence with the last-good time, and `Thử lại`). Time format is `09:14`, or `dd/MM, 09:14` if not today. |
| **Missing fields** | `subjects` empty or `gradeLevel` missing gives a grey "-". The row still renders. |

Offline and error are distinct: offline is a named condition, and error is a failed request.

## 7. Interactions and transitions

- **Interactive elements are only:** the account control (large: `Đăng xuất`), the rail destination, `Thử lại`, and the system back.
- **Realtime data:** the class list is a live Firestore listener. There is no pull-to-refresh, refresh control or sort/filter (at most 15 rows).
- **Rail destination:** tapping the selected `Tổng quan` does nothing. In phase 1 there is nothing to scroll to top for.
- **System back:** back at this root minimises the app. No "press again to exit" and no custom interception.
- **Motion:** feedback only (menu opening, press and focus), 150 to 200ms standard easing, with nothing performing an entrance. Rows arriving from loading swap in place. With `disableAnimations`, everything is instant.
- **Keyboard and tablet pointer:** tab order is account control, rail destination, `Thử lại`. Rows are not focusable and have no hover fill.

## 8. Accessibility

- **Contrast:** every token is from the verified palette (ink 16.7:1, muted 7.4:1 on sheet). Negative glyph and text are `#B3261E` at 6.5:1.
- **Targets:** every interactive target is at least 48x48dp, including the account control and `Thử lại`. Non-interactive rows are also at least 48dp tall.
- **Semantics:**
  - Each class row is one merged node reading e.g. "Lớp 7A, khối 7, môn Toán, Vật lý, 32 học sinh". Table header texts are excluded from semantics, because the row labels already carry the column names.
  - Icon-only controls have tooltips (the tooltip is the accessible name).
  - The offline strip and error line are live regions.
  - Stamps and states are always words. No status is color-only.
- **Text scale:** up to 200% reflows with no clip. Vietnamese stacked marks (e.g. "ẬẤỖỘỄ") get 4dp or more padding above text in fixed-height boxes, and `leadingDistribution: even`.
- **Guideline tests:** `androidTapTargetGuideline`, `labeledTapTargetGuideline` and `textContrastGuideline` must pass on every state above (loaded, loading, empty, offline, error).
- **E2E hooks:** a stable `teacher-home` route key (roadmap criterion 2). Fixture should give the seeded teacher 2+ classes with different subjects and student counts, plus one empty-subject edge case for the "-" state.

## 9. Copy (key and proposed Vietnamese)

All strings via `AppLocalizations` (tests look up by key). Keys marked "existing" are already in the roadmap or direction.

| Key | Vietnamese |
| --- | --- |
| `navTeacherOverview` / h1 | Tổng quan |
| `teacherClassesTitle` | Lớp của tôi |
| `teacherClassesCount` ({count}) | {count} lớp |
| `classColumnName` | Lớp |
| `classColumnGrade` | Khối |
| `classColumnSubjects` | Môn học |
| `classColumnStudents` | Học sinh |
| `classGradeValue` ({grade}), stacked layout | Khối {grade} |
| `classStudentCount` ({count}), stacked layout | {count} học sinh |
| `classRowSemantics` ({name},{grade},{subjects},{count}) | {name}, khối {grade}, môn {subjects}, {count} học sinh |
| `valueMissing` | - |
| `teacherRoleLabel` | Giáo viên |
| `teacherClassesLoading` | Đang tải danh sách lớp |
| `teacherClassesLoaded` ({count}) | Đã tải {count} lớp |
| `teacherClassesEmpty` | Bạn chưa được phân công lớp nào. Liên hệ quản trị viên của trường để được thêm vào lớp. |
| `teacherClassesOfflineNoData` | Chưa có danh sách lớp trên máy này. Danh sách sẽ hiện khi có mạng. |
| `teacherClassesError` | Không tải được danh sách lớp. |
| `teacherClassesStaleError` ({time}) | Không cập nhật được danh sách lớp. Cập nhật lần cuối {time}. |
| `retry` (existing) | Thử lại |
| `retrying` | Đang thử lại… |
| `networkOfflineStale` | Đang ngoại tuyến. Dữ liệu hiển thị có thể chưa mới nhất. |
| `networkReconnecting` | Đã kết nối lại, đang cập nhật… |
| `accountMenuTooltip` | Tài khoản |
| `signOut` (existing, shared with `account-not-set-up`) | Đăng xuất |
| `signingOut` | Đang đăng xuất… |
| `appMarkSemantics` | EduBox |

Note: `networkOfflineStale` differs from the direction's `networkOffline` ("...Tài liệu đã tải về vẫn mở được."). That second sentence is about downloaded documents, which teachers don't have, so I use a teacher-accurate variant.

## 10. What is NOT on this screen

- No greeting (the student home is the only greeting).
- No count tiles, stats, charts or "tasks done" figures.
- No "Cần xử lý" panel in phase 1: a queue with nothing actionable would be a lie.
- No search, bell or avatar cluster.
- No disabled or "coming soon" destinations or tiles.
- No create-class or edit-class action, since accounts and classes are provisioned by the admin script.
- No per-class student list.
- No class-detail navigation: no chevrons, tap states or row hover.
- No sort or filter controls, pagination, pull-to-refresh or FAB.
- No illustration, mascot or padlock.
- No confirmation dialog on sign-out.

## 11. Constraints and open points for the builder

- Role routing already guarantees only teachers reach this route (token-refreshed claim). A non-teacher never sees this screen.
- If `classes.gradeLevel` is a string rather than an integer, print it as-is and sort lexically after the numeric ones. This is a data-type question the seed will answer.
- The shell is the real deliverable of phase 1 for later phases. Build it as a destination registry plus an `EduDensity` teacher instance, with slots: app-bar actions (account only), offline strip, panel-header right slot.

---

## ASSUMPTION list

1. ASSUMPTION: the phase-1 block is titled `Lớp của tôi` rather than `Cần xử lý` (alternatives: `Cần xử lý` titled "my classes" as the direction table literally says, kept empty of actions). Because nothing can need action in phase 1; `Cần xử lý` arrives in phase 2 above it.
2. ASSUMPTION: no dominant accent on phase-1 `teacher-home` (alternatives: accent a class count or the h1 rule). The screen has no primary action or data that matters most.
3. ASSUMPTION: the teacher rail renders at every width of 600dp or more with a single destination, and compact has no bottom bar until a second destination exists (alternatives: no rail until phase 2 like the parent shell; a one-item bottom bar).
4. ASSUMPTION: sign-out lives in one place per window class: the extended rail's bottom user row at large, an app-bar account menu (name, email, `Đăng xuất`) elsewhere (alternatives: sign-out in the 88dp rail with a label; a permanent app-bar text button).
5. ASSUMPTION: no confirmation dialog on sign-out (alternatives: confirm dialog; confirm only when work is unsynced, relevant from phase 3).
6. ASSUMPTION: the class table is left-aligned at max 760dp with no companion panel (alternatives: stretch to the full canvas; pair with an account or profile panel).
7. ASSUMPTION: no row cap or "Xem tất cả"; all classes are shown with a count (alternatives: cap at 6 with a link to a classes screen that doesn't exist).
8. ASSUMPTION: class rows are non-interactive in phase 1 (alternatives: tappable rows opening a class-detail stub).
9. ASSUMPTION: classes sort by numeric `gradeLevel` ascending, then `name` with `vi` collation (alternatives: Firestore insertion order; name only).
10. ASSUMPTION: `gradeLevel` is shown as a Plex Mono figure with header `Khối`, and as `Khối {n}` in the stacked layout (alternatives: "Lớp 7"-style prefix, or a prose cell).
11. ASSUMPTION: the compact and reflow layout is stacked two-line rows with no table header (alternatives: horizontal table scroll; dropping the Môn học column).
12. ASSUMPTION: live Firestore listener with no pull-to-refresh or manual refresh control (alternatives: pull-to-refresh; refresh button).
13. ASSUMPTION: empty state gives no in-app action and points to the school admin (alternatives: a "Liên hệ" mailto, or stating nothing beyond the sentence).
14. ASSUMPTION: offline with no cache shows a neutral explanatory block, not Empty or Error, and has no Retry (alternatives: show Retry; reuse the Error pattern).
15. ASSUMPTION: error after data was shown keeps the rows and adds an inline error line with the last-good time (alternatives: replace the table with the error block).
16. ASSUMPTION: a teacher-specific offline strip key `networkOfflineStale` instead of the shared `networkOffline` (alternatives: reuse the shared string unchanged).
17. ASSUMPTION: the role label `Giáo viên` sits under the name in the large rail scope (alternatives: name only).
18. ASSUMPTION: rows may show a total count only for classes, with no distinct-student total across classes (alternatives: "128 học sinh" total, which is ambiguous when one student is in several of the teacher's classes).
19. ASSUMPTION: table header texts are excluded from semantics because each row label already carries its column names (alternatives: Flutter table semantics with headers).
20. ASSUMPTION: system back at the root minimises the app with no intercept (alternatives: double-back-to-exit).
