import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:timezone/data/latest.dart' as data;

import 'calendar_controller.dart';
import 'calendar_screen.dart';
import 'timezone_revision.dart';

void main() {
  data.initializeTimeZones();
  runApp(const CalendarDemo());
}

class CalendarDemo extends StatefulWidget {
  const CalendarDemo({super.key});
  @override
  State<CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<CalendarDemo> {
  final zones = IanaTimeZoneProvider(databaseRevision: bundledTimeZoneRevision);
  late final CalendarController controller;
  late final MemoryEventSource source;
  bool persianLanguage = false;
  @override
  void initState() {
    super.initState();
    final today =
        zones.dateAt(DateTime.now(), 'Asia/Tehran', CalendarId.persian);
    final start = zones.resolve(today, WallClock(9), 'Asia/Tehran')!;
    source = MemoryEventSource([
      CalendarEvent.timed(
          id: 'planning',
          title: 'Planning',
          start: start,
          end: start.add(const Duration(hours: 2))),
      CalendarEvent.timed(
          id: 'review',
          title: 'Review',
          start: start.add(const Duration(minutes: 30)),
          end: start.add(const Duration(minutes: 90))),
      CalendarEvent.allDay(
          id: 'all-day',
          title: 'Team day',
          dates: CalendarDateRange(today, today.addDays(1))),
    ]);
    controller =
        CalendarController(selectedDate: today, source: source, zones: zones);
  }

  Future<void> move(CalendarEvent event, CalendarDate date) async {
    final CalendarEvent replacement;
    if (event.allDay != null) {
      replacement = CalendarEvent.allDay(
          id: event.id,
          title: event.title,
          dates: CalendarDateRange(date, date.addDays(event.allDay!.dayCount)));
    } else {
      final clock = zones.timeAt(event.start!, controller.zone);
      // Moving to a gap/fold requires a user policy; default rejection is shown.
      final start = zones.resolve(date, clock, controller.zone)!;
      replacement = CalendarEvent.timed(
          id: event.id,
          title: event.title,
          start: start,
          end: start.add(event.end!.difference(event.start!)));
    }
    source.events[source.events.indexWhere((value) => value.id == event.id)] =
        replacement;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: Locale(persianLanguage ? 'fa' : 'en'),
        supportedLocales: const [Locale('en'), Locale('fa')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            fontFamilyFallback: const ['NotoSansArabic']),
        home: Builder(
            builder: (context) => Stack(children: [
                  CalendarScreen(
                      controller: controller,
                      locale: persianLanguage ? 'fa' : 'en',
                      onReschedule: move,
                      today: () => zones.dateAt(DateTime.now(), controller.zone,
                          controller.calendar)),
                  PositionedDirectional(
                      top: MediaQuery.paddingOf(context).top,
                      end: 12,
                      child: TextButton(
                          onPressed: () => setState(
                              () => persianLanguage = !persianLanguage),
                          child: Text(persianLanguage ? 'English' : 'فارسی'))),
                ])),
      );
}

class MemoryEventSource implements CalendarEventSource {
  MemoryEventSource(this.events);
  final List<CalendarEvent> events;
  @override
  Future<List<CalendarEvent>> load(EventQuery query) async => events
      .where((event) => event.allDay != null
          ? event.allDay!.start.compareTo(query.dates.end) < 0 &&
              event.allDay!.end.compareTo(query.dates.start) > 0
          : event.start!.isBefore(query.end) && event.end!.isAfter(query.start))
      .toList();
}
