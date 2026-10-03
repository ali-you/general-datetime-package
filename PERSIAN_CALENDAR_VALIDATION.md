# Persian calendar data and validation

`PersianDateTime` supports Solar Hijri -61-01-01 through 3177-12-29
(Gregorian 0560-03-20 through 3799-03-19). Published Iranian calendar data
remains authoritative for SH 1206–1498; outside that interval, dates use
[Borkowski's break-year model](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm).
The extended interval is a calculated calendar, not a guarantee of official
historical usage or future astronomical decisions. It includes year zero.

`minimumYear` and `maximumYear` describe the supported calculation bounds.
`minimumOfficialYear`, `maximumOfficialYear`, and `hasOfficialCalendarData`
identify whether the published table covers a date. Negative years format as
signed four-digit years, for example `-0061-01-01T00:00:00.000Z`.

The model's uncertainty for distant years is discussed in its original paper.
Other implementations using different astronomical predictions can disagree;
[jalaali-js documents divergence from Intl after Gregorian 2256](https://github.com/jalaali/jalaali-js).
No 2820-year fallback is applied beyond the finite calculation range.

## Primary sources

The source authority is the Calendar Center of the University of Tehran's
Institute of Geophysics. Its website publishes both the official annual
calendars and a leap-year study covering SH 1206–1498:

- [Calendar Center home and publications](https://calendar.ut.ac.ir/)
- [Normal and leap years, SH 1206–1498](https://calendar.ut.ac.ir/documents/2139738/7092644/Kabise%2BShamsi%2B1206-1498.pdf/fbc45bf4-df46-c298-381c-2bff2c57f0e0)
- [Official calendar for SH 1403](https://calendar.ut.ac.ir/documents/2139738/7092644/Calendar+1403.pdf/ec65fdf0-15bf-a12f-4fc3-29f533649186)
- [Official calendar for SH 1404](https://calendar.ut.ac.ir/documents/2139738/7092644/Calendar-1404.pdf/4321b7e0-d043-78ca-49f5-fbfc911e7901)
- [Official calendar for SH 1405](https://calendar.ut.ac.ir/documents/2139738/7092644/Calendar-1405.pdf/64228cbb-f4de-dc32-4d2b-57db3c8e322f)

The downloaded source hashes used during verification were:

```text
d897b960b46992226502a21e24c604db9f87cf68fa43f8df368316bee386475e  leap table 1206-1498
6cfaa18dae05c748eeab995430810fc15780880ccdff1bbc7cae487e4d2f2e60  annual calendar 1403
057a40b265125cf8a1ec9b8133ef797f1635c3ad09ba941cc40614be41558945  annual calendar 1404
8e32b520d5da058414b9378d62a01117273336a4c074591f4e84d59ab32a963c  annual calendar 1405
```

## Source discrepancy and decision

The leap-year PDF's star markers are internally consistent with the annual
official calendars, including leap years 1399 and 1403. Its printed Gregorian
column is not consistent with those markers or the annual calendars. For
example, it marks 1403 as leap but prints March 20 for both the starts of 1403
and 1404, while the official 1404 calendar maps 1404-01-01 to 2025-03-21.

The implementation therefore uses only the study's explicit leap markers. The
civil mapping is anchored to the annual calendars:

```text
1403-01-01 = 2024-03-20
1404-01-01 = 2025-03-21
1405-01-01 = 2026-03-21
```

With the fixed Solar Hijri month lengths, that produces a unique continuous
published-data interval from SH 1206-01-01 (1827-03-22) through SH 1498-12-30
(2120-03-20). The conflicting printed column is retained verbatim in the test
fixture for auditability but is never used for conversion.

## Verification coverage

The tests keep the official CSV fixture separate from production data and use
it as an independent oracle. They verify:

- all 293 published leap/common-year markers and all 3,516 month lengths;
- every one of the 107,016 published-data days in both conversion directions;
- all 3,239 supported year starts and leap statuses against `shamsi_date`;
- all 1,183,020 calculated-range days against external year starts, including
  conversion round trips and Julian day numbers;
- reverse conversion for every day in the external oracle's shared range
  (its final date is Gregorian 3798-12-31; this implementation covers the
  remaining 78 days of the final Persian year as well);
- continuity at both published-data edges and signed-year formatting;
- the three annual-calendar civil anchors above and both range boundaries;
- Julian day numbers, weekdays, normalization, parsing and offsets;
- UTC/local conversion, epoch factories, microsecond precision, equality,
  hashing, comparisons, arithmetic, and `copyWith`;
- Persian Material localization formatting and parsing, customized month
  headers, signed years, date-picker navigation, input mode, and range failures.

Shared critical regression suites and time-zone CI coverage are described in
[CALENDAR_TESTING.md](CALENDAR_TESTING.md).

Run the validation with:

```console
flutter test
flutter test --platform chrome
flutter analyze
```
