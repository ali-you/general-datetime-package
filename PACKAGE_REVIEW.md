# Package review — 2026-10-05

Reviewed the current working trees in `D:/StudioProjects/general_date` and `D:/StudioProjects/general_date_format`, including both Dart cores, Flutter adapters, scheduling support, examples, locale generators, manifests, and CI configuration. Existing uncommitted changes were included and preserved.

Priorities: P1 = fix before release because incorrect data can be accepted silently; P2 = behavioral defect; P3 = maintenance correction.

## Findings requiring fixes

### 1. P1 — Strict parsing accepts nonexistent wall times when DST changes minutes

**Status:** Fixed on 2026-10-05. Strict/loose parsing now compares all constructed
clock components with the requested values, preserving the date-only shift to
exactly 01:00 on the same date. Permissive parsing keeps native normalization.
Regressions cover both calendars in Lord Howe, Monrovia, and Tehran, with a
dedicated CI timezone matrix. Validation passed: 500 Flutter tests, 26 Dart-core
tests, 15 Node regressions in each of the three zones, and both analyzers.

**Location:** `D:/StudioProjects/general_date_format/packages/general_date_format_core/lib/src/date_builder.dart:225`

The verification compares the constructed hour with the requested hour, but never compares the constructed minute, second, or fraction with the requested clock. Checking the input values against 0–59 is insufficient.

**Reproduced:** Compile `.dart_tool/review_dst.dart` to JavaScript and run Node with `TZ=Australia/Lord_Howe`. Parsing Persian `1403-07-15 02:15:12.123456` with `yyyy-MM-dd HH:mm:ss.SSSSSS` in local strict mode returns `1403-07-15 02:45:12.123456`. The requested Gregorian wall time is 2024-10-06 02:15, inside the half-hour DST gap.

**Fix:** Compare every resulting clock component with the supplied clock in strict and loose parsing. Retain any explicitly documented date-only midnight exception narrowly. Add half-hour and historical non-hour transition regressions.

### 2. P2 — Two-digit year resolution breaks at chronology limits and negative centuries

**Status:** Fixed on 2026-10-05. Century windows now compare calendar wall fields
without constructing unsupported endpoints, use floor centuries for negative
years, and require a supported result inside the window. Repeated-year checks
preserve FormatException/nullable parsing contracts and share one clock reading.
Added 13 regressions covering local/UTC bounds, negative centuries, repeated
years, clock precision, ordinal/overflow fields, and unsupported references.
Validation passed: 500 Flutter tests, 39 Dart-core tests, 28 Node regressions in
each of Lord Howe, Monrovia, and Tehran, and both analyzers. The Node regressions
are included in the CI timezone matrix.

**Location:** `D:/StudioProjects/general_date_format/packages/general_date_format_core/lib/src/date_builder.dart:271`

Resolution constructs the provisional year and the window endpoint before determining the final century. These intermediate dates can be unsupported even when the final result is supported. Negative century calculation also uses truncating division rather than floor division.

**Reproduced:**
- With `now = () => HijriDateTime.utc(1580).toDateTime()`, parsing `99-01-01` should select AH 1599 within the window ending AH 1600. It instead tries AH 1699 and throws a FormatException.
- With reference AH 1590, parsing `90-01-01` returns null because the window endpoint AH 1610 is constructed outside the table, although AH 1590 is supported.
- With reference Persian year -40, parsing `99-01-01` returns year -1, later than the window endpoint year -20.
- With reference AH 1580, `tryParseStrict('99 1599-01-01', ...)` using `yy yyyy-MM-dd` leaks a RangeError from repeated-year verification.

**Fix:** Resolve the rolling century using calendar field coordinates and floor division, then construct/check the final supported date. Convert invalid parsed-field range errors consistently to FormatException, including repeated-year verification. Nullable methods must retain their documented contract.

### 3. P2 — Strict era parsing accepts a contradictory signed year

**Status:** Fixed on 2026-10-05. Strict/loose parsing requires every era token's
candidate set to include the era of the resolved year, using the formatter's
year-zero convention. Identical labels and loose case/whitespace aliases retain
all matching meanings. Numeric signs and permissive parsing are preserved.
Added 15 regressions, including all bundled locale round trips for both calendars
and distinct-name fixtures. Validation passed: 500 Flutter tests, 54 Dart-core
tests, 43 Node parser regressions in each of Lord Howe, Monrovia, and Tehran,
both analyzers, formatting, and whitespace checks. CI includes the new tests.

