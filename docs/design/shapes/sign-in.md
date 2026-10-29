<!-- Confirmed by Hii on 2026-10-29 (P1, phase 1). Every ASSUMPTION below is accepted as written unless the "Confirmed decisions" list overrides it. -->

> Backend changed on 2026-10-29: Firebase is replaced by a Serverpod server with PostgreSQL (see the amended spec). Read every Firestore, snapshot, `isFromCache`, custom-claim, or Firebase error reference below as its equivalent in the phase 1 contract: the app's local store and outbox, the server-stored role, and the contract's error shapes. The screen behavior and states are unchanged.

## Confirmed decisions (Hii, 2026-10-29)

- Navigation shows only destinations whose screens exist; no disabled or "coming soon" items.
- Sign-out asks for confirmation (with the offline warning) for students only; teacher and parent sign out immediately; `account-not-set-up` signs out immediately.
- No forgot-password flow; the static `signInHelp` sentence is the only help (orchestrator ruling, forced by admin-provisioned accounts).

# Shape brief: `sign-in` (EduBox Phase 1)

Status: drafted without an interview. Every choice that the flow would have asked about is marked `ASSUMPTION`. No `DECISION` was needed, because the product facts (email and password only, no sign-up, role from claim, fixed copy for three keys) are all settled in the roadmap and spec.

Sources used: PRODUCT.md, DESIGN.md, `docs/design/app-direction.md` (sections 2, 3, 5, 6.4, 7, 8, 9), the roadmap Phase 1 exit criteria 3, 4, 9 and 11, and the Phase 1 spec (Accounts and roles, Language, Error handling).

## 1. Job and audience

- **Purpose:** answer "Can I get into my EduBox?" and get the person to their own role home with one email and one password.
- **Who arrives:** a student, teacher or parent. The app cannot tell which until after authentication.
  - Students are often on a shared or older tablet, in a classroom or at home, and may be younger. They need forgiving touch targets and plain words.
  - Teachers arrive at prep time, parents rarely.
  - Everyone has an account created by the seed/admin script. Nobody has ever chosen their own password in this app.
- **Mode:** Operate. The visitor completes a task, so precision and calm outrank expression.
- `ASSUMPTION: the screen uses student density for everyone, because the role is unknown before auth (gap 24, panel padding 24, 56dp fields and button, 16sp body) (alternatives: teacher density, or an adaptive density after the email is typed).`
- **Success:** credentials accepted, token refreshed, role claim read, and the user lands on `student-home`, `teacher-home` or `parent-home`. With no claim they land on `account-not-set-up`, never on a role home.
- **Product truth this screen carries:**
  - The screen has no sign-up and no role picker. The panel is the whole product's front door, so it should look like one well-kept school record, not a SaaS login.
  - Nothing says the device is locked or restricted, and nothing is gamified.
- **Position in the flow:** `sign-in` and `account-not-set-up` have no shell (direction 6.4). `sign-in` is the root route, so there is no back control and the system back exits the app. After success the route is replaced, so back never returns here.

## 2. Selected direction

The visual world is already fixed: `achromatic-ledger` on `paper`, with a `sheet` panel. The only open composition question is how the panel is arranged.

- **Thesis:** a single index-card-like panel centred on paper. It holds the mark, the heading, two labelled fields, and one accent button. It is flat, with a 1dp `rule` edge, no shadow and no illustration. It reads as a form to be filled in at a school office counter.
- **Focal moment:** the "Đăng nhập" button is the one dominant accent (`accent #1F4C8F`). Everything else is ink, muted and the `negative` family for errors.
- `ASSUMPTION: the 24dp mark stays in accent as the direction (section 1.2) specifies, and is not counted as a dominant accent use because of its size (alternatives: render the mark in ink on this screen only, or drop the glyph and show the wordmark alone).`

## 3. Content inventory and order (top to bottom inside the panel)

1. **Mark and wordmark.** The 24dp index-card glyph, then "EduBox" in Bitter 600 20sp ink. The glyph is excluded from semantics. The wordmark text comes from l10n (`appName`).
2. **Heading (h1).** "Đăng nhập" in Bitter 600 24/32 ink (`signInTitle`).
   - `ASSUMPTION: keep a real h1 below the wordmark so screen readers get a heading and house rule 1 holds (alternatives: wordmark only, marked as the heading, saving about 56dp of height).`
