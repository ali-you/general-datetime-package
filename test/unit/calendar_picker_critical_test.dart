import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  for (final CalendarTestCase calendar in calendarTestCases) {
    group('${calendar.name} critical delegate and picker contracts', () {
      test('compact parsing validates the last day of every reference month',
          () {
        for (int year = calendar.fixtureMinimumYear;
            year <= calendar.fixtureMaximumYear;
            year++) {
          for (int month = 1; month <= 12; month++) {
            final int length = calendar.referenceMonthLength(year, month);
            final String monthText = month.toString().padLeft(2, '0');
            final String valid = '$length/$monthText/$year';
            final DateTime? parsed = calendar.delegate
                .parseCompactDate(valid, calendar.localizations);
            expect(parsed, isNotNull, reason: valid);
            expect(parsed.runtimeType, calendar.type, reason: valid);
            final DateTime reference =
                calendar.referenceGregorian(year, month, length);
            expect(nativeDate(parsed!),
                DateTime(reference.year, reference.month, reference.day),
                reason: valid);
            expect(
                calendar.delegate.formatCompactDate(
                    calendar.make(year, month, length), calendar.localizations),
                valid);
            expect(
                calendar.delegate.parseCompactDate(
                    '${length + 1}/$monthText/$year', calendar.localizations),
                isNull);
            expect(
                calendar.delegate.parseCompactDate(
                    '00/$monthText/$year', calendar.localizations),
                isNull);
          }
        }
      });

      test(
          'week offsets agree with reference weekdays for all seven week starts',
          () {
        for (final int year in <int>[
          calendar.fixtureMinimumYear,
          calendar.fixtureMinimumYear + 1,
          calendar.anchorYear,
          calendar.fixtureMaximumYear - 1,
          calendar.fixtureMaximumYear,
        ]) {
          for (int month = 1; month <= 12; month++) {
            final int weekday =
                calendar.referenceGregorian(year, month, 1).weekday;
            for (int firstDay = 0; firstDay < 7; firstDay++) {
              final int expected = (weekday % 7 - firstDay + 7) % 7;
              expect(
                  calendar.delegate.firstDayOffset(
                      year, month, _WeekStartLocalizations(firstDay)),
                  expected,
                  reason: '$year-$month, week starts at $firstDay');
            }
          }
        }
      });

      test('month navigation resets the day and obeys signed month deltas', () {
        final DateTime start = calendar.make(calendar.anchorYear, 2,
            calendar.referenceMonthLength(calendar.anchorYear, 2),
            hour: 17);
        for (final int delta in <int>[-25, -12, -1, 0, 1, 12, 25]) {
          final DateTime normalized =
              DateTime.utc(calendar.anchorYear, 2 + delta);
          final DateTime reference =
              calendar.referenceGregorian(normalized.year, normalized.month, 1);
          final DateTime actual =
              calendar.delegate.addMonthsToMonthDate(start, delta);
          expect(actual.runtimeType, calendar.type);
          expect((actual.year, actual.month, actual.day),
              (normalized.year, normalized.month, 1));
          expect(nativeDate(actual),
              DateTime(reference.year, reference.month, reference.day));
          expect(calendar.delegate.monthDelta(start, actual), delta);
          expect(calendar.delegate.monthDelta(actual, start), -delta);
        }
      });

      test('dateOnly clears the time and returns the local calendar type', () {
        final DateTime reference =
            calendar.referenceGregorian(calendar.anchorYear, 1, 1);
        for (final bool isUtc in <bool>[false, true]) {
          final DateTime value = calendar.make(calendar.anchorYear, 1, 1,
              hour: 23,
              minute: 59,
              second: 59,
              millisecond: 999,
              microsecond: 999,
              isUtc: isUtc);
          final DateTime result = calendar.delegate.dateOnly(value);
          expect(result.runtimeType, calendar.type);
          expect(result.isUtc, isFalse);
          expect(nativeDate(result),
              DateTime(reference.year, reference.month, reference.day));
        }
      });

      testWidgets(
          'input rejects invalid, out-of-range, and unselectable days then recovers',
          (WidgetTester tester) async {
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();
        final List<DateTime> submitted = <DateTime>[];
        await tester.pumpWidget(_app(
          calendar,
          Form(
            key: formKey,
            child: InputDatePickerFormField(
              firstDate:
                  calendar.make(calendar.anchorYear, 2, 10, isUtc: false),
              lastDate: calendar.make(calendar.anchorYear, 2, 20, isUtc: false),
              initialDate:
                  calendar.make(calendar.anchorYear, 2, 15, isUtc: false),
              selectableDayPredicate: (DateTime date) => date.day != 13,
              onDateSubmitted: submitted.add,
              calendarDelegate: calendar.delegate,
            ),
          ),
        ));
        for (final (String, String) failure in <(String, String)>[
          ('not a date', calendar.localizations.invalidDateFormatLabel),
          (
            '00/02/${calendar.anchorYear}',
            calendar.localizations.invalidDateFormatLabel
          ),
          (
            '32/02/${calendar.anchorYear}',
            calendar.localizations.invalidDateFormatLabel
          ),
          (
            '09/02/${calendar.anchorYear}',
            calendar.localizations.dateOutOfRangeLabel
          ),
          (
            '21/02/${calendar.anchorYear}',
            calendar.localizations.dateOutOfRangeLabel
          ),
          (
            '13/02/${calendar.anchorYear}',
            calendar.localizations.dateOutOfRangeLabel
          ),
        ]) {
          await tester.enterText(find.byType(TextField), failure.$1);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          expect(formKey.currentState!.validate(), isFalse, reason: failure.$1);
          await tester.pump();
          expect(find.text(failure.$2), findsOneWidget, reason: failure.$1);
          expect(submitted, isEmpty);
        }
        await tester.enterText(
            find.byType(TextField), '12/02/${calendar.anchorYear}');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        expect(formKey.currentState!.validate(), isTrue);
        await tester.pump();
        expect(submitted, hasLength(1));
        expect(submitted.single.runtimeType, calendar.type);
        expect((
          submitted.single.year,
          submitted.single.month,
          submitted.single.day
        ), (
          calendar.anchorYear,
          2,
          12
        ));
        expect(find.text(calendar.localizations.invalidDateFormatLabel),
            findsNothing);
        expect(find.text(calendar.localizations.dateOutOfRangeLabel),
            findsNothing);
      });

      testWidgets(
          'input field honors a customized format and parser end to end',
          (WidgetTester tester) async {
        final MaterialLocalizations custom = calendar.name == 'Persian'
            ? const _TokenPersianLocalizations()
            : const _TokenHijriLocalizations();
        final List<DateTime> submitted = <DateTime>[];
        await tester.pumpWidget(_app(
          calendar,
          InputDatePickerFormField(
            initialDate: calendar.make(calendar.anchorYear, 1, 1, isUtc: false),
            firstDate: calendar.make(calendar.anchorYear, 1, 1, isUtc: false),
            lastDate: calendar.make(calendar.anchorYear, 12, 1, isUtc: false),
            onDateSubmitted: submitted.add,
            calendarDelegate: calendar.delegate,
          ),
          localizations: custom,
        ));
        expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'calendar-token');
        await tester.enterText(find.byType(TextField), 'calendar-token');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(submitted, hasLength(1));
        expect(submitted.single.runtimeType, calendar.type);
        expect((
          submitted.single.year,
          submitted.single.month,
          submitted.single.day
        ), (
          calendar.anchorYear,
          1,
          1
        ));
      });

      testWidgets(
          'month navigation crosses the year and selection returns calendar fields',
          (WidgetTester tester) async {
        final List<DateTime> selected = <DateTime>[];
        final DateTime initial =
            calendar.make(calendar.anchorYear, 12, 1, isUtc: false);
        await tester.pumpWidget(_app(
          calendar,
          CalendarDatePicker(
            initialDate: initial,
            currentDate: initial,
            firstDate: calendar.make(calendar.anchorYear, 1, 1, isUtc: false),
            lastDate:
                calendar.make(calendar.anchorYear + 1, 2, 1, isUtc: false),
            onDateChanged: selected.add,
            calendarDelegate: calendar.delegate,
          ),
        ));
        await tester
            .tap(find.byTooltip(calendar.localizations.nextMonthTooltip));
        await tester.pumpAndSettle();
        expect(
            find.text(calendar.localizations.formatMonthYear(
                calendar.make(calendar.anchorYear + 1, 1, 1, isUtc: false))),
            findsOneWidget);
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        expect(selected, hasLength(1));
        expect(selected.single.runtimeType, calendar.type);
        expect(
            (selected.single.year, selected.single.month, selected.single.day),
            (calendar.anchorYear + 1, 1, 1));
        await tester
            .tap(find.byTooltip(calendar.localizations.previousMonthTooltip));
        await tester.pumpAndSettle();
        expect(find.text(calendar.localizations.formatMonthYear(initial)),
            findsOneWidget);
      });

      testWidgets(
          'range endpoints disable navigation before construction can overflow',
          (WidgetTester tester) async {
        final DateTime minimum =
            calendar.make(calendar.minimumYear, 1, 1, isUtc: false);
        final DateTime maximum = calendar
            .make(calendar.maximumYear, 12, calendar.lastDay, isUtc: false);
        for (final (DateTime, String) endpoint in <(DateTime, String)>[
          (minimum, calendar.localizations.previousMonthTooltip),
          (maximum, calendar.localizations.nextMonthTooltip),
        ]) {
          await tester.pumpWidget(_app(
            calendar,
            CalendarDatePicker(
              key: ValueKey<int>(endpoint.$1.year),
              initialDate: endpoint.$1,
              currentDate: endpoint.$1,
              firstDate: minimum,
              lastDate: maximum,
              onDateChanged: (_) =>
                  fail('Disabled navigation changed the date'),
              calendarDelegate: calendar.delegate,
            ),
          ));
          // Flutter omits tooltips on disabled navigation buttons.
          final Finder button = find.widgetWithIcon(
            IconButton,
            endpoint.$2 == calendar.localizations.previousMonthTooltip
                ? Icons.chevron_left
                : Icons.chevron_right,
          );
          expect(tester.widget<IconButton>(button).onPressed, isNull);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    });
  }

  testWidgets(
      'Gregorian, Persian, and Hijri localization scopes coexist without leakage',
      (WidgetTester tester) async {
    final Map<String, MaterialLocalizations> scopes =
        <String, MaterialLocalizations>{};
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (BuildContext context) {
        scopes['Gregorian'] = MaterialLocalizations.of(context);
        return Column(
            children: calendarTestCases.map((CalendarTestCase calendar) {
          return Localizations.override(
            context: context,
            delegates: <LocalizationsDelegate<dynamic>>[
              calendar.localizationDelegate
            ],
            child: Builder(builder: (BuildContext childContext) {
              scopes[calendar.name] = MaterialLocalizations.of(childContext);
              return Text(calendar.name);
            }),
          );
        }).toList());
      }),
    ));
    expect(scopes['Gregorian'], isA<DefaultMaterialLocalizations>());
    expect(
        scopes['Persian'], isA<DefaultPersianCalendarMaterialLocalizations>());
    expect(scopes['Hijri'], isA<DefaultHijriCalendarMaterialLocalizations>());
    final PersianDateTime persian = PersianDateTime(1403, 1, 1);
    final HijriDateTime hijri = HijriDateTime(1446, 1, 1);
    expect(scopes['Gregorian']!.formatMonthYear(DateTime(2024, 1)),
        'January 2024');
    expect(scopes['Persian']!.formatMonthYear(persian), 'Farvardin 1403');
    expect(scopes['Hijri']!.formatMonthYear(hijri), 'Muharram 1446');
    expect(scopes['Persian']!.parseCompactDate('01/01/1403'),
        isA<PersianDateTime>());
    expect(
        scopes['Hijri']!.parseCompactDate('01/01/1446'), isA<HijriDateTime>());
    expect(scopes['Gregorian']!.parseCompactDate('01/01/2024').runtimeType,
        DateTime);
  });
}

