import 'general_date_time_interface.dart';
import 'hijri_date_time.dart';
import 'persian_date_time.dart';

/// Calendar field operations that are safe for values typed as [DateTime].
///
/// Dart's `DateTime.copyWith` extension and Flutter's `DateUtils` reconstruct
/// Gregorian dates from the exposed fields. Use [copyWith] and [dateOnly] for
/// calendar fields, or [toGregorian] before passing a date to Gregorian helpers.
/// Supported calendars are native Gregorian, Persian, and Umm al-Qura Hijri.
abstract final class CalendarDateUtils {
  /// Replaces wall-clock fields in the input's calendar.
  ///
  /// Persian and Hijri inputs retain their calendar type even when [date] is
  /// statically typed as [DateTime]. Native inputs produce native Gregorian
  /// dates. Omitted fields retain their values, including microsecond precision
  /// and UTC/local mode. Overflow normalization and calendar bounds follow the
  /// corresponding constructor.
  ///
  /// Changing [isUtc] reinterprets the wall-clock fields in that mode; it does
  /// not preserve the instant. Use `toUtc()` or `toLocal()` for instant-preserving
  /// timezone conversion. Local DST gaps/folds follow native constructor rules.
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
  static DateTime dateOnly(DateTime date) => copyWith(
        date,
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  /// Returns a native Gregorian [DateTime] for the exact same instant and mode.
  ///
  /// Reads epoch microseconds, never calendar year/month/day, so the result is
  /// safe to pass to Gregorian field helpers. This conversion does not choose
  /// UTC or local time for the caller; use `toUtc()` or `toLocal()` as needed.
  static DateTime toGregorian(DateTime date) =>
      DateTime.fromMicrosecondsSinceEpoch(
        date.microsecondsSinceEpoch,
        isUtc: date.isUtc,
      );
}
