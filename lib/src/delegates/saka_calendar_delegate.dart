// Flutter 3.32 uses the SDK design libraries.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart';

import 'range_picker_calendar_delegate.dart';

/// Material picker arithmetic for [SakaDateTime] values.
///
/// Pair with the default English Saka localizations or the translated
/// Saka localizations from general_date_format.
class SakaCalendarDelegate extends CalendarDelegate<DateTime> {
  const SakaCalendarDelegate();

  /// Use for [showDateRangePicker] to support Flutter's boundary probes.
  CalendarDelegate<DateTime> get rangePickerDelegate =>
      RangePickerCalendarDelegate(this, minimumYear: SakaDateTime.minimumYear);

  SakaDateTime _requireDate(DateTime date) {
    if (date is SakaDateTime) return date;
    throw ArgumentError.value(date, 'date', 'Expected a SakaDateTime');
  }

  @override
  SakaDateTime now() => SakaDateTime.now();

  @override
  SakaDateTime dateOnly(DateTime date) {
    final value = _requireDate(date);
    return SakaDateTime.atStartOfDay(value.year, value.month, value.day);
  }

  @override
  bool isSameDay(DateTime? dateA, DateTime? dateB) => super.isSameDay(
      dateA == null ? null : _requireDate(dateA),
      dateB == null ? null : _requireDate(dateB));

  @override
  bool isSameMonth(DateTime? dateA, DateTime? dateB) => super.isSameMonth(
      dateA == null ? null : _requireDate(dateA),
      dateB == null ? null : _requireDate(dateB));

  @override
  int monthDelta(DateTime startDate, DateTime endDate) {
    final start = _requireDate(startDate);
    final end = _requireDate(endDate);
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  @override
  SakaDateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    final start = _requireDate(monthDate);
    final target = CalendarDate(
            calendar: CalendarId.indian,
            year: start.year,
            month: start.month,
            day: 1)
        .addMonths(monthsToAdd);
    return getMonth(target.year, target.month);
  }

  @override
  SakaDateTime addDaysToDate(DateTime date, int days) {
    final target = CalendarDate.fromDateTime(_requireDate(date)).addDays(days);
    return SakaDateTime.atStartOfDay(target.year, target.month, target.day);
  }

  @override
  int firstDayOffset(
          int year, int month, MaterialLocalizations localizations) =>
      (getMonth(year, month).weekday - localizations.firstDayOfWeekIndex) % 7;

  @override
  int getDaysInMonth(int year, int month) =>
      SakaDateTime.daysInMonth(year, month);

  @override
  SakaDateTime getMonth(int year, int month) =>
      SakaDateTime.atStartOfDay(year, month, 1);

  @override
  SakaDateTime getDay(int year, int month, int day) =>
      dateOnly(SakaDateTime.utc(year, month, day));

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatMonthYear(_requireDate(date));

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatMediumDate(_requireDate(date));

  @override
  String formatShortMonthDay(
          DateTime date, MaterialLocalizations localizations) =>
      localizations.formatShortMonthDay(_requireDate(date));

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatShortDate(_requireDate(date));

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      localizations.formatFullDate(_requireDate(date));

  @override
  String formatCompactDate(
          DateTime date, MaterialLocalizations localizations) =>
      localizations.formatCompactDate(_requireDate(date));

  @override
  SakaDateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    final parsed = localizations.parseCompactDate(inputString);
    return parsed == null ? null : _requireDate(parsed);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) =>
      localizations.dateHelpText;
}
