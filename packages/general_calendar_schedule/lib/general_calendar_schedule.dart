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

  /// All possible UTC offsets for [zone], including historical offsets.
  /// Expansion uses this finite, nonempty set to seek a safe query window.
  Iterable<Duration> offsets(String zone);

  WallClock timeAt(DateTime instant, String zone);
  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar);

  /// [MissingTimePolicy.nextValidMinute] advances by at most 48 wall hours.
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
  Iterable<Duration> offsets(String zone) => _location(zone).zones.map((value) {
        // timezone 0.10 uses integer milliseconds; 0.11 uses Duration.
        final Object offset = value.offset;
        return offset is Duration
            ? offset
            : Duration(milliseconds: offset as int);
      }).toSet();

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
    final zoneOffsets = offsets(zone);
    List<DateTime> candidates(DateTime requested) {
      final results = <DateTime>[];
      for (final offset in zoneOffsets) {
        final instant = DateTime.fromMicrosecondsSinceEpoch(
            requested.microsecondsSinceEpoch - offset.inMicroseconds,
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

  BigInt _wallTime(BigInt dayIndex) =>
      dayIndex * _microsecondsPerDay +
      BigInt.from(Duration(
              hours: time.hour,
              minutes: time.minute,
              seconds: time.second,
              milliseconds: time.millisecond,
              microseconds: time.microsecond)
          .inMicroseconds);

  BigInt _dayIndex(int index) =>
      BigInt.from(startDate.dayIndex) +
      BigInt.from(index) *
          BigInt.from(interval) *
          BigInt.from(frequency == RecurrenceFrequency.weekly ? 7 : 1);

  ({BigInt year, int month}) _period(int index) {
    final step = BigInt.from(index) * BigInt.from(interval);
    if (frequency == RecurrenceFrequency.yearly) {
      return (year: BigInt.from(startDate.year) + step, month: startDate.month);
    }
    final total = BigInt.from(startDate.year) * BigInt.from(12) +
        BigInt.from(startDate.month - 1) +
        step;
    final year = _floorDivide(total, BigInt.from(12));
    return (year: year, month: (total - year * BigInt.from(12)).toInt() + 1);
  }

  bool _periodAfter(({BigInt year, int month}) period, CalendarFields fields) =>
      period.year > BigInt.from(fields.year) ||
      (period.year == BigInt.from(fields.year) && period.month > fields.month);

  bool _pastLastDate(int index) {
    final last = lastDate;
    if (last == null) return false;
    if (frequency == RecurrenceFrequency.daily ||
        frequency == RecurrenceFrequency.weekly) {
      return _dayIndex(index) > BigInt.from(last.dayIndex);
    }
    final period = _period(index);
    final fields = (year: last.year, month: last.month, day: last.day);
    if (_periodAfter(period, fields)) return true;
    if (period.year != BigInt.from(last.year) || period.month != last.month) {
      return false;
    }
    var day = startDate.day;
    if (datePolicy == RecurrenceDatePolicy.clamp) {
      final length = startDate.system.daysInMonth(last.year, last.month);
      if (day > length) day = length;
    }
    return day > last.day;
  }

  CalendarFields _fieldsAtDay(BigInt index) {
    final system = startDate.system;
    final minimum = system.minimumDate, maximum = system.maximumDate;
    final low = BigInt.from(system
            .toGregorianDay(minimum.year, minimum.month, minimum.day)
            .microsecondsSinceEpoch) ~/
        _microsecondsPerDay;
    final high = BigInt.from(system
            .toGregorianDay(maximum.year, maximum.month, maximum.day)
            .microsecondsSinceEpoch) ~/
        _microsecondsPerDay;
    final bounded = index < low ? low : (index > high ? high : index);
    return system.fromGregorianDay(DateTime.fromMicrosecondsSinceEpoch(
        (bounded * _microsecondsPerDay).toInt(),
        isUtc: true));
  }

  int _firstIndex(_ExpansionWindow window) {
    if (frequency == RecurrenceFrequency.daily ||
        frequency == RecurrenceFrequency.weekly) {
      final stride = BigInt.from(interval) *
          BigInt.from(frequency == RecurrenceFrequency.weekly ? 7 : 1) *
          _microsecondsPerDay;
      final index = _floorDivide(
              window.lower - _wallTime(BigInt.from(startDate.dayIndex)),
              stride) +
          BigInt.one;
      return index.isNegative ? 0 : index.toInt();
    }
    final fields =
        _fieldsAtDay(_floorDivide(window.lower, _microsecondsPerDay));
    final distance = frequency == RecurrenceFrequency.monthly
        ? (fields.year - startDate.year) * 12 + fields.month - startDate.month
        : fields.year - startDate.year;
    // An overflow anchor can land in the next month. Inspect its preceding
    // slot's coordinates, then discard it without construction if irrelevant.
    final index = BigInt.from(distance) ~/ BigInt.from(interval) - BigInt.one;
    return index.isNegative ? 0 : index.toInt();
  }

  ({BigInt first, BigInt last}) _slotWallRange(int index) {
    if (frequency == RecurrenceFrequency.daily ||
        frequency == RecurrenceFrequency.weekly) {
      final wall = _wallTime(_dayIndex(index));
      return (first: wall, last: wall);
    }
    final period = _period(index);
    final system = startDate.system;
    if (period.year < BigInt.from(system.minimumDate.year) ||
        period.year > BigInt.from(system.maximumDate.year)) {
      throw RangeError('Recurrence outside supported calendar years');
    }
    final year = period.year.toInt(), month = period.month;
    final length = system.daysInMonth(year, month);
    final minimum = system.minimumDate;
    // Gregorian's first supported month starts partway through the month.
    final anchorDay =
        year == minimum.year && month == minimum.month ? minimum.day : 1;
    final firstDay = BigInt.from(system
                .toGregorianDay(year, month, anchorDay)
                .microsecondsSinceEpoch) ~/
            _microsecondsPerDay -
        BigInt.from(anchorDay - 1);
    var day = startDate.day;
    if (day > length) {
      if (datePolicy == RecurrenceDatePolicy.clamp) {
        day = length;
      } else if (datePolicy != RecurrenceDatePolicy.overflow) {
        // A missing day belongs to this anchor month. Reject it only when
        // that month is queried; a historical invalid slot cannot poison a
        // later query. Skipped slots still count when the month is relevant.
        return (
          first: _wallTime(firstDay),
          last: _wallTime(firstDay + BigInt.from(length - 1))
        );
      }
    }
    final wall = _wallTime(firstDay + BigInt.from(day - 1));
    return (first: wall, last: wall);
  }

  /// Returns occurrences overlapping [from, until), in UTC order. Exhausting
  /// [maxCandidates] relevant anchored slots throws rather than returning an
  /// incomplete success. Historical slots outside the query do not consume it.
  List<ScheduleOccurrence> expand(
      TimeZoneProvider provider, DateTime from, DateTime until,
      {int maxCandidates = 10000}) {
    if (!from.isBefore(until) || maxCandidates <= 0) {
      throw ArgumentError('Invalid expansion window or limit');
    }
    final window = _ExpansionWindow(provider.offsets(zone), from, until,
        duration, missing == MissingTimePolicy.nextValidMinute);
    final upperDay =
        _floorDivide(window.upper - BigInt.one, _microsecondsPerDay);
    final maximum = startDate.system.maximumDate;
    final maximumDay = BigInt.from(startDate.system
            .toGregorianDay(maximum.year, maximum.month, maximum.day)
            .microsecondsSinceEpoch) ~/
        _microsecondsPerDay;
    final upperFields = upperDay > maximumDay ? null : _fieldsAtDay(upperDay);
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

    var examined = 0;
    for (var index = _firstIndex(window);; index++) {
      if ((count != null && index >= count!) || _pastLastDate(index)) break;
      if (frequency != RecurrenceFrequency.daily &&
          frequency != RecurrenceFrequency.weekly &&
          upperFields != null &&
          _periodAfter(_period(index), upperFields)) {
        break;
      }
      final coordinates = _slotWallRange(index);
      if (coordinates.first >= window.upper) break;
      if (!window.mayOverlap(coordinates.first, coordinates.last)) continue;
      if (examined++ >= maxCandidates) {
        throw StateError(
            'Recurrence candidate limit exhausted; narrow the rule/window or increase the limit');
      }
      final date = _candidate(index);
      if (date == null) continue;
      if (lastDate != null && date.compareTo(lastDate!) > 0) break;
      if (excludedDates.contains(date) || overrides.containsKey(date)) continue;
      final instant = provider.resolve(date, time, zone,
          missing: missing, repeated: repeated);
      if (instant != null) append(date, instant);
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

final _microsecondsPerDay = BigInt.from(Duration.microsecondsPerDay);

BigInt _floorDivide(BigInt value, BigInt divisor) {
  final result = value ~/ divisor;
  return value.isNegative && value.remainder(divisor) != BigInt.zero
      ? result - BigInt.one
      : result;
}

final class _ExpansionWindow {
  _ExpansionWindow(Iterable<Duration> zoneOffsets, DateTime from,
      DateTime until, Duration duration, bool advanceMissing)
      : offsets = zoneOffsets
            .map((value) => BigInt.from(value.inMicroseconds))
            .toSet(),
        from = BigInt.from(from.microsecondsSinceEpoch),
        until = BigInt.from(until.microsecondsSinceEpoch),
        duration = BigInt.from(duration.inMicroseconds),
        advance = BigInt.from(
            advanceMissing ? const Duration(hours: 48).inMicroseconds : 0) {
    if (offsets.isEmpty) {
      throw StateError('Zone offset bounds must not be empty');
    }
  }
  final Set<BigInt> offsets;
  final BigInt from, until, duration, advance;
  BigInt get lower =>
      from - duration + offsets.reduce((a, b) => a < b ? a : b) - advance;
  BigInt get upper => until + offsets.reduce((a, b) => a > b ? a : b);

  bool mayOverlap(BigInt firstWall, BigInt lastWall) => offsets.any((offset) =>
      firstWall - offset < until &&
      lastWall - offset + advance + duration > from);
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
