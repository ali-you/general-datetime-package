import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

CalendarDate p(int y, int m, int d) =>
    CalendarDate(calendar: CalendarId.persian, year: y, month: m, day: d);
CalendarDate g(int y, int m, int d) =>
    CalendarDate(calendar: CalendarId.gregory, year: y, month: m, day: d);
void main() {
  test('month policies distinguish clamp, rejection, and overflow', () {
    final date = p(1403, 6, 31);
    expect(date.addMonths(1), p(1403, 7, 30));
    expect(date.addMonths(1, policy: CalendarOverflow.overflow), p(1403, 8, 1));
    expect(() => date.addMonths(1, policy: CalendarOverflow.reject),
        throwsArgumentError);
    expect(date.addMonths(1).addMonths(-1), p(1403, 6, 30));
    expect(p(0, 1, 1).addMonths(-1), p(-1, 12, 1));
    expect(g(2024, 2, 29).addYears(1), g(2025, 2, 28));
  });
  test('same civil day is explicit; tagged equality and hash keys are stable',
      () {
    final native = g(2024, 3, 20);
    final persian = p(1403, 1, 1);
    expect(native.isSameCivilDay(persian), isTrue);
    expect(native.compareTo(persian), 0);
    expect(native == persian, isFalse);
    expect({persian: 'event'}[p(1403, 1, 1)], 'event');
    expect(CalendarDate.fromRecord(persian.toRecord()), persian);
    expect(persian.toCalendar(CalendarId.gregory), native);
  });
  test('civil days and ranges do not depend on local DST or clock fields', () {
    final date = g(2021, 3, 13);
    expect(date.addDays(2), g(2021, 3, 15));
    expect(date.daysUntil(date.addDays(2)), 2);
    final range = CalendarDateRange(date, date.addDays(2));
    expect(range.dayCount, 2);
    expect(range.contains(date.addDays(2)), isFalse);
    expect(CalendarDateRange.inclusiveDayCount(date, date.addDays(2)), 3);
    expect(() => CalendarDateRange(date.addDays(1), date), throwsArgumentError);
  });
  test('ISO and alternative week rules have independently expected results',
      () {
    const iso = CalendarWeekRules();
    expect(iso.weekOfYear(g(2021, 1, 1)), (year: 2020, week: 53));
    expect(iso.weekOfYear(g(2021, 1, 4)), (year: 2021, week: 1));
    expect(iso.weekOfYear(g(2018, 12, 31)), (year: 2019, week: 1));
    const sunday =
        CalendarWeekRules(firstWeekday: DateTime.sunday, minimumDays: 1);
    expect(sunday.weekOfYear(g(2021, 1, 1)), (year: 2021, week: 1));
  });
  test('all calendar endpoints and extreme period offsets fail explicitly', () {
    for (final id in CalendarId.values) {
      final system = CalendarSystems.forId(id);
      final min = system.minimumDate, max = system.maximumDate;
      final first = CalendarDate(
          calendar: id, year: min.year, month: min.month, day: min.day);
      final last = CalendarDate(
          calendar: id, year: max.year, month: max.month, day: max.day);
      expect(() => first.addDays(-1), throwsRangeError);
      expect(() => last.addDays(1), throwsRangeError);
      expect(() => first.addMonths(9223372036854775807), throwsRangeError);
      expect(() => first.addYears(9223372036854775807), throwsRangeError);
    }
  });
}
