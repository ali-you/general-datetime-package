import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const PersianCalendarDelegate defaultDelegate = PersianCalendarDelegate();
  const PersianCalendarDelegate englishDelegate =
      PersianCalendarDelegate.english();
  const PersianCalendarDelegate persianDelegate =
      PersianCalendarDelegate.persian();
  const DefaultMaterialLocalizations gregorianLocalizations =
      DefaultMaterialLocalizations();
  const DefaultHijriCalendarMaterialLocalizations hijriLocalizations =
      DefaultHijriCalendarMaterialLocalizations();

  group('PersianCalendarDelegate presentation', () {
    final PersianDateTime date = PersianDateTime(1403, 1, 1);

    test('default constructor preserves the English presentation', () {
      expect(
        defaultDelegate.presentation,
        PersianCalendarPresentation.english,
      );
      expect(
        defaultDelegate.formatMonthYear(date, gregorianLocalizations),
        englishDelegate.formatMonthYear(date, gregorianLocalizations),
      );
    });

    test('English formatting is independent of ambient localizations', () {
      for (final MaterialLocalizations localizations in <MaterialLocalizations>[
        gregorianLocalizations,
        hijriLocalizations,
      ]) {
        expect(
          englishDelegate.formatMonthYear(date, localizations),
          'Farvardin 1403',
        );
        expect(englishDelegate.formatYear(date.year, localizations), '1403');
        expect(
          englishDelegate.formatMediumDate(date, localizations),
          'Wed, Far 1',
        );
        expect(
          englishDelegate.formatShortMonthDay(date, localizations),
          'Far 1',
        );
        expect(
          englishDelegate.formatShortDate(date, localizations),
          'Far 1, 1403',
        );
        expect(
          englishDelegate.formatFullDate(date, localizations),
          'Wednesday, Farvardin 1, 1403',
        );
        expect(
          englishDelegate.formatCompactDate(date, localizations),
          '01/01/1403',
        );
        expect(englishDelegate.dateHelpText(localizations), 'dd/mm/yyyy');
      }
    });

    test('Persian formatting uses Persian names, digits, and date order', () {
      expect(
        persianDelegate.formatMonthYear(date, gregorianLocalizations),
        'فروردین ۱۴۰۳',
      );
      expect(
        persianDelegate.formatYear(date.year, gregorianLocalizations),
        '۱۴۰۳',
      );
      expect(
        persianDelegate.formatMediumDate(date, gregorianLocalizations),
        'چهارشنبه ۱ فروردین',
      );
      expect(
        persianDelegate.formatShortMonthDay(date, gregorianLocalizations),
        '۱ فروردین',
      );
      expect(
        persianDelegate.formatShortDate(date, gregorianLocalizations),
        '۱ فروردین ۱۴۰۳',
      );
      expect(
        persianDelegate.formatFullDate(date, gregorianLocalizations),
        '۱۴۰۳ فروردین ۱، چهارشنبه',
      );
      expect(
        persianDelegate.formatCompactDate(date, gregorianLocalizations),
        '۱۴۰۳/۰۱/۰۱',
      );
      expect(
        persianDelegate.dateHelpText(gregorianLocalizations),
        'yyyy/mm/dd',
      );
    });
  });

  group('PersianCalendarDelegate parsing', () {
    test('English parser returns strict PersianDateTime values', () {
      for (final MaterialLocalizations localizations in <MaterialLocalizations>[
        gregorianLocalizations,
        hijriLocalizations,
      ]) {
        final DateTime? parsed =
            englishDelegate.parseCompactDate(' 31 / 02 / 1403 ', localizations);

        expect(parsed, isA<PersianDateTime>());
        expect(parsed?.year, 1403);
        expect(parsed?.month, 2);
        expect(parsed?.day, 31);
      }
    });

    test('normalizes Latin, Persian, and Arabic-Indic digits', () {
      final DateTime? latin = persianDelegate.parseCompactDate(
        '1403/02/31',
        gregorianLocalizations,
      );
      final DateTime? persian = persianDelegate.parseCompactDate(
        '۱۴۰۳/۰۲/۳۱',
        gregorianLocalizations,
      );
      final DateTime? arabicIndic = persianDelegate.parseCompactDate(
        '١٤٠٣/٠٢/٣١',
        gregorianLocalizations,
      );
      final DateTime? englishWithPersianDigits =
          englishDelegate.parseCompactDate(
        '۳۱/۰۲/۱۴۰۳',
        gregorianLocalizations,
      );

      for (final DateTime? parsed in <DateTime?>[
        latin,
        persian,
        arabicIndic,
        englishWithPersianDigits,
      ]) {
        expect(parsed, isA<PersianDateTime>());
        expect((parsed?.year, parsed?.month, parsed?.day), (1403, 2, 31));
      }
    });

    test('round-trips valid compact dates in both presentations', () {
      final PersianDateTime date = PersianDateTime(1403, 2, 31);

      for (final PersianCalendarDelegate delegate in <PersianCalendarDelegate>[
        englishDelegate,
        persianDelegate
      ]) {
        final String formatted =
            delegate.formatCompactDate(date, gregorianLocalizations);
        final DateTime? parsed =
            delegate.parseCompactDate(formatted, gregorianLocalizations);

        expect(parsed, isA<PersianDateTime>());
        expect((parsed?.year, parsed?.month, parsed?.day), (1403, 2, 31));
      }
    });

    test('rejects malformed, invalid, and presentation-mismatched dates', () {
      final int invalidEsfandDay = PersianDateTime.daysInMonth(1402, 12) + 1;
      for (final String? input in <String?>[
        null,
        '',
        '31/02',
        '31-02-1403',
        'not/a/date',
        '00/02/1403',
        '32/02/1403',
        '01/13/1403',
        '$invalidEsfandDay/12/1402',
        '1403/02/31',
      ]) {
        expect(
          englishDelegate.parseCompactDate(input, gregorianLocalizations),
          isNull,
          reason: 'Expected "$input" to be rejected.',
        );
      }

      expect(
        persianDelegate.parseCompactDate(
          '31/02/1403',
          gregorianLocalizations,
        ),
        isNull,
      );
    });

    test('accepts exact supported boundaries and rejects adjacent years', () {
      final int minimumYear = PersianDateTime.minimumYear;
      final int maximumYear = PersianDateTime.maximumYear;
      final int lastDay = PersianDateTime.daysInMonth(maximumYear, 12);

      expect(
        englishDelegate.parseCompactDate(
          '01/01/$minimumYear',
          gregorianLocalizations,
        ),
        isA<PersianDateTime>(),
      );
      expect(
        englishDelegate.parseCompactDate(
          '$lastDay/12/$maximumYear',
          gregorianLocalizations,
        ),
        isA<PersianDateTime>(),
      );
      expect(
        englishDelegate.parseCompactDate(
          '01/01/${minimumYear - 1}',
          gregorianLocalizations,
        ),
        isNull,
      );
      expect(
        englishDelegate.parseCompactDate(
          '01/01/${maximumYear + 1}',
          gregorianLocalizations,
        ),
        isNull,
      );
    });
  });

  group('PersianCalendarDelegate calendar operations', () {
    test('uses official month lengths', () {
      expect(englishDelegate.getDaysInMonth(1403, 1), 31);
      expect(englishDelegate.getDaysInMonth(1403, 7), 30);
      expect(
        englishDelegate.getDaysInMonth(1403, 12),
        PersianDateTime.daysInMonth(1403, 12),
      );
    });

    test('navigates across ordinary year boundaries', () {
      final DateTime nextMonth = englishDelegate.addMonthsToMonthDate(
        PersianDateTime(1403, 12, 1),
        1,
      );
      final DateTime nextDay = englishDelegate.addDaysToDate(
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

    test('throws when navigation leaves the official range', () {
      final int minimumYear = PersianDateTime.minimumYear;
      final int maximumYear = PersianDateTime.maximumYear;
      final int lastDay = PersianDateTime.daysInMonth(maximumYear, 12);

      expect(
        () => englishDelegate.addMonthsToMonthDate(
          PersianDateTime(minimumYear, 1, 1),
          -1,
        ),
        throwsRangeError,
      );
      expect(
        () => englishDelegate.addDaysToDate(
          PersianDateTime(maximumYear, 12, lastDay),
          1,
        ),
        throwsRangeError,
      );
    });

    test('aligns offsets with ambient week headers', () {
      expect(
        englishDelegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(0),
        ),
        3,
      );
      expect(
        englishDelegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(1),
        ),
        2,
      );
      expect(
        englishDelegate.firstDayOffset(
          1403,
          1,
          const _FirstDayMaterialLocalizations(6),
        ),
        4,
      );
    });
  });

  group('legacy Persian Material localizations', () {
    const DefaultPersianCalendarMaterialLocalizations localizations =
        DefaultPersianCalendarMaterialLocalizations();

    test('validates dates against the official supported range', () {
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

  testWidgets('CalendarDatePicker needs no replacement localization',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: PersianDateTime(1403, 1, 1),
            firstDate: PersianDateTime(1402, 1, 1),
            lastDate: PersianDateTime(1404, 12, 29),
            currentDate: PersianDateTime(1403, 1, 1),
            onDateChanged: (_) {},
            calendarDelegate: englishDelegate,
          ),
        ),
      ),
    );

    expect(find.text('Farvardin 1403'), findsOneWidget);
    expect(find.text('January 1403'), findsNothing);
  });

  testWidgets('Persian presentation renders its own month header',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: PersianDateTime(1403, 1, 1),
            firstDate: PersianDateTime(1402, 1, 1),
            lastDate: PersianDateTime(1404, 12, 29),
            currentDate: PersianDateTime(1403, 1, 1),
            onDateChanged: (_) {},
            calendarDelegate: persianDelegate,
          ),
        ),
      ),
    );

    expect(find.text('فروردین ۱۴۰۳'), findsOneWidget);
  });

  testWidgets('input picker round-trips a date Gregorian parsing rejects',
      (WidgetTester tester) async {
    DateTime? submittedDate;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputDatePickerFormField(
            initialDate: PersianDateTime(1403, 2, 31),
            firstDate: PersianDateTime(1403, 1, 1),
            lastDate: PersianDateTime(1403, 12, 30),
            onDateSubmitted: (DateTime date) => submittedDate = date,
            calendarDelegate: englishDelegate,
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
    expect(
      (submittedDate?.year, submittedDate?.month, submittedDate?.day),
      (1403, 2, 31),
    );
  });
}

class _FirstDayMaterialLocalizations extends DefaultMaterialLocalizations {
  const _FirstDayMaterialLocalizations(this.firstDay);

  final int firstDay;

  @override
  int get firstDayOfWeekIndex => firstDay;
}
