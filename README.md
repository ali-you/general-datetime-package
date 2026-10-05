# General DateTime

<a href="https://pub.dev/packages/general_datetime">
   <img src="https://img.shields.io/pub/v/general_datetime?label=pub.dev&labelColor=333940&logo=dart">
</a>
<a href="https://github.com/ali-you/general-date-package/issues">
   <img alt="Issues" src="https://img.shields.io/github/issues/ali-you/general-date-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-date-package/issues?q=is%3Aclosed">
   <img alt="Issues" src="https://img.shields.io/github/issues-closed/ali-you/general-date-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-date-package/pulls">
   <img alt="GitHub Pull Requests" src="https://badgen.net/github/prs/ali-you/general-date-package" />
</a>
<a href="https://github.com/ali-you/general-date-package/blob/main/LICENSE" rel="ugc">
   <img src="https://img.shields.io/github/license/ali-you/general-date-package?color=#007A88&amp;labelColor=333940;" alt="GitHub">
</a>
<a href="https://github.com/ali-you/general-date-package">
   <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ali-you/general-date-package">
</a>

![Flutter CI](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml/badge.svg)

Gregorian, Persian (Jalali), and Hijri (Umm al-Qura) chronology with exact
instant conversion, civil-date arithmetic, JSON storage, and Flutter Material
date-picker adapters. Requires Dart 3.4 or newer and Flutter 3.32 or newer.
For servers and command-line applications, use the
[`general_datetime_core`](packages/general_datetime_core/README.md) package
without Flutter.

Persian and Hijri constructors normalize fields using exact arithmetic before
checking the supported calendar bounds. Extreme inputs that would previously
wrap into an ordinary date now throw `RangeError`. Components may still cancel
to a valid result, and ordinary normalization such as hour `25` is unchanged.
The same policy applies to `copyWith` and `CalendarDateUtils.copyWith`.

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
  on elapsed instants. Use `CalendarDate` for timezone-free civil-day and
  month/year arithmetic with an explicit overflow policy.

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

### Pure Dart and Flutter package boundaries

The calendar engine now lives in the independent
[`general_datetime_core`](packages/general_datetime_core/README.md) package.
Backend and CLI projects can depend on that package using only the Dart SDK.
Localized Dart formatting lives in `general_date_format_core` in the neighboring
formatter repository. Both pure packages are prepared as version 1.0.0 and are
not yet published.

This `general_datetime` package remains the Flutter integration wrapper. Its
existing public date imports re-export the core's exact classes; picker
delegates and default Material localizations retain their existing libraries.
The calculations and data tables have one implementation shared by both layers.

For local Flutter development, copy `pubspec_overrides.yaml.example` to
`pubspec_overrides.yaml` before `flutter pub get`. Copy the example's template
as well when running it. Overrides in dependencies are not inherited by apps;
an external app must override `general_datetime_core` to this repository's
`packages/general_datetime_core` directory until the core is published.

