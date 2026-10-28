import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const delegate = HebrewCalendarDelegate();
  const localizations = DefaultHebrewCalendarMaterialLocalizations();

  test('actual months navigate through both Adars and skip absent Adar I', () {
    for (final year in [5784, 5785]) {
      final first = HebrewDateTime(year);
      final months = HebrewDateTime.monthsOfYear(year);
      for (var index = 0; index < months.length; index++) {
        final date = delegate.addMonthsToMonthDate(first, index);
        expect((date.year, date.month, date.day), (year, months[index], 1));
        expect(delegate.monthDelta(first, date), index);
        expect(delegate.monthDelta(date, first), -index);
        expect(delegate.getDaysInMonth(year, months[index]),
            HebrewDateTime.daysInMonth(year, months[index]));
      }
      expect(delegate.addMonthsToMonthDate(first, months.length),
          HebrewDateTime(year + 1));
    }
    expect(
        delegate.getMonth(5785, HebrewDateTime.adarI), HebrewDateTime(5785, 7));
    expect(delegate.addDaysToDate(HebrewDateTime(5785, 5, 30), 1),
        HebrewDateTime(5785, 7, 1));
    expect(delegate.dateOnly(HebrewDateTime.utc(5784, 7, 10, 23)),
        HebrewDateTime(5784, 7, 10));
  });

  test('formats month identities and strictly parses calendar fields', () {
    final date = HebrewDateTime(5784, 7, 10);
    expect(delegate.formatMonthYear(date, localizations), 'Adar II 5784');
    expect(delegate.formatFullDate(date, localizations),
        'Wednesday, Adar II 10, 5784');
    expect(delegate.formatMonthYear(HebrewDateTime(5785, 7), localizations),
        'Adar 5785');
    expect(delegate.formatMonthYear(HebrewDateTime(5784, 6), localizations),
        'Adar I 5784');
    for (final date in [
      HebrewDateTime(1),
      HebrewDateTime(5784, 6, 30),
      HebrewDateTime(5785, 7, 29),
      HebrewDateTime(9999, 13, 29),
    ]) {
      expect(
          delegate.parseCompactDate(
              delegate.formatCompactDate(date, localizations), localizations),
          date);
    }
    for (final input in [
      null,
      '',
      '30/07/5785',
      '01/06/5785',
      '01/14/5784',
      '01/01/0',
      '01/01/10000',
      '01/07/5784junk'
    ]) {
      expect(delegate.parseCompactDate(input, localizations), isNull);
    }
    expect(() => delegate.dateOnly(DateTime(2024)), throwsArgumentError);
    expect(() => delegate.monthDelta(date, PersianDateTime(1403)),
        throwsArgumentError);
    expect(
        () => delegate.parseCompactDate(
            '01/01/2024', const DefaultMaterialLocalizations()),
        throwsArgumentError);
    expect(localizations.formatYear(DateTime(5784)), '5784');
  });

  test('week offsets and range probes work at both supported endpoints', () {
    for (var firstDay = 0; firstDay < 7; firstDay++) {
      expect(delegate.firstDayOffset(5784, 7, _WeekStart(firstDay)),
          (DateTime(2024, 3, 11).weekday % 7 - firstDay + 7) % 7);
    }
    final range = delegate.rangePickerDelegate;
    final minimum = HebrewDateTime(1);
    final maximum = HebrewDateTime(9999, 13, 29);
    for (var day = -5; day <= 0; day++) {
      expect(range.getDay(1, 1, day).isBefore(minimum), isTrue);
    }
    expect(range.addDaysToDate(maximum, 7).isAfter(maximum), isTrue);
    expect(() => delegate.addMonthsToMonthDate(minimum, -1), throwsRangeError);
    expect(() => delegate.addDaysToDate(maximum, 1), throwsRangeError);
  });

  testWidgets('picker visits leap months and changes to a common year',
      (tester) async {
    DateTime? selected;
    await tester.pumpWidget(_app(CalendarDatePicker(
      initialDate: HebrewDateTime(5784, 5, 10),
      firstDate: HebrewDateTime(5783),
      lastDate: HebrewDateTime(5785, 13, 29),
      currentDate: HebrewDateTime(5784, 5, 10),
      onDateChanged: (date) => selected = date,
      calendarDelegate: delegate,
    )));
    expect(find.text('Shevat 5784'), findsOneWidget);
    await tester.tap(find.byTooltip(localizations.nextMonthTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Adar I 5784'), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(selected, HebrewDateTime(5784, 6, 10));
    await tester.tap(find.text('Adar I 5784'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5785'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Adar 5785'), findsOneWidget);
    expect(selected, HebrewDateTime(5785, 7, 10));
    await tester.tap(find.byTooltip(localizations.previousMonthTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Shevat 5785'), findsOneWidget);
  });

  testWidgets('input rejects an absent Adar I and accepts ordinary Adar',
      (tester) async {
    DateTime? submitted;
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_app(Form(
        key: formKey,
        child: InputDatePickerFormField(
          firstDate: HebrewDateTime(5785),
          lastDate: HebrewDateTime(5785, 13, 29),
          initialDate: HebrewDateTime(5785, 7),
          onDateSubmitted: (date) => submitted = date,
          calendarDelegate: delegate,
        ))));
    await tester.enterText(find.byType(TextField), '01/06/5785');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(submitted, isNull);
    expect(find.text(localizations.invalidDateFormatLabel), findsOneWidget);
    await tester.enterText(find.byType(TextField), '29/07/5785');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(submitted, HebrewDateTime(5785, 7, 29));
  });

  for (final atMinimum in [true, false]) {
    testWidgets(
        'range picker renders and saves Hebrew ${atMinimum ? 'minimum' : 'maximum'}',
        (tester) async {
      final year = atMinimum ? 1 : 9999;
      final month = atMinimum ? 1 : 13;
      final first = HebrewDateTime(year, month);
      final last =
          HebrewDateTime(year, month, HebrewDateTime.daysInMonth(year, month));
      final initial = DateTimeRange<DateTime>(start: first, end: last);
      DateTimeRange? selected;
      final range = delegate.rangePickerDelegate;
      await tester.pumpWidget(_app(Builder(
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
      expect(selected!.start, isA<HebrewDateTime>());
      expect(selected!.end, isA<HebrewDateTime>());
    });
  }
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        DefaultHebrewCalendarMaterialLocalizations.delegate
      ],
      home: Scaffold(body: child),
    );

class _WeekStart extends DefaultMaterialLocalizations {
  const _WeekStart(this.firstDay);
  final int firstDay;
  @override
  int get firstDayOfWeekIndex => firstDay;
}
