# EduBox Phase 1 Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> Every task is executed by the opencode CLI on DeepSeek 4.1 Flash, which has no access to Claude skills or to the conversation that wrote this plan.
> Each task is therefore self-contained: it carries every file in full, every command, and every expected result.

**Spec:** `docs/superpowers/specs/2026-10-29-edubox-phase1-prototype-design.md` (it outranks everything, including this plan).

**Contract:** `docs/build/phase-1/contract.md` at tag `phase-1-contract-v1` (commit `52d6d3c`).

**Goal:** Build the phase 1 Flutter app on top of the frozen contract: the achromatic-ledger theme with bundled fonts, the production data layer and network seam, role routing with session restore, the six phase 1 screens with every designed state, and the phase 1 E2E suite.

**Architecture:** One `EduBoxApp` root owns a `SessionController` (stage machine: opening, startFailed, signedOut, notSetUp, home) and a `ConnectivityState` (offline strip plus reconnect reloads), both read through an `AppScope` inherited widget.
Screens take the frozen `EduBoxBackend` seam only: widget tests run against the contract's `FakeBackend`, production runs `CachedBackend` (generated Serverpod client + drift `CachedDataStore` + `NetworkController`).
Every block's data is a small `Loadable<T>` that keeps the last good value, so "error after data was shown" keeps rows on screen.

**Tech Stack:** Flutter 3.47.8 / Dart 3.13.7, Material 3 with an explicit `ColorScheme`, drift 2.34, Serverpod 4.0.4 client (`serverpod_auth_idp_flutter`, `serverpod_auth_idp_client`), `connectivity_plus` 7.3.2, `http` 1.6, `intl` (vi), ARB l10n, `flutter_test` goldens and accessibility guidelines, `integration_test`.

---

## How to read this plan

Tasks run strictly in order 1 to 12; every task assumes the previous tasks are committed.
Each task lists its routing signal: the executor, whether it touches contract-owned paths, and whether a human or Claude reviewer must look at its screenshots.
Code blocks are complete files unless a step says "replace"; copy them exactly, then run `dart format`.
When a step shows an expected output, compare it literally; a different result means stop and fix before moving on.

## Global constraints (apply to every task)

### Toolchain and working directory

- Set the toolchain once per shell: `export PATH="$HOME/development/flutter/bin:$HOME/.pub-cache/bin:$PATH"`.
- Repository root: `/home/hii/Documents/EduBox`, branch `phase-1`.
- Every `flutter` and `dart` command below runs in `/home/hii/Documents/EduBox/edubox_flutter` unless the step says otherwise.
- Never run `flutter create`, never upgrade Flutter, never edit `pubspec.lock` by hand; after a `pubspec.yaml` change run `dart pub get` at the repo root and commit the regenerated root `pubspec.lock` with the task.

### Path ownership (contract.md section 6)

- You may create or edit only frontend-track paths: `edubox_flutter/lib/main.dart`, `lib/src/app/**`, `lib/src/shell/**`, `lib/src/screens/**`, `lib/src/features/**`, `lib/src/data/**`, `lib/src/network/**`, `lib/src/theme/**`, `edubox_flutter/assets/**`, the dependency section of `edubox_flutter/pubspec.yaml` and its `flutter:` section, `edubox_flutter/analysis_options.yaml`, `edubox_flutter/test/**` except `test/contract/**`, `test/local/**`, `test/l10n/**`, and `edubox_flutter/integration_test/**`.
- Never edit `lib/src/contract/**`, `lib/src/fake/**`, `lib/src/local/local_store.dart` or `local_store.g.dart`, `lib/l10n/**`, `l10n.yaml`, anything under `edubox_server/`, `edubox_client/`, `edubox_fixtures/`, `compose.yaml`, `tool/`, `.github/`, or `docs/` (except where Task 2 says so).
- The single exception is Task 2: the orchestrator authorizes it to edit `edubox_flutter/test/l10n/literal_string_scanner.dart`, `edubox_flutter/test/l10n/literal_strings_test.dart` and one sentence of `docs/build/phase-1/contract.md`, for the carried scanner item only.
- If a task seems to need any other contract change (a new ARB key, a changed DTO, a changed repository signature), stop and report a line starting with `CONTRACT-CHANGE:`; do not make the change.

### Copy and localization rules

- Vietnamese is the only locale; every user-visible string, tooltip and semantics label comes from `AppLocalizations` (`lib/l10n/app_vi.arb`, 98 frozen keys).
- Never pass a string literal or an interpolated string (`'...$x...'`) to `Text`, `SelectableText`, `TextSpan`, or to a named argument called `label`, `hint`, `tooltip`, `semanticsLabel`, `semanticLabel`, `labelText`, `hintText`, `helperText`, `errorText`, `counterText`, `semanticCounterText`, `prefixText`, `suffixText`, `message`, `title`, `value`, `text`, `data` or `content`.
- Also forbidden even though the scanner cannot see them: a literal reached through a variable (`const x = 'Xin chào'; Text(x)`), and a literal used as a method target (`Text('xin chào'.toUpperCase())`).
- Numbers shown as text go through `EduFormat.figure(n)`; dates and times through `EduFormat`; data lists through `EduFormat.joinValues`; two values on one meta line are separated by the `MetaDot` widget, never by a literal separator.
- Data values (names, class names, subjects, titles, emails) are shown as they come from the backend.
- Tests and the E2E suite look strings up with `lookupAppLocalizations(const Locale('vi'))` (the `vi` helper), never literal Vietnamese copy; fixture data (titles, names) may be literal in tests.

### Engineering rules

- Test first: every task starts with the failing test, shows the expected failure, then the implementation.
- Widgets read tokens from the theme (`Theme.of`, `EduPalette.of`, `EduTypeExtras.of`, `EduDensity.of`); only `lib/src/theme/**` may contain colour hex values.
- No `print`, no `debugPrint`, no `// TODO`, no commented-out code.
- Errors are never swallowed silently: map them to a `BackendError` and show the screen's state.
- Prose and comments use plain "-" and never the em dash character.

### The four gates (end of every task)

Run all four from `edubox_flutter/`; all must pass before the commit:

```bash
flutter analyze
# Expected: "No issues found!"
dart format --output=none --set-exit-if-changed .
# Expected: "Formatted N files (0 changed)" and exit code 0
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output after gen-l10n (the generated l10n files do not change)
```

If `dart format --set-exit-if-changed` fails, run `dart format .`, re-run the four gates, and include the formatted files in the commit.

### Commit rules

- Commit only the paths the task lists (plus regenerated `pubspec.lock` and golden PNGs when the task says so) with explicit `git add <path>`; never `git add -A` or `git add .`.
- Never commit `skills-lock.json` (it is untracked on purpose) and never commit `edubox_server/config/passwords.yaml`.
- Never commit golden failure artefacts: `flutter test` writes them to `test/**/failures/` when a golden differs; delete those directories before committing.
- Commit message format: `<type>: <description>` with type `feat`, `fix`, `test`, `chore` or `docs`; no attribution lines.
- Never push, never open a PR, never tag; the orchestrator does that after the phase gate.

### Forbidden commands

- No destructive Docker commands: never run `docker compose down -v`, `docker volume rm`, `docker system prune`, `docker rm -f` or any command that deletes volumes, images or containers.
- No `git reset --hard`, `git clean`, `git checkout -- .`, `git push --force`, or history rewrites.
- No `rm -rf` outside `edubox_flutter/build/` and the temporary directories a task names.

## Design tokens (copied from docs/design/app-direction.md; Task 1 encodes them)

| Token | Value | Use |
| --- | --- | --- |
| paper | `#F4F5F8` | Page ground, app bar, rail |
| sheet | `#FFFFFF` | Panels, cards, inputs, dialogs |
| ink | `#191E29` | Text and figures (15.30:1 on paper) |
| muted | `#4E5666` | Secondary text, icons (6.77:1 on paper) |
| accent | `#1F4C8F` | The one dominant accent per screen (white on it 8.44:1) |
| accentPale / accentInk | `#E5ECF6` / `#13305C` | Selected answer (phase 3) |
| active | `#E6E9EF` | Nav pill, skeleton bars, initials disc |
| rule | `#DFE3EA` | 1dp hairlines and panel edges |
| control | `#7D8594` | Text field and outlined button borders (3.71:1) |
| disabled | `#8C93A0` | Disabled control text only |
| negative fg / fill / ink / border | `#B3261E` / `#FBE9E7` / `#7A1A14` / `#EDB9B3` | Real errors only |
| neutral fill / ink / border | `#ECEEF2` / `#2E3440` / `#CDD2DB` | Offline strip |

- Fonts (bundled, offline): Bitter 600 (display and headlines), Be Vietnam Pro 400/500/600 (everything else), IBM Plex Mono 400/500 (figures, timestamps, the signed-in email).
- Type scale (size/line height in sp): displayLarge 32/40 -0.4; displayMedium 28/36 -0.3 (student greeting); headlineLarge 24/32 -0.2 (student and parent h1); headlineMedium 20/28 (teacher h1, dialog title, wordmark); titleLarge 18/26 (student panel title); titleMedium 16/24 (student row title); titleSmall 14/20 (teacher row title); bodyLarge 16/24; bodyMedium 14/20; bodySmall 12/18 muted; labelLarge 16/24 600 (buttons); labelMedium 12/16 500 (nav labels).
- Every style sets `height` and `leadingDistribution: TextLeadingDistribution.even`; nothing under 12sp; nothing a student must read to act under 14sp.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64. Student and parent: gap 24, panel padding 24, section gap 48. Teacher: gap 16, panel padding 16, section gap 32.
- Radii: 8 (panels, cards, dialogs, menus), 6 (buttons, fields), 4 (stamps, cover slots, skeleton bars, tooltips), full circle (initials disc only).
- Elevation: everything at rest is 0 with `surfaceTintColor: Colors.transparent`; only dialogs, menus and tooltips float (elevation 6, ink at 18% shadow, barrier ink at 40%).
- Hairlines: 1dp `rule`; a panel has a 1dp `rule` edge or a tone step, never both a border and a shadow.
- Window classes (width decides, never orientation): compact < 600 (bottom bar or app bar, gutter 16), medium 600-839 (88dp rail, gutter 24), expanded 840-1199 (88dp rail, gutter 32), large >= 1200 (240dp extended rail, gutter 32). Arithmetic: 1280 = 240 + 32 + 976 + 32; 800 = 88 + 24 + 664 + 24.
- Tap targets at least 48x48dp; student primary buttons and pre-auth fields 56dp tall.
- Motion: feedback only, 150-200ms; nothing performs an entrance.

## Look-and-fix rules (from the design-taste app-screen rules and the impeccable craft floor)

These rules are repeated as a checklist inside every screen task, because the executor cannot load the design skills.

- One h1 per screen, a noun or the student greeting; no eyebrow or kicker label above a heading.
- Colour goes on data and the one primary action, never on chrome: the rail, app bar and nav never carry the accent; the active destination is the neutral grey pill.
- Surfaces are flat: 1px rule or one tone step, no card shadows, no gradients, glows, glass, emoji, mascots, badges, streaks, or icons inside tinted circles.
- Tables are rules and alignment: 12sp grey sentence-case headers, no zebra, no header band, figures right-aligned in a monospace face.
- A real zero prints "0"; a missing value is a grey "-"; counts state a fact, never progress.
- Loading is the final layout with flat grey bars at real sizes, no shimmer, no spinner (a spinner is allowed only inside a busy button beside its changed label), no layout shift when data lands.
- Errors live inside the block that failed: one sentence, the last good time when known, and a "Thử lại" text button; never a full-screen error except sign-in and app start.
- An empty block keeps its frame and its header and states one sentence.
- Spacing: tight groups, generous separation, more space above a heading than below it; blocks share one left edge (the gutter), and a title aligns with the first panel under it.
- Contrast: body text at least 4.5:1; the palette above is built to pass, so a contrast failure means a wrong token or a wrong background.
- Every state of every block is built and looked at: loading, populated, empty, error, offline with cache, offline without cache.
- On a phone the navigation folds into a bottom bar or an app bar; no rail and no horizontal page scroll.

## Exit criteria map (roadmap phase 1)

| Criterion | Where it is proven |
| --- | --- |
| 1 Student library shows exactly the approved fixtures | Task 9 widget test; Task 12 E2E `1:` |
| 2 Teacher and parent land on their homes | Tasks 10, 11 widget tests; Task 12 routing test and E2E `2:` |
| 3 Not-set-up users land on account-not-set-up | Task 7 widget tests; Task 12 E2E `3:` (server unknown-role half is a backend test) |
| 4 Wrong credentials; closed port shows backendUnreachable + retry | Task 6 widget tests; Task 12 E2E `4:` and `unreachable_backend_test.dart` |
| 5 Offline with cache after restart, all roles | Task 12 host restart test (`CachedBackend` over a drift file) and E2E `5:` |
| 6 Offline without cache shows the offline-no-data keys | Tasks 8-11 widget tests; Task 12 host restart test and E2E `6:` |
| 7 Reconnect strip then new data | Tasks 8 and 10 widget tests; Task 12 E2E `7:` |
| 8 Network source maps connectivity and probe results | Task 3 unit tests |
| 9 pingStream reaches the app with the role | Task 4 contract suite over `CachedBackend`; Task 12 E2E `9:` |
| 10-14 Storage, authorization, no sign-up, role change, coverage | Backend track (server tests); not frontend |
| 15 No literal user-facing strings | `test/l10n/literal_strings_test.dart`, strengthened in Task 2, green after every task |
| 16 Commands pass on a clean checkout | The four gates after every task; E2E command in Task 12 |
| 17 Accessibility guidelines on every screen and state | `expectAccessibilityGuidelines` in every screen task, per state |

## File structure (what this plan creates)

```text
edubox_flutter/
  assets/fonts/                      Task 1: six TTF files + licenses/*.txt
  lib/main.dart                      Task 5: production bootstrap
  lib/src/theme/                     Task 1: tokens, breakpoints, extensions, theme, font licences
  lib/src/network/                   Task 3: ProbedNetworkController, connectivity + /readyz probe
  lib/src/data/                      Task 4: EduBoxApi, ClientEduBoxApi, CachedBackend, error mapping
  lib/src/app/                       Task 5: AppScope, SessionController, ConnectivityState,
                                             Loadable, formatters, EduBoxApp, StageRouter,
                                             production services
  lib/src/shell/                     Task 5: mark, block states, offline strip, auth panel
                                     Task 8: role shell, account menu, sign-out dialog, student shell
                                     Task 10: teacher shell
  lib/src/features/library/          Task 8: catalogue grouping, ContentRow
  lib/src/screens/app_start/         Task 5: opening and start-failed screens
  lib/src/screens/sign_in/           Task 6
  lib/src/screens/account_not_set_up/ Task 7
  lib/src/screens/student_home/      Task 8
  lib/src/screens/student_library/   Task 9
  lib/src/screens/teacher_home/      Task 10
  lib/src/screens/parent_home/       Task 11
  test/flutter_test_config.dart      Task 1: loads bundled fonts for every test
  test/theme/                        Task 1
  test/network/                      Task 3
  test/data/                         Task 4
  test/support/app_harness.dart      Task 5
  test/app/                          Tasks 5 and 12
  test/features/                     Task 8
  test/widget/<screen>/              Tasks 6-11, goldens in test/widget/goldens/
  integration_test/                  Task 12: E2E harness and phase 1 E2E tests
```

## Screenshot step (used by every screen task)

Screen tasks capture goldens at phone size 411x891 and tablet size 1280x800 with `flutter test --update-goldens <test file>`.
The PNGs land in `edubox_flutter/test/widget/goldens/` (Task 1 and Task 5 goldens live next to their tests).
Open every PNG the task produced (for example with your file viewer or an image-reading tool) and go through the task's look-and-fix checklist.
Fix every item that fails, re-run `flutter test --update-goldens <test file>`, and look again; at most three rounds.
If you cannot view images, do not guess: finish the task and put a line `NEEDS-VISUAL-REVIEW: <png paths>` in your task report so the reviewer looks before approving.
Commit the final PNGs with the task; `flutter test` then compares against them on every later run.


---

## Task 1: Theme, design tokens and bundled fonts

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (two golden PNGs of the Vietnamese mark test).

**Files:**
- Create: `edubox_flutter/assets/fonts/Bitter-SemiBold.ttf`, `BeVietnamPro-Regular.ttf`, `BeVietnamPro-Medium.ttf`, `BeVietnamPro-SemiBold.ttf`, `IBMPlexMono-Regular.ttf`, `IBMPlexMono-Medium.ttf`
- Create: `edubox_flutter/assets/fonts/licenses/Bitter-OFL.txt`, `BeVietnamPro-OFL.txt`, `IBMPlexMono-OFL.txt`
- Create: `edubox_flutter/lib/src/theme/tokens.dart`, `breakpoints.dart`, `theme_extensions.dart`, `edu_theme.dart`, `font_licenses.dart`
- Modify: `edubox_flutter/pubspec.yaml` (the `flutter:` section only)
- Test: `edubox_flutter/test/flutter_test_config.dart`, `test/theme/edu_theme_test.dart`, `test/theme/vietnamese_marks_golden_test.dart`, goldens `test/theme/goldens/vietnamese_marks_1.0x.png`, `vietnamese_marks_2.0x.png`

**Interfaces:**
- Consumes: nothing.
- Produces: `buildEduTheme()` -> `ThemeData`; `eduTextStyle(...)`; constants `EduColors`, `EduFonts`, `EduSpace`, `EduRadius`, `EduSize`, `EduMotion`; `enum WindowClass {compact, medium, expanded, large}` with `WindowClass.of(double width)`, `hasRail`, `hasExtendedRail`, `isCompact`, `gutter`; theme extensions `EduPalette.of(context)`, `EduTypeExtras.of(context)` (`figure`, `figureTeacher`, `timestamp`, `monoBody`), `EduDensity.of(context)` with `EduDensity.student|teacher|parent` and `density.apply(ThemeData)`; `registerFontLicenses()`; font families `Bitter`, `BeVietnamPro`, `IBMPlexMono`.

Why: app-direction sections 3-4 fix every token; the fonts must be bundled (no `google_fonts`, no runtime fetch) because the app must work offline and later in kiosk mode.
Bitter ships on Google Fonts only as a variable font, and Flutter does not map `FontWeight` onto a variable axis reliably on Android, so this task cuts one static SemiBold instance with fonttools (allowed: Bitter has no Reserved Font Name).
Be Vietnam Pro and IBM Plex Mono ship unmodified (IBM Plex reserves its name).

- [ ] **Step 1: Download the fonts and licences (pinned google/fonts commit)**

Run from the repo root `/home/hii/Documents/EduBox`:

```bash
C=6157dfaa640ca5738b4d1a7070fe389c3036d7fc
B=https://raw.githubusercontent.com/google/fonts/$C/ofl
F=edubox_flutter/assets/fonts
mkdir -p $F/licenses /tmp/edubox-fonts
curl -sfL -o $F/BeVietnamPro-Regular.ttf  $B/bevietnampro/BeVietnamPro-Regular.ttf
curl -sfL -o $F/BeVietnamPro-Medium.ttf   $B/bevietnampro/BeVietnamPro-Medium.ttf
curl -sfL -o $F/BeVietnamPro-SemiBold.ttf $B/bevietnampro/BeVietnamPro-SemiBold.ttf
curl -sfL -o $F/IBMPlexMono-Regular.ttf   $B/ibmplexmono/IBMPlexMono-Regular.ttf
curl -sfL -o $F/IBMPlexMono-Medium.ttf    $B/ibmplexmono/IBMPlexMono-Medium.ttf
curl -sfL -o $F/licenses/Bitter-OFL.txt       $B/bitter/OFL.txt
curl -sfL -o $F/licenses/BeVietnamPro-OFL.txt $B/bevietnampro/OFL.txt
curl -sfL -o $F/licenses/IBMPlexMono-OFL.txt  $B/ibmplexmono/OFL.txt
curl -sfL -o /tmp/edubox-fonts/Bitter-var.ttf "$B/bitter/Bitter%5Bwght%5D.ttf"
sha256sum $F/*.ttf /tmp/edubox-fonts/Bitter-var.ttf
```

Expected hashes (stop and report if any differs):

```text
cd1ef6e9d7db28ad5cdb88a65ccbe693870e60d340b791f349d248342b4fe4c3  BeVietnamPro-Regular.ttf
b60832bfa0fcd015158112c64d7e3fdad3b0c6287d1823f85a3103636e845268  BeVietnamPro-Medium.ttf
bd8e27eb02720b9d91e59e4f10a90878643219f25ce6a8d9a4f06a8a88d3bb71  BeVietnamPro-SemiBold.ttf
6a3412f058c7d8dfd9170c41e85ade48e5156ecb89356110ca57a0a27734af46  IBMPlexMono-Regular.ttf
a9b4c49bb299e05b5f6c481e7fb5e78943d2793249a0c8874ab574a2d1ea6755  IBMPlexMono-Medium.ttf
ef2b9a711fb02f1e5823b34da1b7450e0fc76793b7d733a8b41006e24916d4a7  Bitter-var.ttf
```

- [ ] **Step 2: Cut the static Bitter SemiBold instance**

```bash
python3 -m venv /tmp/edubox-fonts/venv
/tmp/edubox-fonts/venv/bin/pip install -q fonttools==4.60.1
/tmp/edubox-fonts/venv/bin/fonttools varLib.instancer /tmp/edubox-fonts/Bitter-var.ttf \
  wght=600 --static --update-name-table -o edubox_flutter/assets/fonts/Bitter-SemiBold.ttf
/tmp/edubox-fonts/venv/bin/python -c "
from fontTools.ttLib import TTFont
f = TTFont('edubox_flutter/assets/fonts/Bitter-SemiBold.ttf')
print('fvar' in f, f['OS/2'].usWeightClass, f['name'].getDebugName(1), f['name'].getDebugName(2))"
rm -rf /tmp/edubox-fonts
```

Expected: the instancer may print `Attempting to fix OTLOffsetOverflowError ...` (harmless), and the check prints `False 600 Bitter SemiBold Regular`.
The file is about 198 KB; its hash varies per run because the font header stores a timestamp.

- [ ] **Step 3: Declare the fonts and licence assets**

`edubox_flutter/pubspec.yaml` (replace the whole file):

```yaml
name: edubox_flutter
description: EduBox Android app (phase 1 contract scaffold).
publish_to: 'none'

version: 0.1.0+1

environment:
  sdk: ^3.12.2
  flutter: ^3.44.4

resolution: workspace

dependencies:
  drift: '>=2.34.0 <2.35.0'
  edubox_client:
    path: ../edubox_client
  edubox_fixtures:
    path: ../edubox_fixtures
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  path: ^1.9.0
  path_provider: ^2.1.6
  serverpod_auth_idp_flutter: 4.0.4
  serverpod_flutter: 4.0.4
  sqlite3: ^3.8.0

dev_dependencies:
  analyzer: any
  build_runner: '>=2.10.0 <2.17.0'
  # Pinned: serverpod_database 4.0.4 needs sqlparser ^0.44 in the shared
  # workspace resolution; drift_dev 2.34.1+1 is the newest unretracted release on
  # sqlparser 0.44.
  drift_dev: 2.34.1+1
  flutter_lints: '>=3.0.0 <7.0.0'
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

dependency_overrides:
  flutter_secure_storage: ^10.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/fonts/licenses/
  fonts:
    - family: Bitter
      fonts:
        - asset: assets/fonts/Bitter-SemiBold.ttf
          weight: 600
    - family: BeVietnamPro
      fonts:
        - asset: assets/fonts/BeVietnamPro-Regular.ttf
          weight: 400
        - asset: assets/fonts/BeVietnamPro-Medium.ttf
          weight: 500
        - asset: assets/fonts/BeVietnamPro-SemiBold.ttf
          weight: 600
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexMono-Medium.ttf
          weight: 500
```

Run `dart pub get` in the repo root; expected: `Got dependencies!` and `git -C .. diff --stat pubspec.lock` shows no change.

- [ ] **Step 4: Write the failing tests**

`edubox_flutter/test/flutter_test_config.dart`:

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts (and Material Icons) before every test file, so
/// widget tests measure real Vietnamese glyphs and goldens show real type.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Bitter', ['assets/fonts/Bitter-SemiBold.ttf']);
  await _loadFont('BeVietnamPro', [
    'assets/fonts/BeVietnamPro-Regular.ttf',
    'assets/fonts/BeVietnamPro-Medium.ttf',
    'assets/fonts/BeVietnamPro-SemiBold.ttf',
  ]);
  await _loadFont('IBMPlexMono', [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-Medium.ttf',
  ]);
  await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
  await testMain();
}

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
```

`edubox_flutter/test/theme/edu_theme_test.dart`:

```dart
import 'package:edubox_flutter/src/theme/breakpoints.dart';
import 'package:edubox_flutter/src/theme/edu_theme.dart';
import 'package:edubox_flutter/src/theme/font_licenses.dart';
import 'package:edubox_flutter/src/theme/theme_extensions.dart';
import 'package:edubox_flutter/src/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = buildEduTheme();

  test('colour scheme is the explicit ledger palette, never a seed', () {
    final scheme = theme.colorScheme;
    expect(scheme.primary, EduColors.accent);
    expect(scheme.primary, const Color(0xFF1F4C8F));
    expect(scheme.surface, const Color(0xFFF4F5F8));
    expect(scheme.onSurface, const Color(0xFF191E29));
    expect(scheme.onSurfaceVariant, const Color(0xFF4E5666));
    expect(scheme.surfaceContainerLowest, const Color(0xFFFFFFFF));
    expect(scheme.secondaryContainer, const Color(0xFFE6E9EF));
    expect(scheme.outline, const Color(0xFF7D8594));
    expect(scheme.outlineVariant, const Color(0xFFDFE3EA));
    expect(scheme.error, const Color(0xFFB3261E));
    expect(scheme.surfaceTint, Colors.transparent);
    expect(theme.scaffoldBackgroundColor, EduColors.paper);
  });

  test('every text role sets family, explicit height and even leading', () {
    final roles = <String, TextStyle?>{
      'displayLarge': theme.textTheme.displayLarge,
      'displayMedium': theme.textTheme.displayMedium,
      'headlineLarge': theme.textTheme.headlineLarge,
      'headlineMedium': theme.textTheme.headlineMedium,
      'titleLarge': theme.textTheme.titleLarge,
      'titleMedium': theme.textTheme.titleMedium,
      'titleSmall': theme.textTheme.titleSmall,
      'bodyLarge': theme.textTheme.bodyLarge,
      'bodyMedium': theme.textTheme.bodyMedium,
      'bodySmall': theme.textTheme.bodySmall,
      'labelLarge': theme.textTheme.labelLarge,
      'labelMedium': theme.textTheme.labelMedium,
      'labelSmall': theme.textTheme.labelSmall,
    };
    for (final MapEntry(:key, :value) in roles.entries) {
      expect(value, isNotNull, reason: key);
      expect(value!.fontFamily, isNotNull, reason: key);
      expect(value.height, isNotNull, reason: key);
      expect(
        value.height! * value.fontSize!,
        greaterThanOrEqualTo(16),
        reason: key,
      );
      expect(value.height!, greaterThanOrEqualTo(1.24), reason: key);
      expect(
        value.leadingDistribution,
        TextLeadingDistribution.even,
        reason: key,
      );
      expect(value.fontSize!, greaterThanOrEqualTo(12), reason: key);
    }
    expect(theme.textTheme.displayMedium!.fontFamily, EduFonts.display);
    expect(theme.textTheme.displayMedium!.fontSize, 28);
    expect(theme.textTheme.headlineLarge!.fontSize, 24);
    expect(theme.textTheme.bodyLarge!.fontFamily, EduFonts.body);
    expect(theme.textTheme.bodyLarge!.fontSize, 16);
  });

  test('surfaces are flat and radii are 8 / 6 / 4 only', () {
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(cardShape.borderRadius, BorderRadius.circular(8));
    expect(cardShape.side.color, EduColors.rule);
    expect(theme.appBarTheme.elevation, 0);
    expect(theme.appBarTheme.scrolledUnderElevation, 0);
    expect(theme.dialogTheme.elevation, 6);
    final filledShape =
        theme.filledButtonTheme.style!.shape!.resolve({})!
            as RoundedRectangleBorder;
    expect(filledShape.borderRadius, BorderRadius.circular(6));
  });

  test('extensions are present with the student density by default', () {
    expect(theme.extension<EduPalette>(), isNotNull);
    expect(theme.extension<EduTypeExtras>()!.figure.fontFamily, EduFonts.mono);
    expect(theme.extension<EduDensity>(), EduDensity.student);
    final teacher = EduDensity.teacher.apply(theme);
    expect(teacher.extension<EduDensity>(), EduDensity.teacher);
    expect(teacher.extension<EduPalette>(), isNotNull);
  });

  test('window classes follow width, never orientation', () {
    expect(WindowClass.of(411), WindowClass.compact);
    expect(WindowClass.of(599.9), WindowClass.compact);
    expect(WindowClass.of(600), WindowClass.medium);
    expect(WindowClass.of(800), WindowClass.medium);
    expect(WindowClass.of(960), WindowClass.expanded);
    expect(WindowClass.of(1280), WindowClass.large);
  });

  test('font and licence assets are bundled', () async {
    for (final asset in [
      'assets/fonts/Bitter-SemiBold.ttf',
      'assets/fonts/BeVietnamPro-Regular.ttf',
      'assets/fonts/BeVietnamPro-Medium.ttf',
      'assets/fonts/BeVietnamPro-SemiBold.ttf',
      'assets/fonts/IBMPlexMono-Regular.ttf',
      'assets/fonts/IBMPlexMono-Medium.ttf',
      ...eduFontLicenseAssets.values,
    ]) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });
}
```

`edubox_flutter/test/theme/vietnamese_marks_golden_test.dart`:

```dart
import 'package:edubox_flutter/src/theme/edu_theme.dart';
import 'package:edubox_flutter/src/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test-only sample text (test/ is not scanned by the l10n literal test).
const _marks = 'ẬẤỖỘỄ ặỵ Đđ';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Vietnamese stacked marks never clip at ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = buildEduTheme();
      final t = theme.textTheme;
      final x = theme.extension<EduTypeExtras>()!;
      final styles = <TextStyle?>[
        t.displayLarge,
        t.displayMedium,
        t.headlineLarge,
        t.headlineMedium,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        x.figure,
        x.timestamp,
        x.monoBody,
      ];
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: RepaintBoundary(
                key: const Key('marks'),
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final style in styles) Text(_marks, style: style),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const Key('marks')),
        matchesGoldenFile('goldens/vietnamese_marks_${scale}x.png'),
      );
    });
  }
}
```

- [ ] **Step 5: Run the tests to verify they fail**

Run: `flutter test test/theme`
Expected: FAIL with a compilation error naming a missing file, for example `Error when reading 'lib/src/theme/breakpoints.dart'`.

- [ ] **Step 6: Write the theme**

`edubox_flutter/lib/src/theme/tokens.dart`:

```dart
import 'package:flutter/painting.dart';

/// Raw design tokens from docs/design/app-direction.md (achromatic-ledger).
///
/// Widgets never use these directly: they read `Theme.of(context)` and the
/// theme extensions in `theme_extensions.dart`. Only `edu_theme.dart` and the
/// extensions read this file.
abstract final class EduColors {
  static const paper = Color(0xFFF4F5F8);
  static const sheet = Color(0xFFFFFFFF);
  static const ink = Color(0xFF191E29);
  static const muted = Color(0xFF4E5666);
  static const accent = Color(0xFF1F4C8F);
  static const accentPale = Color(0xFFE5ECF6);
  static const accentInk = Color(0xFF13305C);
  static const active = Color(0xFFE6E9EF);
  static const rule = Color(0xFFDFE3EA);
  static const control = Color(0xFF7D8594);
  static const disabled = Color(0xFF8C93A0);
  static const inverseAccent = Color(0xFFA8C1EA);
  static const hover = Color(0xFFF9FAFB);
  static const surfaceFallback = Color(0xFFEFF1F4);
  static const surfaceDim = Color(0xFFE9EBF0);

  // Status families (section 3.4): fg, fill, ink, border.
  static const negative = Color(0xFFB3261E);
  static const negativeFill = Color(0xFFFBE9E7);
  static const negativeInk = Color(0xFF7A1A14);
  static const negativeBorder = Color(0xFFEDB9B3);
  static const neutralFill = Color(0xFFECEEF2);
  static const neutralInk = Color(0xFF2E3440);
  static const neutralBorder = Color(0xFFCDD2DB);
}

/// Font family names; they must match `flutter: fonts:` in pubspec.yaml.
abstract final class EduFonts {
  static const display = 'Bitter';
  static const body = 'BeVietnamPro';
  static const mono = 'IBMPlexMono';
}

/// The 4dp spacing scale (section 3.5).
abstract final class EduSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;
  static const s64 = 64.0;
}

/// The tight radius pair plus stamps (section 3.6). Nothing else is allowed.
abstract final class EduRadius {
  /// Cards, panels, tables, dialogs, menus.
  static const panel = 8.0;

  /// Buttons, text fields, answer options.
  static const control = 6.0;

  /// Stamps, chips, cover thumbnails, tooltips, skeleton bars.
  static const small = 4.0;
}

/// Fixed sizes used across screens.
abstract final class EduSize {
  /// Minimum tap target (Android guideline).
  static const tapTarget = 48.0;

  /// Student/pre-auth primary button and field height.
  static const primaryButton = 56.0;

  /// Pre-auth panel width (sign-in, account-not-set-up).
  static const authPanelWidth = 400.0;

  /// Reading-content cap for student and parent screens.
  static const readingMaxWidth = 760.0;

  /// Height of the app-wide offline / reconnecting strip.
  static const offlineStrip = 40.0;

  /// The index-card mark glyph.
  static const mark = 24.0;

  /// Inline status glyph next to an error or notice sentence.
  static const statusGlyph = 18.0;

  /// Rail widths.
  static const railCollapsed = 88.0;
  static const railExtended = 240.0;

  /// Hairline.
  static const hairline = 1.0;
}

/// Motion: feedback only, 150-200ms standard easing.
abstract final class EduMotion {
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
}
```

`edubox_flutter/lib/src/theme/breakpoints.dart`:

```dart
/// Material 3 window classes (app-direction section 5). Width decides the
/// layout, never orientation.
enum WindowClass {
  /// < 600dp: phone, split screen. Bottom bar or app bar only.
  compact,

