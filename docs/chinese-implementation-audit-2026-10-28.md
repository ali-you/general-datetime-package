# Chinese implementation audit — 2026-10-28

Scope: Chinese chronology, constructors, period arithmetic, storage, formatting,
Material delegates/localizations, generic calendar/time widgets, reference-data
generation, and regression behavior of the existing calendars in the three local
working trees. This report describes local execution, not a hosted CI run.

## Bugs reproduced and fixed

| Problem | Reproducer | Corrected behavior |
| --- | --- | --- |
| Digit-ending Chinese month names rejected adjacent numeric fields | English `yyyy MMMdd` formats month 1/day 12 as `2025 Mo112`, which failed to parse | Reserve the following fixed-width numeric run when matching a month name. Strict and loose parsing distinguish `Mo1` + `12` from `Mo11` + `02`, including native digits and adjacent time fields. |
| English picker accepted non-decimal date syntax | `0x1/7/2025`, signed fields, and oversized padded components | Validate the complete decimal `d/m/yyyy` grammar before strict calendar-field validation. Spaces around components and one/two-digit days/months remain supported. |
| Weekday offset disagreed with a clamped carried month | `getMonth(2024, 13)` resolved to month 12, but `firstDayOffset(2024, 13, ...)` used New Year 2025 | Resolve the month through the delegate before calculating its weekday offset, matching the month-length/year-picker policy. |

Each fix has a regression test that failed before the production change.
Additional test-harness corrections distinguish VM filesystem checks from
portable tests and calculate large cancelling clock expectations with BigInt;
native JavaScript Duration summation can itself round such inputs.

## Expanded checks

- Every one of the **72,674 supported civil days** agrees with the installed
  .NET oracle in both directions, including weekdays, Julian days, day-of-year,
  and the internal integer day coordinate.
- Every **2,461 month identity** and each of the **199 year structures** is
  checked against independently exported .NET API fixtures. Tests verify
  traditional/ordinal month mapping, leap identity, year lengths, and New Year.
- Month movement checks both directions, year crossings, long jumps, endpoints,
  and clamp/reject/overflow behavior. Year movement preserves traditional month
  identity across different leap-month positions and exercises both missing-month
  policies, using fixture anchors rather than a Dart round-trip as the expectation.
- Strict fields, huge offsets, exact cancellation, clock carries/borrows, negative
  epochs, minimum/maximum microseconds, offset parsing, copies, comparisons, hashes,
  cross-calendar conversion, and malformed JSON have adversarial coverage.
- All supported years round-trip named months in English and both Chinese script
  variants. All bundled locales are checked with both digit preferences, failed
  formatter reuse, redundant/conflicting tokens, month names before the year,
  two-digit years, adjacent fields, and fractional precision.
- Picker tests cover runtime type guards, month-13 year switching, selecting a
  range into a leap month, and keyboard boundaries at both endpoints for all
  seven week starts. Generic widgets cover two-month booking ranges in LTR/RTL,
  disabled interior dates, keyboard semantics, and Chinese combined date/time input.
- Isolated Node processes verify actual timezone offsets before testing **UTC,
  America/New_York, Asia/Tehran, Asia/Shanghai, and Pacific/Apia**. These checks
  cover DST gaps, repeated hours, 23/25-hour civil days, Apia's skipped day,
  UTC/local precision, and endpoint wall-date range checks without changing OS settings.
- Validator tests prove that missing offline source, a tampered source hash, and
  a changed comparison baseline fail without overwriting generated data or baselines.

## Executed results

Environment: Windows, Dart **3.13.5**, Flutter **3.47.6**, Node **22.16.0** / ICU
**77.1**, with .NET **10.0.11** supplying the independent month fixtures.

| Check | Result |
| --- | --- |
| All three Flutter package analyses | Passed |
| Chronology core analysis | Passed |
| Formatter core analysis | Passed |
| Chronology core, VM | 57 passed |
| Chronology core, Node JavaScript | 51 passed |
| Critical chronology cases compiled to a native executable | 8 passed |
| Formatter core, VM | 86 passed |
| Formatter core, Node JavaScript | 85 passed |
| Chronology Flutter wrapper, randomized order | 352 passed |
| Formatter Flutter wrapper, randomized order | 515 passed |
| Generic calendar widgets, randomized order | 94 passed |
| Formatter example | 7 passed |
| Calendar playground example | 16 passed |
| Calendar application demo | 11 passed |
| Validator failure-path tests | 3 passed |
| Real process timezone checks | All 5 passed |
| Pinned .NET table generation / installed .NET fixture check | Passed |
| CLDR Chinese symbol regeneration and source hashes | Passed |
| HKO / ICU comparison baseline checks | Passed, unchanged |

The randomized Flutter runs used seed `20261028`. Line coverage from the full
chronology VM suite reports **260/260** Chinese DateTime adapter lines and
**96/97** calculation-engine lines. The remaining line is the defensive
`StateError` after exhausting a valid table's month list. These are line-coverage
measurements, not a claim of complete branch coverage or proof of correctness.

## Reproduce

From `general_date`:

```powershell
./tool/export_chinese_oracle.ps1 -Check
python tool/generate_chinese_calendar.py --offline --check
python tool/validate_chinese_hko.py --offline --check
node tool/validate_chinese_oracle.cjs --check
python tool/test_chinese_validators.py
python tool/validate_chinese_timezones.py --dart dart
flutter analyze
flutter test --test-randomize-ordering-seed=20261028
```

The offline generator/reference checks require the ignored downloaded source
caches. Omit `--offline` to populate them; source hashes are still verified.
The .NET fixture check requires PowerShell and an installed .NET calendar API.
In each pure Dart core directory run `dart analyze`, `dart test`, and
`dart test --platform node`. The chronology critical file also supports
`dart test --compiler exe test/chinese_critical_test.dart`.
From `general_date_format`, regenerate-check symbols with
`python tool/generate_calendar_data.py --calendar chinese --check`.
Run the Flutter suites from both companion package roots and their example
directories against the local dependency overrides used for this audit.

## Remaining limits and release gate

- The calendar remains bounded to lunar years **1901–2099** and follows the
  pinned .NET chronology. Its documented **30 HKO** and **417 ICU** differing
  days remain unchanged; no claim of observational or universal Chinese-calendar
  equivalence is made.
- JavaScript treats integer-valued doubles as integers at runtime. Numeric
  validity is checked there, while VM-only tests additionally verify rejection
  of double-typed integral fields. Lexical JSON spellings such as `1` versus
  `1.0` cannot be distinguished after JavaScript decoding.
- Hosted CI, the minimum Dart 3.4 / Flutter 3.32 SDKs, device integration, and a
  browser UI run were not executed in this local audit. JavaScript checks ran in
  Node; Flutter interaction tests ran in the widget test environment.
- CI now retains the full portable Node core suites and the new timezone and
  validator checks. **Before remote formatter CI can pass**, advance
  `general_date_format/.github/calendar_pair.json` from peer revision
  `2f3d8e0e0e29cffaf0c68ba2018d878f0e78cddf` to the reviewed, available chronology
  commit containing Chinese support. The current pinned commit was inspected
  and lacks `chinese_date_time.dart`. A local working tree cannot supply a
  remotely fetchable immutable commit pin; this audit does not commit or publish it.
