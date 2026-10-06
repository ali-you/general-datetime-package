import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final calendar in calendarTestCases) {
    final delegate = calendar.delegate;
    final DateTime date = calendar.make(calendar.anchorYear, 1, 1, hour: 12);
    final other =
        calendarTestCases.firstWhere((item) => item.type != calendar.type);
    final invalidDates = <DateTime>[
      CalendarDateUtils.toGregorian(date), // Same instant, incompatible fields.
      DateTime.utc(
          calendar.anchorYear, 1, 1), // Same fields, different calendar.
      other.make(
          calendar.anchorYear, 1, 1), // Custom calendar with equal fields.
    ];

    Matcher rejects(String name) => isA<ArgumentError>()
        .having((error) => error.name, 'argument name', name)
        .having((error) => error.message, 'expected calendar',
            contains('${calendar.type}'));

    group('${calendar.name} delegate runtime date guards', () {
      final operations = <String, (String, Object? Function(DateTime))>{
        'dateOnly': ('date', delegate.dateOnly),
        'addDaysToDate': ('date', (date) => delegate.addDaysToDate(date, 1)),
        'addMonthsToMonthDate': (
          'monthDate',
          (date) => delegate.addMonthsToMonthDate(date, 1)
        ),
        'formatMonthYear': (
          'date',
          (date) => delegate.formatMonthYear(date, calendar.localizations)
        ),
        'formatMediumDate': (
          'date',
          (date) => delegate.formatMediumDate(date, calendar.localizations)
        ),
        'formatShortMonthDay': (
          'date',
          (date) => delegate.formatShortMonthDay(date, calendar.localizations)
        ),
        'formatShortDate': (
          'date',
          (date) => delegate.formatShortDate(date, calendar.localizations)
        ),
        'formatFullDate': (
          'date',
          (date) => delegate.formatFullDate(date, calendar.localizations)
        ),
        'formatCompactDate': (
          'date',
          (date) => delegate.formatCompactDate(date, calendar.localizations)
        ),
      };
      for (final operation in operations.entries) {
        test('${operation.key} rejects native and other-calendar values', () {
          for (final invalid in invalidDates) {
            expect(() => operation.value.$2(invalid),
                throwsA(rejects(operation.value.$1)),
                reason: '${invalid.runtimeType}');
          }
        });
      }

      test('monthDelta checks both operands', () {
        for (final invalid in invalidDates) {
          expect(() => delegate.monthDelta(invalid, date),
              throwsA(rejects('startDate')));
          expect(() => delegate.monthDelta(date, invalid),
              throwsA(rejects('endDate')));
        }
      });

      final comparisons = <String, bool Function(DateTime?, DateTime?)>{
        'isSameDay': delegate.isSameDay,
        'isSameMonth': delegate.isSameMonth,
      };
      for (final comparison in comparisons.entries) {
        test(
            '${comparison.key} checks both operands even when the other is null',
            () {
          for (final invalid in invalidDates) {
            expect(() => comparison.value(invalid, date),
                throwsA(rejects('dateA')));
            expect(() => comparison.value(date, invalid),
                throwsA(rejects('dateB')));
            expect(() => comparison.value(invalid, null),
                throwsA(rejects('dateA')));
            expect(() => comparison.value(null, invalid),
                throwsA(rejects('dateB')));
            expect(() => comparison.value(invalid, invalid),
                throwsA(rejects('dateA')));
          }
        });
      }

      test('datesOnly checks each range endpoint', () {
        // All endpoints share an instant, so range ordering is independently valid.
        for (final invalid in <DateTime>[
          CalendarDateUtils.toGregorian(date),
          other.fromDateTime(date),
        ]) {
          expect(
              () =>
                  delegate.datesOnly(DateTimeRange(start: invalid, end: date)),
              throwsA(rejects('range.start')));
          expect(
              () =>
                  delegate.datesOnly(DateTimeRange(start: date, end: invalid)),
              throwsA(rejects('range.end')));
        }
        final end = calendar.make(calendar.anchorYear, 1, 2,
            hour: 17, microsecond: 321);
        final result = delegate.datesOnly(DateTimeRange(start: date, end: end));
        expect(result.start.runtimeType, calendar.type);
        expect(result.end.runtimeType, calendar.type);
        expect(result.start.isUtc, isFalse);
        expect(result.end.isUtc, isFalse);
        expect(result.start,
            calendar.make(calendar.anchorYear, 1, 1, isUtc: false));
        expect(
            result.end, calendar.make(calendar.anchorYear, 1, 2, isUtc: false));
      });

      test('parser rejects non-null results in the wrong calendar', () {
        for (final invalid in invalidDates) {
          expect(
              () => delegate.parseCompactDate(
                  'custom input', _ParserLocalizations(invalid)),
              throwsA(rejects('localizations.parseCompactDate result')));
        }
        // A Gregorian localization cannot silently supply a custom-calendar result.
        expect(
            () => delegate.parseCompactDate(
                '03/20/2024', const DefaultMaterialLocalizations()),
            throwsA(rejects('localizations.parseCompactDate result')));
      });

      test('parser retains matching results and invalid-input null behavior',
          () {
        final valid =
            calendar.make(calendar.anchorYear, 1, 1, microsecond: 321);
        expect(
            delegate.parseCompactDate(
                'custom input', _ParserLocalizations(valid)),
            same(valid));
        expect(
            delegate.parseCompactDate(null, const _ParserLocalizations(null)),
            isNull);
        expect(delegate.parseCompactDate('invalid', calendar.localizations),
            isNull);
      });

      test('matching comparisons retain nullable and calendar-field semantics',
          () {
        final sameDay =
            calendar.make(calendar.anchorYear, 1, 1, hour: 23, isUtc: false);
        final nextDay = calendar.make(calendar.anchorYear, 1, 2);
        final nextMonth = calendar.make(calendar.anchorYear, 2, 1);
        for (final comparison in comparisons.values) {
          expect(comparison(null, null), isTrue);
          expect(comparison(date, null), isFalse);
          expect(comparison(null, date), isFalse);
          expect(comparison(date, sameDay), isTrue);
        }
        expect(delegate.isSameDay(date, nextDay), isFalse);
        expect(delegate.isSameMonth(date, nextDay), isTrue);
        expect(delegate.isSameMonth(date, nextMonth), isFalse);
        expect(delegate.monthDelta(date, nextMonth), 1);
        expect(delegate.monthDelta(nextMonth, date), -1);
      });

      test('explicit instant conversion supplies a valid calendar input', () {
        final gregorian =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        final converted = calendar.fromDateTime(gregorian);
        final result = delegate.dateOnly(converted);
        expect(result.runtimeType, calendar.type);
        expect((result.year, result.month, result.day),
            (calendar.anchorYear, 1, 1));
        expect(CalendarDateUtils.toGregorian(result),
            DateTime(gregorian.year, gregorian.month, gregorian.day));
      });

      test(
          'formatters forward matching values unchanged and guard before forwarding',
          () {
        final localizations = _RecordingLocalizations();
        final formatters = <String Function(DateTime, MaterialLocalizations)>[
          delegate.formatMonthYear,
          delegate.formatMediumDate,
          delegate.formatShortMonthDay,
          delegate.formatShortDate,
          delegate.formatFullDate,
          delegate.formatCompactDate,
        ];
        for (final format in formatters) {
          expect(format(date, localizations), 'custom format');
          expect(localizations.seen, same(date));
          localizations.seen = null;
          expect(() => format(invalidDates.first, localizations),
              throwsA(rejects('date')));
          expect(localizations.seen, isNull);
        }
      });

      test(
          'Material picker constructors reject mismatched initial, range and current dates',
          () {
        final first = calendar.make(calendar.anchorYear, 1, 1);
        final last = calendar.make(calendar.anchorYear, 12, 1);
        final selected = calendar.make(calendar.anchorYear, 2, 1);
        for (final field in [
          'initialDate',
          'firstDate',
          'lastDate',
          'currentDate'
        ]) {
          expect(
              () => CalendarDatePicker(
                    initialDate:
                        field == 'initialDate' ? invalidDates.first : selected,
                    firstDate:
                        field == 'firstDate' ? invalidDates.first : first,
                    lastDate: field == 'lastDate' ? invalidDates.first : last,
                    currentDate:
                        field == 'currentDate' ? invalidDates.first : selected,
                    calendarDelegate: delegate,
                    onDateChanged: (_) {},
                  ),
              throwsA(rejects('date')),
              reason: field);
        }
        expect(
            () => InputDatePickerFormField(
                  initialDate: invalidDates.first,
                  firstDate: first,
                  lastDate: last,
                  calendarDelegate: delegate,
                ),
            throwsA(rejects('date')));
      });
    });
  }
}

class _ParserLocalizations extends DefaultMaterialLocalizations {
  const _ParserLocalizations(this.result);
  final DateTime? result;

  @override
  DateTime? parseCompactDate(String? inputString) => result;
}

class _RecordingLocalizations extends DefaultMaterialLocalizations {
  DateTime? seen;

  String record(DateTime date) {
    seen = date;
    return 'custom format';
  }

  @override
  String formatMonthYear(DateTime date) => record(date);
  @override
  String formatMediumDate(DateTime date) => record(date);
  @override
  String formatShortMonthDay(DateTime date) => record(date);
  @override
  String formatShortDate(DateTime date) => record(date);
  @override
  String formatFullDate(DateTime date) => record(date);
  @override
  String formatCompactDate(DateTime date) => record(date);
}
