# General DateTime Core

Pure Dart date and time operations for Gregorian, Solar Hijri (Persian), and
Umm al-Qura Hijri calendars. Use it in servers, command-line tools, web apps,
and Flutter projects without depending on the Flutter SDK.

Requires **Dart 3.4 or later** and has **no runtime dependencies**.

## Features

- Convert calendars while preserving the instant and microsecond precision.
- Use `PersianDateTime` and `HijriDateTime` with the `DateTime` interface.
- Validate fields, inspect month lengths, and query calendar bounds and metadata.
- Work with immutable civil dates, date ranges, and configurable week rules.
- Choose clamp, reject, or overflow policies for month and year arithmetic.
- Serialize instants and civil dates with explicit calendar identifiers.
- Use UTC or the host's local timezone.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  general_datetime_core: ^1.0.0
```

Run `dart pub get`, or `flutter pub get` in a Flutter project.
Version 1.0.0 is published and is re-exported by `general_datetime` 4.0.0.
For development against a local core checkout, you can use a path dependency:

```yaml
dependencies:
  general_datetime_core:
    path: /path/to/general_date/packages/general_datetime_core
```

All public APIs are available from one import:

```dart
import 'package:general_datetime_core/general_datetime_core.dart';
```

## Quick start

```dart
import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final instant = DateTime.utc(2024, 3, 20, 13, 5, 6, 123, 456);
  final persian = PersianDateTime.fromDateTime(instant);
  final hijri = HijriDateTime.fromDateTime(instant);

  print('${persian.year}/${persian.month}/${persian.day}'); // 1403/1/1
  print('${hijri.year}/${hijri.month}/${hijri.day}'); // 1445/9/10
  print(persian.toDateTime()); // 2024-03-20 13:05:06.123456Z
  print(persian.isAtSameMomentAs(hijri)); // true
}
```

`fromDateTime` preserves epoch microseconds and UTC/local mode, including
when converting directly from another supported calendar date-time.

## Calendar date-times

Construct values from calendar fields, parse calendar strings, or get the
current time:

```dart
final persian = PersianDateTime.utc(1403, 1, 1, 13, 5);
final hijri = HijriDateTime.utc(1445, 9, 10, 13, 5);
final local = PersianDateTime(1403, 1, 1, 13, 5);
final now = PersianDateTime.now();
final parsed = PersianDateTime.parse('1403-01-01T13:05:00Z');

print(persian.monthLength); // 31
print(persian.weekday); // 3 (DateTime.wednesday)
print(persian.add(const Duration(hours: 2)).hour); // 15
print(persian.difference(hijri)); // 0:00:00.000000
print(local.toUtc().isUtc); // true
print(now.year);
print(parsed.isAtSameMomentAs(persian)); // true
```

The constructors normalize overflowing calendar and clock fields, subject to
supported bounds. Use `CalendarSystems.construct` or `CalendarDate` for strict
field validation.

`add`, `subtract`, `difference`, comparisons, and epoch getters operate on the
underlying instant. Adding `Duration(days: 1)` adds 24 elapsed hours; local
DST transitions can change the resulting wall-clock hour. Use
`CalendarDate.addDays` for civil-day arithmetic.

Date-time equality and hashing follow native `DateTime` instant and UTC/local
mode semantics. Use `isAtSameMomentAs` to compare an instant across modes.

### Calendar-safe field helpers

Use `CalendarDateUtils` when a calendar value is statically typed as `DateTime`:

```dart
DateTime value = PersianDateTime.utc(1403, 1, 1, 13, 5);
final next = CalendarDateUtils.copyWith(value, day: 2);
final midnight = CalendarDateUtils.dateOnly(value);
final gregorian = CalendarDateUtils.toGregorian(value);

print(next is PersianDateTime); // true
print(midnight.hour); // 0
print(gregorian); // 2024-03-20 13:05:00.000Z
```

Native `DateTime.copyWith` and Gregorian field helpers reconstruct Gregorian
values from the exposed fields. Use these calendar-safe helpers to preserve
calendar fields, or convert with `toGregorian` before calling external helpers.

Changing `isUtc` through `copyWith` reinterprets wall-clock fields. Use `toUtc`
or `toLocal` to preserve the instant during timezone conversion.
`dateOnly` returns midnight in the input's calendar and UTC/local mode, subject
to native local DST normalization. Use `CalendarDate` for a timezone-free date.

## Civil dates and arithmetic

`CalendarDate` is an immutable, validated year/month/day without a clock or
timezone. Use it for birthdays, holidays, and date-only selections.

```dart
final date = CalendarDate(
  calendar: CalendarId.persian,
  year: 1403,
  month: 1,
  day: 1,
);
final gregorian = date.toCalendar(CalendarId.gregory);