3. **Email field.** The label sits above as `Text`, the field is 56dp, and there is 8dp between them.
4. **Password field.** Same structure, with the visibility toggle as a trailing 48dp `IconButton`.
5. **Status slot.** A single in-flow region, empty by default, that holds exactly one of: the wrong-credentials sentence, a backend-unreachable block, or another auth error. It is a live region.
6. **Primary button.** "Đăng nhập", a `FilledButton` filling the panel width, 56dp tall, accent fill, white label.
7. **Help line.** Static `muted` 14/20 text. It is the only answer to "I have no account / I forgot my password".
   - `ASSUMPTION: no forgot-password flow, link or contact details, just one static sentence pointing to the school, because accounts are admin-created and no contact channel exists in the spec (alternatives: a "Quên mật khẩu?" link that opens an explanatory dialog, or omit the line).`

Realistic ranges:
- Email: 6 to about 60 characters, long school addresses possible. The field scrolls horizontally rather than wrapping.
- Password: 6 to about 40 characters.
- Error sentences: at most two lines at 400dp. At 200% text scale, up to about six lines.

There is no data, no counts and no per-role content on this screen.

## 4. Layout per breakpoint

Width decides, never orientation (direction section 5). The panel is `sheet`, radius 8, 1dp `rule` edge, elevation 0, `surfaceTintColor` transparent, padding 24 (inner width 352 at full size). The ground is `paper`, wrapped in `SafeArea`.

| Class | Typical | Panel width | Placement |
| --- | --- | --- | --- |
| compact (<600) | phone, split screen | `min(400, width - 32)` (16dp gutters) | horizontally centred |
| medium (600-839) | 800x1280 portrait tablet | 400 | centred both ways |
| expanded (840-1199) | 960x600 landscape | 400 | centred both ways |
| large (>=1200) | 1280x800, the `edubox_tablet` AVD | 400 | centred both ways |

- Nothing else sits on the canvas: no side art, no footer, no version string. The empty `paper` is the calm.
- **Height:** the panel is about 470dp at 1.0x scale, about 520dp with an error showing. Landscape tablets have about 728dp, so it fits with no scroll.
- **Short viewport** (keyboard open, 200% text scale, split screen): the panel becomes top-aligned with a 16dp margin and scrolls inside a `SingleChildScrollView` (`resizeToAvoidBottomInset: true`). The focused field is kept in view with `Scrollable.ensureVisible`. Nothing is clipped, and the button is always reachable.
  - `ASSUMPTION: the panel is vertically centred when there is room and top-aligned and scrollable when there is not (alternatives: always top-aligned at about 15% from the top, or optically centred 40% from the top).`
- **Rotation:** typed values, error state, password visibility and focus survive. State lives in a controller above the widget, not in a per-orientation subtree. It is not persisted across process death, and the password is never saved to restoration state.
- **200% text scale:** labels and errors wrap, the field and button heights are minimums that can grow, and the Vietnamese-mark golden test applies (keep at least 4dp above text in fixed-height boxes, `leadingDistribution: even`).

## 5. States

Each state lists what the user sees and what the app does.

