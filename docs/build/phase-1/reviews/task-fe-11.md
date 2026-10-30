VERDICT: APPROVE

Scope: d903935..51c49bb (0a8d833 task-fe-9 fixes, 51c49bb Task 11).
Re-run: flutter analyze = No issues found; flutter test test/widget = All tests passed (96); grep debugPrint lib/ = none.
Goldens opened: student_library_phone, parent_home_phone, parent_home_tablet.

0a8d833 vs task-fe-9: all five findings addressed with meaningful tests.
- 16dp compact padding applied to groups and the skeleton panel; test measures the row inset from the EduPanel edge (16 phone, 24 tablet). Phone golden shows the cover slot at x=32 inside the panel at x=16.
- 200% test now runs the guidelines and asserts the second title shares dx and sits below the first.
- Column-major test asserts ceil(n/2) via real positions (two down column one, third at the top of column two) plus guidelines.
- Error-after-data now runs the guidelines, taps retry and asserts recovery.
- Nav list is now the exact [navHome, navLibrary].
- Deviation (200% at tablet): justified, because the one-column fallback only exists at expanded width (on a phone it is one column anyway, so the assertion would be vacuous). Cost: no 200% test of the library on the phone remains (bottom bar and 16dp padding at 200%). See LOW below.

Task 11: scope is exact (screen, stage_router, tests, two goldens). All brief states have a widget test (loading, populated, no linked child, offline with cache, offline without cache, error with retry, sign-out, sign-out failure, 200%). Only the child's name shows (no class, no accent, no rail, no forward copy). Copy is l10n only, no debugPrint. Name is one header semantics node "Hoc sinh: name" with the visible label excluded to avoid double reading. Sign-out is immediate with no confirm. A cached name survives a failed reload (the value branch comes first). Parent brief has no last-refresh time on offline-with-cache, so none is expected.
Visual: panel 24dp under the 64dp app bar, white with hairline and 8dp corners, no shadow, label muted 14 above Bitter 24 name, 24dp inner padding on phone as the brief fixes, 760dp centred column on tablet, lockup at the gutter, overflow at the right edge, no accent, Vietnamese marks (e with tilde and circumflex) intact, nothing clipped. Library phone golden: palette, hairlines, left alignment and bottom bar are correct.

FINDINGS:
- [LOW] edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart:'sign-out failure shows a snackbar with retry' - does not tap the SnackBar retry action nor assert sign-out then succeeds; no guideline check on the snackbar state - owner: FE
- [LOW] edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart:'200% text on a phone...' - asserts only takeException; no guideline check, no long-name case, and the title says "wraps" without asserting it - owner: FE
- [LOW] edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart - no test that a cached name stays on screen when a later read fails (brief and code both promise it); also the shell test asserts no NavigationRail but not no NavigationBar - owner: FE
- [LOW] edubox_flutter/test/widget/student_library/student_library_screen_test.dart:'200% text: one column, no overflow' - moved from phone to tablet, so no 200% library coverage on the phone (bottom bar, 16dp padding); keep one test per size - owner: FE
