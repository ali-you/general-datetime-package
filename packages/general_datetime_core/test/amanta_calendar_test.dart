import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  test('generic now supports Amanta and dateOnly preserves the UTC mode', () {
    final date = AmantaDate.fromGregorian(2023, 7, 22);
    final utc = AmantaDateTime.fromCivilDate(date, isUtc: true, hour: 12);
    expect(CalendarDateUtils.dateOnly(utc),
        AmantaDateTime.atStartOfDay(date, isUtc: true));

    final native = DateTime.now();
    final gregorian = DateTime.utc(native.year, native.month, native.day);
    final dayIndex =
        gregorian.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    if (dayIndex >= AmantaDate.minimumDayIndex &&
        dayIndex <= AmantaDate.maximumDayIndex) {
      expect(GeneralDateTimeInterface.now<AmantaDateTime>().isUtc, isFalse);
    } else {
      expect(GeneralDateTimeInterface.now<AmantaDateTime>, throwsRangeError);
    }
  });

  test('Calendrica Ujjain reference: intercalary month, repeat and skip', () {
    final start = AmantaDate.fromGregorian(2023, 7, 18);
    expect(start.year, 2080);
    expect(start.lunarMonth, 5);
    expect(start.isLeapMonth, isTrue);
    expect(start.day, 1);
    expect(start.tithi, 1);

    final repeated = start.addDays(4);
    expect(repeated.toGregorian(), DateTime.utc(2023, 7, 22));
    expect(repeated.tithi, 4);
    expect(repeated.isRepeatedTithi, isTrue);
    expect(repeated.addDays(-1).tithi, repeated.tithi);
    expect(repeated.addDays(-1), isNot(repeated));
    expect(start.addDays(13).tithi, 14);
    expect(start.addDays(12).tithi, 12);

    final regular = AmantaDate.fromLunarMonth(2080, 5);
    expect(start.addMonths(1), regular);
    expect(regular.isLeapMonth, isFalse);
  });

  test('every supported civil day round trips through fields and Gregorian',
      () {
    for (var index = AmantaDate.minimumDayIndex;
        index <= AmantaDate.maximumDayIndex;
        index++) {
      final date = AmantaDate.fromDayIndex(index);
      final gregorian = date.toGregorian();
      expect(
          AmantaDate.fromGregorian(
              gregorian.year, gregorian.month, gregorian.day),
          date);
      expect(AmantaDate.parse(date.toString()), date);
    }
    final first = AmantaDate.fromDayIndex(AmantaDate.minimumDayIndex);
    final last = AmantaDate.fromDayIndex(AmantaDate.maximumDayIndex);
    expect(() => first.addDays(-1), throwsRangeError);
    expect(() => last.addMonths(1), throwsRangeError);
    expect(() => AmantaDate.parse('2080-06-00'), throwsFormatException);
    expect(() => AmantaDate.fromGregorian(2023, 2, 29), throwsArgumentError);
  });

  test('DateTime adapter preserves the instant and existing storage rejects it',
      () {
    final native = DateTime.utc(2023, 7, 22, 3, 4, 5, 6, 7);
    final date = AmantaDateTime.fromDateTime(native);
    expect(date.toDateTime(), native);
    expect(date.weekday, native.weekday);
    expect(date.microsecond, 7);
    expect(date.year, 2080);
    expect(date.day, 5);
    expect(
        date.add(const Duration(days: 1)).civilDate, date.civilDate.addDays(1));
    expect(CalendarDateUtils.dateOnly(date), isA<AmantaDateTime>());
    expect(() => CalendarInstant.fromDateTime(date), throwsUnsupportedError);
  });
}
