# Hijri calendar validation

`HijriDateTime` implements the data-backed Umm al-Qura calendar. Its supported
interval is AH 1300-01-01 through AH 1600-12-30, corresponding to Gregorian
1882-11-12 through 2174-11-25, inclusive: 301 years and 106,665 calendar days.
The table contains 190 years of 354 days and 111 years of 355 days.

## Sources and independent checks

- [Unicode ICU 78.3 `islamcal.cpp`](https://github.com/unicode-org/icu/blob/release-78.3/icu4c/source/i18n/islamcal.cpp)
  supplies the production month masks. Attribution and the Unicode license are
  in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- [OpenJDK 21's Hijrah-umalqura configuration](https://github.com/openjdk/jdk21u/blob/master/src/java.base/share/classes/java/time/chrono/hijrah-config-Hijrah-umalqura_islamic-umalqura.properties)
  provides independently represented month lengths and the Gregorian epoch.
- Java 21.0.8's `java.time.chrono.HijrahDate` was checked separately: all 3,612
  month lengths and all 301 Gregorian year starts match the production data.
  Every supported Java date also round-tripped through `LocalDate`.
- The committed test fixture uses a separate, reversed-bit representation and
  imports no production calendar code. Every fixture month was checked against
  both primary datasets and the installed Java runtime.

The production masks, encoded as unsigned 16-bit big-endian values, have SHA-256:

```text
4cd91fa0438fc92c8ecfb55f7f603f36cf889579f0469559046a05d94e10f846
```

The 3,612 expanded month lengths, encoded as one byte per month, have SHA-256:

```text
09d10fa7abf400dd61af966c4b7c311ae862a5eb2f3f490e4fb8802d59f7276f
```

## Regression coverage

`test/unit/hijri_date_time_test.dart` validates both conversion directions for
every supported day against the independent fixture, including weekdays,
Julian day numbers, day-of-year, year lengths and microsecond precision.
Additional tests cover normalization, local/UTC representation, epoch
constructors, comparisons, native equality/hashing, arithmetic, `copyWith`,
parsing, formatting, and rejection outside the finite interval.

The complete native Flutter suite passed all 110 tests. Flutter analysis and
the repository formatting check passed. A Chrome run was attempted but did not
reach the tests: the installed Flutter SDK failed to load CanvasKit assets and
generated a malformed Windows test path. Browser execution is unverified.

Numeric offsets are applied before validating the final UTC date. For example,
`1601-01-01T00:00:00+01:00` resolves to the supported AH 1600-12-30 at 23:00 UTC.
An offset that moves the final date outside the interval is rejected.

## Why `hijri` 3.0.1 is not the reference

That package's table covers AH 1356–1500 and differs from ICU/OpenJDK in some
months. Observed examples are:

| Gregorian date | ICU/OpenJDK and this package | `hijri` 3.0.1 |
| --- | --- | --- |
| 1937-05-11 | AH 1356-02-30 | AH 1356-03-01 |
| 2024-12-02 | AH 1446-06-01 | AH 1446-05-30 |

The previous exhaustive comparison against that package therefore could not
validate the chosen chronology or its full range. Primary-source regression
anchors replace those assertions; exhaustive independent fixture validation
continues to cover the entire interval.

## Structure and Flutter integration

The structure follows the Persian calendar: `UmmAlQuraData` holds source data,
`HijriCalendarCalculation` interprets month/year lengths, and `HijriDateTime`
handles native instants, conversion, normalization, and coverage APIs.
`minimumOfficialYear`, `maximumOfficialYear`, and `hasOfficialCalendarData`
mirror the Persian API; all supported Hijri years use published table data.

`HijriCalendarDelegate` handles calendar operations and forwards formatting,
parsing, and input help to the supplied `MaterialLocalizations`. Month names
and default date formats live in `DefaultHijriCalendarMaterialLocalizations`.
Install its localization delegate in the picker scope using
`Localizations.override`, or at app level when the app uses that calendar.
Delegate and widget tests exercise customized names/formats/parsing, input
submission, navigation, range rejection, week alignment, and scoped pickers.

Umm al-Qura data must not be extended using a repeating arithmetic Islamic
leap cycle. Adding support beyond this interval requires a separately verified
month table and corresponding reference tests.
