<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

> Backend changed on 2026-10-29: Firebase is replaced by a Serverpod server with PostgreSQL (see the amended spec). Read every Firestore, snapshot, `isFromCache`, custom-claim, or Firebase error reference below as its equivalent in the phase 1 contract: the app's local store and outbox, the server-stored role, and the contract's error shapes. The screen behavior and states are unchanged.

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- Phase 1 content: greeting, class and date, then the "Mới thêm vào thư viện" panel with the 4 newest approved items, the total, and "Mở thư viện".
- Content rows are not tappable in phase 1.

# Shape brief: `student-home` (phase 1)

Mode: Operate. This is a daily task surface, so ambition shows as restraint and precision.

No user was available, so every choice the flow would have asked about is marked `ASSUMPTION:` inline. All of them are repeated at the end.

Binding sources: `docs/design/app-direction.md` (the achromatic-ledger direction and sections 2, 5, 6.1, 8 and 9), `PRODUCT.md`, the seed `DESIGN.md`, the roadmap phases and Rulings, and the phase 1 spec.

## 1. Job and audience

**Who arrives:** a student on a 10-11" tablet, in class or at home, just after sign-in. They may be young, on a shared or older tablet, and want to get to the material quickly.

**The screen's one question** (app-direction section 2): "What should I study next?"

**What phase 1 can honestly answer:**
- There are no assignments (phase 3), no last-opened lesson (no reader until phase 2 and no `progress` docs until phase 3), no tutor and no tests.
- The only true answer is "here is what your teachers have approved for your class."
- So the biggest block on the phase 1 home is a library panel. It holds the newest approved items and one primary action, "Mở thư viện".
- This deliberately replaces the section 2 table's "Tiếp theo panel" for phase 1 only. The table's end state stays binding; section 6 below says how it takes over.

**The home is thin, and that is accepted.**
- It earns its place with identity (name, class, date), orientation, and a fast way into the library.
- It must not be padded with decoration, teasers or counts to look fuller.

**Success:**
- Within one second the student knows who and where they are (name, class) and what is available.
- One tap takes them to the library.

## 2. Outcome and proof

- E2E: the seeded student signs in and lands on `student-home`. It shows the greeting with their given name, their class name, and at most 4 of the newest approved items for their class, with the draft and other-class fixtures absent. "Mở thư viện" opens `student-library`.
- E2E: "Đăng xuất" is reachable at every breakpoint and returns to `sign-in`.
- Accessibility guideline tests (tap target, labeled tap target, contrast) pass in loaded, loading, empty, error and offline states.

## 3. Selected direction

**Visual authority:** the existing direction, with no new visual world.
- Surfaces: `paper` ground, `sheet` panel, 1dp `rule` edge, flat, 8dp radius.
- Type: Bitter for the greeting, Be Vietnam Pro for everything else, Plex Mono only for stamps and aligned figures.
- Accent: the single dominant accent goes to the "Mở thư viện" `FilledButton`.

**Structural thesis:**
- The home is a vertical stack of data-driven sections in a fixed priority order. A section renders only when its feature exists.
- Phase 1 renders exactly one section, the library panel.
- Later phases add sections above it. Nothing is redesigned.

**Focal moment:** the greeting "Chào Minh" as the h1, then the single panel. There are no tiles and no illustration.

## 4. Student shell and navigation

The shell is owned by a shared student-shell widget (not by this screen). Home is the first destination.

**Destination registry.**
- The shell renders from an ordered list of `StudentDestination { id, labelKey, outlinedIcon, route }`.
- Order is fixed for all phases: Trang chủ, Thư viện, Bài tập, Gia sư AI.
- A destination is registered only in the phase that ships its screen.

| Phase | Destinations shown |
| --- | --- |
| 1 | Trang chủ, Thư viện (2) |
| 3 | + Bài tập |
| 4 | + Gia sư AI |

- Tests (phase 5) live under Bài tập, because test assignments are assignments. They get no new destination.
- The shell code must not hardcode 4. This is what lets later destinations slot in with no layout rework.
- No disabled or "sắp có" placeholders. A greyed destination would invite a dead tap and is a "coming soon" tile by another name, which PRODUCT.md rules out.
  - `ASSUMPTION: two destinations in phase 1, no placeholders for Bài tập or Gia sư AI (alternatives: show all four with disabled items and a reason; show a "sắp có" stamp).`
