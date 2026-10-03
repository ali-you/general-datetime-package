import 'package:flutter/material.dart';

import '../hijri_date_time.dart';

class HijriCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Hijri calendar and the
  /// conventions of the current [MaterialLocalizations].
  const HijriCalendarDelegate();

  @override
  DateTime now() => HijriDateTime.now();

  @override
  DateTime dateOnly(DateTime date) =>
      HijriDateTime(date.year, date.month, date.day);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return HijriDateTime(monthDate.year, monthDate.month + monthsToAdd);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    return HijriDateTime(date.year, date.month, date.day + days);
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week for the month and year, with 0 representing Monday.
    final int weekdayFromMonday = HijriDateTime(year, month).weekday - 1;

    // 0-based start of week depending on the locale, with 0 representing Sunday.
    int firstDayOfWeekIndex = localizations.firstDayOfWeekIndex;

    // firstDayOfWeekIndex recomputed to be Monday-based, in order to compare with
    // weekdayFromMonday.
    firstDayOfWeekIndex = (firstDayOfWeekIndex - 1) % 7;

    // Number of days between the first day of week appearing on the calendar,
    // and the day corresponding to the first of the month.
    return (weekdayFromMonday - firstDayOfWeekIndex) % 7;
  }

  @override
  int getDaysInMonth(int year, int month) =>
      HijriDateTime(year, month).monthLength;

  @override
  HijriDateTime getMonth(int year, int month) => HijriDateTime(year, month);

  @override
  HijriDateTime getDay(int year, int month, int day) =>
      HijriDateTime(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatMonthYear(date);
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatMediumDate(date);
  }

  @override
  String formatShortMonthDay(
      DateTime date, MaterialLocalizations localizations) {
    return localizations.formatShortMonthDay(date);
  }

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatShortDate(date);
  }

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatFullDate(date);
  }

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatCompactDate(date);
  }

  @override
  DateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    return localizations.parseCompactDate(inputString);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return localizations.dateHelpText;
  }
}