Widget _app(CalendarTestCase calendar, Widget child,
        {MaterialLocalizations? localizations}) =>
    MaterialApp(
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        if (localizations == null)
          calendar.localizationDelegate
        else
          _ValueLocalizationsDelegate(localizations),
      ],
      home: Scaffold(body: child),
    );

class _WeekStartLocalizations extends DefaultMaterialLocalizations {
  const _WeekStartLocalizations(this.firstDay);
  final int firstDay;
  @override
  int get firstDayOfWeekIndex => firstDay;
}

class _ValueLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ValueLocalizationsDelegate(this.value);
  final MaterialLocalizations value;
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(value);
  @override
  bool shouldReload(_ValueLocalizationsDelegate old) => old.value != value;
}

class _TokenPersianLocalizations
    extends DefaultPersianCalendarMaterialLocalizations {
  const _TokenPersianLocalizations();
  @override
  String formatCompactDate(DateTime date) => 'calendar-token';
  @override
  DateTime? parseCompactDate(String? inputString) =>
      inputString == 'calendar-token' ? PersianDateTime(1403, 1, 1) : null;
}

class _TokenHijriLocalizations
    extends DefaultHijriCalendarMaterialLocalizations {
  const _TokenHijriLocalizations();
  @override
  String formatCompactDate(DateTime date) => 'calendar-token';
  @override
  DateTime? parseCompactDate(String? inputString) =>
      inputString == 'calendar-token' ? HijriDateTime(1446, 1, 1) : null;
}