- Material suggests 3-5 destinations, but Flutter `NavigationBar` and `NavigationRail` both allow 2. The rail and bar look a little sparse for two phases; that is acceptable.

**Per window class** (width decides, per app-direction section 5):

| Class | Navigation | Where identity and sign-out live |
| --- | --- | --- |
| large, >= 1200 | `NavigationRail(extended: true)`, 240dp. Top: mark, wordmark, then scope "Lớp 7A". Then destinations. | Bottom of the rail: an initials disc, the full name and class, and a visible "Đăng xuất" `TextButton` (48dp). |
| expanded and medium, 600-1199 | `NavigationRail`, 88dp, labels shown. Top: the mark. | Rail trailing slot: a 48dp initials-disc `IconButton`, tooltip "Tài khoản", opening a `MenuAnchor`. |
| compact, < 600 | `NavigationBar`, 72dp, labels always shown, 1dp `rule` top edge | 56dp app bar on `paper`: mark and wordmark left, the same initials-disc menu button right. |

- The menu holds the name (`titleMedium`), the class in `muted`, a rule, then "Đăng xuất".
- Selecting "Đăng xuất" opens the confirm dialog (section 7).
- The scope text is the class name, with no teacher name or other reads.
- Each destination keeps its own scroll position (`StatefulShellRoute` or an `IndexedStack`).
- The home has no app bar on medium and up, because the greeting is the h1. On compact the app bar carries only the mark and the user button, never a title.
- No search bar, bell or avatar cluster (section 6 rule).

## 5. Content and order (phase 1)

Top to bottom inside one centred column, max 760dp:

1. **Greeting block** (always rendered)
   - h1 "Chào An" in Bitter 28/36 (`displayMedium`).
   - Under it, one `muted` `bodyLarge` line: "Lớp 7A · Thứ Năm, 29/10/2026". The class comes first, then the date as weekday in words plus `dd/MM/yyyy`.
   - No emoji, no counts, no streaks, no motivational line.
   - `ASSUMPTION: the greeting uses the given name, the last word of the Vietnamese full name ("Nguyễn Minh An" becomes "An"), with the full name in the user menu (alternatives: first token; full name; "Em" with no name).`
   - The class name also sits in the body because the compact layout has no rail scope.
   - If the student has more than one class, show the names comma-separated and truncated with an ellipsis; the full list goes in the semantics label.
     - `ASSUMPTION: seeds give one class per student, so multi-class is handled only by truncation (alternatives: show a class picker; show only the first class).`
