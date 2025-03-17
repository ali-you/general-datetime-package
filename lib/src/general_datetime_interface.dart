abstract class GeneralDatetimeInterface
    implements Comparable<GeneralDatetimeInterface> {
  GeneralDatetimeInterface(
    this.year, [
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
    this.microsecond = 0,
  ]);

  final int year;
  final int month;
  final int day;

  final int hour;
  final int minute;
  final int second;
  final int millisecond;
  final int microsecond;

  String get name;

  DateTime toDatetime();

  bool get isLeapYear;

  Duration get time => Duration(
    hours: hour,
    minutes: minute,
    seconds: second,
    microseconds: microsecond,
    milliseconds: millisecond,
  );

  int get weekday;

  int get monthLength;

  int get dayOfYear;

  int get julianDay;

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

  // String _sixDigits(int n) {
  //   assert(n < -9999 || n > 9999);
  //   int absN = n.abs();
  //   String sign = n < 0 ? "-" : "+";
  //   if (absN >= 100000) return "$sign$absN";
  //   return "${sign}0$absN";
  // }

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
    // if (isUtc) {
    //   return "$y-$m-$d $h:$min:$sec.$ms${us}Z";
    // } else {
    //   return "$y-$m-$d $h:$min:$sec.$ms$us";
    // }
    // return "JalaliDatetime: $year-$month-$day $hour:$minute:$second,$millisecond,$microsecond";
    return "$y-$m-$d $h:$min:$sec.$ms$us";
  }
}
