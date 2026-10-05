import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as data;

CalendarDate g(int y, int m, int d) =>
    CalendarDate(calendar: CalendarId.gregory, year: y, month: m, day: d);

void main() {
  data.initializeTimeZones();
  final zones = IanaTimeZoneProvider(databaseRevision: 'fixture');
  CalendarSchedule rule(CalendarDate start,
          {RecurrenceFrequency frequency = RecurrenceFrequency.daily,
          int interval = 1,
          int? count,
          CalendarDate? lastDate,
          RecurrenceDatePolicy datePolicy = RecurrenceDatePolicy.clamp,
          WallClock? time,
          Duration duration = const Duration(hours: 1),
          String zone = 'UTC',
          MissingTimePolicy missing = MissingTimePolicy.reject,
          RepeatedTimePolicy repeated = RepeatedTimePolicy.reject,
          Set<CalendarDate> excludedDates = const {},
          Map<CalendarDate, DateTime> overrides = const {}}) =>
      CalendarSchedule(
          startDate: start,
          time: time ?? WallClock(9),
          zone: zone,
          duration: duration,
          frequency: frequency,
          interval: interval,
          count: count,
          lastDate: lastDate,
          datePolicy: datePolicy,
          missing: missing,
          repeated: repeated,
          excludedDates: excludedDates,
          overrides: overrides);

  for (final fold in [false, true]) {
    final start = fold ? g(2024, 11, 2) : g(2024, 3, 9);
    final later = fold ? DateTime.utc(2024, 11, 5) : DateTime.utc(2024, 3, 12);
    final invalidDay =
        fold ? DateTime.utc(2024, 11, 3) : DateTime.utc(2024, 3, 10);
    final schedule = rule(start,
        time: fold ? WallClock(1, 30) : WallClock(2, 30),
        zone: 'America/New_York',
        count: 5);
    test('irrelevant historical ${fold ? 'fold' : 'gap'} is not resolved', () {
      final result =
          schedule.expand(zones, later, later.add(const Duration(days: 1)));
      expect(result.single.date, fold ? g(2024, 11, 5) : g(2024, 3, 12));
    });
    test('relevant ${fold ? 'fold' : 'gap'} still rejects', () {
      expect(
          () => schedule.expand(
              zones, invalidDay, invalidDay.add(const Duration(days: 1))),
          throwsArgumentError);
    });
    test('subday query skips an earlier ${fold ? 'fold' : 'gap'}', () {
      expect(
          schedule.expand(zones, invalidDay.add(const Duration(hours: 20)),
              invalidDay.add(const Duration(hours: 21))),
          isEmpty);
    });
  }

  test('duration lookback keeps overlapping earlier occurrences', () {
    final schedule =
        rule(g(2024, 3, 9), count: 5, duration: const Duration(days: 3));
    final result = schedule.expand(
        zones, DateTime.utc(2024, 3, 12, 9), DateTime.utc(2024, 3, 12, 10));
    expect(result.map((event) => event.date),
        [g(2024, 3, 10), g(2024, 3, 11), g(2024, 3, 12)]);
    final invalid = rule(g(2024, 3, 9),
        count: 5,
        time: WallClock(2, 30),
        zone: 'America/New_York',
        duration: const Duration(days: 3));
    expect(
        () => invalid.expand(
            zones, DateTime.utc(2024, 3, 12), DateTime.utc(2024, 3, 13)),
        throwsArgumentError);
  });

  test('next-valid lookback includes a skipped civil day in Apia', () {
    final schedule = rule(g(2011, 12, 30),
        count: 1,
        time: WallClock(9),
        zone: 'Pacific/Apia',
        missing: MissingTimePolicy.nextValidMinute);
    final result = schedule.expand(
        zones, DateTime.utc(2011, 12, 30, 10), DateTime.utc(2011, 12, 30, 11));
    expect(result.single.date, g(2011, 12, 30));
    expect(result.single.start, DateTime.utc(2011, 12, 30, 10));
  });

  test('old daily rules seek without consuming the candidate limit', () {
    final schedule = rule(g(1900, 1, 1), count: 50000);
    expect(
        schedule
            .expand(zones, DateTime.utc(2024, 3, 20), DateTime.utc(2024, 3, 21),
                maxCandidates: 1)
            .single
            .date,
        g(2024, 3, 20));
    expect(schedule.expand(zones, DateTime.utc(2100), DateTime.utc(2101)),
        isEmpty);
  });

  test('provider resolution sees only potentially overlapping slots', () {
    final recording = _RecordingProvider(zones);
    final schedule = rule(g(1900, 1, 1), count: 50000);
    schedule.expand(
        recording, DateTime.utc(2024, 3, 20), DateTime.utc(2024, 3, 21),
        maxCandidates: 1);
    expect(recording.resolvedDates, [g(2024, 3, 20)]);
  });

  test('custom provider offsets determine the window without a fixed margin',
      () {
    final provider = _FixedOffsetProvider(const Duration(hours: 49));
    final schedule = rule(g(1900, 1, 1), count: 50000, zone: 'Test/Fixed');
    final from =
        DateTime.utc(2024, 3, 20, 8).subtract(const Duration(hours: 49));
    expect(
        schedule
            .expand(provider, from, from.add(const Duration(hours: 2)),
                maxCandidates: 1)
            .single
            .date,
        g(2024, 3, 20));
  });

  test('empty provider offset bounds fail explicitly', () {
    final provider = _FixedOffsetProvider(Duration.zero, emptyOffsets: true);
    expect(
        () => rule(g(2024, 1, 1))
            .expand(provider, DateTime.utc(2024), DateTime.utc(2025)),
        throwsStateError);
  });

  test('weekly stride and original count survive seeking', () {
    final schedule = rule(g(1900, 1, 1),
        frequency: RecurrenceFrequency.weekly, interval: 2, count: 4000);
    final expected = g(1900, 1, 1).addDays(3000 * 14);
    expect(
        schedule
            .expand(zones, expected.gregorianDay,
                expected.gregorianDay.add(const Duration(days: 1)),
                maxCandidates: 1)
            .single
            .date,
        expected);
    final ended = rule(g(1900, 1, 1),
        frequency: RecurrenceFrequency.weekly, interval: 2, count: 3000);
    expect(
        ended.expand(zones, expected.gregorianDay,
            expected.gregorianDay.add(const Duration(days: 1))),
        isEmpty);
  });

  test('monthly queries skip historical missing-day rejection', () {
    final schedule = rule(g(2024, 1, 31),
        count: 4,
        frequency: RecurrenceFrequency.monthly,
        datePolicy: RecurrenceDatePolicy.reject);
    expect(
        schedule
            .expand(zones, DateTime.utc(2024, 3, 31), DateTime.utc(2024, 4),
                maxCandidates: 1)
            .single
            .date,
        g(2024, 3, 31));
    expect(
        () => schedule.expand(
            zones, DateTime.utc(2024, 2), DateTime.utc(2024, 3)),
        throwsArgumentError);
  });

  test('monthly overflow can enter a query from its previous anchor month', () {
    final schedule = rule(g(2024, 1, 31),
        count: 3,
        frequency: RecurrenceFrequency.monthly,
        datePolicy: RecurrenceDatePolicy.overflow);
    expect(
        schedule
            .expand(zones, DateTime.utc(2024, 3), DateTime.utc(2024, 3, 3),
                maxCandidates: 1)
            .single
            .date,
        g(2024, 3, 2));
  });

  test('yearly queries skip earlier invalid leap days and preserve anchors',
      () {
    final schedule = rule(g(1904, 2, 29),
        frequency: RecurrenceFrequency.yearly,
        datePolicy: RecurrenceDatePolicy.reject);
    expect(
        schedule
            .expand(zones, DateTime.utc(2024, 2), DateTime.utc(2024, 3),
                maxCandidates: 1)
            .single
            .date,
        g(2024, 2, 29));
    expect(
        () => schedule.expand(
            zones, DateTime.utc(2023, 2), DateTime.utc(2023, 3)),
        throwsArgumentError);
  });

  test('moved overrides before and after the query are found independently',
      () {
    final schedule = rule(g(1900, 1, 1), count: 50000, excludedDates: {
      g(1900, 1, 2)
    }, overrides: {
      g(1900, 1, 1): DateTime.utc(2024, 3, 20, 10),
      g(1900, 1, 2): DateTime.utc(2024, 3, 20, 11),
      g(2030, 1, 1): DateTime.utc(2024, 3, 20, 12),
    });
    final result = schedule.expand(
        zones, DateTime.utc(2024, 3, 20), DateTime.utc(2024, 3, 21),
        maxCandidates: 1);
    expect(result.map((event) => event.start.hour), [9, 10, 12]);
    expect(result.map((event) => event.date),
        [g(2024, 3, 20), g(1900, 1, 1), g(2030, 1, 1)]);
  });

  test('skipped slots retain count and still consume a relevant query limit',
      () {
    final schedule = rule(g(2024, 1, 31),
        frequency: RecurrenceFrequency.monthly,
        count: 2,
        datePolicy: RecurrenceDatePolicy.skip);
    expect(schedule.expand(zones, DateTime.utc(2024, 3), DateTime.utc(2024, 4)),
        isEmpty);
    final longer = rule(g(2024, 1, 31),
        frequency: RecurrenceFrequency.monthly,
        count: 3,
        datePolicy: RecurrenceDatePolicy.skip);
    expect(
        () => longer.expand(zones, DateTime.utc(2024, 2), DateTime.utc(2024, 4),
            maxCandidates: 1),
        throwsStateError);
  });

  test('future gaps and invalid month slots outside the query are not resolved',
      () {
    final gap =
        rule(g(2024, 3, 9), time: WallClock(2, 30), zone: 'America/New_York');
    expect(
        gap
            .expand(zones, DateTime.utc(2024, 3, 9), DateTime.utc(2024, 3, 10))
            .single
            .date,
        g(2024, 3, 9));
    final month = rule(g(2024, 1, 31),
        frequency: RecurrenceFrequency.monthly,
        datePolicy: RecurrenceDatePolicy.reject);
    expect(
        month
            .expand(zones, DateTime.utc(2024, 1), DateTime.utc(2024, 2))
            .single
            .date,
        g(2024, 1, 31));
  });

  test('inclusive lastDate stops before the following missing-day slot', () {
    for (final last in [g(2024, 1, 31), g(2024, 2, 29)]) {
      final schedule = rule(g(2024, 1, 31),
          lastDate: last,
          frequency: RecurrenceFrequency.monthly,
          datePolicy: RecurrenceDatePolicy.reject);
      expect(
          schedule
              .expand(zones, DateTime.utc(2024), DateTime.utc(2025))
              .single
              .date,
          g(2024, 1, 31));
    }
    final required = rule(g(2024, 1, 31),
        lastDate: g(2024, 3, 1),
        frequency: RecurrenceFrequency.monthly,
        datePolicy: RecurrenceDatePolicy.reject);
    expect(() => required.expand(zones, DateTime.utc(2024), DateTime.utc(2025)),
        throwsArgumentError);
  });

  test('inclusive end date respects clamping and overflow policies', () {
    for (final policy in [
      RecurrenceDatePolicy.clamp,
      RecurrenceDatePolicy.overflow,
      RecurrenceDatePolicy.skip
    ]) {
      final schedule = rule(g(2024, 1, 31),
          lastDate: g(2024, 2, 29),
          frequency: RecurrenceFrequency.monthly,
          datePolicy: policy);
      expect(
          schedule
              .expand(zones, DateTime.utc(2024), DateTime.utc(2025))
              .map((event) => event.date),
          policy == RecurrenceDatePolicy.clamp
              ? [g(2024, 1, 31), g(2024, 2, 29)]
              : [g(2024, 1, 31)]);
    }
  });

  for (final calendar in [CalendarId.persian, CalendarId.islamicUmalqura]) {
    final fields = CalendarSystems.forId(calendar).maximumDate;
    final end = CalendarDate(
        calendar: calendar,
        year: fields.year,
        month: fields.month,
        day: fields.day);
    test('$calendar still rejects a required unsupported chronology slot', () {
      for (final frequency in RecurrenceFrequency.values) {
        final days = switch (frequency) {
          RecurrenceFrequency.daily => 2,
          RecurrenceFrequency.weekly => 8,
          RecurrenceFrequency.monthly => 40,
          RecurrenceFrequency.yearly => 400,
        };
        final schedule = rule(end,
            count: 2,
            frequency: frequency,
            datePolicy: RecurrenceDatePolicy.reject,
            time: WallClock(0));
        expect(
            () => schedule.expand(zones, end.gregorianDay,
                end.gregorianDay.add(Duration(days: days))),
            throwsRangeError);
      }
    });
    for (final frequency in RecurrenceFrequency.values) {
      test('$calendar $frequency ends before unsupported chronology slot', () {
        final schedule = rule(end,
            lastDate: end,
            frequency: frequency,
            datePolicy: RecurrenceDatePolicy.reject,
            time: WallClock(0));
        expect(
            schedule
                .expand(zones, end.gregorianDay,
                    end.gregorianDay.add(const Duration(days: 2)))
                .single
                .date,
            end);
        expect(
            schedule.expand(
                zones,
                end.gregorianDay.add(const Duration(days: 10)),
                end.gregorianDay.add(const Duration(days: 11))),
            isEmpty);
      });
    }
  }

  test('large intervals beyond lastDate do not construct an invalid slot', () {
    for (final frequency in RecurrenceFrequency.values) {
      final schedule = rule(g(2024, 1, 1),
          lastDate: g(2024, 1, 1),
          frequency: frequency,
          interval: 9223372036854775807);
      expect(
          schedule
              .expand(zones, DateTime.utc(2024), DateTime.utc(2025))
              .single
              .date,
          g(2024, 1, 1));
    }
  });
}

