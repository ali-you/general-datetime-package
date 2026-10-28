import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

const arithmetic = ChineseCalendarDelegate();
const english = DefaultChineseCalendarMaterialLocalizations();

void main() {
  test('all date-accepting delegate operations reject native and foreign dates',
      () {
    final date = ChineseDateTime(2025, 7);
    final operations = <void Function(DateTime)>[
      (d) {
        arithmetic.dateOnly(d);
      },
      (d) {
        arithmetic.datesOnly(DateTimeRange(start: d, end: d));
      },
      (d) {
        arithmetic.isSameDay(date, d);
      },
      (d) {
        arithmetic.isSameDay(d, null);
      },
      (d) {
        arithmetic.isSameMonth(date, d);
      },
      (d) {
        arithmetic.monthDelta(date, d);
      },
      (d) {
        arithmetic.monthDelta(d, date);
      },
      (d) {
        arithmetic.addDaysToDate(d, 1);
      },
      (d) {
        arithmetic.addMonthsToMonthDate(d, 1);
      },
      (d) {
        arithmetic.formatMonthYear(d, english);
      },
      (d) {
        arithmetic.formatMediumDate(d, english);
      },
      (d) {
        arithmetic.formatShortMonthDay(d, english);
      },
      (d) {
        arithmetic.formatShortDate(d, english);
      },
      (d) {
        arithmetic.formatFullDate(d, english);
      },
      (d) {
        arithmetic.formatCompactDate(d, english);
      },
    ];
    for (final invalid in [
      DateTime(2025),
      PersianDateTime(1403),
      HebrewDateTime(5784),
      HijriDateTime(1445)
    ]) {
      for (final operation in operations) {
        expect(() => operation(invalid), throwsArgumentError);
      }
    }
    expect(arithmetic.isSameDay(null, null), isTrue);
    expect(arithmetic.isSameMonth(null, date), isFalse);
    expect(arithmetic.parseCompactDate(null, english), isNull);
  });

  test(
      'clamped carried month uses the same first weekday and length as its resolved month',
      () {
    for (var firstDay = 0; firstDay < 7; firstDay++) {
      final localizations = _WeekStart(firstDay);
      final resolved = arithmetic.getMonth(2024, 13);
      expect(resolved, ChineseDateTime(2024, 12));
      expect(arithmetic.firstDayOffset(2024, 13, localizations),
          (DateTime(2024, 12, 31).weekday % 7 - firstDay + 7) % 7);
      expect(arithmetic.getDaysInMonth(2024, 13), resolved.monthLength);
    }
  });

  testWidgets(
      'year picker clamps month thirteen and its day within the selected year',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(_app(CalendarDatePicker(
      firstDate: ChineseDateTime(2024),
      lastDate: ChineseDateTime(2026, 12, 29),
      initialDate: ChineseDateTime(2025, 13, 29),
      currentDate: ChineseDateTime(2025, 13, 29),
      calendarDelegate: arithmetic,
      onDateChanged: (date) => selected = date,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Month 12 2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(selected, ChineseDateTime(2024, 12, 29));
    expect(find.text('Month 12 2024'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'range selection crosses from a regular month into its leap counterpart',
      (tester) async {
    DateTimeRange? selected;
    final range = arithmetic.rangePickerDelegate;
    await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
              onPressed: () async => selected = await showDateRangePicker(
                context: context,
                firstDate: ChineseDateTime(2025, 6),
                lastDate: ChineseDateTime(2025, 7, 29),
                currentDate: ChineseDateTime(2025, 6),
                calendarDelegate: range,
                builder: calendarDateRangePickerBuilder(range),
              ),
              child: const Text('open'),
            ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2').last);
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.saveButtonLabel));
    await tester.pumpAndSettle();
    expect(selected?.start, ChineseDateTime(2025, 6, 30));
    expect(selected?.end, ChineseDateTime(2025, 7, 2));
    expect((selected!.end as ChineseDateTime).monthCode, 'M06L');
    expect(tester.takeException(), isNull);
  });

  for (var weekStart = 0; weekStart < 7; weekStart++) {
    for (final atMinimum in [true, false]) {
      testWidgets(
          'range keyboard respects ${atMinimum ? 'minimum' : 'maximum'} weekStart=$weekStart',
          (tester) async {
        final range = arithmetic.rangePickerDelegate;
        final endpoint =
            atMinimum ? ChineseDateTime(1901) : ChineseDateTime(2099, 13, 30);
        final first = ChineseDateTime(endpoint.year, endpoint.month);
        final last = ChineseDateTime(
            endpoint.year, endpoint.month, endpoint.monthLength);
        final initial = DateTimeRange<DateTime>(start: endpoint, end: endpoint);
        DateTimeRange? selected;
        await tester.pumpWidget(_app(
            Builder(
                builder: (context) => TextButton(
                      onPressed: () async =>
                          selected = await showDateRangePicker(
                        context: context,
                        firstDate: first,
                        lastDate: last,
                        currentDate: endpoint,
                        initialDateRange: initial,
                        calendarDelegate: range,
                        builder: calendarDateRangePickerBuilder(range),
                      ),
                      child: const Text('open'),
                    )),
            weekStart: weekStart));
        await tester.pumpAndSettle();
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final cell = tester.widget<InkResponse>(find
            .ancestor(
                of: find.text('${endpoint.day}'),
                matching: find.byType(InkResponse))
            .first);
        cell.focusNode!.requestFocus();
        await tester.pumpAndSettle();
        expect(cell.focusNode!.hasFocus, isTrue,
            reason: 'initial endpoint focus');
        for (final key in atMinimum
            ? [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]
            : [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowDown]) {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(cell.focusNode!.hasFocus, isTrue);
        }
        await tester.tap(find.text(english.saveButtonLabel));
        await tester.pumpAndSettle();
        expect(selected, initial);
      });
    }
  }
}

Widget _app(Widget child, {int weekStart = 0}) => MaterialApp(
      localizationsDelegates: [_WeekDelegate(weekStart)],
      home: Scaffold(body: child),
    );

class _WeekStart extends DefaultChineseCalendarMaterialLocalizations {
  const _WeekStart(this.firstDay);
  final int firstDay;
  @override
  int get firstDayOfWeekIndex => firstDay;
}

class _WeekDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _WeekDelegate(this.firstDay);
  final int firstDay;
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      _WeekStart(firstDay);
  @override
  bool shouldReload(_WeekDelegate old) => old.firstDay != firstDay;
}
