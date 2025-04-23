import 'package:general_datetime/src/constants.dart';

import 'general_datetime_interface.dart';

/// Represents a date and time in the **Jalali (Persian/Iranian)** calendar system.
///
/// This class provides conversion between Gregorian and Jalali dates,
/// along with time component support (hour, minute, second, etc).
///
/// It extends the [GeneralDatetimeInterface] to support consistent behavior
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
/// var now = JalaliDatetime.now(); // Get current Jalali date and time
/// print(now); // 1403/1/19
///
/// var jDate = JalaliDatetime(1402, 12, 30);
/// print(jDate.toDatetime()); // Converts to equivalent Gregorian date
/// ```
///
/// ### Calendar Notes:
/// The Jalali calendar is a solar calendar used in Iran and Afghanistan,
/// with highly accurate leap year rules and month lengths.
class JalaliDatetime extends GeneralDatetimeInterface<JalaliDatetime> {
  /// Private constructor for raw inputs
  JalaliDatetime._raw(
    super.year, [
    super.month,
    super.day,
    super.hour,
    super.minute,
    super.second,
    super.millisecond,
    super.microsecond,
    super.isUtc,
  ]);

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
  factory JalaliDatetime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return JalaliDatetime._raw(
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
  factory JalaliDatetime.fromDateTime(DateTime datetime) {
    return JalaliDatetime._raw(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
      datetime.isUtc,
    )._toJalali();
  }

  /// Factory constructor for current date and time
  factory JalaliDatetime.now() {
    final DateTime dt = DateTime.now();
    return JalaliDatetime.fromDateTime(dt);
  }

  /// Factory constructor for current date and time in UTC
  factory JalaliDatetime.timestamp() {
    final DateTime dt = DateTime.now().toUtc();
    return JalaliDatetime.fromDateTime(dt);
  }

  /// Factory constructor in UTC with normalization
  factory JalaliDatetime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) =>
      JalaliDatetime._raw(
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

  factory JalaliDatetime.fromSecondsSinceEpoch(int secondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        secondsSinceEpoch * 1000,
        isUtc: isUtc);
    return JalaliDatetime.fromDateTime(dt);
  }