class _RecordingProvider implements TimeZoneProvider {
  _RecordingProvider(this.delegate);
  final TimeZoneProvider delegate;
  final resolvedDates = <CalendarDate>[];
  @override
  String get databaseRevision => delegate.databaseRevision;
  @override
  Iterable<Duration> offsets(String zone) => delegate.offsets(zone);
  @override
  WallClock timeAt(DateTime instant, String zone) =>
      delegate.timeAt(instant, zone);
  @override
  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar) =>
      delegate.dateAt(instant, zone, calendar);
  @override
  DateTime? resolve(CalendarDate date, WallClock time, String zone,
      {MissingTimePolicy missing = MissingTimePolicy.reject,
      RepeatedTimePolicy repeated = RepeatedTimePolicy.reject}) {
    resolvedDates.add(date);
    return delegate.resolve(date, time, zone,
        missing: missing, repeated: repeated);
  }
}

class _FixedOffsetProvider implements TimeZoneProvider {
  _FixedOffsetProvider(this.offset, {this.emptyOffsets = false});
  final Duration offset;
  final bool emptyOffsets;
  @override
  String get databaseRevision => 'fixed-test-offset';
  @override
  Iterable<Duration> offsets(String zone) => emptyOffsets ? [] : [offset];
  @override
  WallClock timeAt(DateTime instant, String zone) {
    final wall = instant.toUtc().add(offset);
    return WallClock(wall.hour, wall.minute, wall.second, wall.millisecond,
        wall.microsecond);
  }

  @override
  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar) =>
      CalendarDate.fromDateTime(instant.toUtc().add(offset))
          .toCalendar(calendar);
  @override
  DateTime resolve(CalendarDate date, WallClock time, String zone,
          {MissingTimePolicy missing = MissingTimePolicy.reject,
          RepeatedTimePolicy repeated = RepeatedTimePolicy.reject}) =>
      date.gregorianDay
          .add(Duration(
              hours: time.hour,
              minutes: time.minute,
              seconds: time.second,
              milliseconds: time.millisecond,
              microseconds: time.microsecond))
          .subtract(offset);
}