**Location:** `D:/StudioProjects/general_date_format/packages/general_date_format_core/lib/src/date_builder.dart:192` and `date_format_field.dart:723`

Era verification previously compared repeated era indices without checking them
against the resulting year's sign or retaining ambiguous meanings.

**Correction to the original reproduction:** The current pinned English symbols
use `AP` for both Persian eras. Therefore `AP -0001-01-01` is valid ambiguous
input and remains accepted; the original claim that English distinguishes these
labels was incorrect. With distinct `BP`/`AP` and `Before Persia`/`Anno Persia`
test symbols, the previous parser accepted after-era labels with negative/zero
years and before-era labels with positive years. Combining an ambiguous short
label with a compatible distinct full name also wrongly failed repeated-era
verification. Before the fix, 12 of the 15 new regression tests failed.

**Fix:** Validate distinguishable era labels against the resulting year. Preserve signed-year construction without implicitly changing the sign. Treat identical/ambiguous era labels as candidate sets rather than rejecting valid round trips.

### 4. P2 — Persian Material range picker crashes at the supported minimum

**Status:** Fixed on 2026-10-05 through the new `rangePickerDelegate` integration
on both calendar delegates. Pass `const PersianCalendarDelegate().rangePickerDelegate`
(or its Hijri equivalent) to Flutter's `showDateRangePicker`/`DateRangePickerDialog`.
The adapter supplies native comparison dates for empty leading cells and
out-of-range keyboard targets, while selectable dates/results, input guards,
and chronology bounds retain their existing contracts. General calendar
arithmetic continues to use the ordinary delegate. Usage is documented in README.
Added 34 tests: actual range selection at both endpoints for all seven week
starts, day/week keyboard limits, invalid input and recovery, and adapter guards.
Validation passed: 323 chronology/picker tests, 500 formatter compatibility
tests, repository analysis, formatting, and whitespace checks. Existing CI
automatically runs the new tests in its SDK/timezone matrix.

**Location:** `D:/StudioProjects/general_date/lib/src/delegates/persian_calendar_delegate.dart:23`,
`hijri_calendar_delegate.dart:23`, and `range_picker_calendar_delegate.dart:13`.

Flutter's range-picker grid calls `getDay` with a day before month day 1 when computing its leading edge, even when that edge is not highlighted. At the minimum supported Persian month, the delegate tries to construct a date outside chronology bounds.

**Reproduced:** Open `showDateRangePicker` with `firstDate: PersianDateTime(-61, 1, 1)`, a matching current date/delegate/localization, and an initial range starting on that date. The widget raises RangeError. Temporary regression: `.dart_tool/review_range_test.dart`. The default English Hijri minimum probe passed; this result should not be generalized to all calendars/locales.

The full week-start matrix subsequently reproduced the same failure at the
Hijri minimum for six non-Sunday week starts. Before the adapter, 12 of the 28
endpoint rendering/selection cases failed; all now pass using `rangePickerDelegate`.

**Fix:** Provide boundary-aware range-picker integration or address the upstream padding calculation. Do not weaken chronology bounds or clamp selectable dates silently. Test actual range pickers at both endpoints and with different week starts; existing endpoint tests exercise CalendarDatePicker instead.

### 5. P2 — Recurrence queries resolve irrelevant historical dates

**Location:** `D:/StudioProjects/general_date/packages/general_calendar_schedule/lib/general_calendar_schedule.dart:308`

Expansion starts at slot zero and resolves every earlier candidate before filtering occurrences against the requested UTC window. An irrelevant old DST gap/fold can prevent a valid later query. Old daily rules can also exhaust the default 10,000-slot limit even for a narrow recent query; narrowing the query does not reduce the historical prefix.

**Reproduced:** Daily New York 02:30 rule starting 2024-03-09, count 5, default gap rejection. Querying only 2024-03-12 through 2024-03-13 fails on the 2024-03-10 gap.

