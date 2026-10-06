import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';

void main() {
  test('portable chronology, microseconds, civil math and negative epoch', () {
    final instant = DateTime.utc(2024, 3, 20, 12, 34, 56, 123, 456);
    final value = PersianDateTime.fromDateTime(instant);
    expect((value.year, value.month, value.day), (1403, 1, 1));
    expect(value.microsecondsSinceEpoch, instant.microsecondsSinceEpoch);
    expect(HijriDateTime.fromDateTime(instant).day, 10);
    expect(CalendarDate.fromDateTime(value).addDays(1).day, 2);
    expect(
        PersianDateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true)
            .secondsSinceEpoch,
        -1);
  });
  testWidgets('Persian picker renders and accepts a matching date',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          DefaultPersianCalendarMaterialLocalizations.delegate
        ],
        home: Scaffold(
            body: CalendarDatePicker(
                initialDate: PersianDateTime(1403, 1, 1),
                firstDate: PersianDateTime(1400),
                lastDate: PersianDateTime(1405),
                calendarDelegate: const PersianCalendarDelegate(),
                onDateChanged: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('Farvardin 1403'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
