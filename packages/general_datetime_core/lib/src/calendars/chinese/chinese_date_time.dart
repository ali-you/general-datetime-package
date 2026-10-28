import '../../general_date_time_interface.dart';
import '../../shared/calendar_field_normalization.dart';
import '../../shared/constants.dart';
import '../../shared/native_date_time.dart';
import 'chinese_calendar_calculation.dart';

/// A Chinese civil date-time backed by the bounded .NET conversion tables.
///
/// Years 1901..2099 identify the Gregorian year containing lunar New Year.
/// [month] is a chronological ordinal, 1..12 or 1..13. Use [lunarMonth],
/// [isLeapMonth], and [monthCode] for traditional month identity, and
/// [ChineseDateTime.fromLunar] to construct using that identity. Days start at
/// midnight; conversion retains the instant and UTC/local wall-clock mode.
/// The .NET chronology does not resolve event timezones or compute astronomy.
class ChineseDateTime extends DateTime
    implements GeneralDateTimeInterface<ChineseDateTime> {
  // Weekday constants returned by [weekday].
  static const int monday = DateTime.monday;
  static const int tuesday = DateTime.tuesday;
  static const int wednesday = DateTime.wednesday;
  static const int thursday = DateTime.thursday;
  static const int friday = DateTime.friday;
  static const int saturday = DateTime.saturday;
  static const int sunday = DateTime.sunday;
  static const int daysPerWeek = DateTime.daysPerWeek;

  static const int maximumMonthsPerYear = 13;
  static const int minimumYear = ChineseCalendarCalculation.minimumYear;
  static const int maximumYear = ChineseCalendarCalculation.maximumYear;
  static int monthsInYear(int year) =>
      ChineseCalendarCalculation.monthsInYear(year);
  static List<int> monthsOfYear(int year) =>
      ChineseCalendarCalculation.monthsOfYear(year);
  static int monthIndex(int year, int month) =>
      ChineseCalendarCalculation.monthIndex(year, month);
  static int leapMonthOfYear(int year) =>
      ChineseCalendarCalculation.leapMonth(year);
  static int ordinalMonth(int year, int lunarMonth,
          {bool isLeapMonth = false}) =>
      ChineseCalendarCalculation.monthForLunar(year, lunarMonth,
          isLeapMonth: isLeapMonth);
  int get monthOrdinal => month;
  int get lunarMonth => ChineseCalendarCalculation.lunarMonth(year, month);
  bool get isLeapMonth => ChineseCalendarCalculation.isLeapMonth(year, month);
  String get monthCode => 'M${_twoDigits(lunarMonth)}${isLeapMonth ? 'L' : ''}';

  /// Construct using a traditional numbered month and explicit leap identity.
  /// Missing leap months and invalid civil/clock fields are rejected.
  factory ChineseDateTime.fromLunar(
      {required int year,
      required int lunarMonth,
      required int day,
      bool isLeapMonth = false,
      bool isUtc = false,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0}) {
    final month = ordinalMonth(year, lunarMonth, isLeapMonth: isLeapMonth);
    if (!isValidDate(year, month, day) ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59 ||
        millisecond < 0 ||
        millisecond > 999 ||
        microsecond < 0 ||
        microsecond > 999) {
      throw ArgumentError('Invalid Chinese civil or clock fields');
    }
    return isUtc
        ? ChineseDateTime.utc(
            year, month, day, hour, minute, second, millisecond, microsecond)
        : ChineseDateTime(
            year, month, day, hour, minute, second, millisecond, microsecond);
  }

  static const int _microsecondsPerMillisecond = 1000;
  static const int _microsecondsPerSecond = 1000000;
  static const int _microsecondsPerMinute = 60 * _microsecondsPerSecond;
  static const int _microsecondsPerHour = 60 * _microsecondsPerMinute;

  static final DateTime _gregorianEpoch = DateTime.utc(1970)
      .add(Duration(days: ChineseCalendarCalculation.minimumDayIndex));
  static int get _supportedDayCount =>
      ChineseCalendarCalculation.maximumDayIndex -
      ChineseCalendarCalculation.minimumDayIndex +
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

  ChineseDateTime._fromResolved(_ResolvedChineseDateTime resolved)
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

  /// Creates a local Chinese date, normalizing overflowing components in
  /// the same style as [DateTime.new].
  factory ChineseDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return ChineseDateTime._fromResolved(
      _resolveChineseFields(
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

  /// Converts a native Gregorian [dateTime] to Chinese without losing its
  /// instant, precision, or UTC/local representation.
  factory ChineseDateTime.fromDateTime(DateTime dateTime) {
    return ChineseDateTime._fromResolved(
      _resolveDateTime(_nativeCopy(dateTime)),
    );
  }

  /// The current local date and time in Chinese.
  factory ChineseDateTime.now() => ChineseDateTime.fromDateTime(DateTime.now());

  /// The current UTC date and time in Chinese.
  factory ChineseDateTime.timestamp() =>
      ChineseDateTime.fromDateTime(DateTime.timestamp());

  /// Creates a UTC Chinese date, normalizing overflowing components in the
  /// same style as [DateTime.utc].
  factory ChineseDateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return ChineseDateTime._fromResolved(
      _resolveChineseFields(
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

  factory ChineseDateTime.fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
  }) {
    RangeError.checkValueInInterval(
      secondsSinceEpoch,
      -Constants.maximumNativeEpochSeconds,
      Constants.maximumNativeEpochSeconds,
      'secondsSinceEpoch',
    );
    return ChineseDateTime.fromMicrosecondsSinceEpoch(
      secondsSinceEpoch * _microsecondsPerSecond,
      isUtc: isUtc,
    );
  }

  factory ChineseDateTime.fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return ChineseDateTime.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc),
    );
  }

  factory ChineseDateTime.fromMicrosecondsSinceEpoch(
    int microsecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return ChineseDateTime.fromDateTime(
      DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      ),
    );
  }

  /// Parses a Chinese ISO-8601-like string.
  ///
  /// A trailing `Z` or numeric offset produces a UTC result. Calendar and time
  /// overflows are normalized, but the final date must remain in the supported
  /// Chinese range.
  factory ChineseDateTime.parse(String formattedString) {
    final Match? match = Constants.parseFormat.firstMatch(formattedString);
    if (match == null || match.end != formattedString.length) {
      throw FormatException('Invalid Chinese date format', formattedString);
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
        return ChineseDateTime(
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
      return ChineseDateTime.utc(
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
        'Chinese date is outside the supported Chinese range',
        formattedString,
      );
    }
  }

  /// Parses [formattedString], returning `null` for invalid or unsupported
  /// dates.
  static ChineseDateTime? tryParse(String formattedString) {
    try {
      return ChineseDateTime.parse(formattedString);
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
  /// supported Chinese date.
  static bool isValidDate(int year, int month, int day) =>
      ChineseCalendarCalculation.isValidDate(year, month, day);

  static int daysInMonth(int year, int month) =>
      ChineseCalendarCalculation.daysInMonth(year, month);

  /// The calendar name.
  @override
  String get name => 'Chinese';

  /// Weekday using [DateTime.monday] through [DateTime.sunday].
  @override
  int get weekday => toDateTime().weekday;

  /// Length of this Chinese month.
  @override
  int get monthLength => daysInMonth(year, month);

  /// One-based day within the Chinese year.
  @override
  int get dayOfYear => _monthStartDay(year, month) + day;

  /// Number of days in this Chinese year.
  int get yearLength => _yearLength(year);

  /// Whether this year contains an intercalary month.
  @override
  bool get isLeapYear => ChineseCalendarCalculation.isLeapYear(year);

  /// This chronology uses .NET tables, not official annual publications.
  bool get hasOfficialCalendarData => false;

  /// Gregorian Julian day number for this calendar date.
  @override
  int get julianDay =>
      ChineseCalendarCalculation.minimumDayIndex + 2440588 + _dayOffset;

  /// Converts this value to a native Gregorian [DateTime].
  @override
  DateTime toDateTime() => _nativeDateTime;

  /// Adds an exact duration and converts the resulting instant to Chinese.
  @override
  ChineseDateTime add(Duration duration) =>
      ChineseDateTime.fromDateTime(toDateTime().add(duration));

  /// Subtracts an exact duration and converts the resulting instant to
  /// Chinese.
  @override
  ChineseDateTime subtract(Duration duration) =>
      ChineseDateTime.fromDateTime(toDateTime().subtract(duration));

  /// Converts this instant to local time.
  @override
  ChineseDateTime toLocal() =>
      isUtc ? ChineseDateTime.fromDateTime(toDateTime().toLocal()) : this;

  /// Converts this instant to UTC.
  @override
  ChineseDateTime toUtc() =>
      isUtc ? this : ChineseDateTime.fromDateTime(toDateTime().toUtc());

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

  /// Creates a copy with selected Chinese wall-clock fields replaced.
  ///
  /// This shadows Dart's [DateTimeCopyWith.copyWith] extension only when the
  /// receiver is statically typed as [ChineseDateTime]. For a [DateTime]-typed
  /// receiver use `CalendarDateUtils.copyWith` from the package's public library;
  /// Dart's extension otherwise reconstructs a Gregorian date from Chinese fields.
  ChineseDateTime copyWith({
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
        ? ChineseDateTime.utc(
            fields[0],
            fields[1],
            fields[2],
            fields[3],
            fields[4],
            fields[5],
            fields[6],
            fields[7],
          )
        : ChineseDateTime(
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

  /// Returns an ISO-like string with Chinese fields, not Gregorian.
  ///
  /// A native `DateTime.parse` or backend timestamp parser will misinterpret
  /// the year. `toUtc()` retains this calendar-specific output. For storage use
  /// `CalendarInstant.fromDateTime(this).toJson()` from the public library, or
  /// `toDateTime().toUtc().toIso8601String()` for a native Gregorian timestamp.
  /// Only [ChineseDateTime.parse] should consume this untagged calendar string.
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

  static _ResolvedChineseDateTime _resolveChineseFields(
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
    final resolvedMonth = ChineseCalendarCalculation.resolveMonth(year, month);
    final monthStartOffset =
        resolvedMonth.start - ChineseCalendarCalculation.minimumDayIndex;

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

  static _ResolvedChineseDateTime _resolveDateTime(DateTime dateTime) {
    final int dayOffset = _gregorianDayOffset(dateTime);
    _requireSupportedDayOffset(dayOffset);

    final fields = ChineseCalendarCalculation.fromDayIndex(
        dayOffset + ChineseCalendarCalculation.minimumDayIndex);

    return _ResolvedChineseDateTime(
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
      ChineseCalendarCalculation.monthStartDayIndex(year, month) -
      ChineseCalendarCalculation.yearStartDayIndex(year);

  static int _yearLength(int year) =>
      ChineseCalendarCalculation.yearLength(year);

  static void _requireSupportedDayOffset(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= _supportedDayCount) {
      throw RangeError(
        'Date is outside the supported Chinese range '
        '($minimumYear through $maximumYear)',
      );
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _threeDigits(int value) => value.toString().padLeft(3, '0');

  static String _fourDigits(int value) => value.toString().padLeft(4, '0');
}

final class _ResolvedChineseDateTime {
  const _ResolvedChineseDateTime({
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
