import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

const delegate = ChineseCalendarDelegate();
const localizations = DefaultChineseCalendarMaterialLocalizations();
Widget app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        DefaultChineseCalendarMaterialLocalizations.delegate
      ],
      home: Scaffold(body: child),
    );

void main() {
  test(
      'delegate counts actual months, guards calendar types and preserves leap identity',
      () {
    for (final year in [2024, 2025]) {
      final first = ChineseDateTime(year);
      for (final month in ChineseDateTime.monthsOfYear(year)) {
        final date = delegate.addMonthsToMonthDate(first, month - 1);
        expect(date, ChineseDateTime(year, month));
        expect(delegate.monthDelta(first, date), month - 1);
        expect(delegate.monthDelta(date, first), 1 - month);
        expect(delegate.getDaysInMonth(year, month),
            ChineseDateTime.daysInMonth(year, month));
      }
    }
    expect(delegate.formatMonthYear(ChineseDateTime(2025, 7), localizations),
        'Leap Month 6 2025');
    expect(delegate.getMonth(2024, 13), ChineseDateTime(2024, 12));
    expect(delegate.addDaysToDate(ChineseDateTime(2025, 6, 30), 1),
        ChineseDateTime(2025, 7));
    expect(delegate.dateOnly(ChineseDateTime.utc(2025, 7, 1, 23)),
        ChineseDateTime(2025, 7));
    expect(() => delegate.dateOnly(DateTime(2025)), throwsArgumentError);
    expect(
        () => delegate.monthDelta(ChineseDateTime(2025), PersianDateTime(1403)),
        throwsArgumentError);
    expect(
        () => delegate.parseCompactDate(
            '01/01/2025', const DefaultMaterialLocalizations()),
        throwsArgumentError);
    for (final date in [
      ChineseDateTime(1901),
      ChineseDateTime(2025, 7, 29),
      ChineseDateTime(2099, 13, 30)
    ]) {
      expect(
          delegate.parseCompactDate(
              delegate.formatCompactDate(date, localizations), localizations),
          date);
    }
    for (final input in [
      null,
      '',
      '30/07/2025',
      '01/13/2024',
      '01/01/2100',
      '01/01/2025junk'
    ]) {
      expect(delegate.parseCompactDate(input, localizations), isNull);
    }
  });

  testWidgets('Material picker navigates regular, leap and following months',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(app(CalendarDatePicker(
      firstDate: ChineseDateTime(2024),
      lastDate: ChineseDateTime(2026, 12, 29),
      initialDate: ChineseDateTime(2025, 6),
      currentDate: ChineseDateTime(2025, 6),
      calendarDelegate: delegate,
      onDateChanged: (date) => selected = date,
    )));
    expect(find.text('Month 6 2025'), findsOneWidget);
    await tester.tap(find.byTooltip(localizations.nextMonthTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Leap Month 6 2025'), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(selected, ChineseDateTime(2025, 7, 10));
    await tester.tap(find.byTooltip(localizations.nextMonthTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Month 7 2025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('input distinguishes ordinal months and rejects absent month 13',
      (tester) async {
    DateTime? submitted;
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(app(Form(
        key: key,
        child: InputDatePickerFormField(
          firstDate: ChineseDateTime(2024),
          lastDate: ChineseDateTime(2025, 13, 29),
          initialDate: ChineseDateTime(2025, 7),
          calendarDelegate: delegate,
          onDateSubmitted: (date) => submitted = date,
        ))));
    await tester.enterText(find.byType(TextField), '01/13/2024');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(submitted, isNull);
    await tester.enterText(find.byType(TextField), '29/07/2025');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(key.currentState!.validate(), isTrue);
    await tester.pump();
    expect(submitted, ChineseDateTime(2025, 7, 29));
  });

  for (final atMinimum in [true, false]) {
    testWidgets(
        'range picker saves the supported ${atMinimum ? 'minimum' : 'maximum'} month',
        (tester) async {
      final year = atMinimum ? 1901 : 2099;
      final month = atMinimum ? 1 : 13;
      final first = ChineseDateTime(year, month);
      final last = ChineseDateTime(
          year, month, ChineseDateTime.daysInMonth(year, month));
      final initial = DateTimeRange<DateTime>(start: first, end: last);
      DateTimeRange? selected;
      final range = delegate.rangePickerDelegate;
      await tester.pumpWidget(app(Builder(
          builder: (context) => TextButton(
                onPressed: () async => selected = await showDateRangePicker(
                  context: context,
                  firstDate: first,
                  lastDate: last,
                  currentDate: first,
                  initialDateRange: initial,
                  calendarDelegate: range,
                  builder: calendarDateRangePickerBuilder(range),
                ),
                child: const Text('open'),
              ))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(localizations.saveButtonLabel));
      await tester.pumpAndSettle();
      expect(selected, initial);
      expect(selected!.start, isA<ChineseDateTime>());
      expect(selected!.end, isA<ChineseDateTime>());
    });
  }
}
