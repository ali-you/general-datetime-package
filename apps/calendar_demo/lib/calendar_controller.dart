import 'package:flutter/foundation.dart';
import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';

enum CalendarView { month, week, day, agenda }

final class CalendarEvent {
  CalendarEvent.timed(
      {required this.id,
      required this.title,
      required DateTime start,
      required DateTime end})
      : start = DateTime.fromMicrosecondsSinceEpoch(
            start.microsecondsSinceEpoch,
            isUtc: true),
        end = DateTime.fromMicrosecondsSinceEpoch(end.microsecondsSinceEpoch,
            isUtc: true),
        allDay = null {
    if (!start.isBefore(end)) {
      throw ArgumentError('Event end must follow start');
    }
  }
  CalendarEvent.allDay(
      {required this.id, required this.title, required CalendarDateRange dates})
      : allDay = dates,
        start = null,
        end = null {
    if (dates.dayCount == 0) {
      throw ArgumentError('All-day event range is empty');
    }
  }
  final String id, title;
  final DateTime? start, end;
  final CalendarDateRange? allDay;
}

final class EventQuery {
  const EventQuery(this.dates, this.start, this.end, this.zone);
  final CalendarDateRange dates;
  final DateTime start, end;
  final String zone;
}

abstract interface class CalendarEventSource {
  Future<List<CalendarEvent>> load(EventQuery query);
}

/// Application state owns selection, query lifecycle and event data. Locale
/// changes only presentation. Old asynchronous results cannot replace new ones.
final class CalendarController extends ChangeNotifier {
  CalendarController(
      {required this.selectedDate,
      required this.source,
      required this.zones,
      this.zone = 'Asia/Tehran',
      this.view = CalendarView.month,
      this.weekRules = const CalendarWeekRules()});
  final CalendarEventSource source;
  final TimeZoneProvider zones;
  final CalendarWeekRules weekRules;
  CalendarDate selectedDate;
  String zone;
  CalendarView view;
  List<CalendarEvent> events = const [];
  String? selectedEventId;
  Object? error;
  bool loading = false, _disposed = false;
  int _generation = 0;
  CalendarId get calendar => selectedDate.calendar;
  List<CalendarDate> get visibleDates {
    var first = selectedDate;
    var length = 1;
    if (view == CalendarView.month) {
      first = selectedDate.system
              .isValidDate(selectedDate.year, selectedDate.month, 1)
          ? CalendarDate(
              calendar: calendar,
              year: selectedDate.year,
              month: selectedDate.month,
              day: 1)
          : selectedDate;
      final preceding = (first.weekday - weekRules.firstWeekday) % 7;
      try {
        first = first.addDays(-preceding);
      } on RangeError {/* Clip at the supported endpoint. */}
      length = 42;
    } else if (view == CalendarView.week) {
      try {
        first = weekRules.startOfWeek(selectedDate);
      } on RangeError {/* Clip at the supported endpoint. */}
      length = 7;
    } else if (view == CalendarView.agenda) {
      length = 30;
    }
    final result = <CalendarDate>[];
    for (var i = 0; i < length; i++) {
      try {
        result.add(first.addDays(i));
      } on RangeError {
        break;
      }
    }
    return List.unmodifiable(result);
  }

  ({DateTime start, DateTime end}) dayBounds(CalendarDate date) {
    final gregorian = date.toCalendar(CalendarId.gregory);
    final start = zones.resolve(gregorian, WallClock(0), zone,
        missing: MissingTimePolicy.nextValidMinute,
        repeated: RepeatedTimePolicy.earlier)!;
    final end = zones.resolve(gregorian.addDays(1), WallClock(0), zone,
        missing: MissingTimePolicy.nextValidMinute,
        repeated: RepeatedTimePolicy.earlier)!;
    return (start: start, end: end);
  }

  EventQuery get query {
    final dates = visibleDates;
    final endDate = dates.last.toCalendar(CalendarId.gregory).addDays(1);
    return EventQuery(CalendarDateRange(dates.first, endDate),
        dayBounds(dates.first).start, dayBounds(dates.last).end, zone);
  }

