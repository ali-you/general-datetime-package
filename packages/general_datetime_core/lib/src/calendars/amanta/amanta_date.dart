import 'amanta_calendar_data.dart';

/// A civil date in the traditional Ujjain Amanta lunisolar calendar.
///
/// Years use the Vikrama era. [month] and [day] are one-based chronological
/// ordinals. [lunarMonth] and [isLeapMonth] identify the traditional month.
/// [tithi] is the lunar day label observed at traditional Ujjain sunrise on
/// the corresponding Gregorian civil date.
final class AmantaDate implements Comparable<AmantaDate> {
  AmantaDate._(this._monthIndex, this.day);

  factory AmantaDate(int year, int month, [int day = 1]) {
    final start = _firstMonth(year);
    final count = monthsInYear(year);
    RangeError.checkValueInInterval(month, 1, count, 'month');
    final index = start + month - 1;
    RangeError.checkValueInInterval(
        day, 1, amantaMonths[index].$4.length, 'day');
    return AmantaDate._(index, day);
  }

  /// Constructs from a traditional month identity and a sequential civil day.
  factory AmantaDate.fromLunarMonth(int year, int lunarMonth,
      {bool isLeapMonth = false, int day = 1}) {
    final start = _firstMonth(year);
    final count = monthsInYear(year);
    for (var ordinal = 1; ordinal <= count; ordinal++) {
      final row = amantaMonths[start + ordinal - 1];
      if (row.$2 == lunarMonth && row.$3 == isLeapMonth) {
        return AmantaDate(year, ordinal, day);
      }
    }
    throw ArgumentError('No matching Amanta month in year $year');
  }

  /// Converts the supplied Gregorian calendar fields, regardless of time zone.
  factory AmantaDate.fromGregorian(int year, int month, int day) {
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError('Invalid Gregorian date: $year-$month-$day');
    }
    return AmantaDate.fromDayIndex(
        date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay);
  }

  static final _compact = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');

  /// Parses a Vikrama year, ordinal month, and civil day as YYYY-MM-DD.
  factory AmantaDate.parse(String input) {
    final match = _compact.firstMatch(input);
    if (match == null || match.end != input.length) {
      throw FormatException('Expected an Amanta date as YYYY-MM-DD', input);
    }
    try {
      return AmantaDate(
          int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    } on RangeError {
      throw FormatException('Invalid or unsupported Amanta date', input);
    }
  }

  factory AmantaDate.fromDayIndex(int dayIndex) {
    RangeError.checkValueInInterval(
        dayIndex, minimumDayIndex, maximumDayIndex, 'dayIndex');
    var low = 0;
    var high = amantaMonths.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_starts[mid] > dayIndex) {
        high = mid - 1;
      } else {
        low = mid;
      }
    }
    return AmantaDate._(low, dayIndex - _starts[low] + 1);
  }

  static final List<int> _starts = [
    minimumDayIndex,
    for (var i = 0, start = minimumDayIndex; i < amantaMonths.length; i++)
      start += amantaMonths[i].$4.length,
  ];

  static final Map<int, int> _yearStarts = {
    for (var i = 0; i < amantaMonths.length; i++)
      if (i == 0 || amantaMonths[i - 1].$1 != amantaMonths[i].$1)
        amantaMonths[i].$1: i,
  };

  static int _firstMonth(int year) =>
      _yearStarts[year] ??
      (throw RangeError.range(year, minimumYear, maximumYear, 'year'));

  static int get minimumYear => amantaMonths.first.$1;
  static int get maximumYear => amantaMonths.last.$1;
  static const int minimumDayIndex = amantaStartDay;
  static int get maximumDayIndex => _starts.last - 1;

  static int monthsInYear(int year) =>
      (_yearStarts[year + 1] ?? amantaMonths.length) - _firstMonth(year);

  static bool isLeapYear(int year) {
    final start = _firstMonth(year);
    final end = start + monthsInYear(year);
    for (var i = start; i < end; i++) {
      if (amantaMonths[i].$3) return true;
    }
    return false;
  }

  final int _monthIndex;
  final int day;

  int get year => amantaMonths[_monthIndex].$1;
  int get month => _monthIndex - _firstMonth(year) + 1;
  int get lunarMonth => amantaMonths[_monthIndex].$2;
  bool get isLeapMonth => amantaMonths[_monthIndex].$3;
  int get monthLength => _tithis.length;
  String get _tithis => amantaMonths[_monthIndex].$4;

  int get tithi => _tithis.codeUnitAt(day - 1) - 96;

  bool get isRepeatedTithi =>
      day > 1 && _tithis.codeUnitAt(day - 2) == _tithis.codeUnitAt(day - 1);

  /// The corresponding Gregorian civil day, with 1970-01-01 equal to zero.
  int get dayIndex => _starts[_monthIndex] + day - 1;

  DateTime toGregorian() => DateTime.utc(1970, 1, 1 + dayIndex);

  AmantaDate addDays(int days) {
    RangeError.checkValueInInterval(
        days, minimumDayIndex - dayIndex, maximumDayIndex - dayIndex, 'days');
    return AmantaDate.fromDayIndex(dayIndex + days);
  }

  /// Advances by chronological months, clamping to the last day if necessary.
  AmantaDate addMonths(int months) {
    RangeError.checkValueInInterval(
        months, -_monthIndex, amantaMonths.length - 1 - _monthIndex, 'months');
    final index = _monthIndex + months;
    final length = amantaMonths[index].$4.length;
    return AmantaDate._(index, day <= length ? day : length);
  }

  int monthsUntil(AmantaDate other) => other._monthIndex - _monthIndex;

  @override
  int compareTo(AmantaDate other) => dayIndex.compareTo(other.dayIndex);

  @override
  bool operator ==(Object other) =>
      other is AmantaDate && dayIndex == other.dayIndex;

  @override
  int get hashCode => dayIndex.hashCode;

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
