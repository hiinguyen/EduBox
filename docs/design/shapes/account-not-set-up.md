<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- The screen shows the explanation, the signed-in email, "Kiểm tra lại" (forced token refresh), and "Đăng xuất".

# Shape brief: `account-not-set-up` (EduBox phase 1)

Status: drafted without an interview, so every choice the flow would have asked about is marked `ASSUMPTION`.
No code and no files were written.
Sources: `PRODUCT.md`, `DESIGN.md` (seed), `docs/design/app-direction.md` (sections 2, 3, 5, 6.4, 7, 8, 9), `docs/build/roadmap.md` (phase 1 criterion 3, criterion 9, Rulings), and the phase 1 spec (Accounts and roles, Language).
No `DECISION` is raised: direction and roadmap already settle the real product choices.

## 1. Job and audience

**Who arrives.**
Anyone who signed in with a valid email and password whose forced-refresh ID token has no valid `role` claim.
"Valid" means one of `student|teacher|parent`, so a missing, empty, or unknown value all land here.
The role is unknown, so this could be a student, a teacher, or a parent.
Their state of mind is mild confusion: the password worked, but the app won't open.
A student may also be in a hurry at the start of a lesson.

**Mode.**
Operate, in its smallest form.
It is a single-purpose notice screen with no shell, per direction 6.4.

**The one question** (direction section 2): "Why can't I go in?"
The biggest block is the sentence `accountNotSetUp` (the h1) and the short explanation under it.

**Outcome.**
- The user understands in one glance that nothing they did is wrong.
- They understand that only the school can fix it, and they know whom to ask.
- They have two clear exits: check again (the claim may have just been set) or sign out (to use another account).

**Product-specific truth.**
- Accounts are provisioned only by the seed/admin script, so the user cannot fix this themselves.
- There is no sign-up, no role picker, and no self-service of any kind.
- The screen must never imply they did something wrong, and never read as a lock or a penalty.

## 2. Selected direction

- **Visual authority:** `achromatic-ledger`, from `app-direction.md`.
  This screen has no shell: a 400dp `sheet` panel centred on `paper`, the mark and wordmark at its top, then the message.
- **Structural thesis:** it reads like a note slipped into a record folder.
  It says "your card has not been filed yet, ask the office", in plain words, with no decoration.
- **Focal moment:** the h1 sentence set in Bitter, and nothing competing with it.
- **Accent:** the one dominant accent goes on the "Đăng xuất" `FilledButton`, as the direction table fixes.
  The "Kiểm tra lại" button is a secondary `OutlinedButton`.
  Functional accents (focus ring) are allowed.

`ASSUMPTION: primary action stays "Đăng xuất" (accent FilledButton) as the binding direction table says, with "Kiểm tra lại" as the OutlinedButton secondary (alternatives: make "Kiểm tra lại" the primary, since it is the likelier action; would need a direction-table amendment).`

`ASSUMPTION: "Kiểm tra lại" is added though the roadmap criterion only names the sentence and a sign-out action; the extra control does not break criterion 3 (alternatives: sign-out only).`

## 3. Content and order (top to bottom, inside the panel)

1. **Mark and wordmark.**
   The 24dp index-card glyph in accent plus "EduBox" in Bitter 600 at 20sp.
   This is the same lockup as `sign-in`, which marks it as the same door.
2. **h1.**
   `accountNotSetUp`, Bitter 600 24/32.
3. **Body.**
   `accountNotSetUpBody`, Be Vietnam Pro 400 16/24, in ink.
   It says: login succeeded, no role has been assigned yet, the school does this, and it is not the user's fault.
4. **Who to contact.**
   `accountNotSetUpContact`, 16/24 in ink, naming "giáo viên hoặc quản trị viên của trường" and pointing at "Kiểm tra lại".
5. **Signed-in-as row.**
   A label in `muted` 12/18, then the email in Plex Mono 400 14/20 in ink.
   It lets the user quote the exact account to the admin, and it shows when they used the wrong account.
   Long emails wrap at any character, up to two lines, then ellipsize.
   `ASSUMPTION: show the signed-in email read-only (alternatives: show nothing; show the Firebase UID, rejected as jargon).`
