import 'general_datetime_interface.dart';

class JalaliDatetime extends GeneralDatetimeInterface {
  /// Private constructor
  JalaliDatetime._(
      super.year, [
        super.month,
        super.day,
        super.hour,
        super.minute,
        super.second,
        super.millisecond,
        super.microsecond,
      ]);

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
    return JalaliDatetime._(
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
  factory JalaliDatetime.fromDatetime(DateTime datetime) {
    return JalaliDatetime._(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
    )._toJalali();
  }

  /// Factory constructor for current date and time
  factory JalaliDatetime.now() {
    DateTime datetime = DateTime.now();
    return JalaliDatetime._(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
    )._toJalali();
  }

  /// Calendar name
  @override
  String get name => "Jalali";

  /// Convert Jalali date to DateTime
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

  /// Check if the year is a leap year
  @override
  bool get isLeapYear {
    final List<int> leapYears = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapYears.contains(year % 33);
  }

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
    int days =
        (365 * gy) +
            ((gy2 + 3) ~/ 4) -
            ((gy2 + 99) ~/ 100) +
            ((gy2 + 399) ~/ 400) -
            80 +
            gd;
    for (int i = 0; i < gm; ++i) days += gDM[i];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    jy += (days - 1) ~/ 365;
    if (days > 365) days = (days - 1) % 365;
    int jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    int jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return JalaliDatetime._(
      jy,
      jm,
      jd,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
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
      d += _daysInJalaliMonth(y, m);
    }
    while (d > _daysInJalaliMonth(y, m)) {
      d -= _daysInJalaliMonth(y, m);
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

    return JalaliDatetime._(y, m, d, h, min, s, ms, us);
  }

  /// Get days in the current month
  @override
  int get monthLength => _daysInJalaliMonth(year, month);

  /// Calculate weekday (0=Saturday, 6=Friday)
  @override
  int get weekday {
    DateTime gregorian = toDatetime();
    return (gregorian.weekday) % 7;
  }

  /// Compare Jalali dates
  @override
  int compareTo(GeneralDatetimeInterface other) {
    return toDatetime().compareTo(other.toDatetime());
  }

  /// Helper method to get month length
  int _daysInJalaliMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return _isJalaliLeapYear(year) ? 30 : 29;
  }

  /// Check if a Jalali year is leap
  bool _isJalaliLeapYear(int year) {
    final List<int> leapYears = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapYears.contains(year % 33);
  }

  /// Julian Day Number getter
  @override
  int get julianDay {
    int totalDays = 0;
    for (int k = 1; k < year; k++) {
      totalDays += 365;
      if (_isJalaliLeapYear(k)) totalDays += 1;
    }
    for (int m = 1; m < month; m++) {
      totalDays += _daysInJalaliMonth(year, m);
    }
    totalDays += day - 1;
    return 1948320 + totalDays;
  }

  @override
  // TODO: implement dayOfYear
  int get dayOfYear => throw UnimplementedError();
}