| State | What shows | Behaviour |
| --- | --- | --- |
| **Idle** | Empty fields, an empty status slot, and the enabled accent button. | No autofocus, so the keyboard does not cover the panel on load. A password manager or autofill can fill both fields. `ASSUMPTION: no autofocus on load (alternatives: autofocus the email field, autofocus only when a hardware keyboard is attached).` |
| **Validating** | A client check that runs on button press. A field that fails shows a 2dp `error` border and a sentence directly below it, with the `error_outline` glyph at 18dp and text at 14/20 `negative` fg. | The first invalid field takes focus and the announcement reads its message. Nothing is sent to Firebase while a field is invalid. Once a field has shown an error, it re-validates live as the user types and clears when valid. There is no validation on blur. `ASSUMPTION: validate on first submit press, then live per field after that field has errored (alternatives: validate on blur, validate on every keystroke from the start).` |
| **Submitting** | The button label becomes "Đang đăng nhập…" with an 18dp, 2dp-stroke spinner inside the button. Fields are read-only with a normal look, not greyed. | The keyboard is dismissed and a double press is ignored. The state lasts from press until the destination route is ready, so it covers sign-in, forced ID-token refresh and claim read, with no wrong-home flash. The busy button keeps the accent fill and white label (8.44:1), and the changed word is the "why". `ASSUMPTION: the busy button keeps accent fill rather than the greyed disabled style (alternatives: M3 disabled grey with the same label).` A 15s timeout falls through to backend unreachable. `ASSUMPTION: 15s submit timeout maps to backendUnreachable (alternatives: 10s, 30s, no client timeout).` |
| **Disabled** | Applies only while submitting (the button and read-only fields above). | The button is never disabled for merely empty fields, because a dead button gives no feedback and no reason. `ASSUMPTION: the submit button is never disabled for empty or invalid input and only disables while submitting (alternatives: disable until both fields are non-empty, with a muted reason beside it).` The visibility toggle stays usable while submitting. |
| **Wrong credentials** | The status slot shows the `error_outline` glyph and `signInWrongCredentials` ("Email hoặc mật khẩu không đúng") in `negative` fg at 16/24. Both field borders go to the 2dp `error` state with no per-field text. | `invalid-credential`, `wrong-password` and `user-not-found` all give the same sentence, so account existence is not revealed. Email is kept, password is cleared, and focus goes to the password field. The error clears on the next edit of either field. `ASSUMPTION: after a wrong-credentials failure the email is kept, the password is cleared and focused, and both fields show the error border (alternatives: keep the password too, only mark the password field).` |
| **Backend unreachable** | The status slot shows the `cloud_off` glyph and `backendUnreachable` ("Không kết nối được với EduBox") in ink, with `backendUnreachableHint` in `muted` beneath it. A "Thử lại" `TextButton` (`retry`, ink label, at least 48dp tall) follows. | The cause is `network-request-failed`, a Firebase timeout, or an Auth closed port, and it must work for the roadmap criterion 4 test. Fields and values are kept, including the password, and the main button is enabled again. Retry re-runs the same sign-in with the kept values and goes back to Submitting. `ASSUMPTION: backend unreachable renders inline in the status slot with neutral cloud_off glyph and a Thử lại text button, form kept (alternatives: negative error_outline glyph, or replace the whole form with a full-panel message). The panel-only variant (mark, message, retry, no form) is used only when app-start session or role resolution fails, not on a submit.` |
| **Account locked or too many attempts** | A negative sentence in the status slot, at 16/24. `signInTooManyAttempts` covers `too-many-requests`. `signInAccountDisabled` covers `user-disabled`. | There is no retry button for these. The user waits or contacts the school, and the button stays enabled. |
| **Unexpected failure** | `signInUnknownError`, negative, with a "Thử lại" text button. | Any other auth exception. Technical detail is logged and never shown. |
| **Authenticated, no claim** | Not an error on this screen. | The route goes to `account-not-set-up`. A claim outside `student`, `teacher` or `parent` is treated the same way. |
| **Claim read fails after a successful sign-in** | Same as backend unreachable. | Retry repeats only the token refresh and claim read, with no re-auth. The session never routes on a stale or absent claim. `ASSUMPTION: a failed claim fetch after successful auth shows the same backendUnreachable block and retry re-runs the claim resolution (alternatives: sign the user out silently and ask for credentials again).` |

Placement of the status slot: between the password field and the button, in flow.
`ASSUMPTION: the status slot sits above the button and pushes it down about 44-68dp when it appears, with no reserved space (alternatives: below the button, or reserve a fixed-height slot to avoid layout shift).`
The slot appears without entrance animation. The tap that triggers it is already finished, so nothing moves under a finger.

`ASSUMPTION: field-level and form-level error sentences are 14sp or 16sp, not the 12sp helper default in the component table, because house rule 12 forbids sub-14sp for anything a student must read to act (alternatives: 12sp helper style per the component table).`

