import 'dart:async';

import 'package:calendar_demo/calendar_controller.dart';
import 'package:calendar_demo/calendar_screen.dart';
import 'package:calendar_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:intl/date_symbol_data_local.dart' as intl_data;
import 'package:timezone/data/latest.dart' as data;

CalendarDate g(int y, int m, int d) =>
    CalendarDate(calendar: CalendarId.gregory, year: y, month: m, day: d);
final zones = IanaTimeZoneProvider(databaseRevision: 'fixture');

class PendingSource implements CalendarEventSource {
  final pending = <Completer<List<CalendarEvent>>>[];
  @override
  Future<List<CalendarEvent>> load(EventQuery query) {
    final completer = Completer<List<CalendarEvent>>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  setUpAll(data.initializeTimeZones);
  // Standalone CalendarScreen tests choose bundled intl locale initialization.
  // The full demo app initializes intl through Flutter's Material delegate.
  setUpAll(intl_data.initializeDateFormatting);
  test('new query wins even when old results arrive later; errors recover',
      () async {
    final source = PendingSource();
    final controller = CalendarController(
        selectedDate: g(2024, 3, 20),
        source: source,
        zones: zones,
        zone: 'UTC');
    final first = controller.reload();
    controller.navigate(1);
    source.pending[1].complete([]);
    await Future<void>.delayed(Duration.zero);
    source.pending[0].completeError(StateError('old failure'));
    await first;
    expect(controller.selectedDate.month, 4);
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
    final failed = controller.reload();
    source.pending[2].completeError(StateError('new failure'));
    await failed;
    expect(controller.error, isA<StateError>());
    final recovered = controller.reload();
    source.pending[3].complete([]);
    await recovered;
    expect(controller.error, isNull);
    controller.dispose();
  });
  test('events split across midnight and deterministic overlap columns',
      () async {
    CalendarEvent event(String id, int hour, int minutes, int length) =>
        CalendarEvent.timed(
            id: id,
            title: id,
            start: DateTime.utc(2024, 3, 20, hour, minutes),
            end: DateTime.utc(2024, 3, 20, hour, minutes + length));
    final controller = CalendarController(
        selectedDate: g(2024, 3, 20),
        zones: zones,
        zone: 'UTC',
        source: MemoryEventSource([
          event('a', 9, 0, 120),
          event('b', 9, 30, 30),
          event('c', 10, 0, 30),
          event('overnight', 23, 0, 120)
        ]));
    await controller.reload();
    final layout = layoutDay(controller, g(2024, 3, 20));
    expect(layout.map((value) => (value.column, value.columns)),
        [(0, 2), (1, 2), (1, 2), (0, 1)]);
    expect(layout.last.end, DateTime.utc(2024, 3, 21));
    expect(layoutDay(controller, g(2024, 3, 21)).single.start,
        DateTime.utc(2024, 3, 21));
    controller.dispose();
  });
  test('DST timelines expose 23 and 25 hours and skipped civil days', () {
    final controller = CalendarController(
        selectedDate: g(2024, 3, 10),
        zones: zones,
        zone: 'America/New_York',
        source: MemoryEventSource([]));
    final spring = controller.dayBounds(g(2024, 3, 10));
    final autumn = controller.dayBounds(g(2024, 11, 3));
    expect(spring.end.difference(spring.start).inHours, 23);
    expect(autumn.end.difference(autumn.start).inHours, 25);
    controller.setZone('Pacific/Apia');
    final skipped = controller.dayBounds(g(2011, 12, 30));
    expect(skipped.end, skipped.start);
    controller.dispose();
  });
  test('minimum touch targets allocate visual overlap columns for short events',
      () async {
    final events = [
      for (var i = 0; i < 2; i++)
        CalendarEvent.timed(
            id: '$i',
            title: '$i',
            start: DateTime.utc(2024, 3, 20, 9, i * 5),
            end: DateTime.utc(2024, 3, 20, 9, (i + 1) * 5))
    ];
    final controller = CalendarController(
        selectedDate: g(2024, 3, 20),
        zones: zones,
        zone: 'UTC',
        source: MemoryEventSource(events));
    await controller.reload();
    expect(layoutDay(controller, g(2024, 3, 20)).map((event) => event.columns),
        [1, 1]);
    expect(
        layoutDay(controller, g(2024, 3, 20), minimumVisualMinutes: 48)
            .map((event) => (event.column, event.columns)),
        [(0, 2), (1, 2)]);
    controller.dispose();
  });
  for (final rtl in [false, true]) {
    testWidgets(
        'month keyboard, semantics and large text at narrow width RTL=$rtl',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = CalendarController(
          selectedDate: g(2024, 3, 20),
          zones: zones,
          zone: 'UTC',
          source: MemoryEventSource([]));
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
          home: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: CalendarScreen(
                      controller: controller, today: () => g(2024, 3, 20))))));
      await tester.pumpAndSettle();
      final day = find.byKey(ValueKey('day-${g(2024, 3, 20).dayIndex}'));
      await tester.ensureVisible(day);
      final button = tester.widget<TextButton>(day);
      button.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(controller.selectedDate, g(2024, 3, rtl ? 19 : 21));
      expect(find.bySemanticsLabel(RegExp('.*events')), findsWidgets);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
  testWidgets(
      'all four views render events and selection offers keyboard rescheduling',
      (tester) async {
    final date = g(2024, 3, 20);
    final event = CalendarEvent.timed(
        id: 'fixture',
        title: 'Fixture meeting',
        start: DateTime.utc(2024, 3, 20, 9),
        end: DateTime.utc(2024, 3, 20, 10));
    final controller = CalendarController(
        selectedDate: date,
        zones: zones,
        zone: 'UTC',
        source: MemoryEventSource([event]));
    addTearDown(controller.dispose);
    CalendarDate? moved;
    await tester.pumpWidget(MaterialApp(
        home: CalendarScreen(
            controller: controller,
            today: () => date,
            onReschedule: (_, next) async {
              moved = next;
            })));
    await tester.pumpAndSettle();
    for (final view in CalendarView.values) {
      controller.setView(view);
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('event-fixture'));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('event-fixture')));
    await tester.pumpAndSettle();
    expect(controller.selectedEventId, 'fixture');
    await tester.tap(find.text('Move to next day'));
    await tester.pumpAndSettle();
    expect(moved, date.addDays(1));
    expect(tester.takeException(), isNull);
  });
}
