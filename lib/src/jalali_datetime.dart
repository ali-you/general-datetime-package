import 'package:general_date/src/calendar_interface.dart';

// class JalaliDatetime extends CalendarInterface<JalaliDatetime> {
//   JalaliDatetime(
//     super.year, [
//     super.month,
//     super.day,
//     super.hour,
//     super.minute,
//     super.second,
//     super.millisecond,
//     super.microsecond,
//   ]);
//
//   // JalaliDate.fromDatetime(DateTime datetime)
//   //   : super(
//   //       datetime.year,
//   //       datetime.month,
//   //       datetime.day,
//   //       datetime.hour,
//   //       datetime.minute,
//   //       datetime.second,
//   //       datetime.minute,
//   //       datetime.microsecond,
//   //     ){
//   //   int jd = _gregorianToJulian(year, month, day);
//   //   JalaliDate converted = _julianToPersian(jd);
//   //   return converted;
//   // }
//
//   factory JalaliDatetime.fromDatetime(DateTime datetime) {
//     int jd = _gregorianToJulian(datetime.year, datetime.month, datetime.day);
//     return _julianToPersian(jd);
//   }
//
//   static const List<String> _months = [
//     'فروردین',
//     'اردیبهشت',
//     'خرداد',
//     'تیر',
//     'مرداد',
//     'شهریور',
//     'مهر',
//     'آبان',
//     'آذر',
//     'دی',
//     'بهمن',
//     'اسفند',
//   ];
//
//   static const List<int> _daysInMonth = [
//     31,
//     31,
//     31,
//     31,
//     31,
//     31,
//     30,
//     30,
//     30,
//     30,
//     30,
//     29,
//   ];
//
//   @override
//   String get name => 'Jalali';
//
//   @override
//   DateTime toDatetime(JalaliDatetime customDatetime) {
//     int jd = _persianToJulian(year, month, day);
//     return _julianToGregorian(jd);
//   }
//
//   JalaliDatetime _fromGregorian(DateTime date) {
//     int jd = _gregorianToJulian(date.year, date.month, date.day);
//     return _julianToPersian(jd);
//   }
//
//   @override
//   List<String> getMonths() => _months;
//
//   @override
//   List<int> getDaysInMonth(int year, int month) {
//     int days = _daysInMonth[month - 1];
//     if (month == 12 && isLeapYear(year)) {
//       days = 30;
//     }
//     return List.generate(days, (index) => index + 1);
//   }
//
//   @override
//   bool isLeapYear(int year) {
//     int mod = (year - ((year > 0) ? 474 : 473)) % 2820 + 474;
//     return (((mod + 38) * 682) % 2816) < 682;
//   }
//
//   int _persianToJulian(int year, int month, int day) {
//     int epBase = year - ((year >= 0) ? 474 : 473);
//     int epYear = 474 + (epBase % 2820);
//     return day +
//         ((month <= 7) ? ((month - 1) * 31) : (((month - 1) * 30) + 6)) +
//         (((epYear * 682) - 110) ~/ 2816) +
//         (epYear - 1) * 365 +
//         (epBase ~/ 2820) * 1029983 +
//         (1948320 - 1);
//   }
//
//   JalaliDatetime _julianToPersian(int jd) {
//     int depoch = jd - _persianToJulian(475, 1, 1);
//     int cycle = depoch ~/ 1029983;
//     int cyear = depoch % 1029983;
//     int ycycle =
//         (cyear != 1029982) ? (((cyear * 2816) + 1031337) ~/ 1028522) : 2820;
//     int year = ycycle + (2820 * cycle) + 474;
//     year = (year <= 0) ? (year - 1) : year;
//     int yday = jd - _persianToJulian(year, 1, 1) + 1;
//     int month =
//         (yday <= 186) ? ((yday - 1) ~/ 31) + 1 : ((yday - 187) ~/ 30) + 7;
//     int day = jd - _persianToJulian(year, month, 1) + 1;
//     return JalaliDatetime(year, month, day);
//   }
//
//   int _gregorianToJulian(int year, int month, int day) {
//     int a = ((14 - month) ~/ 12);
//     int y = year + 4800 - a;
//     int m = month + (12 * a) - 3;
//     return day +
//         (((153 * m) + 2) ~/ 5) +
//         (365 * y) +
//         (y ~/ 4) -
//         (y ~/ 100) +
//         (y ~/ 400) -
//         32045;
//   }
//
//   DateTime _julianToGregorian(int jd) {
//     int j = jd + 32044;
//     int g = j ~/ 146097;
//     int dg = j % 146097;
//     int c = ((dg ~/ 36524) + 1) * 3 ~/ 4;
//     int dc = dg - (c * 36524);
//     int b = dc ~/ 1461;
//     int db = dc % 1461;
//     int a = ((db ~/ 365) + 1) * 3 ~/ 4;
//     int da = db - (a * 365);
//     int y = (g * 400) + (c * 100) + (b * 4) + a;
//     int m = ((da * 5) + 308) ~/ 153 - 2;
//     int d = da - (((m + 4) * 153) ~/ 5) + 122;
//     int year = y - 4800 + ((m + 2) ~/ 12);
//     int month = (m + 2) % 12 + 1;
//     int day = d + 1;
//     return DateTime(year, month, day);
//   }
// }

class JalaliDatetime extends CalendarInterface {
  JalaliDatetime(
    super.year, [
    super.month,
    super.day,
    super.hour,
    super.minute,
    super.second,
    super.millisecond,
    super.microsecond,
  ]);

  factory JalaliDatetime.fromDatetime(DateTime dateTime) {
    final jalali = _gregorianToJalali(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    return JalaliDatetime(
      jalali[0],
      jalali[1],
      jalali[2],
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
  }

  @override
  String get name => "Jalali";

  @override
  DateTime toDatetime() {
    final gregorian = _jalaliToGregorian(year, month, day);
    return DateTime(
      gregorian[0],
      gregorian[1],
      gregorian[2],
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  @override
  bool get isLeapYear {
    final List<int> leapYears = [1, 5, 9, 13, 17, 22, 26, 30];
    return leapYears.contains(year % 33);
  }


  static List<int> _gregorianToJalali(int gy, int gm, int gd) {
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
    return [jy, jm, jd];
  }

  List<int> _jalaliToGregorian(int jy, int jm, int jd) {
    jy += 1595;
    int days =
        -355668 + (365 * jy) + ((jy ~/ 33) * 8) + (((jy % 33) + 3) ~/ 4) + jd;
    days += (jm < 7) ? (jm - 1) * 31 : ((jm - 7) * 30) + 186;
    int gy = 400 * (days ~/ 146097);
    days %= 146097;
    if (days > 36524) {
      days--;
      gy += 100 * (days ~/ 36524);
      days %= 36524;
      if (days >= 365) days++;
    }
    gy += 4 * (days ~/ 1461);
    days %= 1461;
    gy += (days - 1) ~/ 365;
    if (days > 365) days = (days - 1) % 365;
    int gd = days + 1;
    List<int> gm = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0)) gm[2] = 29;
    int i = 1;
    while (gd > gm[i]) gd -= gm[i++];
    return [gy, i, gd];
  }

  @override
  String toString() {
    return "JalaliDatetime: $year-$month-$day $hour:$minute:$second";
  }
}
