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
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// **Normalize values (overflow handling)**
  // HijriDatetime _normalize() {
  //   int y = year, m = month, d = day;
  //   int h = hour, min = minute, s = second, ms = millisecond, us = microsecond;
  //
  //   // Normalize microseconds to milliseconds
  //   ms += us ~/ 1000;
  //   us %= 1000;
  //   if (us < 0) {
  //     us += 1000;
  //     ms -= 1;
  //   }
  //
  //   // Normalize milliseconds to seconds
  //   s += ms ~/ 1000;
  //   ms %= 1000;
  //   if (ms < 0) {
  //     ms += 1000;
  //     s -= 1;
  //   }
  //
  //   // Normalize seconds to minutes
  //   min += s ~/ 60;
  //   s %= 60;
  //   if (s < 0) {
  //     s += 60;
  //     min -= 1;
  //   }
  //
  //   // Normalize minutes.
  //   // When the negative offset comes solely from minutes (with an explicitly provided hour of 0),
  //   // we want to wrap within the day rather than borrowing from the date.
  //   if (h == 0 && min < 0) {
  //     // Instead of cascading (which would subtract a full hour and change the date),
  //     // we add an offset of 60 minutes before doing a modulo on the total minutes.
  //     int totalMinutes = h * 60 + min + 60; // add one hour offset
  //     totalMinutes = ((totalMinutes % 1440) + 1440) % 1440; // normalize to [0,1440)
  //     h = totalMinutes ~/ 60;
  //     min = totalMinutes % 60;
  //   } else {
  //     // Normal cascading: use truncation (which in Dart yields the truncated quotient)
  //     int extra = (min / 60).truncate();
  //     min = min - extra * 60;
  //     h += extra;
  //   }
  //
  //   // Normalize hours to days.
  //
  //   int extra = (h / 24).floor();
  //   h = h - extra * 24;
  //   d += extra;
  //
  //   // Normalize months.
  //   while (m < 1) {
  //     m += 12;
  //     y -= 1;
  //   }
  //   while (m > 12) {
  //     m -= 12;
  //     y += 1;
  //   }
  //
  //   // Normalize days within the month boundaries.
  //   // Underflow: if d < 1, borrow days from the previous month.
  //   while (d < 1) {
  //     m -= 1;
  //     if (m < 1) {
  //       m = 12;
  //       y -= 1;
  //     }
  //     d += _daysInHijriMonth(y, m);
  //   }
  //   // Overflow: if d exceeds the number of days in the current month.
  //   while (d > _daysInHijriMonth(y, m)) {
  //     d -= _daysInHijriMonth(y, m);
  //     m++;
  //     if (m > 12) {
  //       m = 1;
  //       y += 1;
  //     }
  //   }
  //
  //   return HijriDatetime._(y, m, d, h, min, s, ms, us);
  // }

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

    while (d < 1) {
      m -= 1;
      if (m < 1) {
        m = 12;
        y -= 1;
      }
      d += _daysInHijriMonth(y, m);
    }
    // Overflow: if d exceeds the number of days in the current month.
    while (d > _daysInHijriMonth(y, m)) {
      d -= _daysInHijriMonth(y, m);
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

  @override
  // TODO: implement dayOfYear
  int get dayOfYear => throw UnimplementedError();

  @override
  // TODO: implement julianDay
  int get julianDay => throw UnimplementedError();

  @override
  // TODO: implement timeZoneName
  String get timeZoneName => throw UnimplementedError();

  @override
  // TODO: implement timeZoneOffset
  Duration get timeZoneOffset => throw UnimplementedError();

  @override
  GeneralDatetimeInterface add(Duration duration) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Duration difference(GeneralDatetimeInterface other) {
    // TODO: implement difference
    throw UnimplementedError();
  }

  @override
  bool isAfter(GeneralDatetimeInterface other) {
    // TODO: implement isAfter
    throw UnimplementedError();
  }

  @override
  bool isAtSameMomentAs(GeneralDatetimeInterface other) {
    // TODO: implement isAtSameMomentAs
    throw UnimplementedError();
  }

  @override
  bool isBefore(GeneralDatetimeInterface other) {
    // TODO: implement isBefore
    throw UnimplementedError();
  }

  @override
  // TODO: implement microsecondsSinceEpoch
  int get microsecondsSinceEpoch => throw UnimplementedError();

  @override
  // TODO: implement millisecondsSinceEpoch
  int get millisecondsSinceEpoch => throw UnimplementedError();

  @override
  // TODO: implement secondsSinceEpoch
  int get secondsSinceEpoch => throw UnimplementedError();

  @override
  GeneralDatetimeInterface subtract(Duration duration) {
    // TODO: implement subtract
    throw UnimplementedError();
  }
}
