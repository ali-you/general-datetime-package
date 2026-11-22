import 'package:calendar_demo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:timezone/data/latest.dart' as data;

void main() {
  setUpAll(data.initializeTimeZones);
  testWidgets('Chinese selection renders in English and Persian',
      (tester) async {
    await tester.pumpWidget(const app.CalendarDemo());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<CalendarId>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chinese').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Chinese'), findsOneWidget);
  });
  testWidgets('demo boots and switches presentation language', (tester) async {
    await tester.pumpWidget(const app.CalendarDemo());
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