6. **Status region.**
   A one-line live region, empty on arrival; its states are in section 5.
   `ASSUMPTION: the region reserves one line of height (24dp) even when empty, so no layout shift occurs when a result lands (alternatives: let it grow in and shift the buttons).`
7. **Actions**, stacked and full panel width, gap 12.
   - "Kiểm tra lại", `OutlinedButton`, 56dp.
   - "Đăng xuất", `FilledButton`, accent, 56dp.
   `ASSUMPTION: 56dp buttons (the student size) because the user's role is unknown and the audience skews young (alternatives: 48dp).`
   Reading and focus order is top to bottom, so check-again comes before sign-out.

Spacing: panel padding 24; 24 between lockup and h1; 12 between h1 and body; 16 between body paragraphs; 24 before the signed-in row; 24 before the status region; 16 before the buttons.
Radii are 8 for the panel and 6 for the buttons.
The panel has a 1dp `rule` edge and no shadow.
There are no icons except the glyph in the network-error state.

## 4. Layout per breakpoint

Width decides the layout, never orientation.
All of it is wrapped in `SafeArea` and a `SingleChildScrollView` with a `ConstrainedBox(minHeight: viewport)`, so the content is vertically centred when it fits and scrolls when it does not.

| Class | Layout |
| --- | --- |
| large (>= 1200, the AVD landscape 1280x800) | Panel 400dp wide, centred both ways on `paper`. About 728dp of height is available and the panel is about 480dp tall, so it fits with no scroll. |
| expanded (840-1199) | Same panel, same centring. |
| medium (600-839, 800x1280 portrait) | Same 400dp panel, centred. It sits a little above geometric centre (optical centre: top-weighted 45/55) to avoid a dead lower half. |
| compact (< 600, the fallback) | Panel width = screen - 32 (16dp gutters), capped at 400. At < 360dp the panel loses its edge and padding drops to 16. Top-aligned with 32dp top padding when content exceeds the height. |

- No rail, app bar, back control, or offline strip: there is nowhere to go back to.
- Text scale up to 200% reflows: the panel grows taller, the page scrolls, and nothing clips.
- Compact landscape (height about 360dp) scrolls normally.
- Buttons stay full width and keep their label on one line, wrapping to two at 200% scale with the height growing.

`ASSUMPTION: keep the panel at the binding 400dp even on the 1280dp canvas (alternatives: widen to 480dp on large; rejected as it departs from direction 6.4).`

## 5. States

All strings are l10n keys; none are literals.
The screen is static except for the status region and the buttons.

| State | What shows | Controls |
| --- | --- | --- |
| **Resolving (before this screen)** | Not part of this screen. The app-wide `appOpening` screen (mark plus "Đang mở EduBox…" in `muted`) shows until the token and claim are known. This screen never shows a bare spinner. | n/a |
| **Not set up (rest)** | Full content as in section 3, status region empty. | Both enabled. |
| **Checking** | "Kiểm tra lại" becomes "Đang kiểm tra…" with a 18dp spinner before the label (a spinner inside a busy button beside a changed label is allowed by house rule 14). The status region is unchanged. | Check-again is busy; sign-out is disabled with `disabled` text, and its reason is the check in progress, which is visible on the button beside it. |
| **Still not set up** | The status region shows a `muted` sentence, "Vẫn chưa được thiết lập.", then the time in Plex Mono 12/18: "Đã kiểm tra lúc 14:30". No red and no glyph. The sentence never says "failed". | Both enabled. |
| **Network error** | The negative 18dp `error_outline` glyph plus an ink sentence "Chưa kiểm tra được vì không có kết nối mạng." The glyph reinforces the words and does not replace them. | Both enabled. The "Kiểm tra lại" button is the retry, so no second "Thử lại" button appears. |
| **Claim found** | There is no success screen. The router replaces this route with the role home. The button stays in its busy state until the route swaps. | n/a |
| **Signing out** | "Đăng xuất" becomes "Đang đăng xuất…" with the in-button spinner, and check-again is disabled. It then routes to `sign-in`. | Both busy or disabled. |

