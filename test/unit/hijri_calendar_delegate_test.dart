import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const HijriCalendarDelegate delegate = HijriCalendarDelegate();
  const DefaultHijriCalendarMaterialLocalizations localizations =
      DefaultHijriCalendarMaterialLocalizations();

  group('HijriCalendarDelegate localizations', () {
    final HijriDateTime date = HijriDateTime(1446, 1, 1);

    test('uses Umm al-Qura names and formats supplied by localizations', () {
      expect(delegate.formatMonthYear(date, localizations), 'Muharram 1446');
      expect(delegate.formatMediumDate(date, localizations), 'Sun, Muh 1');
      expect(delegate.formatShortMonthDay(date, localizations), 'Muh 1');
      expect(delegate.formatShortDate(date, localizations), 'Muh 1, 1446');
      expect(delegate.formatFullDate(date, localizations),
          'Sunday, Muharram 1, 1446');
      expect(delegate.formatCompactDate(date, localizations), '01/01/1446');
      expect(delegate.formatYear(1446, localizations), '1446');
      expect(delegate.dateHelpText(localizations), localizations.dateHelpText);
      expect(delegate.formatMonthYear(HijriDateTime(1446, 12), localizations),
          'Dhu al-Hijjah 1446');
    });

    test('honors customized month names and input help', () {
      const _CustomHijriMaterialLocalizations custom =
          _CustomHijriMaterialLocalizations();
      expect(delegate.formatMonthYear(date, custom), 'Custom month 1 / 1446');
      expect(delegate.dateHelpText(custom), 'Custom Hijri date help');
    });

    test('honors customized formats and parsing', () {
      const _CustomHijriMaterialLocalizations custom =
          _CustomHijriMaterialLocalizations();
      expect(delegate.formatYear(1446, custom), 'Year 1446');
      expect(delegate.formatMediumDate(date, custom), 'Custom medium date');
      expect(delegate.formatShortMonthDay(date, custom), 'Custom month day');
      expect(delegate.formatShortDate(date, custom), 'Custom short date');
      expect(delegate.formatFullDate(date, custom), 'Custom full date');
      expect(delegate.formatCompactDate(date, custom), 'custom-date');
      expect(delegate.parseCompactDate('custom-date', custom), date);
      expect(delegate.parseCompactDate('01/01/1446', custom), isNull);
    });

    test('uses the supplied parser for valid Hijri dates', () {
      final DateTime? parsed =
          delegate.parseCompactDate(' 30 / 02 / 1446 ', localizations);
      expect(parsed, isA<HijriDateTime>());
      expect((parsed?.year, parsed?.month, parsed?.day), (1446, 2, 30));
    });

    test('rejects malformed, invalid, and unsupported dates', () {
      for (final String? input in <String?>[
        null,
        '',
        '30/02',
        '30-02-1446',
        'not/a/date',
        '00/02/1446',
        '31/02/1446',
        '01/13/1446',
        '30/01/1446',
        '1446/02/30',
        '01/01/1299',
        '01/01/1601',
      ]) {
        expect(delegate.parseCompactDate(input, localizations), isNull,
            reason: input);
      }
    });

    test('round-trips supported dates through the localization formats', () {
      for (final int year in <int>[1300, 1356, 1400, 1446, 1500, 1600]) {
        final HijriDateTime date = HijriDateTime(year, 2, 1);
        final String formatted =
            delegate.formatCompactDate(date, localizations);
        expect(delegate.parseCompactDate(formatted, localizations), date,
            reason: formatted);
      }
    });
  });

  group('HijriCalendarDelegate calendar operations', () {
    test('uses official month lengths', () {
      expect(delegate.getDaysInMonth(1446, 1), 29);
      expect(delegate.getDaysInMonth(1446, 2), 30);
      expect(
        delegate.getDaysInMonth(1446, 12),
        HijriDateTime.daysInMonth(1446, 12),
      );
    });

    test('navigates across ordinary year boundaries', () {
      final DateTime nextMonth = delegate.addMonthsToMonthDate(
        HijriDateTime(1446, 12, 1),
        1,
      );
      final DateTime nextDay = delegate.addDaysToDate(
        HijriDateTime(
          1446,
          12,
          HijriDateTime.daysInMonth(1446, 12),
        ),
        1,
      );

      expect((nextMonth.year, nextMonth.month, nextMonth.day), (1447, 1, 1));
      expect((nextDay.year, nextDay.month, nextDay.day), (1447, 1, 1));
    });

    test('throws when navigation leaves the supported range', () {
      final int minimumYear = HijriDateTime.minimumYear;
      final int maximumYear = HijriDateTime.maximumYear;
      final int lastDay = HijriDateTime.daysInMonth(maximumYear, 12);

      expect(
        () => delegate.addMonthsToMonthDate(
          HijriDateTime(minimumYear, 1, 1),
          -1,
        ),
        throwsRangeError,
      );
      expect(
        () => delegate.addDaysToDate(
          HijriDateTime(maximumYear, 12, lastDay),
          1,
        ),
        throwsRangeError,
      );
    });

    test('aligns offsets with ambient week headers', () {
      expect(
        delegate.firstDayOffset(
          1446,
          1,
          const _FirstDayMaterialLocalizations(0),
        ),
        0,
      );
      expect(
        delegate.firstDayOffset(
          1446,
          1,
          const _FirstDayMaterialLocalizations(1),
        ),
        6,
      );
      expect(
        delegate.firstDayOffset(
          1446,
          1,
          const _FirstDayMaterialLocalizations(6),
        ),
        1,
      );
    });
  });

  group('Hijri Material localizations', () {
    const DefaultHijriCalendarMaterialLocalizations localizations =
        DefaultHijriCalendarMaterialLocalizations();

    test('round-trips both supported endpoints', () {
      for (final HijriDateTime date in <HijriDateTime>[
        HijriDateTime(1300, 1, 1),
        HijriDateTime(1600, 12, 30),
      ]) {
        expect(
            localizations
                .parseCompactDate(localizations.formatCompactDate(date)),
            date);
      }
    });

    test('validates dates against the supported range', () {
      final int minimumYear = HijriDateTime.minimumYear;
      final int maximumYear = HijriDateTime.maximumYear;

      expect(
        localizations.parseCompactDate('01/01/$minimumYear'),
        isA<HijriDateTime>(),
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

  testWidgets('CalendarDatePicker renders names from Hijri localizations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Localizations.override(
              context: context,
              delegates: const <LocalizationsDelegate<dynamic>>[
                DefaultHijriCalendarMaterialLocalizations.delegate,
              ],
              child: CalendarDatePicker(
                initialDate: HijriDateTime(1446, 1, 1),
                firstDate: HijriDateTime(1445, 1, 1),
                lastDate: HijriDateTime(1447, 12, 29),
                currentDate: HijriDateTime(1446, 1, 1),
                onDateChanged: (_) {},
                calendarDelegate: delegate,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Muharram 1446'), findsOneWidget);
    expect(find.text('January 1446'), findsNothing);
  });

  testWidgets('picker month header honors a custom localization',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _CustomHijriLocalizationsDelegate(),
        ],
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: HijriDateTime(1446, 1, 1),
            firstDate: HijriDateTime(1445, 1, 1),
            lastDate: HijriDateTime(1447, 12, 29),
            currentDate: HijriDateTime(1446, 1, 1),
            onDateChanged: (_) {},
            calendarDelegate: delegate,
          ),
        ),
      ),
    );
    expect(find.text('Custom month 1 / 1446'), findsOneWidget);
    expect(find.text('Muharram 1446'), findsNothing);
  });

  testWidgets('input picker uses Hijri localization parsing',
      (WidgetTester tester) async {
    DateTime? submittedDate;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          DefaultHijriCalendarMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: InputDatePickerFormField(
            initialDate: HijriDateTime(1446, 2, 30),
            firstDate: HijriDateTime(1446, 1, 1),
            lastDate:
                HijriDateTime(1446, 12, HijriDateTime.daysInMonth(1446, 12)),
            onDateSubmitted: (DateTime date) => submittedDate = date,
            calendarDelegate: delegate,
          ),
        ),
      ),
    );
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '30/02/1446');
    await tester.enterText(find.byType(TextField), '30/02/1446');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submittedDate, isA<HijriDateTime>());
    expect((submittedDate?.year, submittedDate?.month, submittedDate?.day),
        (1446, 2, 30));
  });
}

