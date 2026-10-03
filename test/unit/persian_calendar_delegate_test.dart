import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const PersianCalendarDelegate delegate = PersianCalendarDelegate();
  const DefaultPersianCalendarMaterialLocalizations localizations =
      DefaultPersianCalendarMaterialLocalizations();

  group('PersianCalendarDelegate localizations', () {
    final PersianDateTime date = PersianDateTime(1403, 1, 1);

    test('uses Solar Hijri names and formats supplied by localizations', () {
      expect(delegate.formatMonthYear(date, localizations), 'Farvardin 1403');
      expect(delegate.formatMediumDate(date, localizations), 'Wed, Far 1');
      expect(delegate.formatShortMonthDay(date, localizations), 'Far 1');
      expect(delegate.formatShortDate(date, localizations), 'Far 1, 1403');
      expect(delegate.formatFullDate(date, localizations),
          'Wednesday, Farvardin 1, 1403');
      expect(delegate.formatCompactDate(date, localizations), '01/01/1403');
      expect(delegate.formatYear(1403, localizations), '1403');
      expect(delegate.dateHelpText(localizations), localizations.dateHelpText);
      expect(delegate.formatMonthYear(PersianDateTime(1403, 12), localizations),
          'Esfand 1403');
    });

    test('honors customized month names and input help', () {
      const _CustomPersianMaterialLocalizations custom =
          _CustomPersianMaterialLocalizations();
      expect(delegate.formatMonthYear(date, custom), 'Custom month 1 / 1403');
      expect(delegate.dateHelpText(custom), 'Custom Persian date help');
    });

    test('uses the supplied parser for valid Persian dates', () {
      final DateTime? parsed =
          delegate.parseCompactDate(' 31 / 02 / 1403 ', localizations);
      expect(parsed, isA<PersianDateTime>());
      expect((parsed?.year, parsed?.month, parsed?.day), (1403, 2, 31));
    });

    test('rejects malformed, invalid, and unsupported dates', () {
      for (final String? input in <String?>[
        null,
        '',
        '31/02',
        '31-02-1403',
        'not/a/date',
        '00/02/1403',
        '32/02/1403',
        '01/13/1403',
        '30/12/1402',
        '1403/02/31',
        '01/01/-62',
        '01/01/3178',
      ]) {
        expect(delegate.parseCompactDate(input, localizations), isNull,
            reason: input);
      }
    });

    test('round-trips extended dates through the localization formats', () {
      for (final int year in <int>[-61, -1, 0, 1000, 1403, 2000, 3177]) {
        final PersianDateTime date = PersianDateTime(year, 2, 31);
        final String formatted =
            delegate.formatCompactDate(date, localizations);
        expect(delegate.parseCompactDate(formatted, localizations), date,
            reason: formatted);
      }
    });
  });

  group('PersianCalendarDelegate calendar operations', () {
    test('uses official month lengths', () {
      expect(delegate.getDaysInMonth(1403, 1), 31);
      expect(delegate.getDaysInMonth(1403, 7), 30);
      expect(
        delegate.getDaysInMonth(1403, 12),
        PersianDateTime.daysInMonth(1403, 12),
      );
    });

    test('navigates across ordinary year boundaries', () {
      final DateTime nextMonth = delegate.addMonthsToMonthDate(
        PersianDateTime(1403, 12, 1),
        1,
      );
      final DateTime nextDay = delegate.addDaysToDate(
        PersianDateTime(
          1403,
          12,
          PersianDateTime.daysInMonth(1403, 12),
        ),
        1,
      );

      expect((nextMonth.year, nextMonth.month, nextMonth.day), (1404, 1, 1));
      expect((nextDay.year, nextDay.month, nextDay.day), (1404, 1, 1));
    });

    test('throws when navigation leaves the supported range', () {
      final int minimumYear = PersianDateTime.minimumYear;
      final int maximumYear = PersianDateTime.maximumYear;
      final int lastDay = PersianDateTime.daysInMonth(maximumYear, 12);

      expect(
        () => delegate.addMonthsToMonthDate(
          PersianDateTime(minimumYear, 1, 1),
          -1,
        ),
        throwsRangeError,
      );
      expect(
        () => delegate.addDaysToDate(
          PersianDateTime(maximumYear, 12, lastDay),
          1,
        ),
        throwsRangeError,
      );
    });

    test('aligns offsets with ambient week headers', () {
      expect(
        delegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(0),
        ),
        3,
      );
      expect(
        delegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(1),
        ),
        2,
      );
      expect(
        delegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(6),
        ),
        4,
      );
    });
  });

  group('Persian Material localizations', () {
    const DefaultPersianCalendarMaterialLocalizations localizations =
        DefaultPersianCalendarMaterialLocalizations();

    test('round-trips compact dates with negative years', () {
      final PersianDateTime date = PersianDateTime(-61);
      expect(localizations.formatCompactDate(date), '01/01/-0061');
      expect(
          localizations.parseCompactDate(localizations.formatCompactDate(date)),
          date);
    });

    test('validates dates against the supported range', () {
      final int minimumYear = PersianDateTime.minimumYear;
      final int maximumYear = PersianDateTime.maximumYear;

      expect(
        localizations.parseCompactDate('01/01/$minimumYear'),
        isA<PersianDateTime>(),
      );
      expect(
        localizations.parseCompactDate('01/01/${minimumYear - 1}'),
        isNull,
      );
      expect(
        localizations.parseCompactDate('01/01/${maximumYear + 1}'),
        isNull,
      );
    });

    test('reports expansion state correctly', () {
      expect(localizations.expandedHint, 'Expanded');
      expect(localizations.collapsedHint, 'Collapsed');
    });
  });

  testWidgets('CalendarDatePicker renders names from Persian localizations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Localizations.override(
              context: context,
              delegates: const <LocalizationsDelegate<dynamic>>[
                DefaultPersianCalendarMaterialLocalizations.delegate,
              ],
              child: CalendarDatePicker(
                initialDate: PersianDateTime(1403, 1, 1),
                firstDate: PersianDateTime(1402, 1, 1),
                lastDate: PersianDateTime(1404, 12, 29),
                currentDate: PersianDateTime(1403, 1, 1),
                onDateChanged: (_) {},
                calendarDelegate: delegate,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Farvardin 1403'), findsOneWidget);
    expect(find.text('January 1403'), findsNothing);
  });

  testWidgets('picker month header honors a custom localization',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _CustomPersianLocalizationsDelegate(),
        ],
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: PersianDateTime(1403, 1, 1),
            firstDate: PersianDateTime(1402, 1, 1),
            lastDate: PersianDateTime(1404, 12, 29),
            currentDate: PersianDateTime(1403, 1, 1),
            onDateChanged: (_) {},
            calendarDelegate: delegate,
          ),
        ),
      ),
    );
    expect(find.text('Custom month 1 / 1403'), findsOneWidget);
    expect(find.text('Farvardin 1403'), findsNothing);
  });

  testWidgets('input picker uses Persian localization parsing',
      (WidgetTester tester) async {
    DateTime? submittedDate;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          DefaultPersianCalendarMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: InputDatePickerFormField(
            initialDate: PersianDateTime(1403, 2, 31),
            firstDate: PersianDateTime(1403, 1, 1),
            lastDate: PersianDateTime(1403, 12, 30),
            onDateSubmitted: (DateTime date) => submittedDate = date,
            calendarDelegate: delegate,
          ),
        ),
      ),
    );
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '31/02/1403');
    await tester.enterText(find.byType(TextField), '31/02/1403');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submittedDate, isA<PersianDateTime>());
    expect((submittedDate?.year, submittedDate?.month, submittedDate?.day),
        (1403, 2, 31));
  });
}

class _FirstDayMaterialLocalizations extends DefaultMaterialLocalizations {
  const _FirstDayMaterialLocalizations(this.firstDay);
  final int firstDay;
  @override
  int get firstDayOfWeekIndex => firstDay;
}

class _CustomPersianMaterialLocalizations
    extends DefaultPersianCalendarMaterialLocalizations {
  const _CustomPersianMaterialLocalizations();
  @override
  String formatMonthYear(DateTime date) =>
      'Custom month ${date.month} / ${date.year}';
  @override
  String get dateHelpText => 'Custom Persian date help';
}

class _CustomPersianLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CustomPersianLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
          const _CustomPersianMaterialLocalizations());
  @override
  bool shouldReload(_CustomPersianLocalizationsDelegate old) => false;
}
