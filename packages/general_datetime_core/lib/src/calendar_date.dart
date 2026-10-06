import 'calendar_serialization.dart';
import 'calendar_system.dart';

enum CalendarOverflow { clamp, reject, overflow }

/// Immutable civil date. Equality includes the calendar; [compareTo] compares
/// the civil-day position, so differently tagged dates can compare as zero.
final class CalendarDate implements Comparable<CalendarDate> {
  factory CalendarDate(
      {required CalendarId calendar,
      required int year,
      required int month,
      required int day}) {
    if (!CalendarSystems.forId(calendar).isValidDate(year, month, day)) {
      throw ArgumentError(
          'Invalid ${calendar.identifier} date: $year-$month-$day');
    }
    return CalendarDate._(calendar, year, month, day);
  }
  const CalendarDate._(this.calendar, this.year, this.month, this.day);
  factory CalendarDate.fromRecord(CalendarDateRecord record) => CalendarDate(
      calendar: record.calendar,
      year: record.year,
      month: record.month,
      day: record.day);

  /// Extracts wall fields; no timezone conversion or implicit midnight event.
  factory CalendarDate.fromDateTime(DateTime value) =>
      CalendarDate.fromRecord(CalendarDateRecord.fromDateTime(value));
  final CalendarId calendar;
  final int year, month, day;
  CalendarSystem get system => CalendarSystems.forId(calendar);
  CalendarDateRecord toRecord() => CalendarDateRecord(
      calendar: calendar, year: year, month: month, day: day);

  /// UTC midnight used only as a Gregorian civil-day coordinate.
  DateTime get gregorianDay => system.toGregorianDay(year, month, day);
  int get dayIndex => gregorianDay.difference(DateTime.utc(1970)).inDays;
  int get weekday => gregorianDay.weekday;
  bool get hasPublishedData => system.hasPublishedData(year);
  CalendarDate toCalendar(CalendarId target) {
    final fields = CalendarSystems.forId(target).fromGregorianDay(gregorianDay);
    return CalendarDate(
        calendar: target,
        year: fields.year,
        month: fields.month,
        day: fields.day);
  }

  CalendarDate addDays(int days) {
    final minimum = system.minimumDate, maximum = system.maximumDate;
    final low = system
        .toGregorianDay(minimum.year, minimum.month, minimum.day)
        .difference(DateTime.utc(1970))
        .inDays;
    final high = system
        .toGregorianDay(maximum.year, maximum.month, maximum.day)
        .difference(DateTime.utc(1970))
        .inDays;
    final index = BigInt.from(dayIndex) + BigInt.from(days);
    if (index < BigInt.from(low) || index > BigInt.from(high)) {
      throw RangeError(
          'Civil-day result outside ${calendar.identifier} bounds');
    }
    final native = DateTime.utc(1970).add(Duration(days: index.toInt()));
    final fields = system.fromGregorianDay(native);
    return CalendarDate(
        calendar: calendar,
        year: fields.year,
        month: fields.month,
        day: fields.day);
  }

  /// Clamping is not reversible. Recurrences must retain their original day.
  CalendarDate addMonths(int months,
      {CalendarOverflow policy = CalendarOverflow.clamp}) {
    final total = BigInt.from(year) * BigInt.from(12) +
        BigInt.from(month - 1) +
        BigInt.from(months);
    var targetYear = total ~/ BigInt.from(12);
    if (total.isNegative && total.remainder(BigInt.from(12)) != BigInt.zero) {
      targetYear -= BigInt.one;
    }
    if (targetYear < BigInt.from(system.minimumDate.year) ||
        targetYear > BigInt.from(system.maximumDate.year)) {
      throw RangeError('Calendar-period result outside supported years');
    }
    final y = targetYear.toInt(),
        m = (total - targetYear * BigInt.from(12)).toInt() + 1;
    final length = system.daysInMonth(y, m);
    if (day > length && policy == CalendarOverflow.reject) {
      throw ArgumentError('Destination month has no day $day');
    }
    if (policy == CalendarOverflow.overflow) {
      return CalendarDate(calendar: calendar, year: y, month: m, day: 1)
          .addDays(day - 1);
    }
    return CalendarDate(
        calendar: calendar,
        year: y,
        month: m,
        day: day > length ? length : day);
  }

