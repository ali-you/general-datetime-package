import 'calendar_date_utils.dart';
import 'general_date_time_interface.dart';
import 'calendars/hijri/hijri_date_time.dart';
import 'calendars/persian/persian_date_time.dart';

/// Unicode calendar identifiers supported by the version-1 storage schema.
enum CalendarId {
  gregory('gregory'),
  persian('persian'),
  islamicUmalqura('islamic-umalqura');

  const CalendarId(this.identifier);

  final String identifier;

  static CalendarId _parse(Object? value) {
    for (final calendar in values) {
      if (value == calendar.identifier) return calendar;
    }
    throw FormatException('Unsupported calendar identifier: $value');
  }

  static CalendarId _of(DateTime date) {
    if (date is PersianDateTime) return persian;
    if (date is HijriDateTime) return islamicUmalqura;
    if (date is GeneralDateTimeInterface) {
      throw UnsupportedError(
        'Serialization is not registered for ${date.runtimeType}.',
      );
    }
    return gregory;
  }
}

/// An immutable instant with optional presentation metadata.
///
/// Version 1 stores a native Gregorian UTC RFC 3339 timestamp, with at most six
/// fractional digits. The four-digit Gregorian year must be 0000 through 9999.
/// Decoding never normalizes invalid fields or truncates precision. Calendar
/// metadata does not change the instant or require it to fit that calendar's
/// supported display range. Convert [instant] explicitly when displaying it.
///
/// [timeZone] is optional, opaque metadata supplied by the application (normally
/// an IANA zone name). This package does not resolve or validate named zones,
/// infer them from local time, or apply their rules. Local/UTC input mode is not
/// persisted; [instant] is always native UTC with the same epoch microseconds.
final class CalendarInstant {
  CalendarInstant._(this.instant, this.calendar, this.timeZone);

  /// Encodes the exact instant and infers the calendar from the runtime type.
  ///
  /// Unsupported calendar interfaces throw [UnsupportedError]. Out-of-schema
  /// Gregorian years and empty/untrimmed zone metadata throw [ArgumentError].
  factory CalendarInstant.fromDateTime(DateTime date, {String? timeZone}) {
    final calendar = CalendarId._of(date);
    final instant = CalendarDateUtils.toGregorian(date).toUtc();
    if (instant.year < 0 || instant.year > 9999) {
      throw ArgumentError.value(date, 'date',
          'Version-1 timestamps require Gregorian years 0000 through 9999.');
    }
    if (!_validTimeZone(timeZone)) {
      throw ArgumentError.value(timeZone, 'timeZone',
          'Zone metadata must be a nonempty, trimmed string.');
    }
    return CalendarInstant._(instant, calendar, timeZone);
  }

  /// Reads a version-1 instant record or throws [FormatException].
  ///
  /// Only extended UTC timestamps ending in `Z` are accepted: four-digit year,
  /// seconds required, and an optional fraction of one through six digits.
  /// Offsets, leap seconds, calendar strings, and RFC 9557 suffixes are not part
  /// of this schema. Unknown fields, versions, calendars, and kinds are rejected.
  factory CalendarInstant.fromJson(Object? json) {
    final record = _readRecord(
      json,
      'instant',
      const {'version', 'kind', 'timestamp', 'calendar'},
      const {'timeZone'},
    );
    final calendar = CalendarId._parse(record['calendar']);
    final zone = record['timeZone'];
    if (record.containsKey('timeZone') &&
        (zone is! String || !_validTimeZone(zone))) {
      throw const FormatException('Invalid timeZone metadata.');
    }
    return CalendarInstant._(
      _readTimestamp(record['timestamp']),
      calendar,
      zone as String?,
    );
  }

  /// The exact instant as a native Gregorian UTC value.
  final DateTime instant;

  /// Preferred presentation calendar; never changes [instant].
  final CalendarId calendar;

  final String? timeZone;

  Map<String, Object> toJson() => {
        'version': 1,
        'kind': 'instant',
        'timestamp': instant.toIso8601String(),
        'calendar': calendar.identifier,
        if (timeZone != null) 'timeZone': timeZone!,
      };
}

