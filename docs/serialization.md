# Serialization

[Documentation index](README.md)

Use `CalendarInstant` for an event on the timeline and `CalendarDateRecord` for
an all-day calendar date. Both define strict version-1 JSON contracts in
[`calendar_serialization.dart`](../packages/general_datetime_core/lib/src/calendar_serialization.dart).

## Calendar identifiers

| Dart enum | Wire string |
| --- | --- |
| `CalendarId.gregory` | `gregory` |
| `CalendarId.persian` | `persian` |
| `CalendarId.islamicUmalqura` | `islamic-umalqura` |
| `CalendarId.hebrew` | `hebrew` |

Use `CalendarId.identifier` for the wire value. Generic `hijri` or `islamic`
strings are not aliases in this schema.
Hebrew dates retain stable numeric month slots, including leap-only Adar I=6
and Adar/Adar II=7. Older core 1.x decoders reject the new identifier; use
core 2.0.0 or newer. The record schema version remains 1.

## Timed events

```json
{
  "version": 1,
  "kind": "instant",
  "timestamp": "2024-03-20T12:34:56.789123Z",
  "calendar": "persian",
  "timeZone": "Asia/Tehran"
}
```

`version`, `kind`, `timestamp`, and `calendar` are required. `timeZone` is optional.
The timestamp is authoritative native Gregorian UTC; calendar is presentation
metadata. Decoding does not require the timestamp to fit that calendar's display
range, so a later display conversion can fail.

The timestamp grammar is `YYYY-MM-DDTHH:mm:ss[.fraction]Z`: Gregorian years
0000–9999, mandatory seconds, and one to six fractional digits when present.
Encoding emits three or six fractional digits and retains microseconds.
Decoding rejects offsets, leap seconds, invalid/overflowing fields, additional
precision, missing zones, and suffix annotations.

`timeZone` must be a nonempty trimmed string if present. It is opaque metadata;
the core neither resolves its rules nor validates it against a zone database.
Omit it rather than writing `null`. Input local/UTC mode is not persisted.

## All-day dates

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

All six fields are required; there are no optional fields. Year, month, and day
must be integers and valid within the selected chronology's supported interval.
Signed Persian years, including zero, are supported. Clock and zone fields are
not part of a civil-date record.

`CalendarDateRecord.fromDateTime` extracts calendar wall fields and discards the
clock and mode. It does not choose a timezone or convert the instant first.

## Complete round trip

```dart
import 'dart:convert';
import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final event = PersianDateTime.utc(1403, 1, 1, 12, 34, 56, 789, 123);
  final encoded = jsonEncode(
    CalendarInstant.fromDateTime(event, timeZone: 'Asia/Tehran'),
  );
  final decoded = CalendarInstant.fromJson(jsonDecode(encoded));
  assert(decoded.instant.isAtSameMomentAs(event));

  final display = CalendarSystems.forId(decoded.calendar)
      .fromInstant(decoded.instant); // UTC; named zone not applied.
  print(display.toIso8601String()); // 1403-01-01T12:34:56.789123Z

  final civil = CalendarDate(
    calendar: CalendarId.persian, year: 1403, month: 1, day: 1,
  );
  final restored = CalendarDate.fromRecord(
    CalendarDateRecord.fromJson(jsonDecode(jsonEncode(civil.toRecord()))),
  );
  assert(restored == civil);
}
```

Apply named-zone rules in your application if presentation requires them. The
[demo zone layer](../apps/calendar_demo/lib/demo_time_zones.dart) is a reference.

## Failure behavior and API boundaries

| Operation | Failure |
| --- | --- |
| Decode missing/unknown fields, incorrect types, versions, kinds, IDs, or invalid values | `FormatException` |
| Construct an invalid record, out-of-schema timestamp year, or invalid zone metadata | `ArgumentError` |
| Encode an unregistered `GeneralDateTimeInterface` implementation | `UnsupportedError` |

Calendar date-time `toIso8601String()` uses calendar years. Parsing that string
as native Gregorian silently changes its meaning. `toUtc()` alone retains the
calendar subclass. For a timestamp-only service boundary, convert explicitly:

```dart
final timestamp = CalendarDateUtils.toGregorian(event).toUtc().toIso8601String();
```

Choose the strict record decoder for persisted data. The normalizing calendar
`parse` methods are described in [calendar operations](calendar-operations.md).
Unknown record keys are rejected; application fields belong in an outer envelope.

Regression references:
[`calendar_serialization_test.dart`](../test/unit/calendar_serialization_test.dart)
and [`dart_core_test.dart`](../packages/general_datetime_core/test/dart_core_test.dart).