## 6. Interactions and focus / keyboard

- **Traversal order:** email, password, visibility toggle, "Đăng nhập", and the retry text button when it is showing. The help line is not interactive.
- **Email field:**
  - `keyboardType: emailAddress`, `textInputAction: next`, autocorrect and suggestions off, `autofillHints: [email]`.
  - The value is trimmed and compared case-insensitively at send time.
- **Password field:**
  - `obscureText: true` by default, `textInputAction: done`, `enableSuggestions: false`, autocorrect off, `autofillHints: [password]`.
  - Return or IME "Done" submits the form. The password is never trimmed and never logged.
- **Autofill:** both fields share one `AutofillGroup`. Call `TextInput.finishAutofillContext` on success so the OS offers to save.
- **Hardware keyboard:** Tab and Shift+Tab move through the order above, Enter on a field behaves like the IME action, and focus rings are visible.
  - The focus ring is a 2dp `primary` border on fields. Buttons use the Material focus ring in `primary`.
- **Focus handling:**
  - A validation failure moves focus to the first invalid field.
  - Wrong credentials move focus to the password field.
  - Success moves focus nowhere, because the route is replaced.
  - A backend failure does not move focus. The `retry` button is reachable by one Tab from the main button.
- **Visibility toggle:**
  - It must not steal focus or drop the keyboard, and the cursor position is preserved.
  - Tooltip and semantic label are `showPassword` ("Hiện mật khẩu") when hidden and `hidePassword` ("Ẩn mật khẩu") when shown. It exposes toggled state.
  - Visibility resets to hidden when the route is left or the app goes to background. It otherwise stays as the user set it, including after a failure. `ASSUMPTION: password visibility persists through failures and resets to hidden on app pause or route change (alternatives: reset to hidden after every failed attempt, or after every submit).`
- **Motion:** feedback only, 150-200ms standard easing for press and focus. The route replacement on success follows the standard transition and is instant when `MediaQuery.disableAnimationsOf` is true. `ASSUMPTION: success is a route replacement with no back stack entry (alternatives: a fade-through transition, or push with a guarded back).`
- **Dialogs and toasts:** none. No `SnackBar` is used for errors, because it would vanish before the user acts.

## 7. Accessibility

- **Labels:** the visible label `Text` is excluded from semantics. Each field carries one semantic label from l10n (`emailLabel`, `passwordLabel`), so TalkBack reads one name, not two. There is no placeholder and no floating label (house rule 11).
- **Errors:**
  - Each field-level error is attached to its field's semantics error text.
  - The status slot is a live region. The same sentence is also sent through `SemanticsService.announce` once, because TalkBack ignores some live-region inserts.
  - The submitting state announces `signInSubmitting` once.
  - An error is never shown by colour alone: it always has the glyph and a sentence.
- **Touch targets:**
  - Fields and the button are 56dp.
  - The visibility toggle is 48x48dp.
  - The retry text button is at least 48dp tall.
  - There is at least 8dp between adjacent targets.
- **Contrast:**
  - ink on sheet 16.68:1.
  - `muted` help text on sheet 7.38:1.
  - Field border `control` on sheet 3.71:1 (non-text 3:1 passes).
  - White on accent 8.44:1.
  - `negative` fg on sheet 6.54:1.
  - Focus border `primary` on sheet 8.44:1.
- **Guideline tests (roadmap criterion 11):** `androidTapTargetGuideline`, `labeledTapTargetGuideline` (the toggle labelled by its tooltip) and `textContrastGuideline` must all pass on this screen, in portrait and landscape.
- **Text scale:** 200% reflows and scrolls with no clipping (see section 4).
- **Test hooks:** give stable `Key`s for the E2E suite: `signIn.email`, `signIn.password`, `signIn.togglePassword`, `signIn.submit`, `signIn.status`, `signIn.retry`. E2E assertions look strings up via `lookupAppLocalizations(Locale('vi'))`, never literal text.

## 8. Copy: l10n keys and proposed Vietnamese

