# Hebrew calendar

This checkout supports the fixed Hebrew civil calendar in the pure Dart core
and the Flutter wrapper. Import `general_datetime_core.dart` in Dart, or
`general_datetime.dart` in Flutter; both expose the same `HebrewDateTime` class.
Hebrew support is included in the prepared `general_datetime_core` 2.0.0 and
`general_datetime` 4.0.0 releases. Their hosted constraints are aligned.
Until publication, select the local core using
[development setup](development.md#dependency-resolution).
CI selects the local core automatically. Translated Hebrew formatting and
Material labels use formatter core 2.0.0 / wrapper 3.0.0; this chronology
wrapper itself provides English labels.

```dart
final native = DateTime.utc(2024, 3, 20, 12, 34, 56, 123, 456);
final hebrew = HebrewDateTime.fromDateTime(native);
print(hebrew.toIso8601String()); // 5784-07-10T12:34:56.123456Z
print(hebrew.toDateTime() == native); // true

final civil = CalendarDate(
  calendar: CalendarId.hebrew, year: 5784, month: HebrewDateTime.adarI, day: 30,
);
print(civil.addMonths(1)); // hebrew:5784-07-29
print(civil.addYears(1)); // hebrew:5785-07-29
// Reject a missing Adar I rather than mapping it to ordinary Adar:
// civil.addYears(1, missingMonth: MissingMonthPolicy.reject);
```

## Calendar contract

- Supported years: AM 1 through 9999, without year zero. Bounds include
  1 Tishri AM 1 through 29 Elul AM 9999.
- Days begin at midnight in the value's UTC or host-local representation.
  Sunset, locations, holidays, and religious observance rules are outside this API.
- The fixed arithmetic follows Unicode ICU 78.3. It calculates leap years,
  year-start postponements, and variable Cheshvan/Kislev lengths. All six year
  lengths (353, 354, 355, 383, 384, 385 days) are supported.
- Epoch getters, durations, comparisons, equality, hashing, and conversions
  preserve native `DateTime` behavior. Use `CalendarDate` for civil arithmetic.
- `hasOfficialCalendarData` and `CalendarSystems.hebrew.hasPublishedData(year)`
  return false: this calendar uses arithmetic rather than an annual published table.

Months use stable, one-based ICU slots. A number identifies the same named month
across leap and common years; it is not always its ordinal within that year.

| Slot | Constant | Month |
| --- | --- | --- |
| 1 | `tishri` | Tishri |
| 2 | `cheshvan` | Cheshvan |
| 3 | `kislev` | Kislev |
| 4 | `tevet` | Tevet |
| 5 | `shevat` | Shevat |
| 6 | `adarI` | Adar I, leap years only |
| 7 | `adar` / `adarII` | Adar in common years, Adar II in leap years |
| 8 | `nisan` | Nisan |
| 9 | `iyar` | Iyar |
| 10 | `sivan` | Sivan |
| 11 | `tammuz` | Tammuz |
| 12 | `av` | Av |
| 13 | `elul` | Elul |

Use `HebrewDateTime.monthsOfYear(year)` or
`CalendarSystems.monthsOfYear(CalendarId.hebrew, year)` to iterate valid slots.
Use `monthOrdinal` for chronological position and `monthsInYear(year)` for the
actual month count. `CalendarDate.addMonths` and picker `monthDelta` count actual
months and skip slot 6 in common years.

`isValidDate`, `CalendarDate`, `CalendarSystems.construct`, and JSON decoding
validate strictly. Date-time constructors normalize day/clock overflow and month
slots outside 1..13: month 0 means previous Elul; month 14 means next Tishri.
An explicit slot 6 in a common year is rejected, including by `copyWith` and
parsing. Use `CalendarDate.addYears` for the explicit missing-month policy.
Its default maps Adar I to ordinary Adar, with day clamping; the separate
`CalendarOverflow` policy controls day rejection or overflow.

## Storage

Version-1 `CalendarInstant` and `CalendarDateRecord` JSON accept the new calendar
identifier `hebrew`. Civil records preserve the stable month slot. Older readers
without this identifier reject Hebrew records; the schema version and existing
calendar identifiers are unchanged. Instant storage retains the existing
four-digit Gregorian timestamp bounds.

`HebrewDateTime.parse` and `toIso8601String` exchange Hebrew calendar fields
(including slot 13), using the package's ISO-like syntax. For Gregorian APIs,
serialize `CalendarInstant` or `value.toDateTime().toUtc().toIso8601String()`.

## Flutter Material pickers

```dart
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';

// Scope this localization delegate to the Hebrew picker or its MaterialApp.
MaterialApp(
  localizationsDelegates: const [
    DefaultHebrewCalendarMaterialLocalizations.delegate,
  ],
  home: Scaffold(
    body: CalendarDatePicker(
      initialDate: HebrewDateTime(5784, 7, 10),
      firstDate: HebrewDateTime(5783),
      lastDate: HebrewDateTime(5785, 13, 29),
      currentDate: HebrewDateTime.now(),
      onDateChanged: (date) {},
      calendarDelegate: const HebrewCalendarDelegate(),
    ),
  ),
);
```

The default localization supplies English Material strings and Hebrew month
names. Compact input uses `dd/mm/yyyy` with the stable slots above. Hebrew-language
localization is provided by the companion formatter 3.0.0 release through
`HebrewCalendarMaterialLocalizations.delegate`, with all 120 formatter locales
and Flutter-supported Material translations. The chronology-only default
remains English. Supply a matching localization delegate in each picker scope.
The calendar application demo retains its existing formatter-supported calendars.

The delegate requires `HebrewDateTime` inputs and parser results. Convert saved
Gregorian values explicitly using `HebrewDateTime.fromDateTime`. Year selection
maps Adar I to ordinary Adar in a common year. For `showDateRangePicker`, use
`const HebrewCalendarDelegate().rangePickerDelegate` and
`calendarDateRangePickerBuilder(rangeDelegate)`, as with the other calendars.

## Verification and provenance

Core tests check independently transcribed Hebcal civil-date anchors, every
supported year and month boundary, full day round trips in representative years,
all year types, large-offset bounds, parsing, conversion precision, arithmetic,
serialization, and week/range operations. Flutter tests exercise leap/common month
navigation, a leap-to-common year selection, invalid input, and range endpoints.
The arithmetic is not independently compared against every supported day.
The [package validation report](hebrew-package-validation-2026-10-12.md) records
239,612 days compared against .NET in both directions, browser JavaScript/Wasm
checks, and Android build coverage. See the
[existing-calendar regression review](hebrew-existing-calendar-regression-2026-10-12.md)
for Persian/Hijri isolation and compiled-size results.

ICU source and license attribution are in the core's
[third-party notices](../packages/general_datetime_core/THIRD_PARTY_NOTICES.md).
The test fixtures attribute their Hebcal sources and CC BY 4.0 data license.
