import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const HijriCalendarDelegate delegate = HijriCalendarDelegate();
  const DefaultMaterialLocalizations gregorianLocalizations =
      DefaultMaterialLocalizations();
  const DefaultPersianCalendarMaterialLocalizations persianLocalizations =
      DefaultPersianCalendarMaterialLocalizations();

  group('HijriCalendarDelegate formatting', () {
    final HijriDateTime date = HijriDateTime(1446, 9, 1);

    test('uses Hijri names independently of ambient localizations', () {
      const List<String> shortWeekdays = <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      const List<String> weekdays = <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      for (final MaterialLocalizations localizations in <MaterialLocalizations>[
        gregorianLocalizations,
        persianLocalizations,
      ]) {
        expect(
          delegate.formatMonthYear(date, localizations),
          'Ramadan 1446',
        );
        expect(delegate.formatYear(date.year, localizations), '1446');
        expect(
          delegate.formatMediumDate(date, localizations),
          '${shortWeekdays[date.weekday - 1]}, Ram 1',
        );
        expect(delegate.formatShortMonthDay(date, localizations), 'Ram 1');
        expect(delegate.formatShortDate(date, localizations), 'Ram 1, 1446');
        expect(
          delegate.formatFullDate(date, localizations),
          '${weekdays[date.weekday - 1]}, Ramadan 1, 1446',
        );
        expect(delegate.formatCompactDate(date, localizations), '01/09/1446');
        expect(delegate.dateHelpText(localizations), 'dd/mm/yyyy');
      }
    });
  });

  group('HijriCalendarDelegate parsing', () {
    test('returns HijriDateTime independently of ambient parser', () {
      for (final MaterialLocalizations localizations in <MaterialLocalizations>[
        gregorianLocalizations,
        persianLocalizations,
      ]) {
        final DateTime? parsed =
            delegate.parseCompactDate(' 01 / 09 / 1446 ', localizations);

        expect(parsed, isA<HijriDateTime>());
        expect(parsed?.year, 1446);
        expect(parsed?.month, 9);
        expect(parsed?.day, 1);
      }
    });

    test('round-trips compact dates', () {
      final HijriDateTime date = HijriDateTime(1446, 9, 1);
      final String formatted =
          delegate.formatCompactDate(date, gregorianLocalizations);

      final DateTime? parsed =
          delegate.parseCompactDate(formatted, gregorianLocalizations);

      expect(parsed, isA<HijriDateTime>());
      expect(parsed?.year, date.year);
      expect(parsed?.month, date.month);
      expect(parsed?.day, date.day);
    });

    test('rejects malformed and out-of-range dates', () {
      for (final String? input in <String?>[
        null,
        '',
        '01/09',
        '01-09-1446',
        'not/a/date',
        '00/09/1446',
        '31/09/1446',
        '01/13/1446',
        '01/01/0000',
      ]) {
        expect(
          delegate.parseCompactDate(input, gregorianLocalizations),
          isNull,
          reason: 'Expected "$input" to be rejected.',
        );
      }
    });
  });

  test('legacy Hijri localization uses official Umm al-Qura month lengths', () {
    final DateTime? thirtyDayMonth =
        const DefaultHijriCalendarMaterialLocalizations().parseCompactDate(
      '30/02/1446',
    );

    expect(thirtyDayMonth, isA<HijriDateTime>());
    expect(thirtyDayMonth?.day, 30);
    expect(
      const DefaultHijriCalendarMaterialLocalizations().parseCompactDate(
        '30/01/1446',
      ),
      isNull,
    );
    expect(
      const DefaultHijriCalendarMaterialLocalizations().parseCompactDate(
        '01/01/1299',
      ),
      isNull,
    );
  });

  testWidgets(
      'CalendarDatePicker shows Hijri header with Persian localizations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          DefaultPersianCalendarMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: HijriDateTime(1446, 9, 1),
            firstDate: HijriDateTime(1446, 1, 1),
            lastDate: HijriDateTime(1446, 12, 29),
            onDateChanged: (_) {},
            calendarDelegate: delegate,
          ),
        ),
      ),
    );

    expect(find.text('Ramadan 1446'), findsOneWidget);
  });
}
