import 'calendar_serialization.dart';
import 'general_date_time_interface.dart';
import 'hijri_date_time.dart';
import 'persian_date_time.dart';

/// Calendar fields describe a civil date, without assigning a timezone.
typedef CalendarFields = ({int year, int month, int day});

/// Construction and conversion contract for the registered chronologies.
///
/// Registration is deliberately limited to the version-1 storage identifiers.
/// Implementing this interface does not register formatter or storage support.
abstract interface class CalendarSystem {
  CalendarId get id;
  String get dataRevision;
  String get calculationPolicy;
  CalendarFields get minimumDate;
  CalendarFields get maximumDate;
  bool isValidDate(int year, int month, int day);
  int daysInMonth(int year, int month);
  int daysInYear(int year);
  bool hasPublishedData(int year);

  /// Gregorian UTC midnight is a civil-day coordinate, not an event instant.
  DateTime toGregorianDay(int year, int month, int day);
  CalendarFields fromGregorianDay(DateTime day);

  /// Strict wall-field construction; local DST normalization is rejected.
  DateTime construct(int year, int month, int day,
      {int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0,
      bool isUtc = true});

  /// Returns native/calendar fields for the same instant in UTC or host local.
  DateTime fromInstant(DateTime instant, {bool isUtc = true});
}

/// Immutable built-in registry. Named-zone and formatter support are separate.
abstract final class CalendarSystems {
  static const gregorian = _BuiltInCalendarSystem(CalendarId.gregory);
  static const persian = _BuiltInCalendarSystem(CalendarId.persian);
  static const ummAlQura = _BuiltInCalendarSystem(CalendarId.islamicUmalqura);
  static CalendarSystem forId(CalendarId id) => switch (id) {
        CalendarId.gregory => gregorian,
        CalendarId.persian => persian,
        CalendarId.islamicUmalqura => ummAlQura,
      };
}

final class _BuiltInCalendarSystem implements CalendarSystem {
  const _BuiltInCalendarSystem(this.id);
  @override
  final CalendarId id;
  @override
  String get dataRevision => switch (id) {
        CalendarId.gregory => 'proleptic-gregorian-v1',
        CalendarId.persian => 'tehran-1206-1498-borkowski-v1',
        CalendarId.islamicUmalqura => 'icu-openjdk21-1300-1600-v1',
      };
  @override
  String get calculationPolicy => switch (id) {
        CalendarId.gregory => 'Proleptic Gregorian; Dart UTC date bounds.',
        CalendarId.persian => 'Published Tehran leap data for 1206–1498; '
            'finite Borkowski calculation elsewhere.',
        CalendarId.islamicUmalqura => 'Finite Umm al-Qura table; no fallback.',
      };
  @override
  CalendarFields get minimumDate => switch (id) {
        CalendarId.gregory => (year: -271821, month: 4, day: 20),
        CalendarId.persian => (
            year: PersianDateTime.minimumYear,
            month: 1,
            day: 1
          ),
        CalendarId.islamicUmalqura => (
            year: HijriDateTime.minimumYear,
            month: 1,
            day: 1
          ),
      };
  @override
  CalendarFields get maximumDate => switch (id) {
        CalendarId.gregory => (year: 275760, month: 9, day: 13),
        CalendarId.persian => (
            year: PersianDateTime.maximumYear,
            month: 12,
            day: PersianDateTime.daysInMonth(PersianDateTime.maximumYear, 12)
          ),
        CalendarId.islamicUmalqura => (
            year: HijriDateTime.maximumYear,
            month: 12,
            day: HijriDateTime.daysInMonth(HijriDateTime.maximumYear, 12)
          ),
      };
  @override
  bool isValidDate(int year, int month, int day) {
    if (id == CalendarId.persian) {
      return PersianDateTime.isValidDate(year, month, day);
    }
    if (id == CalendarId.islamicUmalqura) {
      return HijriDateTime.isValidDate(year, month, day);
    }
    if (year < minimumDate.year ||
        year > maximumDate.year ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return false;
    }
    try {
      final value = DateTime.utc(year, month, day);
      return value.year == year && value.month == month && value.day == day;
    } on ArgumentError {
      return false;
    }
  }

