import 'package:flutter/material.dart';

import '../temp/ja_date_time.dart';

class JalaliDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Gregorian calendar and the
  /// conventions of the current [MaterialLocalizations].
  const JalaliDelegate();

  @override
  DateTime now() => JaDateTime.now();

  @override
  DateTime dateOnly(DateTime date) =>
      JaDateTime(date.year, date.month, date.day);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return JaDateTime(monthDate.year, monthDate.month + monthsToAdd);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    return JaDateTime(date.year, date.month, date.day + days);
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week for the month and year, with 0 representing Monday.
    final int weekdayFromMonday = JaDateTime(year, month).weekday - 1;

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
      JaDateTime(year, month).monthLength;

  @override
  JaDateTime getMonth(int year, int month) => JaDateTime(year, month);

  @override
  JaDateTime getDay(int year, int month, int day) =>
      JaDateTime(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatMonthYear(date);
  }

  @override
  String formatMediumDate(
      DateTime date, MaterialLocalizations localizations) {
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
