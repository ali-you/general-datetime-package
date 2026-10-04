library;

import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:timezone/timezone.dart' as tz;

enum MissingTimePolicy { reject, skip, nextValidMinute }

enum RepeatedTimePolicy { reject, earlier, later }

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

enum RecurrenceDatePolicy { clamp, reject, skip, overflow }

final class WallClock {
  WallClock(this.hour,
      [this.minute = 0,
      this.second = 0,
      this.millisecond = 0,
      this.microsecond = 0]) {
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59 ||
        millisecond < 0 ||
        millisecond > 999 ||
        microsecond < 0 ||
        microsecond > 999) {
      throw ArgumentError('Invalid wall clock');
    }
  }
  final int hour, minute, second, millisecond, microsecond;
}

abstract interface class TimeZoneProvider {
  String get databaseRevision;
  WallClock timeAt(DateTime instant, String zone);
  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar);
  DateTime? resolve(CalendarDate date, WallClock time, String zone,
      {MissingTimePolicy missing = MissingTimePolicy.reject,
      RepeatedTimePolicy repeated = RepeatedTimePolicy.reject});
}

/// Initialize package:timezone data before use. Supply its actual bundled data
/// revision for persistence; this adapter never guesses a device's zone.
final class IanaTimeZoneProvider implements TimeZoneProvider {
  IanaTimeZoneProvider({required this.databaseRevision}) {
    if (databaseRevision.trim().isEmpty) {
      throw ArgumentError('A database revision is required');
    }
  }
  @override
  final String databaseRevision;
  tz.Location _location(String zone) =>
      zone == 'UTC' ? tz.UTC : tz.getLocation(zone);
  @override
  WallClock timeAt(DateTime instant, String zone) {
    final value = tz.TZDateTime.from(instant, _location(zone));
    return WallClock(value.hour, value.minute, value.second, value.millisecond,
        value.microsecond);
  }

  @override
  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar) {
    final value = tz.TZDateTime.from(instant, _location(zone));
    return CalendarDate(
            calendar: CalendarId.gregory,
            year: value.year,
            month: value.month,
            day: value.day)
        .toCalendar(calendar);
  }

  @override
  DateTime? resolve(CalendarDate date, WallClock time, String zone,
      {MissingTimePolicy missing = MissingTimePolicy.reject,
      RepeatedTimePolicy repeated = RepeatedTimePolicy.reject}) {
    final location = _location(zone);
    final day = date.gregorianDay;
    final wall = DateTime.utc(day.year, day.month, day.day, time.hour,
        time.minute, time.second, time.millisecond, time.microsecond);
    // Enumerate offsets, then verify every candidate's actual wall fields.
    // Never rely on TZDateTime's gap/fold constructor normalization.
    final offsets = location.zones.map((value) {
      // timezone 0.10 uses integer milliseconds; 0.11 uses Duration.
      final Object offset = value.offset;
      return offset is Duration
          ? offset.inMicroseconds
          : (offset as int) * 1000;
    }).toSet();
    List<DateTime> candidates(DateTime requested) {
      final results = <DateTime>[];
      for (final offset in offsets) {
        final instant = DateTime.fromMicrosecondsSinceEpoch(
            requested.microsecondsSinceEpoch - offset,
            isUtc: true);
        final local = tz.TZDateTime.from(instant, location);
        if ((
              local.year,
              local.month,
              local.day,
              local.hour,
              local.minute,
              local.second,
              local.millisecond,
              local.microsecond
            ) ==
            (
              requested.year,
              requested.month,
              requested.day,
              requested.hour,
              requested.minute,
              requested.second,
              requested.millisecond,
              requested.microsecond
            )) {
          results.add(instant);
        }
      }
      return results..sort();
    }

    var matches = candidates(wall);
    if (matches.isEmpty) {
      if (missing == MissingTimePolicy.skip) return null;
      if (missing == MissingTimePolicy.reject) {
        throw ArgumentError('Nonexistent wall time in $zone');
      }
      // Preserve seconds/fractions and find the next legal minute, up to 48h.
      for (var minutes = 1; minutes <= 2880 && matches.isEmpty; minutes++) {
        matches = candidates(wall.add(Duration(minutes: minutes)));
      }
      if (matches.isEmpty) {
        throw StateError('No valid wall time within 48 hours');
      }
    }
    if (matches.length > 1 && repeated == RepeatedTimePolicy.reject) {
      throw ArgumentError(
          'Repeated wall time in $zone; select earlier or later');
    }
    return repeated == RepeatedTimePolicy.later ? matches.last : matches.first;
  }
}

