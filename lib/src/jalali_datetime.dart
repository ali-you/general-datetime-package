import 'general_datetime_interface.dart';

class JalaliDatetime extends GeneralDatetimeInterface {
  /// Private constructor
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
  factory JalaliDatetime.fromDatetime(DateTime datetime) {
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
    final DateTime datetime = DateTime.now();
    return JalaliDatetime._raw(
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

  /// Factory constructor for current date and time in UTC
  factory JalaliDatetime.timestamp() {
    final DateTime datetime = DateTime.now().toUtc();
    return JalaliDatetime._raw(
      datetime.year,
      datetime.month,
      datetime.day,
      datetime.hour,
      datetime.minute,
      datetime.second,
      datetime.millisecond,
      datetime.microsecond,
      true,
    )._toJalali();
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
      true,
    )._normalize();
  }

  factory JalaliDatetime.fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
  }) {
    final DateTime datetime = DateTime.fromMillisecondsSinceEpoch(
      secondsSinceEpoch * 1000,
      isUtc: isUtc,
    );
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

  factory JalaliDatetime.fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    final DateTime datetime = DateTime.fromMillisecondsSinceEpoch(
      millisecondsSinceEpoch,
      isUtc: isUtc,
    );
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

  factory JalaliDatetime.fromMicrosecondsSinceEpoch(
    int microsecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    final DateTime datetime = DateTime.fromMicrosecondsSinceEpoch(
      microsecondsSinceEpoch,
      isUtc: isUtc,
    );
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

  factory JalaliDatetime.parse(String formattedString) {
    final re = _parseFormat; // Define your regex pattern elsewhere
    Match? match = re.firstMatch(formattedString);

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

      return JalaliDatetime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
    } else {
      throw FormatException("Invalid date format", formattedString);
    }
  }

  static JalaliDatetime? tryParse(String formattedString) {
    try {
      return JalaliDatetime.parse(formattedString);
    } on FormatException {
      return null;
    }
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
    return JalaliDatetime._raw(
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
      d += daysInJalaliMonth(y, m);
    }
    while (d > daysInJalaliMonth(y, m)) {
      d -= daysInJalaliMonth(y, m);
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

    return JalaliDatetime._raw(y, m, d, h, min, s, ms, us);
  }

  /// Get days in the current month
  @override
  int get monthLength => daysInJalaliMonth(year, month);

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
  int daysInJalaliMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return _isJalaliLeapYear(year) ? 30 : 29;
  }

  /// Check if a Jalali year is leap
  // Helper: Check if a Jalali year is leap.
  bool _isJalaliLeapYear(int jy) {
    // Special case: Year 1 is not a leap year.
    if (jy == 1) return false;

    // Calculate the remainder in the 33-year cycle.
    int r = jy % 33;
    // Make sure we have a positive remainder.
    if (r < 0) r += 33;

    // Leap years in the 33-year cycle occur in these remainders.
    const leapRemainders = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapRemainders.contains(r);
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
      totalDays += daysInJalaliMonth(year, m);
    }
    totalDays += day - 1;
    return 1948321 + totalDays;
  }

  @override
  // TODO: implement dayOfYear
  int get dayOfYear => throw UnimplementedError();

  @override
  DateTime add(Duration duration) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Duration difference(GeneralDatetimeInterface other) {
    // TODO: implement difference
    throw UnimplementedError();
  }

  @override
  bool isAfter(DateTime other) {
    // TODO: implement isAfter
    throw UnimplementedError();
  }

  @override
  bool isAtSameMomentAs(DateTime other) {
    // TODO: implement isAtSameMomentAs
    throw UnimplementedError();
  }

  @override
  bool isBefore(DateTime other) {
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
  DateTime subtract(Duration duration) {
    // TODO: implement subtract
    throw UnimplementedError();
  }

  @override
  // TODO: implement timeZoneName
  String get timeZoneName => throw UnimplementedError();

  @override
  // TODO: implement timeZoneOffset
  Duration get timeZoneOffset => throw UnimplementedError();


  static final RegExp _parseFormat = RegExp(
    r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' // Day part.
    r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:[.,](\d+))?)?)?' // Time part.
    r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$',
  ); // Timezone part.

}
