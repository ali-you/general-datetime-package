# Changelog

## 1.0.0 — release preparation

- Extract the corrected pure Dart implementation from the Flutter package.
- Add `CalendarSystem` and a registry for the three built-in calendars, with
  strict construction, supported ranges, and conversion metadata.
- Add immutable `CalendarDate`, explicit arithmetic overflow policies,
  half-open `CalendarDateRange`, and calendar-aware `CalendarWeekRules`.
- Return the requested concrete type from `GeneralDateTimeInterface.now<T>()`.
