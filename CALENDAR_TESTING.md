# Calendar testing

The suite combines independent reference-data checks, deterministic stress
tests, date-time contracts, and Material picker integration tests for both
Persian and Hijri calendars.

## Independent accuracy checks

The existing calendar suites verify every supported conversion day:

- Persian: 107,016 published-data days against the University of Tehran
  fixture, plus all 1,183,020 supported days against external year starts.
- Hijri: all 106,665 supported days against the separate ICU/OpenJDK fixture.

Production calendar calculations are not imported by the reference fixtures.
The additional shared test cases use those fixtures for month lengths,
Gregorian dates, and calendar fields. Native `DateTime` supplies expectations
for clock normalization, epoch values, time zones, and exact duration arithmetic.

## Critical regression cases

`test/unit/calendar_critical_test.dart` runs the same contracts for both calendars:

- strict first/last-day validity for every reference month;
- 1,000 seeded combinations of negative/overflowing month, day, and clock fields;
- 500 seeded dates in both local and UTC modes, including microseconds;
- 300 seeded reversible duration operations;
- negative epoch values, sub-millisecond boundaries, and signed/unsigned
  32-bit second boundaries, plus rejection of overflowing 64-bit epoch inputs;
- ISO fraction padding/truncation, compact dates, shortened clock fields,
  signed years, extreme offsets, and malformed input;
- an offset matrix at both supported endpoints, including adjacent invalid
  instants and conditional local/UTC boundary rejection;
- historical DST gaps/folds and the difference between duration addition and
  calendar-day navigation;
- cross-calendar factories, every comparison direction, heterogeneous sorting,
  and interchangeable `DateTime` map keys.

The seeded checks print their seed, sample index, and relevant input on failure.
They use fixed seeds `0xCA1E`, `0xDA7E`, and `0xADD`.

The extreme-epoch regressions exposed a signed multiplication overflow in both
calendars: oversized seconds/milliseconds could wrap to valid dates near 1970.
Seconds are now checked before multiplication; milliseconds use the native
validated constructor directly.

`test/unit/calendar_picker_critical_test.dart` verifies:

- compact parsing/formatting and invalid day rejection in every reference month;
- reference weekdays under all seven possible week starts;
- signed month navigation, month deltas, and date-only normalization;
- input validation for malformed, impossible, out-of-range, and disabled dates,
  followed by successful recovery;
- customized formatting/parsing through the actual input widget;
- picker navigation and selection across a year boundary;
- disabled navigation at both finite endpoints;
- coexistence of Gregorian, Persian, and Hijri localization scopes.

The interface suite also checks unsupported factory types.

## Run the tests

```console
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test example/lib
```

Run only the new suites with:

```console
flutter test test/unit/calendar_critical_test.dart test/unit/calendar_picker_critical_test.dart
```

## Time-zone coverage

GitHub Actions runs the complete native suite in three independent Ubuntu jobs:
`UTC`, `Asia/Tehran`, and `America/New_York`. Each job sets the process `TZ`
environment variable and passes `CALENDAR_TEST_TZ` to the tests. The tests
assert UTC's zero offset, Tehran's historical 23/25-hour transition days in
2019, or New York's 23/25-hour transition days in 2021, so an ignored time-zone
setting fails the job.

For example, on Linux:

```sh
TZ=America/New_York flutter test --dart-define=CALENDAR_TEST_TZ=America/New_York
```

Local default runs use the host's time zone. The historical Tehran DST
assertions were also verified explicitly on the current Windows host. CI's
UTC and New York jobs will run when the workflow is triggered.

Browser execution remains unverified because the installed Windows Flutter
SDK cannot start the browser suites; see
[HIJRI_CALENDAR_VALIDATION.md](HIJRI_CALENDAR_VALIDATION.md).