print(gregorian); // gregory:2024-03-20
print(date.addDays(10)); // persian:1403-01-11
print(date.daysUntil(date.addDays(10))); // 10
print(date == gregorian); // false: equality includes the calendar
print(date.isSameCivilDay(gregorian)); // true
```

`CalendarDate.fromDateTime` extracts wall-date fields without converting the
input's timezone. `compareTo` compares civil-day positions across calendars;
two differently tagged dates can compare as zero while remaining unequal.
`gregorianDay` is a UTC-midnight civil-day coordinate, not a timed event.

Choose a policy when the destination month has fewer days:

```dart
final january31 = CalendarDate(
  calendar: CalendarId.gregory,
  year: 2024,
  month: 1,
  day: 31,
);

print(january31.addMonths(1)); // gregory:2024-02-29 (default: clamp)
print(january31.addMonths(1, policy: CalendarOverflow.overflow));
// gregory:2024-03-02

// Throws ArgumentError because February has no day 31:
// january31.addMonths(1, policy: CalendarOverflow.reject);
```

`addYears` accepts the same policies. Clamping is not reversible: retain the
original anchor day when implementing recurring month-end dates. Results
outside the selected calendar's supported range fail explicitly.

### Ranges and week rules

```dart
final start = CalendarDate(
  calendar: CalendarId.persian,
  year: 1403,
  month: 1,
  day: 1,
);
final range = CalendarDateRange(start, start.addDays(7));
print(range.dayCount); // 7
print(range.contains(start)); // true
print(range.contains(range.end)); // false

const rules = CalendarWeekRules(
  firstWeekday: DateTime.saturday,
  minimumDays: 1,
);
print(rules.startOfWeek(start)); // persian:1402-12-26
print(rules.weekOfYear(start)); // (week: 1, year: 1403)
```

Ranges include the start and exclude the end. For an inclusive span, use
`CalendarDateRange.inclusiveDayCount(start, last)`.
Week numbering applies to the date's calendar year. Default rules use Monday
and four minimum days, matching ISO week rules for Gregorian dates. Week
calculations that require dates outside supported bounds can fail.

## Validation and calendar metadata

| Calendar | Registry entry | Storage identifier |
| --- | --- | --- |
| Gregorian | `CalendarSystems.gregorian` | `gregory` |
| Persian | `CalendarSystems.persian` | `persian` |
| Umm al-Qura Hijri | `CalendarSystems.ummAlQura` | `islamic-umalqura` |

```dart
final system = CalendarSystems.persian;
print(system.isValidDate(1403, 1, 31)); // true
print(system.isValidDate(1403, 1, 32)); // false
print(system.daysInMonth(1403, 1)); // 31
print(system.hasPublishedData(1403)); // true

