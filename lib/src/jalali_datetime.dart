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

  double persiana_to_jd() {
    double guess, adr1, adr2, equinox;

    guess = (1948320.5 - 1) + (365.2422 * ((year - 1) - 1));
    adr1 = year - 1;
    equinox = 1948320.5 + (adr1 * 365) + (adr1 / 4).floor();

    return equinox +
        ((month <= 7) ?
        ((month - 1) * 31) :
        (((month - 1) * 30) + 6)
        ) +
        (day - 1);
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

  /// Helper method to check if a Jalali year is leap
  bool _isLeapYear(int year) {
    final adjustedYear = (year > 0 ? year - 474 : year - 473);
    final cycleYear = (adjustedYear % 2820) + 474;
    return (((cycleYear + 38) * 682) % 2816) < 682;
  }
}
