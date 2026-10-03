import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final calendar in calendarTestCases) {
    group('${calendar.name} DateTime-typed field boundary', () {
      test('copyWith retains calendar fields and the correct Gregorian instant',
          () {
        final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
            hour: 12,
            minute: 34,
            second: 56,
            millisecond: 789,
            microsecond: 321);
        final result = CalendarDateUtils.copyWith(date, day: 2);
        final expected = calendar
            .referenceGregorian(calendar.anchorYear, 1, 2)
            .add(const Duration(
                hours: 12,
                minutes: 34,
                seconds: 56,
                milliseconds: 789,
                microseconds: 321));

        expect(result.runtimeType, calendar.type);
        expect((result.year, result.month, result.day),
            (calendar.anchorYear, 1, 2));
        expect(result.microsecondsSinceEpoch, expected.microsecondsSinceEpoch);
        expect(result.isUtc, isTrue);
      });

      test('every replacement field is applied in the selected calendar', () {
        final DateTime date = calendar.make(calendar.anchorYear, 1, 1);
        final result = CalendarDateUtils.copyWith(date,
            year: calendar.anchorYear + 1,
            month: 2,
            day: 3,
            hour: 4,
            minute: 5,
            second: 6,
            millisecond: 7,
            microsecond: 8);
        final expected = calendar
            .referenceGregorian(calendar.anchorYear + 1, 2, 3)
            .add(const Duration(
                hours: 4,
                minutes: 5,
                seconds: 6,
                milliseconds: 7,
                microseconds: 8));

        expect(result.runtimeType, calendar.type);
        expect(result.microsecondsSinceEpoch, expected.microsecondsSinceEpoch);
        expect((result.year, result.month, result.day),
            (calendar.anchorYear + 1, 2, 3));
        expect((
          result.hour,
          result.minute,
          result.second,
          result.millisecond,
          result.microsecond
        ), (
          4,
          5,
          6,
          7,
          8
        ));
      });

      test('copy without replacements retains local/UTC mode and precision',
          () {
        for (final isUtc in [false, true]) {
          final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
              hour: 12, millisecond: 789, microsecond: 321, isUtc: isUtc);
          final result = CalendarDateUtils.copyWith(date);
          expect(result.runtimeType, calendar.type);
          expect(result, date);
          expect(result.isUtc, isUtc);
          expect(result.microsecond, 321);
        }
      });

      test(
          'overflow follows calendar year boundaries rather than Gregorian ones',
          () {
        final length = calendar.referenceMonthLength(calendar.anchorYear, 12);
        final DateTime date = calendar.make(calendar.anchorYear, 12, length);
        final result = CalendarDateUtils.copyWith(date, day: length + 1);
        final expected =
            calendar.referenceGregorian(calendar.anchorYear + 1, 1, 1);
        expect((result.year, result.month, result.day),
            (calendar.anchorYear + 1, 1, 1));
        expect(result.microsecondsSinceEpoch, expected.microsecondsSinceEpoch);
      });

      test(
          'dateOnly clears all clock fields and preserves the calendar and mode',
          () {
        final gregorian =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final isUtc in [false, true]) {
          final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
              hour: 12,
              minute: 34,
              second: 56,
              millisecond: 789,
              microsecond: 321,
              isUtc: isUtc);
          final result = CalendarDateUtils.dateOnly(date);
          final expected = isUtc
              ? gregorian
              : DateTime(gregorian.year, gregorian.month, gregorian.day);
          expect(result.runtimeType, calendar.type);
          expect((result.year, result.month, result.day),
              (calendar.anchorYear, 1, 1));
          expect(
              result.microsecondsSinceEpoch, expected.microsecondsSinceEpoch);
          expect(result.isUtc, isUtc);
          expect((
            result.hour,
            result.minute,
            result.second,
            result.millisecond,
            result.microsecond
          ), (
            expected.hour,
            expected.minute,
            expected.second,
            0,
            0
          ));
        }
      });

      test('native boundary preserves the exact instant and Gregorian fields',
          () {
        final gregorian =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final isUtc in [false, true]) {
          final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
              hour: 12,
              minute: 34,
              second: 56,
              millisecond: 789,
              microsecond: 321,
              isUtc: isUtc);
          final native = CalendarDateUtils.toGregorian(date);
          expect(native, isNot(isA<GeneralDateTimeInterface>()));
          expect(native.microsecondsSinceEpoch, date.microsecondsSinceEpoch);
          expect(native.isUtc, isUtc);
          expect((native.year, native.month, native.day),
              (gregorian.year, gregorian.month, gregorian.day));
          expect(native.microsecond, 321);
          // External field helpers receive real Gregorian fields at this boundary.
          expect(DateUtils.dateOnly(native),
              DateTime(gregorian.year, gregorian.month, gregorian.day));
          final nextDay = native.copyWith(day: native.day + 1);
          final expected = (isUtc ? DateTime.utc : DateTime.new)(gregorian.year,
              gregorian.month, gregorian.day + 1, 12, 34, 56, 789, 321);
          expect(nextDay, expected);
        }
      });

      test(
          'changing isUtc reinterprets wall fields instead of converting the instant',
          () {
        final DateTime date = calendar.make(calendar.anchorYear, 1, 1,
            hour: 12, microsecond: 321, isUtc: false);
        final result = CalendarDateUtils.copyWith(date, isUtc: true);
        final expected = calendar
            .referenceGregorian(calendar.anchorYear, 1, 1)
            .add(const Duration(hours: 12, microseconds: 321));
        expect(result.runtimeType, calendar.type);
        expect(result.isUtc, isTrue);
        expect((result.year, result.month, result.day, result.hour),
            (calendar.anchorYear, 1, 1, 12));
        expect(result.microsecondsSinceEpoch, expected.microsecondsSinceEpoch);
      });

      test('copyWith enforces supported calendar bounds', () {
        final DateTime first = calendar.make(calendar.minimumYear, 1, 1);
        expect(
            () => CalendarDateUtils.copyWith(first, day: 0), throwsRangeError);
      });
    });
  }

  group('Gregorian and unsupported calendar boundaries', () {
    test('native copy and date-only operations retain local/UTC semantics', () {
      for (final isUtc in [false, true]) {
        final date = (isUtc ? DateTime.utc : DateTime.new)(
            2024, 12, 31, 12, 34, 56, 789, 321);
        final result = CalendarDateUtils.copyWith(date, day: 32);
        final expected = (isUtc ? DateTime.utc : DateTime.new)(
            2025, 1, 1, 12, 34, 56, 789, 321);
        expect(result, expected);
        expect(result, isNot(isA<GeneralDateTimeInterface>()));
        expect(CalendarDateUtils.dateOnly(date),
            (isUtc ? DateTime.utc : DateTime.new)(2024, 12, 31));
        expect(CalendarDateUtils.dateOnly(date).isUtc, isUtc);
        expect(CalendarDateUtils.toGregorian(date), date);
      }
    });

    test('unregistered calendar fields fail explicitly', () {
      final DateTime date = _UnsupportedCalendar();
      expect(() => CalendarDateUtils.copyWith(date, day: 2),
          throwsUnsupportedError);
      expect(() => CalendarDateUtils.dateOnly(date), throwsUnsupportedError);
      // Converting an instant remains safe without a calendar field adapter.
      expect(CalendarDateUtils.toGregorian(date), DateTime.utc(2024, 3, 20));
    });
  });
}

class _UnsupportedCalendar extends DateTime
    implements GeneralDateTimeInterface<DateTime> {
  _UnsupportedCalendar() : super.utc(2024, 3, 20);

  @override
  int get year => 9000;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
