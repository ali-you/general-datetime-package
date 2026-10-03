import 'umm_al_qura_data.dart';

/// Calendar calculations using the published Umm al-Qura month table.
///
/// The finite range is AH 1300 through 1600. Every supported year uses
/// [UmmAlQuraData]; a repeating arithmetic leap cycle cannot extend this table.
abstract final class HijriCalendarCalculation {
  static const int minimumYear = UmmAlQuraData.minimumYear;
  static const int maximumYear = UmmAlQuraData.maximumYear;

  static int daysInMonth(int year, int month) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    final int bits = UmmAlQuraData.yearMonthLengthBits[year - minimumYear];
    return bits & (1 << (12 - month)) == 0 ? 29 : 30;
  }

  static int yearLength(int year) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');
    int bits = UmmAlQuraData.yearMonthLengthBits[year - minimumYear];
    int thirtyDayMonths = 0;
    while (bits != 0) {
      thirtyDayMonths += bits & 1;
      bits >>= 1;
    }
    return 12 * 29 + thirtyDayMonths;
  }

  static bool isLeapYear(int year) => yearLength(year) == 355;
}
