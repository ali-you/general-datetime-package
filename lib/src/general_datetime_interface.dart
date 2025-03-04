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
}
