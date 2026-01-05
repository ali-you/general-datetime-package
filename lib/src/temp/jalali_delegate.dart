import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';

import 'ja_date_time.dart';

class JalaliDelegate extends CalendarDelegate<JaDateTime> {
  /// Creates a calendar delegate that uses the Gregorian calendar and the
  /// conventions of the current [MaterialLocalizations].
  const JalaliDelegate();

  @override
  JaDateTime now() => JaDateTime.now();

  @override
  JaDateTime dateOnly(JaDateTime date) =>
      JaDateTime(date.year, date.month, date.day);

  @override
  int monthDelta(JaDateTime startDate, JaDateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  @override
  JaDateTime addMonthsToMonthDate(JaDateTime monthDate, int monthsToAdd) {
    return JaDateTime(monthDate.year, monthDate.month + monthsToAdd);
  }

  @override
  JaDateTime addDaysToDate(JaDateTime date, int days) {
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

  /// {@macro flutter.material.date.getDaysInMonth}
  @override
  int getDaysInMonth(int year, int month) {
    print("getDaysInMonth");
    print(year);
    print(month);
    print(JaDateTime(year, month).monthLength);
    return JaDateTime(year, month).monthLength;
  }

  @override
  JaDateTime getMonth(int year, int month) => JaDateTime(year, month);

  @override
  JaDateTime getDay(int year, int month, int day) =>
      JaDateTime(year, month, day);

  @override
  String formatMonthYear(JaDateTime date, MaterialLocalizations localizations) {
    // return GeneralDateFormat.yMMMM().format(JalaliDateTime(date.year, date.month));
    return localizations.formatMonthYear(date);
  }

  @override
  String formatMediumDate(
      JaDateTime date, MaterialLocalizations localizations) {
    // return GeneralDateFormat.MMMMEEEEd().format(JalaliDateTime(date.year, date.month, date.day));
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
  JaDateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    return JaDateTime(1400);
    // return localizations.parseCompactDate(inputString);
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return localizations.dateHelpText;
  }
}