All text comes from `AppLocalizations` (roadmap criterion 9), including semantics labels and tooltips. The copy uses no personal pronouns, so it fits students, teachers and parents alike. `ASSUMPTION: copy is pronoun-free and register-neutral across roles (alternatives: "em" for students and "bạn" for adults, which needs the role first and so cannot apply pre-auth).`

| Key | Vietnamese | Status |
| --- | --- | --- |
| `appName` | EduBox | proposed |
| `signInTitle` | Đăng nhập | proposed |
| `emailLabel` | Email | proposed |
| `passwordLabel` | Mật khẩu | proposed |
| `signInButton` | Đăng nhập | proposed |
| `signInSubmitting` | Đang đăng nhập… | proposed |
| `showPassword` | Hiện mật khẩu | proposed |
| `hidePassword` | Ẩn mật khẩu | proposed |
| `emailRequired` | Vui lòng nhập email | proposed |
| `emailInvalid` | Email chưa đúng định dạng | proposed |
| `passwordRequired` | Vui lòng nhập mật khẩu | proposed |
| `signInWrongCredentials` | Email hoặc mật khẩu không đúng | fixed by roadmap criterion 4 |
| `backendUnreachable` | Không kết nối được với EduBox | fixed by roadmap criterion 4 |
| `backendUnreachableHint` | Kiểm tra kết nối mạng rồi thử lại. | proposed |
| `retry` | Thử lại | fixed (shared key) |
| `signInTooManyAttempts` | Đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại. | proposed |
| `signInAccountDisabled` | Tài khoản này đang bị tạm khóa. Vui lòng liên hệ nhà trường. | proposed |
| `signInUnknownError` | Không đăng nhập được. Vui lòng thử lại. | proposed |
| `signInHelp` | Quên mật khẩu hoặc chưa có tài khoản? Vui lòng liên hệ nhà trường. | proposed |

Shared with other screens, and so not owned here: `appOpening` ("Đang mở EduBox…", proposed in direction section 8), shown while the app resolves a stored session before this screen would appear.

Validation rules behind the copy:
- `emailRequired` fires on an empty trimmed value.
- `emailInvalid` fires when there is no `@` with non-empty text on both sides.
- `passwordRequired` fires only when the field is empty.
- `ASSUMPTION: email validation is lenient (non-empty text on both sides of an @) and there is no client-side password length rule, so any seeded password works and Firebase decides (alternatives: strict RFC email regex, a 6-character minimum shown as a hint).`
- `ASSUMPTION: three extra Firebase error cases get their own keys (too many attempts, account disabled, unknown), beyond the two fixed by the roadmap (alternatives: map all three to backendUnreachable or to wrong-credentials).`

## 9. Explicitly NOT on this screen

- A sign-up, create-account or "register" entry. Accounts come from the seed/admin script.
- A forgot-password flow, reset email, or any link that opens one. Only the static `signInHelp` sentence is shown.
- A role picker, role tabs or "I am a student / teacher / parent" toggle. Role is read from the custom claim after sign-in.
- Social or SSO sign-in, biometrics, phone number or OTP login.
- A "remember me" or "stay signed in" checkbox. Firebase persists the session and there is no choice to offer.
- A language switcher. Vietnamese is the only locale.
- A greeting ("Chào ..."), the user's name, avatar, or any personalised content. It is unknown before auth.
- An illustration, mascot, hero art, gradient, glow, confetti or any engagement device (PRODUCT.md anti-references).
- Padlock or shield iconography, warning banners, or any text implying the device is locked.
- A shadow on the panel (Flat-By-Default Rule). Separation is the tone step plus the 1dp `rule` edge.
- The navigation shell, app bar or app-wide offline strip. The panel handles unreachable inline.
- A version string, environment badge, terms or privacy links. Not needed for the walking skeleton.
- A spinner on its own. Busy shows only inside the button beside a changed label.
- A `SnackBar` or toast for any error.

## 10. Open items for the contract architect and builder