  /// 600-839dp: 10-11" tablet portrait. 88dp rail.
  medium,

  /// 840-1199dp: 8" tablet landscape. 88dp rail.
  expanded,

  /// >= 1200dp: 10-11" tablet landscape (the edubox_tablet AVD). 240dp rail.
  large;

  static WindowClass of(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 840) return WindowClass.medium;
    if (width < 1200) return WindowClass.expanded;
    return WindowClass.large;
  }

  bool get isCompact => this == WindowClass.compact;

  bool get hasRail => this != WindowClass.compact;

  bool get hasExtendedRail => this == WindowClass.large;

  /// Horizontal gutter around the content canvas.
  double get gutter => switch (this) {
    WindowClass.compact => 16,
    WindowClass.medium => 24,
    WindowClass.expanded => 32,
    WindowClass.large => 32,
  };
}
```

`edubox_flutter/lib/src/theme/theme_extensions.dart`:

```dart
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Raw palette tokens for the few custom widgets that need one (skeleton
/// bars, the mark, the offline strip). Read with `EduPalette.of(context)`.
@immutable
class EduPalette extends ThemeExtension<EduPalette> {
  const EduPalette({
    this.paper = EduColors.paper,
    this.sheet = EduColors.sheet,
    this.ink = EduColors.ink,
    this.muted = EduColors.muted,
    this.accent = EduColors.accent,
    this.active = EduColors.active,
    this.rule = EduColors.rule,
    this.control = EduColors.control,
    this.disabled = EduColors.disabled,
    this.negative = EduColors.negative,
    this.neutralFill = EduColors.neutralFill,
    this.neutralInk = EduColors.neutralInk,
  });

  final Color paper;
  final Color sheet;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color active;
  final Color rule;
  final Color control;
  final Color disabled;
  final Color negative;
  final Color neutralFill;
  final Color neutralInk;

  static EduPalette of(BuildContext context) =>
      Theme.of(context).extension<EduPalette>() ?? const EduPalette();

  @override
  EduPalette copyWith() => this;

  @override
  EduPalette lerp(EduPalette? other, double t) => other ?? this;
}

/// IBM Plex Mono styles for figures, timestamps and the signed-in email.
@immutable
class EduTypeExtras extends ThemeExtension<EduTypeExtras> {
  const EduTypeExtras({
    required this.figure,
    required this.figureTeacher,
    required this.timestamp,
    required this.monoBody,
  });

  /// Figure in a student row: Plex Mono 500, 16/24.
  final TextStyle figure;

  /// Figure in a teacher table: Plex Mono 500, 14/20.
  final TextStyle figureTeacher;

  /// Timestamp or date in a row: Plex Mono 400, 12/18.
  final TextStyle timestamp;

  /// An identifier shown as data (the signed-in email): Plex Mono 400, 14/20.
  final TextStyle monoBody;

  static EduTypeExtras of(BuildContext context) =>
      Theme.of(context).extension<EduTypeExtras>()!;

  @override
  EduTypeExtras copyWith({
    TextStyle? figure,
    TextStyle? figureTeacher,
    TextStyle? timestamp,
    TextStyle? monoBody,
  }) => EduTypeExtras(
    figure: figure ?? this.figure,
    figureTeacher: figureTeacher ?? this.figureTeacher,
    timestamp: timestamp ?? this.timestamp,
    monoBody: monoBody ?? this.monoBody,
  );

  @override
  EduTypeExtras lerp(EduTypeExtras? other, double t) => other ?? this;
}

/// Per-role density (app-direction section 6). The role shell injects one
/// with `EduDensity.apply`.
@immutable
class EduDensity extends ThemeExtension<EduDensity> {
  const EduDensity({
    required this.gap,
    required this.panelPadding,
    required this.sectionGap,
    required this.rowHeight,
    required this.buttonHeight,
  });

  /// Student and pre-auth: generous.
  static const student = EduDensity(
    gap: EduSpace.s24,
    panelPadding: EduSpace.s24,
    sectionGap: EduSpace.s48,
    rowHeight: 72,
    buttonHeight: EduSize.primaryButton,
  );

  /// Teacher: denser, table-forward.
  static const teacher = EduDensity(
    gap: EduSpace.s16,
    panelPadding: EduSpace.s16,
    sectionGap: EduSpace.s32,
    rowHeight: EduSize.tapTarget,
    buttonHeight: 40,
  );

  /// Parent: minimal, student spacing.
  static const parent = EduDensity(
    gap: EduSpace.s24,
    panelPadding: EduSpace.s24,
    sectionGap: EduSpace.s48,
    rowHeight: 64,
    buttonHeight: EduSize.tapTarget,
  );

  final double gap;
  final double panelPadding;
  final double sectionGap;
  final double rowHeight;
  final double buttonHeight;

  static EduDensity of(BuildContext context) =>
      Theme.of(context).extension<EduDensity>() ?? student;

  /// Returns [base] with this density replacing any other density extension.
  ThemeData apply(ThemeData base) => base.copyWith(
    extensions: [
      ...base.extensions.values.where((e) => e is! EduDensity),
      this,
    ],
  );

  @override
  EduDensity copyWith({
    double? gap,
    double? panelPadding,
    double? sectionGap,
    double? rowHeight,
    double? buttonHeight,
  }) => EduDensity(
    gap: gap ?? this.gap,
    panelPadding: panelPadding ?? this.panelPadding,
    sectionGap: sectionGap ?? this.sectionGap,
    rowHeight: rowHeight ?? this.rowHeight,
    buttonHeight: buttonHeight ?? this.buttonHeight,
  );

  @override
  EduDensity lerp(EduDensity? other, double t) => other ?? this;
}
```

`edubox_flutter/lib/src/theme/edu_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'theme_extensions.dart';
import 'tokens.dart';

/// Builds one text style. Every style sets an explicit line height and
/// `leadingDistribution: even`, so stacked Vietnamese marks never clip.
TextStyle eduTextStyle({
  required String family,
  required FontWeight weight,
  required double size,
  required double lineHeight,
  double tracking = 0,
  Color color = EduColors.ink,
}) => TextStyle(
  fontFamily: family,
  fontWeight: weight,
  fontSize: size,
  height: lineHeight / size,
  letterSpacing: tracking,
  color: color,
  leadingDistribution: TextLeadingDistribution.even,
);

/// The type scale of app-direction section 4.2.
TextTheme buildEduTextTheme() => TextTheme(
  displayLarge: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 32,
    lineHeight: 40,
    tracking: -0.4,
  ),
  displayMedium: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 28,
    lineHeight: 36,
    tracking: -0.3,
  ),
  displaySmall: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 24,
    lineHeight: 32,
    tracking: -0.2,
  ),
  headlineLarge: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 24,
    lineHeight: 32,
    tracking: -0.2,
  ),
  headlineMedium: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 20,
    lineHeight: 28,
  ),
  headlineSmall: eduTextStyle(
    family: EduFonts.display,
    weight: FontWeight.w600,
    size: 20,
    lineHeight: 28,
  ),
  titleLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 18,
    lineHeight: 26,
  ),
  titleMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 16,
    lineHeight: 24,
  ),
  titleSmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 14,
    lineHeight: 20,
  ),
  bodyLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 16,
    lineHeight: 24,
  ),
  bodyMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 14,
    lineHeight: 20,
  ),
  bodySmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w400,
    size: 12,
    lineHeight: 18,
    color: EduColors.muted,
  ),
  labelLarge: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w600,
    size: 16,
    lineHeight: 24,
  ),
  labelMedium: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w500,
    size: 12,
    lineHeight: 16,
  ),
  labelSmall: eduTextStyle(
    family: EduFonts.body,
    weight: FontWeight.w500,
    size: 12,
    lineHeight: 16,
  ),
);

/// The explicit colour scheme of app-direction section 4.1.
/// Never `ColorScheme.fromSeed`.
const ColorScheme eduColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: EduColors.accent,
  onPrimary: EduColors.sheet,
  primaryContainer: EduColors.accentPale,
  onPrimaryContainer: EduColors.accentInk,
  secondary: EduColors.muted,
  onSecondary: EduColors.sheet,
  secondaryContainer: EduColors.active,
  onSecondaryContainer: EduColors.ink,
  tertiary: EduColors.muted,
  onTertiary: EduColors.sheet,
  tertiaryContainer: EduColors.neutralFill,
  onTertiaryContainer: EduColors.neutralInk,
  error: EduColors.negative,
  onError: EduColors.sheet,
  errorContainer: EduColors.negativeFill,
  onErrorContainer: EduColors.negativeInk,
  surface: EduColors.paper,
  onSurface: EduColors.ink,
  onSurfaceVariant: EduColors.muted,
  surfaceContainerLowest: EduColors.sheet,
  surfaceContainerLow: EduColors.hover,
  surfaceContainer: EduColors.surfaceFallback,
  surfaceContainerHigh: EduColors.active,
  surfaceContainerHighest: EduColors.rule,
  surfaceBright: EduColors.sheet,
  surfaceDim: EduColors.surfaceDim,
  outline: EduColors.control,
  outlineVariant: EduColors.rule,
  shadow: EduColors.ink,
  scrim: EduColors.ink,
  inverseSurface: EduColors.ink,
  onInverseSurface: EduColors.paper,
  inversePrimary: EduColors.inverseAccent,
  surfaceTint: Colors.transparent,
);

RoundedRectangleBorder _radius(double r, {BorderSide side = BorderSide.none}) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(r),
      side: side,
    );

/// The one app theme (light only in phase 1).
ThemeData buildEduTheme() {
  final text = buildEduTextTheme();
  const floatShadow = Color(0x2E191E29); // ink at 18%.
  final ruleSide = const BorderSide(
    color: EduColors.rule,
    width: EduSize.hairline,
  );
  final buttonShape = _radius(EduRadius.control);
  return ThemeData(
    useMaterial3: true,
    colorScheme: eduColorScheme,
    textTheme: text,
    scaffoldBackgroundColor: EduColors.paper,
    canvasColor: EduColors.paper,
    dividerColor: EduColors.rule,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    iconTheme: const IconThemeData(color: EduColors.muted, size: 20),
    appBarTheme: AppBarThemeData(
      backgroundColor: EduColors.paper,
      foregroundColor: EduColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: text.headlineLarge,
      iconTheme: const IconThemeData(color: EduColors.muted, size: 20),
      actionsIconTheme: const IconThemeData(color: EduColors.muted, size: 20),
    ),
    cardTheme: CardThemeData(
      color: EduColors.sheet,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: _radius(EduRadius.panel, side: ruleSide),
    ),
    dividerTheme: const DividerThemeData(
      color: EduColors.rule,
      thickness: EduSize.hairline,
      space: EduSize.hairline,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: EduColors.accent,
        foregroundColor: EduColors.sheet,
        disabledBackgroundColor: EduColors.active,
        disabledForegroundColor: EduColors.disabled,
        minimumSize: const Size(64, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: EduColors.sheet,
        foregroundColor: EduColors.ink,
        disabledForegroundColor: EduColors.disabled,
        side: const BorderSide(color: EduColors.control),
        minimumSize: const Size(64, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EduColors.ink,
        disabledForegroundColor: EduColors.disabled,
        minimumSize: const Size(EduSize.tapTarget, EduSize.tapTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: EduSpace.s12),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: EduColors.muted,
        minimumSize: const Size(EduSize.tapTarget, EduSize.tapTarget),
        iconSize: 20,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: EduColors.sheet,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EduSpace.s16,
        vertical: EduSpace.s16,
      ),
      errorMaxLines: 3,
      errorStyle: eduTextStyle(
        family: EduFonts.body,
        weight: FontWeight.w400,
        size: 14,
        lineHeight: 20,
        color: EduColors.negative,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.control),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.negative, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EduRadius.control),
        borderSide: const BorderSide(color: EduColors.negative, width: 2),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: EduColors.paper,
      elevation: 0,
      indicatorColor: EduColors.active,
      indicatorShape: _radius(EduRadius.control),
      useIndicator: true,
      selectedIconTheme: const IconThemeData(color: EduColors.ink, size: 20),
      unselectedIconTheme: const IconThemeData(
        color: EduColors.muted,
        size: 20,
      ),
      selectedLabelTextStyle: text.labelMedium,
      unselectedLabelTextStyle: text.labelMedium!.copyWith(
        color: EduColors.muted,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: EduColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: EduColors.active,
      indicatorShape: _radius(EduRadius.control),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: EduColors.muted, size: 20),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: EduColors.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: floatShadow,
      barrierColor: const Color(0x66191E29), // ink at 40%.
      shape: _radius(EduRadius.panel),
      titleTextStyle: text.headlineMedium,
      contentTextStyle: text.bodyLarge,
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(EduColors.sheet),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(floatShadow),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(EduRadius.panel)),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        foregroundColor: EduColors.ink,
        minimumSize: const Size(160, EduSize.tapTarget),
        textStyle: text.bodyLarge,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: EduColors.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: floatShadow,
      shape: _radius(EduRadius.panel),
      textStyle: text.bodyLarge,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: EduColors.ink,
        borderRadius: BorderRadius.circular(EduRadius.small),
      ),
      textStyle: text.bodySmall!.copyWith(color: EduColors.paper),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: EduColors.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: EduColors.paper),
      actionTextColor: EduColors.inverseAccent,
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: EduColors.accent,
      linearTrackColor: EduColors.active,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: EduColors.accent,
      selectionColor: EduColors.accentPale,
      selectionHandleColor: EduColors.accent,
    ),
    extensions: [
      const EduPalette(),
      EduTypeExtras(
        figure: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w500,
          size: 16,
          lineHeight: 24,
        ),
        figureTeacher: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w500,
          size: 14,
          lineHeight: 20,
        ),
        timestamp: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w400,
          size: 12,
          lineHeight: 18,
          color: EduColors.muted,
        ),
        monoBody: eduTextStyle(
          family: EduFonts.mono,
          weight: FontWeight.w400,
          size: 14,
          lineHeight: 20,
        ),
      ),
      EduDensity.student,
    ],
  );
}
```

`edubox_flutter/lib/src/theme/font_licenses.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The OFL licence files bundled with the three font families.
const Map<String, String> eduFontLicenseAssets = {
  'Bitter': 'assets/fonts/licenses/Bitter-OFL.txt',
  'Be Vietnam Pro': 'assets/fonts/licenses/BeVietnamPro-OFL.txt',
  'IBM Plex Mono': 'assets/fonts/licenses/IBMPlexMono-OFL.txt',
};

/// Registers each bundled font's OFL text with the licence page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final entry in eduFontLicenseAssets.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
```

- [ ] **Step 7: Run the tests and create the goldens**

Run: `flutter test --update-goldens test/theme`
Expected: `All tests passed!` and two new PNGs in `test/theme/goldens/`.
Run: `flutter test test/theme`
Expected: `All tests passed!` (6 theme tests + 2 golden tests).

- [ ] **Step 8: Look at the two goldens**

Open `test/theme/goldens/vietnamese_marks_1.0x.png` and `vietnamese_marks_2.0x.png`.
Check: every line shows "ẬẤỖỘỄ ặỵ Đđ"; the top marks (the hat plus the tilde or accent) and the bottom dots are complete on every line; the first lines are the serif Bitter, the middle lines the sans Be Vietnam Pro, the last three lines the monospace IBM Plex Mono; no glyph is a box.
If any mark is cut, the line height of that style is wrong; fix `lib/src/theme/edu_theme.dart`, never the test.

- [ ] **Step 9: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 10: Commit**

```bash
git add edubox_flutter/lib/src/theme/tokens.dart \
  edubox_flutter/lib/src/theme/breakpoints.dart \
  edubox_flutter/lib/src/theme/theme_extensions.dart \
  edubox_flutter/lib/src/theme/edu_theme.dart \
  edubox_flutter/lib/src/theme/font_licenses.dart \
  edubox_flutter/test/flutter_test_config.dart \
  edubox_flutter/test/theme/edu_theme_test.dart \
  edubox_flutter/test/theme/vietnamese_marks_golden_test.dart \
  edubox_flutter/pubspec.yaml \
  edubox_flutter/assets/fonts \
  edubox_flutter/test/theme/goldens
git commit -m "feat: theme tokens and bundled fonts for phase 1"
```


---

## Task 2: Scanner `+` concatenation branch and the uncovered-forms sentence (carried LOW item)

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: YES, authorized by the orchestrator for this task only (`edubox_flutter/test/l10n/literal_string_scanner.dart`, `edubox_flutter/test/l10n/literal_strings_test.dart`, one passage of `docs/build/phase-1/contract.md`); visual review: no.

**Files:**
- Modify: `edubox_flutter/test/l10n/literal_string_scanner.dart` (the `_literalOperands` doc comment and its `BinaryExpression` branch)
- Modify: `edubox_flutter/test/l10n/literal_strings_test.dart` (the planted source and the two expected lists)
- Modify: `docs/build/phase-1/contract.md` (section 3.8, the "Tests:" paragraph)

**Interfaces:**
- Consumes: the existing scanner (`findLiteralStrings`).
- Produces: the scanner also reports a literal inside `+` concatenation (`Text('Chào ' + name)`); contract.md names the two uncovered forms that frontend code must not use.

Why: contract review r3 carried this LOW item: the scanner missed `+` concatenation, a variable reference and a literal method target, and contract.md listed only the covered forms, so an executor could read the uncovered forms as allowed.

- [ ] **Step 1: Plant the failing cases in the self-test**

In `edubox_flutter/test/l10n/literal_strings_test.dart`, replace:

```dart
  SelectableText('Chọn');
  Text(AppLocalizations.of(context)!.retry);
}
```

with:

```dart
  SelectableText('Chọn');
  Text('Chào ' + name!);
  Text(name! + ' ơi' + '!');
  Text(AppLocalizations.of(context)!.retry);
}
```

Replace the test name line:

```dart
    'the scanner catches every widget-call form, including nested expressions',
```

with:

```dart
    'the scanner catches every widget-call form, including nested expressions '
    'and + concatenation',
```

In the expected slot list, replace:

```dart
          'TextSpan.text',
          'SelectableText(...)',
        ],
      );
```

with:

```dart
          'TextSpan.text',
          'SelectableText(...)',
          'Text(...)',
          'Text(...)',
          'Text(...)',
        ],
      );
```

In the expected position list, replace:

```dart
          '18:18',
          '19:18',
        ],
```

with:

```dart
          '18:18',
          '19:18',
          '20:8',
          '21:16',
          '21:24',
        ],
