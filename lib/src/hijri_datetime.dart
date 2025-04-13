import 'dart:math';

import 'package:general_datetime/src/general_datetime_interface.dart';

import 'constants.dart';

/// Represents a date and time in the **Hijri (Islamic)** calendar system
/// using the **Umm al-Qura** calculation method.
///
/// This class allows seamless handling of Islamic calendar dates,
/// with full time component support (hour, minute, second, etc.).
///
/// It extends [GeneralDatetimeInterface] to maintain consistency
/// with other date systems like Gregorian and Jalali.
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
/// var now = HijriDatetime.now(); // Current Hijri date (Umm al-Qura)
/// print(now); // 1446/9/28
///
/// var hDate = HijriDatetime(1445, 10, 1);
/// print(hDate.toDatetime()); // Converts to corresponding Gregorian date
/// ```
///
/// ### Calendar Notes:
/// The Hijri calendar is a **lunar calendar** consisting of 12 months.
/// The Umm al-Qura system is based on astronomical calculations and is the official
/// calendar of Saudi Arabia, commonly used for religious observances.
///
/// > Note: Dates may differ slightly from observational Hijri calendars used in other countries.
class HijriDatetime extends GeneralDatetimeInterface {
  /// Private constructor for raw inputs
  HijriDatetime._raw(
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
  factory HijriDatetime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return HijriDatetime._raw(
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
  factory HijriDatetime.fromDateTime(DateTime datetime) {
    return HijriDatetime._raw(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
      datetime.isUtc,
    )._toHijri();
  }

  /// Factory constructor for current date and time
  factory HijriDatetime.now() {
    DateTime dt = DateTime.now();
    return HijriDatetime.fromDateTime(dt);
  }

  /// Factory constructor for current date and time in UTC
  factory HijriDatetime.timestamp() {
    final DateTime dt = DateTime.now().toUtc();
    return HijriDatetime.fromDateTime(dt);
  }

  /// Factory constructor in UTC with normalization
  factory HijriDatetime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) =>
      HijriDatetime._raw(
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

  factory HijriDatetime.fromSecondsSinceEpoch(int secondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        secondsSinceEpoch * 1000,
        isUtc: isUtc);
    return HijriDatetime.fromDateTime(dt);
  }

  factory HijriDatetime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch,
        isUtc: isUtc);
    return HijriDatetime.fromDateTime(dt);
  }

  factory HijriDatetime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch,
      {bool isUtc = false}) {
    final DateTime dt = DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc);
    return HijriDatetime.fromDateTime(dt);
  }

  factory HijriDatetime.parse(String formattedString) {
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

      return HijriDatetime._raw(
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

  static HijriDatetime? tryParse(String formattedString) {
    try {
      return HijriDatetime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// The calendar name
  @override
  String get name => "Hijri";

  /// Calculate weekday (0=Saturday, 6=Friday)
  @override
  int get weekday {
    DateTime gregorian = toDatetime();
    return (gregorian.weekday) % 7;
  }

  /// Get days in the current month
  @override
  int get monthLength => _monthLength(year, month);

  /// This computes the day count within the Hijri year.
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
  bool get isLeapYear {
    return (((11 * year) + 14) % 30) < 11;
  }

  /// Julian Day Number getter
  /// For HijriDatetime we use the computed JD (rounded down).
  @override
  int get julianDay => _hijriToJD(year, month, day).floor();

  /// Conversion from HijriDatetime(Umm al-Qura) to DateTime (Hijri to Gregorian)
  /// This method uses an approximate conversion via Julian day calculations.
  /// For a given Hijri date, we compute its Julian Day Number (JD) using
  /// an approximation formula and then convert the JD to the Gregorian date.
  /// This method uses the Fliegel-Van Flandern algorithm.
  @override
  DateTime toDatetime() {
    int l = julianDay + 68569;
    int n = (4 * l) ~/ 146097;
    l = l - ((146097 * n + 3) ~/ 4);
    int i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    int j1 = (80 * l) ~/ 2447;
    int dayG = l - (2447 * j1) ~/ 80;
    l = j1 ~/ 11;
    int monthG = j1 + 2 - 12 * l;
    int yearG = 100 * (n - 49) + i + l;

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

  /// Add a Duration to the Hijri date
  @override
  GeneralDatetimeInterface add(Duration duration) {
    DateTime result = toDatetime().add(duration);
    return HijriDatetime.fromDateTime(result);
  }

  /// Subtract a Duration from the Hijri date
  @override
  GeneralDatetimeInterface subtract(Duration duration) {
    DateTime result = toDatetime().subtract(duration);
    return HijriDatetime.fromDateTime(result);
  }

  /// Convert to local time
  @override
  GeneralDatetimeInterface toLocal() {
    DateTime localDt = toDatetime().toLocal();
    return HijriDatetime.fromDateTime(localDt);
  }

  /// Convert to UTC time
  @override
  GeneralDatetimeInterface toUtc() {
    DateTime utcDt = toDatetime().toUtc();
    return HijriDatetime.fromDateTime(utcDt);
  }

  /// Conversion from Gregorian to Hijri (Umm al-Qura)
  /// This method converts the current Gregorian date (stored in the instance)
  /// to a Hijri date according to an approximate algorithm. It computes the
  /// Julian Day Number (JD) of the Gregorian date and then derives the Hijri date.
  HijriDatetime _toHijri() {
    int gy = year;
    int gm = month;
    int gd = day;
    // Convert Gregorian date to Julian Day Number (JD)
    int a = ((14 - gm) ~/ 12);
    int y = gy + 4800 - a;
    int m = gm + 12 * a - 3;
    double jd = gd +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
    // Adjust JD to align with Islamic epoch.
    // The following formula is an approximation.
    int hYear = ((30 * (jd - 1948439.5) + 10646) / 10631).floor();
    double firstDayOfHijriYear = _hijriToJD(hYear, 1, 1);
    int hMonth = min(12, ((jd - firstDayOfHijriYear) / 29.5).ceil() + 1);
    double firstDayOfHijriMonth = _hijriToJD(hYear, hMonth, 1);
    int hDay = (jd - firstDayOfHijriMonth).floor() + 1;

    return HijriDatetime._raw(hYear, hMonth, hDay, hour, minute, second,
        millisecond, microsecond, isUtc);
  }

  /// **Normalize values (overflow handling)**
  HijriDatetime _normalize() {
    int y = year, m = month, d = day;
    int h = hour, min = minute, s = second, ms = millisecond, us = microsecond;
    // Normalize microseconds to milliseconds.
    ms += us ~/ 1000;
    us = us.remainder(1000);
    if (us < 0) {
      us += 1000;
      ms -= 1;
    }
    // Normalize milliseconds to seconds.
    s += ms ~/ 1000;
    ms = ms.remainder(1000);
    if (ms < 0) {
      ms += 1000;
      s -= 1;
    }
    // Normalize seconds to minutes.
    min += s ~/ 60;
    s = s.remainder(60);
    if (s < 0) {
      s += 60;
      min -= 1;
    }
    // Normalize minutes to hours.
    h += min ~/ 60;
    min = min.remainder(60);
    if (min < 0) {
      min += 60;
      h -= 1;
    }
    // Normalize hours to days.
    d += h ~/ 24;
    h = h.remainder(24);
    if (h < 0) {
      h += 24;
      d -= 1;
    }
    // Normalize days within Hijri month boundaries.
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
      m++;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
    // Normalize months to years.
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    return HijriDatetime._raw(y, m, d, h, min, s, ms, us);
  }

  /// Helper method to get month length
  /// In the Umm al-Qura calendar, months are typically alternately 30 and 29 days,
  /// with the last month having 30 days in a leap year.
  int _monthLength(int year, int month) {
    if (month == 12 && isLeapYear) return 30;
    return (month % 2 == 1) ? 30 : 29;
  }

  /// Helper method to convert Hijri date to Julian Day Number (JD)
  /// The following formula is an approximation adapted for the Umm al-Qura system.
  double _hijriToJD(int year, int month, int day) {
    // Using an approximation formula for the Islamic calendar:
    // JD = day + ceil(29.5 * (month - 1)) + (year - 1) * 354 +
    //      floor((3 + (11 * year)) / 30) + 1948440 - 1
    return day +
        (29.5 * (month - 1)).ceilToDouble() +
        (year - 1) * 354 +
        ((3 + (11 * year)) / 30).floor() +
        1948440 -
        1;
  }
}
