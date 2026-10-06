import '../../general_date_time_interface.dart';
import '../../shared/calendar_field_normalization.dart';
import '../../shared/constants.dart';
import 'hijri_calendar_calculation.dart';
import 'umm_al_qura_data.dart';

/// A date and time in Saudi Arabia's Umm al-Qura calendar.
///
/// Umm al-Qura is a published, data-backed calendar. It is not the arithmetic
/// (civil/tabular) Islamic calendar, and it must not be extrapolated with a
/// repeating leap-year formula. This implementation therefore supports only
/// the verified data range AH [minimumYear] through AH [maximumYear].
/// Unsupported dates throw [RangeError] instead of silently changing calendar
/// systems.
///
/// Instances retain the exact native [DateTime] instant internally. Calendar
/// fields such as [year], [month], and [day] are exposed in Umm al-Qura, while
/// epoch values, equality, time-zone data, and comparisons use the true
/// Gregorian instant.
class HijriDateTime extends DateTime
    implements GeneralDateTimeInterface<HijriDateTime> {
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
  static const int muharram = 1;
  static const int safar = 2;
  static const int rabi1 = 3;
  static const int rabi2 = 4;
  static const int jumada1 = 5;
  static const int jumada2 = 6;
  static const int rajab = 7;
  static const int shaban = 8;
  static const int ramadan = 9;
  static const int shawwal = 10;
  static const int dhuqidah = 11;
  static const int dhuhijjah = 12;
  static const int monthsPerYear = 12;

  /// First supported Umm al-Qura year.
  static const int minimumYear = HijriCalendarCalculation.minimumYear;

  /// Last supported Umm al-Qura year.
  static const int maximumYear = HijriCalendarCalculation.maximumYear;

  /// First Hijri year covered by the published Umm al-Qura table.
  static const int minimumOfficialYear = UmmAlQuraData.minimumYear;

  /// Last Hijri year covered by the published Umm al-Qura table.
  static const int maximumOfficialYear = UmmAlQuraData.maximumYear;

  static const int _microsecondsPerMillisecond = 1000;
  static const int _microsecondsPerSecond = 1000000;
  static const int _microsecondsPerMinute = 60 * _microsecondsPerSecond;
  static const int _microsecondsPerHour = 60 * _microsecondsPerMinute;

  static final DateTime _gregorianEpoch = DateTime.utc(
    UmmAlQuraData.epochGregorianYear,
    UmmAlQuraData.epochGregorianMonth,
    UmmAlQuraData.epochGregorianDay,
  );

  /// Cumulative days at the start of each supported year, plus a final end
  /// sentinel. Entry zero is the start of AH 1300.
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

  HijriDateTime._fromResolved(_ResolvedHijriDateTime resolved)
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

  /// Creates a local Umm al-Qura date, normalizing overflowing components in
  /// the same style as [DateTime.new].
  factory HijriDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return HijriDateTime._fromResolved(
      _resolveHijriFields(
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

  /// Converts a native Gregorian [dateTime] to Umm al-Qura without losing its
  /// instant, precision, or UTC/local representation.
  factory HijriDateTime.fromDateTime(DateTime dateTime) {
    return HijriDateTime._fromResolved(
      _resolveDateTime(_nativeCopy(dateTime)),
    );
  }

  /// The current local date and time in Umm al-Qura.
  factory HijriDateTime.now() => HijriDateTime.fromDateTime(DateTime.now());

  /// The current UTC date and time in Umm al-Qura.
  factory HijriDateTime.timestamp() =>
      HijriDateTime.fromDateTime(DateTime.timestamp());

  /// Creates a UTC Umm al-Qura date, normalizing overflowing components in the
  /// same style as [DateTime.utc].
  factory HijriDateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return HijriDateTime._fromResolved(
      _resolveHijriFields(
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

  factory HijriDateTime.fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
  }) {
    RangeError.checkValueInInterval(
      secondsSinceEpoch,
      -Constants.maximumNativeEpochSeconds,
      Constants.maximumNativeEpochSeconds,
      'secondsSinceEpoch',
    );
    return HijriDateTime.fromMicrosecondsSinceEpoch(
      secondsSinceEpoch * _microsecondsPerSecond,
      isUtc: isUtc,
    );
  }

  factory HijriDateTime.fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return HijriDateTime.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc),
    );
  }

  factory HijriDateTime.fromMicrosecondsSinceEpoch(
    int microsecondsSinceEpoch, {
    bool isUtc = false,
  }) {
    return HijriDateTime.fromDateTime(
      DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      ),
    );
  }

  /// Parses a Hijri ISO-8601-like string.
  ///
  /// A trailing `Z` or numeric offset produces a UTC result. Calendar and time
  /// overflows are normalized, but the final date must remain in the supported
  /// Umm al-Qura range.
  factory HijriDateTime.parse(String formattedString) {
    final Match? match = Constants.parseFormat.firstMatch(formattedString);
    if (match == null) {
      throw FormatException('Invalid Hijri date format', formattedString);
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
        return HijriDateTime(
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
      // date may be outside the table even when the final date is supported.
      return HijriDateTime.utc(
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
        'Hijri date is outside the supported Umm al-Qura range',
        formattedString,
      );
    }
  }

  /// Parses [formattedString], returning `null` for invalid or unsupported
  /// dates.
  static HijriDateTime? tryParse(String formattedString) {
    try {
      return HijriDateTime.parse(formattedString);
    } on FormatException {
      return null;
    }
  }

  /// The first supported Gregorian calendar date, in UTC.
  static DateTime get minimumGregorianDate => _gregorianEpoch;

  /// The last supported Gregorian calendar date, in UTC.
  static DateTime get maximumGregorianDate =>
      minimumGregorianDate.add(Duration(days: _supportedDayCount - 1));

  /// Whether the Gregorian wall date of [dateTime] is available in this
  /// implementation's Umm al-Qura data.
  static bool isSupportedDateTime(DateTime dateTime) {
    final DateTime nativeDateTime = _nativeCopy(dateTime);
    final int offset = _gregorianDayOffset(nativeDateTime);
    return offset >= 0 && offset < _supportedDayCount;
  }

  /// Whether [year], [month], and [day] form a strict (non-normalized)
  /// supported Umm al-Qura date.
  static bool isValidDate(int year, int month, int day) {
    if (year < minimumYear || year > maximumYear) return false;
    if (month < 1 || month > monthsPerYear) return false;
    return day >= 1 && day <= daysInMonth(year, month);
  }

  /// Returns the official Umm al-Qura length of [month] in [year].
  static int daysInMonth(int year, int month) {
    _requireSupportedYear(year);
    return HijriCalendarCalculation.daysInMonth(year, month);
  }

  /// The calendar name.
  @override
  String get name => 'Hijri';

  /// Weekday using [DateTime.monday] through [DateTime.sunday].
  @override
  int get weekday => toDateTime().weekday;

  /// Official length of this Umm al-Qura month.
  @override
  int get monthLength => daysInMonth(year, month);

  /// One-based day within the Umm al-Qura year.
  @override
  int get dayOfYear => _monthStartDay(year, month) + day;

  /// Number of days in this Umm al-Qura year.
  int get yearLength => _yearLength(year);

  /// Whether this Umm al-Qura year contains 355 days.
  @override
  bool get isLeapYear => HijriCalendarCalculation.isLeapYear(year);

  /// Whether this year uses the published Umm al-Qura calendar table.
  ///
  /// All currently supported Hijri years have published calendar data.
  bool get hasOfficialCalendarData =>
      year >= minimumOfficialYear && year <= maximumOfficialYear;

  /// Gregorian Julian day number for this calendar date.
  @override
  int get julianDay => UmmAlQuraData.epochJulianDay + _dayOffset;

  /// Converts this value to a native Gregorian [DateTime].
  @override
  DateTime toDateTime() => DateTime.fromMicrosecondsSinceEpoch(
        microsecondsSinceEpoch,
        isUtc: isUtc,
      );

  /// Adds an exact duration and converts the resulting instant to Umm al-Qura.
  @override
  HijriDateTime add(Duration duration) =>
      HijriDateTime.fromDateTime(toDateTime().add(duration));

  /// Subtracts an exact duration and converts the resulting instant to
  /// Umm al-Qura.
  @override
  HijriDateTime subtract(Duration duration) =>
      HijriDateTime.fromDateTime(toDateTime().subtract(duration));

  /// Converts this instant to local time.
  @override
  HijriDateTime toLocal() =>
      isUtc ? HijriDateTime.fromDateTime(toDateTime().toLocal()) : this;

  /// Converts this instant to UTC.
  @override
  HijriDateTime toUtc() =>
      isUtc ? this : HijriDateTime.fromDateTime(toDateTime().toUtc());

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

  /// Creates a copy with selected Umm al-Qura wall-clock fields replaced.
  ///
  /// This shadows Dart's [DateTimeCopyWith.copyWith] extension only when the
  /// receiver is statically typed as [HijriDateTime]. For a [DateTime]-typed
  /// receiver use `CalendarDateUtils.copyWith` from the package's public library;
  /// Dart's extension otherwise reconstructs a Gregorian date from Hijri fields.
  HijriDateTime copyWith({
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
        ? HijriDateTime.utc(
            fields[0],
            fields[1],
            fields[2],
            fields[3],
            fields[4],
            fields[5],
            fields[6],
            fields[7],
          )
        : HijriDateTime(
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

  /// Returns an ISO-like string with Umm al-Qura fields, not Gregorian.
  ///
  /// A native `DateTime.parse` or backend timestamp parser will misinterpret
  /// the year. `toUtc()` retains this calendar-specific output. For storage use
  /// `CalendarInstant.fromDateTime(this).toJson()` from the public library, or
  /// `toDateTime().toUtc().toIso8601String()` for a native Gregorian timestamp.
  /// Only [HijriDateTime.parse] should consume this untagged calendar string.
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

  static _ResolvedHijriDateTime _resolveHijriFields(
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
    // AH 1600-13-00 is the same date as AH 1600-12-30 and can be resolved
    // without inventing month data for AH 1601.
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

  static _ResolvedHijriDateTime _resolveDateTime(DateTime dateTime) {
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
    int dayWithinYear = dayOffset - _yearStartDays[low];
    int month = 1;
    while (true) {
      final int length = daysInMonth(year, month);
      if (dayWithinYear < length) break;
      dayWithinYear -= length;
      month++;
    }

    return _ResolvedHijriDateTime(
      dateTime: dateTime,
      year: year,
      month: month,
      day: dayWithinYear + 1,
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
    int result = 0;
    for (int currentMonth = 1; currentMonth < month; currentMonth++) {
      result += daysInMonth(year, currentMonth);
    }
    return result;
  }

  static int _yearLength(int year) {
    _requireSupportedYear(year);
    return HijriCalendarCalculation.yearLength(year);
  }

  static List<int> _buildYearStartDays() {
    final List<int> starts = <int>[0];
    int cumulativeDays = 0;
    for (int year = minimumYear; year <= maximumYear; year++) {
      cumulativeDays += HijriCalendarCalculation.yearLength(year);
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
        'Umm al-Qura data is available only for AH '
            '$minimumYear through AH $maximumYear',
      );
    }
  }

  static void _requireSupportedDayOffset(int dayOffset) {
    if (dayOffset < 0 || dayOffset >= _supportedDayCount) {
      throw RangeError(
        'Date is outside the supported Umm al-Qura range '
        '(AH $minimumYear-01-01 through AH $maximumYear-12-'
        '${daysInMonth(maximumYear, 12)})',
      );
    }
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _threeDigits(int value) => value.toString().padLeft(3, '0');

  static String _fourDigits(int value) => value.toString().padLeft(4, '0');
}

final class _ResolvedHijriDateTime {
  const _ResolvedHijriDateTime({
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