**Fix:** Seek the first candidate that could overlap the requested window, accounting for duration and zone resolution policies. Preserve anchored slot counting and query moved overrides independently. Reject invalid gap/fold candidates that are relevant to the query.

### 6. P2 — Inclusive lastDate is checked after a potentially invalid next candidate

**Location:** `D:/StudioProjects/general_date/packages/general_calendar_schedule/lib/general_calendar_schedule.dart:313`

The next candidate is constructed before the inclusive ending condition is checked. Construction can throw even though the schedule already ended successfully.

**Reproduced:**
- Monthly Gregorian rule starting 2024-01-31, `lastDate` equal to the start, `datePolicy: reject`. Query January: the valid January occurrence is followed by a failure constructing February 31.
- Daily Umm al-Qura rule starting AH 1600-12-30 with the same `lastDate`. Query its supported day: expansion throws attempting the following unsupported day.

**Fix:** Determine whether a candidate slot is beyond the rule's ending bound before constructing it. Preserve errors for genuinely required invalid candidates. Add both ordinary missing-day and chronology-end regressions.

### 7. P2 — Demo clips boundary month dates without preserving weekday columns

**Location:** `D:/StudioProjects/general_date/apps/calendar_demo/lib/calendar_controller.dart:84` and `calendar_screen.dart:235`

When subtracting the leading weekdays crosses the supported minimum, the controller keeps day 1 as the first displayed date. The grid still starts in the configured first-weekday column.

**Reproduced:** Persian -61-01-01 is weekday 4 (Thursday), but the default header starts at weekday 1 (Monday). It is rendered in the first cell under Monday.

**Fix:** Represent unavailable leading cells as empty grid positions, or provide an explicit leading-cell offset. Keep unsupported dates out of calendar construction.

### 8. P2 — Demo does not load a replacement controller

**Location:** `D:/StudioProjects/general_date/apps/calendar_demo/lib/calendar_screen.dart:35`

The screen calls reload only during initState. Rebuilding the same screen with a different controller updates AnimatedBuilder's listener, but never loads that controller's source.

**Reproduced:** Replace the controller on an existing CalendarScreen: the original source receives one query; the replacement receives zero. Temporary widget probe: `apps/calendar_demo/.dart_tool/review_controller_test.dart`.

**Fix:** Handle controller identity changes in didUpdateWidget, reset controller-specific focus state as appropriate, and trigger the new controller's initial load. Do not dispose a controller owned by the caller.

### 9. P3 — Datetime wrapper repository metadata points to the wrong repository

**Location:** `D:/StudioProjects/general_date/pubspec.yaml:5`

The repository, documentation, and issue-tracker fields use `ali-you/general-datetime-package`. The configured origin and core package metadata use `ali-you/general-date-package`.

**Fix:** Align those three metadata URLs with the actual repository so published package links direct users to the correct source and issue tracker.

## Verification performed

Existing suites all passed with the locally resolved source pair:

| Suite | Passed |
| --- | ---: |
| general_datetime Flutter chronology/picker suite | 289 |
| general_datetime_core Dart suite | 20 |
| general_calendar_schedule Dart suite | 6 |
| calendar_demo suite | 8 |
| general_date_format Flutter suite | 500 |
| general_date_format_core Dart suite | 12 |
| Formatter example widgets | 5 |
| **Total** | **840** |

Both repository Flutter analyses and all three standalone Dart analyses reported no issues. Both locale-generation verification commands passed against the pinned data. Additional probes reproduced the findings above, including a failing Persian range-picker regression and a JavaScript DST probe executed in Node.

The exhaustive calendar-conversion suites passed. No new conversion-table or Gregorian-instant preservation defect was found in this review.

## Release validation still needed

These are validation gaps, not demonstrated code defects:
- Execute the declared minimum SDK versions; this review used Flutter 3.47.5 / Dart 3.13.4.
- Run full Chrome JavaScript/Wasm suites and Android/iOS integration tests. The Node DST probe is not a full browser certification.
- Verify hosted dependency resolution without local overrides and publication contents for each independent package. Current local source-pair success does not verify hosted releases.
- After fixing the findings, commit focused regressions and rerun the relevant suites.

The initial review changed no production source. Issues 1 through 4 were subsequently fixed
as recorded above. Review probes and logs remain under ignored .dart_tool directories.