final class ScheduleOccurrence {
  ScheduleOccurrence(
      {required this.date,
      required DateTime start,
      required this.duration,
      required this.zone,
      required this.zoneRevision})
      : start = DateTime.fromMicrosecondsSinceEpoch(
            start.microsecondsSinceEpoch,
            isUtc: true) {
    if (duration <= Duration.zero) {
      throw ArgumentError('Duration must be positive');
    }
  }
  final CalendarDate date;
  final DateTime start;
  final Duration duration;
  final String zone, zoneRevision;
  DateTime get end => start.add(duration);
  String get chronologyRevision => date.system.dataRevision;
  bool overlaps(ScheduleOccurrence other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

/// A bounded civil recurrence, not an RFC 5545 RRULE parser. Count measures
/// anchored candidate slots, including skipped/cancelled slots. Month/year
/// candidates always derive from [startDate], never the previous clamped date.
/// Future occurrences use current provider rules; persisted past instants stay
/// unchanged. Durations are elapsed time, not wall-clock end times.
final class CalendarSchedule {
  CalendarSchedule(
      {required this.startDate,
      required this.time,
      required this.zone,
      required this.duration,
      required this.frequency,
      this.interval = 1,
      this.count,
      this.lastDate,
      this.datePolicy = RecurrenceDatePolicy.clamp,
      this.missing = MissingTimePolicy.reject,
      this.repeated = RepeatedTimePolicy.reject,
      Set<CalendarDate> excludedDates = const {},
      Map<CalendarDate, DateTime> overrides = const {}})
      : excludedDates = Set.unmodifiable(excludedDates),
        overrides = Map.unmodifiable(overrides.map((date, instant) => MapEntry(
            date,
            DateTime.fromMicrosecondsSinceEpoch(instant.microsecondsSinceEpoch,
                isUtc: true)))) {
    if (interval <= 0 ||
        (count != null && count! <= 0) ||
        duration <= Duration.zero ||
        zone.trim().isEmpty) {
      throw ArgumentError(
          'Invalid recurrence interval, count, duration, or zone');
    }
    if (lastDate != null &&
        (lastDate!.calendar != startDate.calendar ||
            lastDate!.compareTo(startDate) < 0)) {
      throw ArgumentError(
          'lastDate must use the recurrence calendar and follow its start');
    }
    for (final date in {...excludedDates, ...overrides.keys}) {
      if (_candidateIndex(date) == null) {
        throw ArgumentError('Exception date is not an anchored candidate');
      }
    }
  }
  final CalendarDate startDate;
  final WallClock time;
  final String zone;
  final Duration duration;
  final RecurrenceFrequency frequency;
  final int interval;
  final int? count;
  final CalendarDate? lastDate;
  final RecurrenceDatePolicy datePolicy;
  final MissingTimePolicy missing;
  final RepeatedTimePolicy repeated;
  final Set<CalendarDate> excludedDates;
  final Map<CalendarDate, DateTime> overrides;

  CalendarDate? _candidate(int index) {
    final amount = BigInt.from(index) * BigInt.from(interval);
    if (amount > BigInt.from(7000000)) {
      throw RangeError('Recurrence outside supported calendar span');
    }
    final step = amount.toInt();
    if (frequency == RecurrenceFrequency.daily) return startDate.addDays(step);
    if (frequency == RecurrenceFrequency.weekly) {
      return startDate.addDays(step * 7);
    }
    final policy = switch (datePolicy) {
      RecurrenceDatePolicy.clamp => CalendarOverflow.clamp,
      RecurrenceDatePolicy.overflow => CalendarOverflow.overflow,
      _ => CalendarOverflow.reject,
    };
    try {
      return frequency == RecurrenceFrequency.monthly
          ? startDate.addMonths(step, policy: policy)
          : startDate.addYears(step, policy: policy);
    } on RangeError {
      rethrow;
    } on ArgumentError {
      if (datePolicy == RecurrenceDatePolicy.skip) return null;
      rethrow;
    }
  }

  int? _candidateIndex(CalendarDate date) {
    if (date.calendar != startDate.calendar || date.compareTo(startDate) < 0) {
      return null;
    }
    final int distance = switch (frequency) {
      RecurrenceFrequency.daily => startDate.daysUntil(date),
      RecurrenceFrequency.weekly => startDate.daysUntil(date),
      RecurrenceFrequency.monthly =>
        (date.year - startDate.year) * 12 + date.month - startDate.month,
      RecurrenceFrequency.yearly => date.year - startDate.year,
    };
    final stride = interval * (frequency == RecurrenceFrequency.weekly ? 7 : 1);
    // Overflow candidates can land in the following month/year.
    for (final raw in [distance, distance - 1]) {
      if (raw < 0 || raw % stride != 0) continue;
      final index = raw ~/ stride;
      if ((count != null && index >= count!) ||
          (lastDate != null && date.compareTo(lastDate!) > 0)) {
        continue;
      }
      try {
        if (_candidate(index) == date) return index;
      } on ArgumentError {
        continue;
      }
    }
    return null;
  }

  /// Returns occurrences overlapping [from, until), in UTC order. Exhausting
  /// [maxCandidates] throws rather than returning an incomplete success.
  List<ScheduleOccurrence> expand(
      TimeZoneProvider provider, DateTime from, DateTime until,
      {int maxCandidates = 10000}) {
    if (!from.isBefore(until) || maxCandidates <= 0) {
      throw ArgumentError('Invalid expansion window or limit');
    }
    final upper = provider.dateAt(until, zone, CalendarId.gregory).dayIndex + 2;
    final results = <ScheduleOccurrence>[];
    void append(CalendarDate date, DateTime instant) {
      final occurrence = ScheduleOccurrence(
          date: date,
          start: instant,
          duration: duration,
          zone: zone,
          zoneRevision: provider.databaseRevision);
      if (occurrence.start.isBefore(until) && occurrence.end.isAfter(from)) {
        results.add(occurrence);
      }
    }

    var finished = false;
    for (var index = 0; index < maxCandidates; index++) {
      if (count != null && index >= count!) {
        finished = true;
        break;
      }
      final date = _candidate(index);
      if (date == null) continue;
      if (date.dayIndex > upper ||
          (lastDate != null && date.compareTo(lastDate!) > 0)) {
        finished = true;
        break;
      }
      if (excludedDates.contains(date) || overrides.containsKey(date)) continue;
      final instant = provider.resolve(date, time, zone,
          missing: missing, repeated: repeated);
      if (instant != null) append(date, instant);
    }
    if (count != null && count! <= maxCandidates) finished = true;
    if (!finished) {
      throw StateError(
          'Recurrence candidate limit exhausted; narrow the rule/window or increase the limit');
    }
    // Moved exceptions are queried by their new instants even if their original
    // dates lie beyond this window.
    for (final entry in overrides.entries) {
      if (!excludedDates.contains(entry.key)) append(entry.key, entry.value);
    }
    results.sort((a, b) => a.start.compareTo(b.start));
    return List.unmodifiable(results);
  }
}

final class BusinessDayPolicy {
  BusinessDayPolicy(
      {Set<int> weekend = const {DateTime.saturday, DateTime.sunday},
      Iterable<CalendarDate> holidays = const []})
      : weekend = Set.unmodifiable(weekend),
        holidayDays = Set.unmodifiable(holidays.map((date) => date.dayIndex)) {
    if (weekend.any((day) => day < 1 || day > 7) || weekend.length == 7) {
      throw ArgumentError('Invalid weekend');
    }
  }
  final Set<int> weekend, holidayDays;
  bool isBusinessDay(CalendarDate date) =>
      !weekend.contains(date.weekday) && !holidayDays.contains(date.dayIndex);
  CalendarDate nextBusinessDay(CalendarDate date,
      {int maximumSearchDays = 366}) {
    for (var i = 1; i <= maximumSearchDays; i++) {
      final candidate = date.addDays(i);
      if (isBusinessDay(candidate)) return candidate;
    }
    throw StateError('No business day within search limit');
  }
}

/// Applications implement OS/backend delivery. No background service is
/// implied by constructing a schedule.
abstract interface class ReminderDelivery {
  Future<void> schedule(String id, DateTime utcInstant);
  Future<void> cancel(String id);
}