2. **Gap 24** (the home's single gap value).
3. **Library panel** (`sheet`, padding 24)
   - Header: "Mới thêm vào thư viện" (`titleLarge`), and under it in `bodySmall` `muted` "23 tài liệu cho lớp em".
   - The newest approved items for the student's classes, at most 4, ordered by `createdAt` descending. They are the same `ContentRow` widget as `student-library`, 72dp, with 1dp `rule` between rows:
     - A 48 x 64dp cover slot: an `active` rectangle, radius 4, with a 20dp outlined type glyph in `muted`, since phase 1 has no cover images. It is replaced by the image when covers exist.
     - Title in `titleMedium` 16/24, up to two lines.
     - Meta in `bodySmall` `muted`: "Sách · Toán" (type word, then subject).
     - A reserved trailing column holding no stamp in phase 1. Availability stamps arrive in phase 2 with no layout change.
   - Footer: "Mở thư viện", a `FilledButton` in accent, 56dp tall, left-aligned, intrinsic width with a 160dp minimum (full width on compact).
   - The rows are not tappable in phase 1: there is no `student-content-detail` yet, and a dead tap is worse than a static row. The only interactive element in the panel is the button. In phase 2 the rows become tappable.
     - `ASSUMPTION: home rows are static in phase 1, no ripple and no chevron (alternatives: tap goes to the library; tap goes to a stub detail).`
   - If there are 4 or fewer items, show them all.
   - Counts here are catalogue size (what is available), not engagement. They state a fact the student acts on and carry no progress meaning.
   - Both the 4-row preview and the "Mới thêm" ordering are assumed.
     - `ASSUMPTION: the panel is "newest 4" (alternatives: a list of subjects with item counts; a button only; most recently opened, which is impossible before the reader exists).`
   - The home and library share one library provider (same query and cache). The home takes the first 4 and the length, so it makes no second query.
     - `ASSUMPTION: the total comes from the shared library query's length, not a Firestore count() aggregation, which is unavailable offline (alternatives: count aggregation; no total).`

Nothing else renders in phase 1.

## 6. How the home grows (no redesign)

Section order, fixed. A section renders only if its source exists in the current build, and when its source has no data it shows its own designed empty sentence.

1. "Tiếp theo" (phases 2-3): the next assignment, or the last-opened lesson. When it exists it takes the accent via its "Tiếp tục" button. "Mở thư viện" then demotes to an `OutlinedButton`, preserving the one-accent rule.
2. "Bài tập sắp đến hạn" (phase 3): at most 4 rows plus "Xem tất cả".
3. "Đọc gần đây" (phase 2): needs a source for opens. The contract must decide this, because `progress` docs arrive only in phase 3.
4. "Mới thêm vào thư viện" (this phase). It stays as the last section.

At large width, sections 2 and 3 may pair side by side only if each stays >= 340dp. Otherwise they stack.

## 7. Layout per breakpoint

Gap is 24 both ways. The panel is `sheet`, 1dp `rule` edge, radius 8, no shadow. Section spacing is 48 between unrelated sections.

| Class | Canvas | Home layout |
| --- | --- | --- |
| large, >= 1200 (1280 x 800: 240 rail + 32 + 976 content + 32) | 976dp | One column capped at 760dp, centred in the 976dp content area. Top padding 32. Greeting about 72dp, +24, panel about 8 + 26 + 18 + 4 x 72 + 56 + padding, roughly 480dp. Everything including the button fits within ~728dp of height, even with the 40dp offline strip. |
| expanded, 840-1199 (960 x 600) | width - 88 - 64 | The same single column, max 760dp. Content is about 808dp wide at 960, so it stays centred at 760. At 600dp height the button may sit just below the fold. The panel scrolls, and this is acceptable because the 4th row is not essential. |
| medium, 600-839 (800 x 1280: 88 rail + 24 + 664 content + 24) | 664dp | One column, fills 664dp. There is plenty of vertical space. |
| compact, < 600 | width - 32 | 56dp app bar, 16 gutter, panel padding 24 (16 when the viewport is narrower than 360dp). Greeting may wrap to two lines. The button is full width. `NavigationBar` at the bottom. |

- Nothing is clipped at 200% text scale: rows grow in height and long titles wrap to two or three lines.
- The home is a `ListView` / `SingleChildScrollView`, with `SafeArea` and the bottom bar inset respected.
- No two-pane layout on the home in phase 1.

## 8. States (each is designed, not defaulted)

The shell-level app start ("Đang mở EduBox…") is out of scope here.

| State | Behavior |
| --- | --- |
| **Loading** (users, class and library resolving) | The final layout. The weekday and date show at once. The greeting shows "Chào" plus an `active` bar where the name goes, and a bar for the class name. The panel keeps its header and button, with 4 flat `active` row skeletons at the real 72dp height. No shimmer and no spinner. The button is enabled, since the library works on its own. Semantics: one node "Đang tải thư viện", the bars excluded. When fewer than 4 rows load, the panel shrinks, which is accepted. A refresh keeps the old values visible. |
| **Loaded** | As in section 5. |
| **Empty: no class** | Greeting shown, with the date line without a class name. The panel keeps its frame and header. In the body: "Em chưa được xếp vào lớp nào." and a second `muted` sentence "Hãy nhờ giáo viên thêm em vào lớp." No button, because there is no library to open. |
| **Empty: class with no approved content** | The panel keeps its frame and header, with a one-sentence body "Thư viện của lớp chưa có tài liệu nào." and a `muted` hint "Khi giáo viên duyệt tài liệu, tài liệu sẽ hiện ở đây." "Mở thư viện" is still shown, because the library screen has its own empty state. No illustration. |
| **Offline, with cached data** | Everything renders from the Firestore cache. The shell's 40dp strip appears under the app bar, or at the top of the canvas on rail layouts: "Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được." The home adds nothing of its own. The strip is shell-level and not dismissible while offline. |
| **Offline, nothing cached** | The panel shows the error pattern (below) with the sentence "Không tải được thư viện vì đang ngoại tuyến." and "Thử lại". |
| **Reconnecting** | The strip reads "Đã kết nối lại, đang đồng bộ…" and collapses once the queue empties. The data refreshes in place. |
| **Error with retry** | Inside the failed block, never a full screen. An 18dp negative glyph, one sentence naming what failed, the last-good time when known ("Cập nhật lần cuối 09:14."), and a "Thử lại" `TextButton` (48dp). The retry re-subscribes the library query. |
| **Profile or class fails to load** | The greeting falls back to "Xin chào" and the date line shows only the date. The panel body becomes one error block "Không tải được thông tin tài khoản." with "Thử lại". The library cannot load without class IDs, so the two failures collapse into one block rather than two. Sign-out stays available. |
| **Partial** | Greeting present with the library failed: only the panel shows the error. |
| **Rows beyond 4** | The 5th and later rows are not rendered; the total in the header covers them. |
| **Sign-out in progress** | The dialog's confirm button reads "Đang đăng xuất…", is disabled, and shows an 18dp progress indicator inside. |
| **Sign-out fails** | An inline negative sentence inside the dialog: "Không đăng xuất được. Hãy thử lại." The dialog stays open. No `SnackBar`, since it needs action. |

**Sign-out dialog.**
- Title: "Đăng xuất khỏi EduBox?".
- Body: "Em sẽ cần nhập lại email và mật khẩu để vào lại."
- When offline it adds: "Đang ngoại tuyến nên em sẽ chưa đăng nhập lại được cho tới khi có mạng."
- Actions: "Hủy" (outlined) and "Đăng xuất" (ink-filled, since the screen's accent is already spent on "Mở thư viện").
- Reason for the confirm step: with a cached session, an offline sign-out locks the student out until they get a connection.
- In phase 3 and later, add the pending-sync count to the body when it is non-zero.
- Hitting "Hủy" or the barrier dismisses the dialog.
  - `ASSUMPTION: sign-out asks for confirmation, with an offline warning (alternatives: immediate sign-out; undo snackbar).`

## 9. Interactions and feedback

- "Mở thư viện" is a plain push to the Thư viện destination. It selects the destination in the rail or bar instead of pushing a new route, so the rail state and scroll are consistent.
- Selecting Trang chủ in the shell returns to the top of the home.
- Press, focus and menu opening use 150-200ms standard easing. Nothing performs an entrance. When animations are disabled, everything is instant.
- Skeleton bars to data have no layout shift except the row-count shrink noted above.
- There is no pull-to-refresh, because the data is live from the Firestore stream. "Thử lại" is the only manual refresh.
- Background and foreground resume does nothing visible.

## 10. Accessibility

- The greeting is the screen's one heading (`Semantics(header: true)`). Its label is "Chào An, Lớp 7A, Thứ Năm, 29/10/2026".
- Each row is one semantics node: "{title}, {type}, {subject}". The cover and glyph are excluded. There is no "button" role in phase 1, because the rows are static.
- The user menu `IconButton` has a tooltip "Tài khoản", which is its accessible name. The menu items are 48dp.
- The offline strip and the error block are polite live regions, announced once when they appear.
- All targets are >= 48 x 48dp, and the primary button is 56dp.
- Contrast is covered by the direction's tokens: ink 15.30:1, muted 6.77:1 on paper, white on accent 8.44:1.
- Text scales to 200% and reflows. Vietnamese marks are not clipped (line height >= 1.33, `leadingDistribution: even`, >= 4dp padding in fixed-height boxes; the Vietnamese mark golden test covers the greeting).
- Focus order is: user menu or rail, destinations, greeting, then the panel's button. Keyboard and D-pad focus show the 2dp accent ring.
- Every string, tooltip and semantics label comes from `AppLocalizations`.

## 11. Copy and l10n keys (proposed Vietnamese; the key is the contract)

| Key | vi |
| --- | --- |
| `navHome` | Trang chủ |
| `navLibrary` | Thư viện |
| `studentHomeGreeting` (`name`) | Chào {name} |
| `studentHomeGreetingNoName` | Xin chào |
| `studentHomeDateLine` (`className`, `date`) | {className} · {date} |
| `studentHomeDateOnly` (`date`) | {date} |
| `studentHomeLibraryTitle` | Mới thêm vào thư viện |
| `studentHomeLibraryCount` (`count`) | {count} tài liệu cho lớp em |
| `studentHomeOpenLibrary` | Mở thư viện |
| `libraryEmpty` (existing) | Thư viện của lớp chưa có tài liệu nào. |
| `libraryEmptyHint` | Khi giáo viên duyệt tài liệu, tài liệu sẽ hiện ở đây. |
| `studentNoClass` | Em chưa được xếp vào lớp nào. |
| `studentNoClassHint` | Hãy nhờ giáo viên thêm em vào lớp. |
| `studentHomeLoadingLibrary` (semantics) | Đang tải thư viện |
| `studentHomeLibraryError` | Không tải được thư viện. |
| `studentHomeLibraryOfflineNoCache` | Không tải được thư viện vì đang ngoại tuyến. |
| `studentHomeProfileError` | Không tải được thông tin tài khoản. |
| `lastUpdatedAt` (`time`) | Cập nhật lần cuối {time}. |
| `retry` (existing) | Thử lại |
| `networkOffline` (proposed in the direction) | Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được. |
| `accountMenuTooltip` | Tài khoản |
| `signOut` | Đăng xuất |
| `signOutBusy` | Đang đăng xuất… |
| `signOutConfirmTitle` | Đăng xuất khỏi EduBox? |
| `signOutConfirmBody` | Em sẽ cần nhập lại email và mật khẩu để vào lại. |
| `signOutOfflineWarning` | Đang ngoại tuyến nên em sẽ chưa đăng nhập lại được cho tới khi có mạng. |
| `signOutFailed` | Không đăng xuất được. Hãy thử lại. |
| `cancel` | Hủy |
| `contentTypeEbook` | Sách |
| `contentTypeVideo` | Video |
| `contentTypeExercise` | Bài tập |
| `contentRowSemantics` (`title`, `type`, `subject`) | {title}, {type}, {subject} |

- Copy addresses the student as "em" and teachers as "giáo viên", per the direction.
- Dates come from `intl` `vi` (`EEEE, dd/MM/yyyy`), and times are 24-hour.

## 12. What is NOT on this screen

- Streaks, badges, points, counts of finished work, progress percentages, or any metric framed as achievement.
- "Coming soon", disabled or teaser items for assignments, the tutor or tests, and no shortcut tiles to future destinations.
- Mascots, illustration, emoji, confetti, motivational quotes, tips.
- Search bar, bell, notifications, avatar cluster, and unread or "new" badges on items.
- Padlock or "restricted device" iconography and warning banners.
- Filters, sorting, subject tabs, downloads, or item actions (these belong to the library and, in phase 2, the content detail).
- Teacher name, classmates, class roster.
- Pull-to-refresh and any spinner outside a busy button.
- A full-screen error. Errors stay inside their block.

## 13. Constraints and open decisions for builders

- The shell registry and the offline strip are shared components, not per-screen code.
- The `ContentRow` widget is shared with `student-library`. Its type and subject meta lines and the empty cover slot must match exactly.
- Home and library share one library provider.
- A student with no `role` claim never reaches this screen (that is `account-not-set-up`).
- Tokens come from the theme, never hex literals.
- No new package is required.
- Open, for the phase 2 and 3 contracts and not this screen: what record backs "Tiếp theo" and "Đọc gần đây" before `progress` docs exist.
- No product decision is blocked, so there is no `DECISION` entry.

## ASSUMPTION lines

1. `ASSUMPTION: two destinations in phase 1, no placeholders for Bài tập or Gia sư AI (alternatives: show all four with disabled items and a reason; show a "sắp có" stamp).`
2. `ASSUMPTION: the greeting uses the given name, the last word of the Vietnamese full name ("Nguyễn Minh An" becomes "An"), with the full name in the user menu (alternatives: first token; full name; "Em" with no name).`
3. `ASSUMPTION: seeds give one class per student, so multi-class is handled only by truncation (alternatives: show a class picker; show only the first class).`
4. `ASSUMPTION: the panel is "newest 4" (alternatives: a list of subjects with item counts; a button only; most recently opened, which is impossible before the reader exists).`
5. `ASSUMPTION: home rows are static in phase 1, no ripple and no chevron (alternatives: tap goes to the library; tap goes to a stub detail).`
6. `ASSUMPTION: the total comes from the shared library query's length, not a Firestore count() aggregation, which is unavailable offline (alternatives: count aggregation; no total).`
7. `ASSUMPTION: sign-out asks for confirmation, with an offline warning (alternatives: immediate sign-out; undo snackbar).`

Three smaller choices are stated in the body without an ASSUMPTION marker:
- On medium and up the home has no app bar.
- On compact the app bar carries only the mark and the user button.
- The user menu opens from a rail trailing initials disc on medium and expanded, and from an app bar disc on compact.