```

- [ ] **Step 2: Run the self-test to verify it fails**

Run: `flutter test test/l10n/literal_strings_test.dart`
Expected: FAIL in `the scanner catches every widget-call form, including nested expressions and + concatenation`, with `Expected: [...]` listing 22 slots and `Actual:` listing 19 (the three `+` literals are not reported yet).

- [ ] **Step 3: Add the `+` branch to the scanner**

In `edubox_flutter/test/l10n/literal_string_scanner.dart`, replace:

```dart
  /// Unwraps expressions that can contain a hardcoded string: parentheses,
  /// `condition ? 'a' : 'b'`, `'a' ?? 'b'`, and casts.
  static Iterable<Expression> _literalOperands(Expression expression) sync* {
    if (expression is ParenthesizedExpression) {
      yield* _literalOperands(expression.expression);
    } else if (expression is ConditionalExpression) {
      yield* _literalOperands(expression.thenExpression);
      yield* _literalOperands(expression.elseExpression);
    } else if (expression is BinaryExpression &&
        expression.operator.type == TokenType.QUESTION_QUESTION) {
```

with:

```dart
  /// Unwraps expressions that can contain a hardcoded string: parentheses,
  /// `condition ? 'a' : 'b'`, `'a' ?? 'b'`, `'a' + b` concatenation, and
  /// casts.
  static Iterable<Expression> _literalOperands(Expression expression) sync* {
    if (expression is ParenthesizedExpression) {
      yield* _literalOperands(expression.expression);
    } else if (expression is ConditionalExpression) {
      yield* _literalOperands(expression.thenExpression);
      yield* _literalOperands(expression.elseExpression);
    } else if (expression is BinaryExpression &&
        (expression.operator.type == TokenType.QUESTION_QUESTION ||
            expression.operator.type == TokenType.PLUS)) {
```

- [ ] **Step 4: Run the l10n tests to verify they pass**

Run: `flutter test test/l10n`
Expected: `All tests passed!` (the planted `+` cases are reported at 20:8, 21:16 and 21:24, and `lib/` still has no violation).

- [ ] **Step 5: Name the uncovered forms in contract.md**

In `docs/build/phase-1/contract.md` section 3.8, replace:

```text
(`Text(isOn ? 'Bật' : 'Tắt')`), `??`, and `as` casts, so a literal nested in
those forms is still reported. The scanner has a self-test that asserts the
```

with:

```text
(`Text(isOn ? 'Bật' : 'Tắt')`), `??`, `+` concatenation
(`Text('Chào ' + name)`), and `as` casts, so a literal nested in those forms is
still reported. Two forms remain uncovered, and frontend code must not use
them: a literal reached through a variable reference
(`const x = '...'; Text(x)`) and a literal used as a method target
(`Text('xin chào'.toUpperCase())`). The scanner has a self-test that asserts the
```

Run: `git -C .. diff --stat docs/build/phase-1/contract.md`
Expected: `1 file changed`, only that passage.
- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/test/l10n/literal_string_scanner.dart \
  edubox_flutter/test/l10n/literal_strings_test.dart \
  docs/build/phase-1/contract.md
git commit -m "test: scanner catches + concatenation; contract names uncovered forms"
```


---

## Task 3: Production network source (`ProbedNetworkController`)

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: no.

**Files:**
- Create: `edubox_flutter/lib/src/network/probed_network_controller.dart`, `edubox_flutter/lib/src/network/platform_sources.dart`
- Modify: `edubox_flutter/pubspec.yaml` (add `connectivity_plus: ^7.3.2` and `http: ^1.6.0`; both are already in the workspace lock at 7.3.2 and 1.6.0)
- Test: `edubox_flutter/test/network/probed_network_controller_test.dart`

**Interfaces:**
- Consumes: the frozen `NetworkController` and `NetworkStatus` (`lib/src/contract/network_controller.dart`), `BackendConfig`.
- Produces: `abstract interface class ConnectivitySource { Future<bool> hasNetwork(); Stream<bool> get changes; }`; `abstract interface class ReachabilityProbe { Future<bool> isReachable(); }`; `class ProbedNetworkController extends ChangeNotifier implements NetworkController` with `ProbedNetworkController({required ConnectivitySource connectivity, required ReachabilityProbe probe, Duration probeInterval = const Duration(seconds: 15)})`, `Future<void> start()`, `Future<void> probeNow()`; `ConnectivityPlusSource`; `HttpReachabilityProbe(BackendConfig config, {http.Client? client, Duration timeout})` that GETs `<server root>/readyz`; `String serverRootUrl(BackendConfig)` (the URL without trailing slashes, used by every client and probe).

Why: exit criterion 8 and contract section 3.5: connectivity events plus a server reachability probe; "network connected but server unreachable" is offline; recovery when the probe succeeds again; probe failures never throw into the UI.
The probe uses `/readyz`, the route the compose healthcheck and CI already use on port 8080.

- [ ] **Step 1: Add the dependencies**

`edubox_flutter/pubspec.yaml` (replace the whole file):

```yaml
name: edubox_flutter
description: EduBox Android app (phase 1 contract scaffold).
publish_to: 'none'

version: 0.1.0+1

environment:
  sdk: ^3.12.2
  flutter: ^3.44.4

resolution: workspace

dependencies:
  connectivity_plus: ^7.3.2
  drift: '>=2.34.0 <2.35.0'
  edubox_client:
    path: ../edubox_client
  edubox_fixtures:
    path: ../edubox_fixtures
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  http: ^1.6.0
  intl: any
  path: ^1.9.0
  path_provider: ^2.1.6
  serverpod_auth_idp_flutter: 4.0.4
  serverpod_flutter: 4.0.4
  sqlite3: ^3.8.0

dev_dependencies:
  analyzer: any
  build_runner: '>=2.10.0 <2.17.0'
  # Pinned: serverpod_database 4.0.4 needs sqlparser ^0.44 in the shared
  # workspace resolution; drift_dev 2.34.1+1 is the newest unretracted release on
  # sqlparser 0.44.
  drift_dev: 2.34.1+1
  flutter_lints: '>=3.0.0 <7.0.0'
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

dependency_overrides:
  flutter_secure_storage: ^10.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/fonts/licenses/
  fonts:
    - family: Bitter
      fonts:
        - asset: assets/fonts/Bitter-SemiBold.ttf
          weight: 600
    - family: BeVietnamPro
      fonts:
        - asset: assets/fonts/BeVietnamPro-Regular.ttf
          weight: 400
        - asset: assets/fonts/BeVietnamPro-Medium.ttf
          weight: 500
        - asset: assets/fonts/BeVietnamPro-SemiBold.ttf
          weight: 600
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexMono-Medium.ttf
          weight: 500
```

Run `dart pub get` in the repo root; expected `Got dependencies!`.
Run `git -C .. diff --stat pubspec.lock`; expected: no change (both packages were already resolved transitively); if it changed, include it in the commit.

- [ ] **Step 2: Write the failing test**

`edubox_flutter/test/network/probed_network_controller_test.dart`:

```dart
import 'dart:async';

import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/network/platform_sources.dart';
import 'package:edubox_flutter/src/network/probed_network_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeConnectivity implements ConnectivitySource {
  _FakeConnectivity(this.up);

  bool up;
  bool throwOnCheck = false;
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> hasNetwork() async {
    if (throwOnCheck) throw StateError('platform channel failed');
    return up;
  }

  @override
  Stream<bool> get changes => controller.stream;

  Future<void> emit(bool value) async {
    up = value;
    controller.add(value);
    await pumpEventQueue();
  }
}

class _FakeProbe implements ReachabilityProbe {
  _FakeProbe(this.reachable);

  bool reachable;
  bool throws = false;
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<bool> isReachable() async {
    calls++;
    final g = gate;
    if (g != null) await g.future;
    if (throws) throw StateError('probe exploded');
    return reachable;
  }
}

void main() {
  group('ProbedNetworkController', _controllerTests);
  group('HttpReachabilityProbe', _probeTests);
}

void _controllerTests() {
  late _FakeConnectivity connectivity;
  late _FakeProbe probe;
  late ProbedNetworkController controller;
  late List<NetworkStatus> seen;

  Future<void> build({required bool up, required bool reachable}) async {
    connectivity = _FakeConnectivity(up);
    probe = _FakeProbe(reachable);
    controller = ProbedNetworkController(
      connectivity: connectivity,
      probe: probe,
      probeInterval: Duration.zero,
    );
    seen = [];
    controller.changes.listen(seen.add);
    await controller.start();
    await pumpEventQueue();
    seen.clear();
  }

  tearDown(() => controller.dispose());

  test('network up and server answering is online', () async {
    await build(up: true, reachable: true);
    expect(controller.status, NetworkStatus.online);
    expect(controller.isOnline, isTrue);
  });

  test('no network is offline without probing', () async {
    await build(up: false, reachable: true);
    expect(controller.status, NetworkStatus.offline);
    expect(probe.calls, 0);
  });

  test('network connected but server unreachable is offline', () async {
    await build(up: true, reachable: false);
    expect(controller.status, NetworkStatus.offline);
  });

  test('losing the network goes offline at once', () async {
    await build(up: true, reachable: true);
    await connectivity.emit(false);
    expect(controller.status, NetworkStatus.offline);
    expect(seen, [NetworkStatus.offline]);
  });

  test('regaining the network passes through reconnecting to online', () async {
    await build(up: false, reachable: true);
    probe.gate = Completer<void>();
    connectivity.controller.add(true);
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.reconnecting);
    probe.gate!.complete();
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.online);
    expect(seen, [NetworkStatus.reconnecting, NetworkStatus.online]);
  });

  test(
    'regaining the network with the server still down stays offline',
    () async {
      await build(up: false, reachable: false);
      await connectivity.emit(true);
      expect(controller.status, NetworkStatus.offline);
      expect(seen, [NetworkStatus.reconnecting, NetworkStatus.offline]);
    },
  );

  test('recovers to online when the probe succeeds again', () async {
    await build(up: true, reachable: false);
    expect(controller.status, NetworkStatus.offline);
    probe.reachable = true;
    await controller.probeNow();
    expect(controller.status, NetworkStatus.online);
  });

  test('a throwing probe is offline and never escapes', () async {
    await build(up: true, reachable: true);
    probe.throws = true;
    await expectLater(controller.probeNow(), completes);
    expect(controller.status, NetworkStatus.offline);
  });

  test('a throwing connectivity check or stream is offline', () async {
    connectivity = _FakeConnectivity(true)..throwOnCheck = true;
    probe = _FakeProbe(true);
    controller = ProbedNetworkController(
      connectivity: connectivity,
      probe: probe,
      probeInterval: Duration.zero,
    );
    await controller.start();
    expect(controller.status, NetworkStatus.offline);
    connectivity.controller.addError(StateError('stream failed'));
    await pumpEventQueue();
    expect(controller.status, NetworkStatus.offline);
  });

  test('listeners are notified on each transition', () async {
    await build(up: true, reachable: true);
    var notified = 0;
    controller.addListener(() => notified++);
    await connectivity.emit(false);
    await connectivity.emit(true);
    expect(notified, 3);
  });
}

void _probeTests() {
  const config = BackendConfig(serverUrl: 'http://10.0.2.2:8080');

  test('200 on /readyz is reachable', () async {
    Uri? asked;
    final probe = HttpReachabilityProbe(
      config,
      client: MockClient((request) async {
        asked = request.url;
        return http.Response('ok', 200);
      }),
    );
    expect(await probe.isReachable(), isTrue);
    expect(asked.toString(), 'http://10.0.2.2:8080/readyz');
  });

  test('a trailing slash in the server URL is ignored', () async {
    Uri? asked;
    final probe = HttpReachabilityProbe(
      const BackendConfig(serverUrl: 'http://10.0.2.2:8080/'),
      client: MockClient((request) async {
        asked = request.url;
        return http.Response('ok', 200);
      }),
    );
    expect(await probe.isReachable(), isTrue);
    expect(asked.toString(), 'http://10.0.2.2:8080/readyz');
  });

  test('a non-200 answer is unreachable', () async {
    final probe = HttpReachabilityProbe(
      config,
      client: MockClient((_) async => http.Response('starting', 503)),
    );
    expect(await probe.isReachable(), isFalse);
  });

  test('a socket error or timeout is unreachable, never thrown', () async {
    final failing = HttpReachabilityProbe(
      config,
      client: MockClient((_) async => throw http.ClientException('refused')),
    );
    expect(await failing.isReachable(), isFalse);
    final slow = HttpReachabilityProbe(
      config,
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('ok', 200);
      }),
    );
    expect(await slow.isReachable(), isFalse);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/network`
Expected: FAIL with `Error when reading 'lib/src/network/platform_sources.dart'` (or `probed_network_controller.dart`).

- [ ] **Step 4: Write the implementation**

`edubox_flutter/lib/src/network/probed_network_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contract/network_controller.dart';

/// Whether the device has any network interface up (Wi-Fi, mobile,
/// Ethernet). It says nothing about whether the EduBox server answers.
abstract interface class ConnectivitySource {
  Future<bool> hasNetwork();

  /// Emits on every interface change: true when any interface is up.
  Stream<bool> get changes;
}

/// Asks the EduBox server whether it answers. Must never throw: a failure
/// is `false`.
abstract interface class ReachabilityProbe {
  Future<bool> isReachable();
}

/// The production [NetworkController] (contract.md section 3.5).
///
/// It combines connectivity events with a server reachability probe:
/// - no interface up: [NetworkStatus.offline];
/// - interface up but the server does not answer: [NetworkStatus.offline];
/// - interface regained: [NetworkStatus.reconnecting] while the probe runs,
///   then online or offline by the probe result;
/// - a successful probe while offline recovers to online.
///
/// [probeInterval] re-probes on a timer so a server that comes back (or goes
/// away) is noticed without a connectivity event. Probe and stream failures
/// surface as offline and are never rethrown.
class ProbedNetworkController extends ChangeNotifier
    implements NetworkController {
  ProbedNetworkController({
    required this.connectivity,
    required this.probe,
    this.probeInterval = const Duration(seconds: 15),
  });

  final ConnectivitySource connectivity;
  final ReachabilityProbe probe;
  final Duration probeInterval;

  final StreamController<NetworkStatus> _changes =
      StreamController<NetworkStatus>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  Timer? _timer;
  bool _hasNetwork = false;
  bool _disposed = false;
  NetworkStatus _status = NetworkStatus.offline;

  @override
  NetworkStatus get status => _status;

  @override
  bool get isOnline => _status == NetworkStatus.online;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  /// Reads the first state and starts listening. Call once.
  Future<void> start() async {
    _connectivitySub = connectivity.changes.listen(
      (up) => unawaited(_onConnectivity(up)),
      onError: (Object _) => _set(NetworkStatus.offline),
    );
    _hasNetwork = await _safeHasNetwork();
    await probeNow();
    if (probeInterval > Duration.zero) {
      _timer = Timer.periodic(probeInterval, (_) => unawaited(probeNow()));
    }
  }

  /// Probes the server now and updates [status]. Never throws.
  Future<void> probeNow() async {
    if (!_hasNetwork) {
      _set(NetworkStatus.offline);
      return;
    }
    final reachable = await _safeProbe();
    if (_disposed) return;
    if (!_hasNetwork) {
      _set(NetworkStatus.offline);
      return;
    }
    _set(reachable ? NetworkStatus.online : NetworkStatus.offline);
  }

  Future<void> _onConnectivity(bool up) async {
    final wasUp = _hasNetwork;
    _hasNetwork = up;
    if (!up) {
      _set(NetworkStatus.offline);
      return;
    }
    if (!wasUp || _status != NetworkStatus.online) {
      _set(NetworkStatus.reconnecting);
    }
    await probeNow();
  }

  Future<bool> _safeHasNetwork() async {
    try {
      return await connectivity.hasNetwork();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeProbe() async {
    try {
      return await probe.isReachable();
    } catch (_) {
      return false;
    }
  }

  void _set(NetworkStatus value) {
    if (_disposed || value == _status) return;
    _status = value;
    _changes.add(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_connectivitySub?.cancel());
    unawaited(_changes.close());
    super.dispose();
  }
}
```

`edubox_flutter/lib/src/network/platform_sources.dart`:

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../contract/backend_config.dart';
import 'probed_network_controller.dart';

/// The server's base URL without trailing slashes, so
/// `--dart-define=EDUBOX_SERVER_URL=http://10.0.2.2:8080/` and the default
/// `http://10.0.2.2:8080` give the same routes.
String serverRootUrl(BackendConfig config) =>
    config.serverUrl.replaceFirst(RegExp(r'/+$'), '');

/// [ConnectivitySource] over `connectivity_plus`.
class ConnectivityPlusSource implements ConnectivitySource {
  ConnectivityPlusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _anyUp(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> hasNetwork() async =>
      _anyUp(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes => _connectivity.onConnectivityChanged.map(_anyUp);
}

/// [ReachabilityProbe] that GETs the server's `/readyz` (the same route the
/// compose healthcheck uses). Any status other than 200, a timeout or a
/// socket error is "unreachable".
class HttpReachabilityProbe implements ReachabilityProbe {
  HttpReachabilityProbe(
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  final BackendConfig config;
  final Duration timeout;
  final http.Client _client;

  Uri get readyUri => Uri.parse('${serverRootUrl(config)}/readyz');

  @override
  Future<bool> isReachable() async {
    try {
      final response = await _client.get(readyUri).timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/network`
Expected: `All tests passed!` (14 tests).

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/network/probed_network_controller.dart \
  edubox_flutter/lib/src/network/platform_sources.dart \
  edubox_flutter/test/network/probed_network_controller_test.dart \
  edubox_flutter/pubspec.yaml
git commit -m "feat: probed network controller with readyz reachability"
```


---

## Task 4: Production data layer (`CachedBackend` over the generated client)

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none (reads `test/contract/contract_suite.dart` without editing it); visual review: no.

**Files:**
- Create: `edubox_flutter/lib/src/data/edubox_api.dart`, `error_mapping.dart`, `client_edubox_api.dart`, `cached_backend.dart`
- Modify: `edubox_flutter/pubspec.yaml` (add `serverpod_auth_idp_client: 4.0.4`, the same pin the workspace already resolves)
- Test: `edubox_flutter/test/data/fixture_api.dart`, `cached_backend_contract_test.dart`, `cached_backend_test.dart`, `error_mapping_test.dart`

**Interfaces:**
- Consumes: the frozen `EduBoxBackend`, repository interfaces, `BackendResult`/`BackendError`, `AuthSession`, `ParentHomeData`, `NetworkController`, `CachedDataStore` (`lib/src/local/local_store.dart`), the generated `Client` (`emailIdp.login`, `profile.me`, `classes.mine`, `content.library`, `diagnostics.pingStream`), `FlutterAuthSessionManager`.
- Produces: `abstract interface class EduBoxApi` (`login`, `restoreStoredAuth`, `profileMe`, `classesMine`, `contentLibrary`, `pingStream`, `signOut`, `clearStoredAuth`, `close`); `ClientEduBoxApi.create(BackendConfig)`; `BackendError mapApiError(Object error)`; `class CachedBackend implements EduBoxBackend` with `CachedBackend({required EduBoxApi api, required CachedDataStore store, required NetworkController network})`, fields `api`, `store`, `network`, `Future<void> reconnectRefresh`; `dispose()` closes the API and the store.

Behaviour (contract sections 2.4, 3.2-3.5): online calls hit the server, save the snapshot and return `BackendOk(value, cachedAt: <snapshot time>)`; offline or reconnecting reads never dial and return the snapshot with `isStale: true` or `OfflineNoCacheError`; `signIn` and `refreshProfile` fail fast offline with `BackendUnreachableError`; `restoreSession` offline returns the cached session as stale; `signOut` clears the stored auth and the whole cache even offline; on `offline|reconnecting -> online` the backend refreshes `profile.me` and the signed-in role home.
Error mapping: `EmailAccountLoginException(invalidCredentials)` -> `WrongCredentialsError`, `(tooManyAttempts)` -> `TooManyAttemptsError`, other reasons -> `UnexpectedBackendError`; `AuthUserBlockedException` -> `AccountDisabledError`; `AccessDeniedException(notSetUp|wrongRole|unauthenticated)` -> `NotSetUpError|PermissionDeniedError|SessionExpiredError`; `ServerpodClientUnauthorized` and refresh-token exceptions -> `SessionExpiredError`; `ServerpodClientNetworkException`, `SocketException`, `TimeoutException`, `HttpException` -> `BackendUnreachableError`; anything else -> `UnexpectedBackendError(cause)`.
The host tests use `FixtureEduBoxApi`, a fixture-backed stand-in that throws the same exception types the generated client throws (host `flutter test` has no secure-storage plugin), and run the frozen contract suite against `CachedBackend`.

- [ ] **Step 1: Add the dependency**

`edubox_flutter/pubspec.yaml` (replace the whole file):

```yaml
name: edubox_flutter
description: EduBox Android app (phase 1 contract scaffold).
publish_to: 'none'

version: 0.1.0+1

environment:
  sdk: ^3.12.2
  flutter: ^3.44.4

resolution: workspace

dependencies:
  connectivity_plus: ^7.3.2
  drift: '>=2.34.0 <2.35.0'
  edubox_client:
    path: ../edubox_client
  edubox_fixtures:
    path: ../edubox_fixtures
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  http: ^1.6.0
  intl: any
  path: ^1.9.0
  path_provider: ^2.1.6
  serverpod_auth_idp_client: 4.0.4
  serverpod_auth_idp_flutter: 4.0.4
  serverpod_flutter: 4.0.4
  sqlite3: ^3.8.0

dev_dependencies:
  analyzer: any
  build_runner: '>=2.10.0 <2.17.0'
  # Pinned: serverpod_database 4.0.4 needs sqlparser ^0.44 in the shared
  # workspace resolution; drift_dev 2.34.1+1 is the newest unretracted release on
  # sqlparser 0.44.
  drift_dev: 2.34.1+1
  flutter_lints: '>=3.0.0 <7.0.0'
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

dependency_overrides:
  flutter_secure_storage: ^10.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/fonts/licenses/
  fonts:
    - family: Bitter
      fonts:
        - asset: assets/fonts/Bitter-SemiBold.ttf
          weight: 600
    - family: BeVietnamPro
      fonts:
        - asset: assets/fonts/BeVietnamPro-Regular.ttf
          weight: 400
        - asset: assets/fonts/BeVietnamPro-Medium.ttf
          weight: 500
        - asset: assets/fonts/BeVietnamPro-SemiBold.ttf
          weight: 600
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/IBMPlexMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexMono-Medium.ttf
          weight: 500
```

Run `dart pub get` in the repo root; expected `Got dependencies!`; include `pubspec.lock` in the commit only if it changed.

- [ ] **Step 2: Write the failing tests**

`edubox_flutter/test/data/fixture_api.dart`:

```dart
import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/data/edubox_api.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason;

/// A host-side stand-in for the Serverpod server: it answers from the phase 1
/// fixtures and throws the same exception types the generated client throws,
/// so `CachedBackend` and `mapApiError` are tested end to end without a
/// server or the secure-storage plugin.
class FixtureEduBoxApi implements EduBoxApi {
  FixtureEduBoxApi({this.unreachable = false});

  /// True models a closed port: every call throws a network exception.
  bool unreachable;

  FixtureSet fixtures = FixtureSet.phase1();
  final Map<String, String?> _roleOverrides = {};
  final Map<String, int> _failedLogins = {};
  String? _storedAccountKey;

  /// Number of server calls made (offline paths must not add to it).
  int calls = 0;

  void setRole(String accountKey, String? role) =>
      _roleOverrides[accountKey] = role;

  void _dial() {
    calls++;
    if (unreachable) {
      throw const ServerpodClientNetworkException('connection refused');
    }
  }

  AccountFixture _caller() {
    final key = _storedAccountKey;
    if (key == null) throw ServerpodClientUnauthorized();
    return fixtures.account(key);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    _dial();
    final normalized = email.trim().toLowerCase();
    if ((_failedLogins[normalized] ?? 0) >= 5) {
      throw EmailAccountLoginException(
        reason: EmailAccountLoginExceptionReason.tooManyAttempts,
      );
    }
    final account = fixtures.accountByEmail(normalized);
    if (account == null || password != devPassword) {
      _failedLogins[normalized] = (_failedLogins[normalized] ?? 0) + 1;
      throw EmailAccountLoginException(
        reason: EmailAccountLoginExceptionReason.invalidCredentials,
      );
    }
    if (account.blocked) throw AuthUserBlockedException();
    _failedLogins.remove(normalized);
    _storedAccountKey = account.key;
  }

  @override
  Future<bool> restoreStoredAuth() async => _storedAccountKey != null;

  @override
  Future<ProfileResult> profileMe() async {
    _dial();
    return _profileOf(_caller());
  }

  @override
  Future<List<ClassSummary>> classesMine() async {
    _dial();
    final caller = _requireRole(UserRole.teacher);
    return [
      for (final (index, item) in fixtures.classesOfTeacher(caller.key).indexed)
        ClassSummary(
          id: index + 1,
          name: item.name,
          gradeLevel: item.gradeLevel,
          subjects: List.of(item.subjects),
          studentCount: item.studentKeys.length,
        ),
    ];
  }

  @override
  Future<StudentLibrary> contentLibrary() async {
    _dial();
    final caller = _requireRole(UserRole.student);
    return StudentLibrary(
      classes: [
        for (final (index, item)
            in fixtures.classesOfStudent(caller.key).indexed)
          StudentClass(
            id: index + 1,
            name: item.name,
            gradeLevel: item.gradeLevel,
            subjects: List.of(item.subjects),
          ),
      ],
      items: [
        for (final (index, item)
            in fixtures.libraryOfStudent(caller.key).indexed)
          LibraryItem(
            id: index + 1,
            type: ContentType.values.byName(item.type.name),
            title: item.title,
            subject: item.subject,
            gradeLevel: item.gradeLevel,
            createdAt: item.createdAt,
          ),
      ],
    );
  }

  @override
  Stream<PingMessage> pingStream() async* {
    _dial();
    final profile = _profileOf(_caller());
    if (profile.status != ProfileStatus.ready) {
      throw AccessDeniedException(reason: AccessDeniedReason.notSetUp);
    }
    for (var sequence = 1; sequence <= 3; sequence++) {
      yield PingMessage(
        sequence: sequence,
        total: 3,
        role: profile.profile!.role,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    _dial();
    _storedAccountKey = null;
  }

  @override
  Future<void> clearStoredAuth() async => _storedAccountKey = null;

  @override
  Future<void> close() async {}

  AccountFixture _requireRole(UserRole role) {
    final caller = _caller();
    final profile = _profileOf(caller);
    if (profile.status != ProfileStatus.ready) {
      throw AccessDeniedException(reason: AccessDeniedReason.notSetUp);
    }
    if (profile.profile!.role != role) {
      throw AccessDeniedException(reason: AccessDeniedReason.wrongRole);
    }
    return caller;
  }

  ProfileResult _profileOf(AccountFixture account) {
    final raw = _roleOverrides.containsKey(account.key)
        ? _roleOverrides[account.key]
        : account.role;
    final role = raw == null ? null : UserRole.values.asNameMap()[raw];
    if (!account.hasProfile || role == null) {
      return ProfileResult(
        status: ProfileStatus.notSetUp,
        signedInEmail: account.email,
      );
    }
    final linkedKey = account.linkedStudentKey;
    return ProfileResult(
      status: ProfileStatus.ready,
      signedInEmail: account.email,
      profile: Profile(
        userId: fixtures.accounts.indexOf(account) + 1,
        role: role,
        name: account.name,
        email: account.email,
        linkedStudentName: linkedKey == null
            ? null
            : fixtures.account(linkedKey).name,
      ),
    );
  }
}
```

`edubox_flutter/test/data/cached_backend_contract_test.dart`:

```dart
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';

import '../contract/contract_suite.dart';
import 'fixture_api.dart';

/// Runs the frozen contract suite against the production data layer, with a
/// fixture-backed API standing in for the server.
void main() {
  final network = ManualNetworkController();
  late FixtureEduBoxApi api;
  late CachedDataStore store;

  runBackendContractTests(
    name: 'phase 1 backend contract (CachedBackend over the fixture API)',
    createBackend: () async {
      api = FixtureEduBoxApi();
      store = CachedDataStore(EduBoxDatabase.inMemory());
      return CachedBackend(api: api, store: store, network: network);
    },
    createUnreachableBackend: () async => CachedBackend(
      api: FixtureEduBoxApi(unreachable: true),
      store: CachedDataStore(EduBoxDatabase.inMemory()),
      network: ManualNetworkController(),
    ),
    network: network,
    setRole: (accountKey, role) async => api.setRole(accountKey, role),
    clearCache: () => store.clearAll(),
  );
}
```

`edubox_flutter/test/data/cached_backend_test.dart`:

```dart
import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_api.dart';

void main() {
  late ManualNetworkController network;
  late FixtureEduBoxApi api;
  late CachedDataStore store;
  late CachedBackend backend;

  setUp(() {
    network = ManualNetworkController();
    api = FixtureEduBoxApi();
    store = CachedDataStore(EduBoxDatabase.inMemory());
    backend = CachedBackend(api: api, store: store, network: network);
  });

  tearDown(() async {
    await backend.dispose();
    network.dispose();
  });

  Future<void> signIn(String key) async {
    final account = FixtureSet.phase1().account(key);
    final result = await backend.auth.signIn(
      email: account.email,
      password: devPassword,
    );
    expect(result.isOk, isTrue, reason: '$result');
  }

  test('offline sign-in and check-again fail fast without dialing', () async {
    network.goOffline();
    final signIn = await backend.auth.signIn(
      email: 'hs.an@edubox.test',
      password: devPassword,
    );
    expect(signIn.errorOrNull, isA<BackendUnreachableError>());
    final refresh = await backend.auth.refreshProfile();
    expect(refresh.errorOrNull, isA<BackendUnreachableError>());
    expect(api.calls, 0);
  });

  test('offline data reads never dial the server', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    final before = api.calls;
    network.goOffline();
    final cached = await backend.library.library();
    expect(cached.isStale, isTrue);
    await backend.profile.me();
    network.goReconnecting();
    await backend.library.library();
    expect(api.calls, before);
  });

  test(
    'sign-in trims and lower-cases the email and caches the session',
    () async {
      final result = await backend.auth.signIn(
        email: '  HS.An@EduBox.test ',
        password: devPassword,
      );
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.signedInEmail, 'hs.an@edubox.test');
      final cached = await store.readSession();
      expect(cached!.value.role, UserRole.student);
    },
  );

  test(
    'the reconnect transition refreshes the profile and the role home',
    () async {
      await signIn(FixtureKeys.teacherLan);
      expect((await backend.classes.mine()).valueOrNull, hasLength(3));
      network.goOffline();
      api.fixtures = api.fixtures.withReconnectDeltas();
      expect((await store.readTeacherClasses())!.value, hasLength(3));
      network.goOnline();
      await Future<void>.delayed(Duration.zero);
      await backend.reconnectRefresh;
      final cached = await store.readTeacherClasses();
      expect(cached!.value.map((c) => c.name), contains('8B'));
    },
  );

  test(
    'restore with no stored auth clears the cache and returns null',
    () async {
      await signIn(FixtureKeys.studentAn);
      await api.clearStoredAuth();
      final restored = await backend.auth.restoreSession();
      expect(restored.isOk, isTrue);
      expect(restored.valueOrNull, isNull);
      expect(await store.readSession(), isNull);
    },
  );

  test('restore online re-reads the role from the server', () async {
    await signIn(FixtureKeys.nullRole);
    api.setRole(FixtureKeys.nullRole, 'teacher');
    final restored = await backend.auth.restoreSession();
    expect(restored.valueOrNull!.role, UserRole.teacher);
    expect(restored.isStale, isFalse);
  });

  test('restore offline returns the cached session as stale', () async {
    await signIn(FixtureKeys.parentBinh);
    network.goOffline();
    final restored = await backend.auth.restoreSession();
    expect(restored.isStale, isTrue);
    expect(restored.valueOrNull!.role, UserRole.parent);
    expect(restored.valueOrNull!.linkedStudentName, 'Nguyễn Minh An');
  });

  test('sign-out offline clears the stored auth and the cache', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    network.goOffline();
    final result = await backend.auth.signOut();
    expect(result.isOk, isTrue);
    expect(await store.readSession(), isNull);
    expect(await store.readStudentLibrary(), isNull);
    expect(await api.restoreStoredAuth(), isFalse);
  });

  test('offline role gate uses the cached session', () async {
    await signIn(FixtureKeys.studentAn);
    await backend.library.library();
    network.goOffline();
    expect(
      (await backend.classes.mine()).errorOrNull,
      isA<PermissionDeniedError>(),
    );
  });

  test(
    'ping offline throws BackendUnreachable inside BackendException',
    () async {
      await signIn(FixtureKeys.studentAn);
      network.goOffline();
      await expectLater(
        backend.diagnostics.pingStream().toList(),
        throwsA(
          isA<BackendException>().having(
            (e) => e.error,
            'error',
            isA<BackendUnreachableError>(),
          ),
        ),
      );
    },
  );
}
```

`edubox_flutter/test/data/error_mapping_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/data/error_mapping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason;

void main() {
  test('sign-in exceptions map to the sign-in error shapes', () {
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.invalidCredentials,
        ),
      ),
      isA<WrongCredentialsError>(),
    );
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.tooManyAttempts,
        ),
      ),
      isA<TooManyAttemptsError>(),
    );
    expect(
      mapApiError(
        EmailAccountLoginException(
          reason: EmailAccountLoginExceptionReason.unknown,
        ),
      ),
      isA<UnexpectedBackendError>(),
    );
    expect(
      mapApiError(AuthUserBlockedException()),
      isA<AccountDisabledError>(),
    );
  });

  test('access denials map by reason', () {
    expect(
      mapApiError(AccessDeniedException(reason: AccessDeniedReason.notSetUp)),
      isA<NotSetUpError>(),
    );
    expect(
      mapApiError(AccessDeniedException(reason: AccessDeniedReason.wrongRole)),
      isA<PermissionDeniedError>(),
    );
    expect(
      mapApiError(
        AccessDeniedException(reason: AccessDeniedReason.unauthenticated),
      ),
      isA<SessionExpiredError>(),
    );
    expect(
      mapApiError(ServerpodClientUnauthorized()),
      isA<SessionExpiredError>(),
    );
  });

  test('transport failures are backendUnreachable', () {
    expect(
      mapApiError(const ServerpodClientNetworkException('refused')),
      isA<BackendUnreachableError>(),
    );
    expect(
      mapApiError(const SocketException('refused')),
      isA<BackendUnreachableError>(),
    );
    expect(
      mapApiError(TimeoutException('slow')),
      isA<BackendUnreachableError>(),
    );
  });

  test('anything else is unexpected and keeps its cause for logs', () {
    final error = mapApiError(StateError('boom'));
    expect(error, isA<UnexpectedBackendError>());
    expect((error as UnexpectedBackendError).cause, isA<StateError>());
    expect(
      mapApiError(ServerpodClientInternalServerError()),
      isA<UnexpectedBackendError>(),
    );
    expect(
      mapApiError(const BackendException(NotSetUpError())),
      isA<NotSetUpError>(),
    );
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/data`
Expected: FAIL with `Error when reading 'lib/src/data/edubox_api.dart'` (or another `lib/src/data/` file).

- [ ] **Step 4: Write the data layer**

`edubox_flutter/lib/src/data/edubox_api.dart`:

```dart
import 'package:edubox_client/edubox_client.dart'
    show ClassSummary, PingMessage, ProfileResult, StudentLibrary;

/// The raw server calls the data layer needs, one method per endpoint.
///
/// Every method throws the server/transport exception unchanged; the caller
/// maps it with `mapApiError`. Production is `ClientEduBoxApi` (the
/// generated Serverpod client); unit tests use a fixture-backed fake.
abstract interface class EduBoxApi {
  /// `emailIdp.login`, then stores the returned session in the auth module's
  /// session manager.
  Future<void> login({required String email, required String password});

  /// Restores the stored auth session from local secure storage without a
  /// server call. Returns true when a session is stored.
  Future<bool> restoreStoredAuth();

  /// `profile.me`.
  Future<ProfileResult> profileMe();

  /// `classes.mine`.
  Future<List<ClassSummary>> classesMine();

  /// `content.library`.
  Future<StudentLibrary> contentLibrary();

  /// `diagnostics.pingStream`.
  Stream<PingMessage> pingStream();

  /// Best-effort server sign-out; always clears the stored auth session,
  /// even when the server call fails.
  Future<void> signOut();

  /// Clears the stored auth session without a server call.
  Future<void> clearStoredAuth();

  Future<void> close();
}
```

`edubox_flutter/lib/src/data/error_mapping.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:edubox_client/edubox_client.dart'
    show
        AccessDeniedException,
        AccessDeniedReason,
        ServerpodClientException,
        ServerpodClientNetworkException,
        ServerpodClientUnauthorized;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    show
        AuthUserBlockedException,
        EmailAccountLoginException,
        EmailAccountLoginExceptionReason,
        RefreshTokenExpiredException,
        RefreshTokenInvalidSecretException,
        RefreshTokenMalformedException,
        RefreshTokenNotFoundException;

import '../contract/backend_result.dart';

/// Maps a server or transport exception to the contract's typed error
/// (contract.md section 2.4). Never throws.
BackendError mapApiError(Object error) => switch (error) {
  BackendException(:final error) => error,
  EmailAccountLoginException(:final reason) => switch (reason) {
    EmailAccountLoginExceptionReason.invalidCredentials =>
      const WrongCredentialsError(),
    EmailAccountLoginExceptionReason.tooManyAttempts =>
      const TooManyAttemptsError(),
    _ => UnexpectedBackendError(error),
  },
  AuthUserBlockedException() => const AccountDisabledError(),
  AccessDeniedException(:final reason) => switch (reason) {
    AccessDeniedReason.notSetUp => const NotSetUpError(),
    AccessDeniedReason.wrongRole => const PermissionDeniedError(),
    AccessDeniedReason.unauthenticated => const SessionExpiredError(),
  },
  ServerpodClientUnauthorized() ||
  RefreshTokenExpiredException() ||
  RefreshTokenInvalidSecretException() ||
  RefreshTokenMalformedException() ||
  RefreshTokenNotFoundException() => const SessionExpiredError(),
  ServerpodClientNetworkException() ||
  SocketException() ||
  TimeoutException() ||
  HttpException() => const BackendUnreachableError(),
  ServerpodClientException() => UnexpectedBackendError(error),
  _ => UnexpectedBackendError(error),
};
```

`edubox_flutter/lib/src/data/client_edubox_api.dart`:

```dart
import 'package:edubox_client/edubox_client.dart'
    show Client, ClassSummary, PingMessage, ProfileResult, StudentLibrary;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManager, FlutterAuthSessionManagerExtension;
import 'package:serverpod_flutter/serverpod_flutter.dart'
    show FlutterConnectivityMonitor;

import '../contract/backend_config.dart';
import '../network/platform_sources.dart' show serverRootUrl;
import 'edubox_api.dart';

/// [EduBoxApi] over the generated Serverpod client and the auth module's
/// Flutter session manager (secure storage). Used by `main.dart` and the
/// on-device integration tests; host unit tests use a fake instead because
/// `flutter test` has no secure-storage plugin.
class ClientEduBoxApi implements EduBoxApi {
  ClientEduBoxApi._(this.client, this.sessionManager);

  /// The sign-in brief's 15 s submit timeout maps to the client timeout.
  static const connectionTimeout = Duration(seconds: 15);

  factory ClientEduBoxApi.create(BackendConfig config) {
    final client = Client(
      '${serverRootUrl(config)}/',
      connectionTimeout: connectionTimeout,
    )..connectivityMonitor = FlutterConnectivityMonitor();
    final sessionManager = FlutterAuthSessionManager();
    client.authSessionManager = sessionManager;
    return ClientEduBoxApi._(client, sessionManager);
  }

  final Client client;
  final FlutterAuthSessionManager sessionManager;

  @override
  Future<void> login({required String email, required String password}) async {
    final success = await client.emailIdp.login(
      email: email,
      password: password,
    );
    await sessionManager.updateSignedInUser(success);
  }

  @override
  Future<bool> restoreStoredAuth() async {
    await sessionManager.restore();
    return sessionManager.isAuthenticated;
  }

  @override
  Future<ProfileResult> profileMe() => client.profile.me();

  @override
  Future<List<ClassSummary>> classesMine() => client.classes.mine();

  @override
  Future<StudentLibrary> contentLibrary() => client.content.library();

  @override
  Stream<PingMessage> pingStream() => client.diagnostics.pingStream();

  @override
  Future<void> signOut() async {
    // signOutDevice clears the stored session in a finally block, so the
    // device is signed out locally even when the server call fails.
    await sessionManager.signOutDevice();
  }

  @override
  Future<void> clearStoredAuth() => sessionManager.updateSignedInUser(null);

  @override
  Future<void> close() async => client.close();
}
```

`edubox_flutter/lib/src/data/cached_backend.dart`:

```dart
import 'dart:async';

import 'package:edubox_client/edubox_client.dart'
    show
        ClassSummary,
        PingMessage,
        ProfileResult,
        ProfileStatus,
        StudentLibrary,
        UserRole;

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/network_controller.dart';
import '../contract/repositories.dart';
import '../contract/session.dart';
import '../local/local_store.dart';
import 'edubox_api.dart';
import 'error_mapping.dart';

/// The production [EduBoxBackend]: the server API, the drift cache and the
/// network seam (contract.md sections 3.3-3.5).
///
/// Online it calls the server, saves the snapshot and returns
/// `isStale: false`. Offline or reconnecting it never dials the server: data
/// reads return the snapshot with `isStale: true` or `OfflineNoCacheError`,
/// and `signIn` / `refreshProfile` fail fast with `BackendUnreachableError`.
/// On every `offline|reconnecting -> online` transition it refreshes
/// `profile.me` and the signed-in role home in the background. It owns
/// [api] and [store] and closes both in [dispose].
class CachedBackend implements EduBoxBackend {
  CachedBackend({
    required this.api,
    required this.store,
    required this.network,
  }) {
    _lastStatus = network.status;
    _networkSub = network.changes.listen(_onNetworkChange);
  }

  final EduBoxApi api;
  final CachedDataStore store;
  final NetworkController network;

  late NetworkStatus _lastStatus;
  late final StreamSubscription<NetworkStatus> _networkSub;

  /// Completes when the most recent reconnect refresh finishes (tests).
  Future<void> reconnectRefresh = Future.value();

  bool get _online => network.status == NetworkStatus.online;

  @override
  late final AuthRepository auth = _Auth(this);

  @override
  late final ProfileRepository profile = _Profile(this);

  @override
  late final ClassesRepository classes = _Classes(this);

  @override
  late final LibraryRepository library = _Library(this);

  @override
  late final ParentRepository parent = _Parent(this);

  @override
  late final DiagnosticsRepository diagnostics = _Diagnostics(this);

  @override
  Future<void> dispose() async {
    await _networkSub.cancel();
    await api.close();
    await store.close();
  }

  void _onNetworkChange(NetworkStatus status) {
    final wasOffline = _lastStatus != NetworkStatus.online;
    _lastStatus = status;
    if (wasOffline && status == NetworkStatus.online) {
      reconnectRefresh = _refreshAfterReconnect();
    }
  }

  Future<void> _refreshAfterReconnect() async {
    final cached = await store.readSession();
    if (cached == null) return;
    final me = await profile.me();
    final session = me.valueOrNull;
    if (session == null || session.status != ProfileStatus.ready) return;
    switch (session.profile?.role) {
      case UserRole.student:
        await library.library();
      case UserRole.teacher:
        await classes.mine();
      case UserRole.parent:
        await parent.home();
      case null:
        break;
    }
  }

  /// Runs [call] against the server, mapping any exception.
  Future<BackendResult<T>> _guard<T>(
    Future<BackendResult<T>> Function() call,
  ) async {
    try {
      return await call();
    } catch (error) {
      return BackendFailure<T>(mapApiError(error));
    }
  }

  /// Saves the session for a fresh `profile.me` answer.
  Future<AuthSession> _saveProfile(ProfileResult result, String? email) async {
    final cached = await store.readSession();
    final session = AuthSession(
      signedInEmail:
          result.signedInEmail ?? email ?? cached?.value.signedInEmail ?? '',
      profileResult: result,
    );
    await store.saveSession(session);
    return session;
  }

  /// Offline role gate from the cached session (render-only, never an
  /// authorization decision; the server re-checks every online call).
  Future<BackendError?> _offlineRoleFailure(UserRole role) async {
    final cached = await store.readSession();
    if (cached == null) return const OfflineNoCacheError();
    final session = cached.value;
    if (session.isNotSetUp) return const NotSetUpError();
    if (session.role != role) return const PermissionDeniedError();
    return null;
  }
}

class _Auth implements AuthRepository {
  _Auth(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    if (!b._online) return const BackendFailure(BackendUnreachableError());
    final normalized = email.trim().toLowerCase();
    return b._guard(() async {
      await b.api.login(email: normalized, password: password);
      final result = await b.api.profileMe();
      final session = await b._saveProfile(result, normalized);
      final saved = await b.store.readSession();
      return BackendOk(session, cachedAt: saved?.cachedAt);
    });
  }

  @override
  Future<BackendResult<AuthSession?>> restoreSession() async {
    if (!b._online) {
      final cached = await b.store.readSession();
      if (cached == null) return const BackendOk(null);
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    final hasAuth = await b._guard<bool>(
      () async => BackendOk(await b.api.restoreStoredAuth()),
    );
    if (hasAuth case BackendFailure(:final error)) return BackendFailure(error);
    if (hasAuth.valueOrNull != true) {
      await b.store.clearAll();
      return const BackendOk(null);
    }
    final result = await _refresh();
    if (result case BackendFailure(error: SessionExpiredError())) {
      await b.api.clearStoredAuth();
      await b.store.clearAll();
      return const BackendOk(null);
    }
    return result;
  }

  @override
  Future<BackendResult<AuthSession>> refreshProfile() async {
    if (!b._online) return const BackendFailure(BackendUnreachableError());
    final hasAuth = await b._guard<bool>(
      () async => BackendOk(await b.api.restoreStoredAuth()),
    );
    if (hasAuth case BackendFailure(:final error)) return BackendFailure(error);
    if (hasAuth.valueOrNull != true) {
      return const BackendFailure(SessionExpiredError());
    }
    return _refresh();
  }

  Future<BackendResult<AuthSession>> _refresh() => b._guard(() async {
    final result = await b.api.profileMe();
    final session = await b._saveProfile(result, null);
    final saved = await b.store.readSession();
    return BackendOk(session, cachedAt: saved?.cachedAt);
  });

  @override
  Future<BackendResult<void>> signOut() async {
    if (b._online) {
      try {
        await b.api.signOut();
      } catch (_) {
        // Best effort: the local session is cleared below regardless.
        await b.api.clearStoredAuth();
      }
    } else {
      await b.api.clearStoredAuth();
    }
    try {
      await b.store.clearAll();
      return const BackendOk(null);
    } catch (error) {
      return BackendFailure(UnexpectedBackendError(error));
    }
  }
}

class _Profile implements ProfileRepository {
  _Profile(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<ProfileResult>> me() async {
    if (!b._online) {
      final cached = await b.store.readSession();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(
        cached.value.profileResult,
        cachedAt: cached.cachedAt,
        isStale: true,
      );
    }
    return b._guard(() async {
      final result = await b.api.profileMe();
      await b._saveProfile(result, null);
      final saved = await b.store.readSession();
      return BackendOk(result, cachedAt: saved?.cachedAt);
    });
  }
}

class _Classes implements ClassesRepository {
  _Classes(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<List<ClassSummary>>> mine() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.teacher);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readTeacherClasses();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final value = await b.api.classesMine();
      await b.store.saveTeacherClasses(value);
      final saved = await b.store.readTeacherClasses();
      return BackendOk(value, cachedAt: saved?.cachedAt);
    });
  }
}

class _Library implements LibraryRepository {
  _Library(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<StudentLibrary>> library() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.student);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readStudentLibrary();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final value = await b.api.contentLibrary();
      await b.store.saveStudentLibrary(value);
      final saved = await b.store.readStudentLibrary();
      return BackendOk(value, cachedAt: saved?.cachedAt);
    });
  }
}

class _Parent implements ParentRepository {
  _Parent(this.b);

  final CachedBackend b;

  @override
  Future<BackendResult<ParentHomeData>> home() async {
    if (!b._online) {
      final denial = await b._offlineRoleFailure(UserRole.parent);
      if (denial != null) return BackendFailure(denial);
      final cached = await b.store.readParentHome();
      if (cached == null) return const BackendFailure(OfflineNoCacheError());
      return BackendOk(cached.value, cachedAt: cached.cachedAt, isStale: true);
    }
    return b._guard(() async {
      final result = await b.api.profileMe();
      await b._saveProfile(result, null);
      final profile = result.profile;
      if (result.status != ProfileStatus.ready || profile == null) {
        return const BackendFailure(NotSetUpError());
      }
      if (profile.role != UserRole.parent) {
        return const BackendFailure(PermissionDeniedError());
      }
      final data = ParentHomeData(linkedStudentName: profile.linkedStudentName);
      await b.store.saveParentHome(data);
      final saved = await b.store.readParentHome();
      return BackendOk(data, cachedAt: saved?.cachedAt);
    });
  }
}

class _Diagnostics implements DiagnosticsRepository {
  _Diagnostics(this.b);

  final CachedBackend b;

  @override
  Stream<PingMessage> pingStream() {
    if (!b._online) {
      return Stream.error(const BackendException(BackendUnreachableError()));
    }
    return b.api.pingStream().handleError(
      (Object error) => throw BackendException(mapApiError(error)),
    );
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/data`
Expected: `All tests passed!` (the contract suite group, 10 `CachedBackend` tests and 4 mapping tests).

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/data/edubox_api.dart \
  edubox_flutter/lib/src/data/error_mapping.dart \
  edubox_flutter/lib/src/data/client_edubox_api.dart \
  edubox_flutter/lib/src/data/cached_backend.dart \
  edubox_flutter/test/data/fixture_api.dart \
  edubox_flutter/test/data/cached_backend_contract_test.dart \
  edubox_flutter/test/data/cached_backend_test.dart \
  edubox_flutter/test/data/error_mapping_test.dart \
  edubox_flutter/pubspec.yaml
git commit -m "feat: cached backend over the generated client with error mapping"
```


---

## Task 5: App shell core: session restore, role routing, connectivity strip, shared blocks

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (app-start goldens).

**Files:**
- Create: `edubox_flutter/lib/src/app/app_scope.dart`, `session_controller.dart`, `connectivity_state.dart`, `loadable.dart`, `formatters.dart`, `edubox_app.dart`, `stage_router.dart`, `production_services.dart`
- Create: `edubox_flutter/lib/src/shell/edu_mark.dart`, `block_states.dart`, `offline_strip.dart`, `auth_panel.dart`
- Create: `edubox_flutter/lib/src/screens/app_start/app_start_screens.dart`
- Modify: `edubox_flutter/lib/main.dart` (replace the scaffold)
- Test: `edubox_flutter/test/support/app_harness.dart`, `test/app/session_routing_test.dart`, `test/app/formatters_test.dart`, `test/widget/app_start/app_start_screens_test.dart`, goldens `test/widget/goldens/app_start_failed_phone.png`, `app_start_failed_tablet.png`

**Interfaces:**
- Consumes: Tasks 1, 3, 4; the frozen `FakeBackend` for tests.
- Produces:
  - `class AppServices({required EduBoxBackend backend, required NetworkController network, DateTime Function()? clock})`.
  - `class AppScope extends InheritedWidget` with `services`, `session`, `connectivity`; `AppScope.of(context)`.
  - `enum AppStage {opening, startFailed, signedOut, notSetUp, home}`; `class SessionController extends ChangeNotifier` with `stage`, `session`, `sessionRefreshedAt`, `start()`, `accept(AuthSession, {DateTime? refreshedAt})`, `expire()`, `Future<BackendError?> signOut()`.
  - `enum StripState {hidden, offline, reconnecting}`; `class ConnectivityState extends ChangeNotifier` with `strip`, `isOnline`, `register(Future<void> Function())`, `unregister(...)`.
  - `class Loadable<T> extends ChangeNotifier` with `value`, `cachedAt`, `isStale`, `error`, `isLoading`, `hasValue`, `load()`.
  - `EduFormat.weekdayDate`, `.time`, `.lastGood`, `.figure`, `.joinValues`, `.givenName`, `.initials`; `compareVietnamese(a, b)`.
  - `class EduBoxApp({required AppServices services})`; `class StageRouter({required SessionController session})`.
  - `createProductionServices(BackendConfig, {NetworkController? network, File? databaseFile})`, `defaultDatabaseFile()`.
  - Shell widgets: `EduMarkGlyph`, `EduLockup`, `SkeletonBar`, `enum BlockTone {error, offline, plain}`, `BlockMessage`, `BusyLabel`, `RetryButton` (key `block.retry`), `EduPanel`, `MetaDot`, `OfflineStrip({required StripState state, bool staleWording})` (key `shell.offlineStrip`), `AuthPanelScaffold`.
  - Screens: `AppOpeningScreen` (key `screen.appOpening`), `AppStartFailedScreen({required Future<void> Function() onRetry})` (key `screen.appStartFailed`).
  - Test harness: `vi`, `TestSizes.phone|tabletPortrait|smallLandscape|tablet`, `fixedClock()` (Thursday 29/10/2026 09:14), `pumpEduApp(...)`, `TestApp`, `setWindow`, `expectAccessibilityGuidelines`, `expectScreenGolden(tester, name)`, `newFake`, `ManualNetworkControllerHolder.create()`, `FakeBackendWithHold.create()`, `rootKey`.

Behaviour:
- The root restores the stored session once; `opening` shows the mark and `appOpening` (never a bare spinner); a restore failure other than `SessionExpiredError` is `startFailed`, the panel-only `backendUnreachable` + `backendUnreachableHint` + `retry` variant from the sign-in brief.
- Each stage replaces the whole screen (no back stack); a stage change first pops any dialog or menu route.
- Screens never refresh from a timer: they `register` their reload with `ConnectivityState`, which runs every reload on `offline|reconnecting -> online` and shows `networkReconnecting` until they finish, then collapses.
- Stages whose screens arrive later render `AppOpeningScreen` as a placeholder in `StageRouter`; Tasks 6-11 replace the file.

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/support/app_harness.dart`:

```dart
import 'package:edubox_flutter/l10n/generated/app_localizations.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Vietnamese strings, looked up by key (never literal text).
final AppLocalizations vi = lookupAppLocalizations(const Locale('vi'));

/// Test window sizes in logical pixels.
abstract final class TestSizes {
  /// Compact: a phone (Pixel 7-class) in portrait.
  static const phone = Size(411, 891);

  /// Medium: a 10-11" tablet in portrait.
  static const tabletPortrait = Size(800, 1280);

  /// Expanded: an 8" tablet in landscape.
  static const smallLandscape = Size(960, 600);

  /// Large: the edubox_tablet AVD in landscape.
  static const tablet = Size(1280, 800);
}

/// Thursday 29/10/2026 09:14 local: the fixed clock for every widget test.
DateTime fixedClock() => DateTime(2026, 10, 29, 9, 14);

/// A fake whose refresh times follow [fixedClock], so "last updated"
/// times are stable ("09:14").
FakeBackend newFake(ManualNetworkController network) =>
    FakeBackend(network: network, clock: () => fixedClock().toUtc());

/// The root boundary that goldens capture.
const rootKey = Key('test.root');

/// A pumped app over the fake backend.
class TestApp {
  TestApp(this.fake, this.network);

  final FakeBackend fake;
  final ManualNetworkController network;
}

/// Sets the window to [size] at device pixel ratio 1 and [textScale].
void setWindow(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Pumps the whole app. With [signedInAs] the fake already holds that
/// session, so the app restores straight into its stage.
Future<TestApp> pumpEduApp(
  WidgetTester tester, {
  Size size = TestSizes.tablet,
  double textScale = 1,
  String? signedInAs,
  FakeBackend? fake,
  ManualNetworkController? network,
  bool settle = true,
}) async {
  setWindow(tester, size, textScale: textScale);
  final seam = network ?? ManualNetworkController();
  final backend = fake ?? newFake(seam);
  if (signedInAs != null) backend.signInAs(signedInAs);
  await tester.pumpWidget(
    RepaintBoundary(
      key: rootKey,
      child: EduBoxApp(
        // A new key per pump: pumping again re-creates the app root.
        key: UniqueKey(),
        services: AppServices(
          backend: backend,
          network: seam,
          clock: fixedClock,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return TestApp(backend, seam);
}

/// The three Flutter accessibility guidelines of exit criterion 17.
Future<void> expectAccessibilityGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

/// Captures the whole window as `test/widget/goldens/<name>.png`.
Future<void> expectScreenGolden(WidgetTester tester, String name) =>
    expectLater(find.byKey(rootKey), matchesGoldenFile('../goldens/$name.png'));

/// A fake and its seam, built before pumping so a test can set failure
/// switches (or hold calls) for the first load.
class ManualNetworkControllerHolder {
  ManualNetworkControllerHolder._(this.fake, this.network);

  factory ManualNetworkControllerHolder.create() {
    final network = ManualNetworkController();
    return ManualNetworkControllerHolder._(newFake(network), network);
  }

  final FakeBackend fake;
  final ManualNetworkController network;
}

/// Like [ManualNetworkControllerHolder], with every call held pending.
abstract final class FakeBackendWithHold {
  static ManualNetworkControllerHolder create() {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.holdCalls();
    return holder;
  }
}
```

`edubox_flutter/test/app/session_routing_test.dart`:

```dart
import 'dart:async';

import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/connectivity_state.dart';
import 'package:edubox_flutter/src/app/loadable.dart';
import 'package:edubox_flutter/src/app/session_controller.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/fake/fake_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

AppStage stageOf(WidgetTester tester) => AppScope.of(
  tester.element(find.byType(Scaffold).first),
).session.stage;

void main() {
  group('SessionController', () {
    late ManualNetworkController network;
    late FakeBackend fake;
    late SessionController session;

    setUp(() {
      network = ManualNetworkController();
      fake = FakeBackend(network: network);
      session = SessionController(fake);
    });

    test('starts in opening, then signedOut with nothing stored', () async {
      expect(session.stage, AppStage.opening);
      await session.start();
      expect(session.stage, AppStage.signedOut);
      expect(session.session, isNull);
    });

    test('a stored role session restores to home', () async {
      fake.signInAs(FixtureKeys.teacherLan);
      await session.start();
      expect(session.stage, AppStage.home);
      expect(session.session!.role!.name, 'teacher');
      expect(session.sessionRefreshedAt, isNotNull);
    });

    test('a stored not-set-up session restores to notSetUp', () async {
      fake.signInAs(FixtureKeys.noProfile);
      await session.start();
      expect(session.stage, AppStage.notSetUp);
    });

    test('an unreachable restore is startFailed; retry recovers', () async {
      fake.signInAs(FixtureKeys.studentAn);
      fake.restoreError = const BackendUnreachableError();
      await session.start();
      expect(session.stage, AppStage.startFailed);
      fake.clearFailures();
      await session.start();
      expect(session.stage, AppStage.home);
    });

    test('offline restore uses the cached session', () async {
      fake.signInAs(FixtureKeys.parentBinh);
      network.goOffline();
      await session.start();
      expect(session.stage, AppStage.home);
    });

    test('signOut goes to signedOut; a failure keeps the stage', () async {
      fake.signInAs(FixtureKeys.studentAn);
      await session.start();
      fake.signOutError = const UnexpectedBackendError();
      expect(await session.signOut(), isA<UnexpectedBackendError>());
      expect(session.stage, AppStage.home);
      fake.clearFailures();
      expect(await session.signOut(), isNull);
      expect(session.stage, AppStage.signedOut);
    });

    test('expire clears the session and goes to signedOut', () async {
      fake.signInAs(FixtureKeys.studentAn);
      await session.start();
      await session.expire();
      expect(session.stage, AppStage.signedOut);
      expect(fake.currentSession, isNull);
    });
  });

  group('ConnectivityState', () {
    test(
      'strip follows the seam and shows reconnecting while reloads run',
      () async {
        final network = ManualNetworkController();
        final state = ConnectivityState(network);
        expect(state.strip, StripState.hidden);
        network.goOffline();
        expect(state.strip, StripState.offline);
        network.goReconnecting();
        expect(state.strip, StripState.reconnecting);
        final gate = Completer<void>();
        var reloads = 0;
        Future<void> reload() async {
          reloads++;
          await gate.future;
        }

        state.register(reload);
        network.goOnline();
        expect(reloads, 1);
        expect(state.strip, StripState.reconnecting);
        gate.complete();
        await pumpEventQueue();
        expect(state.strip, StripState.hidden);
        state.unregister(reload);
        network.goOffline();
        network.goOnline();
        expect(reloads, 1);
        state.dispose();
      },
    );
  });

  group('Loadable', () {
    test('keeps the last good value when a reload fails', () async {
      var fail = false;
      final loadable = Loadable<int>(
        () async => fail
            ? const BackendFailure<int>(UnexpectedBackendError())
            : BackendOk(42, cachedAt: DateTime.utc(2026, 10, 29)),
      );
      expect(loadable.hasValue, isFalse);
      await loadable.load();
      expect(loadable.value, 42);
      expect(loadable.cachedAt, DateTime.utc(2026, 10, 29));
      fail = true;
      await loadable.load();
      expect(loadable.value, 42);
      expect(loadable.error, isA<UnexpectedBackendError>());
      fail = false;
      await loadable.load();
      expect(loadable.error, isNull);
      loadable.dispose();
    });
  });

  group('app root', () {
    testWidgets('the root is MaterialApp, Vietnamese only, light only', (
      tester,
    ) async {
      await pumpEduApp(tester);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('vi'));
      expect(app.themeMode, ThemeMode.light);
      expect(app.theme!.colorScheme.primary, const Color(0xFF1F4C8F));
    });
  });
}
```

`edubox_flutter/test/app/formatters_test.dart`:

```dart
import 'package:edubox_flutter/src/app/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  test('weekday date and 24-hour time in Vietnamese', () {
    final date = DateTime(2026, 10, 29, 14, 30);
    expect(EduFormat.weekdayDate(date), 'Thứ Năm, 29/10/2026');
    expect(EduFormat.time(date), '14:30');
  });

  test('last-good time: HH:mm today, dd/MM, HH:mm otherwise', () {
    final now = DateTime(2026, 10, 29, 18);
    expect(EduFormat.lastGood(DateTime(2026, 10, 29, 9, 14), now), '09:14');
    expect(
      EduFormat.lastGood(DateTime(2026, 10, 28, 9, 14), now),
      '28/10, 09:14',
    );
  });

  test('figures use the vi grouping and print a real zero', () {
    expect(EduFormat.figure(0), '0');
    expect(EduFormat.figure(1250), '1.250');
  });

  test('given name and initials', () {
    expect(EduFormat.givenName('Nguyễn Minh An'), 'An');
    expect(EduFormat.givenName('  '), '');
    expect(EduFormat.initials('Nguyễn Minh An'), 'NA');
    expect(EduFormat.initials('Lan'), 'L');
    expect(EduFormat.initials(''), '');
  });

  test('Vietnamese compare folds diacritics and puts đ after d', () {
    final words = ['Đọc', 'Dạy', 'Ánh', 'An', 'Bé', 'dung'];
    words.sort(compareVietnamese);
    expect(words, ['An', 'Ánh', 'Bé', 'Dạy', 'dung', 'Đọc']);
  });

  test('joinValues joins data with a comma', () {
    expect(EduFormat.joinValues(['Toán', 'Tiếng Anh']), 'Toán, Tiếng Anh');
    expect(EduFormat.joinValues(const []), '');
  });
}
```

`edubox_flutter/test/widget/app_start/app_start_screens_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/session_controller.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

AppStage stageOf(WidgetTester tester) => AppScope.of(
  tester.element(find.byType(Scaffold).first),
).session.stage;

void main() {
  testWidgets('opening shows the mark and appOpening, never a spinner', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.holdCalls();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      settle: false,
    );
    await tester.pump();
    expect(find.byKey(const Key('screen.appOpening')), findsOneWidget);
    expect(find.text(vi.appOpening), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await expectAccessibilityGuidelines(tester);
    holder.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(stageOf(tester), AppStage.signedOut);
  });

  testWidgets('app-start failure: panel, hint and a retry that recovers', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.restoreError = const BackendUnreachableError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byKey(const Key('screen.appStartFailed')), findsOneWidget);
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.text(vi.backendUnreachableHint), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    holder.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(stageOf(tester), AppStage.home);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: app start failed on $name', (tester) async {
      final holder = ManualNetworkControllerHolder.create();
      holder.fake.restoreError = const BackendUnreachableError();
      await pumpEduApp(
        tester,
        size: size,
        fake: holder.fake,
        network: holder.network,
        signedInAs: FixtureKeys.studentAn,
      );
      await expectScreenGolden(tester, 'app_start_failed_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app test/widget/app_start`
Expected: FAIL with `Error when reading 'lib/src/app/formatters.dart'` (or another missing `lib/src/app/` file).

- [ ] **Step 3: Write the app core, shared blocks and app-start screens**

`edubox_flutter/lib/src/app/app_scope.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../contract/backend.dart';
import '../contract/network_controller.dart';
import 'connectivity_state.dart';
import 'session_controller.dart';

/// Everything a screen needs from outside the widget tree. Tests build one
/// over `FakeBackend` and `ManualNetworkController`; `main.dart` builds one
/// over `CachedBackend` and `ProbedNetworkController`.
class AppServices {
  AppServices({
    required this.backend,
    required this.network,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final EduBoxBackend backend;
  final NetworkController network;

  /// Local wall clock for the date line and "checked at" times.
  final DateTime Function() clock;
}

/// Provides [AppServices], the [SessionController] and the
/// [ConnectivityState] to the tree. Read with `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required this.session,
    required this.connectivity,
    required super.child,
  });

  final AppServices services;
  final SessionController session;
  final ConnectivityState connectivity;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services ||
      session != oldWidget.session ||
      connectivity != oldWidget.connectivity;
}
```

`edubox_flutter/lib/src/app/session_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../contract/backend.dart';
import '../contract/backend_result.dart';
import '../contract/session.dart';

/// Which top-level screen the app shows. Each stage replaces the previous
/// one (no back stack), so system back at any root exits the app.
enum AppStage {
  /// Restoring a stored session: the mark and `appOpening`.
  opening,

  /// App-start session or role resolution failed: the panel with
  /// `backendUnreachable` and `retry`.
  startFailed,

  /// No session: `sign-in`.
  signedOut,

  /// Signed in, but no valid role: `account-not-set-up`.
  notSetUp,

  /// Signed in with a role: the role home.
  home,
}

/// Owns the signed-in session and the top-level stage.
class SessionController extends ChangeNotifier {
  SessionController(this.backend);

  final EduBoxBackend backend;

  AppStage _stage = AppStage.opening;
  AuthSession? _session;
  DateTime? _sessionRefreshedAt;

  AppStage get stage => _stage;

  AuthSession? get session => _session;

  /// `BackendOk.cachedAt` of the last sign-in, restore or check-again: the
  /// last time the profile was refreshed from the server.
  DateTime? get sessionRefreshedAt => _sessionRefreshedAt;

  /// Restores a stored session (online or from the cache when offline).
  Future<void> start() async {
    _go(AppStage.opening);
    final result = await backend.auth.restoreSession();
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        if (value == null) {
          _session = null;
          _go(AppStage.signedOut);
        } else {
          accept(value, refreshedAt: cachedAt);
        }
      case BackendFailure(error: SessionExpiredError()):
        _session = null;
        _go(AppStage.signedOut);
      case BackendFailure():
        _go(AppStage.startFailed);
    }
  }

  /// Routes a freshly resolved session to its stage.
  void accept(AuthSession session, {DateTime? refreshedAt}) {
    _session = session;
    _sessionRefreshedAt = refreshedAt;
    _go(session.isReady ? AppStage.home : AppStage.notSetUp);
  }

  /// A call reported `SessionExpiredError`: clear locally, go to sign-in.
  Future<void> expire() async {
    await backend.auth.signOut();
    _session = null;
    _go(AppStage.signedOut);
  }

  /// Signs out. On failure the stage does not change and the error is
  /// returned for the caller to show.
  Future<BackendError?> signOut() async {
    final result = await backend.auth.signOut();
    if (result case BackendFailure(:final error)) return error;
    _session = null;
    _sessionRefreshedAt = null;
    _go(AppStage.signedOut);
    return null;
  }

  void _go(AppStage stage) {
    _stage = stage;
    notifyListeners();
  }
}
```

`edubox_flutter/lib/src/app/connectivity_state.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contract/network_controller.dart';

/// What the shell's 40dp strip shows.
enum StripState {
  /// Online and idle: no strip.
  hidden,

  /// `networkOffline` (or `networkOfflineStale` where a screen asks for it).
  offline,

  /// `networkReconnecting`: the seam is reconnecting, or it just came back
  /// online and the visible screens are re-reading.
  reconnecting,
}

/// Bridges [NetworkController] to the screens.
///
/// Screens register a reload callback; on every
/// `offline|reconnecting -> online` transition all registered reloads run
/// and the strip shows `networkReconnecting` until they finish, then
/// collapses. Screens never refresh from their own timer.
class ConnectivityState extends ChangeNotifier {
  ConnectivityState(this.network) : _last = network.status {
    network.addListener(_onNetwork);
  }

  final NetworkController network;
  final Set<Future<void> Function()> _reloads = {};
  NetworkStatus _last;
  int _running = 0;
  bool _disposed = false;

  bool get isOnline => network.status == NetworkStatus.online;

  StripState get strip {
    switch (network.status) {
      case NetworkStatus.offline:
        return StripState.offline;
      case NetworkStatus.reconnecting:
        return StripState.reconnecting;
      case NetworkStatus.online:
        return _running > 0 ? StripState.reconnecting : StripState.hidden;
    }
  }

  /// Registers [reload] to run after every reconnect.
  void register(Future<void> Function() reload) => _reloads.add(reload);

  void unregister(Future<void> Function() reload) => _reloads.remove(reload);

  void _onNetwork() {
    final now = network.status;
    final cameBack = now == NetworkStatus.online && _last != now;
    _last = now;
    notifyListeners();
    if (cameBack) unawaited(_reloadAll());
  }

  Future<void> _reloadAll() async {
    _running++;
    notifyListeners();
    try {
      await Future.wait([for (final reload in _reloads.toList()) reload()]);
    } finally {
      _running--;
      // A reload may finish after the app root was disposed.
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    network.removeListener(_onNetwork);
    super.dispose();
  }
}
```

`edubox_flutter/lib/src/app/loadable.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../contract/backend_result.dart';

/// One block's data: the last good value, its freshness, and the last
/// error. A failed reload keeps the old value, so "error after data was
/// shown" keeps the rows on screen.
class Loadable<T> extends ChangeNotifier {
  Loadable(this._fetch);

  final Future<BackendResult<T>> Function() _fetch;

  T? _value;
  DateTime? _cachedAt;
  bool _isStale = false;
  BackendError? _error;
  bool _isLoading = false;
  bool _disposed = false;

  T? get value => _value;

  /// When [value] was last refreshed from the server.
  DateTime? get cachedAt => _cachedAt;

  /// True when [value] came from the local store while offline.
  bool get isStale => _isStale;

  /// The last load's error, cleared by the next success.
  BackendError? get error => _error;

  bool get isLoading => _isLoading;

  bool get hasValue => _value != null;

  /// Loads once; concurrent calls share nothing and simply both run.
  Future<void> load() async {
    _isLoading = true;
    _notify();
    final result = await _fetch();
    if (_disposed) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt, :final isStale):
        _value = value;
        _cachedAt = cachedAt;
        _isStale = isStale;
        _error = null;
      case BackendFailure(:final error):
        _error = error;
    }
    _isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

`edubox_flutter/lib/src/app/formatters.dart`:

```dart
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:intl/intl.dart';

/// Vietnamese date and time formatting (app-direction section 3.3). Every
/// visible date or time goes through here; times are local and 24-hour.
abstract final class EduFormat {
  static const _locale = 'vi';

  /// "Thứ Năm, 29/10/2026".
  static String weekdayDate(DateTime local) =>
      DateFormat('EEEE, dd/MM/yyyy', _locale).format(local);

  /// "14:30".
  static String time(DateTime local) =>
      DateFormat('HH:mm', _locale).format(local);

  /// "09:14" today, otherwise "28/10, 09:14".
  static String lastGood(DateTime cachedAt, DateTime now) {
    final local = cachedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    return day == today
        ? time(local)
        : DateFormat('dd/MM, HH:mm', _locale).format(local);
  }

  /// A whole-number figure in `vi` ("1.250"); a real zero prints "0".
  static String figure(int value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  /// Joins data values (subjects, class names) for one line of text.
  static String joinValues(Iterable<String> values) => values.join(', ');

  /// The given name: the last word of a Vietnamese full name
  /// ("Nguyễn Minh An" -> "An"). Empty when the name is blank.
  static String givenName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.last;
  }

  /// Up to two initials for the account disc ("Nguyễn Minh An" -> "NA").
  static String initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last.characters.first).toUpperCase();
  }
}

/// Vietnamese-aware ordering: compares with diacritics folded first
/// (so "Đọc" sorts with "D", after "Dạy"), then by the raw text.
int compareVietnamese(String a, String b) {
  final folded = _fold(a).compareTo(_fold(b));
  return folded != 0 ? folded : a.compareTo(b);
}

String _fold(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_base[char] ?? char);
  }
  return buffer.toString();
}

/// Lower-case Vietnamese letters mapped to their base letter. "đ" maps to
/// "d~" so it sorts right after every "d".
final Map<String, String> _base = () {
  const groups = {
    'a': 'àáảãạăằắẳẵặâầấẩẫậ',
    'e': 'èéẻẽẹêềếểễệ',
    'i': 'ìíỉĩị',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'u': 'ùúủũụưừứửữự',
    'y': 'ỳýỷỹỵ',
  };
  final map = <String, String>{'đ': 'd~'};
  for (final MapEntry(:key, :value) in groups.entries) {
    for (final char in value.characters) {
      map[char] = key;
    }
  }
  return map;
}();
```

`edubox_flutter/lib/src/app/edubox_app.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/edu_theme.dart';
import 'app_scope.dart';
import 'connectivity_state.dart';
import 'session_controller.dart';
import 'stage_router.dart';

/// The app root. Re-creating it (a new [EduBoxApp] over a reopened drift
/// store) is the E2E harness's in-process restart.
class EduBoxApp extends StatefulWidget {
  const EduBoxApp({super.key, required this.services});

  final AppServices services;

  @override
  State<EduBoxApp> createState() => _EduBoxAppState();
}

class _EduBoxAppState extends State<EduBoxApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SessionController _session;
  late final ConnectivityState _connectivity;
  AppStage? _shownStage;

  @override
  void initState() {
    super.initState();
    _session = SessionController(widget.services.backend)
      ..addListener(_onSession);
    _connectivity = ConnectivityState(widget.services.network);
    unawaited(_session.start());
  }

  void _onSession() {
    // A stage change replaces the whole screen: close any dialog or menu
    // route first so nothing from the old stage stays on top.
    if (_session.stage != _shownStage) {
      _shownStage = _session.stage;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _session.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      session: _session,
      connectivity: _connectivity,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: buildEduTheme(),
        themeMode: ThemeMode.light,
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => StageRouter(session: _session),
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/production_services.dart`:

```dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../contract/backend_config.dart';
import '../contract/network_controller.dart';
import '../data/cached_backend.dart';
import '../data/client_edubox_api.dart';
import '../local/local_store.dart';
import '../network/platform_sources.dart';
import '../network/probed_network_controller.dart';
import 'app_scope.dart';

/// The drift store file inside the app's support directory.
Future<File> defaultDatabaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'edubox.sqlite'));
}

/// Production wiring: the generated client, the on-disk drift store and the
/// probed network seam. The E2E harness passes its own [network] (a
/// `ManualNetworkController`) and [databaseFile] so it can switch the seam
/// and re-create the app root over the same store.
Future<AppServices> createProductionServices(
  BackendConfig config, {
  NetworkController? network,
  File? databaseFile,
}) async {
  final file = databaseFile ?? await defaultDatabaseFile();
  final seam = network ?? await _startProbedNetwork(config);
  final backend = CachedBackend(
    api: ClientEduBoxApi.create(config),
    store: CachedDataStore(EduBoxDatabase.open(file)),
    network: seam,
  );
  return AppServices(backend: backend, network: seam);
}

Future<NetworkController> _startProbedNetwork(BackendConfig config) async {
  final controller = ProbedNetworkController(
    connectivity: ConnectivityPlusSource(),
    probe: HttpReachabilityProbe(config),
  );
  await controller.start();
  return controller;
}
```

`edubox_flutter/lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'src/app/edubox_app.dart';
import 'src/app/production_services.dart';
import 'src/contract/backend_config.dart';
import 'src/theme/font_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final services = await createProductionServices(
    BackendConfig.fromEnvironment(),
  );
  runApp(EduBoxApp(services: services));
}
```

`edubox_flutter/lib/src/shell/edu_mark.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// The 24dp index-card glyph: a 2dp outline card, radius 4, with a raised
/// tab on its top-left third, in the accent (app-direction section 1.2).
class EduMarkGlyph extends StatelessWidget {
  const EduMarkGlyph({super.key, this.size = EduSize.mark});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(EduPalette.of(context).accent),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit;
    final fill = Paint()..color = color;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(2 * unit, 7 * unit, 20 * unit, 14 * unit),
      Radius.circular(4 * unit),
    );
    canvas.drawRRect(card, stroke);
    final tab = RRect.fromRectAndCorners(
      Rect.fromLTWH(2 * unit, 3 * unit, 8 * unit, 5 * unit),
      topLeft: Radius.circular(2 * unit),
      topRight: Radius.circular(2 * unit),
    );
    canvas.drawRRect(tab, fill);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// The glyph plus the "EduBox" wordmark (Bitter 600, 20sp, ink), read by
/// screen readers as one image labelled `appMarkSemantics`.
class EduLockup extends StatelessWidget {
  const EduLockup({super.key, this.showWordmark = true});

  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.headlineMedium;
    return Semantics(
      container: true,
      label: l10n.appMarkSemantics,
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EduMarkGlyph(),
          if (showWordmark) ...[
            const SizedBox(width: EduSpace.s8),
            Text(l10n.appName, style: style),
          ],
        ],
      ),
    );
  }
}
```

`edubox_flutter/lib/src/shell/block_states.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// A flat skeleton bar at the real size of the value it replaces. No
/// shimmer. Excluded from semantics: the block announces one loading label.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({super.key, required this.width, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: EduPalette.of(context).active,
          borderRadius: BorderRadius.circular(EduRadius.small),
        ),
      ),
    );
  }
}

/// The tone of an in-block message.
enum BlockTone {
  /// A failed request: negative `error_outline` glyph.
  error,

  /// Offline, not a fault: muted `cloud_off_outlined` glyph.
  offline,

  /// A plain sentence with no glyph (empty states, no linked child).
  plain,
}

/// One sentence (plus optional hint and action) inside the block that it
/// describes. Never full screen. A polite live region.
class BlockMessage extends StatelessWidget {
  const BlockMessage({
    super.key,
    required this.message,
    this.tone = BlockTone.plain,
    this.hint,
    this.action,
    this.messageStyle,
  });

  final String message;
  final BlockTone tone;
  final String? hint;
  final Widget? action;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final glyph = switch (tone) {
      BlockTone.error => Icon(
        Icons.error_outline,
        size: EduSize.statusGlyph,
        color: palette.negative,
      ),
      BlockTone.offline => Icon(
        Icons.cloud_off_outlined,
        size: EduSize.statusGlyph,
        color: palette.muted,
      ),
      BlockTone.plain => null,
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (glyph != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: ExcludeSemantics(child: glyph),
            ),
            const SizedBox(width: EduSpace.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: messageStyle ?? text.bodyLarge),
                if (hint != null) ...[
                  const SizedBox(height: EduSpace.s4),
                  Text(
                    hint!,
                    style: text.bodyMedium!.copyWith(color: palette.muted),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: EduSpace.s8),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An 18dp, 2dp-stroke spinner beside a changed label, for busy buttons.
/// The only place a spinner is allowed.
class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: EduSize.statusGlyph,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? DefaultTextStyle.of(context).style.color,
          ),
        ),
        const SizedBox(width: EduSpace.s8),
        Flexible(child: Text(label)),
      ],
    );
  }
}

/// The ink "Thử lại" text button; while [busy] it reads "Đang thử lại…"
/// with the in-button spinner and is disabled.
class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      key: const Key('block.retry'),
      onPressed: busy ? null : onPressed,
      child: busy ? BusyLabel(label: l10n.retrying) : Text(l10n.retry),
    );
  }
}

/// A `sheet` panel: radius 8, 1dp `rule` edge, no shadow.
class EduPanel extends StatelessWidget {
  const EduPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: child,
      ),
    );
  }
}

/// A 3dp dot between two values on one meta line ("Sách · Toán"), so no
/// separator text is ever hardcoded.
class MetaDot extends StatelessWidget {
  const MetaDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EduSpace.s8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: EduPalette.of(context).muted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/shell/offline_strip.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/connectivity_state.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// The app-wide 40dp strip at the top of the canvas (app-direction
/// section 8). Neutral fill, never warning-grey, never a padlock; not
/// dismissible while offline; collapses when the reconnect refresh ends.
class OfflineStrip extends StatelessWidget {
  const OfflineStrip({
    super.key,
    required this.state,
    this.staleWording = false,
  });

  final StripState state;

  /// Teacher-home and student-library use `networkOfflineStale` when the
  /// shown snapshot is older than the last profile refresh.
  final bool staleWording;

  @override
  Widget build(BuildContext context) {
    if (state == StripState.hidden) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final offline = state == StripState.offline;
    final message = offline
        ? (staleWording ? l10n.networkOfflineStale : l10n.networkOffline)
        : l10n.networkReconnecting;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('shell.offlineStrip'),
        constraints: const BoxConstraints(minHeight: EduSize.offlineStrip),
        color: palette.neutralFill,
        padding: const EdgeInsets.symmetric(
          horizontal: EduSpace.s16,
          vertical: EduSpace.s8,
        ),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                offline ? Icons.cloud_off_outlined : Icons.sync,
                size: EduSize.statusGlyph,
                color: palette.muted,
              ),
            ),
            const SizedBox(width: EduSpace.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: palette.neutralInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/shell/auth_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The pre-auth layout (sign-in, account-not-set-up, app start): a 400dp
/// `sheet` panel on `paper`, centred when it fits, top-aligned and
/// scrollable when it does not (keyboard, 200% text, split screen).
class AuthPanelScaffold extends StatelessWidget {
  const AuthPanelScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(EduSpace.s16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: EduSize.authPanelWidth,
                      ),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                            narrow ? EduSpace.s16 : EduSpace.s24,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/screens/app_start/app_start_screens.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Shown once while the stored session and role resolve: the mark and
/// "Đang mở EduBox…" in `muted`. Never a bare spinner.
class AppOpeningScreen extends StatelessWidget {
  const AppOpeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('screen.appOpening'),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EduLockup(),
              const SizedBox(height: EduSpace.s16),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.appOpening,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: EduPalette.of(context).muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-start session or role resolution failed: the panel-only variant of
/// backend unreachable (mark, message, hint, "Thử lại"; no form).
class AppStartFailedScreen extends StatefulWidget {
  const AppStartFailedScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<AppStartFailedScreen> createState() => _AppStartFailedScreenState();
}

class _AppStartFailedScreenState extends State<AppStartFailedScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    return AuthPanelScaffold(
      key: const Key('screen.appStartFailed'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const EduLockup(),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: EduSize.statusGlyph,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(width: EduSpace.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.backendUnreachable,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: EduSpace.s4),
                      Text(
                        l10n.backendUnreachableHint,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EduSpace.s8),
          RetryButton(onPressed: _retry, busy: _busy),
        ],
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/app_start/app_start_screens.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const AppOpeningScreen(),
      AppStage.notSetUp => const AppOpeningScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => const AppOpeningScreen(),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test --update-goldens test/app test/widget/app_start` then `flutter test test/app test/widget/app_start`
Expected: `All tests passed!` both times; two PNGs appear in `test/widget/goldens/`.

- [ ] **Step 5: Look at the goldens and fix**

Open `test/widget/goldens/app_start_failed_phone.png` and `app_start_failed_tablet.png`.

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] A single white 400dp panel centred on the grey ground; the mark (blue index card) and "EduBox" in Bitter at its top; no shadow.
- [ ] The `cloud_off` glyph is grey, not red; "Không kết nối được với EduBox" in ink, the hint under it in grey; "Thử lại" is an ink text button at least 48dp tall.
- [ ] No accent anywhere except the small mark.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/app/app_scope.dart \
  edubox_flutter/lib/src/app/session_controller.dart \
  edubox_flutter/lib/src/app/connectivity_state.dart \
  edubox_flutter/lib/src/app/loadable.dart \
  edubox_flutter/lib/src/app/formatters.dart \
  edubox_flutter/lib/src/app/edubox_app.dart \
  edubox_flutter/lib/src/app/production_services.dart \
  edubox_flutter/lib/main.dart \
  edubox_flutter/lib/src/shell/edu_mark.dart \
  edubox_flutter/lib/src/shell/block_states.dart \
  edubox_flutter/lib/src/shell/offline_strip.dart \
  edubox_flutter/lib/src/shell/auth_panel.dart \
  edubox_flutter/lib/src/screens/app_start/app_start_screens.dart \
  edubox_flutter/test/support/app_harness.dart \
  edubox_flutter/test/app/session_routing_test.dart \
  edubox_flutter/test/app/formatters_test.dart \
  edubox_flutter/test/widget/app_start/app_start_screens_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/app_start_failed_phone.png \
  edubox_flutter/test/widget/goldens/app_start_failed_tablet.png
git commit -m "feat: app root with session restore, stage routing and offline strip"
```


---

## Task 6: Screen `sign-in`

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (four sign-in PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (route `signedOut` to `SignInScreen`)
- Test: `edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart`

**Interfaces:**
- Consumes: `AppScope` (`services.backend.auth.signIn`, `auth.refreshProfile`, `session.accept`), `AuthPanelScaffold`, `EduLockup`, `BusyLabel`, theme tokens.
- Produces: `class SignInScreen` with `SignInScreen.submitTimeout` (15 s); keys `SignInKeys.screen` (`screen.signIn`), `email` (`signIn.email`), `password` (`signIn.password`), `togglePassword`, `submit`, `status`, `retry` (`signIn.retry`).

Brief: `docs/design/shapes/sign-in.md` (confirmed 2026-10-29); Firebase wording maps to the contract: `invalid-credential` -> `WrongCredentialsError`, `too-many-requests` -> `TooManyAttemptsError`, `user-disabled` -> `AccountDisabledError`, network or timeout -> `BackendUnreachableError`, the "claim read" -> `profile.me` inside `signIn`.
Layout: no shell; a 400dp `sheet` panel centred on `paper` (16dp gutters on compact, top-aligned and scrolling when it does not fit); student density for everyone (56dp fields and button).
Order inside the panel: lockup; h1 `signInTitle` (Bitter 24/32); label `emailLabel` above the email field; label `passwordLabel` above the password field with the 48dp visibility toggle (tooltip `showPassword` / `hidePassword`); the status slot; the full-width 56dp accent button `signInButton`; the static `signInHelp` line in muted 14/20.
Labels above fields are excluded from semantics; each field carries its label through `Semantics(label: ...)`.
Validation runs on the first submit, then live per field: `emailRequired` (empty), `emailInvalid` (no text on both sides of an `@`), `passwordRequired`; the first invalid field takes focus; nothing is sent while invalid.
The button is never disabled for empty input; while submitting it keeps the accent fill, reads `signInSubmitting` with the in-button spinner, the fields are read-only, and a double press is ignored.
Wrong credentials: both fields get the 2dp error border with no per-field text, the email is kept, the password is cleared and focused.
Unreachable: `cloud_off` glyph, `backendUnreachable` in ink, `backendUnreachableHint` in muted, a `retry` text button; retry re-runs only the role read when sign-in already succeeded (`refreshProfile`), otherwise the sign-in.
No SnackBar, no forgot-password link, no sign-up, no role picker.

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Idle | Empty fields, empty status slot, enabled accent button | `signInTitle`, `emailLabel`, `passwordLabel`, `signInButton`, `signInHelp` | `idle: heading, labelled fields, button and help line` |
| Validating | Field errors under the fields | `emailRequired`, `emailInvalid`, `passwordRequired` | `validating: empty submit shows field errors and sends nothing` |
| Submitting (loading) | Busy accent button | `signInSubmitting` | `submitting: busy label, then the role home replaces sign-in` |
| Wrong credentials (error) | Negative sentence, both borders red, password cleared | `signInWrongCredentials` | `wrong credentials: sentence, password cleared, email kept` |
| Backend unreachable (offline) | Neutral glyph, sentence, hint, retry | `backendUnreachable`, `backendUnreachableHint`, `retry` | `backend unreachable: message, hint and retry that recovers` |
| Too many attempts / disabled | Negative sentence, no retry | `signInTooManyAttempts`, `signInAccountDisabled` | `too many attempts and account disabled: sentence, no retry` |
| Unexpected failure | Negative sentence and retry | `signInUnknownError`, `retry` | `unexpected failure: unknown-error sentence with retry` |
| Text at 200% on a phone | Reflows and scrolls, no overflow | - | `200% text scale on a phone reflows without overflow` |

Empty and offline-with-cache do not apply to sign-in (no data); offline is the unreachable state.

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String email = 'hs.an@edubox.test',
  String password = devPassword,
}) async {
  await tester.enterText(find.byKey(SignInKeys.email), email);
  await tester.enterText(find.byKey(SignInKeys.password), password);
  await tester.tap(find.byKey(SignInKeys.submit));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('idle: heading, labelled fields, button and help line', (
    tester,
  ) async {
    await pumpEduApp(tester);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
    expect(find.text(vi.signInTitle), findsWidgets);
    expect(find.bySemanticsLabel(vi.emailLabel), findsOneWidget);
    expect(find.bySemanticsLabel(vi.passwordLabel), findsOneWidget);
    expect(find.text(vi.signInHelp), findsOneWidget);
    expect(find.byKey(SignInKeys.status), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('validating: empty submit shows field errors and sends nothing', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text(vi.emailRequired), findsOneWidget);
    expect(find.text(vi.passwordRequired), findsOneWidget);
    expect(app.fake.currentSession, isNull);
    await tester.enterText(find.byKey(SignInKeys.email), 'khong-co-a-cong');
    await tester.pump();
    expect(find.text(vi.emailInvalid), findsOneWidget);
  });

  testWidgets('submitting: busy label, then the role home replaces sign-in', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.holdCalls();
    await tester.enterText(find.byKey(SignInKeys.email), 'hs.an@edubox.test');
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pump();
    expect(find.text(vi.signInSubmitting), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsNothing);
  });

  testWidgets('wrong credentials: sentence, password cleared, email kept', (
    tester,
  ) async {
    await pumpEduApp(tester);
    await fillAndSubmit(tester, password: 'sai-mat-khau');
    expect(find.text(vi.signInWrongCredentials), findsOneWidget);
    final password = tester.widget<TextField>(find.byKey(SignInKeys.password));
    expect(password.controller!.text, isEmpty);
    final email = tester.widget<TextField>(find.byKey(SignInKeys.email));
    expect(email.controller!.text, 'hs.an@edubox.test');
    await expectAccessibilityGuidelines(tester);
    await tester.enterText(find.byKey(SignInKeys.password), 'x');
    await tester.pump();
    expect(find.text(vi.signInWrongCredentials), findsNothing);
  });

  testWidgets('backend unreachable: message, hint and retry that recovers', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.text(vi.backendUnreachableHint), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.byKey(SignInKeys.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsNothing);
  });

  testWidgets('too many attempts and account disabled: sentence, no retry', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const TooManyAttemptsError();
    await fillAndSubmit(tester);
    expect(find.text(vi.signInTooManyAttempts), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsNothing);
    app.fake.signInError = const AccountDisabledError();
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text(vi.signInAccountDisabled), findsOneWidget);
  });

  testWidgets('unexpected failure: unknown-error sentence with retry', (
    tester,
  ) async {
    final app = await pumpEduApp(tester);
    app.fake.signInError = const UnexpectedBackendError();
    await fillAndSubmit(tester);
    expect(find.text(vi.signInUnknownError), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
  });

  testWidgets('password visibility toggle swaps its tooltip', (tester) async {
    await pumpEduApp(tester);
    expect(find.byTooltip(vi.showPassword), findsOneWidget);
    await tester.tap(find.byKey(SignInKeys.togglePassword));
    await tester.pump();
    expect(find.byTooltip(vi.hidePassword), findsOneWidget);
  });

  testWidgets('200% text scale on a phone reflows without overflow', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
    );
    app.fake.signInError = const BackendUnreachableError();
    await fillAndSubmit(tester);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(vi.signInHelp),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(vi.signInHelp), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: sign-in idle and error on $name', (tester) async {
      final app = await pumpEduApp(tester, size: size);
      await expectScreenGolden(tester, 'sign_in_idle_$name');
      app.fake.signInError = const BackendUnreachableError();
      await fillAndSubmit(tester);
      await expectScreenGolden(tester, 'sign_in_unreachable_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/sign_in/sign_in_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/screens/sign_in/sign_in_screen.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../contract/backend_result.dart';
import '../../contract/session.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests (sign-in brief section 7).
abstract final class SignInKeys {
  static const screen = Key('screen.signIn');
  static const email = Key('signIn.email');
  static const password = Key('signIn.password');
  static const togglePassword = Key('signIn.togglePassword');
  static const submit = Key('signIn.submit');
  static const status = Key('signIn.status');
  static const retry = Key('signIn.retry');
}

/// What the status slot between the password field and the button shows.
enum _Status { none, wrongCredentials, unreachable, tooMany, disabled, unknown }

/// `sign-in` (docs/design/shapes/sign-in.md).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  /// The brief's submit timeout; it falls through to backend unreachable.
  static const submitTimeout = Duration(seconds: 15);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _submitting = false;
  bool _obscure = true;
  bool _validated = false;
  _Status _status = _Status.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _email.addListener(_onEdit);
    _password.addListener(_onEdit);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Password visibility resets when the app goes to the background.
    if (state != AppLifecycleState.resumed && !_obscure) {
      setState(() => _obscure = true);
    }
  }

  void _onEdit() {
    // Wrong-credentials clears on the next edit; field errors re-validate
    // live once they have been shown.
    if (_status == _Status.wrongCredentials || _validated) {
      setState(() {
        if (_status == _Status.wrongCredentials) _status = _Status.none;
      });
    }
  }

  String? _emailError(AppLocalizations l10n) {
    if (!_validated) return null;
    final value = _email.text.trim();
    if (value.isEmpty) return l10n.emailRequired;
    final at = value.indexOf('@');
    if (at <= 0 || at == value.length - 1) return l10n.emailInvalid;
    return null;
  }

  String? _passwordError(AppLocalizations l10n) {
    if (!_validated) return null;
    return _password.text.isEmpty ? l10n.passwordRequired : null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _validated = true;
      _status = _Status.none;
    });
    final emailError = _emailError(l10n);
    final passwordError = _passwordError(l10n);
    if (emailError != null || passwordError != null) {
      (emailError != null ? _emailFocus : _passwordFocus).requestFocus();
      _announce(emailError ?? passwordError!);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    _announce(l10n.signInSubmitting);
    final scope = AppScope.of(context);
    final result = await _withTimeout(
      scope.services.backend.auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
    if (!mounted) return;
    _handle(result);
  }

  /// Retry after "unreachable": if sign-in already succeeded and only the
  /// role read failed, re-run the role read without re-authenticating.
  Future<void> _retry() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _status = _Status.none;
    });
    final auth = AppScope.of(context).services.backend.auth;
    var result = await _withTimeout(auth.refreshProfile());
    if (result case BackendFailure(error: SessionExpiredError())) {
      result = await _withTimeout(
        auth.signIn(email: _email.text.trim(), password: _password.text),
      );
    }
    if (!mounted) return;
    _handle(result);
  }

  Future<BackendResult<AuthSession>> _withTimeout(
    Future<BackendResult<AuthSession>> call,
  ) => call.timeout(
    SignInScreen.submitTimeout,
    onTimeout: () => const BackendFailure(BackendUnreachableError()),
  );

  void _handle(BackendResult<AuthSession> result) {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        TextInput.finishAutofillContext();
        AppScope.of(context).session.accept(value, refreshedAt: cachedAt);
        return;
      case BackendFailure(:final error):
        final status = switch (error) {
          WrongCredentialsError() => _Status.wrongCredentials,
          BackendUnreachableError() => _Status.unreachable,
          TooManyAttemptsError() => _Status.tooMany,
          AccountDisabledError() => _Status.disabled,
          _ => _Status.unknown,
        };
        // Clear first: the edit listener must not wipe the new status.
        if (status == _Status.wrongCredentials) _password.clear();
        setState(() {
          _submitting = false;
          _status = status;
        });
        if (status == _Status.wrongCredentials) _passwordFocus.requestFocus();
        _announce(_statusText(l10n, status));
    }
  }

  String _statusText(AppLocalizations l10n, _Status status) => switch (status) {
    _Status.none => '',
    _Status.wrongCredentials => l10n.signInWrongCredentials,
    _Status.unreachable => l10n.backendUnreachable,
    _Status.tooMany => l10n.signInTooManyAttempts,
    _Status.disabled => l10n.signInAccountDisabled,
    _Status.unknown => l10n.signInUnknownError,
  };

  void _announce(String message) {
    if (message.isEmpty) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final wrong = _status == _Status.wrongCredentials;
    return AuthPanelScaffold(
      key: SignInKeys.screen,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: EduLockup(),
            ),
            const SizedBox(height: EduSpace.s24),
            Semantics(
              header: true,
              child: Text(l10n.signInTitle, style: text.headlineLarge),
            ),
            const SizedBox(height: EduSpace.s24),
            _FieldLabel(l10n.emailLabel),
            const SizedBox(height: EduSpace.s8),
            Semantics(
              label: l10n.emailLabel,
              child: TextField(
                key: SignInKeys.email,
                controller: _email,
                focusNode: _emailFocus,
                readOnly: _submitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                style: text.bodyLarge,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: InputDecoration(
                  constraints: const BoxConstraints(
                    minHeight: EduSize.primaryButton,
                  ),
                  errorText: wrong ? null : _emailError(l10n),
                  error: wrong ? const SizedBox.shrink() : null,
                ),
              ),
            ),
            const SizedBox(height: EduSpace.s16),
            _FieldLabel(l10n.passwordLabel),
            const SizedBox(height: EduSpace.s8),
            Semantics(
              label: l10n.passwordLabel,
              child: TextField(
                key: SignInKeys.password,
                controller: _password,
                focusNode: _passwordFocus,
                readOnly: _submitting,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                style: text.bodyLarge,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  constraints: const BoxConstraints(
                    minHeight: EduSize.primaryButton,
                  ),
                  errorText: wrong ? null : _passwordError(l10n),
                  error: wrong ? const SizedBox.shrink() : null,
                  suffixIcon: IconButton(
                    key: SignInKeys.togglePassword,
                    tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                    isSelected: !_obscure,
                    icon: const Icon(Icons.visibility_outlined),
                    selectedIcon: const Icon(Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            _StatusSlot(
              status: _status,
              message: _statusText(l10n, _status),
              onRetry: _retry,
            ),
            const SizedBox(height: EduSpace.s24),
            SizedBox(
              height: EduSize.primaryButton,
              child: FilledButton(
                key: SignInKeys.submit,
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  // Busy keeps the accent fill; the changed word is the why.
                  disabledBackgroundColor: EduPalette.of(context).accent,
                  disabledForegroundColor: EduPalette.of(context).sheet,
                ),
                child: _submitting
                    ? BusyLabel(
                        label: l10n.signInSubmitting,
                        color: EduPalette.of(context).sheet,
                      )
                    : Text(l10n.signInButton),
              ),
            ),
            const SizedBox(height: EduSpace.s16),
            Text(
              l10n.signInHelp,
              style: text.bodyMedium!.copyWith(
                color: EduPalette.of(context).muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label above its field; excluded from semantics because the field
/// carries the same label (one name, not two).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusSlot extends StatelessWidget {
  const _StatusSlot({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final _Status status;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == _Status.none) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final unreachable = status == _Status.unreachable;
    final retryable = unreachable || status == _Status.unknown;
    return Padding(
      key: SignInKeys.status,
      padding: const EdgeInsets.only(top: EduSpace.s16),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: ExcludeSemantics(
                    child: Icon(
                      unreachable
                          ? Icons.cloud_off_outlined
                          : Icons.error_outline,
                      size: EduSize.statusGlyph,
                      color: unreachable ? palette.muted : palette.negative,
                    ),
                  ),
                ),
                const SizedBox(width: EduSpace.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: text.bodyLarge!.copyWith(
                          color: unreachable ? palette.ink : palette.negative,
                        ),
                      ),
                      if (unreachable)
                        Text(
                          l10n.backendUnreachableHint,
                          style: text.bodyMedium!.copyWith(
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (retryable)
              Padding(
                padding: const EdgeInsets.only(top: EduSpace.s8),
                child: TextButton(
                  key: SignInKeys.retry,
                  onPressed: onRetry,
                  child: Text(l10n.retry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AppOpeningScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => const AppOpeningScreen(),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/widget/sign_in/sign_in_screen_test.dart`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/sign_in_idle_phone.png`
- `test/widget/goldens/sign_in_idle_tablet.png`
- `test/widget/goldens/sign_in_unreachable_phone.png`
- `test/widget/goldens/sign_in_unreachable_tablet.png`

Run: `flutter test test/widget/sign_in/sign_in_screen_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] The "Đăng nhập" button is the only accent fill on the screen; the 24dp mark is the only other blue.
- [ ] Labels sit above the fields (no floating label, no placeholder); fields are 56dp tall with a grey `#7D8594` border and 6dp corners.
- [ ] In the unreachable PNGs the status block sits between the password field and the button, the glyph is grey `cloud_off`, and "Thử lại" lines up under the sentence area.
- [ ] The help line is grey and wraps cleanly; the panel is centred on the tablet and has 16dp side gutters on the phone.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/screens/sign_in/sign_in_screen.dart \
  edubox_flutter/test/widget/sign_in/sign_in_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/sign_in_idle_phone.png \
  edubox_flutter/test/widget/goldens/sign_in_idle_tablet.png \
  edubox_flutter/test/widget/goldens/sign_in_unreachable_phone.png \
  edubox_flutter/test/widget/goldens/sign_in_unreachable_tablet.png
git commit -m "feat: sign-in screen with every brief state"
```


---

## Task 7: Screen `account-not-set-up`

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (two PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/screens/account_not_set_up/account_not_set_up_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (route `notSetUp` to `AccountNotSetUpScreen`)
- Test: `edubox_flutter/test/widget/account_not_set_up/account_not_set_up_screen_test.dart`

**Interfaces:**
- Consumes: `AppScope` (`session.session.signedInEmail`, `services.backend.auth.refreshProfile`, `session.accept`, `session.expire`, `session.signOut`, `services.clock`), `AuthPanelScaffold`, `BlockMessage`, `BusyLabel`, `EduFormat.time`.
- Produces: `class AccountNotSetUpScreen`; keys `AccountNotSetUpKeys.screen` (`screen.accountNotSetUp`), `checkAgain`, `signOut`, `status`.

Brief: `docs/design/shapes/account-not-set-up.md` (confirmed 2026-10-29); "role claim" means the server role from `profile.me`, "forced token refresh" means `AuthRepository.refreshProfile()` (no re-auth).
Layout: the same 400dp pre-auth panel as sign-in.
Order: lockup; h1 `accountNotSetUp` (Bitter 24/32); `accountNotSetUpBody`; `accountNotSetUpContact`; the signed-in row (`accountSignedInAs` in muted 12/18, then the email in IBM Plex Mono 14/20), merged into one semantics node `accountSignedInAsSemantics(email)`; a status line that reserves 24dp; then the 56dp outlined `accountCheckAgain` and the 56dp accent `signOut` (the screen's one accent), stacked full width, 12dp apart.
Check again: the status line clears first; the button reads `accountChecking` with the spinner and sign-out is disabled; a ready profile routes to the role home (the button stays busy until then); still not set up shows `accountStillNotSetUp` in muted plus `accountCheckedAt(HH:mm)` in mono; an offline or unreachable check shows the negative glyph and `accountCheckFailedOffline` (no second retry button); an expired session routes to sign-in; any other failure shows `studentHomeProfileError` (role-neutral "could not load the account information").
Sign-out is immediate (no confirmation): `signOutBusy` with the spinner, then sign-in.
No auto-check on a timer or on resume, no app bar, no strip.

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Not set up (rest, populated) | Explanation, email, two buttons | `accountNotSetUp`, `accountNotSetUpBody`, `accountNotSetUpContact`, `accountSignedInAs`, `accountSignedInAsSemantics`, `accountCheckAgain`, `signOut` | `no-profile user lands here, never on a role home`; `null-role user lands here too` |
| Checking (loading) | Busy check-again, sign-out disabled | `accountChecking` | `checking: busy label, sign-out disabled` |
| Still not set up (empty result) | Muted sentence and the time | `accountStillNotSetUp`, `accountCheckedAt` | `still not set up: muted sentence and the checked-at time` |
| Network error (offline) | Negative glyph and sentence | `accountCheckFailedOffline` | `offline check: the network sentence, no extra retry button` |
| Role found | Routes to the role home | - | `role fixed by the admin: check again routes to the home` |
| Session gone | Routes to sign-in | - | `expired session on check again routes to sign-in` |
| Signing out | Busy sign-out, then sign-in | `signOutBusy` | `sign-out is immediate and returns to sign-in` |
| Text at 200% on a phone | Scrolls, no overflow | - | `200% text on a phone scrolls without overflow` |

Offline-with-cache does not apply (the screen has no cached data); the offline row above is its offline state.

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/widget/account_not_set_up/account_not_set_up_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('no-profile user lands here, never on a role home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
    expect(find.text(vi.accountNotSetUp), findsOneWidget);
    expect(find.text(vi.accountNotSetUpBody), findsOneWidget);
    expect(find.text('chua.thiet.lap@edubox.test'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        vi.accountSignedInAsSemantics('chua.thiet.lap@edubox.test'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    expect(find.text(vi.accountCheckAgain), findsOneWidget);
    expect(find.text(vi.signOut), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('null-role user lands here too', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    expect(find.text(vi.accountNotSetUp), findsOneWidget);
  });

  testWidgets('checking: busy label, sign-out disabled', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.holdCalls();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pump();
    expect(find.text(vi.accountChecking), findsOneWidget);
    final signOut = tester.widget<FilledButton>(
      find.byKey(AccountNotSetUpKeys.signOut),
    );
    expect(signOut.onPressed, isNull);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
  });

  testWidgets('still not set up: muted sentence and the checked-at time', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(vi.accountStillNotSetUp), findsOneWidget);
    expect(find.text(vi.accountCheckedAt('09:14')), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline check: the network sentence, no extra retry button', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.network.goOffline();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.text(vi.accountCheckFailedOffline), findsOneWidget);
    expect(find.text(vi.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('role fixed by the admin: check again routes to the home', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.setRole(FixtureKeys.nullRole, 'student');
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.byKey(AccountNotSetUpKeys.screen), findsNothing);
  });

  testWidgets('expired session on check again routes to sign-in', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    app.fake.profileError = const SessionExpiredError();
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out is immediate and returns to sign-in', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    await tester.tap(find.byKey(AccountNotSetUpKeys.signOut));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('200% text on a phone scrolls without overflow', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.nullRole,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: account-not-set-up on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.nullRole);
      await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
      await tester.pumpAndSettle();
      await expectScreenGolden(tester, 'account_not_set_up_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/account_not_set_up/account_not_set_up_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/screens/account_not_set_up/account_not_set_up_screen.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/screens/account_not_set_up/account_not_set_up_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../contract/backend_result.dart';
import '../../shell/auth_panel.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class AccountNotSetUpKeys {
  static const screen = Key('screen.accountNotSetUp');
  static const checkAgain = Key('accountNotSetUp.checkAgain');
  static const signOut = Key('accountNotSetUp.signOut');
  static const status = Key('accountNotSetUp.status');
}

enum _Result { none, stillNotSetUp, offline, failed }

/// `account-not-set-up` (docs/design/shapes/account-not-set-up.md).
class AccountNotSetUpScreen extends StatefulWidget {
  const AccountNotSetUpScreen({super.key});

  @override
  State<AccountNotSetUpScreen> createState() => _AccountNotSetUpScreenState();
}

class _AccountNotSetUpScreenState extends State<AccountNotSetUpScreen> {
  bool _checking = false;
  bool _signingOut = false;
  _Result _result = _Result.none;
  DateTime? _checkedAt;

  Future<void> _checkAgain() async {
    final scope = AppScope.of(context);
    setState(() {
      _checking = true;
      _result = _Result.none; // Clear the previous line first.
    });
    final result = await scope.services.backend.auth.refreshProfile();
    if (!mounted) return;
    switch (result) {
      case BackendOk(:final value, :final cachedAt):
        if (value.isReady) {
          // Stay busy until the route swaps to the role home.
          scope.session.accept(value, refreshedAt: cachedAt);
          return;
        }
        setState(() {
          _checking = false;
          _result = _Result.stillNotSetUp;
          _checkedAt = scope.services.clock();
        });
      case BackendFailure(error: SessionExpiredError()):
        await scope.session.expire();
      case BackendFailure(error: BackendUnreachableError()):
        setState(() {
          _checking = false;
          _result = _Result.offline;
        });
      case BackendFailure():
        setState(() {
          _checking = false;
          _result = _Result.failed;
        });
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final error = await AppScope.of(context).session.signOut();
    if (mounted && error != null) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final email = AppScope.of(context).session.session?.signedInEmail ?? '';
    final busy = _checking || _signingOut;
    return AuthPanelScaffold(
      key: AccountNotSetUpKeys.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: EduLockup(),
          ),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            header: true,
            child: Text(l10n.accountNotSetUp, style: text.headlineLarge),
          ),
          const SizedBox(height: EduSpace.s12),
          Text(l10n.accountNotSetUpBody, style: text.bodyLarge),
          const SizedBox(height: EduSpace.s16),
          Text(l10n.accountNotSetUpContact, style: text.bodyLarge),
          const SizedBox(height: EduSpace.s24),
          Semantics(
            container: true,
            label: l10n.accountSignedInAsSemantics(email),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountSignedInAs, style: text.bodySmall),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EduTypeExtras.of(context).monoBody,
                ),
              ],
            ),
          ),
          const SizedBox(height: EduSpace.s24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: EduSpace.s24),
            child: _StatusLine(result: _result, checkedAt: _checkedAt),
          ),
          const SizedBox(height: EduSpace.s16),
          SizedBox(
            height: EduSize.primaryButton,
            child: OutlinedButton(
              key: AccountNotSetUpKeys.checkAgain,
              onPressed: busy ? null : _checkAgain,
              child: _checking
                  ? BusyLabel(label: l10n.accountChecking, color: palette.ink)
                  : Text(l10n.accountCheckAgain),
            ),
          ),
          const SizedBox(height: EduSpace.s12),
          SizedBox(
            height: EduSize.primaryButton,
            child: FilledButton(
              key: AccountNotSetUpKeys.signOut,
              onPressed: busy ? null : _signOut,
              child: _signingOut
                  ? BusyLabel(label: l10n.signOutBusy)
                  : Text(l10n.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.result, required this.checkedAt});

  final _Result result;
  final DateTime? checkedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final Widget child = switch (result) {
      _Result.none => const SizedBox.shrink(),
      _Result.stillNotSetUp => Wrap(
        spacing: EduSpace.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.accountStillNotSetUp,
            style: text.bodyLarge!.copyWith(color: palette.muted),
          ),
          Text(
            l10n.accountCheckedAt(EduFormat.time(checkedAt!)),
            style: EduTypeExtras.of(context).timestamp,
          ),
        ],
      ),
      _Result.offline => BlockMessage(
        tone: BlockTone.error,
        message: l10n.accountCheckFailedOffline,
      ),
      _Result.failed => BlockMessage(
        tone: BlockTone.error,
        message: l10n.studentHomeProfileError,
      ),
    };
    return Semantics(
      key: AccountNotSetUpKeys.status,
      liveRegion: true,
      container: true,
      child: child,
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => const AppOpeningScreen(),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/widget/account_not_set_up/account_not_set_up_screen_test.dart`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/account_not_set_up_phone.png`
- `test/widget/goldens/account_not_set_up_tablet.png`

Run: `flutter test test/widget/account_not_set_up/account_not_set_up_screen_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] "Đăng xuất" is the only accent fill; "Kiểm tra lại" is a white button with a grey border above it.
- [ ] The email is in the monospace face and wraps or ellipsizes after two lines; the "checked at" time is monospace and grey.
- [ ] The status line has no red unless the check failed; "Vẫn chưa được thiết lập." is grey.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/screens/account_not_set_up/account_not_set_up_screen.dart \
  edubox_flutter/test/widget/account_not_set_up/account_not_set_up_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/account_not_set_up_phone.png \
  edubox_flutter/test/widget/goldens/account_not_set_up_tablet.png
git commit -m "feat: account-not-set-up screen with check again"
```


---

## Task 8: Student shell and screen `student-home`

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (student-home PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/features/library/catalogue.dart`, `content_row.dart`
- Create: `edubox_flutter/lib/src/shell/role_shell.dart`, `account_menu.dart`, `sign_out_dialog.dart`, `student_shell.dart`
- Create: `edubox_flutter/lib/src/screens/student_home/student_home_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (route the student role to `StudentShell`)
- Test: `edubox_flutter/test/features/catalogue_test.dart`, `edubox_flutter/test/widget/student_home/student_home_screen_test.dart`

**Interfaces:**
- Consumes: Task 5 (`AppScope`, `Loadable`, `ConnectivityState`, `OfflineStrip`, `BlockMessage`, `RetryButton`, `SkeletonBar`, `MetaDot`, `EduFormat`), `LibraryRepository.library()`.
- Produces:
  - `SubjectGroup({{String? subject, List<LibraryItem> items}})`, `buildCatalogue(StudentLibrary)`, `newestItems(StudentLibrary, {{int count = 4}})`.
  - `contentTypeLabel(AppLocalizations, ContentType)`, `ContentRow({{required LibraryItem item, required String semanticsLabel, String? subject}})`.
  - `ShellDestination({{key, icon, selectedIcon, label, body}})`, `RoleShell({{destinations, selectedIndex, onSelected, scope, footer, accountButton, strip, String? title}})`.
  - `AccountMenuButton({{tooltip, icon, lines, onSignOut, busy}})` (keys `shell.accountMenu`, `shell.menuSignOut`), `InitialsDisc`, `RailUserRow({{lines, onSignOut, leading, busy, firstLineIsName}})` (key `shell.railSignOut`).
  - `showStudentSignOutDialog(context)` (keys `signOut.dialog`, `signOut.cancel`, `signOut.confirm`).
  - `StudentLibraryScope` (`library`, `openLibrary`), `enum StudentDestination {{home, library}}`, `StudentShell({{WidgetBuilder? libraryBuilder}})` (Task 9 passes the library screen).
  - `StudentHomeScreen`; keys `StudentHomeKeys.greeting`, `panel`, `openLibrary`; destination key `screen.studentHome`.

Brief: `docs/design/shapes/student-home.md` (confirmed 2026-10-29: greeting, class and date, then "Mới thêm vào thư viện" with the 4 newest approved items, the total and "Mở thư viện"; rows not tappable; sign-out asks first for students only).
Firestore wording maps to the contract: the "Firestore cache" is the drift snapshot (`BackendOk.isStale`), "offline, nothing cached" is `OfflineNoCacheError`, "permission denied" is `PermissionDeniedError` or `NotSetUpError`.
Shell (app-direction 6.1, generous density): large is the extended 240dp rail (lockup, the class names as scope, destinations, and a bottom user row with the initials disc, name, class and a visible "Đăng xuất"); medium and expanded are the 88dp rail with the mark and an initials-disc account menu (tooltip `accountMenuTooltip`); compact is a 56dp app bar with the lockup and the same menu, plus a bottom bar once two destinations exist (Task 9).
Phase 1 registers only built destinations: Task 8 ships Trang chủ (`navHome`); Task 9 adds Thư viện (`navLibrary`); no disabled or "coming soon" items.
Home: one column capped at 760dp; greeting `studentHomeGreeting(given name)` in Bitter 28/36 (the given name is the last word of the full name), falling back to `studentHomeGreetingNoName`; the line `studentHomeDateLine(class names, weekday date)` or `studentHomeDateOnly(date)` in muted 16/24; the greeting and date line are one heading node.
Library panel (`sheet`, padding 24): title `studentHomeLibraryTitle` (18/26), the total `studentHomeLibraryCount(n)` in 12/18 muted, at most 4 newest rows (`ContentRow` with the type word and subject separated by `MetaDot`, semantics `contentRowSemantics`), then the 56dp accent "Mở thư viện" (`studentHomeOpenLibrary`, min width 160, full width on compact), the screen's one accent.
The home and the library share one `Loadable<StudentLibrary>` owned by the shell (one query, one cache); a `SessionExpiredError` from it signs out and routes to sign-in.
Sign-out dialog: `signOutConfirmTitle`, `signOutConfirmBody`, plus `signOutOfflineWarning` when offline; `cancel` (outlined) and an ink-filled `signOut` (the accent is spent on "Mở thư viện"); busy `signOutBusy`; failure shows `signOutFailed` inside the dialog.

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Loading | Header, count bar, 4 skeleton rows, enabled button | `studentHomeLibraryTitle`, `studentHomeLoadingLibrary` (semantics) | `loading: skeleton rows, header and enabled button` |
| Populated | Greeting, class/date, newest 4, total, button | `studentHomeGreeting`, `studentHomeDateLine`, `studentHomeLibraryCount`, `studentHomeOpenLibrary`, `contentType*`, `contentRowSemantics` | `loaded: greeting with given name, class, date, newest 4` |
| Empty: no class | Two sentences, no button, date only | `studentNoClass`, `studentNoClassHint`, `studentHomeDateOnly` | `empty: no class shows the no-class sentences and no button` |
| Empty: class without content | Sentence and hint, button kept | `libraryEmpty`, `libraryEmptyHint` | `empty: class without approved content keeps the button` |
| Offline with cache | Cached rows and the strip | `networkOffline` | `offline with cache: data and the networkOffline strip` |
| Offline without cache | Error pattern with retry, never empty | `studentHomeLibraryOfflineNoCache`, `retry` | `offline without cache: offline sentence with retry` |
| Error with retry | Negative sentence, retry recovers | `studentHomeLibraryError`, `retry`, `lastUpdatedAt` (error after data) | `error with retry: sentence, retry recovers the panel` |
| Profile or role failure | `studentHomeProfileError`, greeting falls back | `studentHomeProfileError`, `studentHomeGreetingNoName` | covered by the mapping in `_LibraryPanel` (NotSetUp / PermissionDenied) |
| Reconnecting | Strip reads reconnecting, then the new item | `networkReconnecting` | `reconnect: strip reads reconnecting, then new item appears` |
| Sign-out confirm / offline / failure | Dialog states | `signOutConfirmTitle`, `signOutConfirmBody`, `signOutOfflineWarning`, `signOutFailed`, `cancel`, `signOutBusy` | `sign-out asks first; confirm returns to sign-in`; `sign-out offline adds the warning; failure stays inline` |
| Session expired | Routes to sign-in | - | `session expired on a data call routes to sign-in` |
| Layout and 200% text | Phone app bar, rail from 600dp, no overflow | - | `layout: phone has an app bar, medium and up a rail`; `200% text on a phone reflows without overflow` |

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/features/catalogue_test.dart`:

```dart
import 'package:edubox_client/edubox_client.dart';
import 'package:edubox_flutter/src/features/library/catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryItem item(String title, String subject, ContentType type, int day) =>
    LibraryItem(
      id: day,
      type: type,
      title: title,
      subject: subject,
      gradeLevel: 7,
      createdAt: DateTime.utc(2026, 10, day),
    );

void main() {
  final library = StudentLibrary(
    classes: [
      StudentClass(
        id: 1,
        name: '7A',
        gradeLevel: 7,
        subjects: ['Toán', 'Ngữ văn'],
      ),
    ],
    items: [
      item('Phân số', 'Toán', ContentType.ebook, 20),
      item('Đọc hiểu', 'Ngữ văn', ContentType.video, 21),
      item('Luyện tập', 'Toán', ContentType.exercise, 22),
      item('Nội quy', '', ContentType.ebook, 24),
      item('Từ vựng', 'Tiếng Anh', ContentType.ebook, 25),
      item('Ánh sáng', 'Vật lý', ContentType.video, 23),
      item('Phân số', 'Toán', ContentType.video, 19),
    ],
  );

  test('groups follow the class subject order, then A-Z, then other', () {
    final groups = buildCatalogue(library);
    expect(groups.map((g) => g.subject), [
      'Toán',
      'Ngữ văn',
      'Tiếng Anh',
      'Vật lý',
      null,
    ]);
  });

  test('inside a group: title A-Z, ties by type ebook, video, exercise', () {
    final toan = buildCatalogue(library).first;
    expect(toan.items.map((i) => '${i.title}/${i.type.name}'), [
      'Luyện tập/exercise',
      'Phân số/ebook',
      'Phân số/video',
    ]);
  });

  test('newest four by createdAt, newest first', () {
    expect(newestItems(library).map((i) => i.title), [
      'Từ vựng',
      'Nội quy',
      'Ánh sáng',
      'Luyện tập',
    ]);
  });
}
```

`edubox_flutter/test/widget/student_home/student_home_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:edubox_flutter/src/shell/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: greeting with given name, class, date, newest 4', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    expect(find.text(vi.studentHomeGreeting('An')), findsOneWidget);
    expect(
      find.text(vi.studentHomeDateLine('7A', 'Thứ Năm, 29/10/2026')),
      findsOneWidget,
    );
    expect(find.text(vi.studentHomeLibraryTitle), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
    // Newest four by createdAt: 25, 24, 23, 22 October.
    expect(find.text('Từ vựng Tiếng Anh 7 - Unit 1'), findsOneWidget);
    expect(find.text('Nội quy lớp học'), findsOneWidget);
    expect(find.text('Tế bào và mô'), findsOneWidget);
    expect(find.text('Luyện tập: Phép cộng phân số'), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsNothing);
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: skeleton rows, header and enabled button', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    // The restore already ran inside pumpWidget; hold the library load.
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.studentHomeLibraryTitle), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
  });

  testWidgets('empty: no class shows the no-class sentences and no button', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentNoClass);
    expect(find.text(vi.studentNoClass), findsOneWidget);
    expect(find.text(vi.studentNoClassHint), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsNothing);
    expect(
      find.text(vi.studentHomeDateOnly('Thứ Năm, 29/10/2026')),
      findsOneWidget,
    );
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('empty: class without approved content keeps the button', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentEmpty);
    expect(find.text(vi.libraryEmpty), findsOneWidget);
    expect(find.text(vi.libraryEmptyHint), findsOneWidget);
    expect(find.byKey(StudentHomeKeys.openLibrary), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: data and the networkOffline strip', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: offline sentence with retry', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    app.fake.clearCache();
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryOfflineNoCache), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    expect(find.text(vi.libraryEmpty), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error with retry: sentence, retry recovers the panel', (
    tester,
  ) async {
    final network = ManualNetworkControllerHolder.create();
    network.fake.libraryError = const UnexpectedBackendError();
    await pumpEduApp(
      tester,
      fake: network.fake,
      network: network.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.text(vi.studentHomeLibraryError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    network.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.studentHomeLibraryCount(6)), findsOneWidget);
  });

  testWidgets('reconnect: strip reads reconnecting, then new item appears', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.fake.applyReconnectDeltas();
    app.fake.holdCalls();
    app.network.goOnline();
    await tester.pump();
    expect(find.text(vi.networkReconnecting), findsOneWidget);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkReconnecting), findsNothing);
    expect(find.text(vi.studentHomeLibraryCount(7)), findsOneWidget);
    expect(find.text('Ôn tập chương 1'), findsOneWidget);
  });

  testWidgets('sign-out asks first; confirm returns to sign-in', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsOneWidget);
    expect(find.text(vi.signOutConfirmBody), findsOneWidget);
    expect(find.text(vi.signOutOfflineWarning), findsNothing);
    await expectAccessibilityGuidelines(tester);
    await tester.tap(find.byKey(const Key('signOut.confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out offline adds the warning; failure stays inline', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.studentAn,
    );
    app.network.goOffline();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.accountMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.menuSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutOfflineWarning), findsOneWidget);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byKey(const Key('signOut.confirm')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    await tester.tap(find.byKey(const Key('signOut.cancel')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsNothing);
  });

  testWidgets('session expired on a data call routes to sign-in', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.libraryError = const SessionExpiredError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('layout: phone has an app bar, medium and up a rail', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const Key('shell.accountMenu')), findsOneWidget);
    await pumpEduApp(
      tester,
      size: TestSizes.tabletPortrait,
      signedInAs: FixtureKeys.studentAn,
    );
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byType(RoleShell), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    final large = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(large.extended, isTrue);
  });

  testWidgets('200% text on a phone reflows without overflow', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.studentAn,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: student-home on $name', (tester) async {
      final app = await pumpEduApp(
        tester,
        size: size,
        signedInAs: FixtureKeys.studentAn,
      );
      await expectScreenGolden(tester, 'student_home_$name');
      app.network.goOffline();
      await tester.pumpAndSettle();
      await expectScreenGolden(tester, 'student_home_offline_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/catalogue_test.dart test/widget/student_home/student_home_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/features/library/catalogue.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/features/library/catalogue.dart`:

```dart
import 'package:edubox_client/edubox_client.dart'
    show ContentType, LibraryItem, StudentLibrary;

import '../../app/formatters.dart';

/// One subject group of the library catalogue. [subject] is null for the
/// last group of items with an empty subject ("Môn khác").
class SubjectGroup {
  const SubjectGroup({required this.subject, required this.items});

  final String? subject;
  final List<LibraryItem> items;
}

const _typeOrder = [ContentType.ebook, ContentType.video, ContentType.exercise];

/// Groups the library by subject (student-library brief section 3):
/// subjects in the order of the classes' `subjects[]` (first class first),
/// then any other subject A-Z (Vietnamese-aware), then "Môn khác" last.
/// Inside a group: title A-Z, ties by type (Sách, Video, Bài tập).
List<SubjectGroup> buildCatalogue(StudentLibrary library) {
  final classOrder = <String>[];
  for (final studentClass in library.classes) {
    for (final subject in studentClass.subjects) {
      if (!classOrder.contains(subject)) classOrder.add(subject);
    }
  }
  final bySubject = <String, List<LibraryItem>>{};
  final other = <LibraryItem>[];
  for (final item in library.items) {
    final subject = item.subject.trim();
    if (subject.isEmpty) {
      other.add(item);
    } else {
      bySubject.putIfAbsent(subject, () => []).add(item);
    }
  }
  final extra =
      bySubject.keys.where((subject) => !classOrder.contains(subject)).toList()
        ..sort(compareVietnamese);
  final ordered = [
    ...classOrder.where(bySubject.containsKey),
    ...extra,
  ];
  return [
    for (final subject in ordered)
      SubjectGroup(subject: subject, items: _sorted(bySubject[subject]!)),
    if (other.isNotEmpty) SubjectGroup(subject: null, items: _sorted(other)),
  ];
}

List<LibraryItem> _sorted(List<LibraryItem> items) => [...items]
  ..sort((a, b) {
    final byTitle = compareVietnamese(a.title, b.title);
    if (byTitle != 0) return byTitle;
    return _typeOrder.indexOf(a.type).compareTo(_typeOrder.indexOf(b.type));
  });

/// The newest [count] items by `createdAt`, newest first (student-home).
List<LibraryItem> newestItems(StudentLibrary library, {int count = 4}) => ([
  ...library.items,
]..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(count).toList();
```

`edubox_flutter/lib/src/features/library/content_row.dart`:

```dart
import 'package:edubox_client/edubox_client.dart' show ContentType, LibraryItem;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../theme/theme_extensions.dart';
import '../../shell/block_states.dart';
import '../../theme/tokens.dart';

/// The visible type word: "Sách", "Video", "Bài tập".
String contentTypeLabel(AppLocalizations l10n, ContentType type) =>
    switch (type) {
      ContentType.ebook => l10n.contentTypeEbook,
      ContentType.video => l10n.contentTypeVideo,
      ContentType.exercise => l10n.contentTypeExercise,
    };

IconData _typeGlyph(ContentType type) => switch (type) {
  ContentType.ebook => Icons.menu_book_outlined,
  ContentType.video => Icons.play_circle_outline,
  ContentType.exercise => Icons.edit_note_outlined,
};

/// One catalogue row, shared by student-home and student-library: a
/// 48x64 cover slot (decorative glyph until phase 2 covers), the title
/// (up to 2 lines, 3 at 1.5x text) and a muted meta line. Not tappable in
/// phase 1: no ripple, no chevron, no focus stop. One semantics node.
class ContentRow extends StatelessWidget {
  const ContentRow({
    super.key,
    required this.item,
    required this.semanticsLabel,
    this.subject,
  });

  final LibraryItem item;

  /// `contentRowSemantics` on the home, `libraryItemSemantics` in the
  /// library.
  final String semanticsLabel;

  /// Shown after the type word on the home ("Sách · Toán"); null in the
  /// library, where the subject is the group heading.
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = EduPalette.of(context);
    final text = Theme.of(context).textTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final meta = text.bodyMedium!.copyWith(color: palette.muted);
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: EduDensity.of(context).rowHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EduSpace.s4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.sheet,
                  border: Border.all(color: palette.rule),
                  borderRadius: BorderRadius.circular(EduRadius.small),
                ),
                child: Icon(
                  _typeGlyph(item.type),
                  size: 24,
                  color: palette.muted,
                ),
              ),
              const SizedBox(width: EduSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: scale >= 1.5 ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(contentTypeLabel(l10n, item.type), style: meta),
                        if (subject != null && subject!.isNotEmpty) ...[
                          const MetaDot(),
                          Text(subject!, style: meta),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/shell/role_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';
import 'edu_mark.dart';

/// One navigation destination. Register a destination only in the phase
/// that ships its screen: no disabled or "coming soon" items.
class ShellDestination {
  const ShellDestination({
    required this.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.body,
  });

  final Key key;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;
}

/// The destination-driven shell shared by the student and teacher roles
/// (app-direction section 6; width decides, never orientation):
///
/// - large (>= 1200): extended 240dp rail on `paper`: lockup, [scope],
///   destinations, and [footer] at the bottom.
///   Arithmetic: 1280 = 240 rail + 32 + 976 content + 32.
/// - medium/expanded (600-1199): 88dp rail with the mark only.
///   Arithmetic: 800 = 88 rail + 24 + 664 content + 24.
/// - compact (< 600): an app bar, and a bottom `NavigationBar` only when
///   there are two or more destinations.
///
/// The active destination is the neutral `active` pill; no accent in the
/// navigation. Each destination keeps its state in an [IndexedStack].
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.scope,
    required this.footer,
    required this.accountButton,
    required this.strip,
    this.title,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Under the lockup in the extended rail (the class, or the teacher).
  final Widget scope;

  /// The extended rail's bottom user row with its visible sign-out.
  final Widget footer;

  /// The account menu button used below the large window class.
  final Widget accountButton;

  /// The offline / reconnecting strip, at the top of the canvas.
  final Widget strip;

  /// When set, an app bar with this h1 shows at every width and holds
  /// [accountButton] below the large class (teacher). When null, only the
  /// compact class gets an app bar, with the lockup (student).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final body = IndexedStack(
      index: selectedIndex,
      children: [
        for (final destination in destinations)
          KeyedSubtree(key: destination.key, child: destination.body),
      ],
    );
    final appBar = _appBar(context, window);
    // With a rail, the app bar sits over the canvas only; the rail runs the
    // full height. On compact it is the Scaffold's app bar.
    final canvas = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (window.hasRail && appBar != null)
          SizedBox(height: appBar.preferredSize.height, child: appBar),
        strip,
        Expanded(child: body),
      ],
    );
    return Scaffold(
      appBar: window.hasRail ? null : appBar,
      bottomNavigationBar: window.isCompact && destinations.length >= 2
          ? _bottomBar(context)
          : null,
      body: SafeArea(
        child: window.hasRail
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rail(context, window),
                  Expanded(child: canvas),
                ],
              )
            : canvas,
      ),
    );
  }

  PreferredSizeWidget? _appBar(BuildContext context, WindowClass window) {
    final showAccount = !window.hasExtendedRail;
    if (title != null) {
      return AppBar(
        toolbarHeight: 56,
        // The h1 shares the canvas's left edge with the first panel.
        titleSpacing: window.isCompact ? null : window.gutter,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium,
        leading: window.isCompact
            ? const Padding(
                padding: EdgeInsets.all(EduSpace.s16),
                child: EduMarkGlyph(),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Semantics(header: true, child: Text(title!)),
        actions: [
          if (showAccount) accountButton,
          const SizedBox(width: EduSpace.s8),
        ],
      );
    }
    if (!window.isCompact) return null;
    return AppBar(
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      title: const EduLockup(),
      actions: [
        accountButton,
        const SizedBox(width: EduSpace.s8),
      ],
    );
  }

  Widget _rail(BuildContext context, WindowClass window) {
    final extended = window.hasExtendedRail;
    return NavigationRail(
      extended: extended,
      minExtendedWidth: EduSize.railExtended,
      minWidth: EduSize.railCollapsed,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      leading: Padding(
        padding: const EdgeInsets.only(
          top: EduSpace.s16,
          bottom: EduSpace.s24,
        ),
        child: extended
            ? SizedBox(
                width: EduSize.railExtended - 2 * EduSpace.s24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EduLockup(),
                    const SizedBox(height: EduSpace.s16),
                    scope,
                  ],
                ),
              )
            : const EduMarkGlyph(),
      ),
      trailingAtBottom: true,
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: EduSpace.s16),
        child: extended
            ? SizedBox(
                width: EduSize.railExtended - 2 * EduSpace.s24,
                child: footer,
              )
            : (title == null ? accountButton : const SizedBox.shrink()),
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: EduPalette.of(context).rule)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
```

`edubox_flutter/lib/src/shell/account_menu.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// An icon button (tooltip = accessible name) that opens a menu with a
/// non-interactive header ([lines]: name, then muted details), a rule, and
/// one "Đăng xuất" item.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.lines,
    required this.onSignOut,
    this.busy = false,
  });

  final String tooltip;
  final Widget icon;
  final List<String> lines;
  final VoidCallback onSignOut;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    return MenuAnchor(
      menuChildren: [
        if (lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EduSpace.s16,
              EduSpace.s12,
              EduSpace.s16,
              EduSpace.s12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lines.first, style: text.titleMedium),
                  for (final line in lines.skip(1))
                    Text(
                      line,
                      style: text.bodyMedium!.copyWith(color: palette.muted),
                    ),
                ],
              ),
            ),
          ),
        if (lines.isNotEmpty) const Divider(),
        MenuItemButton(
          key: const Key('shell.menuSignOut'),
          leadingIcon: const Icon(Icons.logout_outlined, size: 18),
          onPressed: busy ? null : onSignOut,
          child: Text(busy ? l10n.signOutBusy : l10n.signOut),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const Key('shell.accountMenu'),
        tooltip: tooltip,
        icon: icon,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// A full-circle initials disc (people are the only circles).
class InitialsDisc extends StatelessWidget {
  const InitialsDisc({super.key, required this.initials, this.size = 32});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = EduPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.active,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

/// The extended rail's bottom user row: [leading], name and detail lines,
/// then a visible "Đăng xuất" text button (48dp).
class RailUserRow extends StatelessWidget {
  const RailUserRow({
    super.key,
    required this.lines,
    required this.onSignOut,
    this.leading,
    this.busy = false,
    this.firstLineIsName = true,
  });

  final Widget? leading;
  final List<String> lines;
  final VoidCallback onSignOut;
  final bool busy;

  /// False when the first line is not a name (the teacher's email row),
  /// so every line is muted body text.
  final bool firstLineIsName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: EduSpace.s8),
            ],
            Expanded(
              // One node for the identity lines ("name\nclass").
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lines.isNotEmpty)
                      Text(
                        lines.first,
                        style: firstLineIsName
                            ? text.titleSmall
                            : text.bodyMedium!.copyWith(color: palette.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    for (final line in lines.skip(1))
                      Text(
                        line,
                        style: text.bodyMedium!.copyWith(color: palette.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: EduSpace.s8),
        TextButton.icon(
          key: const Key('shell.railSignOut'),
          onPressed: busy ? null : onSignOut,
          icon: const Icon(Icons.logout_outlined, size: 18),
          label: Text(busy ? l10n.signOutBusy : l10n.signOut),
        ),
      ],
    );
  }
}
```

`edubox_flutter/lib/src/shell/sign_out_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../shell/block_states.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// Students only: confirm sign-out, with the offline warning (a cached
/// session signed out offline cannot sign in again until there is a
/// connection). Teacher, parent and account-not-set-up sign out at once.
Future<void> showStudentSignOutDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _StudentSignOutDialog(),
);

class _StudentSignOutDialog extends StatefulWidget {
  const _StudentSignOutDialog();

  @override
  State<_StudentSignOutDialog> createState() => _StudentSignOutDialogState();
}

class _StudentSignOutDialogState extends State<_StudentSignOutDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final error = await AppScope.of(context).session.signOut();
    // On success the app root closes this dialog when the stage changes.
    if (mounted && error != null) {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final palette = EduPalette.of(context);
    final offline = !scope.connectivity.isOnline;
    return AlertDialog(
      key: const Key('signOut.dialog'),
      title: Text(l10n.signOutConfirmTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signOutConfirmBody),
            if (offline) ...[
              const SizedBox(height: EduSpace.s12),
              Text(l10n.signOutOfflineWarning),
            ],
            if (_failed) ...[
              const SizedBox(height: EduSpace.s12),
              BlockMessage(tone: BlockTone.error, message: l10n.signOutFailed),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('signOut.cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('signOut.confirm'),
          // Ink fill: the screen's one accent is already "Mở thư viện".
          style: FilledButton.styleFrom(
            backgroundColor: palette.ink,
            foregroundColor: palette.sheet,
            disabledBackgroundColor: palette.ink,
            disabledForegroundColor: palette.sheet,
          ),
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? BusyLabel(label: l10n.signOutBusy, color: palette.sheet)
              : Text(l10n.signOut),
        ),
      ],
    );
  }
}
```

`edubox_flutter/lib/src/shell/student_shell.dart`:

```dart
import 'dart:async';

import 'package:edubox_client/edubox_client.dart' show StudentLibrary;
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../app/connectivity_state.dart';
import '../app/formatters.dart';
import '../app/loadable.dart';
import '../contract/backend_result.dart';
import '../screens/student_home/student_home_screen.dart';
import '../theme/theme_extensions.dart';
import 'account_menu.dart';
import 'offline_strip.dart';
import 'role_shell.dart';
import 'sign_out_dialog.dart';

/// The student's one library query, shared by home and library (one
/// provider, one cache), plus the "open the library" navigation.
class StudentLibraryScope extends InheritedNotifier<Loadable<StudentLibrary>> {
  const StudentLibraryScope({
    super.key,
    required Loadable<StudentLibrary> library,
    required this.openLibrary,
    required super.child,
  }) : super(notifier: library);

  final VoidCallback openLibrary;

  static StudentLibraryScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<StudentLibraryScope>();
    assert(scope != null, 'No StudentLibraryScope above this widget.');
    return scope!;
  }

  Loadable<StudentLibrary> get library => notifier!;
}

/// Student destinations, in their fixed order. Phase 1 ships two.
enum StudentDestination { home, library }

/// The student shell: generous density, rail or bottom bar by width,
/// sign-out with confirmation.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, this.libraryBuilder});

  /// Builds the Thư viện destination; null until the library screen ships.
  final WidgetBuilder? libraryBuilder;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  Loadable<StudentLibrary>? _library;
  late AppScope _scope;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_library == null) {
      final library = Loadable<StudentLibrary>(
        _scope.services.backend.library.library,
      )..addListener(_onLibrary);
      _library = library;
      _scope.connectivity.register(library.load);
      unawaited(library.load());
    }
  }

  void _onLibrary() {
    if (_library!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final library = _library!;
    _scope.connectivity.unregister(library.load);
    library
      ..removeListener(_onLibrary)
      ..dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = _library!;
    final session = _scope.session;
    final name = session.session?.profile?.name ?? '';
    return Theme(
      data: EduDensity.student.apply(Theme.of(context)),
      child: StudentLibraryScope(
        library: library,
        openLibrary: () {
          if (widget.libraryBuilder != null) {
            _select(StudentDestination.library.index);
          }
        },
        child: ListenableBuilder(
          listenable: Listenable.merge([_scope.connectivity, library]),
          builder: (context, _) {
            final classNames = EduFormat.joinValues(
              library.value?.classes.map((c) => c.name) ?? const [],
            );
            final refreshedAt = session.sessionRefreshedAt;
            final staleLibrary =
                _index == StudentDestination.library.index &&
                library.isStale &&
                library.cachedAt != null &&
                refreshedAt != null &&
                library.cachedAt!.isBefore(refreshedAt);
            final details = [name, if (classNames.isNotEmpty) classNames];
            return RoleShell(
              selectedIndex: _index,
              onSelected: _select,
              strip: OfflineStrip(
                state: _scope.connectivity.strip,
                staleWording:
                    staleLibrary &&
                    _scope.connectivity.strip == StripState.offline,
              ),
              scope: Text(
                classNames,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              footer: RailUserRow(
                leading: InitialsDisc(initials: EduFormat.initials(name)),
                lines: details,
                onSignOut: () => showStudentSignOutDialog(context),
              ),
              accountButton: AccountMenuButton(
                tooltip: l10n.accountMenuTooltip,
                icon: InitialsDisc(initials: EduFormat.initials(name)),
                lines: details,
                onSignOut: () => showStudentSignOutDialog(context),
              ),
              destinations: [
                ShellDestination(
                  key: const Key('screen.studentHome'),
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_outlined,
                  label: l10n.navHome,
                  body: const StudentHomeScreen(),
                ),
                if (widget.libraryBuilder != null)
                  ShellDestination(
                    key: const Key('screen.studentLibrary'),
                    icon: Icons.local_library_outlined,
                    selectedIcon: Icons.local_library_outlined,
                    label: l10n.navLibrary,
                    body: Builder(builder: widget.libraryBuilder!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/screens/student_home/student_home_screen.dart`:

```dart
import 'package:edubox_client/edubox_client.dart' show StudentLibrary;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../features/library/catalogue.dart';
import '../../features/library/content_row.dart';
import '../../shell/block_states.dart';
import '../../shell/student_shell.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class StudentHomeKeys {
  static const greeting = Key('studentHome.greeting');
  static const panel = Key('studentHome.libraryPanel');
  static const openLibrary = Key('studentHome.openLibrary');
}

/// `student-home` (docs/design/shapes/student-home.md): greeting, class
/// and date, then "Mới thêm vào thư viện" with the newest 4 approved items,
/// the total and "Mở thư viện" (the screen's one accent).
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final libraryScope = StudentLibraryScope.of(context);
    final library = libraryScope.library;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);

    final profileFailed =
        !library.hasValue &&
        (library.error is NotSetUpError ||
            library.error is PermissionDeniedError);
    final given = EduFormat.givenName(
      scope.session.session?.profile?.name ?? '',
    );
    final greeting = profileFailed || given.isEmpty
        ? l10n.studentHomeGreetingNoName
        : l10n.studentHomeGreeting(given);
    final date = EduFormat.weekdayDate(scope.services.clock());
    final classNames = EduFormat.joinValues(
      library.value?.classes.map((c) => c.name) ?? const [],
    );
    final dateLine = classNames.isEmpty
        ? l10n.studentHomeDateOnly(date)
        : l10n.studentHomeDateLine(classNames, date);
    final loadingNames = !library.hasValue && library.error == null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        window.gutter,
        window.isCompact ? EduSpace.s16 : EduSpace.s32,
        window.gutter,
        EduSpace.s32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EduSize.readingMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // One heading node: the greeting and the class/date line
                // merge into it (no composed label string).
                MergeSemantics(
                  key: StudentHomeKeys.greeting,
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: text.displayMedium),
                        const SizedBox(height: EduSpace.s4),
                        if (loadingNames)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: SkeletonBar(width: 220),
                          )
                        else
                          Text(
                            dateLine,
                            style: text.bodyLarge!.copyWith(
                              color: palette.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: EduSpace.s24),
                _LibraryPanel(
                  library: library,
                  onOpenLibrary: libraryScope.openLibrary,
                  compact: window.isCompact,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel({
    required this.library,
    required this.onOpenLibrary,
    required this.compact,
  });

  final Loadable<StudentLibrary> library;
  final VoidCallback onOpenLibrary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = library.value;
    final error = library.error;
    final noClass = value != null && value.classes.isEmpty;
    final showButton = !noClass;

    final Widget body;
    if (value == null && error == null) {
      body = Semantics(
        label: l10n.studentHomeLoadingLibrary,
        liveRegion: true,
        container: true,
        child: Column(
          children: [for (var i = 0; i < 4; i++) const _SkeletonRow()],
        ),
      );
    } else if (value == null) {
      body = BlockMessage(
        tone: BlockTone.error,
        message: switch (error) {
          OfflineNoCacheError() => l10n.studentHomeLibraryOfflineNoCache,
          NotSetUpError() ||
          PermissionDeniedError() => l10n.studentHomeProfileError,
          _ => l10n.studentHomeLibraryError,
        },
        action: RetryButton(
          onPressed: library.load,
          busy: library.isLoading,
        ),
      );
    } else if (noClass) {
      body = BlockMessage(
        message: l10n.studentNoClass,
        hint: l10n.studentNoClassHint,
      );
    } else if (value.items.isEmpty) {
      body = BlockMessage(
        message: l10n.libraryEmpty,
        hint: l10n.libraryEmptyHint,
      );
    } else {
      final newest = newestItems(value);
      body = Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: EduSpace.s16),
              child: BlockMessage(
                tone: BlockTone.error,
                message: l10n.studentHomeLibraryError,
                hint: library.cachedAt == null
                    ? null
                    : l10n.lastUpdatedAt(
                        EduFormat.lastGood(
                          library.cachedAt!,
                          AppScope.of(context).services.clock(),
                        ),
                      ),
                action: RetryButton(
                  onPressed: library.load,
                  busy: library.isLoading,
                ),
              ),
            ),
          for (final (index, item) in newest.indexed) ...[
            if (index > 0) const Divider(),
            ContentRow(
              item: item,
              subject: item.subject,
              semanticsLabel: l10n.contentRowSemantics(
                item.title,
                contentTypeLabel(l10n, item.type),
                item.subject,
              ),
            ),
          ],
        ],
      );
    }

    return Card(
      key: StudentHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.studentHomeLibraryTitle, style: text.titleLarge),
            if (value != null && !noClass && value.items.isNotEmpty)
              Text(
                l10n.studentHomeLibraryCount(value.items.length),
                style: text.bodySmall,
              )
            else if (value == null && error == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SkeletonBar(width: 140, height: 12),
              ),
            const SizedBox(height: EduSpace.s16),
            body,
            if (showButton) ...[
              const SizedBox(height: EduSpace.s24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  height: EduSize.primaryButton,
                  width: compact ? double.infinity : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 160),
                    child: FilledButton(
                      key: StudentHomeKeys.openLibrary,
                      onPressed: onOpenLibrary,
                      child: Text(l10n.studentHomeOpenLibrary),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EduDensity.of(context).rowHeight,
      child: const Row(
        children: [
          SkeletonBar(width: 48, height: 64),
          SizedBox(width: EduSpace.s16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBar(width: 220),
                SizedBox(height: EduSpace.s8),
                SkeletonBar(width: 96, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../shell/student_shell.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => const StudentShell(),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/features test/widget/student_home`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/student_home_phone.png`
- `test/widget/goldens/student_home_tablet.png`
- `test/widget/goldens/student_home_offline_phone.png`
- `test/widget/goldens/student_home_offline_tablet.png`

Run: `flutter test test/features test/widget/student_home`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] "Mở thư viện" is the only accent fill; the rail's active destination is a grey pill with ink icon and label.
- [ ] "Chào An" is the largest text, Bitter; the class and date line is grey under it; no emoji, counts of finished work or streaks.
- [ ] Rows: a 48x64 cover slot with a grey 1px edge and a grey type glyph, the title in 16/24 semibold, then "Sách · Tiếng Anh" in grey with a small dot between the words; 1px rules between rows; no chevrons or ripples (rows are not tappable).
- [ ] The total "6 tài liệu cho lớp em" sits right under the panel title; the panel is capped at 760dp and centred on the tablet.
- [ ] In the offline PNGs the 40dp grey strip spans the canvas top (not the rail) with the `cloud_off` glyph and "Đang ngoại tuyến. Dữ liệu đã lưu vẫn hiển thị."
- [ ] The extended rail shows the lockup, the class, the destination, and at the bottom the initials disc, name, class and "Đăng xuất".

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/features/library/catalogue.dart \
  edubox_flutter/lib/src/features/library/content_row.dart \
  edubox_flutter/lib/src/shell/role_shell.dart \
  edubox_flutter/lib/src/shell/account_menu.dart \
  edubox_flutter/lib/src/shell/sign_out_dialog.dart \
  edubox_flutter/lib/src/shell/student_shell.dart \
  edubox_flutter/lib/src/screens/student_home/student_home_screen.dart \
  edubox_flutter/test/features/catalogue_test.dart \
  edubox_flutter/test/widget/student_home/student_home_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/student_home_phone.png \
  edubox_flutter/test/widget/goldens/student_home_tablet.png \
  edubox_flutter/test/widget/goldens/student_home_offline_phone.png \
  edubox_flutter/test/widget/goldens/student_home_offline_tablet.png
git commit -m "feat: student shell and student-home screen"
```


---

## Task 9: Screen `student-library`

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (library PNGs and the regenerated student-home PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/screens/student_library/student_library_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (pass `libraryBuilder` to `StudentShell`)
- Test: `edubox_flutter/test/widget/student_library/student_library_screen_test.dart`
- Regenerate: the four `student_home_*.png` goldens (the rail and bottom bar now show two destinations)

**Interfaces:**
- Consumes: Task 8 (`StudentLibraryScope`, `buildCatalogue`, `ContentRow`, `contentTypeLabel`, `StudentHomeKeys.openLibrary`), Task 5 blocks.
- Produces: `StudentLibraryScreen`; keys `StudentLibraryKeys.header` (`studentLibrary.header`), `list`; destination key `screen.studentLibrary`.

Brief: `docs/design/shapes/student-library.md` (confirmed 2026-10-29: grouped by subject in the class's `subjects[]` order, A-Z by title inside a group, exercises listed with "Bài tập", no search or filter, rows not tappable).
"An empty snapshot that is `isFromCache` while offline" maps to `OfflineNoCacheError`; the "stream error" maps to any other failure.
Layout: a pinned header (h1 `libraryTitle` in Bitter 24/32 and the total `libraryTotal(n)` in muted 16/24) above a scrolling list; the list is one semantics container `libraryListSemantics`; each group has a `titleLarge` subject heading (or `librarySubjectOther` for an empty subject, always last) and a `sheet` panel of rows separated by 1px rules; each row reads `libraryItemSemantics(title, type)` and shows the type word only.
Expanded and large classes flow each group's rows into two equal columns, column-major (split at `ceil(n/2)`), at full canvas width; medium and compact use one column capped at 760dp; text scale 1.5x or more forces one column.
No dominant accent and no primary action on this screen.
Error after data was shown keeps the rows and puts `libraryLoadErrorWithTime(HH:mm)` with "Thử lại" in a band above the groups.
Offline without cache shows `libraryOfflineNoData` with the neutral `cloud_off` glyph and no retry (it fills on reconnect).

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Loading | h1 at once, total bar, two skeleton groups, one live label | `libraryTitle`, `libraryLoading` | `loading: h1 at once, skeleton announced as one label` |
| Populated | Exactly the approved fixtures, grouped and ordered | `libraryTotal`, `librarySubjectOther`, `libraryItemSemantics`, `contentType*` | `full: exactly the approved fixtures, grouped by subject`; `group order: class subjects, then others, then Môn khác` |
| Empty | One muted sentence, total reads 0 | `libraryEmpty`, `libraryTotal` | `empty: one sentence, total reads 0` |
| Offline with cache | Rows and the strip | `networkOffline` | `offline with cache: rows and the networkOffline strip` |
| Offline without cache | Neutral sentence, never empty, no retry | `libraryOfflineNoData` | `cold offline start without cache shows libraryOfflineNoData` |
| Error with retry; error after data | Negative sentence and retry; band above kept rows | `libraryLoadError`, `libraryLoadErrorWithTime`, `retry` | `error with retry, and error after data keeps the rows` |
| Navigation | "Mở thư viện" selects this destination; phone bottom bar | `navLibrary` | `Mở thư viện on the home selects this destination`; `phone: bottom bar with both destinations` |
| Text at 200% | One column, no overflow | - | `200% text: one column, no overflow` |

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/widget/student_library/student_library_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:edubox_flutter/src/screens/student_library/student_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Future<TestApp> openLibrary(
  WidgetTester tester, {
  String student = FixtureKeys.studentAn,
  Size size = TestSizes.tablet,
  double textScale = 1,
  ManualNetworkControllerHolder? holder,
}) async {
  final app = await pumpEduApp(
    tester,
    size: size,
    textScale: textScale,
    signedInAs: student,
    fake: holder?.fake,
    network: holder?.network,
  );
  await tester.tap(find.text(vi.navLibrary).last);
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('full: exactly the approved fixtures, grouped by subject', (
    tester,
  ) async {
    await openLibrary(tester);
    expect(find.text(vi.libraryTitle), findsWidgets);
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);
    final expected = FixtureSet.phase1().libraryOfStudent(
      FixtureKeys.studentAn,
    );
    for (final item in expected) {
      expect(find.text(item.title), findsWidgets, reason: item.title);
    }
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
    for (final subject in ['Toán', 'Ngữ văn', 'Khoa học tự nhiên']) {
      expect(find.text(subject), findsOneWidget, reason: subject);
    }
    expect(find.text(vi.librarySubjectOther), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('group order: class subjects, then others, then Môn khác', (
    tester,
  ) async {
    await openLibrary(tester, size: TestSizes.tabletPortrait);
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    expect(top('Toán'), lessThan(top('Ngữ văn')));
    expect(top('Ngữ văn'), lessThan(top('Khoa học tự nhiên')));
    expect(top('Khoa học tự nhiên'), lessThan(top('Tiếng Anh')));
    await tester.scrollUntilVisible(
      find.text(vi.librarySubjectOther),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(vi.librarySubjectOther), findsOneWidget);
  });

  testWidgets('loading: h1 at once, skeleton announced as one label', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.studentAn,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text(vi.navLibrary).last);
    await tester.pump();
    expect(find.text(vi.libraryTotal(6)), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(vi.libraryLoading), findsOneWidget);
    semantics.dispose();
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);
  });

  testWidgets('empty: one sentence, total reads 0', (tester) async {
    await openLibrary(tester, student: FixtureKeys.studentEmpty);
    expect(find.text(vi.libraryEmpty), findsOneWidget);
    expect(find.text(vi.libraryTotal(0)), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: rows and the networkOffline strip', (
    tester,
  ) async {
    final app = await openLibrary(tester);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('cold offline start without cache shows libraryOfflineNoData', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.signInAs(FixtureKeys.studentAn);
    holder.fake.clearCache();
    holder.fake.hasCache = true;
    holder.fake.libraryError = const OfflineNoCacheError();
    await openLibrary(tester, holder: holder);
    expect(find.text(vi.libraryOfflineNoData), findsOneWidget);
    expect(find.text(vi.libraryEmpty), findsNothing);
    expect(find.byKey(const Key('block.retry')), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error with retry, and error after data keeps the rows', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.libraryError = const UnexpectedBackendError();
    final app = await openLibrary(tester, holder: holder);
    expect(find.text(vi.libraryLoadError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryTotal(6)), findsOneWidget);

    app.fake.libraryError = const UnexpectedBackendError();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.libraryLoadErrorWithTime('09:14')), findsOneWidget);
    expect(find.text('Phân số và số thập phân'), findsOneWidget);
  });

  testWidgets('Mở thư viện on the home selects this destination', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
    await tester.pumpAndSettle();
    expect(find.byKey(StudentLibraryKeys.header), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 1);
  });

  testWidgets('phone: bottom bar with both destinations', (tester) async {
    await openLibrary(tester, size: TestSizes.phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(StudentLibraryKeys.header), findsOneWidget);
  });

  testWidgets('200% text: one column, no overflow', (tester) async {
    await openLibrary(tester, size: TestSizes.phone, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: student-library on $name', (tester) async {
      await openLibrary(tester, size: size);
      await expectScreenGolden(tester, 'student_library_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/student_library/student_library_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/screens/student_library/student_library_screen.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/screens/student_library/student_library_screen.dart`:

```dart
import 'package:edubox_client/edubox_client.dart'
    show LibraryItem, StudentLibrary;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../features/library/catalogue.dart';
import '../../features/library/content_row.dart';
import '../../shell/block_states.dart';
import '../../shell/student_shell.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class StudentLibraryKeys {
  static const header = Key('studentLibrary.header');
  static const list = Key('studentLibrary.list');
}

/// `student-library` (docs/design/shapes/student-library.md): the
/// catalogue of approved content grouped by subject. Ink only: no dominant
/// accent, no primary action. Rows are not tappable in phase 1.
class StudentLibraryScreen extends StatelessWidget {
  const StudentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = StudentLibraryScope.of(context).library;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final value = library.value;
    final loading = value == null && library.error == null;
    final columns =
        (window == WindowClass.expanded || window == WindowClass.large) &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5
        ? 2
        : 1;
    final maxWidth = columns == 2 ? double.infinity : EduSize.readingMaxWidth;
    final padding = EdgeInsets.symmetric(horizontal: window.gutter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned header: the h1 and the total stay in view.
        Padding(
          key: StudentLibraryKeys.header,
          padding: padding.copyWith(
            top: window.isCompact ? EduSpace.s16 : EduSpace.s32,
            bottom: EduSpace.s16,
          ),
          child: _Capped(
            maxWidth: maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.libraryTitle, style: text.headlineLarge),
                ),
                const SizedBox(height: EduSpace.s4),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SkeletonBar(width: 96),
                  )
                else if (value != null)
                  Text(
                    l10n.libraryTotal(value.items.length),
                    style: text.bodyLarge!.copyWith(color: palette.muted),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            key: StudentLibraryKeys.list,
            label: l10n.libraryListSemantics,
            container: true,
            explicitChildNodes: true,
            child: ListView(
              padding: padding.copyWith(bottom: EduSpace.s32),
              children: [
                _Capped(
                  maxWidth: maxWidth,
                  child: _Body(library: library, columns: columns),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Capped extends StatelessWidget {
  const _Capped({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Full width up to the cap, centred; never shrink-wrapped.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.library, required this.columns});

  final Loadable<StudentLibrary> library;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = library.value;
    final error = library.error;
    final gap = EduDensity.of(context).gap;

    if (value == null && error == null) {
      return Semantics(
        label: l10n.libraryLoading,
        liveRegion: true,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var group = 0; group < 2; group++) ...[
              if (group > 0) SizedBox(height: gap),
              const SkeletonBar(width: 140, height: 20),
              const SizedBox(height: EduSpace.s12),
              const _SkeletonPanel(),
            ],
          ],
        ),
      );
    }
    if (value == null) {
      if (error is OfflineNoCacheError) {
        return EduPanel(
          child: BlockMessage(
            tone: BlockTone.offline,
            message: l10n.libraryOfflineNoData,
          ),
        );
      }
      return EduPanel(
        child: BlockMessage(
          tone: BlockTone.error,
          message: l10n.libraryLoadError,
          action: RetryButton(
            onPressed: library.load,
            busy: library.isLoading,
          ),
        ),
      );
    }
    if (value.items.isEmpty) {
      return EduPanel(
        child: Text(
          l10n.libraryEmpty,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: EduPalette.of(context).muted,
          ),
        ),
      );
    }
    final groups = buildCatalogue(value);
    final cachedAt = library.cachedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          EduPanel(
            child: BlockMessage(
              tone: BlockTone.error,
              message: cachedAt == null
                  ? l10n.libraryLoadError
                  : l10n.libraryLoadErrorWithTime(
                      EduFormat.lastGood(
                        cachedAt,
                        AppScope.of(context).services.clock(),
                      ),
                    ),
              action: RetryButton(
                onPressed: library.load,
                busy: library.isLoading,
              ),
            ),
          ),
          SizedBox(height: gap),
        ],
        for (final (index, group) in groups.indexed) ...[
          if (index > 0) SizedBox(height: gap),
          _SubjectGroupView(group: group, columns: columns),
        ],
      ],
    );
  }
}

class _SubjectGroupView extends StatelessWidget {
  const _SubjectGroupView({required this.group, required this.columns});

  final SubjectGroup group;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = group.subject ?? l10n.librarySubjectOther;
    final items = group.items;
    final split = (items.length / 2).ceil();
    final lists = columns == 2
        ? [items.sublist(0, split), items.sublist(split)]
        : [items];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(heading, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: EduSpace.s12),
        EduPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: EduSpace.s24,
            vertical: EduSpace.s8,
          ),
          child: lists.length == 1
              ? _Rows(items: lists.first)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Rows(items: lists[0])),
                      const SizedBox(width: EduSpace.s24),
                      Expanded(child: _Rows(items: lists[1])),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.items});

  final List<LibraryItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const Divider(),
          ContentRow(
            item: item,
            semanticsLabel: l10n.libraryItemSemantics(
              item.title,
              contentTypeLabel(l10n, item.type),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel();

  @override
  Widget build(BuildContext context) {
    return EduPanel(
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            SizedBox(
              height: EduDensity.of(context).rowHeight,
              child: const Row(
                children: [
                  SkeletonBar(width: 48, height: 64),
                  SizedBox(width: EduSpace.s16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          child: SkeletonBar(width: double.infinity),
                        ),
                        SizedBox(height: EduSpace.s8),
                        FractionallySizedBox(
                          widthFactor: 0.25,
                          child: SkeletonBar(
                            width: double.infinity,
                            height: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/student_library/student_library_screen.dart';
import '../shell/student_shell.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => StudentShell(
          libraryBuilder: (_) => const StudentLibraryScreen(),
        ),
        UserRole.teacher => const AppOpeningScreen(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/widget/student_library test/widget/student_home`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/student_library_phone.png`
- `test/widget/goldens/student_library_tablet.png`
- `test/widget/goldens/student_home_phone.png`
- `test/widget/goldens/student_home_tablet.png`
- `test/widget/goldens/student_home_offline_phone.png`
- `test/widget/goldens/student_home_offline_tablet.png`

Run: `flutter test test/widget/student_library test/widget/student_home`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] The library has no accent fill at all; the rail pill now sits on "Thư viện".
- [ ] The header ("Thư viện" and "6 tài liệu") is left-aligned with the subject headings and the panels (it must not float centred on the tablet).
- [ ] Subject headings are 18/26 semibold ink, with 12dp to their panel and 24dp between groups; "Môn khác" is last.
- [ ] On the tablet each group panel spans the canvas with two columns of rows; on the phone one column with 16dp gutters.
- [ ] The student-home PNGs, regenerated, show both destinations in the rail and in the phone's bottom bar.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/screens/student_library/student_library_screen.dart \
  edubox_flutter/test/widget/student_library/student_library_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/student_library_phone.png \
  edubox_flutter/test/widget/goldens/student_library_tablet.png \
  edubox_flutter/test/widget/goldens/student_home_phone.png \
  edubox_flutter/test/widget/goldens/student_home_tablet.png \
  edubox_flutter/test/widget/goldens/student_home_offline_phone.png \
  edubox_flutter/test/widget/goldens/student_home_offline_tablet.png
git commit -m "feat: student-library catalogue screen"
```


---

## Task 10: Teacher shell and screen `teacher-home`

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (teacher PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/shell/teacher_shell.dart`, `edubox_flutter/lib/src/screens/teacher_home/teacher_home_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (route the teacher role to `TeacherShell`)
- Test: `edubox_flutter/test/widget/teacher_home/teacher_home_screen_test.dart`

**Interfaces:**
- Consumes: Task 8 (`RoleShell`, `ShellDestination`, `AccountMenuButton`, `RailUserRow`), Task 5 (`Loadable`, blocks, `EduFormat`, `compareVietnamese`), `ClassesRepository.mine()`.
- Produces: `TeacherShell`; `TeacherHomeScreen({{required Loadable<List<ClassSummary>> classes}})`; `sortClasses(List<ClassSummary>)`; keys `TeacherHomeKeys.panel`, `table`, `stacked`; destination key `screen.teacherHome`.

Brief: `docs/design/shapes/teacher-home.md` (confirmed 2026-10-29: the "Lớp của tôi" ledger Lớp | Khối | Môn học | Học sinh, sorted by grade then name, rows not tappable, no roster screen; teacher signs out immediately).
"Live Firestore listener" maps to the `ConnectivityState` reload on reconnect; `studentUids.length` is `ClassSummary.studentCount`; "isFromCache" is `OfflineNoCacheError` versus a stale `BackendOk`.
Shell (teacher density: gap 16, panel padding 16, 48dp rows): an app bar with the h1 `navTeacherOverview` in Bitter 20/28 over the canvas (its title aligned with the panel's left edge); large has the extended rail with the lockup, the teacher's name and `teacherRoleLabel` as scope, the one destination (`dashboard_outlined`), and at the bottom the email in muted and a visible "Đăng xuất"; medium and expanded have the 88dp rail with the mark and the account menu (`more_vert`, tooltip `accountMenuTooltip`, header name and email) in the app bar; compact has the mark in the app bar, the same menu and no bottom bar (one destination).
Sign-out is immediate; a failure shows a SnackBar `signOutFailed` with a `retry` action.
Panel `teacherClassesTitle` (14/20 semibold) with the count `teacherClassesCount(n)` in IBM Plex Mono 12 muted at the right, left-aligned and capped at 760dp.
Table (wide enough): a 40dp header row of `classColumnName`, `classColumnGrade`, `classColumnSubjects`, `classColumnStudents` in 12/18 muted (excluded from semantics), a 1px rule, then rows of at least 48dp: name 14/20 semibold (never truncated), grade as a mono figure, subjects joined (up to 3 lines) or a grey `valueMissing`, student count as a right-aligned mono figure (a real zero prints "0"); each row is one node `classRowSemantics`.
Stacked rows (compact, under 560dp, or text 1.5x and up): line 1 name and `classStudentCount(n)`; line 2 `classGradeValue(grade)` `MetaDot` subjects in muted; no header row.

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Loading | Title, column heads, 3 skeleton rows | `teacherClassesLoading` (live), `classColumn*` | `loading: header, column heads and skeleton rows` |
| Populated | Ledger sorted by grade then name, "-" and "0" | `teacherClassesCount`, `classColumn*`, `classRowSemantics`, `teacherClassesLoaded`, `valueMissing` | `loaded: own classes as a ledger, sorted, with - and 0` |
| Empty | "0 lớp" and the sentence, no header row | `teacherClassesEmpty` | `empty: 0 classes, the sentence, no header row` |
| Offline with cache | Rows and the strip | `networkOffline` (or `networkOfflineStale` when the snapshot predates the last profile refresh) | `offline with cache: rows and the offline strip` |
| Offline without cache | Neutral `cloud_off` sentence, no retry, never empty | `teacherClassesOfflineNoData` | `offline without cache: neutral sentence, never empty` |
| Error with retry; error after data | Negative sentence and retry; inline line above kept rows | `teacherClassesError`, `teacherClassesStaleError`, `retry`, `retrying` | `error: sentence and retry; error after data keeps rows` |
| Reconnecting | Strip reads reconnecting, then 8B appears | `networkReconnecting` | `reconnect: the new class appears without user action` |
| Sign-out | Immediate from the rail or the menu | `signOut`, `signOutBusy` | `sign-out is immediate from the large rail`; `phone: stacked rows, account menu signs out` |
| Text at 200% | Stacked rows, no overflow | `classGradeValue`, `classStudentCount` | `200% text at tablet width switches to stacked rows` |

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/widget/teacher_home/teacher_home_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/teacher_home/teacher_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: own classes as a ledger, sorted, with - and 0', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    expect(find.text(vi.navTeacherOverview), findsWidgets);
    expect(find.text(vi.teacherClassesTitle), findsOneWidget);
    expect(find.text(vi.teacherClassesCount(3)), findsOneWidget);
    expect(find.byKey(TeacherHomeKeys.table), findsOneWidget);
    for (final header in [
      vi.classColumnName,
      vi.classColumnGrade,
      vi.classColumnSubjects,
      vi.classColumnStudents,
    ]) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('7A'), lessThan(top('7B')));
    expect(top('7B'), lessThan(top('8A')));
    expect(find.text('Toán, Ngữ văn, Khoa học tự nhiên'), findsOneWidget);
    expect(find.text(vi.valueMissing), findsOneWidget); // 8A: no subjects.
    expect(find.text('0'), findsOneWidget); // 8A: no students.
    expect(find.text('9A'), findsNothing); // Another teacher's class.
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: header, column heads and skeleton rows', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.teacherLan,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump();
    expect(find.text(vi.teacherClassesTitle), findsOneWidget);
    expect(find.text(vi.classColumnName), findsOneWidget);
    expect(find.text(vi.teacherClassesCount(3)), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text(vi.teacherClassesCount(3)), findsOneWidget);
  });

  testWidgets('empty: 0 classes, the sentence, no header row', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherNoClass);
    expect(find.text(vi.teacherClassesCount(0)), findsOneWidget);
    expect(find.text(vi.teacherClassesEmpty), findsOneWidget);
    expect(find.text(vi.classColumnName), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: rows and the offline strip', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: neutral sentence, never empty', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.classesError = const OfflineNoCacheError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.text(vi.teacherClassesOfflineNoData), findsOneWidget);
    expect(find.text(vi.teacherClassesEmpty), findsNothing);
    expect(find.text(vi.retry), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error: sentence and retry; error after data keeps rows', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.classesError = const UnexpectedBackendError();
    final app = await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.text(vi.teacherClassesError), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    app.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text('7A'), findsOneWidget);
    app.fake.classesError = const UnexpectedBackendError();
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.network.goOnline();
    await tester.pumpAndSettle();
    expect(find.text(vi.teacherClassesStaleError('09:14')), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
  });

  testWidgets('reconnect: the new class appears without user action', (
    tester,
  ) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    app.network.goOffline();
    await tester.pumpAndSettle();
    app.fake.applyReconnectDeltas();
    app.fake.holdCalls();
    app.network.goOnline();
    await tester.pump();
    expect(find.text(vi.networkReconnecting), findsOneWidget);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text('8B'), findsOneWidget);
    expect(find.text(vi.networkReconnecting), findsNothing);
  });

  testWidgets('sign-out is immediate from the large rail', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutConfirmTitle), findsNothing);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('phone: stacked rows, account menu signs out', (tester) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(find.byKey(TeacherHomeKeys.stacked), findsOneWidget);
    expect(find.text(vi.classStudentCount(1)), findsWidgets);
    expect(find.text(vi.classGradeValue(7)), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
    await expectAccessibilityGuidelines(tester);
    await tester.tap(find.byKey(const Key('shell.accountMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell.menuSignOut')));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('200% text at tablet width switches to stacked rows', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.tabletPortrait,
      textScale: 2,
      signedInAs: FixtureKeys.teacherLan,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(TeacherHomeKeys.stacked), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: teacher-home on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.teacherLan);
      await expectScreenGolden(tester, 'teacher_home_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/teacher_home/teacher_home_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/shell/teacher_shell.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/shell/teacher_shell.dart`:

```dart
import 'dart:async';

import 'package:edubox_client/edubox_client.dart' show ClassSummary;
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/app_scope.dart';
import '../app/connectivity_state.dart';
import '../app/loadable.dart';
import '../contract/backend_result.dart';
import '../screens/teacher_home/teacher_home_screen.dart';
import '../theme/theme_extensions.dart';
import 'account_menu.dart';
import 'offline_strip.dart';
import 'role_shell.dart';

/// The teacher shell: denser, table-forward. Phase 1 has one destination
/// (Tổng quan); the rail renders from 600dp up even with one item so the
/// canvas keeps its width when phase 2 adds "Nội dung". Sign-out is
/// immediate (no confirmation).
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  Loadable<List<ClassSummary>>? _classes;
  late AppScope _scope;
  bool _signingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_classes == null) {
      final classes = Loadable<List<ClassSummary>>(
        _scope.services.backend.classes.mine,
      )..addListener(_onClasses);
      _classes = classes;
      _scope.connectivity.register(classes.load);
      unawaited(classes.load());
    }
  }

  void _onClasses() {
    if (_classes!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final classes = _classes!;
    _scope.connectivity.unregister(classes.load);
    classes
      ..removeListener(_onClasses)
      ..dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final error = await _scope.session.signOut();
    if (!mounted || error == null) return;
    setState(() => _signingOut = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.signOutFailed),
        action: SnackBarAction(label: l10n.retry, onPressed: _signOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final classes = _classes!;
    final session = _scope.session;
    final profile = session.session?.profile;
    final name = profile?.name ?? '';
    final email = session.session?.signedInEmail ?? '';
    final text = Theme.of(context).textTheme;
    return Theme(
      data: EduDensity.teacher.apply(Theme.of(context)),
      child: ListenableBuilder(
        listenable: Listenable.merge([_scope.connectivity, classes]),
        builder: (context, _) {
          final refreshedAt = session.sessionRefreshedAt;
          final stale =
              classes.isStale &&
              classes.cachedAt != null &&
              refreshedAt != null &&
              classes.cachedAt!.isBefore(refreshedAt);
          return RoleShell(
            title: l10n.navTeacherOverview,
            selectedIndex: 0,
            onSelected: (_) {},
            strip: OfflineStrip(
              state: _scope.connectivity.strip,
              staleWording:
                  stale && _scope.connectivity.strip == StripState.offline,
            ),
            scope: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? email : name, style: text.titleSmall),
                Text(
                  l10n.teacherRoleLabel,
                  style: text.bodyMedium!.copyWith(
                    color: EduPalette.of(context).muted,
                  ),
                ),
              ],
            ),
            footer: RailUserRow(
              lines: [email],
              firstLineIsName: false,
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            accountButton: AccountMenuButton(
              tooltip: l10n.accountMenuTooltip,
              icon: const Icon(Icons.more_vert),
              lines: [if (name.isNotEmpty) name, email],
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            destinations: [
              ShellDestination(
                key: const Key('screen.teacherHome'),
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_outlined,
                label: l10n.navTeacherOverview,
                body: TeacherHomeScreen(classes: classes),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

`edubox_flutter/lib/src/screens/teacher_home/teacher_home_screen.dart`:

```dart
import 'package:edubox_client/edubox_client.dart' show ClassSummary;
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/formatters.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../shell/block_states.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class TeacherHomeKeys {
  static const panel = Key('teacherHome.classesPanel');
  static const table = Key('teacherHome.table');
  static const stacked = Key('teacherHome.stacked');
}

/// Classes sorted by grade (numeric), then name (Vietnamese-aware).
List<ClassSummary> sortClasses(List<ClassSummary> classes) =>
    [...classes]..sort((a, b) {
      final byGrade = a.gradeLevel.compareTo(b.gradeLevel);
      return byGrade != 0 ? byGrade : compareVietnamese(a.name, b.name);
    });

/// `teacher-home` (docs/design/shapes/teacher-home.md): the "Lớp của tôi"
/// ledger (Lớp | Khối | Môn học | Học sinh). No dominant accent and no
/// primary action in phase 1. Rows are not tappable.
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key, required this.classes});

  final Loadable<List<ClassSummary>> classes;

  @override
  Widget build(BuildContext context) {
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    final density = EduDensity.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        window.gutter,
        density.gap,
        window.gutter,
        EduSpace.s32,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EduSize.readingMaxWidth,
            ),
            child: _ClassesPanel(classes: classes, compact: window.isCompact),
          ),
        ),
      ],
    );
  }
}

