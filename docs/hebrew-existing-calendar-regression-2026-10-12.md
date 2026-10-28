# Hebrew support: impact on Persian and Hijri — 2026-10-12

No functional regression was found in Persian or Umm al-Qura Hijri behavior.
Before/after comparisons produced identical results in all **850,228 records**.
The observable integration effects are a larger compiled formatter sample and
the additional public `CalendarId.hebrew` enum case.

## Source review

The chronology comparison uses the pre-Hebrew commit
`57abcf2d0a04f1cdae250495c56e607f6ba170bf` and the current worktree based on
`31cdbdb3792142d6cf6a09dccc3d552af64641e2`. The formatter comparison uses its
pre-Hebrew commit `617fdc390e50610c417d9f788133ac44a7453c2a` and the current
uncommitted Hebrew implementation. Both versions use the same Dart SDK and
third-party dependencies, with package configuration pointing to the respective
source snapshots.

Persian and Hijri calculation files, date-time classes, chronology picker
delegates and default localizations are unchanged. Their formatter month data,
neutral locale tables, locale policy and translated Material delegate files are
also unchanged.

The shared changes add explicit Hebrew branches in calendar dispatch,
serialization, helpers and civil arithmetic. Existing calendars continue to use
their original 12-month arithmetic. Formatter month-name access is routed through
a helper; Persian and Hijri still select the same symbol lists. Leap-month
restrictions, month 13 validation and quarter rejection are guarded by the Hebrew
calendar type. The two-digit-year candidate construction is now year-aware for
Hebrew; existing-calendar window results were compared separately.

## Before/after comparison

| Area | Records | Result |
| --- | ---: | --- |
| Persian month boundaries, years -61–3177 | 77,736 | Identical |
| Persian civil arithmetic | 320,661 | Identical |
| Hijri month boundaries, years 1300–1600 | 7,224 | Identical |
| Hijri civil arithmetic | 29,799 | Identical |
| Formatting across all 120 locale identifiers | 103,680 | Identical |
| Strict, ordinary and loose parsing across those locales | 311,040 | Identical |
| Invalid input and overflow normalization | 40 | Identical |
| Two-digit-year windows | 48 | Identical |

Each category compares record counts and SHA-256 digests of serialized outputs,
including exception types and messages. The boundary checks cover the first and
last day of every supported month, UTC conversion, precision, weekdays, bounds,
year/month lengths, published-data flags, helpers and date/instant serialization.

Arithmetic checks use month ends in months 1, 6 and 12 of every supported year,
multiple positive and negative month/year offsets, all three overflow policies
and neighboring-day operations. Locale checks use all twelve months of Persian
1403 and Hijri 1446, 18 patterns, and both native-digit and ASCII settings. They
include standalone and narrow month names, quarters, ordinals, weekdays, eras,
redundant fields and six fractional digits.

These comparisons establish unchanged behavior in the exercised cases, including
unchanged errors. They are not a new independent calendar oracle or an exhaustive
test of every possible date, pattern and input combination.

## Regression tests

| Run | Result |
| --- | --- |
| Focused chronology classes, helpers, serialization and picker suites | **256 passed** |
| Focused formatter parsing, locale, state, boundaries and Material suites | **379 passed** |
| Complete formatter core, including five new coexistence tests | **75 passed** |
| Node suites in Australia/Lord_Howe | **64 passed** |
| Node suites in Africa/Monrovia | **64 passed** |
| Node suites in Asia/Tehran | **64 passed** |
| Formatter core analysis and new-test formatting | **Passed** |

The new `calendar_coexistence_test.dart` protects the shared formatter against:

- Month-name and digit-cache leakage while alternating Hebrew, Persian and
  Hijri, across all supported locales and named-month widths.
- Failed Hebrew leap-month parsing affecting subsequent existing-calendar input.
- Hebrew month 13 becoming accepted by strict Persian or Hijri parsing.
- Hebrew quarter rejection breaking existing quarter formatters/parsers.
- Two-digit-year windows retaining the wrong calendar after formatter reuse.

The existing timezone CI job now includes this new test file. No production code
change was necessary. The earlier full native and browser validation remains
documented in [the package validation report](hebrew-package-validation-2026-10-12.md).

## Integration and size effects

`CalendarId.hebrew` is appended, preserving the indices and storage identifiers
of the existing enum values. Consumer code that exhaustively switches over
`CalendarId` must add a Hebrew case or a default. Code iterating `CalendarId.values`
now sees four calendars. Existing Persian/Hijri JSON payloads are unchanged.

An identical Persian/Hijri-only formatter sample was compiled with `dart compile
js -O4` before and after the addition, and its Node output matched:

| Sample artifact | Before | After | Increase |
| --- | ---: | ---: | ---: |
| JavaScript bytes | 300,751 | 332,982 | **32,231** |
| Gzip bytes, level 9 | 74,120 | 81,397 | **7,277** |

This shows a size cost even for this sample that only uses Persian and Hijri.
It measures one optimized Dart formatter program, not a Flutter application or
APK size budget. CPU latency and device memory were not benchmarked. Separate
calendar entry points or deferred Hebrew data could be evaluated if application
size becomes a requirement; the current calendar behavior needs no corrective
change.

## Evidence and limits

Local scripts, source snapshots, comparison digests, compiled samples and command
logs are retained under `general_date/.dart_tool/validation/2026-10-12/` (ignored
by Git): `setup_side_effect_baseline.py`, `side_effect_probe.dart`,
`compare_side_effect_results.py`, `side_effect_comparison.json` and
`regression-*.log`/`.json`.

This run used Flutter 3.47.6, Dart 3.13.5 and Node 22.16.0. The native comparison
used the host Iran timezone; the Node timezone runs set and assert their actual
timezone. Minimum SDK, hosted release and physical-device coverage limits remain
as described in the package validation report.