  CalendarDate addYears(int years,
      {CalendarOverflow policy = CalendarOverflow.clamp}) {
    final months = BigInt.from(years) * BigInt.from(12);
    // All supported spans fit comfortably in this exact bound.
    if (months.abs() > BigInt.from(7000000)) {
      throw RangeError('Year offset outside supported span');
    }
    return addMonths(months.toInt(), policy: policy);
  }

  /// Signed number of civil days from this date to [other].
  int daysUntil(CalendarDate other) => other.dayIndex - dayIndex;
  bool isSameCivilDay(CalendarDate other) => dayIndex == other.dayIndex;
  @override
  int compareTo(CalendarDate other) => dayIndex.compareTo(other.dayIndex);
  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      calendar == other.calendar &&
      year == other.year &&
      month == other.month &&
      day == other.day;
  @override
  int get hashCode => Object.hash(calendar, year, month, day);
  @override
  String toString() =>
      '${calendar.identifier}:$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Half-open civil-date range. The end date is not included.
final class CalendarDateRange {
  CalendarDateRange(this.start, this.end) {
    if (start.compareTo(end) > 0) throw ArgumentError('End precedes start');
  }
  final CalendarDate start, end;
  int get dayCount => start.daysUntil(end);
  bool contains(CalendarDate date) =>
      date.compareTo(start) >= 0 && date.compareTo(end) < 0;
  static int inclusiveDayCount(CalendarDate start, CalendarDate last) {
    if (start.compareTo(last) > 0) {
      throw ArgumentError('Last date precedes start');
    }
    return start.daysUntil(last) + 1;
  }
}

/// Week-year rules apply to the chosen calendar, not implicitly to Gregorian.
final class CalendarWeekRules {
  const CalendarWeekRules(
      {this.firstWeekday = DateTime.monday, this.minimumDays = 4})
      : assert(firstWeekday >= 1 && firstWeekday <= 7),
        assert(minimumDays >= 1 && minimumDays <= 7);
  final int firstWeekday, minimumDays;
  void _validate() {
    if (firstWeekday < 1 ||
        firstWeekday > 7 ||
        minimumDays < 1 ||
        minimumDays > 7) {
      throw ArgumentError('Week rules require values in 1–7');
    }
  }

  CalendarDate startOfWeek(CalendarDate date) {
    _validate();
    return date.addDays(-((date.weekday - firstWeekday) % 7));
  }

  int _firstWeek(int januaryIndex, int weekday) {
    final preceding = (weekday - firstWeekday) % 7;
    return januaryIndex - preceding + (7 - preceding < minimumDays ? 7 : 0);
  }

  ({int year, int week}) weekOfYear(CalendarDate date) {
    _validate();
    final start = CalendarDate(
        calendar: date.calendar, year: date.year, month: 1, day: 1);
    var weekYear = date.year;
    var first = _firstWeek(start.dayIndex, start.weekday);
    final yearLength = date.system.daysInYear(date.year);
    final next = _firstWeek(
        start.dayIndex + yearLength, (start.weekday - 1 + yearLength) % 7 + 1);
    if (date.dayIndex >= next) {
      weekYear++;
      first = next;
    } else if (date.dayIndex < first) {
      weekYear--;
      // Explicitly fails if the previous week-year is outside chronology data.
      final previous = CalendarDate(
          calendar: date.calendar, year: weekYear, month: 1, day: 1);
      first = _firstWeek(previous.dayIndex, previous.weekday);
    }
    return (year: weekYear, week: (date.dayIndex - first) ~/ 7 + 1);
  }
}
