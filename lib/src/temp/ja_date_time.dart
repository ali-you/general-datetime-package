import 'package:general_datetime/src/constants.dart';
import 'package:general_datetime/src/general_date_time_interface_2.dart';
import 'package:general_datetime/src/gregorian_helper.dart';

import '../../general_datetime.dart';

/// Represents a date and time in the **Jalali (Persian/Iranian)** calendar system.
///
/// This class provides conversion between Gregorian and Jalali dates,
/// along with time component support (hour, minute, second, etc).
///
/// It extends the [GeneralDateTimeInterface] to support consistent behavior
/// across multiple calendar types.
///
/// ### Features:
/// - Supports Jalali <-> Gregorian conversion.
/// - Time components (hour, minute, second, etc.) are supported.
/// - Supports normalization of overflow values (e.g., 90 seconds becomes 1 minute 30 seconds).
/// - Provides leap year check and weekday calculation.
/// - Offers a consistent interface across calendars (Gregorian, Jalali, Hijri).
///
/// ### Example:
/// ```dart
/// var now = JalaliDateTime.now(); // Get current Jalali date and time
/// print(now); // 1403/1/19
///
/// var jDate = JalaliDateTime(1402, 12, 30);
/// print(jDate.toDateTime()); // Converts to equivalent Gregorian date
/// ```
///
/// ### Calendar Notes:
/// The Jalali calendar is a solar calendar used in Iran and Afghanistan,
/// with highly accurate leap year rules and month lengths.
class JaDateTime extends DateTime implements GeneralDateTimeInterface2<JaDateTime> {
  /// Private constructor for raw inputs
  ///

  @override
  final int year;
  @override
  final int month;
  @override
  final int day;
  @override
  final int hour;
  @override
  final int minute;
  @override
  final int second;
  @override
  final int millisecond;
  @override
  final int microsecond;

  final bool _isUtc;


  JaDateTime._internal(
      this.year, [
        this.month = 1,
        this.day = 1,
        this.hour = 0,
        this.minute = 0,
        this.second = 0,
        this.millisecond = 0,
        this.microsecond = 0,
        bool isUtc = false,
      ]) : _isUtc = isUtc, super(year, month, day, hour, minute, second, millisecond, microsecond);


  final List<int> _breaks = [
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
    3178
  ];

  /// Start: Factories section
  /// Factory constructor with normalization
  factory JaDateTime(
      int year, [
        int month = 1,
        int day = 1,
        int hour = 0,
        int minute = 0,
        int second = 0,
        int millisecond = 0,
        int microsecond = 0,
      ]) {
    return JaDateTime._internal(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    )._normalize();
  }

  /// Factory constructor for converting from DateTime
  factory JaDateTime.fromDateTime(DateTime dateTime) {
    return JaDateTime._internal(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
      dateTime.isUtc,
    )._toJalali();
  }

  /// Factory constructor for current date and time
  factory JaDateTime.now() {
    final DateTime dt = DateTime.now();
    return JaDateTime.fromDateTime(dt);
  }

  /// Factory constructor for current date and time in UTC
  factory JaDateTime.timestamp() {
    final DateTime dt = DateTime.now().toUtc();
    return JaDateTime.fromDateTime(dt);
  }

  /// Factory constructor in UTC with normalization
  factory JaDateTime.utc(
      int year, [
        int month = 1,
        int day = 1,
        int hour = 0,
        int minute = 0,
        int second = 0,
        int millisecond = 0,
        int microsecond = 0,
      ]) =>
      JaDateTime._internal(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
        true,
      )._normalize();