final value = system.construct(1403, 1, 1, hour: 13); // UTC by default
final fields = system.fromGregorianDay(DateTime.utc(2024, 3, 20));
print(fields); // (day: 1, month: 1, year: 1403)
print(value.isUtc); // true
```

Each system exposes `minimumDate`, `maximumDate`, `dataRevision`, and
`calculationPolicy`. `construct` rejects invalid date and clock fields;
with `isUtc: false`, it also rejects wall times normalized by a local DST gap.
`fromInstant` converts an instant to UTC or host-local calendar fields.
`fromGregorianDay` requires a native Gregorian `DateTime` and uses its date
fields. Use `CalendarSystems.forId` to select a built-in calendar by ID.
Implementing `CalendarSystem` does not register a new calendar with storage
or formatting APIs.

## JSON serialization

Use `CalendarInstant` to store a timed event as a native Gregorian UTC timestamp
with its preferred display calendar:

```dart
import 'dart:convert';
import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final date = PersianDateTime.utc(1403, 1, 1, 13, 5, 6, 123, 456);
  final encoded = jsonEncode(CalendarInstant.fromDateTime(date));
  final restored = CalendarInstant.fromJson(jsonDecode(encoded));
  final display = CalendarSystems.forId(restored.calendar)
      .fromInstant(restored.instant);

  print(encoded);
  print(display.year); // 1403
}
```

The instant record has this shape:

```json
{
  "version": 1,
  "kind": "instant",
  "timestamp": "2024-03-20T13:05:06.123456Z",
  "calendar": "persian"
}
```

An optional `timeZone` string can carry application metadata, such as
`Asia/Tehran`. The core does not resolve or validate named timezone rules.
Decoding always returns a native UTC instant; local input mode is not persisted.
Version 1 accepts Gregorian years 0000–9999, seconds, and up to six fractional
digits in UTC timestamps ending in `Z`. Invalid fields, numeric offsets,
unknown keys, unsupported versions, and unsupported calendars are rejected.

Use `CalendarDateRecord` to store a date without time or timezone:

```dart
final date = CalendarDate(
  calendar: CalendarId.persian,
  year: 1403,
  month: 1,
  day: 1,
);
final json = date.toRecord().toJson();
final restored = CalendarDate.fromRecord(CalendarDateRecord.fromJson(json));
print(restored == date); // true
```

```json
{
  "version": 1,
  "kind": "calendar-date",
  "calendar": "persian",
  "year": 1403,
  "month": 1,
  "day": 1
}
```

`PersianDateTime.toIso8601String` and `HijriDateTime.toIso8601String` emit
**calendar fields**; only the matching calendar parser should read them.
For APIs and databases expecting Gregorian timestamps, use `CalendarInstant`
or `value.toDateTime().toUtc().toIso8601String()`.

## Supported ranges and calculation policy

| Calendar | Supported range | Calculation/data policy |
| --- | --- | --- |
| Gregorian | Dart native date bounds: -271821-04-20 through 275760-09-13 | Proleptic Gregorian |
| Persian | SH -61 through 3177, including year zero | Published University of Tehran leap data for SH 1206–1498; finite Borkowski calculation elsewhere |
| Umm al-Qura Hijri | AH 1300 through 1600 | Finite month table derived from Unicode ICU; no fallback outside the table |

Persian dates outside the published table are calculated dates and are not
guaranteed official civil dates. Umm al-Qura dates can differ from
observational or other Islamic calendars.

The date-time classes expose `minimumYear`, `maximumYear`,
`minimumGregorianDate`, `maximumGregorianDate`, `isValidDate`, and
`isSupportedDateTime`. Calendar conversions and arithmetic must stay within
the target calendar's bounds. Instant serialization has the narrower
four-digit Gregorian-year range described above.

The core handles UTC and host-local time. Named timezone resolution,
recurrence scheduling, localized formatting, and UI widgets are outside
this package's API.

## Flutter and formatting integration

The Flutter `general_datetime` package re-exports these core types and adds
Material calendar delegates and default localizations. Shared class identities
allow values to cross between the core and wrapper APIs without conversion.

Use `general_date_format_core` for localized formatting in pure Dart. Named
zone handling in the repository's calendar demo uses the `timezone` package
in the application.

## Source organization

Calendar-specific implementations and data live under `lib/src/calendars`:

| Directory | Contents |
| --- | --- |
| `calendars/gregorian/` | Gregorian calculation helper; Gregorian date-times use Dart's native `DateTime` |
| `calendars/persian/` | `PersianDateTime`, Persian calendar calculation, and Iranian calendar data |
| `calendars/hijri/` | `HijriDateTime`, Umm al-Qura calendar calculation, and month data |
| `shared/` | Common field normalization and parsing constants |

Cross-calendar APIs such as `CalendarDate`, `CalendarSystems`, field helpers,
and serialization remain directly under `lib/src`. Previous date-time paths
retain compatibility exports. The Flutter wrapper references
calendar-specific helpers and data directly in `calendars/`.
Applications should import `package:general_datetime_core/general_datetime_core.dart`.

## Example and development

Run these commands from `packages/general_datetime_core` in a checkout:

```sh
dart pub get
dart analyze
dart test
dart run example/cli.dart
```

The [CLI example](example/cli.dart) demonstrates conversion and JSON storage.
Dart tests cover calendar fixtures, civil arithmetic, serialization, supported
bounds, and the absence of Flutter in the dependency graph. The parent
repository also includes reference tests through the Flutter wrapper.

Validate the release archive before publishing:

```sh
dart pub publish --dry-run
```

Publish the core before packages that depend on its hosted release. See the
[changelog](CHANGELOG.md) for release changes and
[GitHub issues](https://github.com/ali-you/general-date-package/issues) for
bug reports. Include the calendar, input fields, UTC/local mode, and expected
result when reporting a conversion issue.

## License

BSD 3-Clause; see [LICENSE](LICENSE). Unicode ICU data attribution and its
license are included in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
