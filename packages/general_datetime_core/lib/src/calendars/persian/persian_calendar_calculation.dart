import 'iranian_calendar_data.dart';

/// Extends the published Iranian calendar using Borkowski's break-year model.
///
/// Published years always use [IranianCalendarData]. Outside that interval,
/// dates are calculated predictions, not official historical or future dates.
/// The model's finite range is Solar Hijri -61 through 3177.
///
/// Algorithm source:
/// https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm
abstract final class PersianCalendarCalculation {
  static const int minimumYear = -61;
  static const int maximumYear = 3177;

  static const List<int> _breakYears = <int>[
    -61,
    9,
    38,
    199,
    426,
    686,
    756,
    818,
    1111,
    1181,
    1210,
    1635,
    2060,
    2097,
    2192,
    2262,
    2324,
    2394,
    2456,
    3178,
  ];

  static bool isLeapYear(int year) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');
    if (year >= IranianCalendarData.minimumYear &&
        year <= IranianCalendarData.maximumYear) {
      return IranianCalendarData.isLeapYear(year);
    }

    int previousBreak = _breakYears.first;
    int jump = 0;
    for (final int nextBreak in _breakYears.skip(1)) {
      jump = nextBreak - previousBreak;
      if (year < nextBreak) break;
      previousBreak = nextBreak;
    }
    int yearsSinceBreak = year - previousBreak;
    if (jump - yearsSinceBreak < 6) {
      yearsSinceBreak = yearsSinceBreak - jump + ((jump + 4) ~/ 33) * 33;
    }
    // Borkowski's MOD uses signed remainders, including -1 for the fourth
    // common year. Only a zero result denotes a leap year.
    return ((yearsSinceBreak + 1).remainder(33) - 1).remainder(4) == 0;
  }
}
