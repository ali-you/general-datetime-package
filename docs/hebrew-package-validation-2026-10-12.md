# Hebrew package validation — 2026-10-12

Release metadata follow-up: the manifests are now aligned to chronology wrapper
4.0.0, formatter wrapper 3.0.0 and both cores 2.0.0. The version discrepancy
recorded below describes the state during the original validation, before
that update. See [release preparation](release-preparation.md).

The local Hebrew implementations pass the checks below across both Dart cores,
both Flutter wrappers, and the runnable examples/demo. No production defect was
found. Validation exposed a JavaScript test compilation problem, which was fixed,
and added Hebrew coverage to the existing timezone parser tests.

## Validated source and environment

- Chronology: `general_date`, based on commit
  `31cdbdb3792142d6cf6a09dccc3d552af64641e2`, plus the validation changes below.
- Formatter: the local Hebrew worktree based on commit
  `617fdc3`; its existing uncommitted implementation was included and preserved.
- Windows; Flutter **3.47.6**, Dart **3.13.5**, Node **22.16.0**,
  Chrome **154.0.8037.98**. Native checks used the host Iran timezone.
- Local dependency overrides resolve to the new cores. The actual
  `.dart_tool/package_config.json` files were checked in all **seven** workspaces:
  chronology root/core/example/demo and formatter root/core/example.

These results describe the local source pair, including uncommitted files;
they do not establish availability in published packages.

## Results

| Check | Result |
| --- | --- |
| Chronology Dart core, complete suite | **30 passed** |
| Formatter Dart core, complete suite | **70 passed** |
| Chronology Flutter wrapper, complete suite | **328 passed** |
| Formatter Flutter wrapper, complete suite | **509 passed** |
| Calendar application demo | **11 passed** |
| Formatter Flutter example | **6 passed** |
| Full repository analysis, both repositories | **No issues** |
| CI formatting targets | **63 chronology + 57 formatter files; unchanged** |
| Chronology Node: calendar date/system/Hebrew suites | **25 passed** |
| Formatter Node: integration/precision/Hebrew/year-window/era suites | **43 passed** |
| Formatter Node: Lord Howe, Monrovia, Tehran | **59 passed in each timezone** |
| Chronology Chrome, JavaScript and WebAssembly | **9 passed for each compiler** |
| Formatter Chrome, JavaScript and WebAssembly | **10 passed for each compiler** |
| Generated Persian, Hijri and Hebrew CLDR data | **All pinned data verified** |
| Persian Afrikaans symbol generator | **Verified** |
| Both Dart CLI examples, compile and execute | **Passed** |
| Calendar demo, Android ARM64 debug APK | **Built successfully** |
| Formatter example, Android ARM64 debug APK | **Built successfully** |

There are **954 passing native test cases** across the complete suites. Browser
and Node runs intentionally select portable and Hebrew integration suites.
The chronology picker example has no separate test suite; its sources were
included in full repository analysis.

Hebrew chronology tests check all **9,999 supported year structures** and every
month boundary, including all six possible year lengths. They also exercise
stable month identity, both Adars, missing-month policies, bounds, serialization,
civil arithmetic, conversion, weekday and microsecond preservation.

Formatter and Material tests cover common/leap-year month names, strict and loose
parsing, year-dependent month validation, ordinal fields, eras, two-digit years,
native digits, six fractional digits, localized pickers, input and ranges.
Hebrew quarter fields continue to fail explicitly, as designed.

The three timezone runs set the real Node `TZ` and assert it in the fixtures.
They exercise Hebrew alongside Persian and Hijri through daylight-saving gaps,
overlaps, historical second-resolution offsets and civil-date parsing. CLDR
verification reads **110 pinned source locales per calendar**, supplying the
existing **120 supported locale identifiers** through aliases.

## Independent Hebrew comparison

A separate oracle was generated using **.NET 10.0.11**
`System.Globalization.HebrewCalendar`. Every day in complete Hebrew years
**5344–5999** was compared against this implementation:

- **656 years**, including each year length and common/leap month layout.
- **8,114 months**, including lengths and the absent Adar I slot in common years.
- **239,612 days**, checking Gregorian → Hebrew and Hebrew → Gregorian.

All comparisons passed both under the Dart VM and in a compiled native executable.
This independently checks a substantial modern interval; it is not an independent
oracle for the entire AM 1–9999 range. Separate JavaScript probes also preserved
microseconds and instant equality at Gregorian years 1600, 2024, 3000 and 6000.

## Validation changes

1. Replaced JavaScript-incompatible int64 literals in two chronology core test
   files with runtime parsing. The tests retain VM int64 coverage and explicitly
   exercise JavaScript's largest exactly representable integer.
2. Added the portable chronology core Node suites to its CI workflow.
3. Added Hebrew to the formatter core's existing timezone parser cases,
   increasing the complete core suite from 63 to 70 tests.

Browser execution encountered two Flutter SDK path problems on Windows: CanvasKit
requests returned 404, and the generated test dispatcher lost a separator in a
nested test path. Temporary CanvasKit junctions and a root test entry point let the
original tests execute. Those temporary files were removed afterward; the SDK was
not modified. A repeat on this Windows SDK may require the same workaround.

Tool-generated changes to example lockfiles and analysis configuration were
restored to their pre-validation contents. Local development overrides remain
available for testing the source pair.

## Practical limits and release follow-up

- The minimum supported Dart **3.4.0** / Flutter **3.32.0** matrix was not run
  locally; those checks remain configured in CI.
- Android verification compiled debug APKs; it did not install or execute them
  on a phone. iOS was not tested on this Windows host. Release-mode mobile builds
  and Windows desktop application builds were not checked.
- The formatter example build emitted existing Gradle/AGP/Kotlin deprecation
  warnings; the build completed successfully.
- Hosted dependency validation was not performed. The new core APIs were tested
  through local overrides. Release versions and hosted constraints still need
  reconciliation before publishing; the chronology wrapper manifest says 3.0.0
  while its release documentation describes 4.0.0.

## Commands and retained evidence

The usual checks, after resolving the local source pair, are:

```sh
# Each pure Dart core
dart pub get
dart analyze
dart test
dart compile exe example/cli.dart -o .dart_tool/calendar_cli

# Each Flutter wrapper
flutter pub get
flutter analyze --no-pub
flutter test --no-pub

# Chronology core portability
dart test --platform node test/calendar_date_test.dart test/calendar_system_test.dart test/hebrew_calendar_test.dart

# Formatter core; repeat with matching TZ and define for each timezone
dart test --platform node --dart2js-args=-DCALENDAR_TEST_TZ=Asia/Tehran test/dst_parsing_test.dart test/two_digit_year_window_test.dart test/era_parsing_test.dart test/hebrew_format_test.dart

# Formatter browser; repeat with --wasm
flutter test --no-pub --platform chrome test/platform_formatter_smoke_test.dart test/hebrew_material_localizations_test.dart

# Formatter locale generation
python tool/generate_calendar_data.py --check
python tool/generate_persian_af_symbols.py --check

# Demo and formatter example, from each application directory
flutter build apk --debug --no-pub --target-platform android-arm64
```

The command logs and JSON records, dependency path audit, independent oracle
input and generation script are retained locally under
`general_date/.dart_tool/validation/2026-10-12/` (ignored by Git). The comparison
program and compiled executable are in the chronology core's `.dart_tool/`.
Each completed command record contains its working directory, arguments,
timezone, exit status and duration. Earlier failed/aborted browser attempts and
the initial Node compilation failure are retained alongside successful retries.
