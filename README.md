# General DateTime (Dynamic Calendar)

<a href="https://pub.dev/packages/general_datetime">
   <img src="https://img.shields.io/pub/v/general_datetime?label=pub.dev&labelColor=333940&logo=dart">
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues">
   <img alt="Issues" src="https://img.shields.io/github/issues/ali-you/general-datetime-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues?q=is%3Aclosed">
   <img alt="Issues" src="https://img.shields.io/github/issues-closed/ali-you/general-datetime-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/pulls">
   <img alt="GitHub Pull Requests" src="https://badgen.net/github/prs/ali-you/general-datetime-package" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/blob/main/LICENSE" rel="ugc">
   <img src="https://img.shields.io/github/license/ali-you/general-datetime-package?color=#007A88&amp;labelColor=333940;" alt="GitHub">
</a>
<a href="https://github.com/ali-you/general-datetime-package">
   <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ali-you/general-datetime-package">
</a>

![Flutter CI](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml/badge.svg)

A Flutter/Dart Package for working with dates across several calendar systems. Using a unified
interface, you can convert, manipulate, and compare dates in Gregorian, Persian (Jalali),
Hijri (Umm al-Qura), and other
calendar systems—all while preserving time components and handling timezone, leap year, and negative
value normalization within each calendar's documented range.

## Related Packages

