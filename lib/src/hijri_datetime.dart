import 'dart:math';

import 'package:general_datetime/src/general_datetime_interface.dart';

class HijriDatetime extends GeneralDatetimeInterface {
  /// **Private constructor**
  HijriDatetime._(
    super.year, [
    super.month,
    super.day,
    super.hour,
    super.minute,
    super.second,
    super.millisecond,
    super.microsecond,
  ]);

  /// **Factory constructor with normalization**
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
    return HijriDatetime._(
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

  /// **Factory constructor for converting from DateTime (Gregorian)**
  factory HijriDatetime.fromDatetime(DateTime datetime) {
    return HijriDatetime._(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
    )._toHijri();
  }

  /// **Factory constructor for getting the current Hijri date**
  factory HijriDatetime.now() {
    DateTime datetime = DateTime.now();
    return HijriDatetime.fromDatetime(datetime);
  }

  /// **Calendar name**
  @override
  String get name => "Hijri (Umm al-Qura)";

  ///
  /// ### Conversion from Hijri (Umm al-Qura) to Gregorian
  ///
  /// This method uses an approximate conversion via Julian day calculations.
  /// For a given Hijri date, we compute its Julian Day Number (JD) using
  /// an approximation formula and then convert the JD to the Gregorian date.
  ///
  @override
  DateTime toDatetime() {
    double jd = _hijriToJD(year, month, day);
    return _jdToGregorian(jd);
  }

  /// **Check if the Hijri year is a leap year (approximation)**
  ///
  /// In the Islamic calendar the leap year rule is usually given by:
  /// if (((11 * year) + 14) % 30) < 11 then it is a leap year.
  @override
  bool get isLeapYear {
    return (((11 * year) + 14) % 30) < 11;
  }

  ///
  /// ### Conversion from Gregorian to Hijri (Umm al-Qura)
  ///
  /// This method converts the current Gregorian date (stored in the instance)
  /// to a Hijri date according to an approximate algorithm. It computes the
  /// Julian Day Number (JD) of the Gregorian date and then derives the Hijri date.
  ///
  HijriDatetime _toHijri() {
    double jd = _gregorianToJD(year, month, day);
    // Adjust JD to align with Islamic epoch
    // The following formula is an approximation.
    int hYear = ((30 * (jd - 1948439.5) + 10646) / 10631).floor();
    double firstDayOfHijriYear = _hijriToJD(hYear, 1, 1);
    int hMonth = min(12, ((jd - firstDayOfHijriYear) / 29.5).ceil() + 1);
    double firstDayOfHijriMonth = _hijriToJD(hYear, hMonth, 1);
    int hDay = (jd - firstDayOfHijriMonth).floor() + 1;

    return HijriDatetime._(
      hYear,
      hMonth,
      hDay,
      this.hour,
      this.minute,
      this.second,
      this.millisecond,
      this.microsecond,
    );
  }

  /// **Normalize values (overflow handling)**
  HijriDatetime _normalize() {
    int y = year, m = month, d = day;
    int h = hour, min = minute, s = second, ms = millisecond, us = microsecond;

    ms += us ~/ 1000;
    us %= 1000;

    s += ms ~/ 1000;
    ms %= 1000;

    min += s ~/ 60;
    s %= 60;

    h += min ~/ 60;
    min %= 60;

    d += h ~/ 24;
    h %= 24;

    while (d > _daysInHijriMonth(y, m)) {
      d -= _daysInHijriMonth(y, m);
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }

    return HijriDatetime._(y, m, d, h, min, s, ms, us);
  }

  /// **Get days in the current Hijri month**
  @override
  int get monthLength => _daysInHijriMonth(year, month);

  /// **Calculate weekday (0=Saturday, 6=Friday)**
  @override
  int get weekday {
    DateTime gregorian = toDatetime();
    return (gregorian.weekday) % 7;
  }

  /// **Compare Hijri dates**
  @override
  int compareTo(GeneralDatetimeInterface other) {
    return toDatetime().compareTo(other.toDatetime());
  }

  /// **Helper method to get month length**
  ///
  /// In the Umm al-Qura calendar, months are typically alternately 30 and 29 days,
  /// with the last month having 30 days in a leap year.
  int _daysInHijriMonth(int year, int month) {
    if (month == 12 && isLeapYear) return 30;
    return (month % 2 == 1) ? 30 : 29;
  }

  /// **Convert Hijri date to Julian Day Number (JD)**
  ///
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

  /// **Convert Gregorian date to Julian Day Number (JD)**
  double _gregorianToJD(int year, int month, int day) {
    int a = ((14 - month) ~/ 12);
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }

  /// **Convert a Julian Day Number to Gregorian Date**
  ///
  /// This method uses the Fliegel-Van Flandern algorithm.
  DateTime _jdToGregorian(double jd) {
    int j = jd.floor();
    int l = j + 68569;
    int n = (4 * l) ~/ 146097;
    l = l - ((146097 * n + 3) ~/ 4);
    int i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    int j1 = (80 * l) ~/ 2447;
    int d = l - (2447 * j1) ~/ 80;
    l = j1 ~/ 11;
    int m = j1 + 2 - 12 * l;
    int y = 100 * (n - 49) + i + l;
    return DateTime(y, m, d, hour, minute, second, millisecond, microsecond);
  }

  /// **String representation**
  @override
  String toString() {
    return "HijriDatetime (Umm al-Qura): $year-$month-$day $hour:$minute:$second";
  }
}
