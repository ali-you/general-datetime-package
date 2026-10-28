/// Fixed Hebrew civil calendar, using one-based ICU month slots.
///
/// Slot 6 (Adar I) is absent in common years; slot 7 is Adar/Adar II.
/// Days start at midnight. Year-start calculations follow Unicode ICU 78.3:
/// https://github.com/unicode-org/icu/blob/release-78.3/icu4c/source/i18n/hebrwcal.cpp
/// See THIRD_PARTY_NOTICES.md. Arithmetic is bounded before multiplication.
abstract final class HebrewCalendarCalculation {
  static const minimumYear = 1;
  static const maximumYear = 9999;

  static void requireYear(int year) =>
      RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');

  static bool _leap(int year) => (year * 12 + 17) % 19 >= 12;

  static bool isLeapYear(int year) {
    requireYear(year);
    return _leap(year);
  }

  static int monthsInYear(int year) => isLeapYear(year) ? 13 : 12;

  static List<int> monthsOfYear(int year) {
    final leap = isLeapYear(year);
    return List<int>.unmodifiable([
      for (var m = 1; m <= 13; m++)
        if (m != 6 || leap) m,
    ]);
  }

  static void _requireMonth(int year, int month) {
    requireYear(year);
    RangeError.checkValueInInterval(month, 1, 13, 'month');
    if (month == 6 && !_leap(year)) {
      throw RangeError.value(month, 'month', 'Adar I is absent in year $year');
    }
  }

  // Internal neighboring years are needed for year lengths and end sentinels.
  static int _monthsBeforeYear(int year) => (235 * year - 234) ~/ 19;

  static int _start(int year) {
    final months = _monthsBeforeYear(year);
    final parts = months * 13753 + 12084;
    var day = months * 29 + parts ~/ 25920;
    final fraction = parts % 25920;
    final weekday = day % 7; // Monday = 0 in this epoch coordinate.
    if (weekday == 2 || weekday == 4 || weekday == 6) {
      day++;
    } else if (weekday == 1 && fraction > 16404 && !_leap(year)) {
      day += 2;
    } else if (weekday == 0 && fraction > 23269 && _leap(year - 1)) {
      day++;
    }
    return day + 347998 - 2440588; // Gregorian 1970-01-01 = 0.
  }

  static int get minimumDayIndex => _start(minimumYear);
  static int get maximumDayIndex => _start(maximumYear + 1) - 1;

  static int yearStartDayIndex(int year) {
    requireYear(year);
    return _start(year);
  }

  static int yearLength(int year) {
    requireYear(year);
    return _start(year + 1) - _start(year);
  }

  static int daysInMonth(int year, int month) {
    _requireMonth(year, month);
    if (month == 2) return yearLength(year) % 10 == 5 ? 30 : 29;
    if (month == 3) return yearLength(year) % 10 == 3 ? 29 : 30;
    return const [
      30,
      29,
      30,
      29,
      30,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29
    ][month - 1];
  }

  static bool isValidDate(int year, int month, int day) {
    if (year < minimumYear ||
        year > maximumYear ||
        month < 1 ||
        month > 13 ||
        (month == 6 && !_leap(year))) {
      return false;
    }
    return day >= 1 && day <= daysInMonth(year, month);
  }

  static int monthStartDayIndex(int year, int month) {
    _requireMonth(year, month);
    var index = _start(year);
    for (var m = 1; m < month; m++) {
      if (m != 6 || _leap(year)) index += daysInMonth(year, m);
    }
    return index;
  }

  static int toDayIndex(int year, int month, int day) {
    if (!isValidDate(year, month, day)) {
      throw ArgumentError('Invalid Hebrew date: $year-$month-$day');
    }
    return monthStartDayIndex(year, month) + day - 1;
  }

  static ({int year, int month, int day}) fromDayIndex(int index) {
    RangeError.checkValueInInterval(
        index, minimumDayIndex, maximumDayIndex, 'dayIndex');
    var low = minimumYear, high = maximumYear;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_start(middle) <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    var remaining = index - _start(low);
    for (final month in monthsOfYear(low)) {
      final length = daysInMonth(low, month);
      if (remaining < length) {
        return (year: low, month: month, day: remaining + 1);
      }
      remaining -= length;
    }
    throw StateError('Invalid Hebrew day coordinate');
  }

  static int monthOrdinal(int year, int month) {
    _requireMonth(year, month);
    return month > 6 && !_leap(year) ? month - 1 : month;
  }

  /// Zero-based absolute chronological month, for navigation and differences.
  static int monthIndex(int year, int month) =>
      _monthsBeforeYearChecked(year) + monthOrdinal(year, month) - 1;

  static int _monthsBeforeYearChecked(int year) {
    requireYear(year);
    return _monthsBeforeYear(year);
  }

  static ({int year, int month}) _fromMonthIndex(BigInt index) {
    final end = BigInt.from(_monthsBeforeYear(maximumYear + 1));
    if (index.isNegative || index >= end) {
      throw RangeError('Hebrew month offset outside supported years');
    }
    final target = index.toInt();
    var low = minimumYear, high = maximumYear;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_monthsBeforeYear(middle) <= target) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    final ordinal = target - _monthsBeforeYear(low) + 1;
    return (
      year: low,
      month: !_leap(low) && ordinal >= 6 ? ordinal + 1 : ordinal
    );
  }

  static ({int year, int month}) addMonths(int year, int month, int count) =>
      _fromMonthIndex(
          BigInt.from(monthIndex(year, month)) + BigInt.from(count));

  /// Month slots 1..13 are identities, not chronological offsets. An absent
  /// Adar I is rejected. Outside those slots, 0 is the previous Elul and 14
  /// is the next Tishri; further overflow advances actual months.
  /// The final year-start sentinel supports day/clock overflow back into range.
  static ({int year, int month, int start}) resolveMonth(int year, int month) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear + 1, 'year');
    if (month >= 1 && month <= 13 && year <= maximumYear) {
      return (year: year, month: month, start: monthStartDayIndex(year, month));
    }
    final BigInt index;
    if (month < 1) {
      index = BigInt.from(_monthsBeforeYear(year)) +
          BigInt.from(month) -
          BigInt.one;
    } else if (year == maximumYear + 1 && month == 1) {
      return (year: year, month: 1, start: maximumDayIndex + 1);
    } else if (year <= maximumYear && month > 13) {
      index = BigInt.from(_monthsBeforeYear(year + 1)) +
          BigInt.from(month) -
          BigInt.from(14);
    } else {
      throw RangeError('Hebrew month outside supported years');
    }
    if (index == BigInt.from(_monthsBeforeYear(maximumYear + 1))) {
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
