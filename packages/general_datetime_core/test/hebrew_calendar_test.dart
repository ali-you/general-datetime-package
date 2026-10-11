import 'dart:convert';

import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

import 'fixtures/hebrew_reference_dates.dart';

CalendarDate h(int year, int month, int day) => CalendarDate(
    calendar: CalendarId.hebrew, year: year, month: month, day: day);

void main() {
  test('independent reference dates preserve instant, precision and weekday',
      () {
    for (final fixture in hebrewReferenceDates) {
      final (gy, gm, gd) = fixture.gregorian;
      final (hy, hm, hd) = fixture.hebrew;
      final native = DateTime.utc(gy, gm, gd, 12, 34, 56, 123, 456);
      final value = HebrewDateTime.fromDateTime(native);
      expect((value.year, value.month, value.day), (hy, hm, hd));
      expect(HebrewDateTime.utc(hy, hm, hd, 12, 34, 56, 123, 456).toDateTime(),
          native);
      expect(value.weekday, native.weekday);
      expect(value.julianDay, h(hy, hm, hd).dayIndex + 2440588);
      expect(value.microsecondsSinceEpoch, native.microsecondsSinceEpoch);
      expect(value.isUtc, isTrue);
      expect(value, native);
      expect(native, value);
      expect({native: 'event'}[value], 'event');
      expect(
          h(hy, hm, hd).toCalendar(CalendarId.gregory),
          CalendarDate(
              calendar: CalendarId.gregory, year: gy, month: gm, day: gd));
    }
  });

  test('all supported year structures and every month boundary', () {
    final lengths = <int>{};
    for (var year = HebrewDateTime.minimumYear;
        year <= HebrewDateTime.maximumYear;
        year++) {
      final months = HebrewDateTime.monthsOfYear(year);
      final start = HebrewDateTime.utc(year);
      final length = CalendarSystems.hebrew.daysInYear(year);
      lengths.add(length);
      expect(months.length, start.isLeapYear ? 13 : 12);
      expect(months.contains(6), start.isLeapYear);
      var sum = 0;
      for (final month in months) {
        final size = HebrewDateTime.daysInMonth(year, month);
        final first = HebrewDateTime.utc(year, month);
        final last = HebrewDateTime.utc(year, month, size);
        expect(first.dayOfYear, sum + 1);
        expect(last.dayOfYear, sum + size);
        expect(HebrewDateTime.fromDateTime(first.toDateTime()).month, month);
        expect(HebrewDateTime.fromDateTime(last.toDateTime()).day, size);
        expect(first.monthOrdinal, months.indexOf(month) + 1);
        sum += size;
      }
      expect(sum, length);
      if (year < HebrewDateTime.maximumYear) {
        expect(HebrewDateTime.utc(year + 1).difference(start).inDays, length);
      }
    }
    expect(lengths, {353, 354, 355, 383, 384, 385});
  });

  test(
      'day round trips and month advancement across complete leap/common years',
      () {
    for (final year in [5771, 5784, 5785, 5786]) {
      final first = h(year, 1, 1);
      for (var i = 0; i < first.system.daysInYear(year); i++) {
        final date = first.addDays(i);
        expect(
            date.toCalendar(CalendarId.gregory).toCalendar(CalendarId.hebrew),
            date);
        expect(date.addDays(1).addDays(-1), date);
      }
      final months = HebrewDateTime.monthsOfYear(year);
      for (var i = 0; i < months.length; i++) {
        final value = h(year, months[i], 1);
        expect(first.addMonths(i), value);
        expect(value.addMonths(-i), first);
      }
      expect(first.addMonths(months.length), h(year + 1, 1, 1));
    }
    expect(h(5784, 5, 1).addMonths(1), h(5784, 6, 1));
    expect(h(5785, 5, 1).addMonths(1), h(5785, 7, 1));
    expect(h(5785, 7, 1).addMonths(-1), h(5785, 5, 1));
    expect(h(5784, 1, 1).addMonths(235), h(5803, 1, 1));
    expect(h(5803, 1, 1).addMonths(-235), h(5784, 1, 1));
  });

  test('year addition preserves named month and separates missing month policy',
      () {
    expect(h(5784, 8, 15).addYears(1), h(5785, 8, 15));
    expect(h(5784, 6, 30).addYears(1), h(5785, 7, 29));
    expect(
        () =>
            h(5784, 6, 1).addYears(1, missingMonth: MissingMonthPolicy.reject),
        throwsArgumentError);
    expect(() => h(5784, 6, 30).addYears(1, policy: CalendarOverflow.reject),
        throwsArgumentError);
    expect(h(5784, 6, 30).addYears(1, policy: CalendarOverflow.overflow),
        h(5785, 8, 1));
    expect(h(5784, 6, 30).addMonths(1), h(5784, 7, 29));
  });

  test('strict fields, missing months and normalized constructor overflows',
      () {
    expect(() => h(5785, 6, 1), throwsArgumentError);
    expect(() => HebrewDateTime.utc(5785, 6), throwsRangeError);
    expect(() => CalendarSystems.hebrew.construct(5784, 6, 31),
        throwsArgumentError);
    expect(HebrewDateTime.isValidDate(5785, 13, 29), isTrue);
    expect(HebrewDateTime.isValidDate(5785, 6, 1), isFalse);
    expect(HebrewDateTime.utc(5785, 5, 31), HebrewDateTime.utc(5785, 7, 1));
    expect(HebrewDateTime.utc(5784, 14), HebrewDateTime.utc(5785));
    expect(HebrewDateTime.utc(5785, 14), HebrewDateTime.utc(5786));
    expect(HebrewDateTime.utc(5785, 0), HebrewDateTime.utc(5784, 13));
    expect(HebrewDateTime.utc(5785, 1, 1, 24), HebrewDateTime.utc(5785, 1, 2));
    expect(HebrewDateTime.utc(10000, 1, 0), HebrewDateTime.utc(9999, 13, 29));
    expect(() => HebrewDateTime.utc(10000), throwsRangeError);
    expect(() => h(1, 1, 1).addDays(-1), throwsRangeError);
    expect(() => h(9999, 13, 29).addDays(1), throwsRangeError);
    for (final offset in [9223372036854775807, -9223372036854775807]) {
      expect(() => h(5784, 1, 1).addMonths(offset), throwsRangeError);
      expect(() => h(5784, 1, 1).addYears(offset), throwsRangeError);
      expect(() => HebrewDateTime.utc(5784, offset), throwsRangeError);
    }
  });

  test('parsing, copy helpers, epoch precision and cross-calendar conversion',
      () {
    final value = HebrewDateTime.utc(5784, 7, 10, 12, 34, 56, 123, 456);
    expect(HebrewDateTime.parse(value.toIso8601String()), value);
    expect(HebrewDateTime.parse('5784-07-10T14:34:56.123456+02:00'), value);
    expect(HebrewDateTime.tryParse('5785-06-01'), isNull);
    expect(HebrewDateTime.tryParse('5784-07-10Z\njunk'), isNull);
    expect(HebrewDateTime.fromDateTime(PersianDateTime.fromDateTime(value)),
        value);
    expect(
        HebrewDateTime.fromDateTime(HijriDateTime.fromDateTime(value)), value);
    expect(CalendarDateUtils.copyWith(value, day: 11), isA<HebrewDateTime>());
    expect(CalendarDateUtils.dateOnly(value), HebrewDateTime.utc(5784, 7, 10));
    expect(value.toLocal().toUtc(), value);
    expect(
        HebrewDateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true)
            .secondsSinceEpoch,
        -1);
    expect(
        GeneralDateTimeInterface.now<HebrewDateTime>(), isA<HebrewDateTime>());
    expect(value.hasOfficialCalendarData, isFalse);
    expect(CalendarSystems.hebrew.hasPublishedData(value.year), isFalse);
  });

  test('Hebrew instant and civil records preserve stable month identity', () {
    final value = HebrewDateTime.utc(5784, 6, 1, 12, 0, 0, 123, 456);
    final instant = CalendarInstant.fromJson(
        jsonDecode(jsonEncode(CalendarInstant.fromDateTime(value))));
    expect(instant.calendar, CalendarId.hebrew);
    expect(instant.instant, value.toDateTime());
    final record = CalendarDateRecord.fromJson(
        jsonDecode(jsonEncode(h(5784, 6, 1).toRecord())));
    expect(CalendarDate.fromRecord(record), h(5784, 6, 1));
    expect(
        () => CalendarDateRecord.fromJson({
              'version': 1,
              'kind': 'calendar-date',
              'calendar': 'hebrew',
              'year': 5785,
              'month': 6,
              'day': 1,
            }),
        throwsFormatException);
    expect(CalendarSystems.monthsOfYear(CalendarId.hebrew, 5785).contains(6),
        isFalse);
    final date = h(5785, 1, 1);
    expect(CalendarDateRange(date, date.addDays(7)).dayCount, 7);
    expect(const CalendarWeekRules().weekOfYear(date), (year: 5785, week: 1));
  });
}
