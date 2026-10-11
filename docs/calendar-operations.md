# Calendar operations

[Documentation index](README.md)

Examples use the public `general_datetime_core` import. The Flutter wrapper's
`general_datetime.dart` import exposes the same APIs.

## Supported dates

| Calendar ID | Inclusive calendar bounds | Inclusive Gregorian UTC civil days | Coverage policy |
| --- | --- | --- | --- |
| `CalendarId.gregory` | Native Dart bounds | -271821-04-20 through 275760-09-13 | Proleptic Gregorian |
| `CalendarId.persian` | -61-01-01 through 3177-12-29 | 0560-03-20 through 3799-03-19 | Tehran leap data in SH 1206–1498; finite Borkowski calculation elsewhere |
| `CalendarId.islamicUmalqura` | 1300-01-01 through 1600-12-30 | 1882-11-12 through 2174-11-25 | Verified Umm al-Qura month table; no fallback |

Persian years include zero. Published Persian data and the calculated extension
are distinct: `hasOfficialCalendarData` on a date-time and `hasPublishedData` on
a civil date expose coverage. All supported Umm al-Qura years use table data.
Umm al-Qura is a specific Hijri chronology; other Islamic calendars may disagree.

Read the [Persian](persian-calendar-validation.md) and
[Umm al-Qura](hijri-calendar-validation.md) validation reports for provenance.
Bounds apply to the resulting wall date, so duration arithmetic and UTC/local
conversion can fail near an endpoint.

## Normalizing and strict construction

Date-time constructors normalize fields in their own calendar:

```dart
final normalized = PersianDateTime.utc(1403, 13, 1);
assert(normalized.year == 1404 && normalized.month == 1);
assert(!PersianDateTime.isValidDate(1403, 13, 1));
```

Optional month/day default to 1 and clock fields to 0. Unsupported normalized
results throw `RangeError`; extreme values cannot wrap into ordinary dates.

For strict input, use `CalendarDate` or a calendar system:

```dart
final system = CalendarSystems.persian;
final value = system.construct(1403, 1, 1, hour: 12); // UTC by default.
final fields = system.fromGregorianDay(DateTime.utc(2024, 3, 20));
assert(fields == (year: 1403, month: 1, day: 1));
```

`construct` rejects invalid date/clock fields and local times normalized by DST.
It does not provide an application policy for choosing between repeated local
times. `fromInstant(value, isUtc: ...)` converts an instant; `fromGregorianDay`
reads native Gregorian wall fields and ignores the clock. Pass calendar
subclasses to `fromInstant` instead.

## Parsing

```dart
final persian = PersianDateTime.parse('1403-01-01T12:34:56.789123Z');
final hijri = HijriDateTime.parse('1445-09-10T03:30:00+03:30');
assert(hijri.isUtc && hijri.hour == 0);
assert(PersianDateTime.tryParse('invalid') == null);
```

These parsers interpret the receiving calendar, accept ASCII digits, normalize
field overflow, and truncate fractional seconds beyond six digits. `Z` and
numeric offsets produce UTC; no zone produces host-local time. Offset adjustment
precedes the final range check. Invalid syntax, invalid offsets, and unsupported
results produce `FormatException`; `tryParse` returns `null`.

Use the companion formatter for strict localized user input. Storage has a
different, strict grammar described in [serialization](serialization.md).

## Instants and field replacement

`add`, `subtract`, `difference`, ordering, and `isAtSameMomentAs` operate on
instants. `toDateTime` returns native Gregorian with the same epoch and mode;
`toUtc`/`toLocal` retain the calendar subclass. A day-long `Duration` is 24 elapsed
hours and may change the wall clock across DST.

`secondsSinceEpoch` floors microseconds to the containing Unix second, including
negative values: -1 microsecond is -1 second. Use microsecond storage when the
fraction matters.

Use calendar-aware helpers when a value is statically typed `DateTime`:

```dart
DateTime selected = PersianDateTime.utc(1403, 1, 1, 12, 30, 0, 123, 456);
final next = CalendarDateUtils.copyWith(selected, day: 2);
final midnight = CalendarDateUtils.dateOnly(selected);
final native = CalendarDateUtils.toGregorian(selected);
assert(next is PersianDateTime && next.microsecond == 456);
assert(midnight is PersianDateTime && midnight.hour == 0);
assert(native.year == 2024);
```

Dart's `DateTime.copyWith` extension and Gregorian Flutter `DateUtils` helpers can
reconstruct the wrong calendar from custom fields. Concrete calendar classes'
own `copyWith` methods are safe through their concrete static types.
`copyWith(isUtc: ...)` reinterprets wall fields; use `toUtc`/`toLocal` to preserve
the instant. `dateOnly` still constructs a date-time and can encounter local DST.

## Civil dates and period arithmetic

```dart
final date = CalendarDate(
  calendar: CalendarId.persian, year: 1403, month: 6, day: 31,
);
final tomorrow = date.addDays(1); // 1403-07-01
final clamped = date.addMonths(1); // 1403-07-30
final carried = date.addMonths(1, policy: CalendarOverflow.overflow);
// 1403-08-01
final gregorian = date.toCalendar(CalendarId.gregory);
assert(date.isSameCivilDay(gregorian));
assert(date != gregorian); // Equality includes the calendar tag.
```

`addMonths` and `addYears` use `CalendarOverflow.clamp` by default.
`reject` throws `ArgumentError` for a missing destination day; `overflow` carries
excess days forward. Clamping loses the original day, so recurring monthly events
should retain their requested month/day separately. Out-of-range results fail.

`CalendarDate.fromDateTime` extracts wall fields without timezone conversion.
For a UTC date, convert the instant to UTC first. `dayIndex` counts civil days
from Gregorian 1970-01-01; `gregorianDay` is its native UTC-midnight coordinate.
`compareTo`, `daysUntil`, and `isSameCivilDay` compare coordinates, while equality
and hashing also include calendar identity.

## Ranges and weeks

```dart
final start = CalendarDate(
  calendar: CalendarId.gregory, year: 2021, month: 1, day: 1,
);
final range = CalendarDateRange(start, start.addDays(7));
assert(range.dayCount == 7);
assert(!range.contains(start.addDays(7))); // End excluded.
assert(CalendarDateRange.inclusiveDayCount(start, start.addDays(7)) == 8);
assert(const CalendarWeekRules().weekOfYear(start) == (year: 2020, week: 53));
```

Civil ranges are half-open; Flutter picker ranges select an inclusive last date.
To convert a picker selection, extract both civil dates and add one day to its
last date for the exclusive end. That conversion cannot represent an exclusive
end beyond the maximum supported day; use `inclusiveDayCount` when only a count
is needed.

`CalendarWeekRules` accepts `firstWeekday` and `minimumDays` from 1–7. Defaults are
Monday and four days. Week-years follow the selected calendar; Gregorian defaults
match ISO week rules. Operations needing earlier days or years can fail at the
calendar boundary.