- Confirm the proposed keys above, and decide whether `signInButton` and `signInTitle` should share a key.
- The exact fixed copy to preserve in tests: `signInWrongCredentials`, `backendUnreachable`, and `retry` ("Thử lại"). Criterion 4 asserts all three.
- Force an ID-token refresh after sign-in and before routing (roadmap risk). The Submitting state must cover it.
- Keep the Vietnamese mark golden test passing for every text style used here, including `leadingDistribution: even`.
- Any new strings added during build need ARB entries, or the l10n literal-string test will fail.

---

## ASSUMPTION lines (full list)

1. ASSUMPTION: the screen uses student density for everyone, because the role is unknown before auth (gap 24, panel padding 24, 56dp fields and button, 16sp body) (alternatives: teacher density, or an adaptive density after the email is typed).
2. ASSUMPTION: the 24dp mark stays in accent as the direction (section 1.2) specifies, and is not counted as a dominant accent use because of its size (alternatives: render the mark in ink on this screen only, or drop the glyph and show the wordmark alone).
3. ASSUMPTION: keep a real h1 below the wordmark so screen readers get a heading and house rule 1 holds (alternatives: wordmark only, marked as the heading, saving about 56dp of height).
4. ASSUMPTION: no forgot-password flow, link or contact details, just one static sentence pointing to the school, because accounts are admin-created and no contact channel exists in the spec (alternatives: a "Quên mật khẩu?" link that opens an explanatory dialog, or omit the line).
5. ASSUMPTION: the panel is vertically centred when there is room and top-aligned and scrollable when there is not (alternatives: always top-aligned at about 15% from the top, or optically centred 40% from the top).
6. ASSUMPTION: no autofocus on load (alternatives: autofocus the email field, autofocus only when a hardware keyboard is attached).
7. ASSUMPTION: validate on first submit press, then live per field after that field has errored (alternatives: validate on blur, validate on every keystroke from the start).
8. ASSUMPTION: the busy button keeps accent fill rather than the greyed disabled style (alternatives: M3 disabled grey with the same label).
9. ASSUMPTION: 15s submit timeout maps to backendUnreachable (alternatives: 10s, 30s, no client timeout).
10. ASSUMPTION: the submit button is never disabled for empty or invalid input and only disables while submitting (alternatives: disable until both fields are non-empty, with a muted reason beside it).
11. ASSUMPTION: after a wrong-credentials failure the email is kept, the password is cleared and focused, and both fields show the error border (alternatives: keep the password too, only mark the password field).
12. ASSUMPTION: backend unreachable renders inline in the status slot with neutral cloud_off glyph and a Thử lại text button, form kept (alternatives: negative error_outline glyph, or replace the whole form with a full-panel message). The panel-only variant (mark, message, retry, no form) is used only when app-start session or role resolution fails, not on a submit.
13. ASSUMPTION: a failed claim fetch after successful auth shows the same backendUnreachable block and retry re-runs the claim resolution (alternatives: sign the user out silently and ask for credentials again).
14. ASSUMPTION: the status slot sits above the button and pushes it down about 44-68dp when it appears, with no reserved space (alternatives: below the button, or reserve a fixed-height slot to avoid layout shift).
15. ASSUMPTION: field-level and form-level error sentences are 14sp or 16sp, not the 12sp helper default in the component table, because house rule 12 forbids sub-14sp for anything a student must read to act (alternatives: 12sp helper style per the component table).
16. ASSUMPTION: password visibility persists through failures and resets to hidden on app pause or route change (alternatives: reset to hidden after every failed attempt, or after every submit).
17. ASSUMPTION: success is a route replacement with no back stack entry (alternatives: a fade-through transition, or push with a guarded back).
18. ASSUMPTION: copy is pronoun-free and register-neutral across roles (alternatives: "em" for students and "bạn" for adults, which needs the role first and so cannot apply pre-auth).
19. ASSUMPTION: email validation is lenient (non-empty text on both sides of an @) and there is no client-side password length rule, so any seeded password works and Firebase decides (alternatives: strict RFC email regex, a 6-character minimum shown as a hint).
20. ASSUMPTION: three extra Firebase error cases get their own keys (too many attempts, account disabled, unknown), beyond the two fixed by the roadmap (alternatives: map all three to backendUnreachable or to wrong-credentials).

No `DECISION` items were raised.
