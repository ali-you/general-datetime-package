/// Published Iranian Solar Hijri calendar data.
///
/// The Calendar Center of the University of Tehran's Institute of Geophysics
/// publishes leap-year results for Solar Hijri years 1206 through 1498. The
/// civil-date mapping is anchored by its official 1404 annual calendar, which
/// pairs 1404-01-01 with Gregorian 2025-03-21. Those results are the authority
/// for this table; no cyclic leap-year rule is used or extrapolated beyond the
/// published interval.
///
/// Source:
/// https://calendar.ut.ac.ir/documents/2139738/7092644/Kabise%2BShamsi%2B1206-1498.pdf/fbc45bf4-df46-c298-381c-2bff2c57f0e0
/// https://calendar.ut.ac.ir/documents/2139738/7092644/Calendar-1404.pdf/4321b7e0-d043-78ca-49f5-fbfc911e7901
///
/// Source PDF SHA-256:
/// d897b960b46992226502a21e24c604db9f87cf68fa43f8df368316bee386475e
/// 057a40b265125cf8a1ec9b8133ef797f1635c3ad09ba941cc40614be41558945
abstract final class IranianCalendarData {
  static const int minimumYear = 1206;
  static const int maximumYear = 1498;
  static const int yearCount = maximumYear - minimumYear + 1;

  static const int epochGregorianYear = 1827;
  static const int epochGregorianMonth = 3;
  static const int epochGregorianDay = 22;
  static const int epochJulianDay = 2388438;

  /// One bit-like character per year, starting at [minimumYear].
  /// `1` denotes an official leap year and `0` a common year.
  static const String _leapYearFlags =
      '0000100010001000100010001000100010000100010001000100010001000100'
      '0100001000100010001000100010001000100001000100010001000100010001'
      '0001000010001000100010001000100010001000010001000100010001000100'
      '0100010000100010001000100010001000100010000100010001000100010001'
      '0001000100001000100010001000100010001';

  static bool isLeapYear(int year) {
    RangeError.checkValueInInterval(
      year,
      minimumYear,
      maximumYear,
      'year',
    );
    return _leapYearFlags.codeUnitAt(year - minimumYear) == 0x31;
  }
}