Details:
- On each new check the previous status line is cleared first, so a stale "Vẫn chưa..." never sits next to a fresh result.
- Check-again forces an ID-token refresh (`getIdTokenResult(true)`) and re-reads the claim.
- A refresh that fails because the user was disabled or deleted (an auth error, not a network error) routes to `sign-in`.
- Closed-port or Auth-down on refresh counts as the network-error state here, not a full-screen `backendUnreachable`.
  This is a narrowing of the direction's rule that `backendUnreachable` shows only on sign-in and app start.
  `ASSUMPTION: network failure during a re-check shows the inline network-error line in the status region, not full-screen backendUnreachable (alternatives: reuse backendUnreachable with its Thử lại).`
- There is no auto-polling or timer: the user decides when to check.
  `ASSUMPTION: manual check only, no periodic background refresh (alternatives: poll every 30s; rejected as quiet churn and notification pressure).`
- There is no cooldown on the button, and double-tap is guarded by the busy state.
- Re-checking is safe and idempotent.

## 6. Interaction

- **Arrival:** the screen appears directly from `appOpening` or from a sign-in with no extra animation.
  A 150ms fade of the whole panel is allowed, and it is skipped when reduce-motion is on.
- **Status line swap:** it changes without animation, so there is no motion to suppress.
- **System back:** this is a root route, so back exits the app and does not navigate to `sign-in`.
- **App resume** (from the background): it does not auto-check; the user keeps control.
  `ASSUMPTION: no re-check on app resume (alternatives: silent re-check on resume, which could move the user to home unprompted).`
- **Sign-out** clears the Auth session and any per-user cached state, then routes to `sign-in` with empty fields.

## 7. Accessibility

- **Semantics tree** (reading order): the lockup is one image with the label "EduBox"; h1 as `header: true`; body; contact line; the signed-in row merged into one node ("Đang đăng nhập bằng <email>"); the status live region; the two buttons.
- **Initial focus** lands on the h1, so TalkBack reads the main message first.
- **Live region:** the status region is `liveRegion: true`.
  The checking, still-not-set-up, and network-error results are announced when they appear.
  The busy label change is announced because the button's semantics label changes.
- **Targets and contrast:** every tap target is at least 48x48 (the buttons are 56 tall).
  All text meets AA on `sheet` or `paper`.
  The glyph is never alone, since it always sits next to its sentence.
  `muted` on `sheet` is 7.38:1.
- **Text scale** reflows up to 200%.
- **Tests that must pass:** `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`, and the literal-string l10n test (criterion 9).
  Phase 1 E2E criterion 3 looks up `accountNotSetUp` by key, expects a sign-out action, and expects no role home.
- Spinners carry a semantics label (`accountChecking` or `signingOut`).
- Tooltips are not needed because there are no icon-only buttons.

## 8. Copy: l10n keys and proposed Vietnamese

The roadmap fixes `accountNotSetUp`; every other row is proposed, and the key is the contract.
Style: neutral and warm, with no jargon (no "claim", "token", or "role" in English), no blame, and no pronoun beyond "bạn".

| Key | Proposed vi |
| --- | --- |
| `accountNotSetUp` | Tài khoản chưa được thiết lập (fixed by roadmap) |
| `accountNotSetUpBody` | Bạn đã đăng nhập đúng, nhưng tài khoản này chưa được gán vai trò (học sinh, giáo viên hoặc phụ huynh). Việc này do nhà trường thực hiện, không phải lỗi của bạn. |
| `accountNotSetUpContact` | Hãy nhờ giáo viên hoặc quản trị viên của trường thiết lập giúp, rồi bấm "Kiểm tra lại". |
| `accountSignedInAs` | Đang đăng nhập bằng |
| `accountSignedInAsSemantics` | Đang đăng nhập bằng {email} (placeholder `email`) |
| `accountCheckAgain` | Kiểm tra lại |
| `accountChecking` | Đang kiểm tra… |
| `accountStillNotSetUp` | Vẫn chưa được thiết lập. |
| `accountCheckedAt` | Đã kiểm tra lúc {time} (`time` is formatted by `intl` `vi`, 24-hour, for example 14:30) |
| `accountCheckFailedOffline` | Chưa kiểm tra được vì không có kết nối mạng. |
| `signOut` (shared key; check whether it already exists) | Đăng xuất |
| `signingOut` | Đang đăng xuất… |
| `eduboxMarkSemantics` | EduBox |

