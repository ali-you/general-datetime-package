# Changelog

## Unreleased

- Add `HebrewDateTime` and `CalendarSystems.hebrew` for the fixed midnight-based
  Hebrew civil calendar, AM 1–9999, using ICU-compatible stable month slots.
- Support Hebrew through conversion, validation, field helpers, civil dates,
  weeks, ranges, instant/civil JSON, and `GeneralDateTimeInterface.now`.
- Add `CalendarId.hebrew`, `CalendarSystems.monthsOfYear`, actual-month
  arithmetic, and `MissingMonthPolicy` for Adar I in common destination years.
- Validate independent Hebcal anchors, every supported year and month boundary,
  representative day round trips, arithmetic policies, serialization and bounds.

## 1.0.0

- Extract the corrected pure Dart implementation from the Flutter package.
- Add `CalendarSystem` and a registry for the three built-in calendars, with
  strict construction, supported ranges, and conversion metadata.
- Add immutable `CalendarDate`, explicit arithmetic overflow policies,
  half-open `CalendarDateRange`, and calendar-aware `CalendarWeekRules`.
- Return the requested concrete type from `GeneralDateTimeInterface.now<T>()`.
- Provide calendar-safe field helpers and versioned instant/civil-date JSON
  serialization without runtime dependencies or a Flutter SDK requirement.
- Document installation, conversion, arithmetic, validation, supported ranges,
  serialization, and integration with the Flutter and formatting packages.
- Group chronology implementations and data by Gregorian, Persian, and
  Umm al-Qura Hijri calendar, retaining compatibility exports for date-time paths.
- Remove calendar-specific forwarding files from `shared/` and reference their
  implementations in `calendars/` directly from the Flutter wrapper.
