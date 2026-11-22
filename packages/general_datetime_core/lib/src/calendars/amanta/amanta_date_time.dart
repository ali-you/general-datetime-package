import '../../general_date_time_interface.dart';
import '../../shared/native_date_time.dart';
import 'amanta_date.dart';

/// A DateTime adapter for Amanta civil dates. Its clock follows Dart's UTC or
/// local mode. The civil date's tithi always describes Ujjain sunrise.
final class AmantaDateTime extends DateTime
    implements GeneralDateTimeInterface<AmantaDateTime> {
  AmantaDateTime._(this._native, this.civilDate)
      : super.fromMicrosecondsSinceEpoch(_native.microsecondsSinceEpoch,
            isUtc: _native.isUtc);

  factory AmantaDateTime.fromDateTime(DateTime value) {
    final date = copyNativeDateTime(value);
    return AmantaDateTime._(
        date, AmantaDate.fromGregorian(date.year, date.month, date.day));
  }

  /// Converts the current local instant to Amanta.
  factory AmantaDateTime.now() => AmantaDateTime.fromDateTime(DateTime.now());

  /// Represents the start of a civil day in UTC or in the host timezone.
  ///
  /// Dart may normalize a missing local midnight to a later time on the same
  /// date. If the host timezone skips the entire date, use its UTC midnight
  /// so the returned value still represents the requested civil day.
  factory AmantaDateTime.atStartOfDay(AmantaDate date, {bool isUtc = false}) {
    final gregorian = date.toGregorian();
    if (isUtc) return AmantaDateTime._(gregorian, date);
    final local = DateTime(gregorian.year, gregorian.month, gregorian.day);
    final sameDay = (local.year, local.month, local.day) ==
        (gregorian.year, gregorian.month, gregorian.day);
    return AmantaDateTime._(sameDay ? local : gregorian, date);
  }

  factory AmantaDateTime.fromCivilDate(
    AmantaDate date, {
    bool isUtc = false,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    RangeError.checkValueInInterval(second, 0, 59, 'second');
    RangeError.checkValueInInterval(millisecond, 0, 999, 'millisecond');
    RangeError.checkValueInInterval(microsecond, 0, 999, 'microsecond');
    final day = date.toGregorian();
    final construct = isUtc ? DateTime.utc : DateTime.new;
    final value = construct(day.year, day.month, day.day, hour, minute, second,
        millisecond, microsecond);
    if ((value.year, value.month, value.day, value.hour, value.minute) !=
        (day.year, day.month, day.day, hour, minute)) {
      throw ArgumentError('The local timezone normalized the supplied time');
    }
    return AmantaDateTime._(value, date);
  }

  final DateTime _native;
  final AmantaDate civilDate;

  @override
  int get year => civilDate.year;
  @override
  int get month => civilDate.month;
  @override
  int get day => civilDate.day;
  @override
  String get name => 'Amanta';
  @override
  int get monthLength => civilDate.monthLength;
  @override
  int get dayOfYear => civilDate.dayIndex - AmantaDate(year, 1).dayIndex + 1;
  @override
  bool get isLeapYear => AmantaDate.isLeapYear(year);
  @override
  int get julianDay => civilDate.dayIndex + 2440588;
  @override
  int get secondsSinceEpoch =>
      (millisecondsSinceEpoch - millisecond) ~/ Duration.millisecondsPerSecond;

  @override
  DateTime toDateTime() => _native;
  @override
  AmantaDateTime add(Duration duration) =>
      AmantaDateTime.fromDateTime(_native.add(duration));
  @override
  AmantaDateTime subtract(Duration duration) =>
      AmantaDateTime.fromDateTime(_native.subtract(duration));
  @override
  AmantaDateTime toLocal() =>
      isUtc ? AmantaDateTime.fromDateTime(_native.toLocal()) : this;
  @override
  AmantaDateTime toUtc() =>
      isUtc ? this : AmantaDateTime.fromDateTime(_native.toUtc());
}