class _ClassesPanel extends StatelessWidget {
  const _ClassesPanel({required this.classes, required this.compact});

  final Loadable<List<ClassSummary>> classes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final value = classes.value;
    final error = classes.error;
    final extras = EduTypeExtras.of(context);
    final palette = EduPalette.of(context);

    final Widget body;
    if (value == null && error == null) {
      body = Semantics(
        label: l10n.teacherClassesLoading,
        liveRegion: true,
        container: true,
        child: const _Skeleton(),
      );
    } else if (value == null) {
      body = error is OfflineNoCacheError
          ? BlockMessage(
              tone: BlockTone.offline,
              message: l10n.teacherClassesOfflineNoData,
              messageStyle: text.bodyMedium,
            )
          : BlockMessage(
              tone: BlockTone.error,
              message: l10n.teacherClassesError,
              messageStyle: text.bodyMedium,
              action: RetryButton(
                onPressed: classes.load,
                busy: classes.isLoading,
              ),
            );
    } else if (value.isEmpty) {
      body = Text(
        l10n.teacherClassesEmpty,
        style: text.bodyMedium!.copyWith(color: palette.muted),
      );
    } else {
      final sorted = sortClasses(value);
      final scale = MediaQuery.textScalerOf(context).scale(1);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: EduSpace.s16),
              child: BlockMessage(
                tone: BlockTone.error,
                messageStyle: text.bodyMedium,
                message: classes.cachedAt == null
                    ? l10n.teacherClassesError
                    : l10n.teacherClassesStaleError(
                        EduFormat.lastGood(
                          classes.cachedAt!,
                          AppScope.of(context).services.clock(),
                        ),
                      ),
                action: RetryButton(
                  onPressed: classes.load,
                  busy: classes.isLoading,
                ),
              ),
            ),
          Semantics(
            liveRegion: true,
            label: l10n.teacherClassesLoaded(sorted.length),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    compact || scale >= 1.5 || constraints.maxWidth < 560;
                return stacked
                    ? _StackedRows(classes: sorted)
                    : _Table(classes: sorted);
              },
            ),
          ),
        ],
      );
    }

    return Card(
      key: TeacherHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.teacherClassesTitle,
                      style: text.titleSmall,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    l10n.teacherClassesCount(value.length),
                    style: extras.timestamp,
                  ),
              ],
            ),
            const SizedBox(height: EduSpace.s12),
            body,
          ],
        ),
      ),
    );
  }
}

