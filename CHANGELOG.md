# Changelog

## Unreleased

- Replaced the mixed Persian leap algorithms with a finite official data model
  sourced from the University of Tehran Calendar Center for SH 1206–1498.
- Rebuilt Persian conversion, normalization, parsing, UTC/local handling, epoch
  factories, arithmetic, equality, hashing, and `copyWith` around the true
  native `DateTime` instant.
- Made unsupported Persian dates fail explicitly instead of extrapolating a
  33-year, break-table, or 2820-year cycle.
- Made `PersianCalendarDelegate` own English/Persian names, digit shaping,
  formatting, and parsing under any ambient Material localization.
- Added official-source fixtures and exhaustive Persian calendar, boundary,
  precision, parsing, delegate, and widget tests.
- Replaced the approximate tabular Hijri implementation with the official
  Unicode ICU/OpenJDK Umm al-Qura month data for AH 1300 through AH 1600.
- Rebuilt Hijri conversion, normalization, parsing, UTC/local handling, epoch
  factories, arithmetic, equality, and `copyWith` around the true native
  `DateTime` instant.
- Made unsupported Umm al-Qura dates fail explicitly instead of silently
  extrapolating another Islamic calendar.
- Made `HijriCalendarDelegate` own Hijri formatting and parsing so it remains
  correct under Gregorian or Persian ambient Material localizations.
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
