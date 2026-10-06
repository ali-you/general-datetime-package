import '../../general_date_time_interface.dart';
import '../../shared/calendar_field_normalization.dart';
import '../../shared/constants.dart';
import 'iranian_calendar_data.dart';
import 'persian_calendar_calculation.dart';

/// A date and time in the Solar Hijri (Persian) calendar.
///
/// The Iranian calendar is determined astronomically, not by an indefinitely
/// repeating arithmetic leap-year cycle. This implementation is therefore
/// data-backed by the official University of Tehran Calendar Center table for
/// [minimumOfficialYear] through [maximumOfficialYear]. Outside those years,
/// Borkowski's break-year model extends support to [minimumYear] through
/// [maximumYear]. Calculated dates are not guaranteed official civil dates.
/// Dates beyond the calculation's finite range throw [RangeError].
///
/// Instances retain the exact native [DateTime] instant internally. Calendar
/// fields such as [year], [month], and [day] are exposed in Solar Hijri, while
/// epoch values, equality, time-zone data, and comparisons use the true
/// Gregorian instant.
class PersianDateTime extends DateTime
    implements GeneralDateTimeInterface<PersianDateTime> {
  // Weekday constants returned by [weekday].
  static const int monday = DateTime.monday;
  static const int tuesday = DateTime.tuesday;
  static const int wednesday = DateTime.wednesday;
  static const int thursday = DateTime.thursday;
  static const int friday = DateTime.friday;
  static const int saturday = DateTime.saturday;
  static const int sunday = DateTime.sunday;
  static const int daysPerWeek = DateTime.daysPerWeek;

  // Month constants returned by [month].
  static const int farvardin = 1;
  static const int ordibehesht = 2;
  static const int khordad = 3;
  static const int tir = 4;
  static const int mordad = 5;
  static const int shahrivar = 6;
  static const int mehr = 7;
  static const int aban = 8;
  static const int azar = 9;
  static const int dey = 10;
  static const int bahman = 11;
  static const int esfand = 12;
  static const int monthsPerYear = 12;

  /// First Solar Hijri year supported by the calculation model.
  static const int minimumYear = PersianCalendarCalculation.minimumYear;

  /// Last Solar Hijri year supported by the calculation model.
  static const int maximumYear = PersianCalendarCalculation.maximumYear;

  /// First Solar Hijri year covered by the official source table.
  static const int minimumOfficialYear = IranianCalendarData.minimumYear;

  /// Last Solar Hijri year covered by the official source table.
  static const int maximumOfficialYear = IranianCalendarData.maximumYear;

  static const int _microsecondsPerMillisecond = 1000;
  static const int _microsecondsPerSecond = 1000000;
  static const int _microsecondsPerMinute = 60 * _microsecondsPerSecond;
  static const int _microsecondsPerHour = 60 * _microsecondsPerMinute;

  static final DateTime _gregorianEpoch = DateTime.utc(
    IranianCalendarData.epochGregorianYear,
    IranianCalendarData.epochGregorianMonth,
    IranianCalendarData.epochGregorianDay,
  ).subtract(Duration(days: _yearStartDays[minimumOfficialYear - minimumYear]));

  static final int _epochJulianDay = IranianCalendarData.epochJulianDay -
      _yearStartDays[minimumOfficialYear - minimumYear];

  /// Cumulative days at the start of each supported year, plus an end
  /// sentinel after [maximumYear].
  static final List<int> _yearStartDays = _buildYearStartDays();

  static int get _supportedDayCount => _yearStartDays.last;

  @override
  final int year;

  @override
  final int month;

  @override
  final int day;

  @override
  final int hour;

  @override
  final int minute;

  @override
  final int second;

  @override
  final int millisecond;

  @override
  final int microsecond;

  final int _dayOffset;

  PersianDateTime._fromResolved(_ResolvedPersianDateTime resolved)
      : year = resolved.year,
        month = resolved.month,
        day = resolved.day,
        hour = resolved.dateTime.hour,
        minute = resolved.dateTime.minute,
        second = resolved.dateTime.second,
        millisecond = resolved.dateTime.millisecond,
        microsecond = resolved.dateTime.microsecond,
        _dayOffset = resolved.dayOffset,
        super.fromMicrosecondsSinceEpoch(
          resolved.dateTime.microsecondsSinceEpoch,
          isUtc: resolved.dateTime.isUtc,
        );

  /// Creates a local Solar Hijri date, normalizing overflowing components in
  /// the same style as [DateTime.new].
  factory PersianDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return PersianDateTime._fromResolved(
      _resolvePersianFields(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
        isUtc: false,
      ),
    );
  }

  /// Converts a native Gregorian [dateTime] to Solar Hijri without losing its
  /// instant, precision, or UTC/local representation.
  factory PersianDateTime.fromDateTime(DateTime dateTime) {
    return PersianDateTime._fromResolved(
      _resolveDateTime(_nativeCopy(dateTime)),
    );
  }

  /// The current local date and time in Solar Hijri.
  factory PersianDateTime.now() => PersianDateTime.fromDateTime(DateTime.now());

  /// The current UTC date and time in Solar Hijri.
  factory PersianDateTime.timestamp() =>
      PersianDateTime.fromDateTime(DateTime.timestamp());

  /// Creates a UTC Solar Hijri date, normalizing overflowing components in
  /// the same style as [DateTime.utc].
  factory PersianDateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return PersianDateTime._fromResolved(
      _resolvePersianFields(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
        isUtc: true,
      ),
    );
  }

  factory PersianDateTime.fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
  }) {
    RangeError.checkValueInInterval(
      secondsSinceEpoch,
      -Constants.maximumNativeEpochSeconds,
      Constants.maximumNativeEpochSeconds,
      'secondsSinceEpoch',
    );
    return PersianDateTime.fromMicrosecondsSinceEpoch(
      secondsSinceEpoch * _microsecondsPerSecond,
      isUtc: isUtc,
    );
  }

  factory PersianDateTime.fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return PersianDateTime.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc),
    );
  }

  factory PersianDateTime.fromMicrosecondsSinceEpoch(
    int microsecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return PersianDateTime.fromDateTime(
      DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      ),
    );
  }

  /// Parses a Solar Hijri ISO-8601-like string.
  ///
  /// A trailing `Z` or numeric offset produces a UTC result. Calendar and time
  /// overflows are normalized, but the final date must remain in the
  /// supported range.
  factory PersianDateTime.parse(String formattedString) {
    final Match? match = Constants.parseFormat.firstMatch(formattedString);
    if (match == null) {
      throw FormatException('Invalid Persian date format', formattedString);
    }

    int parseIntOrZero(String? value) => value == null ? 0 : int.parse(value);

    int parseFraction(String? value) {
      if (value == null) return 0;
      int result = 0;
      for (int index = 0; index < 6; index++) {
        result *= 10;
        if (index < value.length) {
          result += value.codeUnitAt(index) ^ 0x30;
        }
      }
      return result;
    }

    try {
      final int year = int.parse(match[1]!);
      final int month = int.parse(match[2]!);
      final int day = int.parse(match[3]!);
      final int hour = parseIntOrZero(match[4]);
      final int minute = parseIntOrZero(match[5]);
      final int second = parseIntOrZero(match[6]);
      final int fraction = parseFraction(match[7]);
      final int millisecond = fraction ~/ _microsecondsPerMillisecond;
      final int microsecond = fraction % _microsecondsPerMillisecond;

      if (match[8] == null) {
        return PersianDateTime(
          year,
          month,
          day,
          hour,
          minute,
          second,
          millisecond,
          microsecond,
        );
      }

      final String? signText = match[9];
      int offsetMinutes = 0;
      if (signText != null) {
        final int offsetHour = int.parse(match[10]!);
        final int offsetMinute = parseIntOrZero(match[11]);
        if (offsetHour > 23 || offsetMinute > 59) {
          throw const FormatException('Invalid time-zone offset');
        }
        final int sign = signText == '-' ? -1 : 1;
        offsetMinutes = sign * (offsetHour * 60 + offsetMinute);
      }

      // Apply the offset before checking the supported range: the wall date
      // can lie outside the table while its resulting UTC date is supported.
      return PersianDateTime.utc(
        year,
        month,
        day,
        hour,
        minute - offsetMinutes,
        second,
        millisecond,
        microsecond,
      );
    } on RangeError {
      throw FormatException(
        'Persian date is outside the supported range',
        formattedString,
      );
    }
  }

  /// Parses [formattedString], returning `null` for invalid or unsupported
  /// dates.
  static PersianDateTime? tryParse(String formattedString) {
    try {
      return PersianDateTime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// The first supported Gregorian calendar date, in UTC.
  static DateTime get minimumGregorianDate => _gregorianEpoch;

  /// The last supported Gregorian calendar date, in UTC.
  static DateTime get maximumGregorianDate =>
      minimumGregorianDate.add(Duration(days: _supportedDayCount - 1));

  /// Whether the Gregorian wall date of [dateTime] is within the
  /// supported range.
  static bool isSupportedDateTime(DateTime dateTime) {
    final DateTime nativeDateTime = _nativeCopy(dateTime);
    final int offset = _gregorianDayOffset(nativeDateTime);
    return offset >= 0 && offset < _supportedDayCount;
  }

  /// Whether [year], [month], and [day] form a strict (non-normalized)
  /// supported Solar Hijri date.
  static bool isValidDate(int year, int month, int day) {
    if (year < minimumYear || year > maximumYear) return false;
    if (month < 1 || month > monthsPerYear) return false;
    return day >= 1 && day <= daysInMonth(year, month);
  }

  /// Returns the calendar length of [month] in [year].
  static int daysInMonth(int year, int month) {
    _requireSupportedYear(year);
    RangeError.checkValueInInterval(month, 1, monthsPerYear, 'month');
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return PersianCalendarCalculation.isLeapYear(year) ? 30 : 29;
  }

  /// The calendar name.
  @override
  String get name => 'Persian';

  /// Weekday using [DateTime.monday] through [DateTime.sunday].
  @override
  int get weekday => toDateTime().weekday;

  /// Calendar length of this Solar Hijri month.
  @override
  int get monthLength => daysInMonth(year, month);

  /// One-based day within the Solar Hijri year.
  @override
  int get dayOfYear => _monthStartDay(year, month) + day;

  /// Number of days in this Solar Hijri year.
  int get yearLength => _yearLength(year);

  /// Whether this Solar Hijri year contains 366 days.
  @override
  bool get isLeapYear => PersianCalendarCalculation.isLeapYear(year);

  /// Whether this year uses the published official calendar table.
  bool get hasOfficialCalendarData =>
      year >= minimumOfficialYear && year <= maximumOfficialYear;

  /// Gregorian Julian day number for this calendar date.
  @override
  int get julianDay => _epochJulianDay + _dayOffset;

  /// Converts this value to a native Gregorian [DateTime].
  @override
  DateTime toDateTime() => DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      );

  /// Adds an exact duration and converts the resulting instant to Solar Hijri.
  @override
  PersianDateTime add(Duration duration) =>
      PersianDateTime.fromDateTime(toDateTime().add(duration));

  /// Subtracts an exact duration and converts the resulting instant to Solar
  /// Hijri.
  @override
  PersianDateTime subtract(Duration duration) =>
      PersianDateTime.fromDateTime(toDateTime().subtract(duration));

  /// Converts this instant to local time.
  @override
  PersianDateTime toLocal() =>
      isUtc ? PersianDateTime.fromDateTime(toDateTime().toLocal()) : this;

  /// Converts this instant to UTC.
  @override
  PersianDateTime toUtc() =>
      isUtc ? this : PersianDateTime.fromDateTime(toDateTime().toUtc());

  @override
  int compareTo(DateTime other) =>
      toDateTime().compareTo(_nativeComparisonValue(other));

  @override
  bool isBefore(DateTime other) =>
      toDateTime().isBefore(_nativeComparisonValue(other));

  @override
  bool isAfter(DateTime other) =>
      toDateTime().isAfter(_nativeComparisonValue(other));

  @override
  bool isAtSameMomentAs(DateTime other) =>
      toDateTime().isAtSameMomentAs(_nativeComparisonValue(other));

  @override
  Duration difference(DateTime other) =>
      toDateTime().difference(_nativeComparisonValue(other));

  /// Unix seconds, rounded down directly from [microsecondsSinceEpoch].
  ///
  /// This is the second containing the instant, independent of time zone.
  /// For example, -1 microsecond maps to -1 second, not zero.
  @override
  int get secondsSinceEpoch {
    final micros = microsecondsSinceEpoch;
    final seconds = micros ~/ Duration.microsecondsPerSecond;
    return micros.remainder(Duration.microsecondsPerSecond) < 0
        ? seconds - 1
        : seconds;
  }

  /// Creates a copy with selected Solar Hijri wall-clock fields replaced.
  ///
  /// This shadows Dart's [DateTimeCopyWith.copyWith] extension only when the
  /// receiver is statically typed as [PersianDateTime]. For a [DateTime]-typed
  /// receiver use `CalendarDateUtils.copyWith` from the package's public library;
  /// Dart's extension otherwise reconstructs a Gregorian date from Persian fields.
  PersianDateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool? isUtc,
  }) {
    final bool resultIsUtc = isUtc ?? this.isUtc;
    final List<int> fields = <int>[
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    ];
    return resultIsUtc
        ? PersianDateTime.utc(
            fields[0],
            fields[1],
            fields[2],
            fields[3],
            fields[4],
            fields[5],
            fields[6],
            fields[7],
          )
        : PersianDateTime(
            fields[0],
            fields[1],
            fields[2],
            fields[3],
            fields[4],
            fields[5],
            fields[6],
            fields[7],
          );
  }

  @override
  String toString() => _formatIso8601(separator: ' ');

  /// Returns an ISO-like string with Persian calendar fields, not Gregorian.
  ///
  /// A native `DateTime.parse` or backend timestamp parser will misinterpret
  /// the year. `toUtc()` retains this calendar-specific output. For storage use
  /// `CalendarInstant.fromDateTime(this).toJson()` from the public library, or
  /// `toDateTime().toUtc().toIso8601String()` for a native Gregorian timestamp.
  /// Only [PersianDateTime.parse] should consume this untagged calendar string.
  @override
  String toIso8601String() => _formatIso8601(separator: 'T');

  String _formatIso8601({required String separator}) {
    final String fraction = microsecond == 0
        ? _threeDigits(millisecond)
        : '${_threeDigits(millisecond)}${_threeDigits(microsecond)}';
    return '${_fourDigits(year)}-${_twoDigits(month)}-${_twoDigits(day)}'
        '$separator${_twoDigits(hour)}:${_twoDigits(minute)}:'
        '${_twoDigits(second)}.$fraction${isUtc ? 'Z' : ''}';
  }

  static _ResolvedPersianDateTime _resolvePersianFields(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
    int millisecond,
    int microsecond, {
    required bool isUtc,
  }) {
    final (normalizedYear, normalizedMonth) =
        normalizeCalendarMonth(year, month, minimumYear, maximumYear);

    // Keep the end sentinel available during normalization. For example,
    // (maximumYear + 1)-01-00 denotes the final supported calendar day.
    final int monthStartOffset;
    if (normalizedYear == maximumYear + 1 && normalizedMonth == 1) {
      monthStartOffset = _supportedDayCount;
    } else {
      _requireSupportedYear(normalizedYear);
      monthStartOffset = _yearStartDays[normalizedYear - minimumYear] +
          _monthStartDay(normalizedYear, normalizedMonth);
    }

    final (dayOffset, clockMicroseconds) = normalizeCalendarTime(
      monthStartOffset,
      _supportedDayCount,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
    _requireSupportedDayOffset(dayOffset);

    int remaining = clockMicroseconds;
    final int normalizedHour = remaining ~/ _microsecondsPerHour;
    remaining %= _microsecondsPerHour;
    final int normalizedMinute = remaining ~/ _microsecondsPerMinute;
    remaining %= _microsecondsPerMinute;
    final int normalizedSecond = remaining ~/ _microsecondsPerSecond;
    remaining %= _microsecondsPerSecond;
    final int normalizedMillisecond = remaining ~/ _microsecondsPerMillisecond;
    final int normalizedMicrosecond = remaining % _microsecondsPerMillisecond;

    final DateTime gregorianDate = _gregorianEpoch.add(
      Duration(days: dayOffset),
    );
    final DateTime dateTime = isUtc
        ? DateTime.utc(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
            normalizedHour,
            normalizedMinute,
            normalizedSecond,
            normalizedMillisecond,
            normalizedMicrosecond,
          )
        : DateTime(
            gregorianDate.year,
            gregorianDate.month,
            gregorianDate.day,
            normalizedHour,
            normalizedMinute,
            normalizedSecond,
            normalizedMillisecond,
            normalizedMicrosecond,
          );

    // Resolve once more from native wall fields. This preserves DateTime's
    // behavior for local times changed by daylight-saving transitions.
    return _resolveDateTime(dateTime);
  }

  static _ResolvedPersianDateTime _resolveDateTime(DateTime dateTime) {
    final int dayOffset = _gregorianDayOffset(dateTime);
    _requireSupportedDayOffset(dayOffset);

    int low = 0;
    int high = maximumYear - minimumYear + 1;
    while (low < high) {
      final int middle = (low + high) >> 1;
      if (_yearStartDays[middle + 1] <= dayOffset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    final int year = minimumYear + low;
    final int dayWithinYear = dayOffset - _yearStartDays[low];
    final int month;
    final int day;
    if (dayWithinYear < 6 * 31) {
      month = dayWithinYear ~/ 31 + 1;
      day = dayWithinYear % 31 + 1;
    } else {
      final int dayWithinSecondHalf = dayWithinYear - 6 * 31;
      month = dayWithinSecondHalf ~/ 30 + 7;
      day = dayWithinSecondHalf % 30 + 1;
    }

    return _ResolvedPersianDateTime(
      dateTime: dateTime,
      year: year,
      month: month,
      day: day,
      dayOffset: dayOffset,
    );
  }

  static DateTime _nativeCopy(DateTime dateTime) =>
      DateTime.fromMicrosecondsSinceEpoch(
        dateTime.microsecondsSinceEpoch,
        isUtc: dateTime.isUtc,
      );

  static DateTime _nativeComparisonValue(DateTime dateTime) {
    if (dateTime case final GeneralDateTimeInterface customDateTime) {
      return customDateTime.toDateTime();
    }
    return dateTime;
  }

  static int _gregorianDayOffset(DateTime dateTime) => DateTime.utc(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      ).difference(_gregorianEpoch).inDays;

  static int _monthStartDay(int year, int month) {
    if (month <= 6) return (month - 1) * 31;
    return 6 * 31 + (month - 7) * 30;
  }

  static int _yearLength(int year) {
    _requireSupportedYear(year);
    return PersianCalendarCalculation.isLeapYear(year) ? 366 : 365;
  }

  static List<int> _buildYearStartDays() {
    final List<int> starts = <int>[0];
    int cumulativeDays = 0;
    for (int year = minimumYear; year <= maximumYear; year++) {
      cumulativeDays += PersianCalendarCalculation.isLeapYear(year) ? 366 : 365;
      starts.add(cumulativeDays);
    }
    return List<int>.unmodifiable(starts);
  }

  static void _requireSupportedYear(int year) {
    if (year < minimumYear || year > maximumYear) {
      throw RangeError.range(
        year,
        minimumYear,
        maximumYear,
        'year',
        'Persian calendar calculation is available only for Solar Hijri '
            '$minimumYear through $maximumYear',
      );
    }
  }

  static void _requireSupportedDayOffset(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= _supportedDayCount) {
      throw RangeError(
        'Date is outside the supported Persian calendar range '
        '($minimumYear-01-01 through $maximumYear-12-'
        '${daysInMonth(maximumYear, 12)})',
      );
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _threeDigits(int value) => value.toString().padLeft(3, '0');

  static String _fourDigits(int value) =>
      '${value < 0 ? '-' : ''}${value.abs().toString().padLeft(4, '0')}';
}

final class _ResolvedPersianDateTime {
  const _ResolvedPersianDateTime({
    required this.dateTime,
    required this.year,
    required this.month,
    required this.day,
    required this.dayOffset,
  });

  final DateTime dateTime;
  final int year;
  final int month;
  final int day;
  final int dayOffset;
}
