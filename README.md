# General DateTime

Gregorian, Persian (Jalali), and Hijri (Umm al-Qura) chronology for Dart and
Flutter. Convert exact instants, work with calendar fields and all-day dates,
serialize values safely, and use Persian or Hijri calendars in Material date
pickers.

[![pub.dev](https://img.shields.io/pub/v/general_datetime.svg)](https://pub.dev/packages/general_datetime)
[![Calendar CI](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml/badge.svg)](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml)

## Contents

- [Choose a package](#choose-a-package)
- [Installation and local setup](#installation-and-local-setup)
- [Quick start](#quick-start)
- [Supported calendars and bounds](#supported-calendars-and-bounds)
- [Construction, validation, and parsing](#construction-validation-and-parsing)
- [Instants, arithmetic, and timezones](#instants-arithmetic-and-timezones)
- [Safe field operations](#safe-field-operations)
- [Civil dates, periods, ranges, and weeks](#civil-dates-periods-ranges-and-weeks)
- [Calendar system API](#calendar-system-api)
- [JSON storage](#json-storage)
- [Flutter Material pickers](#flutter-material-pickers)
- [Formatting, scheduling, and examples](#formatting-scheduling-and-examples)
- [Testing and release checks](#development-and-testing)

## Choose a package

| Package | Role | Requires Flutter |
| --- | --- | --- |
| `general_datetime` | Chronology core re-exports and Material calendar/localization delegates | Yes |
| [`general_datetime_core`](packages/general_datetime_core/README.md) | Calendar date-times, strict calendar systems, civil dates, and JSON storage | No |
| `general_date_format` | Localized Persian/Hijri formatting and multilingual Material adapters, in the neighboring repository | Yes |
| `general_date_format_core` | Localized Persian/Hijri formatting and parsing for servers and CLIs | No |
| [`general_calendar_schedule`](packages/general_calendar_schedule/README.md) | Optional named-zone resolution, recurrence, and business-day policies | No |

The Flutter wrapper re-exports the core's exact classes. A `PersianDateTime`
created through either import has the same runtime type; there are no competing
copies of the chronology engine. The scheduling package is separate and has
`publish_to: none`.

Use these public libraries:

```dart
import 'package:general_datetime/general_datetime.dart'; // Chronology core APIs.
// Flutter adapters use separate public libraries:
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';
```

For pure Dart, replace those imports with:

```dart
import 'package:general_datetime_core/general_datetime_core.dart';
```

## Installation and local setup

The checked-in manifests target `general_datetime` **3.0.0** and
`general_datetime_core` **1.0.0**. The Flutter wrapper requires Dart
`>=3.4.0 <4.0.0` and Flutter `>=3.32.0`; the core requires only Dart
`>=3.4.0 <4.0.0`.

When those matching releases are available from your package source:

```yaml
dependencies:
  general_datetime: ^3.0.0
```

## Quick start

```dart
import 'package:general_datetime/general_datetime.dart';

void main() {
  final native = DateTime.utc(2024, 3, 20, 12, 34, 56, 789, 123);
  final persian = PersianDateTime.fromDateTime(native);
  final hijri = HijriDateTime.fromDateTime(native);

  print(persian.toIso8601String()); // 1403-01-01T12:34:56.789123Z
  print(hijri.toIso8601String()); // 1445-09-10T12:34:56.789123Z
  print(persian.toDateTime().toIso8601String());
  // 2024-03-20T12:34:56.789123Z

  print(persian.microsecondsSinceEpoch == native.microsecondsSinceEpoch); // true
  print(hijri.isAtSameMomentAs(persian)); // true
}
```

`PersianDateTime` and `HijriDateTime` extend `DateTime` and implement
`GeneralDateTimeInterface`. Their year/month/day getters use their own
calendar, while their epoch values and duration operations describe the same
native instant. Native Gregorian `DateTime` remains the Gregorian date-time
implementation.

## Supported calendars and bounds

| Calendar | Calendar fields, inclusive | Gregorian UTC civil-day bounds | Policy |
| --- | --- | --- | --- |
| Gregorian | Native Dart date bounds | -271821-04-20 through 275760-09-13 | Proleptic Gregorian |
| Persian | SH -61-01-01 through 3177-12-29 | 0560-03-20 through 3799-03-19 | Published Tehran leap data for SH 1206–1498; finite Borkowski calculation elsewhere |
| Umm al-Qura | AH 1300-01-01 through 1600-12-30 | 1882-11-12 through 2174-11-25 | Finite verified month table; no arithmetic fallback |

Persian years include zero. Calculated Persian dates outside SH 1206–1498 are
not a guarantee of official historical usage or future astronomical decisions.
Umm al-Qura is one specific Hijri chronology; observational/religious calendars
and other Islamic algorithms may produce different dates.

Both calendar date-time classes expose:

| API | Meaning |
| --- | --- |
| `minimumYear`, `maximumYear` | Supported calculation/table year bounds |
| `minimumOfficialYear`, `maximumOfficialYear` | Published-data coverage |
| `minimumGregorianDate`, `maximumGregorianDate` | First/last supported Gregorian day, at UTC midnight |
| `hasOfficialCalendarData` | Whether the instance's year has published data |
| `isSupportedDateTime(native)` | Whether the input's Gregorian wall date is supported in its UTC/local mode |
| `isValidDate(year, month, day)` | Strict calendar-field validity, without normalization |
| `daysInMonth(year, month)` | Month length; invalid month/year throws `RangeError` |

Range checks apply to the resulting calendar wall date. Converting UTC/local
mode or adding a duration near an endpoint can throw `RangeError` if the new
wall date falls outside that calendar's bounds.

Data sources, hashes, independent fixtures, and source decisions are documented
in [Persian validation](PERSIAN_CALENDAR_VALIDATION.md) and
[Umm al-Qura validation](HIJRI_CALENDAR_VALIDATION.md).

## Construction, validation, and parsing

Both classes provide the same constructor family:

| Constructor | Behavior |
| --- | --- |
| `PersianDateTime(year, [month, day, hour, minute, second, millisecond, microsecond])` | Local calendar wall fields |
| `PersianDateTime.utc(...)` | UTC calendar wall fields |
| `PersianDateTime.fromDateTime(value)` | Same instant and UTC/local mode, with Persian fields |
| `PersianDateTime.now()` | Current local instant |
| `PersianDateTime.timestamp()` | Current UTC instant |
| `fromSecondsSinceEpoch`, `fromMillisecondsSinceEpoch`, `fromMicrosecondsSinceEpoch` | Epoch constructors; named `isUtc` defaults to `false` |
| `parse(text)`, `tryParse(text)` | Calendar-specific ISO-like input |

Replace `PersianDateTime` with `HijriDateTime` for the Hijri equivalents.
Optional month/day default to 1; all optional clock fields default to 0.
`fromDateTime` also accepts another supported calendar subclass and preserves
its epoch rather than reinterpreting its exposed fields.
`GeneralDateTimeInterface.now<PersianDateTime>()` and the Hijri equivalent
provide generic local clocks for those two registered types; other type
arguments throw `TypeError`.

Constructors normalize overflow and negative components in the selected
calendar:

```dart
final nextYear = PersianDateTime.utc(1403, 13, 1); // 1404-01-01
final nextDay = HijriDateTime.utc(1445, 9, 10, 25); // 1445-09-11 01:00
final valid = PersianDateTime.isValidDate(1403, 13, 1); // false
```

Normalization uses exact arithmetic before narrowing to supported values.
Extreme inputs cannot wrap into ordinary dates; unsupported results throw
`RangeError`. Exact cancellation that produces a supported date remains valid.
For strict construction, use `CalendarSystems.forId(...).construct(...)` or
`CalendarDate` rather than a normalizing date-time constructor.

### Calendar-specific ISO-like parsing

```dart
final value = PersianDateTime.parse('1403-01-01T12:34:56.789123Z');
final shifted = HijriDateTime.parse('1445-09-10T03:30:00+03:30');
// shifted is UTC, with clock time 00:00.
final invalid = HijriDateTime.tryParse('not a date'); // null
```

These parsers read the receiving class's calendar, use ASCII digits, normalize
calendar/clock overflow, and truncate fractions beyond six digits. `Z` or a
numeric offset produces UTC; an omitted zone produces local time. Offsets are
applied before the final supported-range check. Invalid syntax/offsets and
unsupported results throw `FormatException`; `tryParse` returns `null` for
those failures. These are permissive constructors, not strict input validators.
For localized patterns and strict user input, use `general_date_format`.

## Instants, arithmetic, and timezones

```dart
final start = PersianDateTime.utc(1403, 1, 1, 12);
final later = start.add(const Duration(hours: 36));
print(later.difference(start).inHours); // 36
print(later.subtract(const Duration(hours: 36)) == start); // true
final local = start.toLocal();
final utcAgain = local.toUtc(); // Same instant as start.
```

`add`, `subtract`, `difference`, `compareTo`, `isBefore`, `isAfter`, and
`isAtSameMomentAs` operate on instants. Equality/hash keys follow native
`DateTime` behavior: calendar field equality is not required for the same
instant and UTC/local representation. Use `isAtSameMomentAs` when comparing
across UTC/local modes.

A `Duration(days: 1)` is 24 elapsed hours. It need not land at the same wall
clock time across DST. Use civil-date arithmetic for all-day navigation.

`toDateTime()` returns a native Gregorian value preserving epoch microseconds
and UTC/local mode. `toUtc()` and `toLocal()` preserve the instant and retain
the calendar subclass. Local timezone names/offsets and DST behavior come from
the operating system; date-time instances do not retain an IANA timezone ID.
Do not assume a named-zone `TZDateTime` keeps its named-zone semantics when
converted to these classes.

`secondsSinceEpoch` rounds down to the containing Unix second, directly from
microseconds. For example, -1 microsecond returns -1 second; -1000001 returns
-2 seconds. Millisecond/microsecond epoch getters retain native behavior.
Use microseconds or `CalendarInstant` storage when fractions matter.

Useful instance fields include `name`, `monthLength`, `yearLength`,
`isLeapYear`, `dayOfYear`, `julianDay`, and `hasOfficialCalendarData`.
`weekday` always uses Dart's Monday=1 through Sunday=7 convention.

## Safe field operations

Calendar date-times expose custom fields through the `DateTime` interface.
Dart's `DateTime.copyWith` extension and Flutter's Gregorian `DateUtils`
helpers can reconstruct the wrong calendar from those fields. Use the package's
helpers when the variable is statically typed `DateTime`:

```dart
DateTime selected = PersianDateTime.utc(1403, 1, 1, 12, 30, 0, 123, 456);
final next = CalendarDateUtils.copyWith(selected, day: 2);
// PersianDateTime, 1403-01-02, with clock fields and UTC preserved.
final midnight = CalendarDateUtils.dateOnly(selected);
// PersianDateTime.utc(1403, 1, 1).
final native = CalendarDateUtils.toGregorian(selected);
// DateTime.utc(2024, 3, 20, 12, 30, 0, 123, 456).
```

`copyWith` accepts all date/clock fields and `isUtc`, retaining omitted fields.
It uses the input calendar's normalization and range checks. The concrete
classes' own `copyWith` is also safe when called through their concrete static
type. Native Gregorian values remain native; unregistered calendar interfaces
throw `UnsupportedError` for field operations.

Changing `isUtc` through `copyWith` reinterprets wall fields. To preserve the
instant, call `toUtc()`/`toLocal()` instead. `dateOnly` preserves UTC/local mode
and is still a date-time: local DST rules may normalize a nonexistent midnight.
For timezone-free dates use `CalendarDate`; for picker normalization use the
matching calendar delegate.

## Civil dates, periods, ranges, and weeks

`CalendarDate` is an immutable, strictly validated calendar date without a
clock or timezone. Its calendar identifiers are `CalendarId.gregory`,
`CalendarId.persian`, and `CalendarId.islamicUmalqura`.

```dart
final date = CalendarDate(
  calendar: CalendarId.persian, year: 1403, month: 6, day: 31,
);
final tomorrow = date.addDays(1); // 1403-07-01
final clamped = date.addMonths(1); // 1403-07-30
final carried = date.addMonths(1, policy: CalendarOverflow.overflow);
// 1403-08-01
final gregorian = date.toCalendar(CalendarId.gregory);
final record = date.toRecord(); // CalendarDateRecord for JSON storage.
```

`addMonths` and `addYears` offer explicit missing-day policies:

| Policy | Result when the destination lacks the original day |
| --- | --- |
| `CalendarOverflow.clamp` (default) | Last valid day in the destination month |
| `CalendarOverflow.reject` | `ArgumentError` |
| `CalendarOverflow.overflow` | Carry excess days into the following month |

Clamping is not reversible. Repeated monthly recurrences should retain the
original requested date instead of repeatedly adding to a clamped result.
Operations outside supported bounds fail explicitly.

`CalendarDate.fromDateTime(value)` extracts the input's calendar wall date and
discards its clock/mode. It does not perform a timezone conversion.
`fromRecord` restores a stored civil date. `gregorianDay` is UTC midnight used
as a civil-day coordinate, not an event timestamp; `dayIndex`, `weekday`, and
`hasPublishedData` expose day position and calendar coverage.

Civil-date equality/hash keys include the calendar tag. `compareTo`,
`isSameCivilDay`, and `daysUntil` compare civil-day positions, so differently
tagged dates can compare as zero while remaining unequal.

```dart
final start = CalendarDate(
  calendar: CalendarId.gregory, year: 2021, month: 1, day: 1,
);
final range = CalendarDateRange(start, start.addDays(7));
print(range.dayCount); // 7
print(range.contains(start.addDays(7))); // false: the end is excluded.
print(CalendarDateRange.inclusiveDayCount(start, start.addDays(7))); // 8
print(const CalendarWeekRules().weekOfYear(start)); // (year: 2020, week: 53)
```

`CalendarWeekRules(firstWeekday: ..., minimumDays: ...)` supports explicit week
starts and first-week thresholds from 1–7. Defaults match ISO rules for the
Gregorian calendar; on Persian/Hijri dates the week-year follows that calendar.
`startOfWeek` and calculations needing an adjacent year can fail at calendar
bounds.

## Calendar system API

Use `CalendarSystems.gregorian`, `.persian`, `.ummAlQura`, or
`CalendarSystems.forId(id)` for strict operations without switching on classes:

```dart
final system = CalendarSystems.forId(CalendarId.persian);
final value = system.construct(1403, 1, 1, hour: 12); // UTC by default.
final day = system.toGregorianDay(1403, 1, 1); // 2024-03-20 UTC midnight.
final fields = system.fromGregorianDay(DateTime.utc(2024, 3, 20));
// (year: 1403, month: 1, day: 1)
```

The interface includes validity, month/year lengths, `minimumDate`,
`maximumDate`, `hasPublishedData(year)`, `dataRevision`, and `calculationPolicy`.
`construct` validates fields instead of normalizing them and rejects local
wall times that DST changes during construction. `fromInstant(value,
 isUtc: ...)` converts an exact instant with the requested mode (default UTC).

`fromGregorianDay` requires native Gregorian fields and ignores their clock;
calendar subclasses must use `fromInstant` instead. The built-in registry is
closed. Implementing `CalendarSystem` or `GeneralDateTimeInterface` does not
register a new calendar for field helpers, formatting, or version-1 storage.

## JSON storage

Choose the record that matches your domain:

| Value | Record | Required fields | Optional fields |
| --- | --- | --- | --- |
| Timed event | `CalendarInstant` | `version: 1`, `kind: "instant"`, `timestamp`, `calendar` | `timeZone` |
| All-day calendar date | `CalendarDateRecord` | `version: 1`, `kind: "calendar-date"`, `calendar`, integer `year`, `month`, `day` | None |

Identifiers are `gregory`, `persian`, and `islamic-umalqura`, available through
`CalendarId.identifier`. Other Islamic algorithms are not aliases for Umm al-Qura.

```dart
import 'dart:convert';
import 'package:general_datetime/general_datetime.dart';

void main() {
  final date = PersianDateTime.utc(1403, 1, 1, 12, 34, 56, 789, 123);
  final stored = jsonEncode(
    CalendarInstant.fromDateTime(date, timeZone: 'Asia/Tehran'),
  );
  final restored = CalendarInstant.fromJson(jsonDecode(stored));
  print(restored.instant.toIso8601String()); // 2024-03-20T12:34:56.789123Z

  final allDay = CalendarDateRecord(
    calendar: CalendarId.persian, year: 1403, month: 1, day: 1,
  );
  final restoredDay = CalendarDateRecord.fromJson(jsonDecode(jsonEncode(allDay)));
  print(CalendarDate.fromRecord(restoredDay)); // persian:1403-01-01
}
```

The timestamp is authoritative and always decoded as native Gregorian UTC.
The preferred calendar is metadata; display conversion is explicit. Optional
`timeZone` is a nonempty trimmed string retained as opaque metadata. It is not
validated against a zone database and does not apply an offset. Input local/UTC
mode is not persisted.

Timestamp syntax is `YYYY-MM-DDTHH:mm:ss[.fraction]Z`, with Gregorian years
0000–9999 and at most six fractional digits. Encoder output uses three or six
fractional digits. Decoding rejects offsets, missing seconds, leap seconds,
excess precision, invalid/overflowing fields, and annotations. All-day records
store only strictly validated fields, including signed Persian years, within
the chosen calendar's bounds. `fromDateTime` extracts wall fields without
converting them.

Both decoders throw `FormatException` for missing/unknown keys, wrong types,
unknown identifiers, unsupported versions, or invalid values. Direct invalid
record construction throws `ArgumentError`; encoding unregistered calendars
throws `UnsupportedError`. Optional `timeZone` must be omitted rather than
provided as `null`.

**Calendar-specific `toString()`/`toIso8601String()` output is not a generic
Gregorian timestamp.** `toUtc()` still returns a calendar subclass. For a
timestamp-only API, use:

```dart
final timestamp = CalendarDateUtils.toGregorian(date).toUtc().toIso8601String();
```

Do not represent an all-day calendar date by an implicit midnight timestamp.

## Flutter Material pickers

A picker needs both a calendar delegate (date arithmetic) and matching
`MaterialLocalizations` (date labels and input parsing).

| Calendar | Arithmetic delegate | Built-in English localization |
| --- | --- | --- |
| Persian | `PersianCalendarDelegate` | `DefaultPersianCalendarMaterialLocalizations.delegate` |
| Umm al-Qura | `HijriCalendarDelegate` | `DefaultHijriCalendarMaterialLocalizations.delegate` |

The built-in localizations support English (`en`) only and use the legacy
`dd/mm/yyyy` compact input format with ASCII digits. For translated labels,
locale-specific date order, RTL languages, and native digits, use the Material
localizations from `general_date_format`.

### Complete Persian picker example

```dart
import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';

void main() => runApp(MaterialApp(
  localizationsDelegates: const [
    DefaultPersianCalendarMaterialLocalizations.delegate,
  ],
  home: Scaffold(
    body: CalendarDatePicker(
      initialDate: PersianDateTime(1403, 1, 1),
      firstDate: PersianDateTime(1400),
      lastDate: PersianDateTime(1410, 12, 29),
      calendarDelegate: const PersianCalendarDelegate(),
      onDateChanged: (DateTime selected) {
        debugPrint(CalendarDate.fromDateTime(selected).toString());
      },
    ),
  ),
));
```

For Hijri, replace all calendar date values, the arithmetic delegate, and the
localization delegate with the corresponding Hijri types.

Every date argument to these delegates must have the matching runtime type,
including comparisons, range endpoints, and non-null parser results.
Incompatible dates throw `ArgumentError`, even if they describe the same
instant or have the same numeric fields. Explicitly convert external Gregorian
instants with the calendar's `fromDateTime` factory first. Invalid compact text
returns `null`; a parser returning another calendar is a configuration error.

The delegates use local calendar wall dates for picker normalization/navigation.
Date labels, input help, and parsing are forwarded to the ambient localization.
When an app uses several calendar types, keep its global localizations and
scope each picker with `Localizations.override`; avoid installing competing
Material delegates in one scope. Flutter uses the first supported Material
localization delegate in that scope.

### Range selection at supported bounds

Use `rangePickerDelegate` with Flutter's `showDateRangePicker` or
`DateRangePickerDialog`, together with matching calendar localizations:

```dart
final range = await showDateRangePicker(
  context: context,
  firstDate: PersianDateTime(PersianDateTime.minimumYear),
  lastDate: PersianDateTime(PersianDateTime.minimumYear, 2, 20),
  currentDate: PersianDateTime(PersianDateTime.minimumYear),
  calendarDelegate: const PersianCalendarDelegate().rangePickerDelegate,
);
```

For Umm al-Qura, use `const HijriCalendarDelegate().rangePickerDelegate` and
matching Hijri dates. Flutter probes empty leading cells and adjacent keyboard
targets before checking the picker's bounds. The adapter supplies native
comparison dates for those probes; selectable dates and returned range endpoints
remain supported calendar objects. Use the ordinary delegate for general date
arithmetic and single-date pickers.

### Standalone year selection

Use Flutter's `YearPicker` and supply a matching `currentDate`. Its native
default clock is Gregorian even with a custom calendar delegate:

```dart
Widget persianYears(BuildContext context, ValueChanged<DateTime> onChanged) {
  return Localizations.override(
    context: context,
    delegates: const [DefaultPersianCalendarMaterialLocalizations.delegate],
    child: YearPicker(
      firstDate: PersianDateTime(1380),
      lastDate: PersianDateTime(1450, 12, 29),
      selectedDate: PersianDateTime(1403, 1, 1),
      currentDate: PersianDateTime.now(),
      calendarDelegate: const PersianCalendarDelegate(),
      onChanged: onChanged,
    ),
  );
}
```

`CalendarDatePicker` already defaults its current date through the calendar
delegate. This package exports no `CalendarYearPicker` wrapper.

## Formatting, scheduling, and examples

Use the neighboring `general_date_format` / `general_date_format_core`
packages for localized patterns, names, digits, and strict parsing. Chronology
ISO-like output is intended for its matching calendar parser.

The optional [`general_calendar_schedule`](packages/general_calendar_schedule/README.md)
package provides initialized IANA zone providers, explicit missing/repeated
wall-time policies, bounded daily/weekly/monthly/yearly recurrences, exclusions,
moved exceptions, business days, and a reminder-delivery interface. It does not
supply an ICS/RRULE importer, automatic holiday data, or notification delivery.
It depends on `timezone`; the chronology core has no zone dependency.

- [Picker example](example/README.md): three calendar pickers with separate scopes.
- [Calendar application demo](apps/calendar_demo/README.md): month/week/day/agenda
  event views, calendar switching, named zones, and selection/rescheduling.
- [Pure Dart core](packages/general_datetime_core/README.md): CLI example and
  Flutter-free setup.

## Development and testing

After resolving local dependencies, run from this repository:

```sh
flutter analyze
flutter test
flutter test test/unit/calendar_critical_test.dart test/unit/calendar_picker_critical_test.dart
dart format --output=none --set-exit-if-changed lib test example/lib
```

Run `dart analyze` and `dart test` inside the chronology core and scheduling
package (resolve each package's dependencies first). Run `flutter test` in
`apps/calendar_demo`. Both Dart cores include compilable CLI examples.

Tests compare all 1,183,020 supported Persian days and all 106,665 Umm al-Qura
days against independent fixtures. Regressions cover leap/month boundaries,
normalization and integer overflow, negative epochs, fractions, UTC/local/DST,
equality/hash keys, field helpers, strict serialization, delegate guards, and
picker input/navigation.

Local verification on **2026-10-05**, using Flutter 3.47.5 / Dart 3.13.4:

| Suite | Passed |
| --- | ---: |
| Flutter chronology/pickers | 289 |
| Standalone chronology core | 20 |
| Scheduling package | 6 |
| Calendar demo | 8 |

Analysis and format checks passed. The core CLI compiled and ran, and explicit
historical Tehran 23/25-hour assertions passed with:

```sh
flutter test --dart-define=CALENDAR_TEST_TZ=Asia/Tehran test/unit/calendar_critical_test.dart
```

CI is configured for minimum/current SDKs and UTC/Tehran/New York Linux jobs;
source peers are pinned in `.github/calendar_pair.json`. Windows local tests
use the OS timezone. Browser JavaScript/Wasm, Android/iOS, minimum SDK execution,
the full process-timezone matrix, and hosted dependency resolution were not
certified by that local run. Coverage percentages were not recalculated.

Release dependency order is: `general_datetime_core` first, then
`general_datetime` and `general_date_format_core`, then `general_date_format`.
Before publishing wrappers, resolve and test the matching hosted core versions
without development overrides. Local path success does not certify hosted
resolution.

## Contributions and license

See [CHANGELOG.md](CHANGELOG.md) for release changes. Open issues and pull
requests on the [repository](https://github.com/ali-you/general-date-package).
The code uses the BSD 3-Clause [LICENSE](LICENSE); calendar data attribution and
the Unicode license are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
