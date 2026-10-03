import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final calendar in calendarTestCases) {
    group('${calendar.name} standalone year picker', () {
      testWidgets('omitted currentDate renders and selects a calendar year',
          (tester) async {
        final before = calendar.fromDateTime(DateTime.now());
        final selected = <DateTime>[];
        final initial = calendar.make(before.year, 2, 12, hour: 16);
        final picker = CalendarYearPicker(
          key: ValueKey(calendar.name),
          firstDate: calendar.make(before.year - 1, 1, 1),
          lastDate: calendar.make(before.year + 1, 12, 1),
          selectedDate: initial,
          onChanged: selected.add,
          calendarDelegate: calendar.delegate,
        );
        final after = calendar.fromDateTime(DateTime.now());
        expect(picker.currentDate.runtimeType, calendar.type);
        expect(
          picker.currentDate,
          anyOf(calendar.delegate.dateOnly(before),
              calendar.delegate.dateOnly(after)),
        );
        expect(picker.currentDate.isUtc, isFalse);

        await tester.pumpWidget(_app(calendar, picker));
        expect(find.byKey(ValueKey(calendar.name)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('${before.year + 1}'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(selected, hasLength(1));
        expect(selected.single.runtimeType, calendar.type);
        expect(selected.single.isUtc, isFalse);
        expect(
            (selected.single.year, selected.single.month, selected.single.day),
            (before.year + 1, 2, 1));
        final reference = calendar.referenceGregorian(before.year + 1, 2, 1);
        expect(CalendarDateUtils.toGregorian(selected.single),
            DateTime(reference.year, reference.month, reference.day));
      });

      test('default uses the supplied delegate clock once', () {
        final fixed = calendar.make(calendar.anchorYear, 4, 5,
            hour: 13, microsecond: 321);
        var calls = 0;
        final delegate = _clockDelegate(calendar, () {
          calls++;
          return fixed;
        });
        final picker = CalendarYearPicker(
          firstDate: calendar.make(calendar.anchorYear, 1, 1),
          lastDate: calendar.make(calendar.anchorYear + 1, 12, 1),
          selectedDate: null,
          onChanged: (_) {},
          calendarDelegate: delegate,
        );
        expect(calls, 1);
        expect(picker.currentDate,
            calendar.make(calendar.anchorYear, 4, 5, isUtc: false));
        expect(picker.selectedDate, isNull);
      });

      testWidgets('explicit currentDate outside the range bypasses the clock',
          (tester) async {
        final delegate = _clockDelegate(calendar,
            () => throw StateError('Explicit currentDate must bypass now()'));
        final selected = <DateTime>[];
        final picker = CalendarYearPicker(
          currentDate: calendar.make(calendar.anchorYear - 1, 3, 4, hour: 15),
          firstDate: calendar.make(calendar.anchorYear, 1, 1, hour: 12),
          lastDate: calendar.make(calendar.anchorYear + 1, 12, 1, hour: 23),
          selectedDate: null,
          onChanged: selected.add,
          dragStartBehavior: DragStartBehavior.down,
          calendarDelegate: delegate,
        );
        expect(picker.currentDate,
            calendar.make(calendar.anchorYear - 1, 3, 4, isUtc: false));
        expect(picker.firstDate,
            calendar.make(calendar.anchorYear, 1, 1, isUtc: false));
        expect(picker.lastDate,
            calendar.make(calendar.anchorYear + 1, 12, 1, isUtc: false));
        expect(picker.calendarDelegate, same(delegate));
        expect(picker.dragStartBehavior, DragStartBehavior.down);

        await tester.pumpWidget(_app(calendar, picker));
        await tester.tap(find.text('${calendar.anchorYear - 1}'));
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
        await tester.tap(find.text('${calendar.anchorYear}'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(selected.single.runtimeType, calendar.type);
        expect(selected.single.year, calendar.anchorYear);
      });

      test('every supplied date rejects native and other-calendar values', () {
        final first = calendar.make(calendar.anchorYear, 1, 1);
        final last = calendar.make(calendar.anchorYear + 1, 12, 1);
        final other =
            calendarTestCases.firstWhere((item) => item.type != calendar.type);
        for (final invalid in <DateTime>[
          CalendarDateUtils.toGregorian(first),
          other.fromDateTime(first),
        ]) {
          for (final argument in [
            'currentDate',
            'firstDate',
            'lastDate',
            'selectedDate'
          ]) {
            expect(
              () => CalendarYearPicker(
                currentDate: argument == 'currentDate' ? invalid : first,
                firstDate: argument == 'firstDate' ? invalid : first,
                lastDate: argument == 'lastDate' ? invalid : last,
                selectedDate: argument == 'selectedDate' ? invalid : first,
                onChanged: (_) {},
                calendarDelegate: calendar.delegate,
              ),
              throwsArgumentError,
              reason: '$argument: ${invalid.runtimeType}',
            );
          }
        }
      });

      test('direct Flutter YearPicker requires a matching explicit currentDate',
          () {
        final first = calendar.make(calendar.anchorYear, 1, 1);
        final last = calendar.make(calendar.anchorYear + 1, 12, 1);
        expect(
          () => YearPicker(
            firstDate: first,
            lastDate: last,
            selectedDate: first,
            onChanged: (_) {},
            calendarDelegate: calendar.delegate,
          ),
          throwsArgumentError,
        );
        final picker = YearPicker(
          currentDate: calendar.make(calendar.anchorYear, 3, 4, hour: 15),
          firstDate: first,
          lastDate: last,
          selectedDate: first,
          onChanged: (_) {},
          calendarDelegate: calendar.delegate,
        );
        expect(picker.currentDate,
            calendar.make(calendar.anchorYear, 3, 4, isUtc: false));
      });
    });
  }

  testWidgets('default Gregorian delegate renders and selects a year',
      (tester) async {
    final selected = <DateTime>[];
    final picker = CalendarYearPicker(
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2025, 12, 31),
      selectedDate: DateTime(2024, 3, 20),
      onChanged: selected.add,
    );
    expect(picker.currentDate.runtimeType, DateTime);
    expect(picker.currentDate.hour, 0);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: picker)));
    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(selected.single, DateTime(2025, 3, 1));
  });
}

Widget _app(CalendarTestCase calendar, Widget child) => MaterialApp(
      localizationsDelegates: [calendar.localizationDelegate],
      home: Scaffold(body: child),
    );

CalendarDelegate<DateTime> _clockDelegate(
        CalendarTestCase calendar, DateTime Function() clock) =>
    calendar.name == 'Persian'
        ? _ClockPersianDelegate(clock)
        : _ClockHijriDelegate(clock);

class _ClockPersianDelegate extends PersianCalendarDelegate {
  const _ClockPersianDelegate(this.clock);
  final DateTime Function() clock;
  @override
  DateTime now() => clock();
}

class _ClockHijriDelegate extends HijriCalendarDelegate {
  const _ClockHijriDelegate(this.clock);
  final DateTime Function() clock;
  @override
  DateTime now() => clock();
}