/// Column flex: identity column 35-45% and never truncated.
const _flex = [8, 3, 8, 3];

class _Table extends StatelessWidget {
  const _Table({required this.classes});

  final List<ClassSummary> classes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final extras = EduTypeExtras.of(context);
    final palette = EduPalette.of(context);
    final header = text.bodySmall!.copyWith(color: palette.muted);
    return Column(
      key: TeacherHomeKeys.table,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header texts are excluded: each row label carries the column names.
        ExcludeSemantics(
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: Text(l10n.classColumnName, style: header),
                ),
                Expanded(
                  flex: _flex[1],
                  child: Text(l10n.classColumnGrade, style: header),
                ),
                Expanded(
                  flex: _flex[2],
                  child: Text(l10n.classColumnSubjects, style: header),
                ),
                Expanded(
                  flex: _flex[3],
                  child: Text(
                    l10n.classColumnStudents,
                    style: header,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        for (final (index, item) in classes.indexed) ...[
          if (index > 0) const Divider(),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: _rowLabel(l10n, item),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: EduDensity.of(context).rowHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: EduSpace.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: _flex[0],
                      child: Text(item.name, style: text.titleSmall),
                    ),
                    Expanded(
                      flex: _flex[1],
                      child: Text(
                        EduFormat.figure(item.gradeLevel),
                        style: extras.figureTeacher,
                      ),
                    ),
                    Expanded(
                      flex: _flex[2],
                      child: _Subjects(subjects: item.subjects, maxLines: 3),
                    ),
                    Expanded(
                      flex: _flex[3],
                      child: Text(
                        EduFormat.figure(item.studentCount),
                        style: extras.figureTeacher,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StackedRows extends StatelessWidget {
  const _StackedRows({required this.classes});

  final List<ClassSummary> classes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final muted = text.bodyMedium!.copyWith(color: palette.muted);
    return Column(
      key: TeacherHomeKeys.stacked,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in classes.indexed) ...[
          if (index > 0) const Divider(),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: _rowLabel(l10n, item),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: EduSpace.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.name, style: text.titleSmall),
                        ),
                        Text(
                          l10n.classStudentCount(item.studentCount),
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: EduSpace.s4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.classGradeValue(item.gradeLevel),
                          style: muted,
                        ),
                        const MetaDot(),
                        _Subjects(subjects: item.subjects, style: muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Subjects joined for display, or the grey "-" when there are none.
class _Subjects extends StatelessWidget {
  const _Subjects({required this.subjects, this.maxLines, this.style});

  final List<String> subjects;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (subjects.isEmpty) {
      return Text(
        l10n.valueMissing,
        style: text.bodyMedium!.copyWith(color: EduPalette.of(context).muted),
      );
    }
    return Text(
      EduFormat.joinValues(subjects),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style ?? text.bodyMedium,
    );
  }
}

String _rowLabel(AppLocalizations l10n, ClassSummary item) =>
    l10n.classRowSemantics(
      item.name,
      item.gradeLevel,
      item.subjects.isEmpty
          ? l10n.valueMissing
          : EduFormat.joinValues(item.subjects),
      item.studentCount,
    );

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final header = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: Text(l10n.classColumnName, style: header),
                ),
                Expanded(
                  flex: _flex[1],
                  child: Text(l10n.classColumnGrade, style: header),
                ),
                Expanded(
                  flex: _flex[2],
                  child: Text(l10n.classColumnSubjects, style: header),
                ),
                Expanded(
                  flex: _flex[3],
                  child: Text(
                    l10n.classColumnStudents,
                    style: header,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        for (var row = 0; row < 3; row++)
          SizedBox(
            height: EduDensity.of(context).rowHeight,
            child: Row(
              children: [
                Expanded(
                  flex: _flex[0],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 120, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[1],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 24, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[2],
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBar(width: 160, height: 14),
                  ),
                ),
                Expanded(
                  flex: _flex[3],
                  child: const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SkeletonBar(width: 24, height: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/student_library/student_library_screen.dart';
import '../shell/student_shell.dart';
import '../shell/teacher_shell.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
/// Stages whose screen is not built yet show [AppOpeningScreen] until
/// their task replaces the placeholder.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => StudentShell(
          libraryBuilder: (_) => const StudentLibraryScreen(),
        ),
        UserRole.teacher => const TeacherShell(),
        UserRole.parent => const AppOpeningScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/widget/teacher_home/teacher_home_screen_test.dart`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/teacher_home_phone.png`
- `test/widget/goldens/teacher_home_tablet.png`

Run: `flutter test test/widget/teacher_home/teacher_home_screen_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] No accent fill anywhere (phase 1 teacher-home has no primary action); the rail pill is grey.
- [ ] "Tổng quan" in the app bar starts at the same left edge as the panel below it; the rail runs the full height beside the app bar.
- [ ] Table header labels are 12sp grey sentence case with no fill band; one 1px rule under the header and between rows; no zebra.
- [ ] Grade and student figures are monospace; student counts are right-aligned under a right-aligned "Học sinh" header; 8A shows a grey "-" for subjects and "0" students.
- [ ] The panel stops at 760dp, left-aligned; the rest of the canvas is plain grey ground.
- [ ] On the phone each class is a two-line row with "Khối 7 · Toán, ..." in grey on line 2.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/shell/teacher_shell.dart \
  edubox_flutter/lib/src/screens/teacher_home/teacher_home_screen.dart \
  edubox_flutter/test/widget/teacher_home/teacher_home_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/teacher_home_phone.png \
  edubox_flutter/test/widget/goldens/teacher_home_tablet.png
git commit -m "feat: teacher shell and teacher-home class ledger"
```


---

## Task 11: Screen `parent-home` and the parent shell

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none; visual review: yes (parent PNGs).

**Files:**
- Create: `edubox_flutter/lib/src/screens/parent_home/parent_home_screen.dart`
- Modify: `edubox_flutter/lib/src/app/stage_router.dart` (route the parent role to `ParentHomeScreen`)
- Test: `edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart`

**Interfaces:**
- Consumes: Task 8 (`AccountMenuButton`), Task 5 (`Loadable`, blocks, `OfflineStrip`, `EduLockup`), `ParentRepository.home()`, `ParentHomeData.hasLinkedChild`.
- Produces: `ParentHomeScreen`; keys `ParentHomeKeys.screen` (`screen.parentHome`), `panel`, `name`.

Brief: `docs/design/shapes/parent-home.md` (confirmed 2026-10-29: the "Học sinh" label and the linked child's name only, no forward-looking copy; parent signs out immediately).
"`users` doc with `linkedStudentUid`/`linkedStudentName`" maps to `ParentHomeData.linkedStudentName` from `ParentRepository.home()`.
Shell: no rail and no bottom bar; a 64dp app bar on `paper` with the lockup and a 48dp `more_vert` overflow (tooltip `parentMenuTooltip`) holding one item, `signOut`; the strip under the app bar.
Body: one centred column capped at 760dp, the record panel top-aligned 24dp below the app bar: the label `parentHomeStudentLabel` in muted 14/20 (weight 500, see the comment in the code), 8dp, then the name in Bitter 24/32 as the h1, one semantics node `parentHomeStudentSemantics(name)`.
No class line (the parent role cannot read classes), no accent, no app bar scope, no "coming soon".
No linked child is neutral (no glyph) with `retry`; offline without cache is neutral `cloud_off` with `retry`; a failed read is negative `error_outline` with `retry`; a cached name stays on screen even when a later read fails.
Sign-out is immediate; a failure shows a SnackBar `signOutFailed` with a `retry` action and keeps the screen.

States this task builds (each has a widget test with the accessibility guidelines):

| State | What shows | l10n keys | Test |
| --- | --- | --- | --- |
| Loading | The label and a 240x24 bar | `parentHomeStudentLabel` | `loading: label at once, a bar where the name goes` |
| Populated | Label and the name as the h1 | `parentHomeStudentLabel`, `parentHomeStudentSemantics` | `loaded: the label and the linked child name as the h1` |
| Empty: no linked child | Neutral sentence with retry | `parentHomeNoChild`, `retry` | `no linked child: neutral sentence with retry` |
| Offline with cache | The name and the strip | `networkOffline` | `offline with cache: the name and the strip` |
| Offline without cache | Neutral offline sentence and retry | `parentHomeOfflineNoData`, `retry` | `offline without cache: neutral offline sentence and retry` |
| Error with retry | Negative sentence; retry recovers | `parentHomeLoadError`, `retry` | `error: negative sentence; retry recovers` |
| Sign-out | Immediate; failure SnackBar | `parentMenuTooltip`, `signOut`, `signOutFailed` | `sign-out from the overflow is immediate`; `sign-out failure shows a snackbar with retry` |
| Text at 200% | Name wraps, no overflow | - | `200% text on a phone wraps the name, no overflow` |

- [ ] **Step 1: Write the failing tests**

`edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_result.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  testWidgets('loaded: the label and the linked child name as the h1', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    expect(find.text(vi.parentHomeStudentLabel), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    expect(
      find.bySemanticsLabel(vi.parentHomeStudentSemantics('Nguyễn Minh An')),
      findsOneWidget,
    );
    expect(find.byType(NavigationRail), findsNothing);
    semantics.dispose();
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('loading: label at once, a bar where the name goes', (
    tester,
  ) async {
    final app = await pumpEduApp(
      tester,
      signedInAs: FixtureKeys.parentBinh,
      settle: false,
    );
    app.fake.holdCalls();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(vi.parentHomeStudentLabel), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsNothing);
    await expectAccessibilityGuidelines(tester);
    app.fake.releaseCalls();
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  testWidgets('no linked child: neutral sentence with retry', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentNoChild);
    expect(find.text(vi.parentHomeNoChild), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline with cache: the name and the strip', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    app.network.goOffline();
    await tester.pumpAndSettle();
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('offline without cache: neutral offline sentence and retry', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.parentError = const OfflineNoCacheError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(find.text(vi.parentHomeOfflineNoData), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
  });

  testWidgets('error: negative sentence; retry recovers', (tester) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.parentError = const UnexpectedBackendError();
    await pumpEduApp(
      tester,
      fake: holder.fake,
      network: holder.network,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(find.text(vi.parentHomeLoadError), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await expectAccessibilityGuidelines(tester);
    holder.fake.clearFailures();
    await tester.tap(find.text(vi.retry));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  testWidgets('sign-out from the overflow is immediate', (tester) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    await tester.tap(find.byTooltip(vi.parentMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(vi.signOut));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('sign-out failure shows a snackbar with retry', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    app.fake.signOutError = const UnexpectedBackendError();
    await tester.tap(find.byTooltip(vi.parentMenuTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(vi.signOut));
    await tester.pumpAndSettle();
    expect(find.text(vi.signOutFailed), findsOneWidget);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
  });

  testWidgets('200% text on a phone wraps the name, no overflow', (
    tester,
  ) async {
    await pumpEduApp(
      tester,
      size: TestSizes.phone,
      textScale: 2,
      signedInAs: FixtureKeys.parentBinh,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, size) in [
    ('phone', TestSizes.phone),
    ('tablet', TestSizes.tablet),
  ]) {
    testWidgets('golden: parent-home on $name', (tester) async {
      await pumpEduApp(tester, size: size, signedInAs: FixtureKeys.parentBinh);
      await expectScreenGolden(tester, 'parent_home_$name');
    });
  }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/parent_home/parent_home_screen_test.dart`
Expected: FAIL with a compilation error naming a missing file under `lib/src/` (for example `Error when reading 'lib/src/screens/parent_home/parent_home_screen.dart'`).

- [ ] **Step 3: Write the implementation**

`edubox_flutter/lib/src/screens/parent_home/parent_home_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../app/loadable.dart';
import '../../contract/backend_result.dart';
import '../../contract/session.dart';
import '../../shell/account_menu.dart';
import '../../shell/block_states.dart';
import '../../shell/edu_mark.dart';
import '../../shell/offline_strip.dart';
import '../../theme/breakpoints.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/tokens.dart';

/// Stable keys for widget and E2E tests.
abstract final class ParentHomeKeys {
  static const screen = Key('screen.parentHome');
  static const panel = Key('parentHome.panel');
  static const name = Key('parentHome.name');
}

/// `parent-home` (docs/design/shapes/parent-home.md) with its minimal
/// shell: a 64dp app bar (lockup, overflow with "Đăng xuất"), the strip,
/// and one record panel: the "Học sinh" label above the linked child's
/// name. No rail, no accent, no forward-looking copy.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  Loadable<ParentHomeData>? _home;
  late AppScope _scope;
  bool _signingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (_home == null) {
      final home = Loadable<ParentHomeData>(
        _scope.services.backend.parent.home,
      )..addListener(_onHome);
      _home = home;
      _scope.connectivity.register(home.load);
      unawaited(home.load());
    }
  }

  void _onHome() {
    if (_home!.error is SessionExpiredError) {
      unawaited(_scope.session.expire());
    }
  }

  @override
  void dispose() {
    final home = _home!;
    _scope.connectivity.unregister(home.load);
    home
      ..removeListener(_onHome)
      ..dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final error = await _scope.session.signOut();
    if (!mounted || error == null) return;
    setState(() => _signingOut = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.signOutFailed),
        action: SnackBarAction(label: l10n.retry, onPressed: _signOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = _home!;
    final window = WindowClass.of(MediaQuery.sizeOf(context).width);
    return Theme(
      data: EduDensity.parent.apply(Theme.of(context)),
      child: Scaffold(
        key: ParentHomeKeys.screen,
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          titleSpacing: window.gutter,
          title: const EduLockup(),
          actions: [
            AccountMenuButton(
              tooltip: l10n.parentMenuTooltip,
              icon: const Icon(Icons.more_vert),
              lines: const [],
              busy: _signingOut,
              onSignOut: _signOut,
            ),
            const SizedBox(width: EduSpace.s8),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([_scope.connectivity, home]),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OfflineStrip(state: _scope.connectivity.strip),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      window.gutter,
                      EduSpace.s24,
                      window.gutter,
                      EduSpace.s32,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: EduSize.readingMaxWidth,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: _RecordPanel(home: home),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.home});

  final Loadable<ParentHomeData> home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = EduPalette.of(context);
    final value = home.value;
    final error = home.error;
    final retry = Padding(
      padding: const EdgeInsets.only(top: EduSpace.s8),
      child: RetryButton(onPressed: home.load, busy: home.isLoading),
    );

    final Widget body;
    if (value != null && value.hasLinkedChild) {
      // A cached name stays on screen even when a later read fails.
      final name = value.linkedStudentName!.trim();
      body = Semantics(
        key: ParentHomeKeys.name,
        header: true,
        container: true,
        label: l10n.parentHomeStudentSemantics(name),
        excludeSemantics: true,
        child: Text(name, style: text.headlineLarge),
      );
    } else if (home.isLoading || (value == null && error == null)) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SkeletonBar(width: 240, height: 24),
      );
    } else if (value != null) {
      body = BlockMessage(message: l10n.parentHomeNoChild, action: retry);
    } else if (error is OfflineNoCacheError) {
      body = BlockMessage(
        tone: BlockTone.offline,
        message: l10n.parentHomeOfflineNoData,
        action: retry,
      );
    } else {
      body = BlockMessage(
        tone: BlockTone.error,
        message: l10n.parentHomeLoadError,
        action: retry,
      );
    }

    final showLabel = !(value != null && value.hasLinkedChild);
    return Card(
      key: ParentHomeKeys.panel,
      child: Padding(
        padding: EdgeInsets.all(EduDensity.of(context).panelPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The label is merged into the name's semantics when a name
            // shows, so it is excluded there to avoid reading it twice.
            ExcludeSemantics(
              excluding: !showLabel,
              child: Semantics(
                container: true,
                child: Text(
                  l10n.parentHomeStudentLabel,
                  // 500, not 400: an 8-letter muted label at 400 leaves too
                  // few solid pixels for textContrastGuideline's sampling.
                  style: text.bodyMedium!.copyWith(
                    color: palette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: EduSpace.s8),
            body,
          ],
        ),
      ),
    );
  }
}
```

`edubox_flutter/lib/src/app/stage_router.dart` (replace the whole file):

```dart
import 'package:edubox_client/edubox_client.dart' show UserRole;
import 'package:flutter/material.dart';

import '../screens/account_not_set_up/account_not_set_up_screen.dart';
import '../screens/app_start/app_start_screens.dart';
import '../screens/parent_home/parent_home_screen.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/student_library/student_library_screen.dart';
import '../shell/student_shell.dart';
import '../shell/teacher_shell.dart';
import 'session_controller.dart';

/// Maps the session stage (and, at home, the role) to the one screen that
/// fills the window. Each stage change swaps the whole subtree.
class StageRouter extends StatelessWidget {
  const StageRouter({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return switch (session.stage) {
      AppStage.opening => const AppOpeningScreen(),
      AppStage.startFailed => AppStartFailedScreen(onRetry: session.start),
      AppStage.signedOut => const SignInScreen(),
      AppStage.notSetUp => const AccountNotSetUpScreen(),
      AppStage.home => switch (session.session!.role!) {
        UserRole.student => StudentShell(
          libraryBuilder: (_) => const StudentLibraryScreen(),
        ),
        UserRole.teacher => const TeacherShell(),
        UserRole.parent => const ParentHomeScreen(),
      },
    };
  }
}
```

- [ ] **Step 4: Run the tests and capture the screenshots**

Run: `flutter test --update-goldens test/widget/parent_home/parent_home_screen_test.dart`
Expected: `All tests passed!`; these PNGs now exist:

- `test/widget/goldens/parent_home_phone.png`
- `test/widget/goldens/parent_home_tablet.png`

Run: `flutter test test/widget/parent_home/parent_home_screen_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Look at every screenshot and fix**

Common look-and-fix checklist (check every PNG of this task; fix, regenerate, look again):

- [ ] No yellow-and-black overflow stripes, no clipped text, no clipped Vietnamese marks (look at the tops of "Ậ", "Ễ", "Ỗ" in headings).
- [ ] Exactly one h1, set in Bitter; no eyebrow or small label above it.
- [ ] The accent `#1F4C8F` (blue-black) appears in at most one dominant place, named below; the rail, app bar and nav show no blue (the active destination is a grey `#E6E9EF` pill).
- [ ] Panels are white `#FFFFFF` with a 1px `#DFE3EA` edge and 8dp corners on the `#F4F5F8` ground; no shadow on any resting surface; buttons and fields have 6dp corners.
- [ ] No gradient, glow, emoji, mascot, badge, illustration, padlock, or icon inside a tinted circle or square.
- [ ] Every block shares the same left edge (the gutter); a title lines up with the panel under it; there is more space above a heading than below it.
- [ ] Text is at least 12sp everywhere and at least 14sp for anything a student must read to act; secondary text is `#4E5666` grey, body text is `#191E29` ink.
- [ ] Loading shows flat grey bars at the real size of the values, with no spinner; errors sit inside their block with one sentence and "Thử lại"; empty blocks keep their frame and header.
- [ ] On the phone image the navigation is folded (bottom bar or app bar), nothing scrolls sideways, and every tap target looks at least 48dp.

Task-specific checks:

- [ ] No accent anywhere except the small mark; no rail, no tabs, no bottom bar.
- [ ] The panel is top-aligned 24dp under the app bar, not vertically centred; it hugs its content and never stretches down the screen.
- [ ] "Học sinh" is small grey text directly above the name; the name is Bitter 24 ink and wraps freely on the phone.
- [ ] The lockup in the app bar starts at the gutter; the overflow button is at the right edge.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/lib/src/screens/parent_home/parent_home_screen.dart \
  edubox_flutter/test/widget/parent_home/parent_home_screen_test.dart \
  edubox_flutter/lib/src/app/stage_router.dart \
  edubox_flutter/test/widget/goldens/parent_home_phone.png \
  edubox_flutter/test/widget/goldens/parent_home_tablet.png
git commit -m "feat: parent-home screen with its minimal shell"
```


---

## Task 12: Role routing, host restart tests (criteria 5 and 6), and the phase 1 E2E suite

**Routing:** executor opencode DeepSeek 4.1 Flash; contract paths: none (`integration_test/**` is frontend-owned per contract.md section 6); visual review: no. The E2E run itself needs the `edubox_tablet` AVD, the compose `e2e` profile and the backend-track `bin/seed` and storage work; the executor only compiles it here, and the orchestrator runs it at the phase gate.

**Files:**
- Create: `edubox_flutter/test/app/role_routing_test.dart`, `edubox_flutter/test/app/restart_test.dart`
- Create: `edubox_flutter/integration_test/support/e2e_harness.dart`, `edubox_flutter/integration_test/phase1_test.dart`, `edubox_flutter/integration_test/unreachable_backend_test.dart`

**Interfaces:**
- Consumes: everything above; `createProductionServices(config, network:, databaseFile:)`; the generated client's `e2e.run(token:, step:, accountKey:, role:)` (contract section 2.8); `FixtureEduBoxApi` from Task 4.
- Produces: `E2eHarness({BackendConfig? config})` with `setUp()`, `control(step, {accountKey, role})`, `pumpRoot(tester)` (the in-process restart), `signIn(tester, accountKey, {password})`, `backend`, `network`, `dispose()`; helpers `settle`, `waitFor`, `vi`, `e2eToken` (`--dart-define=EDUBOX_E2E_TOKEN`, default the dev-only compose value `dev-only-e2e-control-token`).

Why: exit criteria 1-7 and 9 are E2E on the AVD; criterion 4's unreachable half needs its own file with its own `BackendConfig` on a closed port.
The host `restart_test.dart` proves criteria 5 and 6 without the AVD: the production `CachedBackend` over an on-disk drift file, the app root re-created offline over the same file, and no server call while offline.
The E2E harness clears the auth module's secure storage and the drift file before every test, resets the server with `e2e.run(step: 'reset')`, and switches the `ManualNetworkController` seam directly (roadmap E2E harness ruling).

- [ ] **Step 1: Write the host routing and restart tests**

`edubox_flutter/test/app/role_routing_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('no stored session routes to sign-in', (tester) async {
    await pumpEduApp(tester);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  testWidgets('each role restores straight into its own home', (
    tester,
  ) async {
    await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    expect(find.byKey(const Key('screen.studentHome')), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.teacherLan);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.nullRole);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
    await pumpEduApp(tester, signedInAs: FixtureKeys.noProfile);
    expect(find.byKey(AccountNotSetUpKeys.screen), findsOneWidget);
  });

  testWidgets('sign-in routes every role to its home', (tester) async {
    for (final (key, screen) in [
      (FixtureKeys.studentAn, const Key('screen.studentHome')),
      (FixtureKeys.teacherLan, const Key('screen.teacherHome')),
      (FixtureKeys.parentBinh, ParentHomeKeys.screen),
      (FixtureKeys.nullRole, AccountNotSetUpKeys.screen),
    ]) {
      await pumpEduApp(tester);
      final account = FixtureSet.phase1().account(key);
      await tester.enterText(find.byKey(SignInKeys.email), account.email);
      await tester.enterText(find.byKey(SignInKeys.password), devPassword);
      await tester.tap(find.byKey(SignInKeys.submit));
      await tester.pumpAndSettle();
      expect(find.byKey(screen), findsOneWidget, reason: key);
    }
  });

  testWidgets('offline start restores the cached session to its home', (
    tester,
  ) async {
    final holder = ManualNetworkControllerHolder.create();
    holder.fake.signInAs(FixtureKeys.teacherLan);
    holder.network.goOffline();
    await pumpEduApp(tester, fake: holder.fake, network: holder.network);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    expect(find.text(vi.networkOffline), findsOneWidget);
    expect(find.text('7A'), findsOneWidget);
  });

  testWidgets('a stage change closes any open dialog', (tester) async {
    final app = await pumpEduApp(tester, signedInAs: FixtureKeys.studentAn);
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final context = tester.element(find.byType(AlertDialog));
    await AppScope.of(context).session.expire();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
    expect(app.fake.currentSession, isNull);
  });
}
```

`edubox_flutter/test/app/restart_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/fixture_api.dart';
import '../support/app_harness.dart';

/// Host versions of exit criteria 5 and 6: the production data layer over
/// an on-disk drift file; the app root is re-created offline over the same
/// file (the E2E harness's in-process restart).
void main() {
  late Directory dir;
  late File file;
  late FixtureEduBoxApi api;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('edubox_restart_');
    file = File('${dir.path}/edubox.sqlite');
    api = FixtureEduBoxApi();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<CachedBackend> pumpRoot(
    WidgetTester tester,
    ManualNetworkController network,
  ) async {
    final backend = CachedBackend(
      api: api,
      store: CachedDataStore(EduBoxDatabase(NativeDatabase(file))),
      network: network,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: EduBoxApp(
          key: UniqueKey(),
          services: AppServices(
            backend: backend,
            network: network,
            clock: fixedClock,
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    return backend;
  }

  Future<void> signIn(WidgetTester tester, String key) async {
    final account = FixtureSet.phase1().account(key);
    await tester.enterText(find.byKey(SignInKeys.email), account.email);
    await tester.enterText(find.byKey(SignInKeys.password), devPassword);
    await tester.tap(find.byKey(SignInKeys.submit));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  for (final (role, key, probe) in [
    ('student', FixtureKeys.studentAn, 'Tế bào và mô'),
    ('teacher', FixtureKeys.teacherLan, '7A'),
    ('parent', FixtureKeys.parentBinh, 'Nguyễn Minh An'),
  ]) {
    testWidgets('$role: offline re-create renders the cached home', (
      tester,
    ) async {
      setWindow(tester, TestSizes.tablet);
      final network = ManualNetworkController();
      final first = await pumpRoot(tester, network);
      await signIn(tester, key);
      expect(find.text(probe), findsOneWidget);
      network.goOffline();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(first.dispose);
      final callsBefore = api.calls;
      final second = await pumpRoot(tester, network);
      expect(find.text(probe), findsOneWidget);
      expect(find.text(vi.networkOffline), findsOneWidget);
      expect(api.calls, callsBefore, reason: 'no server call while offline');
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(second.dispose);
    });
  }

  testWidgets('cleared cache: offline re-create shows offline-no-data', (
    tester,
  ) async {
    setWindow(tester, TestSizes.tablet);
    final network = ManualNetworkController();
    final first = await pumpRoot(tester, network);
    await signIn(tester, FixtureKeys.teacherLan);
    // Clear only this role's home data, as the E2E criterion 6 test does.
    await tester.runAsync(() async {
      final db = first.store.db;
      await db.delete(db.cachedClasses).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('teacherClasses'))).go();
    });
    network.goOffline();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(first.dispose);
    final second = await pumpRoot(tester, network);
    expect(find.text(vi.teacherClassesOfflineNoData), findsOneWidget);
    expect(find.text(vi.teacherClassesEmpty), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(second.dispose);
  });
}
```

- [ ] **Step 2: Run them**

Run: `flutter test test/app`
Expected: `All tests passed!`.
These tests exercise code from earlier tasks, so they pass at once; if one fails, the bug is in the earlier task's code: fix the code, not the test, and name the fix in the commit message.

- [ ] **Step 3: Write the E2E harness and tests**

`edubox_flutter/integration_test/support/e2e_harness.dart`:

```dart
import 'dart:io';

import 'package:edubox_client/edubox_client.dart' show Client;
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/l10n/generated/app_localizations.dart';
import 'package:edubox_flutter/src/app/app_scope.dart';
import 'package:edubox_flutter/src/app/edubox_app.dart';
import 'package:edubox_flutter/src/app/production_services.dart';
import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/contract/network_controller.dart';
import 'package:edubox_flutter/src/data/cached_backend.dart';
import 'package:edubox_flutter/src/network/platform_sources.dart'
    show serverRootUrl;
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterSecureStorage;

/// Every E2E assertion looks copy up by key, never as literal text.
final AppLocalizations vi = lookupAppLocalizations(const Locale('vi'));

/// The e2e-control token. The compose e2e server's dev-only value is the
/// default; override with `--dart-define=EDUBOX_E2E_TOKEN=...`.
const e2eToken = String.fromEnvironment(
  'EDUBOX_E2E_TOKEN',
  defaultValue: 'dev-only-e2e-control-token',
);

/// Drives the real app on the AVD against the compose stack: the
/// production data layer over the generated client, an on-disk drift file,
/// and a directly switchable network seam (roadmap E2E harness ruling).
class E2eHarness {
  E2eHarness({BackendConfig? config})
    : config = config ?? BackendConfig.fromEnvironment(),
      network = ManualNetworkController();

  final BackendConfig config;
  final ManualNetworkController network;
  late final File databaseFile;
  AppServices? _services;

  /// The current app's data layer (for cache surgery in criterion 6).
  CachedBackend get backend => _services!.backend as CachedBackend;

  /// Starts every test signed out with an empty store: the auth module's
  /// secure storage and the drift file from an earlier test are removed.
  Future<void> setUp() async {
    await const FlutterSecureStorage().deleteAll();
    final dir = await getTemporaryDirectory();
    databaseFile = File('${dir.path}/edubox_e2e.sqlite');
    if (databaseFile.existsSync()) databaseFile.deleteSync();
  }

  /// Calls the token-guarded `e2e.run` control route (contract 2.8).
  Future<void> control(String step, {String? accountKey, String? role}) async {
    final client = Client('${serverRootUrl(config)}/');
    try {
      final result = await client.e2e.run(
        token: e2eToken,
        step: step,
        accountKey: accountKey,
        role: role,
      );
      expect(result, 'ok:$step');
    } finally {
      client.close();
    }
  }

  /// Pumps a fresh app root over the same drift file. Calling it again is
  /// the in-process restart: the old store is closed first.
  Future<void> pumpRoot(WidgetTester tester) async {
    final old = _services;
    if (old != null) {
      await tester.pumpWidget(const SizedBox());
      await old.backend.dispose();
    }
    final services = await createProductionServices(
      config,
      network: network,
      databaseFile: databaseFile,
    );
    _services = services;
    await tester.pumpWidget(EduBoxApp(key: UniqueKey(), services: services));
    await settle(tester);
  }

  /// Signs in through the sign-in screen with the dev password.
  Future<void> signIn(
    WidgetTester tester,
    String accountKey, {
    String password = devPassword,
  }) async {
    final account = FixtureSet.phase1().account(accountKey);
    await waitFor(tester, find.byKey(SignInKeys.email));
    await tester.enterText(find.byKey(SignInKeys.email), account.email);
    await tester.enterText(find.byKey(SignInKeys.password), password);
    await tester.tap(find.byKey(SignInKeys.submit));
    await settle(tester);
  }

  Future<void> dispose() async {
    await _services?.backend.dispose();
    network.dispose();
  }
}

/// Pumps until no frame is scheduled, tolerating real network latency.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 30),
  );
}

/// Pumps until [finder] matches or [timeout] passes.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets, reason: 'timed out waiting');
}
```

`edubox_flutter/integration_test/phase1_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/local/local_store.dart';
import 'package:edubox_flutter/src/screens/account_not_set_up/account_not_set_up_screen.dart';
import 'package:edubox_flutter/src/screens/parent_home/parent_home_screen.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:edubox_flutter/src/screens/student_home/student_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_harness.dart';

/// Clears one role's home data from the drift cache (criterion 6).
Future<void> clearRoleHome(EduBoxDatabase db, String role) async {
  switch (role) {
    case 'student':
      await db.delete(db.cachedLibraryItems).go();
      await db.delete(db.cachedLibraryClasses).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('studentLibrary'))).go();
    case 'teacher':
      await db.delete(db.cachedClasses).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('teacherClasses'))).go();
    case 'parent':
      await db.delete(db.cachedParentHomes).go();
      await (db.delete(
        db.cachedSnapshots,
      )..where((t) => t.kind.equals('parentHome'))).go();
  }
}

/// Phase 1 E2E (roadmap exit criteria 1-7 and 9) on the AVD against the
/// compose stack. Run with the contract's e2e command (contract.md 5).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late E2eHarness harness;
  final fixtures = FixtureSet.phase1();

  setUp(() async {
    harness = E2eHarness();
    await harness.setUp();
    await harness.control('reset');
  });

  tearDown(() => harness.dispose());

  testWidgets('1: student sees exactly the approved fixtures', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
    await settle(tester);
    final expected = fixtures.libraryOfStudent(FixtureKeys.studentAn);
    expect(find.text(vi.libraryTotal(expected.length)), findsOneWidget);
    for (final item in expected) {
      await tester.scrollUntilVisible(
        find.text(item.title),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(item.title), findsWidgets);
    }
    expect(find.text('Bản nháp: Hình học chương 2'), findsNothing);
    expect(find.text('Chuyển động cơ học'), findsNothing);
  });

  testWidgets('2: teacher lands on teacher-home, parent on parent-home', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    expect(find.byKey(const Key('screen.teacherHome')), findsOneWidget);
    for (final item in fixtures.classesOfTeacher(FixtureKeys.teacherLan)) {
      expect(find.text(item.name), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('shell.railSignOut')));
    await settle(tester);
    await harness.signIn(tester, FixtureKeys.parentBinh);
    expect(find.byKey(ParentHomeKeys.screen), findsOneWidget);
    expect(find.text('Nguyễn Minh An'), findsOneWidget);
  });

  for (final key in [FixtureKeys.noProfile, FixtureKeys.nullRole]) {
    testWidgets('3: $key lands on account-not-set-up', (tester) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      expect(find.text(vi.accountNotSetUp), findsOneWidget);
      expect(find.text(vi.accountCheckAgain), findsOneWidget);
      expect(find.text(vi.signOut), findsOneWidget);
      expect(find.byKey(const Key('screen.studentHome')), findsNothing);
    });
  }

  testWidgets('3: check again sees the admin role fix', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.nullRole);
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await settle(tester);
    expect(find.text(vi.accountStillNotSetUp), findsOneWidget);
    await harness.control('assign-role');
    await tester.tap(find.byKey(AccountNotSetUpKeys.checkAgain));
    await settle(tester);
    expect(find.byKey(const Key('screen.studentHome')), findsOneWidget);
  });

  testWidgets('4: wrong credentials show signInWrongCredentials', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(
      tester,
      FixtureKeys.studentHa,
      password: 'not-the-password',
    );
    expect(find.text(vi.signInWrongCredentials), findsOneWidget);
    expect(find.byKey(SignInKeys.screen), findsOneWidget);
  });

  for (final (key, probe) in [
    (FixtureKeys.studentAn, 'Tế bào và mô'),
    (FixtureKeys.teacherLan, '7A'),
    (FixtureKeys.parentBinh, 'Nguyễn Minh An'),
  ]) {
    testWidgets('5: $key home renders offline from the store after restart', (
      tester,
    ) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      expect(find.text(probe), findsOneWidget);
      harness.network.goOffline();
      await harness.pumpRoot(tester);
      expect(find.text(probe), findsOneWidget);
      expect(find.text(vi.networkOffline), findsOneWidget);
      if (key == FixtureKeys.studentAn) {
        await tester.tap(find.byKey(StudentHomeKeys.openLibrary));
        await settle(tester);
        expect(find.text(vi.libraryTotal(6)), findsOneWidget);
      }
      harness.network.goOnline();
    });
  }

  for (final (key, role, message) in [
    (FixtureKeys.studentAn, 'student', vi.studentHomeLibraryOfflineNoCache),
    (FixtureKeys.teacherLan, 'teacher', vi.teacherClassesOfflineNoData),
    (FixtureKeys.parentBinh, 'parent', vi.parentHomeOfflineNoData),
  ]) {
    testWidgets('6: $role home without cache shows its offline-no-data', (
      tester,
    ) async {
      await harness.pumpRoot(tester);
      await harness.signIn(tester, key);
      await clearRoleHome(harness.backend.store.db, role);
      harness.network.goOffline();
      await harness.pumpRoot(tester);
      expect(find.text(message), findsOneWidget);
      if (role == 'student') {
        await tester.tap(find.text(vi.navLibrary).last);
        await settle(tester);
        expect(find.text(vi.libraryOfflineNoData), findsOneWidget);
      }
      harness.network.goOnline();
    });
  }

  testWidgets('7: reconnect shows the strip, then the new data', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    harness.network.goOffline();
    await settle(tester);
    expect(find.text(vi.networkOffline), findsOneWidget);
    await harness.control('reconnect-library');
    harness.network.goOnline();
    await tester.pump();
    expect(find.text(vi.networkReconnecting), findsOneWidget);
    await waitFor(tester, find.text('Ôn tập chương 1'));
    await settle(tester);
    expect(find.text(vi.networkReconnecting), findsNothing);
    expect(find.text(vi.networkOffline), findsNothing);
  });

  testWidgets('7: reconnect shows the teacher the new class', (tester) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    harness.network.goOffline();
    await settle(tester);
    await harness.control('reconnect-classes');
    harness.network.goOnline();
    await waitFor(tester, find.text('8B'));
    await settle(tester);
    expect(find.text(vi.networkReconnecting), findsNothing);
  });

  testWidgets('9: pingStream reaches the app with the caller role', (
    tester,
  ) async {
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.teacherLan);
    final messages = await harness.backend.diagnostics.pingStream().toList();
    expect(messages.length, greaterThanOrEqualTo(2));
    expect(messages.every((m) => m.role.name == 'teacher'), isTrue);
  });
}
```

`edubox_flutter/integration_test/unreachable_backend_test.dart`:

```dart
import 'package:edubox_fixtures/edubox_fixtures.dart';
import 'package:edubox_flutter/src/contract/backend_config.dart';
import 'package:edubox_flutter/src/screens/sign_in/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_harness.dart';

/// Exit criterion 4 (unreachable half): this file builds its own backend
/// config pointing at a closed port on the host alias, overriding the
/// EDUBOX_SERVER_URL default, and expects backendUnreachable with retry.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a closed port shows backendUnreachable and retry', (
    tester,
  ) async {
    final harness = E2eHarness(
      config: const BackendConfig(serverUrl: 'http://10.0.2.2:8099'),
    );
    await harness.setUp();
    await harness.pumpRoot(tester);
    await harness.signIn(tester, FixtureKeys.studentAn);
    await waitFor(tester, find.text(vi.backendUnreachable));
    expect(find.text(vi.backendUnreachable), findsOneWidget);
    expect(find.byKey(SignInKeys.retry), findsOneWidget);
    expect(find.text(vi.retry), findsOneWidget);
    await harness.dispose();
  });
}
```

- [ ] **Step 4: Compile-check the E2E suite on the host**

Run: `flutter analyze`
Expected: `No issues found!` (the analyzer covers `integration_test/`).
Do not run `flutter test integration_test` here: it needs the AVD and the compose stack.

- [ ] **Step 5: Record the E2E command for the gate**

The orchestrator runs it at the phase gate, from the repo root, once the backend track has landed `bin/seed` and the storage spike:

```bash
tool/bootstrap.sh
docker compose --profile e2e up -d --build --wait
docker compose run --rm minio-init
(cd edubox_flutter && flutter test integration_test \
  -d "$EDUBOX_E2E_DEVICE" \
  --dart-define=EDUBOX_SERVER_URL=http://10.0.2.2:8080/)
```

Expected at the gate: every test in `phase1_test.dart` and `unreachable_backend_test.dart` passes.
The trailing slash in the define is harmless: `serverRootUrl` (Task 3) strips it before the client, the probe and the harness build their URLs.

- [ ] **Step 6: Run the four gates**

```bash
flutter analyze
# Expected: No issues found!
dart format --output=none --set-exit-if-changed .
# Expected: Formatted N files (0 changed)
flutter test
# Expected: last line "All tests passed!"
flutter gen-l10n && git -C .. status --porcelain edubox_flutter/lib/l10n
# Expected: no output
```

- [ ] **Step 7: Commit**

```bash
git add edubox_flutter/test/app/role_routing_test.dart \
  edubox_flutter/test/app/restart_test.dart \
  edubox_flutter/integration_test/support/e2e_harness.dart \
  edubox_flutter/integration_test/phase1_test.dart \
  edubox_flutter/integration_test/unreachable_backend_test.dart
git commit -m "test: role routing, restart and phase 1 e2e suite"
```


---

## Self-review (done by the plan author)

- Spec and roadmap coverage: every phase 1 frontend capability (theme tokens, bundled fonts, session persistence, role routing from `profile.me`, the drift-backed data layer, the network seam's production source, l10n scaffolding use, the six screens and the shell strip) has a task; criteria 10-14 are backend-track server tests and are not mapped here.
- Every task was replayed in order on a scratch copy of the repo at `phase-1-contract-v1`: after each task `flutter analyze` reported no issues, `dart format --set-exit-if-changed` changed nothing, and `flutter test` passed (57 tests after Task 1, 209 after Task 12).
- Package APIs were checked against `~/.pub-cache` (Serverpod 4.0.4 client, `FlutterAuthSessionManager`, `serverpod_auth_idp_client` exceptions, `connectivity_plus` 7.3.2, `http` 1.6.0 `MockClient`) and the Flutter 3.47.8 SDK (`SemanticsService.sendAnnouncement`, `NavigationRail.trailingAtBottom`, `InputDecorationThemeData`, `AppBarThemeData`, accessibility guidelines).
- Decisions the briefs left open, made here and visible in code comments:
  - `networkOfflineStale` replaces `networkOffline` on teacher-home and student-library only when the shown snapshot is older than the last profile refresh (`sessionRefreshedAt`), the literal reading of contract section 3.8.
  - The shared `ContentRow` cover slot follows the student-library brief (white, 1px rule, 24dp glyph), because both briefs require one shared row and the library brief is the more specific.
  - An unexpected check-again failure on account-not-set-up shows `studentHomeProfileError`, the only role-neutral "could not load the account" key.
  - The parent label uses weight 500 instead of 400, and rail identity lines are one merged node, because `textContrastGuideline` samples too few solid pixels from short 400-weight muted labels.
  - Sign-in retry after unreachable first tries `refreshProfile` (role read only) and falls back to a fresh sign-in when no session is stored.
