# Changelog

## [3.0.0] — release preparation

- Breaking: replaces the published 2.1.0 chronology and native-instant contracts
  with the corrected implementations described below. Unsupported calendar
  dates now fail explicitly. Publish this core before general_date_format 2.0.0.

- Added shared critical suites for both calendars: independent seeded
  normalization, precision/epoch boundaries, adversarial parsing, DST, calendar
  interoperability, and picker validation/navigation/localization isolation.
- Added exhaustive compact parsing checks over all reference months and a
  three-time-zone CI matrix with explicit DST assertions.
- Fixed oversized epoch seconds/milliseconds wrapping into dates near 1970
  in both calendars, with regressions for positive and negative 64-bit inputs.
- Aligned Hijri calculations, data-coverage APIs, Material localizations,
  delegates, scoped picker examples, and tests with the Persian structure.
- Added customized Hijri formatting/parsing and input-picker coverage, and
  corrected the Hijri localization's expansion-state hints.
- Fixed Hijri parsing to apply numeric time-zone offsets before validating
  supported endpoints, retaining microsecond precision.
- Cross-checked all 3,612 Umm al-Qura months with ICU 78.3 and Java/OpenJDK 21;
  replaced incompatible `hijri` 3.0.1 comparisons with primary-source regressions.

- Extended Persian support to SH -61 through 3177 (Gregorian 0560-03-20
  through 3799-03-19), retaining published data for SH 1206–1498 and using
  Borkowski's finite break-year model elsewhere.
- Exposed official-data bounds and coverage separately from calculation bounds.
- Added signed-year formatting, expanded boundary tests, and exhaustive
  conversion checks over the extended interval.

- Replaced the mixed Persian leap algorithms with a finite official data model
  sourced from the University of Tehran Calendar Center for SH 1206–1498.
- Rebuilt Persian conversion, normalization, parsing, UTC/local handling, epoch
  factories, arithmetic, equality, hashing, and `copyWith` around the true
  native `DateTime` instant.
- Made dates outside the finite Persian calculation range fail explicitly
  instead of extrapolating a 33-year or 2820-year cycle.
- Restored `PersianCalendarDelegate` to use the current Material localizations
  for month names, date formatting, parsing, and input help.
- Added official-source fixtures and exhaustive Persian calendar, boundary,
  precision, parsing, delegate, and widget tests.
- Replaced the approximate tabular Hijri implementation with the official
  Unicode ICU/OpenJDK Umm al-Qura month data for AH 1300 through AH 1600.
- Rebuilt Hijri conversion, normalization, parsing, UTC/local handling, epoch
  factories, arithmetic, equality, and `copyWith` around the true native
  `DateTime` instant.
- Made unsupported Umm al-Qura dates fail explicitly instead of silently
  extrapolating another Islamic calendar.
- Made `HijriCalendarDelegate` use the current Material localizations for
  month names, date formatting, parsing, and input help, like the Persian delegate.
- Added exhaustive calendar, boundary, precision, parsing, delegate, and widget
  tests, independently cross-validated with ICU and OpenJDK.
- Raised the declared Flutter minimum to 3.32.0, where `CalendarDelegate` is
  available on the stable channel.

## [2.1.0]
- Added `DefaultHijriCalendarMaterialLocalizations` for Hijri calendar support in Material widgets.
- Added `HijriCalendarDelegate` for Hijri calendar integration.
- Exported new Hijri localizations and delegates.
- Updated `README.md` and documentation

## [2.0.0]
- Migrated all interfaces to the `DateTime` wrapper.
- Updated `README.md` with new initialization snippets.
- Added 15 new test cases in `DateTimeTests.kt` covering timezone offsets and leap years.

## [1.2.2]
- Updated `README.md` and documentation

## [1.2.1]
- Added `GeneralDateTimeInterface.now<T>()` to access current time via the generic interface.
- Updated `README.md` and documentation

## [1.2.0]
- `JalaliDateTime` algorithm changed to Khayyam algorithm with high precision
- Updated `README.md` and documentation

## [1.0.1]
- New optimizations in interface and implementations
- `HijriDateTime` implemented completely
- Added robust and varied test cases for `HijriDateTime`
- Updated `README.md` and documentation

## [0.1.2]
- `toLocal()` and `toUtc()` added to `general_datetime_interface`
- `toLocal()` and `toUtc()` implemented for `jalali_datetime`
- Updated `README.md` and documentation

## [0.1.1]
- Jalali DateTime completed (Persian calendar)
- New testcases added
- Updated `README.md` and documentation

## [0.0.2]
- Jalali DateTime completed (Persian calendar)
- New testcases added
- Updated `README.md` and documentation

## [0.0.1]
- Initial release with support for all platforms
