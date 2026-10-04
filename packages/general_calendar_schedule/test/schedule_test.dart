import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as data;

CalendarDate g(int y, int m, int d) =>
    CalendarDate(calendar: CalendarId.gregory, year: y, month: m, day: d);
void main() {
  data.initializeTimeZones();
  final provider = IanaTimeZoneProvider(databaseRevision: 'test-bundled-data');
  test('New York gap rejects, skips or advances to the next valid minute', () {
    final date = g(2024, 3, 10);
    expect(() => provider.resolve(date, WallClock(2, 30), 'America/New_York'),
        throwsArgumentError);
    expect(
        provider.resolve(date, WallClock(2, 30), 'America/New_York',
            missing: MissingTimePolicy.skip),
        isNull);
    expect(
        provider.resolve(date, WallClock(2, 30), 'America/New_York',
            missing: MissingTimePolicy.nextValidMinute),
        DateTime.utc(2024, 3, 10, 7));
  });
  test('fold resolution uses independent UTC instants and retains fractions',
      () {
    final date = g(2024, 11, 3), clock = WallClock(1, 30, 0, 123, 456);
    expect(() => provider.resolve(date, clock, 'America/New_York'),
        throwsArgumentError);
    expect(
        provider.resolve(date, clock, 'America/New_York',
            repeated: RepeatedTimePolicy.earlier),
        DateTime.utc(2024, 11, 3, 5, 30, 0, 123, 456));
    expect(
        provider.resolve(date, clock, 'America/New_York',
            repeated: RepeatedTimePolicy.later),
        DateTime.utc(2024, 11, 3, 6, 30, 0, 123, 456));
  });
  test('daily 09:00 recurrence crosses DST with 23 elapsed hours', () {
    final rule = CalendarSchedule(
        startDate: g(2024, 3, 9),
        time: WallClock(9),
        zone: 'America/New_York',
        duration: const Duration(hours: 1),
        frequency: RecurrenceFrequency.daily,
        count: 3);
    final occurrences = rule.expand(
        provider, DateTime.utc(2024, 3, 9), DateTime.utc(2024, 3, 12));
    expect(occurrences.map((event) => event.start), [
      DateTime.utc(2024, 3, 9, 14),
      DateTime.utc(2024, 3, 10, 13),
      DateTime.utc(2024, 3, 11, 13)
    ]);
    expect(occurrences[1].start.difference(occurrences[0].start),
        const Duration(hours: 23));
    expect(
        () => rule.expand(provider, DateTime.utc(2024), DateTime.utc(2025),
            maxCandidates: 1),
        throwsStateError);
    expect(
        rule
            .expand(
                provider, DateTime.utc(2024, 3, 9), DateTime.utc(2024, 3, 12),
                maxCandidates: 3)
            .length,
        3);
  });
  test('monthly anchor retains day 31 and moved exceptions are found', () {
    final start = g(2024, 1, 31);
    final rule = CalendarSchedule(
        startDate: start,
        time: WallClock(9),
        zone: 'UTC',
        duration: const Duration(hours: 1),
        frequency: RecurrenceFrequency.monthly,
        count: 3,
        overrides: {g(2024, 3, 31): DateTime.utc(2024, 1, 15, 12)});
    final occurrences =
        rule.expand(provider, DateTime.utc(2024), DateTime.utc(2024, 4));
    expect(occurrences.map((event) => event.start), [
      DateTime.utc(2024, 1, 15, 12),
      DateTime.utc(2024, 1, 31, 9),
      DateTime.utc(2024, 2, 29, 9)
    ]);
    final early = rule.expand(
        provider, DateTime.utc(2024, 1, 15), DateTime.utc(2024, 1, 16));
    expect(early.single.date, g(2024, 3, 31));
    final skipped = CalendarSchedule(
        startDate: start,
        time: WallClock(9),
        zone: 'UTC',
        duration: const Duration(hours: 1),
        frequency: RecurrenceFrequency.monthly,
        count: 3,
        datePolicy: RecurrenceDatePolicy.skip);
    expect(
        skipped
            .expand(provider, DateTime.utc(2024), DateTime.utc(2024, 4))
            .map((event) => event.date),
        [start, g(2024, 3, 31)]);
  });
  test('Persian and Hijri wall dates project into the selected zone', () {
    for (final date in [
      CalendarDate(calendar: CalendarId.persian, year: 1403, month: 1, day: 1),
      CalendarDate(
          calendar: CalendarId.islamicUmalqura, year: 1445, month: 9, day: 10)
    ]) {
      expect(provider.resolve(date, WallClock(9), 'Asia/Tehran'),
          DateTime.utc(2024, 3, 20, 5, 30));
      expect(
          provider.dateAt(
              DateTime.utc(2024, 3, 19, 22), 'Asia/Tehran', date.calendar),
          date);
    }
  });
  test('business holidays and half-open conflicts are explicit', () {
    final policy = BusinessDayPolicy(holidays: [g(2024, 3, 18)]);
    expect(policy.nextBusinessDay(g(2024, 3, 15)), g(2024, 3, 19));
    ScheduleOccurrence occurrence(int hour) => ScheduleOccurrence(
        date: g(2024, 3, 20),
        start: DateTime.utc(2024, 3, 20, hour),
        duration: const Duration(hours: 1),
        zone: 'UTC',
        zoneRevision: provider.databaseRevision);
    expect(occurrence(9).overlaps(occurrence(10)), isFalse);
    expect(occurrence(9).overlaps(occurrence(9)), isTrue);
  });
}
