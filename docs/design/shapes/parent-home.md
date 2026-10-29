<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- Phase 1 content: the "Học sinh" label and the linked child's name only, with no forward-looking copy.

# Shape brief: `parent-home` (phase 1)

Mode: Operate, in the product register. There was no user to interview, so every choice that would have been a question is marked `ASSUMPTION`. No `DECISION` stops were needed.

## 1. Job and audience

- **Who arrives:** a parent, rarely and briefly, on a tablet that may be shared or the child's own. They have just signed in and want to know the account is set up and linked to the right child.
- **The one question** (from the direction's per-screen table): "Whose record is this?" The screen answers it with the linked child's name and nothing else.
- **Primary action:** none. The accent is not used on this screen, per the table.
- **Honest scope:**
  - Phase 1 delivers only a role-gated landing with a verified link.
  - The parent's own `users` doc carries `linkedStudentUid` and `linkedStudentName` (roadmap ASSUMPTION, 2026-10-29).
  - The parent cannot read the child's `users` doc or `classes`. The screen therefore has the name and nothing else true to show.

## 2. The central decision: say nothing about what is coming

**The screen does not mention results, AI chat history, or "coming soon".**

- `docs/design/app-direction.md` §6.3 is binding: "the child's name ... and nothing else; no placeholder dashboard, no 'coming soon' tiles."
- PRODUCT.md says the product should not "look like a demo". A promise about future features is exactly what makes a stub look like one.
- A parent in phase 1 has no running expectation to manage. A line such as "Kết quả sẽ hiển thị tại đây" promises something the build may not deliver on this device, and the feature set is explicitly unscoped (roadmap line 184).
- The screen stays truthful. It confirms the sign-in and the link, and it claims nothing else.
- To stop it reading as unfinished, it is composed as a deliberate single "record header", not an empty dashboard:
  - One `sheet` panel holds a form-style label ("Học sinh") above the name, like the label-over-value of a school record card.
  - The panel is top-aligned, not centred in the canvas.
  - There are no skeleton tiles, ghost cards, illustration or empty-state text.
- Phase 6 replaces the screen outright (`parent-summary`), so nothing here needs to anticipate it.

`ASSUMPTION: no forward-looking copy on the phase 1 screen (alternatives: one muted sentence "Kết quả và lịch sử trò chuyện với gia sư AI sẽ xuất hiện tại đây"; a sentence on the home that links nowhere)`

## 3. Content and order (top to bottom, one column)

1. **App bar** (64dp, `paper`, elevation 0, centreAligned false).
   - Left: the mark and the "EduBox" wordmark.
   - Right: a 48dp overflow `IconButton` (`more_vert`, outlined) with a single item, "Đăng xuất".
   - The direction puts the child's name and class in the app bar as scope. On this screen the name is already the h1, so the app bar scope is omitted here. It returns on phase 6 screens, where the h1 is something else.
2. **Offline strip** (40dp, app-wide pattern, owned by the shell). It sits directly under the app bar while offline and is not designed here.
3. **Record panel** (`sheet`, 1dp `rule` edge, radius 8, padding 24, elevation 0), 24dp below the app bar or strip:
   - Label: "Học sinh", Be Vietnam Pro 400, 14/20, `muted`.
   - 8dp gap.
   - Name: `headlineLarge` (Bitter 600, 24/32), `ink`. It is the screen's h1.
   - No class line (see the next paragraph).
4. Nothing else. The rest of the canvas is plain `paper`.

**The class is not shown.**

- The direction says "name and class in `muted`". The parent role cannot read `classes` or the child's `users` doc.
- Only `linkedStudentName` is available.
- Phase 1 therefore shows the name alone.

`ASSUMPTION: show the name only because linkedStudentName is the only linked-child field the parent may read (alternatives: have the seed also write linkedStudentClassName on the parent doc so the direction's "Lớp 7A" line can render, which is a small schema addition the contract architect would own)`

`ASSUMPTION: "Học sinh" label above the name, as a form-style label and not a status stamp (alternatives: no label and the name alone; "Phụ huynh của" as an eyebrow)`

`ASSUMPTION: omit the app bar scope on parent-home to avoid printing the name twice (alternatives: keep the scope in the app bar and render the h1 as the label only)`

## 4. Layout per breakpoint

Width decides layout, never orientation. There is no rail in the parent shell.

| Class | Width | Gutter | Behaviour |
| --- | --- | --- | --- |
| compact | < 600 | 16 | The panel is full width between gutters and the app bar is 64dp. The panel padding stays 24 (the direction fixes parent panel padding at 24), and the name wraps freely. |
| medium | 600-839 (800 x 1280 portrait) | 24 | The column is the full 752dp, centred, with 24 above. |
| expanded | 840-1199 | 32 | The column is capped at 760dp and centred. |
| large | >= 1200 (1280 x 800 landscape) | 32 | The same 760dp centred column; `paper` fills both sides. |

- The panel hugs its content in height and is never stretched.
- It is top-aligned, 24dp under the app bar or strip. Vertical centring would read as a splash or a placeholder.
- Everything sits inside `SafeArea` and works with the system bars hidden (kiosk readiness).
- The body scrolls (`SingleChildScrollView` or sliver) so that 200% text scale cannot clip.
- Text scale up to 200%:
  - The name wraps to as many lines as needed (never ellipsis, since it is the content).
  - The label stays above the name.
  - Long Vietnamese names with stacked diacritics get the 32 line height, and the panel grows.

## 5. States

All states live inside the panel except the offline strip. None is full-screen, per §8. The panel keeps its frame and its "Học sinh" label in every state.

| State | What shows | Keys and copy |
| --- | --- | --- |
| **Loading** | The label is shown at once. The name is replaced by a flat `active` bar at the real name size (about 240 x 24, one line). There is no shimmer and no spinner, and the layout does not shift when the name lands. The subscription resolving from cache is effectively instant. | `parentHomeStudentLabel` "Học sinh" |
| **Loaded** | Name in ink as the h1. | |
| **No linked child** (seed error: `linkedStudentUid` or `linkedStudentName` is missing, empty or whitespace) | The name slot is replaced by one `bodyLarge` sentence in `ink`. There is no negative colour and no glyph. It is a data-setup fault and nothing is wrong in the parent's hands. A "Thử lại" `TextButton` re-reads the doc, in case the seed or admin fixed it. "Đăng xuất" stays reachable in the app bar. This is not `account-not-set-up`, which covers a missing role claim. | `parentHomeNoChild` "Tài khoản này chưa được liên kết với học sinh nào. Hãy liên hệ nhà trường để được hỗ trợ." and `retry` "Thử lại" |
| **Offline, name cached** | The normal loaded view. The shell's strip says "Đang ngoại tuyến..." (`networkOffline`). The screen adds nothing, because the name is static data and a cached name is current. | |
| **Offline, nothing cached** (first sign-in on this device while offline, the read cannot resolve) | The `cloud_off` 18dp glyph in `muted` plus one sentence, then "Thử lại". It is neutral because offline is not a fault. | `parentHomeOfflineNoData` "Chưa có thông tin học sinh trên máy này. Hãy kết nối mạng để tải." and `retry` |
| **Error with retry** (read failed while online) | The negative 18dp `error_outline` glyph, one sentence, and "Thử lại". There is no "last updated" clause, because nothing was ever good. If a cached name exists the screen keeps showing it and does not enter the error state. | `parentHomeLoadError` "Không tải được thông tin học sinh." and `retry` |

- Retry sets the panel back to Loading (skeleton bar) and re-reads once.
- It is a `TextButton` with a 48dp target, aligned left under the sentence, with 16dp above it.
- Error and no-child sentences get `Semantics(liveRegion: true)` so a screen reader announces the change.

`ASSUMPTION: "no linked child" is neutral (no negative glyph) while a failed read is negative (alternatives: negative for both; treat no-child as full account-not-set-up and sign the user out)`

`ASSUMPTION: no pull-to-refresh and no manual refresh control, since the name is static and parent use is low-frequency (alternatives: pull-to-refresh)`

## 6. Interactions

- **Sign-out** is in the app bar overflow menu, per the direction.
  - The menu is a standard M3 popup, radius 8, with a shadow (it floats).
  - The single item is "Đăng xuất" (`signOut`). It is a text row with no icon in the accent, in `ink`.
  - Choosing it signs out immediately and routes to `sign-in`. There is no confirm dialog, because it is reversible and the user is just a parent with a password.
  - A failed sign-out is rare. If it happens, show a `SnackBar` with a retry action and keep the user on the screen.
- A one-item overflow menu is slightly hidden. That is acceptable here because the direction binds it and the screen is otherwise empty. It matters most in the no-child and error states, where the parent may be on the wrong account. The overflow is always present and is the only control in the app bar.
- The panel is not tappable. It has no hover, ripple or chevron, because it implies no navigation.
- Motion: only the menu opening, 150-200ms. When `disableAnimations` is on, it is instant. The name fading in is not an entrance animation (nothing performs an entrance); the skeleton bar is simply swapped for the text.

## 7. Accessibility

- The name is the single h1 (`Semantics(header: true)`), merged with its label into one node whose label is "Học sinh: {name}" via `parentHomeStudentSemantics` (proposed).
- Focus and traversal order: app bar mark and wordmark (one labelled node), overflow, then the panel.
- The overflow button's tooltip and semantics label are l10n `parentMenuTooltip` "Tùy chọn".
- Contrast:
  - `ink` on `sheet` is 16.68:1.
  - `muted` on `sheet` is 7.38:1.
  - The label at 14sp is above the 12sp floor.
  - The `cloud_off` and `error_outline` glyphs are reinforced by words and never carry the state alone.
- Tap targets are at least 48 x 48dp (overflow, "Thử lại", menu item).
- Text scale up to 200% reflows without clipping.
- The Flutter guideline tests (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) pass in loaded, loading, no-child, error and offline-no-cache.
- All strings, including semantics labels and tooltips, come from `AppLocalizations`.
- The "Học sinh" label is not a status, so it does not use the Stamp face.

## 8. Copy (l10n keys and proposed Vietnamese)

| Key | Vietnamese | Note |
| --- | --- | --- |
| `parentHomeStudentLabel` | Học sinh | New |
| `parentHomeStudentSemantics` | Học sinh: {name} | New, with an ICU `{name}` placeholder |
| `parentHomeNoChild` | Tài khoản này chưa được liên kết với học sinh nào. Hãy liên hệ nhà trường để được hỗ trợ. | New |
| `parentHomeLoadError` | Không tải được thông tin học sinh. | New |
| `parentHomeOfflineNoData` | Chưa có thông tin học sinh trên máy này. Hãy kết nối mạng để tải. | New |
| `parentMenuTooltip` | Tùy chọn | New |
| `retry` | Thử lại | Existing |
| `signOut` | Đăng xuất | Existing (confirm that the key name matches the contract) |
| `networkOffline` | Đang ngoại tuyến. Tài liệu đã tải về vẫn mở được. | Existing, proposed in the direction; shell-owned |

- The tone is plain and direct. It does not use "bạn" or "em", so there is no addressing. It names a next step wherever the user can act.
- "Tài liệu đã tải về vẫn mở được" in the shell's offline strip is student-oriented. The parent has no downloads. The shell may need a role-neutral variant when it renders for the parent. Flag this to the shell owner.

## 9. What is NOT on the screen

- No "coming soon" text, tiles, ghost cards, or any mention of results, scores, AI chats or progress.
- No class, grade, avatar, initials disc, greeting ("Xin chào..."), date or last-active time.
- No rail, bottom nav or tabs. The parent shell has no navigation.
- No accent colour. The screen has no primary action and no emphasis beyond ink.
- No illustration, gradient, shadow, badge or stat.
- No create, edit or delete control, and no pull-to-refresh.
- No padlock or "read-only" notice. The parent role is read-only by construction.
- No child's UID, email, or other raw data.

## 10. Constraints and open points for builders

- Data: one stream or read of the parent's own `users/{uid}`, using `linkedStudentName` for display. The screen must not read the child's `users` doc or `classes`, because rules deny it.
- The linked state is determined by both fields being present and non-blank; that logic belongs in a repository or provider, not the widget.
- Golden or widget tests per state: loading, loaded (short and long names, 200% text scale), no-child, error, offline-no-cache, compact and large widths.
- This screen is replaced by `parent-summary` in phase 6. Keep it self-contained.
- Light theme only in phase 1.

## ASSUMPTION lines

1. `ASSUMPTION: no forward-looking copy on the phase 1 screen (alternatives: one muted sentence "Kết quả và lịch sử trò chuyện với gia sư AI sẽ xuất hiện tại đây"; a sentence on the home that links nowhere)`
2. `ASSUMPTION: show the name only because linkedStudentName is the only linked-child field the parent may read (alternatives: have the seed also write linkedStudentClassName on the parent doc so the direction's "Lớp 7A" line can render, which is a small schema addition the contract architect would own)`
3. `ASSUMPTION: "Học sinh" label above the name, as a form-style label and not a status stamp (alternatives: no label and the name alone; "Phụ huynh của" as an eyebrow)`
4. `ASSUMPTION: omit the app bar scope on parent-home to avoid printing the name twice (alternatives: keep the scope in the app bar and render the h1 as the label only)`
5. `ASSUMPTION: "no linked child" is neutral (no negative glyph) while a failed read is negative (alternatives: negative for both; treat no-child as full account-not-set-up and sign the user out)`
6. `ASSUMPTION: no pull-to-refresh and no manual refresh control, since the name is static and parent use is low-frequency (alternatives: pull-to-refresh)`

The brief also relies on four defaults that I did not mark inline:
- The panel is top-aligned, not centred.
- Sign-out has no confirm dialog.
- Sign-out lives in the app bar overflow menu, as the direction says, even though it is a one-item menu.
- Retry re-reads once and returns to the skeleton.

Files read: `/home/hii/Documents/EduBox/PRODUCT.md`, `/home/hii/Documents/EduBox/DESIGN.md`, `/home/hii/Documents/EduBox/docs/design/app-direction.md`, `/home/hii/Documents/EduBox/docs/build/roadmap.md`, `/home/hii/Documents/EduBox/docs/superpowers/specs/2026-10-29-edubox-phase1-prototype-design.md`. I wrote nothing.
