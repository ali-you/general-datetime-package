import '../../general_date_time_interface.dart';
import '../../shared/calendar_field_normalization.dart';
import '../../shared/constants.dart';
import '../../shared/native_date_time.dart';
import 'hebrew_calendar_calculation.dart';

/// A midnight-based civil date and time in the fixed Hebrew calendar.
///
/// Supported years are 1..9999 (Anno Mundi). Month slots are stable: Tishri=1,
/// Adar I=6 (leap years only), Adar/Adar II=7, Nisan=8, Elul=13.
/// [monthOrdinal] is the chronological position in the current year.
/// Absent Adar I is rejected; day/clock and out-of-slot month overflow normalize.
/// Sunset-based observances are outside this civil API. Instances retain the
/// native instant and UTC/local mode, like the other calendar date-time types.
class HebrewDateTime extends DateTime
    implements GeneralDateTimeInterface<HebrewDateTime> {
  // Weekday constants returned by [weekday].
  static const int monday = DateTime.monday;
  static const int tuesday = DateTime.tuesday;
  static const int wednesday = DateTime.wednesday;
  static const int thursday = DateTime.thursday;
  static const int friday = DateTime.friday;
  static const int saturday = DateTime.saturday;
  static const int sunday = DateTime.sunday;
  static const int daysPerWeek = DateTime.daysPerWeek;

  // Stable, one-based ICU month slots. Slot 6 is skipped in common years.
  static const int tishri = 1;
  static const int cheshvan = 2;
  static const int kislev = 3;
  static const int tevet = 4;
  static const int shevat = 5;
  static const int adarI = 6;
  static const int adar = 7;
  static const int adarII = 7;
  static const int nisan = 8;
  static const int iyar = 9;
  static const int sivan = 10;
  static const int tammuz = 11;
  static const int av = 12;
  static const int elul = 13;
  static const int maximumMonthsPerYear = 13;
  static const int minimumYear = HebrewCalendarCalculation.minimumYear;
  static const int maximumYear = HebrewCalendarCalculation.maximumYear;

  static int monthsInYear(int year) =>
      HebrewCalendarCalculation.monthsInYear(year);
  static List<int> monthsOfYear(int year) =>
      HebrewCalendarCalculation.monthsOfYear(year);

  /// Absolute chronological month coordinate for navigation and differences.
  static int monthIndex(int year, int month) =>
      HebrewCalendarCalculation.monthIndex(year, month);
  int get monthOrdinal => HebrewCalendarCalculation.monthOrdinal(year, month);
  bool get isLeapMonth => month == adarI;

  static const int _microsecondsPerMillisecond = 1000;
  static const int _microsecondsPerSecond = 1000000;
  static const int _microsecondsPerMinute = 60 * _microsecondsPerSecond;
  static const int _microsecondsPerHour = 60 * _microsecondsPerMinute;

  static final DateTime _gregorianEpoch = DateTime.utc(1970)
      .add(Duration(days: HebrewCalendarCalculation.minimumDayIndex));
  static int get _supportedDayCount =>
      HebrewCalendarCalculation.maximumDayIndex -
      HebrewCalendarCalculation.minimumDayIndex +
      1;

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
  final DateTime _nativeDateTime;

  HebrewDateTime._fromResolved(_ResolvedHebrewDateTime resolved)
      : year = resolved.year,
        month = resolved.month,
        day = resolved.day,
        hour = resolved.dateTime.hour,
        minute = resolved.dateTime.minute,
        second = resolved.dateTime.second,
        millisecond = resolved.dateTime.millisecond,
        microsecond = resolved.dateTime.microsecond,
        _dayOffset = resolved.dayOffset,
        _nativeDateTime = resolved.dateTime,
        super.fromMicrosecondsSinceEpoch(
          resolved.dateTime.microsecondsSinceEpoch,
          isUtc: resolved.dateTime.isUtc,
        );

  // Keep the native split representation on JavaScript, where an aggregate
  // microsecond epoch can round even though these components remain exact.
  @override
  int get millisecondsSinceEpoch => _nativeDateTime.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _nativeDateTime.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _nativeDateTime.timeZoneName;
  @override
  Duration get timeZoneOffset => _nativeDateTime.timeZoneOffset;
  @override
  int get hashCode => _nativeDateTime.hashCode;
  @override
  bool operator ==(Object other) =>
      other is DateTime && _nativeDateTime == other;

  /// Creates a local Hebrew date, normalizing overflowing components in
  /// the same style as [DateTime.new].
  factory HebrewDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return HebrewDateTime._fromResolved(
      _resolveHebrewFields(
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

  /// Converts a native Gregorian [dateTime] to Hebrew without losing its
  /// instant, precision, or UTC/local representation.
  factory HebrewDateTime.fromDateTime(DateTime dateTime) {
    return HebrewDateTime._fromResolved(
      _resolveDateTime(_nativeCopy(dateTime)),
    );
  }

  /// The current local date and time in Hebrew.
  factory HebrewDateTime.now() => HebrewDateTime.fromDateTime(DateTime.now());

  /// The current UTC date and time in Hebrew.
  factory HebrewDateTime.timestamp() =>
      HebrewDateTime.fromDateTime(DateTime.timestamp());

  /// Creates a UTC Hebrew date, normalizing overflowing components in the
  /// same style as [DateTime.utc].
  factory HebrewDateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return HebrewDateTime._fromResolved(
      _resolveHebrewFields(
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

  factory HebrewDateTime.fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
  }) {
    RangeError.checkValueInInterval(
      secondsSinceEpoch,
      -Constants.maximumNativeEpochSeconds,
      Constants.maximumNativeEpochSeconds,
      'secondsSinceEpoch',
    );
    return HebrewDateTime.fromMicrosecondsSinceEpoch(
      secondsSinceEpoch * _microsecondsPerSecond,
      isUtc: isUtc,
    );
  }

  factory HebrewDateTime.fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return HebrewDateTime.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc),
    );
  }

  factory HebrewDateTime.fromMicrosecondsSinceEpoch(
    int microsecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return HebrewDateTime.fromDateTime(
      DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      ),
    );
  }

  /// Parses a Hebrew ISO-8601-like string.
  ///
  /// A trailing `Z` or numeric offset produces a UTC result. Calendar and time
  /// overflows are normalized, but the final date must remain in the supported
  /// Hebrew range.
  factory HebrewDateTime.parse(String formattedString) {
    final Match? match = Constants.parseFormat.firstMatch(formattedString);
    if (match == null || match.end != formattedString.length) {
      throw FormatException('Invalid Hebrew date format', formattedString);
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
        return HebrewDateTime(
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

      // Validate the resulting UTC date after applying the offset. The wall
      // date may be outside the range even when the final date is supported.
      return HebrewDateTime.utc(
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
        'Hebrew date is outside the supported Hebrew range',
        formattedString,
      );
    }
  }

  /// Parses [formattedString], returning `null` for invalid or unsupported
  /// dates.
  static HebrewDateTime? tryParse(String formattedString) {
    try {
      return HebrewDateTime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// The first supported Gregorian calendar date, in UTC.
  static DateTime get minimumGregorianDate => _gregorianEpoch;

  /// The last supported Gregorian calendar date, in UTC.
  static DateTime get maximumGregorianDate =>
      minimumGregorianDate.add(Duration(days: _supportedDayCount - 1));

  /// Whether the Gregorian wall date of [dateTime] is within this
  /// implementation's supported range.
  static bool isSupportedDateTime(DateTime dateTime) {
    final DateTime nativeDateTime = _nativeCopy(dateTime);
    final int offset = _gregorianDayOffset(nativeDateTime);
    return offset >= 0 && offset < _supportedDayCount;
  }

  /// Whether [year], [month], and [day] form a strict (non-normalized)
  /// supported Hebrew date.
  static bool isValidDate(int year, int month, int day) =>
      HebrewCalendarCalculation.isValidDate(year, month, day);

  static int daysInMonth(int year, int month) =>
      HebrewCalendarCalculation.daysInMonth(year, month);

  /// The calendar name.
  @override
  String get name => 'Hebrew';

  /// Weekday using [DateTime.monday] through [DateTime.sunday].
  @override
  int get weekday => toDateTime().weekday;

  /// Length of this Hebrew month.
  @override
  int get monthLength => daysInMonth(year, month);

  /// One-based day within the Hebrew year.
  @override
  int get dayOfYear => _monthStartDay(year, month) + day;

  /// Number of days in this Hebrew year.
  int get yearLength => _yearLength(year);

  /// Whether this year contains the intercalary month Adar I.
  @override
  bool get isLeapYear => HebrewCalendarCalculation.isLeapYear(year);

  /// This fixed arithmetic calendar does not use published annual tables.
  bool get hasOfficialCalendarData => false;

  /// Gregorian Julian day number for this calendar date.
  @override
  int get julianDay =>
      HebrewCalendarCalculation.minimumDayIndex + 2440588 + _dayOffset;

  /// Converts this value to a native Gregorian [DateTime].
  @override
  DateTime toDateTime() => _nativeDateTime;

  /// Adds an exact duration and converts the resulting instant to Hebrew.
  @override
  HebrewDateTime add(Duration duration) =>
      HebrewDateTime.fromDateTime(toDateTime().add(duration));

  /// Subtracts an exact duration and converts the resulting instant to
  /// Hebrew.
  @override
  HebrewDateTime subtract(Duration duration) =>
      HebrewDateTime.fromDateTime(toDateTime().subtract(duration));

  /// Converts this instant to local time.
  @override
  HebrewDateTime toLocal() =>
      isUtc ? HebrewDateTime.fromDateTime(toDateTime().toLocal()) : this;

  /// Converts this instant to UTC.
  @override
  HebrewDateTime toUtc() =>
      isUtc ? this : HebrewDateTime.fromDateTime(toDateTime().toUtc());

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

  /// Unix seconds, rounded down from the precise native instant.
  ///
  /// This is the second containing the instant, independent of time zone.
  /// For example, -1 microsecond maps to -1 second, not zero.
  @override
  int get secondsSinceEpoch {
    final millis = floorEpochMilliseconds(_nativeDateTime);
    final seconds = millis ~/ Duration.millisecondsPerSecond;
    return millis.remainder(Duration.millisecondsPerSecond) < 0
        ? seconds - 1
        : seconds;
  }

  /// Creates a copy with selected Hebrew wall-clock fields replaced.
  ///
  /// This shadows Dart's [DateTimeCopyWith.copyWith] extension only when the
  /// receiver is statically typed as [HebrewDateTime]. For a [DateTime]-typed
  /// receiver use `CalendarDateUtils.copyWith` from the package's public library;
  /// Dart's extension otherwise reconstructs a Gregorian date from Hebrew fields.
  HebrewDateTime copyWith({
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
        ? HebrewDateTime.utc(
            fields[0],
            fields[1],
            fields[2],
            fields[3],
            fields[4],
            fields[5],
            fields[6],
            fields[7],
          )
        : HebrewDateTime(
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

  /// Returns an ISO-like string with Hebrew fields, not Gregorian.
  ///
  /// A native `DateTime.parse` or backend timestamp parser will misinterpret
  /// the year. `toUtc()` retains this calendar-specific output. For storage use
  /// `CalendarInstant.fromDateTime(this).toJson()` from the public library, or
  /// `toDateTime().toUtc().toIso8601String()` for a native Gregorian timestamp.
  /// Only [HebrewDateTime.parse] should consume this untagged calendar string.
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

  static _ResolvedHebrewDateTime _resolveHebrewFields(
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
    final resolvedMonth = HebrewCalendarCalculation.resolveMonth(year, month);
    final monthStartOffset =
        resolvedMonth.start - HebrewCalendarCalculation.minimumDayIndex;

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

  static _ResolvedHebrewDateTime _resolveDateTime(DateTime dateTime) {
    final int dayOffset = _gregorianDayOffset(dateTime);
    _requireSupportedDayOffset(dayOffset);

    final fields = HebrewCalendarCalculation.fromDayIndex(
        dayOffset + HebrewCalendarCalculation.minimumDayIndex);

    return _ResolvedHebrewDateTime(
      dateTime: dateTime,
      year: fields.year,
      month: fields.month,
      day: fields.day,
      dayOffset: dayOffset,
    );
  }

  static DateTime _nativeCopy(DateTime dateTime) =>
      copyNativeDateTime(dateTime);

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

  static int _monthStartDay(int year, int month) =>
      HebrewCalendarCalculation.monthStartDayIndex(year, month) -
      HebrewCalendarCalculation.yearStartDayIndex(year);

  static int _yearLength(int year) =>
      HebrewCalendarCalculation.yearLength(year);

  static void _requireSupportedDayOffset(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= _supportedDayCount) {
      throw RangeError(
        'Date is outside the supported Hebrew range '
        '(AM $minimumYear-01-01 through AM $maximumYear-13-'
        '${daysInMonth(maximumYear, 13)})',
      );
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _threeDigits(int value) => value.toString().padLeft(3, '0');

  static String _fourDigits(int value) => value.toString().padLeft(4, '0');
}

final class _ResolvedHebrewDateTime {
  const _ResolvedHebrewDateTime({
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
