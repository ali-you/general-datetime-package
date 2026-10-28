# Architecture

[Documentation index](README.md)

## Package boundaries

`general_datetime_core` owns chronology and has no Flutter dependency.
`general_datetime` adds Material adapters and exports the resolved core's public
types. Changes to core source in this monorepository affect wrapper consumers
only when dependency resolution selects that source or a release containing it.

```text
Application
  |-- general_datetime/general_datetime.dart --> resolved general_datetime_core
  |-- general_datetime/delegates.dart ---------> Flutter Material adapters
  `-- general_datetime/default_localizations.dart -> English calendar labels

general_datetime_core
  |-- CalendarDate --> CalendarSystems --> native/calendar date-time values
  |-- CalendarDateUtils -----------------> calendar-preserving field operations
  |-- CalendarInstant / CalendarDateRecord -> version-1 JSON contracts
  `-- PersianDateTime / HijriDateTime / HebrewDateTime -> calculations and data
```

This is the implemented dependency structure. The engine-based structure in the
[expansion review](calendar-expansion-review.md) is a proposal.

## Source map

Paths below are relative to the repository root.

| Source | Responsibility |
| --- | --- |
| [`lib/general_datetime.dart`](../lib/general_datetime.dart) | Public core re-export |
| [`lib/delegates.dart`](../lib/delegates.dart) | Public picker delegates and range-picker builder |
| [`lib/default_localizations.dart`](../lib/default_localizations.dart) | Public default Material localizations |
| [`packages/general_datetime_core/lib/general_datetime_core.dart`](../packages/general_datetime_core/lib/general_datetime_core.dart) | Pure Dart public API exports |
| [`calendar_system.dart`](../packages/general_datetime_core/lib/src/calendar_system.dart) | Strict construction, bounds, metadata, and built-in registry |
| [`calendar_date.dart`](../packages/general_datetime_core/lib/src/calendar_date.dart) | Immutable civil dates, period arithmetic, ranges, and week rules |
| [`calendar_date_utils.dart`](../packages/general_datetime_core/lib/src/calendar_date_utils.dart) | Safe operations when static types are `DateTime` |
| [`calendar_serialization.dart`](../packages/general_datetime_core/lib/src/calendar_serialization.dart) | Calendar IDs and strict JSON records |
| [`general_date_time_interface.dart`](../packages/general_datetime_core/lib/src/general_date_time_interface.dart) | Shared calendar date-time contract |
| [`calendars/persian/`](../packages/general_datetime_core/lib/src/calendars/persian/) | Persian date-time, calculation policy, and published leap data |
| [`calendars/hijri/`](../packages/general_datetime_core/lib/src/calendars/hijri/) | Umm al-Qura date-time, calculations, and month table |
| [`calendars/hebrew/`](../packages/general_datetime_core/lib/src/calendars/hebrew/) | Fixed Hebrew calculation, stable month slots and date-time compatibility |
| [`lib/src/delegates/`](../lib/src/delegates/) | Calendar arithmetic, runtime guards, and bounded range-picker probes |
| [`lib/src/localizations/`](../lib/src/localizations/) | English calendar-specific Material formatting and parsing |

Applications should import public libraries rather than `src` paths.

## Contracts that cross layers

- **Instants:** conversions copy epoch microseconds. Calendar fields are a
  presentation of that instant in UTC or host-local mode.
- **Civil dates:** `CalendarDate` carries a calendar tag and validated fields.
  Its Gregorian midnight is a day coordinate, not a scheduled event.
- **Bounds:** Persian calculations and the Umm al-Qura table are finite. Callers
  must handle operations that leave the supported interval.
- **Localization:** delegates provide calendar arithmetic and forward labels and
  input parsing to the ambient `MaterialLocalizations`.
- **Storage:** an instant uses a Gregorian UTC timestamp; an all-day date uses
  tagged fields. The stored calendar preference does not change the timestamp.
- **Named zones:** the core uses UTC or the host timezone. The demo handles IANA
  zone rules through its own `timezone` dependency.

Tests protect the core/wrapper identity boundary in
[`core_package_identity_test.dart`](../test/unit/core_package_identity_test.dart).

## Extending the package

The built-in registry supports `gregory`, `persian`, `islamic-umalqura`, and `hebrew`.
Implementing `CalendarSystem` or `GeneralDateTimeInterface` does not register a
new calendar with field utilities, version-1 storage, or formatter packages.
`GeneralDateTimeInterface.now<T>()` selects Persian, Hijri and Hebrew types explicitly.

Hebrew civil arithmetic counts actual months and preserves stable month identity;
`CalendarSystems.monthsOfYear` exposes valid slots, and `MissingMonthPolicy`
controls Adar I when adding years. Existing calendars retain twelve-month
arithmetic. Chinese and Hindu calendars remain proposed extensions. The
[expansion review](calendar-expansion-review.md) records the earlier design
analysis; see the [Hebrew guide](hebrew-calendar.md) for implemented behavior.