`ASSUMPTION: no contact name, email, or phone number appears on the screen, since phase 1 holds no school-contact data (alternatives: a configurable `supportContact` in backend config shown as a line; needs seed and config work).`

`ASSUMPTION: "bạn" is the one pronoun used because the role is unknown (alternatives: "em", which fits students but would be wrong for teachers and parents; no pronoun).`

## 9. What is NOT on this screen

- No padlock, shield, warning triangle, warning-grey banner, or any "restricted" or "access denied" wording (DESIGN.md Don'ts, house rule 10).
- No illustration, mascot, or confetti.
- No sign-up, "tạo tài khoản", role picker, or request-access form.
  A user without a role cannot fix it, and nothing here pretends otherwise.
- No "Quên mật khẩu" (password reset is not offered on this screen).
- No error codes, claim names, UIDs, or stack text.
- No stamp: the screen has no row status, and the Stamped Status Rule applies to rows.
- No app bar, rail, bottom nav, back arrow, or offline strip.
- No language switcher (Vietnamese is the only locale).
- No auto-refresh timer, countdown, or pressure copy.
- No mention of Phase 2 or kiosk mode.
- No dark theme (phase 1 is light only).
- No invented support channel (see the contact assumption).

## 10. Open items for the builder

- The final Vietnamese text lives in `app_vi.arb`.
  Tests look strings up by key through `lookupAppLocalizations(Locale('vi'))`.
- Keys beyond `accountNotSetUp` are new; the contract architect should confirm or rename them.
- `signOut` is probably shared with the parent overflow menu and the teacher shell, so reuse it rather than duplicating it.
- Add E2E coverage beyond criterion 3 for check-again:
  - seed a no-claim user and tap check-again, then expect the "still not set up" status line;
  - set the claim through the Admin SDK between taps and expect a route to the role home;
  - use the closed-port or network seam and expect the network-error line.
- Check that the Bitter h1 "Tài khoản chưa được thiết lập" passes the Vietnamese diacritic golden at 24sp and at 200% scale.

## ASSUMPTION list

1. `ASSUMPTION: primary action stays "Đăng xuất" (accent FilledButton) as the binding direction table says, with "Kiểm tra lại" as the OutlinedButton secondary (alternatives: make "Kiểm tra lại" the primary, since it is the likelier action; would need a direction-table amendment).`
2. `ASSUMPTION: "Kiểm tra lại" is added though the roadmap criterion only names the sentence and a sign-out action; the extra control does not break criterion 3 (alternatives: sign-out only).`
3. `ASSUMPTION: show the signed-in email read-only (alternatives: show nothing; show the Firebase UID, rejected as jargon).`
4. `ASSUMPTION: the region reserves one line of height (24dp) even when empty, so no layout shift occurs when a result lands (alternatives: let it grow in and shift the buttons).`
5. `ASSUMPTION: 56dp buttons (the student size) because the user's role is unknown and the audience skews young (alternatives: 48dp).`
6. `ASSUMPTION: keep the panel at the binding 400dp even on the 1280dp canvas (alternatives: widen to 480dp on large; rejected as it departs from direction 6.4).`
7. `ASSUMPTION: network failure during a re-check shows the inline network-error line in the status region, not full-screen backendUnreachable (alternatives: reuse backendUnreachable with its Thử lại).`
8. `ASSUMPTION: manual check only, no periodic background refresh (alternatives: poll every 30s; rejected as quiet churn and notification pressure).`
9. `ASSUMPTION: no re-check on app resume (alternatives: silent re-check on resume, which could move the user to home unprompted).`
10. `ASSUMPTION: no contact name, email, or phone number appears on the screen, since phase 1 holds no school-contact data (alternatives: a configurable supportContact in backend config shown as a line; needs seed and config work).`
11. `ASSUMPTION: "bạn" is the one pronoun used because the role is unknown (alternatives: "em", which fits students but would be wrong for teachers and parents; no pronoun).`
