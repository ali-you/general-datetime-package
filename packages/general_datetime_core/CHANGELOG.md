# Changelog

## 2.0.0 — 2026-10-28

- Extend Chinese validation to every supported day coordinate, month identity,
  period overflow policy and cross-year leap-month mapping. Verify exact large
  cancellations on VM/JavaScript, native executable behavior, and five process
  timezones; add non-overwriting oracle/baseline checks.


- Add Chinese civil chronology for lunar years 1901–2099, with pinned MIT .NET
  tables, explicit leap-month identity, actual-month arithmetic, JSON storage,
  English Material adapters, and independent exhaustive runtime validation.
- Append `CalendarId.chinese`; exhaustive enum switches must handle the new case.
  Document intentional differences from HKO and ICU reference chronologies.


- Validate all 3,652,078 supported Hebrew dates against an independent Hebcal
  oracle, retain reproducible validation tools, and add postponement anchors
  independently confirmed by .NET.

- Preserve the native split millisecond/microsecond representation when copying
  instants; avoid JavaScript aggregate-epoch rounding in Hebrew and Persian
  extended ranges. Retain exact hash/equality, comparisons, fractions and
  duration operations; share the same implementation with Hijri.
- Test odd fractions and second-boundary carry in VM/Node across supported
  endpoints, ancient/future dates, UTC/local mode, helpers and serialization.

- Breaking: add `CalendarId.hebrew`. Exhaustive switches must handle the new
  case; existing enum indices and Persian/Hijri serialization stay unchanged.

- Add `HebrewDateTime` and `CalendarSystems.hebrew` for the fixed midnight-based
  Hebrew civil calendar, AM 1–9999, using ICU-compatible stable month slots.
- Support Hebrew through conversion, validation, field helpers, civil dates,
  weeks, ranges, instant/civil JSON, and `GeneralDateTimeInterface.now`.
- Add `CalendarId.hebrew`, `CalendarSystems.monthsOfYear`, actual-month
  arithmetic, and `MissingMonthPolicy` for Adar I in common destination years.
- Validate independent Hebcal anchors, every supported year and month boundary,
  representative day round trips, arithmetic policies, serialization and bounds.
- Add JavaScript-compatible extreme-offset tests and portable core Node CI.
- Independently compare 239,612 Hebrew days with .NET and preserve pre-Hebrew
  Persian/Hijri conversion, helpers, serialization and arithmetic results.

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
