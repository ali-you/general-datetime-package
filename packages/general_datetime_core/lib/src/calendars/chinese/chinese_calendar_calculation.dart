import 'chinese_calendar_data.dart';

/// Bounded .NET Chinese civil chronology. Years use the Gregorian year in
/// which lunar New Year occurs. Months are chronological ordinals (1..12/13),
/// distinct from the traditional number repeated by an intercalary month.
abstract final class ChineseCalendarCalculation {
  static const minimumYear = 1901;
  static const maximumYear = 2099;
  static void requireYear(int year) =>
      RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');
  static (int, int, int) _row(int year) {
    requireYear(year);
    return chineseCalendarData[year - minimumYear];
  }

  static int leapMonth(int year) => _row(year).$2;
  static bool isLeapYear(int year) => leapMonth(year) != 0;
  static int monthsInYear(int year) => isLeapYear(year) ? 13 : 12;
  static List<int> monthsOfYear(int year) =>
      List.unmodifiable(List.generate(monthsInYear(year), (i) => i + 1));
  static void _requireMonth(int year, int month) =>
      RangeError.checkValueInInterval(month, 1, monthsInYear(year), 'month');
  static int daysInMonth(int year, int month) {
    _requireMonth(year, month);
    return 29 + ((_row(year).$3 >> (month - 1)) & 1);
  }

  static int lunarMonth(int year, int month) {
    _requireMonth(year, month);
    final leap = leapMonth(year);
    return leap != 0 && month > leap ? month - 1 : month;
  }

  static bool isLeapMonth(int year, int month) {
    _requireMonth(year, month);
    return leapMonth(year) != 0 && month == leapMonth(year) + 1;
  }

  /// Resolve a traditional month identity; an absent leap month is rejected.
  static int monthForLunar(int year, int lunarMonth,
      {bool isLeapMonth = false}) {
    requireYear(year);
    RangeError.checkValueInInterval(lunarMonth, 1, 12, 'lunarMonth');
    final leap = leapMonth(year);
    if (isLeapMonth && leap != lunarMonth) {
      throw ArgumentError('Year $year has no leap month $lunarMonth');
    }
    return lunarMonth +
        (isLeapMonth || (leap != 0 && lunarMonth > leap) ? 1 : 0);
  }

  static int yearStartDayIndex(int year) => _row(year).$1;
  static int yearLength(int year) => monthsOfYear(year)
      .fold(0, (total, month) => total + daysInMonth(year, month));
  static int get minimumDayIndex => chineseCalendarData.first.$1;
  static int get maximumDayIndex =>
      yearStartDayIndex(maximumYear) + yearLength(maximumYear) - 1;
  static bool isValidDate(int year, int month, int day) =>
      year >= minimumYear &&
      year <= maximumYear &&
      month >= 1 &&
      month <= monthsInYear(year) &&
      day >= 1 &&
      day <= daysInMonth(year, month);
  static int monthStartDayIndex(int year, int month) {
    _requireMonth(year, month);
    var start = yearStartDayIndex(year);
    for (var m = 1; m < month; m++) {
      start += daysInMonth(year, m);
    }
    return start;
  }

  static int toDayIndex(int year, int month, int day) {
    if (!isValidDate(year, month, day)) {
      throw ArgumentError('Invalid Chinese date: $year-$month-$day');
    }
    return monthStartDayIndex(year, month) + day - 1;
  }

  static ({int year, int month, int day}) fromDayIndex(int index) {
    RangeError.checkValueInInterval(
        index, minimumDayIndex, maximumDayIndex, 'dayIndex');
    var low = minimumYear, high = maximumYear;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (yearStartDayIndex(middle) <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    var remaining = index - yearStartDayIndex(low);
    for (final month in monthsOfYear(low)) {
      final length = daysInMonth(low, month);
      if (remaining < length) {
        return (year: low, month: month, day: remaining + 1);
      }
      remaining -= length;
    }
    throw StateError('Invalid Chinese day coordinate');
  }

  static final List<int> _monthOffsets = _makeMonthOffsets();
  static List<int> _makeMonthOffsets() {
    final result = <int>[0];
    for (var year = minimumYear; year <= maximumYear; year++) {
      result.add(result.last + monthsInYear(year));
    }
    return List.unmodifiable(result);
  }

  static int monthIndex(int year, int month) {
    _requireMonth(year, month);
    return _monthOffsets[year - minimumYear] + month - 1;
  }

  static ({int year, int month}) _fromMonthIndex(BigInt index) {
    if (index.isNegative || index >= BigInt.from(_monthOffsets.last)) {
      throw RangeError('Chinese month offset outside supported years');
    }
    final target = index.toInt();
    var low = 0, high = maximumYear - minimumYear;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_monthOffsets[middle] <= target) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return (year: low + minimumYear, month: target - _monthOffsets[low] + 1);
  }

  static ({int year, int month}) addMonths(int year, int month, int count) =>
      _fromMonthIndex(
          BigInt.from(monthIndex(year, month)) + BigInt.from(count));

  /// Normalize ordinal month overflow through actual months. An end sentinel
  /// permits day/clock overflow back from the first unsupported year.
  static ({int year, int month, int start}) resolveMonth(int year, int month) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear + 1, 'year');
    final index = BigInt.from(_monthOffsets[year - minimumYear]) +
        BigInt.from(month) -
        BigInt.one;
    if (index == BigInt.from(_monthOffsets.last)) {
      return (year: maximumYear + 1, month: 1, start: maximumDayIndex + 1);
    }
    final target = _fromMonthIndex(index);
    return (
      year: target.year,
      month: target.month,
      start: monthStartDayIndex(target.year, target.month)
    );
  }
}