  void _requireYear(int year) {
    if (year < minimumDate.year || year > maximumDate.year) {
      throw RangeError.range(year, minimumDate.year, maximumDate.year, 'year');
    }
  }

  @override
  int daysInMonth(int year, int month) {
    _requireYear(year);
    if (month < 1 || month > 12) throw RangeError.range(month, 1, 12, 'month');
    if (id == CalendarId.persian) {
      return PersianDateTime.daysInMonth(year, month);
    }
    if (id == CalendarId.islamicUmalqura) {
      return HijriDateTime.daysInMonth(year, month);
    }
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    return [
      31,
      leap ? 29 : 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31
    ][month - 1];
  }

  @override
  int daysInYear(int year) => List.generate(12, (i) => daysInMonth(year, i + 1))
      .reduce((a, b) => a + b);
  @override
  bool hasPublishedData(int year) {
    _requireYear(year);
    return switch (id) {
      CalendarId.gregory => false,
      CalendarId.persian => year >= PersianDateTime.minimumOfficialYear &&
          year <= PersianDateTime.maximumOfficialYear,
      CalendarId.islamicUmalqura => true,
    };
  }

  @override
  DateTime construct(int year, int month, int day,
      {int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0,
      bool isUtc = true}) {
    if (!isValidDate(year, month, day)) {
      throw ArgumentError('Invalid ${id.identifier} date: $year-$month-$day');
    }
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
      throw ArgumentError('Invalid clock fields');
    }
    final DateTime result = switch (id) {
      CalendarId.gregory => isUtc
          ? DateTime.utc(
              year, month, day, hour, minute, second, millisecond, microsecond)
          : DateTime(
              year, month, day, hour, minute, second, millisecond, microsecond),
      CalendarId.persian => isUtc
          ? PersianDateTime.utc(
              year, month, day, hour, minute, second, millisecond, microsecond)
          : PersianDateTime(
              year, month, day, hour, minute, second, millisecond, microsecond),
      CalendarId.islamicUmalqura => isUtc
          ? HijriDateTime.utc(
              year, month, day, hour, minute, second, millisecond, microsecond)
          : HijriDateTime(
              year, month, day, hour, minute, second, millisecond, microsecond),
    };
    if ((
          result.year,
          result.month,
          result.day,
          result.hour,
          result.minute,
          result.second,
          result.millisecond,
          result.microsecond
        ) !=
        (year, month, day, hour, minute, second, millisecond, microsecond)) {
      throw ArgumentError('Wall time normalized by the local timezone');
    }
    return result;
  }

  @override
  DateTime fromInstant(DateTime instant, {bool isUtc = true}) {
    final native = DateTime.fromMicrosecondsSinceEpoch(
        instant.microsecondsSinceEpoch,
        isUtc: isUtc);
    return switch (id) {
      CalendarId.gregory => native,
      CalendarId.persian => PersianDateTime.fromDateTime(native),
      CalendarId.islamicUmalqura => HijriDateTime.fromDateTime(native),
    };
  }

  @override
  DateTime toGregorianDay(int year, int month, int day) {
    final value = construct(year, month, day);
    return DateTime.fromMicrosecondsSinceEpoch(value.microsecondsSinceEpoch,
        isUtc: true);
  }

  @override
  CalendarFields fromGregorianDay(DateTime day) {
    if (day is GeneralDateTimeInterface) {
      throw ArgumentError(
          'fromGregorianDay requires native Gregorian fields; use fromInstant for calendar date-times');
    }
    final value = fromInstant(DateTime.utc(day.year, day.month, day.day));
    return (year: value.year, month: value.month, day: value.day);
  }
}
