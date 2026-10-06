import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:general_date_format_core/general_date_format_core.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:intl/intl.dart' as intl;

import 'calendar_controller.dart';

typedef RescheduleEvent = Future<void> Function(
    CalendarEvent event, CalendarDate date);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen(
      {super.key,
      required this.controller,
      this.locale = 'en',
      this.onReschedule,
      required this.today});
  final CalendarController controller;
  final String locale;
  final CalendarDate Function() today;
  final RescheduleEvent? onReschedule;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _focus = <CalendarDate, FocusNode>{};
  CalendarController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    controller.reload();
  }

  @override
  void dispose() {
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  String _dateText(CalendarDate date, [String pattern = 'y/M/d']) {
    final value = date.system.construct(date.year, date.month, date.day);
    if (date.calendar == CalendarId.gregory) {
      return intl.DateFormat(pattern, widget.locale).format(value);
    }
    return GeneralDateFormat(pattern, widget.locale).format(value);
  }

  String _secondary(CalendarDate date) {
    final id = date.calendar == CalendarId.gregory
        ? CalendarId.persian
        : CalendarId.gregory;
    try {
      return _dateText(date.toCalendar(id));
    } on ArgumentError {
      return 'Outside secondary calendar range';
    }
  }

  String _time(DateTime instant) {
    final clock = controller.zones.timeAt(instant, controller.zone);
    return '${clock.hour.toString().padLeft(2, '0')}:${clock.minute.toString().padLeft(2, '0')}';
  }

  void _action(VoidCallback callback) {
    try {
      callback();
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _focusDate(CalendarDate date) {
    _action(() => controller.selectDate(date));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus[controller.selectedDate]?.requestFocus();
    });
  }

  KeyEventResult _key(CalendarDate date, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    int? days;
    if (key == LogicalKeyboardKey.arrowLeft) days = rtl ? 1 : -1;
    if (key == LogicalKeyboardKey.arrowRight) days = rtl ? -1 : 1;
    if (key == LogicalKeyboardKey.arrowUp) days = -7;
    if (key == LogicalKeyboardKey.arrowDown) days = 7;
    if (days != null) {
      _action(() => _focusDate(date.addDays(days!)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      _action(
          () => controller.navigate(key == LogicalKeyboardKey.pageUp ? -1 : 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _focusDate(widget.today());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _move(CalendarEvent event, CalendarDate date) async {
    try {
      await widget.onReschedule!(event, date);
      await controller.reload();
    } catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not move event: $failure')));
      }
    }
  }

  void _openEvent(CalendarEvent event) {
    controller.selectEvent(event);
    final date = event.allDay?.start ??
        controller.zones
            .dateAt(event.start!, controller.zone, controller.calendar);
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(event.title),
              content: Text(event.allDay != null
                  ? 'All day · ${_dateText(date)}'
                  : '${_dateText(date)} · ${_time(event.start!)}–${_time(event.end!)} · ${controller.zone}'),
              actions: [
                if (widget.onReschedule != null) ...[
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _action(() => _move(event, date.addDays(-1)));
                      },
                      child: const Text('Move to previous day')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _action(() => _move(event, date.addDays(1)));
                      },
                      child: const Text('Move to next day')),
                ],
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close')),
              ],
            ));
  }

  Widget _event(CalendarEvent event, {bool compact = false}) {
    final label =
        '${event.title}, ${event.allDay != null ? 'all day' : '${_time(event.start!)} to ${_time(event.end!)} ${controller.zone}'}';
    final button = Semantics(
      label: label,
      selected: controller.selectedEventId == event.id,
      child: Tooltip(
          message: label,
          child: OutlinedButton(
            key: ValueKey('event-${event.id}'),
            onPressed: () => _openEvent(event),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: const Size(48, 48),
                backgroundColor: controller.selectedEventId == event.id
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null),
            child: Text(event.title,
                maxLines: compact ? 1 : 3, overflow: TextOverflow.ellipsis),
          )),
    );
    if (widget.onReschedule == null) return button;
    return LongPressDraggable<CalendarEvent>(
        data: event,
        feedback: Material(
            elevation: 4,
            child: Padding(
                padding: const EdgeInsets.all(12), child: Text(event.title))),
        childWhenDragging: Opacity(opacity: .4, child: button),
        child: button);
  }

  Widget _dateCell(CalendarDate date) {
    final events = controller.eventsOn(date);
    final selected = date == controller.selectedDate;
    final node =
        _focus.putIfAbsent(date, () => FocusNode(debugLabel: date.toString()));
    return DragTarget<CalendarEvent>(
      onWillAcceptWithDetails: (_) => widget.onReschedule != null,
      onAcceptWithDetails: (details) => _move(details.data, date),
      builder: (context, candidates, rejected) => DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: selected || candidates.isNotEmpty
                ? Theme.of(context).colorScheme.primaryContainer
                : null),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Focus(
              onKeyEvent: (_, event) => _key(date, event),
              child: TextButton(
                focusNode: node,
                key: ValueKey('day-${date.dayIndex}'),
                onPressed: () => controller.selectDate(date),
                child: Semantics(
                    selected: selected,
                    label:
                        '${_dateText(date, 'yMMMMEEEEd')}, ${events.length} events',
                    child: Text('${date.day}', maxLines: 1)),
              )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(_secondary(date),
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          for (final event in events.take(2)) _event(event, compact: true),
          if (events.length > 2)
            Text('+${events.length - 2} events', textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _month(double width) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final height = 205.0 * math.max(1.0, scale);
    final dates = controller.visibleDates;
    return Column(children: [
      Row(
          children: List.generate(7, (index) {
        final weekday = (controller.weekRules.firstWeekday - 1 + index) % 7 + 1;
        final fixture = CalendarDate(
            calendar: CalendarId.gregory, year: 2024, month: 1, day: weekday);
        return Expanded(
            child: Text(_dateText(fixture, width < 500 ? 'EEEEE' : 'EEE'),
                textAlign: TextAlign.center));
      })),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dates.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisExtent: height),
          itemBuilder: (_, index) => _dateCell(dates[index])),
    ]);
  }

  Widget _agenda() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final date in controller.visibleDates) ...[
          Semantics(
              header: true,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_dateText(date, 'yMMMMEEEEd')))),
          if (controller.eventsOn(date).isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('No events')),
          for (final event in controller.eventsOn(date))
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _event(event)),
        ],
      ]);
  Widget _timeline(double width) {
    final dates = controller.visibleDates;
    final columnWidth = math.max(240.0, width / dates.length);
    final minuteHeight =
        math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final date in dates)
              SizedBox(
                width: columnWidth,
                child: Column(children: [
                  TextButton(
                      onPressed: () => controller.selectDate(date),
                      child: Text(_dateText(date, 'MMMEd'))),
                  Text(_secondary(date)),
                  for (final event in controller
                      .eventsOn(date)
                      .where((event) => event.allDay != null))
                    _event(event),
                  Builder(builder: (context) {
                    final bounds = controller.dayBounds(date);
                    final minutes =
                        bounds.end.difference(bounds.start).inMinutes;
                    if (minutes == 0) {
                      return const Text('This civil day has no local instants');
                    }
                    final placements =
                        layoutDay(controller, date, minimumVisualMinutes: 48);
                    return SizedBox(
                        height: (minutes + 48) * minuteHeight,
                        child: Stack(children: [
                          for (var minute = 0; minute < minutes; minute += 60)
                            Positioned(
                                top: minute * minuteHeight,
                                left: 0,
                                right: 0,
                                child: Row(children: [
                                  SizedBox(
                                      width: 48,
                                      child: Text(
                                          _time(bounds.start
                                              .add(Duration(minutes: minute))),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall)),
                                  const Expanded(child: Divider())
                                ])),
                          for (final placement in placements)
                            PositionedDirectional(
                                top: placement.start
                                        .difference(bounds.start)
                                        .inMicroseconds /
                                    Duration.microsecondsPerMinute *
                                    minuteHeight,
                                start: 48 +
                                    (columnWidth - 48) *
                                        placement.column /
                                        placement.columns,
                                width: (columnWidth - 48) / placement.columns,
                                height: math.max(
                                    48 * minuteHeight,
                                    placement.end
                                            .difference(placement.start)
                                            .inMicroseconds /
                                        Duration.microsecondsPerMinute *
                                        minuteHeight),
                                child: _event(placement.event)),
                        ]));
                  }),
                ]),
              )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
            appBar: AppBar(title: const Text('Calendar')),
            body: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IconButton(
                                      tooltip: 'Previous period',
                                      onPressed: controller.canNavigate(-1)
                                          ? () => _action(
                                              () => controller.navigate(-1))
                                          : null,
                                      icon: const Icon(Icons.chevron_left)),
                                  Text(
                                      _dateText(
                                          controller.selectedDate, 'yMMMM'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  IconButton(
                                      tooltip: 'Next period',
                                      onPressed: controller.canNavigate(1)
                                          ? () => _action(
                                              () => controller.navigate(1))
                                          : null,
                                      icon: const Icon(Icons.chevron_right)),
                                  TextButton(
                                      onPressed: () =>
                                          _focusDate(widget.today()),
                                      child: const Text('Today')),
                                  SizedBox(
                                      width: math.min(
                                          280, constraints.maxWidth - 24),
                                      child: DropdownButton<CalendarView>(
                                          isExpanded: true,
                                          value: controller.view,
                                          items: [
                                            for (final view
                                                in CalendarView.values)
                                              DropdownMenuItem(
                                                  value: view,
                                                  child: Text(view.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis))
                                          ],
                                          onChanged: (view) =>
                                              controller.setView(view!))),
                                  SizedBox(
                                      width: math.min(
                                          280, constraints.maxWidth - 24),
                                      child: DropdownButton<CalendarId>(
                                          isExpanded: true,
                                          value: controller.calendar,
                                          items: [
                                            for (final id in CalendarId.values)
                                              DropdownMenuItem(
                                                  value: id,
                                                  child: Text(
                                                      switch (id) {
                                                        CalendarId.gregory =>
                                                          'Gregorian',
                                                        CalendarId.persian =>
                                                          'Persian',
                                                        CalendarId
                                                              .islamicUmalqura =>
                                                          'Umm al-Qura'
                                                      },
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis))
                                          ],
                                          onChanged: (id) => _action(() =>
                                              controller.setCalendar(id!)))),
                                  SizedBox(
                                      width: math.min(
                                          280, constraints.maxWidth - 24),
                                      child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: controller.zone,
                                          items: [
                                            for (final zone in {
                                              'UTC',
                                              'Asia/Tehran',
                                              'America/New_York',
                                              controller.zone
                                            })
                                              DropdownMenuItem(
                                                  value: zone,
                                                  child: Text(zone,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis))
                                          ],
                                          onChanged: (zone) => _action(() =>
                                              controller.setZone(zone!)))),
                                ])),
                        if (!controller.selectedDate.hasPublishedData &&
                            controller.calendar != CalendarId.gregory)
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                  'Calculated calendar date; outside published Persian data coverage.')),
                        if (controller.loading)
                          Semantics(
                              liveRegion: true,
                              label: 'Loading events',
                              child: LinearProgressIndicator()),
                        if (controller.error != null)
                          Semantics(
                              liveRegion: true,
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(children: [
                                    const Text('Events could not be loaded'),
                                    TextButton(
                                        onPressed: controller.reload,
                                        child: const Text('Retry')),
                                  ]))),
                        if (controller.error == null)
                          switch (controller.view) {
                            CalendarView.month => _month(constraints.maxWidth),
                            CalendarView.agenda => _agenda(),
                            _ => _timeline(constraints.maxWidth),
                          },
                      ],
                    ))),
          ));
}