class _FirstDayMaterialLocalizations extends DefaultMaterialLocalizations {
  const _FirstDayMaterialLocalizations(this.firstDay);
  final int firstDay;
  @override
  int get firstDayOfWeekIndex => firstDay;
}

class _CustomHijriMaterialLocalizations
    extends DefaultHijriCalendarMaterialLocalizations {
  const _CustomHijriMaterialLocalizations();
  @override
  String formatMonthYear(DateTime date) =>
      'Custom month ${date.month} / ${date.year}';
  @override
  String get dateHelpText => 'Custom Hijri date help';

  @override
  String formatYear(DateTime date) => 'Year ${date.year}';
  @override
  String formatMediumDate(DateTime date) => 'Custom medium date';
  @override
  String formatShortMonthDay(DateTime date) => 'Custom month day';
  @override
  String formatShortDate(DateTime date) => 'Custom short date';
  @override
  String formatFullDate(DateTime date) => 'Custom full date';
  @override
  String formatCompactDate(DateTime date) => 'custom-date';
  @override
  DateTime? parseCompactDate(String? inputString) =>
      inputString == 'custom-date' ? HijriDateTime(1446, 1, 1) : null;
}

class _CustomHijriLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CustomHijriLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
          const _CustomHijriMaterialLocalizations());
  @override
  bool shouldReload(_CustomHijriLocalizationsDelegate old) => false;
}