Publish `general_datetime_core` 1.0.0 first, then `general_datetime` 3.0.0.
The formatting core also requires the new Dart chronology core. Verify hosted
resolution without local overrides before releasing either Flutter wrapper.

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
preserve the instant. Material pickers use the matching delegate's local-date
policy. Use `CalendarDate` for timezone-free dates and explicit month/year
arithmetic, as shown in [Application calendar API](#application-calendar-api).

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
local value, or resolve zone offsets/DST. Named-zone wall-clock schedules and
recurrences use the optional
[`general_calendar_schedule`](packages/general_calendar_schedule/README.md)
package and its explicit DST policies.

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
midnight timestamps. Use `CalendarDate` for civil-date arithmetic.

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

`secondsSinceEpoch` is the Unix second containing the instant, rounded down
directly from `microsecondsSinceEpoch`, independently of UTC/local mode.
For example, -1 microsecond and -999999 microseconds both return -1 second;
-1000001 microseconds returns -2 seconds. Exact integer seconds are unchanged.
This replaces the previous mixed millisecond-rounding/second-truncation behavior
for negative fractions. Reconstructing from that integer returns the beginning
of the containing second. Use microseconds or `CalendarInstant` storage when
fractional precision must be retained.

### Generic Current Time

Use the generic interface to get the current time for any supported type:

```dart
var nowPersian = GeneralDateTimeInterface.now<PersianDateTime>();
var nowHijri = GeneralDateTimeInterface.now<HijriDateTime>();
```

## Customization

Application adapters can implement `CalendarSystem`. The built-in registry,
formatter and version-1 serialization support Gregorian, Persian and Umm al-Qura;
implementing an interface alone does not register another calendar.

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

## Application calendar API

`CalendarSystems.forId(CalendarId.persian)` exposes strict construction,
validity, supported/published bounds, calendar fields and civil-day conversion.
The built-in registry supports Gregorian, Persian and Umm al-Qura only; an
implementation of `CalendarSystem` does not automatically register formatter
or version-1 storage support.

Use `CalendarDate` for all-day/domain values:

```dart
final date = CalendarDate(
  calendar: CalendarId.persian, year: 1403, month: 6, day: 31);
final next = date.addMonths(1); // 1403-07-30: default clamping
final civilTomorrow = date.addDays(1);
final record = next.toRecord(); // Existing version-1 civil storage schema
```

`CalendarOverflow.reject` rejects absent destination days; `overflow` carries
them into the following month. Clamping is not reversible. Recurrences must
retain the original requested day. `CalendarDateRange` is half-open; use
`inclusiveDayCount` explicitly when both endpoints are included. Tagged equality
includes the calendar; `isSameCivilDay`/`compareTo` compare civil-day position.

`CalendarWeekRules` supplies explicit weekday/minimum-first-week-day policies
for the selected calendar, including its week-year. Calculations that require
calendar data outside supported bounds fail explicitly.

Named-zone resolution and recurrence live in the independent optional
[`general_calendar_schedule`](packages/general_calendar_schedule/README.md)
package. The runnable [`calendar_demo`](apps/calendar_demo/README.md) owns event
views/controller state. Neither layer adds dependencies to the chronology core.

## Development and testing

From the repository root, resolve the unpublished core through the tracked
override template, then run:

```powershell
Copy-Item pubspec_overrides.yaml.example pubspec_overrides.yaml
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test example/lib
```

For the [picker example](example/README.md), also copy
`example/pubspec_overrides.yaml.example` to `example/pubspec_overrides.yaml`,
then run `flutter pub get` and `flutter run` from `example`.
The [calendar demo](apps/calendar_demo/README.md) documents its own setup.

Run the critical chronology and picker suites with:

```sh
flutter test test/unit/calendar_critical_test.dart test/unit/calendar_picker_critical_test.dart
```

From `packages/general_datetime_core`, run `dart pub get`, `dart analyze`,
and `dart test`. Its CLI example also supports `dart compile exe`.
From `packages/general_calendar_schedule`, copy its override template before
running the same Dart checks. From `apps/calendar_demo`, run `flutter test`.

The suites compare all 1,183,020 supported Persian days and all 106,665
Umm al-Qura days against independent fixtures. Critical regressions cover
constructor/epoch overflow, negative epochs, microseconds, leap/month bounds,
UTC/local conversion, equality/hash keys, strict JSON storage, runtime delegate
guards, and picker navigation/input. Source provenance and calendar-specific
validation are retained in the linked [Persian](PERSIAN_CALENDAR_VALIDATION.md)
and [Umm al-Qura](HIJRI_CALENDAR_VALIDATION.md) documents.

Local verification on 2026-10-05 used Flutter 3.47.5 and Dart 3.13.4:

| Suite | Tests passed |
| --- | ---: |
| Flutter chronology and pickers | 289 |
| Standalone chronology core | 20 |
| Named-zone scheduling | 6 |
| Calendar demo | 8 |

Static analysis and format checks passed. The compiled core CLI preserved
microseconds through JSON storage. Historical Tehran 23/25-hour DST assertions
also passed with `--dart-define=CALENDAR_TEST_TZ=Asia/Tehran`.

CI is configured for UTC, Tehran, and New York on Linux, with minimum/current
SDK jobs and the formatter peer pinned in `.github/calendar_pair.json`.
Windows tests use the operating system's timezone; setting `TZ` alone does not
verify another process timezone. Browser JavaScript/Wasm, Android/iOS, minimum
SDK execution, the full timezone matrix, and hosted dependency resolution were
not verified in that local run. Coverage percentages were not recalculated.

## Contributions and license

Open an issue or pull request on the
[repository](https://github.com/ali-you/general-date-package).
This project uses the BSD 3-Clause [LICENSE](LICENSE). Calendar data attribution
and the Unicode license are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