  Future<void> reload() async {
    final generation = ++_generation;
    loading = true;
    events = const [];
    error = null;
    notifyListeners();
    try {
      final result = await source.load(query);
      if (_disposed || generation != _generation) return;
      if (result.map((event) => event.id).toSet().length != result.length) {
        throw StateError('Event source returned duplicate IDs');
      }
      events = List.unmodifiable(result);
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      events = const [];
      error = failure;
    }
    if (_disposed || generation != _generation) return;
    loading = false;
    notifyListeners();
  }

  void selectDate(CalendarDate date) {
    final previous = query;
    selectedDate = date.toCalendar(calendar);
    final next = query;
    notifyListeners();
    if (previous.start != next.start || previous.end != next.end) reload();
  }

  void selectEvent(CalendarEvent event) {
    selectedEventId = event.id;
    notifyListeners();
  }

  void setView(CalendarView value) {
    view = value;
    reload();
  }

  void setCalendar(CalendarId value) {
    selectedDate = selectedDate.toCalendar(value);
    reload();
  }

  void setZone(String value) {
    // Validate zone resolution before mutating controller state.
    zones.resolve(selectedDate, WallClock(12), value);
    zone = value;
    reload();
  }

  CalendarDate _navigationTarget(int direction) => view == CalendarView.month
      ? selectedDate.addMonths(direction)
      : selectedDate.addDays(direction *
          (view == CalendarView.week
              ? 7
              : view == CalendarView.agenda
                  ? 30
                  : 1));
  bool canNavigate(int direction) {
    try {
      _navigationTarget(direction);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  void navigate(int direction) => selectDate(_navigationTarget(direction));
  List<CalendarEvent> eventsOn(CalendarDate date) {
    final bounds = dayBounds(date);
    return events
        .where((event) => event.allDay != null
            ? event.allDay!.contains(date)
            : bounds.start.isBefore(bounds.end) &&
                event.start!.isBefore(bounds.end) &&
                event.end!.isAfter(bounds.start))
        .toList()
      ..sort((a, b) {
        if (a.allDay != null && b.allDay == null) return -1;
        if (b.allDay != null && a.allDay == null) return 1;
        final order = a.start?.compareTo(b.start ?? a.start!) ?? 0;
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

final class EventPlacement {
  const EventPlacement(
      this.event, this.start, this.end, this.column, this.columns);
  final CalendarEvent event;
  final DateTime start, end;
  final int column, columns;
}

/// Clip into a single civil day and allocate deterministic columns per connected
/// overlap group. Touching half-open intervals can share a column.
List<EventPlacement> layoutDay(CalendarController controller, CalendarDate date,
    {int minimumVisualMinutes = 0}) {
  final bounds = controller.dayBounds(date);
  final segments = controller
      .eventsOn(date)
      .where((event) => event.start != null)
      .map((event) => (
            event: event,
            start: event.start!.isBefore(bounds.start)
                ? bounds.start
                : event.start!,
            end: event.end!.isAfter(bounds.end) ? bounds.end : event.end!
          ))
      .toList()
    ..sort((a, b) {
      final order = a.start.compareTo(b.start);
      if (order != 0) return order;
      final ending = a.end.compareTo(b.end);
      return ending == 0 ? a.event.id.compareTo(b.event.id) : ending;
    });
  final result = <EventPlacement>[];
  DateTime visualEnd(DateTime start, DateTime end) {
    final minimum = start.add(Duration(minutes: minimumVisualMinutes));
    return minimum.isAfter(end) ? minimum : end;
  }

  var index = 0;
  while (index < segments.length) {
    final group = [segments[index++]];
    var end = visualEnd(group.first.start, group.first.end);
    while (index < segments.length && segments[index].start.isBefore(end)) {
      final segment = segments[index++];
      group.add(segment);
      final occupiedEnd = visualEnd(segment.start, segment.end);
      if (occupiedEnd.isAfter(end)) end = occupiedEnd;
    }
    final columnEnds = <DateTime>[];
    final assigned = <int>[];
    for (final segment in group) {
      var column = columnEnds.indexWhere((end) => !end.isAfter(segment.start));
      if (column < 0) {
        column = columnEnds.length;
        columnEnds.add(visualEnd(segment.start, segment.end));
      } else {
        columnEnds[column] = visualEnd(segment.start, segment.end);
      }
      assigned.add(column);
    }
    for (var i = 0; i < group.length; i++) {
      result.add(EventPlacement(group[i].event, group[i].start, group[i].end,
          assigned[i], columnEnds.length));
    }
  }
  return List.unmodifiable(result);
}