| Version                                                                                                                      | Package                                                             | Description                                                             |
|------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|
| [![general_date_format](https://img.shields.io/pub/v/general_date_format.svg)](https://pub.dev/packages/general_date_format) | [general_date_format](https://pub.dev/packages/general_date_format) | Date formatting for multiple calendar systems with localization support |

## Features

- **Gregorian ↔ Other calendars:**
  Convert between Gregorian and other dates with high precision, preserving time components (hours,
  minutes, seconds, milliseconds, and microseconds).

- **Leap Year Handling:**
  Detect and correctly handle leap years and leap days, including automatic correction of invalid
  leap dates.

- **Custom Arithmetic:**
  Perform date arithmetic using custom implementations of `add`, `subtract`, and `difference` that work
  directly on calendar fields.

- **Negative Normalization:**
  Automatically normalize negative or overflow values in day, month, hour, minute, second, millisecond, and
  microsecond components.

- **Time Zone Support:**
  Retrieve the time zone name and offset matching Flutter’s `DateTime` behavior for both local and UTC
  dates.

- **Parsing and Formatting:**
  Create custom datetime (`PersianDateTime`, `HijriDateTime`) instances from formatted strings.

- **Flutter Integration:**
  Full support for `MaterialLocalizations` and `CalendarDelegate` for both Persian and Hijri calendars, allowing seamless integration with Flutter's `DatePicker`.

## Installation

To use this plugin, add it to your project:

### 1. Add to `pubspec.yaml`

```yaml
dependencies:
  general_datetime: ^3.0.0

```

Version 3.0.0 is the corrected source release being prepared in this repository.
Until it is published, use a path dependency to this checkout; the hosted 2.1.0
implementation does not contain these fixes:

```yaml
dependencies:
  general_datetime:
    path: ../general_date
```

### 2. Install from terminal

```bash
flutter pub add general_datetime
```

## Usage

Import the package into your Dart code:

```dart
import 'package:general_datetime/general_datetime.dart';
```

### Persian Calendar (Jalali)

```dart
void main() {
  // Create a Gregorian date and convert it to Persian dates:
  PersianDateTime pDate = PersianDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(pDate.toString()); // 1403-12-11 00:00:00.000

  // Create a Persian date directly (auto-normalization applies):
  PersianDateTime directDate = PersianDateTime(1403, 12, 11, 14, 30);
  
  // Arithmetic:
  var nextWeek = directDate.add(Duration(days: 7));

  // Supported calculation range (official table: 1206 through 1498):
  print(PersianDateTime.minimumYear); // -61
  print(PersianDateTime.maximumYear); // 3177
}
```

### Hijri Calendar (Umm al-Qura)

```dart
void main() {
  // Create a Gregorian date and convert it to Hijri dates:
  HijriDateTime hDate = HijriDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(hDate.toString()); // 1446-09-01 00:00:00.000

  // Create a Hijri date directly:
  HijriDateTime directDate = HijriDateTime(1446, 9, 1);

  // Supported range and published-data coverage:
  print(HijriDateTime.minimumYear); // 1300
  print(HijriDateTime.maximumYear); // 1600
  print(directDate.hasOfficialCalendarData); // true
}
```

### Safe calendar field operations

Use `CalendarDateUtils` when a calendar value is held in a `DateTime` variable,
such as a picker callback or a shared event model:

```dart
DateTime selected = PersianDateTime.utc(1403, 1, 1, 12, 30);
final nextDate = CalendarDateUtils.copyWith(selected, day: 2);
// PersianDateTime.utc(1403, 1, 2, 12, 30), Gregorian 2024-03-21.
final midnight = CalendarDateUtils.dateOnly(selected);
// PersianDateTime.utc(1403, 1, 1); UTC/local mode is preserved.

final native = CalendarDateUtils.toGregorian(selected);
// Native DateTime.utc(2024, 3, 20, 12, 30), preserving the exact instant.
final gregorianChange = native.copyWith(day: 21);
```

The same helpers support Hijri and native Gregorian dates. Field copies use the
input's calendar normalization and range checks. Other implementations of
`GeneralDateTimeInterface` fail with `UnsupportedError` for field operations
until an adapter is implemented; their instants can still use `toGregorian`.

Avoid `selected.copyWith(...)` when `selected` is statically typed `DateTime`,
and avoid `DateUtils.dateOnly(selected)` or other Gregorian helpers on calendar
subclasses. Dart resolves its `copyWith` extension from the static type and
Flutter's helpers reconstruct Gregorian dates from exposed calendar fields.
These upstream calls cannot be overridden by this package. Route calendar field
operations through `CalendarDateUtils`, or convert with `toGregorian` before
using an external Gregorian helper. Convert the result back explicitly with
`PersianDateTime.fromDateTime` or `HijriDateTime.fromDateTime` when needed.

`dateOnly` returns a date-time with cleared clock fields, retaining UTC/local
mode. Local DST rules can normalize a nonexistent midnight. Changing `isUtc`
through `copyWith` reinterprets wall-clock fields; use `toUtc()`/`toLocal()` to
preserve the instant. Material pickers should continue using the matching
calendar delegate's local-date policy. A timezone-free civil-date model and
calendar-period policies are separate work tracked in issue 18 of
[the checklist](CALENDAR_ISSUES_CHECKLIST.md).

### Safe JSON storage

Use `CalendarInstant` for timed values and `CalendarDateRecord` for all-day
calendar dates. Both expose `toJson()` and a strict `fromJson()` factory and work
with `dart:convert`. These versioned records are this package's storage contract.

```dart
import 'dart:convert';
import 'package:general_datetime/general_datetime.dart';

DateTime selected = PersianDateTime.utc(1403, 1, 1, 12, 34, 56, 789, 123);
final event = CalendarInstant.fromDateTime(selected, timeZone: 'Asia/Tehran');
final stored = jsonEncode(event);
// {"version":1,"kind":"instant",
//  "timestamp":"2024-03-20T12:34:56.789123Z",
//  "calendar":"persian","timeZone":"Asia/Tehran"}
final restored = CalendarInstant.fromJson(jsonDecode(stored));
// restored.instant is native Gregorian UTC, retaining the exact microseconds.
final display = PersianDateTime.fromDateTime(restored.instant);
// Explicit UTC calendar conversion; it does not apply the named zone metadata.

final allDay = CalendarDateRecord.fromDateTime(HijriDateTime.utc(1446, 9, 1));
final dateJson = jsonEncode(allDay);
// {"version":1,"kind":"calendar-date","calendar":"islamic-umalqura",
//  "year":1446,"month":9,"day":1}
final restoredDate = CalendarDateRecord.fromJson(jsonDecode(dateJson));
// Calendar fields only: no clock, timezone, or implied instant.

final explicitDate = CalendarDateRecord(
  calendar: CalendarId.persian, year: 1403, month: 1, day: 1,
);
```

Version-1 fields:

| Record | Required fields | Optional fields |
| --- | --- | --- |
| Instant | `version: 1`, `kind: "instant"`, `timestamp`, `calendar` | `timeZone` |
| Calendar date | `version: 1`, `kind: "calendar-date"`, `calendar`, integer `year`, `month`, `day` | None |

The supported [Unicode calendar identifiers](https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml)
are `gregory`, `persian`, and `islamic-umalqura`, exposed by `CalendarId`.
`islamic` and other Hijri algorithms are not aliases for Umm al-Qura. Identifiers
name the calendar system; the calculation rules, data sources, and supported
ranges remain those documented by this package. The schema version identifies
the record layout, not a calendar-data revision.

For instants, the timestamp is authoritative. Serialization converts epoch
microseconds to native Gregorian UTC before formatting. Decoding returns native
UTC; the preferred calendar is metadata and does not reinterpret the timestamp.
An instant can be outside that calendar's supported display range; an explicit
conversion to the calendar then follows its normal range checks. Input
local/UTC mode is not retained. The optional `timeZone` must be a nonempty,
trimmed string and is retained as opaque application metadata, normally an IANA
name. The package does not validate zone existence, infer a zone name from a
local value, or resolve zone offsets/DST. A future wall-clock schedule or a
recurrence requires its own policy (issue 19).

The timestamp schema uses a strict UTC subset of
[RFC 3339](https://www.rfc-editor.org/rfc/rfc3339.html#section-5.6):
`YYYY-MM-DDTHH:mm:ss[.fraction]Z`, Gregorian years 0000 through 9999, and at most
six fractional digits. Encoder output has three or six fractional digits.
Decoding rejects invalid dates, overflow normalization, leap seconds, offsets,
missing seconds, excess precision, and RFC 9557 annotations. Native Gregorian
inputs outside the timestamp year range cannot be encoded. RFC 9557 interchange
is separate from this JSON schema; its calendar identifiers are reused here.

Calendar-date records validate strict calendar fields and supported bounds.
They support signed Persian years including zero, and native Gregorian UTC date
bounds. `fromDateTime` explicitly extracts the input's wall date and discards
clock fields and timezone mode without converting it. Use the field constructor
when the source is already a civil date. All-day records must not be encoded as
midnight timestamps. Calendar arithmetic remains separate work (issue 18).

Both decoders throw `FormatException` for missing/unknown fields, wrong types,
unknown identifiers, unsupported versions, wrong record kinds, or invalid field
values. An optional `timeZone` must be omitted rather than set to null. Direct
construction with invalid dates or zone metadata throws `ArgumentError`;
unregistered calendar interfaces throw `UnsupportedError` when encoding.

**Do not store Persian/Hijri `toIso8601String()` or `toString()` output as a
generic timestamp.** Those methods retain their existing calendar-specific
behavior for compatibility with the matching calendar parser. `toUtc()` still
returns a calendar subclass. A Persian `1403-01-01T...Z` would be read as
Gregorian year 1403 by a generic parser. A schema cannot detect this mistake
after someone manually assigns such a string to `timestamp`; always use the
instant encoder. For a timestamp-only external API, use
`CalendarDateUtils.toGregorian(selected).toUtc().toIso8601String()`.

## Flutter Integration (Localization & Delegates)

Use the matching `CalendarDelegate` with Flutter Material date pickers.
`PersianCalendarDelegate` and `HijriCalendarDelegate` handle calendar
calculations and forward names, formatting, parsing, and input help to the
current `MaterialLocalizations`. Supply
`DefaultPersianCalendarMaterialLocalizations.delegate` for a Persian picker and
`DefaultHijriCalendarMaterialLocalizations.delegate` for a Hijri picker.

Both delegates require matching runtime calendar types for every date argument:
`PersianDateTime` for Persian and `HijriDateTime` for Hijri. This applies to
date-only/range normalization, month/day navigation, nullable comparisons, and
formatting. Both comparison operands and both range endpoints are checked.
Native Gregorian and other-calendar dates throw `ArgumentError`; convert their
instants explicitly before passing them to the delegate:

```dart
final gregorian = DateTime.utc(2024, 3, 20);
final selected = PersianDateTime.fromDateTime(gregorian);
final pickerDate = const PersianCalendarDelegate().dateOnly(selected);
```

The matching `MaterialLocalizations` parser must return the same calendar type.
Invalid text still returns null; a non-null result in another calendar throws
`ArgumentError` for incompatible localization configuration. Valid formatting
and parsing continue using the supplied localization without implicit conversion.
Picker normalization retains calendar wall-date fields and produces local dates.
When using Flutter's `YearPicker` directly, provide a matching `currentDate`
such as `PersianDateTime.now()` or `HijriDateTime.now()`. Flutter defaults to
native `DateTime.now()` even with a custom delegate, so omitting it throws
`ArgumentError` with these delegates. `CalendarDatePicker` already defaults to
the delegate's `now()`.

### Use with CalendarYearPicker

Use the package's `CalendarYearPicker` for standalone year selection. Its
omitted `currentDate` uses `calendarDelegate.now()`, and all supplied dates
are normalized and validated by the delegate:

```dart
Localizations.override(
  context: context,
  delegates: const <LocalizationsDelegate<dynamic>>[
    DefaultPersianCalendarMaterialLocalizations.delegate,
  ],
  child: CalendarYearPicker(
    firstDate: PersianDateTime(1380, 1, 1),
    lastDate: PersianDateTime(1450, 12, 29),
    selectedDate: PersianDateTime(1403, 1, 1),
    calendarDelegate: const PersianCalendarDelegate(),
    onChanged: (DateTime date) {
      print("Selected year: ${date.year}");
    },
  ),
)
```

For Hijri, use `HijriDateTime` inputs, `HijriCalendarDelegate`, and
`DefaultHijriCalendarMaterialLocalizations.delegate`. The wrapper is exported
from `general_datetime.dart` and also supports the default Gregorian delegate.
An explicit `currentDate` overrides the calendar clock; it must match the
delegate's calendar, but need not fall within the selectable range. The
wrapper forwards year selection, keys, and drag behavior to Flutter's picker.

### Use with CalendarDatePicker

Pass the corresponding delegate to change the calendar system:

```dart
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';

// Inside build(BuildContext context), scope the Persian localization to its picker:
Localizations.override(
  context: context,
  delegates: const <LocalizationsDelegate<dynamic>>[
    DefaultPersianCalendarMaterialLocalizations.delegate,
  ],
  child: CalendarDatePicker(
    initialDate: PersianDateTime.now(),
    firstDate: PersianDateTime(1380, 1, 1),
    lastDate: PersianDateTime(1450, 12, 29),
    calendarDelegate: const PersianCalendarDelegate(),
    onDateChanged: (DateTime date) {
      print("Selected: $date");
    },
  ),
)
```

The Hijri picker uses the same structure:

```dart
Localizations.override(
  context: context,
  delegates: const <LocalizationsDelegate<dynamic>>[
    DefaultHijriCalendarMaterialLocalizations.delegate,
  ],
  child: CalendarDatePicker(
    initialDate: HijriDateTime.now(),
    firstDate: HijriDateTime(1440, 1, 1),
    lastDate: HijriDateTime(1460, 12, 29),
    calendarDelegate: const HijriCalendarDelegate(),
    onDateChanged: (DateTime date) {
      print("Selected: $date");
    },
  ),
)
```

For an app using only one calendar, the matching localization delegate can
instead be registered in `MaterialApp.localizationsDelegates`. Custom Material
localizations can replace month names, date formats, and parsing without
changing the calendar delegate. Scope calendar-specific localizations to their
picker when showing several calendar systems in one app.

## API Overview

### Factory Constructors

- `fromDateTime(DateTime datetime)`: Converts Gregorian to target calendar.
- `now()`: Current date and time in the target calendar.
- `utc(...)`: Creates a UTC date with normalization.
- `parse(String formattedString)`: Parse ISO-like strings.

### Core Properties

- `year`, `month`, `day`, `hour`, `minute`, `second`, `millisecond`, `microsecond`.
- `timeZoneName`, `timeZoneOffset`.
- `isLeapYear`: Whether the year is a leap year in that specific calendar.
- `dayOfYear`: 1-based day of the year.
- `julianDay`: The calculated Julian day number.

### Generic Current Time

Use the generic interface to get the current time for any supported type:

```dart
var nowPersian = GeneralDateTimeInterface.now<PersianDateTime>();
var nowHijri = GeneralDateTimeInterface.now<HijriDateTime>();
```

## Customization

You can extend `GeneralDateTimeInterface` to support additional calendar systems.

> [!IMPORTANT]
> Ensure custom calendars define their supported range, normalization rules,
> and an independently verified conversion model.

## Calendars

### Persian Calendar

The Iranian Solar Hijri calendar is astronomical; it is not safely represented
by an indefinitely repeating 33-year or 2820-year arithmetic cycle. This
implementation uses the University of Tehran Calendar Center's published leap
results for SH 1206 through 1498, anchored to its official annual calendars.
The supported interval is SH -61-01-01 through 3177-12-29 (Gregorian
0560-03-20 through 3799-03-19). Within SH 1206–1498, the published table remains
the authority. Outside it, Borkowski's finite break-year calculation supplies
leap years; these calculated dates are not guaranteed official historical or
future civil dates. Dates beyond the calculation range throw `RangeError`.

`minimumOfficialYear`, `maximumOfficialYear`, and `hasOfficialCalendarData`
identify the published-data interval separately from the supported range.
The [calculation model](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm)
includes uncertainty for distant dates; implementations using other models,
including `Intl`, may differ after Gregorian 2256.

The first six months contain 31 days, the next five contain 30, and Esfand has
29 or 30 according to the published data or calculation model. Gregorian conversion, UTC/local
behavior, parsing, epoch constructors, arithmetic, equality, hashing, and
overflow normalization preserve the true native `DateTime` instant at
microsecond precision.

The official-source decision, a discrepancy found in one source PDF, exact
data hashes, and exhaustive validation method are documented in
[`PERSIAN_CALENDAR_VALIDATION.md`](PERSIAN_CALENDAR_VALIDATION.md).

### Hijri Calendar (Umm al-Qura)

The Hijri calendar is lunar and has 12 months. This implementation uses the
published **Umm al-Qura** month data used by Unicode ICU and OpenJDK, rather
than the repeating 30-year arithmetic Islamic calendar. The verified range is
AH 1300-01-01 through AH 1600-12-30 (Gregorian 1882-11-12 through
2174-11-25). Dates outside that finite range throw `RangeError`; the
implementation never silently falls back to a different Hijri calendar.

Month lengths and 354/355-day years come directly from the Umm al-Qura data.
As with `PersianDateTime`, `minimumOfficialYear`, `maximumOfficialYear`, and
`hasOfficialCalendarData` describe published-data coverage. Every supported
Hijri year uses the table, so its official-data bounds equal its supported bounds.
Gregorian conversion, UTC/local behavior, parsing, epoch constructors,
arithmetic, and overflow normalization all preserve the native `DateTime`
instant at microsecond precision.

Data provenance and the Unicode license notice are recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
Source checks, exhaustive coverage, and differences from `hijri` 3.0.1 are
documented in [`HIJRI_CALENDAR_VALIDATION.md`](HIJRI_CALENDAR_VALIDATION.md).

## Contributions

See [CALENDAR_TESTING.md](CALENDAR_TESTING.md) for exhaustive calendar coverage,
critical regression cases, and the UTC/Tehran/New York CI test matrix.

Contributions are welcome! If you have suggestions, fixes, or new features, please submit a pull
request or open an issue on GitHub.

## Licence

This project is licensed under the BSD 3-Clause License. See the [LICENSE](https://github.com/ali-you/general-datetime-package/blob/main/LICENSE) file for details.
