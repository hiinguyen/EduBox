VERDICT: APPROVE

Scope: 5735173 (app shell review r2 fixes) and 8b698d9 (Task 8), range 8015981..8b698d9.
Re-run: flutter analyze = No issues found; flutter test test/app test/widget test/features = All tests passed (85).
Goldens opened: student_home_phone, student_home_tablet, student_home_offline_phone, student_home_offline_tablet. Palette, Bitter greeting, hairline panel (no shadow), one accent on "Mở thư viện" (the sign-out button is ink), left alignment with the cover slots, the 240dp rail with the user row and visible "Đăng xuất", the offline strip placement and Vietnamese marks are all correct; nothing is clipped. The tablet golden is 1280 (large) only, so the medium 88dp rail has no golden.

Status of 5735173: debugPrint removed from edubox_app.dart and session_controller.dart (developer.log); the sign-out vs reconnect-refresh race is fixed with _sessionEpoch (the new test is gated on refreshProfile and would resurrect the session on the old code); a failed refresh is now logged; AppServices.dispose() releases the network seam for discarded and disposed startup services (two new bootstrap tests assert the controller stream closes). Task 8 files match the plan: newest 4, rows not tappable (excludeSemantics container, no onTap), only Trang chủ registered, student sign-out confirm with offline warning and inline failure, all copy from l10n keys, profile-error test present with accessibility assertions.

FINDINGS:
- [MEDIUM] edubox_flutter/lib/src/data/cached_backend.dart:107 - debugPrint still present in lib/ after the commit whose purpose was to remove them; violates the plan rule "No print, no debugPrint" - evidence: grep debugPrint lib/ - owner: FE
- [MEDIUM] edubox_flutter/test/widget/student_home/student_home_screen_test.dart - the "error after data" branch (student_home_screen.dart:171-190: error block with lastUpdatedAt hint above cached rows, plus retry) has no widget test, although the plan table lists it - evidence: no test sets an error after a successful load or asserts lastUpdatedAt - owner: FE
- [LOW] edubox_flutter/test/app/session_routing_test.dart - the new "failed refresh is reported" behaviour (developer.log in _refreshAfterReconnect) is not asserted - evidence: only the race is tested - owner: FE
- [LOW] edubox_flutter/test/widget/student_home/student_home_screen_test.dart - no test asserts that rows are not tappable or that the rail/bar holds exactly one destination (the plan's "nav shows only built destinations"); both hold in code - owner: FE
- [LOW] edubox_flutter/test/widget/student_home/student_home_screen_test.dart:254 - the 200% text test only checks takeException; it runs no accessibility guideline check on the scaled layout - owner: FE
- [LOW] edubox_flutter/lib/src/shell/student_shell.dart:132-133 - home selectedIcon equals icon (home_outlined); selection is shown only by the pill, which is fine, but a filled variant would aid the state cue - owner: FE
