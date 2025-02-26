abstract class CalendarInterface<T> {
  CalendarInterface(
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

  DateTime toGregorian(int year, int month, int day);

  T fromGregorian(DateTime date);

  List<String> getMonths();

  List<int> getDaysInMonth(int year, int month);

  bool isLeapYear(int year);
}
