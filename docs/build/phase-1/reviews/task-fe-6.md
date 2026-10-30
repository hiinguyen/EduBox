VERDICT: APPROVE

Range dca5bd9..feb2861 (single commit feb2861). `flutter analyze`: no issues. `flutter test test/widget/sign_in`: 11/11 pass.
All four goldens opened and checked: palette (paper ground, sheet panel with 1dp rule edge, no shadow), Bitter wordmark and h1, body family for labels, one accent use (button, plus the mark), 24dp panel padding rhythm, 16dp gutters on phone, 400dp centred panel on tablet, Vietnamese diacritics intact, nothing clipped. All copy comes from l10n keys. Password is obscured with a reveal toggle and is never logged.

FINDINGS:
- [MEDIUM] edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart:233 - field-level validation errors render the sentence only; the brief (section 5 Validating, section 7 "never colour alone") asks for the 18dp error_outline glyph beside the sentence - theme errorStyle has no glyph and the screen passes plain errorText - owner: FE implementer
- [MEDIUM] edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart:135 - the 200% text scale test renders the unreachable error state but runs no expectAccessibilityGuidelines (extra requirement: guidelines in every error-state test) - owner: FE implementer
- [MEDIUM] edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart:66 - no golden or visual evidence for wrong credentials (2dp error border on both fields via error: SizedBox.shrink()) or the validating state; any extra helper-row height that SizedBox.shrink() adds is unverified, so a layout shift or missing border could go unnoticed - owner: FE implementer
- [MEDIUM] edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart:66 - the brief's behaviours are untested: password focus after wrong credentials, first invalid field takes focus, a double press is ignored, the 15s timeout maps to unreachable, retry after a successful sign-in calls only refreshProfile (claim-read failure path), the toggle really un-obscures, and background resets visibility - owner: FE implementer
- [LOW] edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart:117 - retry re-signs-in when refreshProfile returns SessionExpiredError, but the contract lists only unreachable/unexpected for refreshProfile; harmless, though the branch is untested and the contract comment should name it - owner: FE implementer
- [LOW] edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart:137 - on the 15s timeout the underlying signIn future keeps running and may complete on the server while the UI shows unreachable; the result is dropped silently - owner: FE implementer
- [LOW] edubox_flutter/test/widget/goldens/sign_in_unreachable_phone.png - the "Thử lại" text button label sits at about x=52 while the glyph and message start at x=40, so the retry label is visibly indented from the status block's left edge; consider aligning the label to the glyph column - owner: FE implementer
- [LOW] edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart:174 - SemanticsService.sendAnnouncement is called on every state change; the status slot is also a liveRegion, so TalkBack may read it twice (the brief wants once) - owner: FE implementer

## Re-review r2

VERDICT: APPROVE

Range: fc847ea. `flutter analyze`: no issues. `flutter test test/widget/sign_in`: 20/20 pass.

- MEDIUM field-error glyph: fixed. `_FieldError` renders the 18dp `error_outline` plus the 14/20 negative sentence, and the validating test asserts two glyphs at `EduSize.statusGlyph`. Both validating goldens show glyph and text. The field error is exposed through the semantics hint rather than a native error text, which is acceptable.
- MEDIUM 200% test lacks guidelines: fixed. It now calls `expectAccessibilityGuidelines`.
- MEDIUM no goldens for validating or wrong credentials: fixed. Phone and tablet goldens for both are added. Validating shows 2dp negative borders with glyph and sentence under each field, and the panel is unclipped. Wrong credentials shows both borders in red, email kept, password empty, and the single sentence with glyph in the slot. The `SizedBox.shrink()` error adds no visible layout gap.
- MEDIUM untested behaviours: fixed. New tests cover first-invalid focus (email, then password), password focus after wrong credentials, double press (counted by a `CountingAuth` wrapper, one `signIn` call), the 15s timeout (`pump(submitTimeout)` gives unreachable), claim-read retry (`signIn` once, `refreshProfile` once), toggle `obscureText` both ways, and background reset. All are deterministic: they use a held fake, a fake clock and call counters, with no real timers.
- LOW "Thử lại" indent: fixed. `RetryButton` now aligns with the message column (x=66 in the phone golden), and a test asserts equal x.
- Remaining LOW, not blocking: field-error glyphs sit about 16dp inside the field edge (Material helper padding), while the status-slot glyph sits flush at the panel edge; this is a small horizontal inconsistency.
- Remaining LOW, not blocking: the timeout leaves the late `signIn` future running, and the possible double announcement is unaddressed (both LOWs from r1, unchanged).
- No new defects found.
