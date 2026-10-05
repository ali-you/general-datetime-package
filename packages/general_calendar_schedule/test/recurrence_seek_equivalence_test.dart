import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as data;

void main() {
  data.initializeTimeZones();
  final zones = IanaTimeZoneProvider(databaseRevision: 'fixture');
  final starts = [
    CalendarDate(calendar: CalendarId.gregory, year: 2020, month: 1, day: 31),
    CalendarDate(calendar: CalendarId.persian, year: -40, month: 6, day: 31),
    CalendarDate(
        calendar: CalendarId.islamicUmalqura, year: 1445, month: 9, day: 30),
  ];
  for (final start in starts) {
    for (final frequency in RecurrenceFrequency.values) {
      test('${start.calendar} $frequency seeking matches bounded expansion',
          () {
        for (final datePolicy in [
          RecurrenceDatePolicy.clamp,
          RecurrenceDatePolicy.skip,
          RecurrenceDatePolicy.overflow
        ]) {
          for (final interval in [1, 3]) {
            const count = 32;
            final dates = <CalendarDate>[];
            // This oracle enumerates the whole bounded rule, using only the
            // civil calendar API. Query seeking and provider bounds are absent.
            for (var index = 0; index < count; index++) {
              final step = index * interval;
              final policy = switch (datePolicy) {
                RecurrenceDatePolicy.clamp => CalendarOverflow.clamp,
                RecurrenceDatePolicy.overflow => CalendarOverflow.overflow,
                _ => CalendarOverflow.reject,
              };
              try {
                dates.add(switch (frequency) {
                  RecurrenceFrequency.daily => start.addDays(step),
                  RecurrenceFrequency.weekly => start.addDays(step * 7),
                  RecurrenceFrequency.monthly =>
                    start.addMonths(step, policy: policy),
                  RecurrenceFrequency.yearly =>
                    start.addYears(step, policy: policy),
                });
              } on ArgumentError {
                if (datePolicy != RecurrenceDatePolicy.skip) rethrow;
              }
            }
            final instants = dates
                .map((date) => date.gregorianDay
                    .add(const Duration(hours: 9, microseconds: 123456)))
                .toList();
            for (final duration in [
              const Duration(hours: 1),
              const Duration(days: 36)
            ]) {
              final schedule = CalendarSchedule(
                  startDate: start,
                  frequency: frequency,
                  interval: interval,
                  count: count,
                  datePolicy: datePolicy,
                  time: WallClock(9, 0, 0, 123, 456),
                  zone: 'UTC',
                  duration: duration);
              for (final instant in [
                instants.first,
                instants[instants.length ~/ 2],
                instants.last
              ]) {
                for (final from in [
                  instant.subtract(const Duration(hours: 6)),
                  instant,
                  instant.add(duration)
                ]) {
                  final until = from.add(const Duration(hours: 12));
                  final expected = <CalendarDate>[
                    for (var i = 0; i < dates.length; i++)
                      if (instants[i].isBefore(until) &&
                          instants[i].add(duration).isAfter(from))
                        dates[i],
                  ];
                  final actual = schedule.expand(zones, from, until);
                  expect(actual.map((event) => event.date), expected,
                      reason:
                          '$datePolicy interval=$interval duration=$duration '
                          'from=$from until=$until');
                  expect(actual.map((event) => event.start), [
                    for (var i = 0; i < dates.length; i++)
                      if (instants[i].isBefore(until) &&
                          instants[i].add(duration).isAfter(from))
                        instants[i],
                  ]);
                }
              }
            }
          }
        }
      });
    }
  }
}
