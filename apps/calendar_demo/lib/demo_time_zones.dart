import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:timezone/timezone.dart' as tz;

enum MissingTimePolicy { reject, nextValidMinute }

enum RepeatedTimePolicy { reject, earlier, later }

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

/// Demo-only named-zone conversion. Initialize timezone data before use.
/// Missing/repeated event times reject; day bounds choose explicit policies.
final class DemoTimeZones {
  tz.Location _location(String zone) =>
      zone == 'UTC' ? tz.UTC : tz.getLocation(zone);

  Iterable<Duration> _offsets(String zone) =>
      _location(zone).zones.map((value) {
        // timezone 0.10 uses integer milliseconds; 0.11 uses Duration.
        final Object offset = value.offset;
        return offset is Duration
            ? offset
            : Duration(milliseconds: offset as int);
      }).toSet();

  WallClock timeAt(DateTime instant, String zone) {
    final value = tz.TZDateTime.from(instant, _location(zone));
    return WallClock(value.hour, value.minute, value.second, value.millisecond,
        value.microsecond);
  }

  CalendarDate dateAt(DateTime instant, String zone, CalendarId calendar) {
    final value = tz.TZDateTime.from(instant, _location(zone));
    return CalendarDate(
            calendar: CalendarId.gregory,
            year: value.year,
            month: value.month,
            day: value.day)
        .toCalendar(calendar);
  }

  DateTime resolve(CalendarDate date, WallClock time, String zone,
      {MissingTimePolicy missing = MissingTimePolicy.reject,
      RepeatedTimePolicy repeated = RepeatedTimePolicy.reject}) {
    final location = _location(zone);
    final day = date.gregorianDay;
    final wall = DateTime.utc(day.year, day.month, day.day, time.hour,
        time.minute, time.second, time.millisecond, time.microsecond);
    // Enumerate offsets, then verify every candidate's actual wall fields.
    // Never rely on TZDateTime's gap/fold constructor normalization.
    final zoneOffsets = _offsets(zone);
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
