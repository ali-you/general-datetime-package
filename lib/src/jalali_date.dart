import 'package:general_date/src/calendar_interface.dart';

class JalaliDate extends CalendarInterface<JalaliDate> {
  JalaliDate(
    super.year, [
    super.month,
    super.day,
    super.hour,
    super.minute,
    super.second,
    super.millisecond,
    super.microsecond,
  ]);

  static const List<String> _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<int> _daysInMonth = [
    31,
    31,
    31,
    31,
    31,
    31,
    30,
    30,
    30,
    30,
    30,
    29,
  ];

  @override
  String get name => 'Jalali';

  @override
  DateTime toGregorian(int year, int month, int day) {
    int jd = _persianToJulian(year, month, day);
    return _julianToGregorian(jd);
  }

  @override
  JalaliDate fromGregorian(DateTime date) {
    int jd = _gregorianToJulian(date.year, date.month, date.day);
    return _julianToPersian(jd);
  }

  @override
  List<String> getMonths() => _months;

  @override
  List<int> getDaysInMonth(int year, int month) {
    int days = _daysInMonth[month - 1];
    if (month == 12 && isLeapYear(year)) {
      days = 30;
    }
    return List.generate(days, (index) => index + 1);
  }

  @override
  bool isLeapYear(int year) {
    int mod = (year - ((year > 0) ? 474 : 473)) % 2820 + 474;
    return (((mod + 38) * 682) % 2816) < 682;
  }

  // Julian Day for Persian date
  int _persianToJulian(int year, int month, int day) {
    int epBase = year - ((year >= 0) ? 474 : 473);
    int epYear = 474 + (epBase % 2820);
    return day +
        ((month <= 7) ? ((month - 1) * 31) : (((month - 1) * 30) + 6)) +
        (((epYear * 682) - 110) ~/ 2816) +
        (epYear - 1) * 365 +
        (epBase ~/ 2820) * 1029983 +
        (1948320 - 1);
  }

  // Persian Date from Julian Day
  Map<String, int> _julianToPersian(int jd) {
    int depoch = jd - _persianToJulian(475, 1, 1);
    int cycle = depoch ~/ 1029983;
    int cyear = depoch % 1029983;
    int ycycle =
        (cyear != 1029982) ? (((cyear * 2816) + 1031337) ~/ 1028522) : 2820;
    int year = ycycle + (2820 * cycle) + 474;
    year = (year <= 0) ? (year - 1) : year;
    int yday = jd - _persianToJulian(year, 1, 1) + 1;
    int month =
        (yday <= 186) ? ((yday - 1) ~/ 31) + 1 : ((yday - 187) ~/ 30) + 7;
    int day = jd - _persianToJulian(year, month, 1) + 1;
    return {'year': year, 'month': month, 'day': day};
  }

  // Julian Day for Gregorian date
  int _gregorianToJulian(int year, int month, int day) {
    int a = ((14 - month) ~/ 12);
    int y = year + 4800 - a;
    int m = month + (12 * a) - 3;
    return day +
        (((153 * m) + 2) ~/ 5) +
        (365 * y) +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;
  }

  // Gregorian Date from Julian Day
  DateTime _julianToGregorian(int jd) {
    int j = jd + 32044;
    int g = j ~/ 146097;
    int dg = j % 146097;
    int c = ((dg ~/ 36524) + 1) * 3 ~/ 4;
    int dc = dg - (c * 36524);
    int b = dc ~/ 1461;
    int db = dc % 1461;
    int a = ((db ~/ 365) + 1) * 3 ~/ 4;
    int da = db - (a * 365);
    int y = (g * 400) + (c * 100) + (b * 4) + a;
    int m = ((da * 5) + 308) ~/ 153 - 2;
    int d = da - (((m + 4) * 153) ~/ 5) + 122;
    int year = y - 4800 + ((m + 2) ~/ 12);
    int month = (m + 2) % 12 + 1;
    int day = d + 1;
    return DateTime(year, month, day);
  }
}
