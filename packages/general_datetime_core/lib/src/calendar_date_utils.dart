import 'calendars/amanta/amanta_date.dart';
import 'calendars/amanta/amanta_date_time.dart';
import 'calendars/chinese/chinese_date_time.dart';
import 'calendars/hebrew/hebrew_date_time.dart';
import 'shared/native_date_time.dart';
import 'general_date_time_interface.dart';
import 'calendars/hijri/hijri_date_time.dart';
import 'calendars/persian/persian_date_time.dart';
import 'calendars/saka/saka_date_time.dart';

/// Calendar field operations that are safe for values typed as [DateTime].
///
/// Dart's `DateTime.copyWith` extension and Flutter's `DateUtils` reconstruct
/// Gregorian dates from the exposed fields. Use [copyWith] and [dateOnly] for
/// calendar fields, or [toGregorian] before passing a date to Gregorian helpers.
/// Supports native Gregorian, Persian, Umm al-Qura Hijri, Hebrew, Chinese,
/// Amanta, and Saka.
abstract final class CalendarDateUtils {
  /// Replaces wall-clock fields in the input's calendar.
  ///
  /// Supported calendar inputs retain their type even when [date] is statically
  /// typed as [DateTime]. Native inputs produce native Gregorian
  /// dates. Omitted fields retain their values, including microsecond precision
  /// and UTC/local mode. Overflow normalization and calendar bounds follow the
  /// corresponding constructor.
  ///
  /// Changing [isUtc] reinterprets the wall-clock fields in that mode; it does
  /// not preserve the instant. Use `toUtc()` or `toLocal()` for instant-preserving
  /// timezone conversion. Amanta rejects nonexistent local times. Other
  /// supported calendars follow their constructor's local DST behavior.
  ///
  /// Other [GeneralDateTimeInterface] implementations throw [UnsupportedError]
  /// rather than interpreting their calendar fields as Gregorian.
  static DateTime copyWith(
    DateTime date, {
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
    if (date is SakaDateTime) {
      return date.copyWith(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        isUtc: isUtc,
      );
    }
    if (date is AmantaDateTime) {
      return AmantaDateTime.fromCivilDate(
        AmantaDate(year ?? date.year, month ?? date.month, day ?? date.day),
        hour: hour ?? date.hour,
        minute: minute ?? date.minute,
        second: second ?? date.second,
        millisecond: millisecond ?? date.millisecond,
        microsecond: microsecond ?? date.microsecond,
        isUtc: isUtc ?? date.isUtc,
      );
    }
    if (date is ChineseDateTime) {
      return date.copyWith(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        isUtc: isUtc,
      );
    }
    if (date is HebrewDateTime) {
      return date.copyWith(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        isUtc: isUtc,
      );
    }
    if (date is PersianDateTime) {
      return date.copyWith(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        isUtc: isUtc,
      );
    }
    if (date is HijriDateTime) {
      return date.copyWith(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond,
        isUtc: isUtc,
      );
    }
    if (date is GeneralDateTimeInterface) {
      throw UnsupportedError(
        'Calendar field operations are not registered for ${date.runtimeType}.',
      );
    }
    return toGregorian(date).copyWith(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      millisecond: millisecond,
      microsecond: microsecond,
      isUtc: isUtc,
    );
  }

  /// Clears the clock fields in the input's calendar and UTC/local mode.
  ///
  /// The result represents midnight, subject to native local DST normalization.
  /// This is a date-time, not a timezone-free civil-date value. Unlike Flutter's
  /// `DateUtils.dateOnly`, UTC inputs remain UTC. For a Material picker use its
  /// matching calendar delegate, which supplies the picker's local-date policy.
  static DateTime dateOnly(DateTime date) {
    if (date is SakaDateTime) {
      return SakaDateTime.atStartOfDay(date.year, date.month, date.day,
          isUtc: date.isUtc);
    }
    if (date is AmantaDateTime) {
      return AmantaDateTime.atStartOfDay(date.civilDate, isUtc: date.isUtc);
    }
    return copyWith(
      date,
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
  }

  /// Returns a native Gregorian [DateTime] for the exact same instant and mode.
  ///
  /// Copies split epoch milliseconds/microseconds, never calendar year/month/day, so the result is
  /// safe to pass to Gregorian field helpers. This conversion does not choose
  /// UTC or local time for the caller; use `toUtc()` or `toLocal()` as needed.
  static DateTime toGregorian(DateTime date) => copyNativeDateTime(date);
}