  factory JalaliDatetime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
        isUtc: isUtc);
    return JalaliDatetime.fromDateTime(dt);
  }

  factory JalaliDatetime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc);
    return JalaliDatetime.fromDateTime(dt);
  }

  factory JalaliDatetime.parse(String formattedString) {
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

      return JalaliDatetime._raw(
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

  static JalaliDatetime? tryParse(String formattedString) {
    try {
      return JalaliDatetime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// The calendar name
  @override
  String get name => "Jalali";

  /// Calculate weekday (0=Saturday, 6=Friday)
  @override
  int get weekday {
    DateTime gd = toDatetime();
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

  // static double persianToJd(int year, int month, int day) {
  //   var adr, equinox, guess, jd;
  //   guess = (PERSIAN_EPOCH - 1) + (TropicalYear * ((year - 1) - 1));
  //   adr = [year - 1, 0];
  //   while (adr[0] < year){
  //     adr = persianYear(guess);
  //     guess = adr[1] + (TropicalYear + 2);
  //   }
  //   equinox = adr[1];
  //   jd = equinox +
  //       ((month <= 7) ?
  //       ((month - 1) * 31) :
  //       (((month - 1) * 30) + 6)
  //       ) +
  //       (day - 1);
  //   return jd;
  // }

  /// Julian Day Number getter
  @override
  int get julianDay {
    int totalDays = 0;
    for (int k = 1; k < year; k++) {
      totalDays += 365;
      if (_isLeapYear(k)) totalDays += 1;
    }
    for (int m = 1; m < month; m++) {
      totalDays += _monthLength(year, m);
    }
    totalDays += day - 1;
    return 1948321 + totalDays;
  }

  /// Conversion from JalaliDatetime to DateTime (Jalali to Gregorian)
  /// This method uses an approximate conversion via Julian day calculations.
  /// For a given Jalali date, we compute its Julian Day Number (JD) using
  /// an approximation formula and then convert the JD to the Gregorian date.
  @override
  DateTime toDatetime() {
    int a = julianDay + 32044;
    int b = ((4 * a) + 3) ~/ 146097;
    int c = a - ((146097 * b) ~/ 4);
    int d = ((4 * c) + 3) ~/ 1461;
    int e = c - ((1461 * d) ~/ 4);
    int m = ((5 * e) + 2) ~/ 153;
    int dayG = e - ((153 * m + 2) ~/ 5) + 1;
    int monthG = m + 3 - 12 * (m ~/ 10);
    int yearG = 100 * b + d - 4800 + (m ~/ 10);
    if (isUtc) {
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
  JalaliDatetime add(Duration duration) {
    final DateTime result = toDatetime().add(duration);
    return JalaliDatetime.fromDateTime(result);
  }

  /// Subtract a Duration from the Jalali date
  @override
  JalaliDatetime subtract(Duration duration) {
    final DateTime result = toDatetime().subtract(duration);
    return JalaliDatetime.fromDateTime(result);
  }

  /// Convert to local time
  @override
  JalaliDatetime toLocal() {
    if (!isUtc) return this;
    final localDt = toDatetime().toLocal();
    return JalaliDatetime.fromDateTime(localDt);
  }

  /// Convert to UTC time
  @override
  JalaliDatetime toUtc() {
    if (isUtc) return this;
    final utcDt = toDatetime().toUtc();
    return JalaliDatetime.fromDateTime(utcDt);
  }

  // /// Convert from Gregorian to Jalali
  // JalaliDatetime _toJalali() {
  //   final int gDayNo =
  //       DateTime(year, month, day).difference(DateTime(0)).inDays;
  //
  //   int jy = year - 621;
  //   int gDayNo1 = DateTime(_gregorianYear(jy), 3, _startYearMarch(jy))
  //       .difference(DateTime(0))
  //       .inDays;
  //
  //   int jDayNo = gDayNo - gDayNo1;
  //
  //   if (jDayNo >= 0) {
  //     if (jDayNo <= 185) {
  //       return JalaliDatetime._raw(jy, 1 + jDayNo ~/ 31, (jDayNo % 31) + 1,
  //           hour, minute, second, millisecond, microsecond, isUtc);
  //     } else {
  //       jDayNo -= 186;
  //       return JalaliDatetime._raw(jy, 7 + jDayNo ~/ 30, (jDayNo % 30) + 1,
  //           hour, minute, second, millisecond, microsecond, isUtc);
  //     }
  //   } else {
  //     jy -= 1;
  //     final int prevDayNo = DateTime(_gregorianYear(jy), 3, _startYearMarch(jy))
  //         .difference(DateTime(0))
  //         .inDays;
  //     jDayNo = gDayNo - prevDayNo;
  //     if (jDayNo <= 185) {
  //       return JalaliDatetime._raw(jy, 1 + jDayNo ~/ 31, (jDayNo % 31) + 1,
  //           hour, minute, second, millisecond, microsecond, isUtc);
  //     } else {
  //       jDayNo -= 186;
  //       return JalaliDatetime._raw(jy, 7 + jDayNo ~/ 30, (jDayNo % 30) + 1,
  //           hour, minute, second, millisecond, microsecond, isUtc);
  //     }
  //   }
  // }

  /// Convert from Gregorian to Jalali
  JalaliDatetime _toJalali() {
    int gy = year;
    int gm = month;
    int gd = day;
    List<int> gDM = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int jy;
    if (gy > 1600) {
      jy = 979;
      gy -= 1600;
    } else {
      jy = 0;
      gy -= 621;
    }
    int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) -
        80 +
        gd;
    for (int i = 0; i < gm; ++i) {
      days += gDM[i];
    }
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    jy += (days - 1) ~/ 365;
    if (days > 365) days = (days - 1) % 365;
    int jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    int jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return JalaliDatetime._raw(
        jy, jm, jd, hour, minute, second, millisecond, microsecond, isUtc);
  }

  /// Normalize values (overflow handling)
  JalaliDatetime _normalize() {
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
    return JalaliDatetime._raw(y, m, d, h, min, s, ms, us, isUtc);
  }

  /// Helper method to get month length
  int _monthLength(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return _isLeapYear(year) ? 30 : 29;
  }

  // bool _isLeapYear(int jy) {
  //   // Special case: Year 1 is not a leap year.
  //   if (jy == 1) return false;
  //   // Calculate the remainder in the 33-year cycle.
  //   // Make sure we have a positive remainder.
  //   int r = jy % 33;
  //   if (r < 0) r += 33;
  //   // Leap years in the 33-year cycle occur in these remainders.
  //   const leapRemainders = [1, 5, 9, 13, 17, 22, 26, 30];
  //   return leapRemainders.contains(r);
  // }

  // bool _isLeapYear(int jy) {
  //     int base = year > 0 ? 474 : 473;
  //     int cycleYear = ((year - base) % 2820 + 2820) % 2820; // ensures positive mod
  //     return (((cycleYear + 474 + 38) * 682) % 2816) < 682;
  //
  //
  // }

  bool _isLeapYear(int jy) => _leapAndCycle(jy) == 0;

  /// Shared internal helper to calculate leap status from Jalali logic.
  int _leapAndCycle(int jy) {
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
    final int gy = _gregorianYear(jy);
    final _CycleStats stats = _cycleStats(jy);
    final int leapG = gy ~/ 4 - ((gy ~/ 100 + 1) * 3 ~/ 4) - 150;
    return 20 + stats.leapCount - leapG;
  }

  _CycleStats _cycleStats(int jy) {
    if (jy < -61 || jy >= 3178) {
      throw StateError('Year out of range');
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