  factory JaDateTime.fromSecondsSinceEpoch(int secondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        secondsSinceEpoch * 1000,
        isUtc: isUtc);
    return JaDateTime.fromDateTime(dt);
  }

  factory JaDateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
        isUtc: isUtc);
    return JaDateTime.fromDateTime(dt);
  }

  factory JaDateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc);
    return JaDateTime.fromDateTime(dt);
  }

  factory JaDateTime.parse(String formattedString) {
    Match? match = Constants.parseFormat.firstMatch(formattedString);
    if (match != null) {
      int parseIntOrZero(String? matched) {
        if (matched == null) return 0;
        return int.parse(matched);
      }

      int parseMilliAndMicroseconds(String? matched) {
        if (matched == null) return 0;
        int result = 0;
        for (int i = 0; i < 6; i++) {
          result *= 10;
          if (i < matched.length) {
            result += matched.codeUnitAt(i) ^ 0x30;
          }
        }
        return result;
      }

      int year = int.parse(match[1]!);
      int month = int.parse(match[2]!);
      int day = int.parse(match[3]!);
      int hour = parseIntOrZero(match[4]);
      int minute = parseIntOrZero(match[5]);
      int second = parseIntOrZero(match[6]);
      int milliAndMicro = parseMilliAndMicroseconds(match[7]);
      int millisecond = milliAndMicro ~/ 1000;
      int microsecond = milliAndMicro % 1000;

      bool isUtc = false;
      if (match[8] != null) {
        isUtc = true;
        String? tzSign = match[9];
        if (tzSign != null) {
          int sign = (tzSign == '-') ? -1 : 1;
          int hourDiff = int.parse(match[10]!);
          int minuteDiff = parseIntOrZero(match[11]);
          int totalDiff = sign * (hourDiff * 60 + minuteDiff);

          minute -= totalDiff;
          while (minute < 0) {
            minute += 60;
            hour -= 1;
          }
          while (minute >= 60) {
            minute -= 60;
            hour += 1;
          }
        }
      }

      return JaDateTime._internal(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
        isUtc,
      );
    } else {
      throw FormatException("Invalid date format", formattedString);
    }
  }

  /// End: Factories section

  static JaDateTime? tryParse(String formattedString) {
    try {
      return JaDateTime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// private variable to implement gregorian calculations
  final GregorianHelper _gregorianHelper = GregorianHelper();

  /// The calendar name
  @override
  String get name => "Jalali";

  /// Calculate weekday (0=Saturday, 6=Friday)
  @override
  int get weekday {
    DateTime gd = toDateTime();
    return (gd.weekday) % 7;
  }

  /// Get days in the current month
  @override
  int get monthLength => _monthLength(year, month);

  /// This computes the day count within the Jalali year.
  @override
  int get dayOfYear {
    int dayCount = 0;
    for (int m = 1; m < month; m++) {
      dayCount += _monthLength(year, m);
    }
    return dayCount + day;
  }

  /// Check if the year is a leap year
  @override
  bool get isLeapYear => _isLeapYear(year);

  /// Julian Day Number getter
  @override
  int get julianDay {
    int totalDays = 0;
    if (year > 1) {
      for (int k = 1; k < year; k++) {
        totalDays += 365;
        if (_isLeapYear(k)) totalDays += 1;
      }
    } else if (year < 1) {
      for (int k = year; k < 1; k++) {
        totalDays -= 365;
        if (_isLeapYear(k)) totalDays -= 1;
      }
    }
    // Add all months of the current year
    for (int m = 1; m < month; m++) {
      totalDays += _monthLength(year, m);
    }
    // Add days in current month (zero-based)
    totalDays += (day - 1);
    // 1 Farvardin 1 → JDN 1948320
    return 1948321 + totalDays;
  }

  /// Conversion from JalaliDateTime to DateTime (Jalali to Gregorian)
  /// This method uses an approximate conversion via Julian day calculations.
  /// For a given Jalali date, we compute its Julian Day Number (JD) using
  /// an approximation formula and then convert the JD to the Gregorian date.
  @override
  DateTime toDateTime() {
    int floorDiv(int x, int y) => (x / y).floor();

    int a = julianDay + 32044;
    int b = floorDiv(4 * a + 3, 146097);
    int c = a - floorDiv(146097 * b, 4);
    int d = floorDiv(4 * c + 3, 1461);
    int e = c - floorDiv(1461 * d, 4);
    int m = floorDiv(5 * e + 2, 153);

    int dayG = e - floorDiv(153 * m + 2, 5) + 1;
    int monthG = m + 3 - 12 * floorDiv(m, 10);
    int yearG = 100 * b + d - 4800 + floorDiv(m, 10);

    if (_isUtc) {
      return DateTime.utc(
          yearG, monthG, dayG, hour, minute, second, millisecond, microsecond);
    }
    return DateTime(
      yearG,
      monthG,
      dayG,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// Add a Duration to the Jalali date
  @override
  JaDateTime add(Duration duration) {
    final DateTime result = toDateTime().add(duration);
    return JaDateTime.fromDateTime(result);
  }

  /// Subtract a Duration from the Jalali date
  @override
  JaDateTime subtract(Duration duration) {
    final DateTime result = toDateTime().subtract(duration);
    return JaDateTime.fromDateTime(result);
  }

  /// Convert to local time
  @override
  JaDateTime toLocal() {
    if (!_isUtc) return this;
    final localDt = toDateTime().toLocal();
    return JaDateTime.fromDateTime(localDt);
  }

  /// Convert to UTC time
  @override
  JaDateTime toUtc() {
    if (_isUtc) return this;
    final utcDt = toDateTime().toUtc();
    return JaDateTime.fromDateTime(utcDt);
  }

  /// Convert from Gregorian to Jalali
  JaDateTime _toJalali() {
    int jy = year - 621;
    int jdn1f = _gregorianHelper.julianDay(year, 3, _startYearMarch(jy));
    int jdn = _gregorianHelper.julianDay(year, month, day);
    int lastLeap = _leapAndCycle(jy);
    int k = jdn - jdn1f;
    if (k >= 0) {
      if (k <= 185) {
        final int jm = 1 + (k ~/ 31);
        final int jd = (k % 31) + 1;
        return JaDateTime._internal(
            jy, jm, jd, hour, minute, second, millisecond, microsecond, _isUtc);
      } else {
        k -= 186;
      }
    } else {
      jy -= 1;
      k += 179;
      if (lastLeap == 1) k += 1;
    }
    final int jm = 7 + (k ~/ 30);
    final int jd = (k % 30) + 1;
    return JaDateTime._internal(
        jy, jm, jd, hour, minute, second, millisecond, microsecond, _isUtc);
  }

  /// Normalize values (overflow handling)
  JaDateTime _normalize() {
    int y = year, m = month, d = day;
    int h = hour, min = minute, s = second, ms = millisecond, us = microsecond;
    // Normalize microseconds to milliseconds
    ms += us ~/ 1000;
    us = us.remainder(1000);
    if (us < 0) {
      us += 1000;
      ms -= 1;
    }
    // Normalize milliseconds to seconds
    s += ms ~/ 1000;
    ms = ms.remainder(1000);
    if (ms < 0) {
      ms += 1000;
      s -= 1;
    }
    // Normalize seconds to minutes
    min += s ~/ 60;
    s = s.remainder(60);
    if (s < 0) {
      s += 60;
      min -= 1;
    }
    // Normalize minutes to hours
    h += min ~/ 60;
    min = min.remainder(60);
    if (min < 0) {
      min += 60;
      h -= 1;
    }
    // Normalize hours to days
    d += h ~/ 24;
    h = h.remainder(24);
    if (h < 0) {
      h += 24;
      d -= 1;
    }
    // Normalize days to months
    while (d < 1) {
      m -= 1;
      if (m < 1) {
        m = 12;
        y -= 1;
      }
      d += _monthLength(y, m);
    }
    while (d > _monthLength(y, m)) {
      d -= _monthLength(y, m);
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
    // Normalize months to years
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    return JaDateTime._internal(y, m, d, h, min, s, ms, us, _isUtc);
  }

  /// Helper method to get month length
  int _monthLength(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return _isLeapYear(year) ? 30 : 29;
  }

  bool _isLeapYear(int jy) {
    if (jy < -61 || jy >= 3178) {
      int base = year > 0 ? 474 : 473;
      int cycleYear = ((year - base) % 2820 + 2820) % 2820;
      return (((cycleYear + 474 + 38) * 682) % 2816) < 682;
    }
    return _leapAndCycle(jy) == 0;
  }

  /// Shared internal helper to calculate leap status from Jalali logic.
  int _leapAndCycle(int jy) {
    if (jy < -61 || jy >= 3178) {
      int base = jy > 0 ? 474 : 473;
      int cycleYear = ((jy - base) % 2820 + 2820) % 2820;
      int leap = (((cycleYear + 474 + 38) * 682) % 2816) ~/ 682;
      return leap == 0 ? 0 : 1; // Return 0 for leap year, 1 otherwise
    }

    final _CycleStats stats = _cycleStats(jy);
    int n = jy - stats.lastBreak; // n = years since last break point (jp)
    if (stats.jump - n < 6) {
      n = n - stats.jump + ((stats.jump + 4) ~/ 33) * 33;
    }
    int leap = ((n + 1) % 33 - 1) % 4;
    if (leap == -1) leap = 4;
    return leap;
  }

  int _gregorianYear(int jy) => jy + 621;

  /// Gets the Gregorian March day when Farvardin 1st (Nowruz) starts
  int _startYearMarch(int jy) {
    if (jy < -61 || jy >= 3178) {
      int gy = _gregorianYear(jy);
      int march = ((gy ~/ 4) - ((gy ~/ 100 + 1) * 3 ~/ 4) - 150);
      return 20 - march;
    }
    final int gy = _gregorianYear(jy);
    final _CycleStats stats = _cycleStats(jy);
    final int leapG = gy ~/ 4 - ((gy ~/ 100 + 1) * 3 ~/ 4) - 150;
    return 20 + stats.leapCount - leapG;
  }

  _CycleStats _cycleStats(int jy) {
    if (jy < -61 || jy >= 3178) {
      throw Exception('Year must be between 61 and 3178 in this algorithm');
    }
    // leap year count
    int leapCount = -14;
    // last break year
    int lastBreak = _breaks[0];
    // jump period
    int jump = 0;
    for (int i = 1; i < _breaks.length; i++) {
      // current break year
      int currentBreak = _breaks[i];
      jump = currentBreak - lastBreak;
      if (jy < currentBreak) break;
      leapCount += (jump ~/ 33) * 8 + ((jump % 33) ~/ 4);
      lastBreak = currentBreak;
    }
    // years since the last break
    int fromBreak = jy - lastBreak;
    leapCount += (fromBreak ~/ 33) * 8 + ((fromBreak % 33 + 3) ~/ 4);
    if ((jump % 33) == 4 && jump - fromBreak == 4) leapCount++;
    return _CycleStats(leapCount: leapCount, lastBreak: lastBreak, jump: jump);
  }

  @override
  // TODO: implement secondsSinceEpoch
  int get secondsSinceEpoch => throw UnimplementedError();

  @override
  String toString() {
    String y = _fourDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (_isUtc) {
      return "$y-$m-$d $h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms$us";
    }
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String _threeDigits(int n) {
    if (n >= 100) return "$n";
    if (n >= 10) return "0$n";
    return "00$n";
  }

  String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    int absN = n.abs();
    String sign = n < 0 ? "-" : "+";
    if (absN >= 100000) return "$sign$absN";
    return "${sign}0$absN";
  }
}

/// Helper private class to return results from cycle calculation
class _CycleStats {
  _CycleStats(
      {required this.leapCount, required this.lastBreak, required this.jump});

  /// number of leap years since cycle start
  final int leapCount;

  /// last break year from breaks list
  final int lastBreak;

  /// interval between two break points in the cycle
  final int jump;
}
