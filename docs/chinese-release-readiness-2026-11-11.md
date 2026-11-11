# Chinese calendar completion — 2026-11-11

Chinese chronology, formatting, parsing, Material adapters and generic calendar
integration are implemented in the five local packages. The new formatter
releases are **general_date_format_core 3.1.0** and **general_date_format 4.1.0**.
Chronology core 3.0.0 / wrapper 5.0.0 and general_calendar 1.1.0 are already
published. No publication, commits, tags or remote CI runs were created here.

## Completed changes

- Restore and review the Chinese formatter implementation and parser fixes from
  repository commit `da1013d1aceb4ae82ffe8c6c50fbe2885551e2c7`, preserving the
  current chronology dependency contract and coexistence tests.
- Add checksum-locked CLDR 48 names in all 120 bundled locale identifiers,
  related-year formatting, ordinal numeric months, year-aware traditional/leap
  name parsing, native digits and exact microseconds. Era and quarter patterns
  explicitly reject Chinese dates; this API does not implement cyclic years.
- Export translated Chinese Material adapters through both public Flutter
  libraries, and demonstrate Chinese formatting and picker selection.
- Verify selection through general_calendar in Chinese and Persian, including
  leap-month identity, and add Chinese to real-timezone formatter tests.
- Repair the calendar application's Chinese selection crash by supplying the
  completed formatter, requiring its correct minimum version and testing both
  presentation languages. Mount demo widgets through the test binding.
- Fix the Dart 3.4 negative-epoch test to compare millisecond constructors with
  the native constructor, rather than assuming newer native getter rounding.
- Restrict the formatter dependency-graph filesystem test to VM, restore full
  Node CI, and add Chinese browser CI. Pre-publication chronology CI uses the
  remotely available reviewed formatter commit above for its demo.
- Align guides and release versions. Keep maintainer docs and large reference
  reports on GitHub, outside published archives; README guide URLs remain usable.

## Executed verification

Windows, Flutter 3.47.6 / Dart 3.13.5, Node 22.16.0 / ICU 77.1:

| Package | Native tests | Analysis |
| --- | ---: | --- |
| general_datetime_core | 57 passed | Passed |
| general_datetime | 352 passed | Passed |
| general_date_format_core | 99 passed | Passed |
| general_date_format | 519 passed | Passed |
| general_calendar | 152 passed | Passed |

The formatter core also passes **98 Node tests**; chronology core passes its
**51 Node tests**. Exact Dart **3.4.0** isolated packages pass analysis and all
**57 chronology / 99 formatter tests**. The earlier Flutter **3.32.2** completion run passed formatter
analysis and **518 tests**; this is a near-minimum check, not an assertion that
Flutter 3.32.0 itself was rerun locally. CI retains that exact minimum.

The calendar application passes **12 tests**, including the formerly crashing
Chinese selection in English and Persian. The formatter example passes
**7 tests**, including Chinese picker confirmation in Persian.
The general_calendar playground example passes **16 tests**. All five package
suites total **1,179 native cases**, with **35 additional example/demo cases**.

Chrome JavaScript and WebAssembly each pass **10 Chinese localization and
five-package calendar integration tests**. The installed Flutter SDK's Windows
test server returned 404 for its CanvasKit assets because it compared a Windows
path with a forward-slash prefix. For these local browser runs, existing SDK
renderer files were served from a temporary checkout's test directory. Neither
the SDK nor package runtime sources were modified for that workaround.

Each of Lord Howe, Monrovia and Tehran passes **29 formatter timezone cases** in
an actual Node process, including Chinese strict/loose DST normalization.
Chronology's five-zone validator also passes UTC, New York, Tehran, Shanghai and
Apia. Source-pair tooling passes five regression tests.

The pinned Chinese CLDR generator reproduces its output from **110 source
locales**, including checksum verification. The chronology table generator
reproduces **199 lunar years**; the installed .NET API verifies **2,461 month
fixtures**, and the exhaustive native test compares **72,674 civil days** in
both directions. Three validator failure-path tests pass. HKO and ICU comparison
baselines remain unchanged: **30 HKO differences / 417 ICU differences**.

All five publish dry runs succeed with **zero warnings** in clean temporary
snapshots outside Git ignore rules. The formatter wrapper has one expected
hint for its staged formatter-core path override, because core 3.1.0 is not yet
hosted. Core 3.1.0 is tested and archive-validated against hosted chronology
3.0.0 without chronology overrides. Attribution notices remain in the archives.

## Independent implementation revalidation

A follow-up adversarial review found and fixed one additional parser defect:
`yMMMMMdd` formatted a date such as `20256b12`, but parsing consumed only one
year digit. Chinese related years are always 1901-2099, so `y` and `yyy` must
retain the full four-digit year before digit-leading named months; `yy` retains
its rolling two-digit contract. The new regression failed before the change
and passes strict/loose parsing in every bundled locale, six month contexts and
four full-year widths. The exact minimum Dart 3.4 suite passes all 99 tests.

The added Material test enumerates every supported locale in the bundled set,
both digit preferences and the first/last supported dates, in addition to a
modern leap month. Both Chrome backends pass the expanded ten-test selection.

The reproducible formatter-core tool `tool/validate_chinese_oracle.dart` checks
all **72,674 civil days** against the **2,461 independent .NET month fixtures**,
with literal CLDR English names. Numeric and named formatting match independent
expected fields; **218,022 strict/loose parses** resolve to independently expected
Gregorian instants with odd microseconds. This extends chronology validation
through the complete formatter chain instead of only round-tripping its output.

All five analyses and package suites were rerun after the parser correction.
No additional runtime defects were found in the reviewed scope. The 35 example
checks above are retained from the completion run; their source is unchanged.
The hosted-core prerequisite, remote CI and device limits below still apply.

## Release sequence and remaining external checks

1. Commit/review the formatter changes and publish formatter core 3.1.0.
2. Resolve formatter wrapper 4.1.0 without the formatter-core override; rerun
   analysis, tests and the dry run against hosted core 3.1.0, then publish it.
3. Advance the chronology demo's immutable formatter source pin to the reviewed
   release commit when available, or switch the demo to hosted core 3.1.0.
4. Run remote CI for the committed revisions. New iOS and physical-device runs
   were not performed locally; the old failed CI run is not evidence for the
   corrected uncommitted source.

The calendar remains bounded to lunar years **1901-2099**, following .NET's
civil table. It is not an astronomical calculation, a guarantee of HKO/ICU
equivalence, or a geographical timezone resolver. Existing user edits to the
documentation index and the cross-language expansion draft were preserved.

## Reproduce

Resolve the local pair using the formatter repository's
`tool/resolve_calendar_pair.py`; resolve each core and example separately.
In each core run `dart analyze`, `dart test`, and `dart test --platform node`.
In each Flutter package run `flutter analyze` and `flutter test`.

From the formatter root:

```console
python tool/generate_calendar_data.py --calendar chinese --check
python tool/test_resolve_calendar_pair.py
flutter test --platform chrome test/chinese_material_localizations_test.dart test/chinese_calendar_integration_test.dart
flutter test --platform chrome --wasm test/chinese_material_localizations_test.dart test/chinese_calendar_integration_test.dart
```

From the chronology root, reproduce reference and timezone checks with the
commands in [the Chinese guide](chinese-calendar.md) and the historical audit.
Run `pub publish --dry-run` from each independent package root in a clean
checkout, preserving licenses and omitting local overrides as hosted versions
become available.
