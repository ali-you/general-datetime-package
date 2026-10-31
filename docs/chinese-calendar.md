# Chinese civil calendar

`ChineseDateTime` and `CalendarSystems.chinese` implement a bounded Chinese
lunisolar civil calendar using the MIT-licensed .NET 10.0.0 month tables.
Supported lunar years are **1901–2099**, inclusive: Gregorian civil dates
**1901-02-19 through 2100-02-08**. Unsupported dates throw; there is no
astronomical or arithmetic fallback.

## Year and month coordinates

The year is the **Gregorian year containing lunar New Year**, not an ICU extended
year or a repeating sexagenary year. For example, Gregorian 2025-07-25 is in
Chinese year 2025.

`month` is the **chronological position within that year**, from 1 through 12
or 13. `lunarMonth` is the traditional month number, from 1 through 12.
`isLeapMonth` identifies the repeated month. `monthCode` provides stable
identity, such as `M06`, `M06L`, or `M07`.

| Gregorian day | year | month | lunarMonth | isLeapMonth | monthCode |
| --- | --- | --- | --- | --- | --- |
| 2025-06-25 | 2025 | 6 | 6 | false | M06 |
| 2025-07-25 | 2025 | 7 | 6 | true | M06L |
| 2025-08-23 | 2025 | 8 | 7 | false | M07 |

```dart
import 'package:general_datetime_core/general_datetime_core.dart';

final converted = ChineseDateTime.fromDateTime(DateTime.utc(2025, 7, 25));
final leap = ChineseDateTime.fromLunar(
  year: 2025, lunarMonth: 6, day: 1, isLeapMonth: true, isUtc: true,
);
assert(converted == leap);
assert(leap.month == 7);
assert(leap.monthCode == 'M06L');
assert(ChineseDateTime.utc(2025, 7) == leap);
```

`fromLunar` rejects nonexistent leap months and invalid date/clock components.
Positional constructors normalize ordinal-month, day, and clock overflow,
subject to the supported bounds. Local constructors follow native Dart DST
normalization; `CalendarSystems.chinese.construct` rejects normalized wall
times. Days begin at midnight. UTC/local conversion preserves the instant and
does not select a geographical timezone for the caller.

## Civil arithmetic and storage

Use `CalendarDate` for all-day dates and calendar periods. `addMonths` advances
through actual months, including the leap month. `addYears` preserves the
traditional numbered month and leap identity. When the destination lacks that
leap month, `MissingMonthPolicy.regular` maps to the corresponding regular month;
`MissingMonthPolicy.reject` throws. Day overflow uses the existing independent
clamp/reject/overflow policy.

```dart
final date = CalendarDate.fromDateTime(leap);
assert(date.addMonths(1).monthCode == 'M07');
assert(date.addYears(1).monthCode == 'M06');
final restored = CalendarDate.fromRecord(
  CalendarDateRecord.fromJson(date.toRecord().toJson()),
);
assert(restored.monthCode == 'M06L');
```

Version-1 JSON remains unchanged. The `chinese` identifier plus year and ordinal
month preserves leap identity unambiguously. `CalendarInstant` stores native UTC
timestamps and the presentation calendar. `ChineseDateTime.parse` and
`toIso8601String` use the related year and ordinal month; native `DateTime.parse`
must not consume those calendar-specific strings.

`CalendarId.chinese` is appended to the enum, preserving existing enum indices.
Consumers with exhaustive switches must handle the new case. These changes are
included in core 3.0.0 / Flutter wrapper 5.0.0.

## Formatting and Flutter pickers

The companion formatter supports Chinese dates with CLDR 48 month names in all
bundled locales. Numeric `M`/`MM`/`L`/`LL` use **ordinal months**, matching the
constructors and storage. Named month patterns display traditional month names
with CLDR's leap marker; for example, English `MMMM` uses `Sixth Monthbis` and
Chinese uses `闰六月`. Names can precede the year during parsing, and strict
parsing rejects conflicting numeric/named months and nonexistent leap identities.

