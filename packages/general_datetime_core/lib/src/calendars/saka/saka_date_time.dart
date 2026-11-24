import '../../general_date_time_interface.dart';
import '../../shared/calendar_field_normalization.dart';
import '../../shared/native_date_time.dart';

/// A date and time in the Indian National Calendar (Saka).
///
/// Years 1 through 9920 use the national civil rules, projected before their
/// adoption in 1957. Months are numbered 1 (Chaitra) through 12 (Phalguna).
/// Local and UTC constructors normalize overflowing fields like [DateTime].
/// Use `CalendarSystems.saka.construct` for strict construction.
final class SakaDateTime extends DateTime
    implements GeneralDateTimeInterface<SakaDateTime> {
  static const int minimumYear = 1;
  static const int maximumYear = 9920;
  static const int _yearOffset = 78;

  static final _firstDay = _yearStart(minimumYear);
  static final _endDay = _yearStart(maximumYear + 1);
  static final _dayCount = _endDay.difference(_firstDay).inDays;

  SakaDateTime._(this._native, this.year, this.month, this.day)
      : super.fromMicrosecondsSinceEpoch(_native.microsecondsSinceEpoch,
            isUtc: _native.isUtc);

  factory SakaDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) =>
      _construct(
          year, month, day, hour, minute, second, millisecond, microsecond,
          isUtc: false);

  factory SakaDateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) =>
      _construct(
          year, month, day, hour, minute, second, millisecond, microsecond,
          isUtc: true);

  /// Preserves the instant and mode, using its Gregorian wall date for conversion.
  factory SakaDateTime.fromDateTime(DateTime value) =>
      _fromNative(copyNativeDateTime(value));

  factory SakaDateTime.now() => _fromNative(DateTime.now());

  /// Constructs a valid civil day at local midnight, or UTC when requested.
  /// A missing local midnight uses Dart's same-day normalized time. If the
  /// entire local date is skipped, the result uses UTC midnight for that day.
  factory SakaDateTime.atStartOfDay(int year, int month, int day,
      {bool isUtc = false}) {
    RangeError.checkValueInInterval(day, 1, daysInMonth(year, month), 'day');
    final gregorian = _gregorianDay(year, month, day);
    final local = isUtc
        ? gregorian
        : DateTime(gregorian.year, gregorian.month, gregorian.day);
    return SakaDateTime._(
        _hasSameDay(local, gregorian) ? local : gregorian, year, month, day);
  }

  final DateTime _native;

  @override
  final int year;
  @override
  final int month;
  @override
  final int day;

  static bool _isLeap(int year) {
    final gregorianYear = year + _yearOffset;
    return gregorianYear % 4 == 0 &&
        (gregorianYear % 100 != 0 || gregorianYear % 400 == 0);
  }

  static int _length(int year, int month) =>
      month == 1 ? (_isLeap(year) ? 31 : 30) : (month <= 6 ? 31 : 30);

  static int daysInMonth(int year, int month) {
    RangeError.checkValueInInterval(year, minimumYear, maximumYear, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    return _length(year, month);
  }

  static bool isValidDate(int year, int month, int day) =>
      year >= minimumYear &&
      year <= maximumYear &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= _length(year, month);

  static DateTime _yearStart(int year) =>
      DateTime.utc(year + _yearOffset, 3, _isLeap(year) ? 21 : 22);

  static int _monthOffset(int year, int month) {
    if (month == 1) return 0;
    final preceding = month - 2;
    final longMonths = preceding < 5 ? preceding : 5;
    return _length(year, 1) + longMonths * 31 + (preceding - longMonths) * 30;
  }

  static DateTime _gregorianDay(int year, int month, int day) =>
      _yearStart(year).add(Duration(days: _monthOffset(year, month) + day - 1));

  static bool _hasSameDay(DateTime a, DateTime b) =>
      (a.year, a.month, a.day) == (b.year, b.month, b.day);

  static SakaDateTime _fromNative(DateTime native) {
    if (native.year < _firstDay.year || native.year > _endDay.year) {
      throw RangeError('Gregorian wall date outside the Saka range');
    }
    final gregorian = DateTime.utc(native.year, native.month, native.day);
    if (gregorian.isBefore(_firstDay) || !gregorian.isBefore(_endDay)) {
      throw RangeError('Gregorian wall date outside the Saka range');
    }
    var year = native.year - _yearOffset;
    var start = _yearStart(year);
    if (gregorian.isBefore(start)) start = _yearStart(--year);
    final offset = gregorian.difference(start).inDays;
    final afterChaitra = offset - _length(year, 1);
    if (afterChaitra < 0) return SakaDateTime._(native, year, 1, offset + 1);
    if (afterChaitra < 155) {
      return SakaDateTime._(
          native, year, 2 + afterChaitra ~/ 31, 1 + afterChaitra % 31);
    }
    final remaining = afterChaitra - 155;
    return SakaDateTime._(
        native, year, 7 + remaining ~/ 30, 1 + remaining % 30);
  }

  static SakaDateTime _construct(int year, int month, int day, int hour,
      int minute, int second, int millisecond, int microsecond,
      {required bool isUtc}) {
    final (y, m) =
        normalizeCalendarMonth(year, month, minimumYear, maximumYear);
    RangeError.checkValueInInterval(y, minimumYear, maximumYear + 1, 'year');
    final start = _gregorianDay(y, m, 1).difference(_firstDay).inDays;
    final (offset, clock) = normalizeCalendarTime(
        start, _dayCount, day, hour, minute, second, millisecond, microsecond);
    RangeError.checkValueInInterval(offset, 0, _dayCount - 1, 'day offset');
    final gregorian = _firstDay.add(Duration(days: offset));
    final construct = isUtc ? DateTime.utc : DateTime.new;
    final native = construct(
      gregorian.year,
      gregorian.month,
      gregorian.day,
      clock ~/ Duration.microsecondsPerHour,
      clock ~/ Duration.microsecondsPerMinute % 60,
      clock ~/ Duration.microsecondsPerSecond % 60,
      clock ~/ Duration.microsecondsPerMillisecond % 1000,
      clock % 1000,
    );
    return _fromNative(native);
  }

  @override
  String get name => 'Saka';
  @override
  int get monthLength => _length(year, month);
  @override
  int get dayOfYear => _monthOffset(year, month) + day;
  @override
  bool get isLeapYear => _isLeap(year);
  @override
  int get julianDay =>
      _gregorianDay(year, month, day).difference(DateTime.utc(1970)).inDays +
      2440588;

  @override
  int get weekday => _native.weekday;
  @override
  int get hour => _native.hour;
  @override
  int get minute => _native.minute;
  @override
  int get second => _native.second;
  @override
  int get millisecond => _native.millisecond;
  @override
  int get microsecond => _native.microsecond;
  @override
  int get millisecondsSinceEpoch => _native.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _native.microsecondsSinceEpoch;
  @override
  int get secondsSinceEpoch =>
      (floorEpochMilliseconds(_native) - millisecond) ~/
      Duration.millisecondsPerSecond;
  @override
  String get timeZoneName => _native.timeZoneName;
  @override
  Duration get timeZoneOffset => _native.timeZoneOffset;

  @override
  DateTime toDateTime() => _native;
  @override
  SakaDateTime add(Duration duration) => _fromNative(_native.add(duration));
  @override
  SakaDateTime subtract(Duration duration) =>
      _fromNative(_native.subtract(duration));
  @override
  SakaDateTime toLocal() => isUtc ? _fromNative(_native.toLocal()) : this;
  @override
  SakaDateTime toUtc() => isUtc ? this : _fromNative(_native.toUtc());

  @override
  int compareTo(DateTime other) => _native.compareTo(copyNativeDateTime(other));
  @override
  bool isBefore(DateTime other) => compareTo(other) < 0;
  @override
  bool isAfter(DateTime other) => compareTo(other) > 0;
  @override
  bool isAtSameMomentAs(DateTime other) => compareTo(other) == 0;
  @override
  Duration difference(DateTime other) =>
      _native.difference(copyNativeDateTime(other));
  @override
  bool operator ==(Object other) =>
      other is DateTime && _native == copyNativeDateTime(other);
  @override
  int get hashCode => _native.hashCode;

  SakaDateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool? isUtc,
  }) =>
      _construct(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
        isUtc: isUtc ?? this.isUtc,
      );

  String get _dateText => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String toString() => '$_dateText${_native.toString().substring(10)}';

  /// Returns Saka fields. For a Gregorian timestamp, call [toDateTime] first.
  @override
  String toIso8601String() =>
      '$_dateText${_native.toIso8601String().substring(10)}';
}
