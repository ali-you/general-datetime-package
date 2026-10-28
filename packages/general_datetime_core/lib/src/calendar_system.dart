import 'calendars/chinese/chinese_date_time.dart';
import 'calendars/hebrew/hebrew_date_time.dart';
import 'shared/native_date_time.dart';
import 'calendar_serialization.dart';
import 'general_date_time_interface.dart';
import 'calendars/hijri/hijri_date_time.dart';
import 'calendars/persian/persian_date_time.dart';

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

  /// Same instant in UTC or host local mode, exposed in this calendar.
  DateTime fromInstant(DateTime instant, {bool isUtc = true});
}

/// Immutable built-in registry. Chinese months are chronological ordinals;
/// Hebrew uses stable slots. Always enumerate months with [monthsOfYear].
abstract final class CalendarSystems {
  static const chinese = _BuiltInCalendarSystem(CalendarId.chinese);
  static const hebrew = _BuiltInCalendarSystem(CalendarId.hebrew);
  static const gregorian = _BuiltInCalendarSystem(CalendarId.gregory);
  static const persian = _BuiltInCalendarSystem(CalendarId.persian);
  static const ummAlQura = _BuiltInCalendarSystem(CalendarId.islamicUmalqura);

  /// Valid month slots in chronological order, including intercalary months.
  static List<int> monthsOfYear(CalendarId id, int year) {
    if (id == CalendarId.chinese) return ChineseDateTime.monthsOfYear(year);
    if (id == CalendarId.hebrew) return HebrewDateTime.monthsOfYear(year);
    forId(id).daysInYear(year);
    return List<int>.unmodifiable(List.generate(12, (i) => i + 1));
  }

  static CalendarSystem forId(CalendarId id) => switch (id) {
        CalendarId.chinese => chinese,
        CalendarId.hebrew => hebrew,
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
        CalendarId.chinese => 'dotnet10-1901-2099-v1',
        CalendarId.hebrew => 'fixed-hebrew-icu78.3-v1',
        CalendarId.gregory => 'proleptic-gregorian-v1',
        CalendarId.persian => 'tehran-1206-1498-borkowski-v1',
        CalendarId.islamicUmalqura => 'icu-openjdk21-1300-1600-v1',
      };
  @override
  String get calculationPolicy => switch (id) {
        CalendarId.chinese =>
          '.NET Chinese civil tables; related Gregorian years 1901-2099; ordinal months; no fallback.',
        CalendarId.hebrew =>
          'Fixed Hebrew arithmetic; midnight civil days; AM 1–9999.',
        CalendarId.gregory => 'Proleptic Gregorian; Dart UTC date bounds.',
        CalendarId.persian => 'Published Tehran leap data for 1206–1498; '
            'finite Borkowski calculation elsewhere.',
        CalendarId.islamicUmalqura => 'Finite Umm al-Qura table; no fallback.',
      };
  @override
  CalendarFields get minimumDate => switch (id) {
        CalendarId.chinese => (
            year: ChineseDateTime.minimumYear,
            month: 1,
            day: 1
          ),
        CalendarId.hebrew => (
            year: HebrewDateTime.minimumYear,
            month: 1,
            day: 1
          ),
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
        CalendarId.chinese => (
            year: ChineseDateTime.maximumYear,
            month: ChineseDateTime.monthsInYear(ChineseDateTime.maximumYear),
            day: ChineseDateTime.daysInMonth(ChineseDateTime.maximumYear,
                ChineseDateTime.monthsInYear(ChineseDateTime.maximumYear))
          ),
        CalendarId.hebrew => (
            year: HebrewDateTime.maximumYear,
            month: 13,
            day: 29
          ),
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
    if (id == CalendarId.chinese) {
      return ChineseDateTime.isValidDate(year, month, day);
    }
    if (id == CalendarId.hebrew) {
      return HebrewDateTime.isValidDate(year, month, day);
    }
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
    if (id == CalendarId.chinese) {
      return ChineseDateTime.daysInMonth(year, month);
    }
    if (id == CalendarId.hebrew) return HebrewDateTime.daysInMonth(year, month);
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
  int daysInYear(int year) {
    _requireYear(year);
    final months = id == CalendarId.chinese
        ? ChineseDateTime.monthsOfYear(year)
        : id == CalendarId.hebrew
            ? HebrewDateTime.monthsOfYear(year)
            : List.generate(12, (i) => i + 1);
    return months.fold(0, (total, month) => total + daysInMonth(year, month));
  }

  @override
  bool hasPublishedData(int year) {
    _requireYear(year);
    return switch (id) {
      CalendarId.chinese => false,
      CalendarId.hebrew => false,
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
      CalendarId.chinese => isUtc
          ? ChineseDateTime.utc(
              year, month, day, hour, minute, second, millisecond, microsecond)
          : ChineseDateTime(
              year, month, day, hour, minute, second, millisecond, microsecond),
      CalendarId.hebrew => isUtc
          ? HebrewDateTime.utc(
              year, month, day, hour, minute, second, millisecond, microsecond)
          : HebrewDateTime(
              year, month, day, hour, minute, second, millisecond, microsecond),
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
    final native = copyNativeDateTime(instant, isUtc: isUtc);
    return switch (id) {
      CalendarId.chinese => ChineseDateTime.fromDateTime(native),
      CalendarId.hebrew => HebrewDateTime.fromDateTime(native),
      CalendarId.gregory => native,
      CalendarId.persian => PersianDateTime.fromDateTime(native),
      CalendarId.islamicUmalqura => HijriDateTime.fromDateTime(native),
    };
  }

  @override
  DateTime toGregorianDay(int year, int month, int day) {
    final value = construct(year, month, day);
    return copyNativeDateTime(value, isUtc: true);
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