The package keeps its shared locale skeleton patterns. The `y` field means the
related Gregorian year; era (`G`), quarter (`Q`), and cyclic-year formatting are
outside this API. Era and quarter patterns explicitly reject Chinese dates.
`dateSymbols.MONTHS` lists the twelve regular month names; use the formatter to
resolve a date's ordinal month and leap identity.

```dart
import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';

// Install DefaultChineseCalendarMaterialLocalizations.delegate in MaterialApp.
final picker = CalendarDatePicker(
  firstDate: ChineseDateTime(2024),
  lastDate: ChineseDateTime(2026, 12, 29),
  initialDate: ChineseDateTime(2025, 7),
  calendarDelegate: const ChineseCalendarDelegate(),
  onDateChanged: (date) {},
);
```

For translated Material strings and CLDR names, install
`ChineseCalendarMaterialLocalizations.delegate` from `general_date_format`
instead. Both localization adapters parse ordinal numeric month input.
`ChineseCalendarDelegate` checks date types, counts actual months, and clamps
an ordinal 13 carried by Flutter into a twelve-month year to its last month.
For `showDateRangePicker`, use `delegate.rangePickerDelegate` and
`calendarDateRangePickerBuilder(rangeDelegate)`, as with the other bounded calendars.

`general_calendar` works through the same delegate; its example includes Chinese
calendar selection, and tests cover year overview, leap-month selection, and
both finite endpoints.

## Data provenance and validation

- Runtime source: [.NET 10.0.0 ChineseLunisolarCalendar](https://github.com/dotnet/runtime/blob/v10.0.0/src/libraries/System.Private.CoreLib/src/System/Globalization/ChineseLunisolarCalendar.cs),
  SHA-256 `f6a6a3e586571e6afeaa347ad26d7b9ade0a2a160667b62539feac4c6cf7ada6`.
  The source's MIT notice is reproduced in both packages' third-party notices.
- `tool/generate_chinese_calendar.py` verifies that pinned hash before decoding
  each year's New Year anchor, repeated month, and chronological month lengths.
  `--check --offline` checks reproducibility against the ignored local cache.
- `tool/export_chinese_oracle.ps1` generates independent expected month anchors
  and lengths through installed .NET calendar APIs. The recorded oracle was
  .NET 10.0.11. All **72,674 supported days** are checked in both directions
  against those 2,461 month fixtures, including day-of-year and month navigation.
- `tool/validate_chinese_hko.py` independently compares the
  [HKO historical text tables](https://www.hko.gov.hk/en/gts/time/conversion.htm).
  Those downloaded tables remain in the ignored cache. The report records
  **30 differing days, 2057-09-28 through 2057-10-27**. The runtime follows the
  pinned .NET table throughout; it does not claim exact HKO equivalence.
  HKO's text source omits 2069-12-30; the validator explicitly supplies lunar
  day 17, confirmed by the [same year's PDF](https://www.hko.gov.hk/en/gts/time/calendar/pdf/files/2069e.pdf).
- `tool/validate_chinese_oracle.cjs` compares every supported day with Node's
  ICU Chinese calendar. ICU 77.1 differs on **417 days**. Exact dates and values
  are retained in `chinese-icu-comparison.json`; HKO differences are retained
  in `chinese-hko-comparison.json`. These are intentional chronology differences,
  not silently corrected outputs.

The .NET table is implementation data rather than an official annual calendar
publication, so `hasOfficialCalendarData` and `hasPublishedData` are false.
Future astronomical dates can differ across reference implementations. This
civil API does not compute solar terms, observance times, or Panchanga fields.

## Verification on 2026-10-28

All three Flutter package analyses passed. Chronology core passed 57 VM tests
and 51 JavaScript tests; formatter core passed 86 VM tests and 85 JavaScript
tests. Flutter suites passed 352 chronology-wrapper tests, 515
formatter tests, and 94 generic-calendar tests. Updated formatter/calendar
examples passed 7 and 16 tests; the calendar application demo passed 11.
The pinned .NET and CLDR Chinese generators reproduced their generated output.
See the [complete implementation audit](chinese-implementation-audit-2026-10-28.md)
for native executable tests, five real process timezones, regression fixes,
coverage, and the remaining remote CI source-pin requirement.