/// An immutable calendar date with no clock fields, timezone, or instant.
///
/// Version 1 stores the calendar identifier and integer year/month/day fields.
/// Invalid dates and dates outside the selected implementation's supported
/// range are rejected, without constructor overflow normalization. Signed
/// Persian years (including zero) are supported. This record defines storage
/// only; date arithmetic and scheduling policies are separate concerns.
final class CalendarDateRecord {
  /// Creates a validated calendar date; invalid fields throw [ArgumentError].
  factory CalendarDateRecord({
    required CalendarId calendar,
    required int year,
    required int month,
    required int day,
  }) {
    if (!_validDate(calendar, year, month, day)) {
      throw ArgumentError('Invalid ${calendar.identifier} date: '
          '$year-$month-$day.');
    }
    return CalendarDateRecord._(calendar, year, month, day);
  }

  const CalendarDateRecord._(this.calendar, this.year, this.month, this.day);

  /// Explicitly extracts the input's wall date and discards its clock and mode.
  ///
  /// No timezone conversion occurs. Unsupported calendar interfaces throw
  /// [UnsupportedError]. Use [CalendarInstant] to persist a timed value instead.
  factory CalendarDateRecord.fromDateTime(DateTime date) => CalendarDateRecord(
        calendar: CalendarId._of(date),
        year: date.year,
        month: date.month,
        day: date.day,
      );

  /// Reads a version-1 calendar-date record or throws [FormatException].
  factory CalendarDateRecord.fromJson(Object? json) {
    final record = _readRecord(
      json,
      'calendar-date',
      const {'version', 'kind', 'calendar', 'year', 'month', 'day'},
      const {},
    );
    final calendar = CalendarId._parse(record['calendar']);
    final year = record['year'];
    final month = record['month'];
    final day = record['day'];
    if (year is! int ||
        month is! int ||
        day is! int ||
        !_validDate(calendar, year, month, day)) {
      throw const FormatException('Invalid calendar date fields.');
    }
    return CalendarDateRecord._(calendar, year, month, day);
  }

  final CalendarId calendar;
  final int year;
  final int month;
  final int day;

  Map<String, Object> toJson() => {
        'version': 1,
        'kind': 'calendar-date',
        'calendar': calendar.identifier,
        'year': year,
        'month': month,
        'day': day,
      };
}

bool _validTimeZone(String? zone) =>
    zone == null || (zone.isNotEmpty && zone.trim() == zone);

Map<String, Object?> _readRecord(
  Object? json,
  String kind,
  Set<String> requiredKeys,
  Set<String> optionalKeys,
) {
  if (json is! Map || json.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a JSON object with string keys.');
  }
  final record = Map<String, Object?>.from(json);
  if (!requiredKeys.every(record.containsKey) ||
      record.keys.any((key) =>
          !requiredKeys.contains(key) && !optionalKeys.contains(key))) {
    throw const FormatException('Missing or unknown record fields.');
  }
  if (record['version'] is! int || record['version'] != 1) {
    throw const FormatException('Unsupported schema version.');
  }
  if (record['kind'] != kind) {
    throw FormatException('Expected a $kind record.');
  }
  return record;
}

bool _validDate(CalendarId calendar, int year, int month, int day) {
  switch (calendar) {
    case CalendarId.persian:
      return PersianDateTime.isValidDate(year, month, day);
    case CalendarId.islamicUmalqura:
      return HijriDateTime.isValidDate(year, month, day);
    case CalendarId.gregory:
      // Check before native construction, including extreme integer inputs.
      if (year < -271821 ||
          year > 275760 ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31) {
        return false;
      }
      try {
        final date = DateTime.utc(year, month, day);
        return date.year == year && date.month == month && date.day == day;
      } on ArgumentError {
        return false;
      }
  }
}

final _timestampPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?Z$',
);

DateTime _readTimestamp(Object? value) {
  final match = value is String ? _timestampPattern.firstMatch(value) : null;
  // Check the entire input explicitly, including a possible final newline.
  if (match == null || match.end != (value as String).length) {
    throw const FormatException('Expected a Gregorian UTC timestamp.');
  }
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final hour = int.parse(match[4]!);
  final minute = int.parse(match[5]!);
  final second = int.parse(match[6]!);
  if (!_validDate(CalendarId.gregory, year, month, day) ||
      hour > 23 ||
      minute > 59 ||
      second > 59) {
    throw const FormatException('Invalid Gregorian timestamp fields.');
  }
  final fraction = int.parse((match[7] ?? '').padRight(6, '0'));
  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
    fraction ~/ 1000,
    fraction % 1000,
  );
}
