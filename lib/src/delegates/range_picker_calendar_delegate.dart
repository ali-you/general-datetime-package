import 'package:flutter/material.dart';

import '../calendar_date_utils.dart';

/// Internal adapter for Flutter's range-picker comparison probes.
class RangePickerCalendarDelegate extends CalendarDelegate<DateTime> {
  const RangePickerCalendarDelegate(this.delegate, {required this.minimumYear});

  final CalendarDelegate<DateTime> delegate;
  final int minimumYear;

  @override
  DateTime getDay(int year, int month, int day) {
    // Flutter requests the start of the first week even when it is an empty
    // leading cell. That date is used only for highlight comparisons, never
    // as a day widget, localization input, or selectable date.
    if (year == minimumYear && month == 1 && day >= -5 && day <= 0) {
      return _comparisonDay(delegate.getMonth(year, month), day - 1);
    }
    return delegate.getDay(year, month, day);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    try {
      return delegate.addDaysToDate(date, days);
    } on RangeError {
      // Arrow-key navigation probes an adjacent day/week before checking the
      // picker's bounds. Let that comparison reject the out-of-range target.
      if (days < -7 || days > 7) rethrow;
      return _comparisonDay(delegate.dateOnly(date), days);
    }
  }

  DateTime _comparisonDay(DateTime date, int days) {
    final native = CalendarDateUtils.toGregorian(date);
    // Advance local wall days rather than 24-hour durations across DST.
    return DateTime(native.year, native.month, native.day + days);
  }

  @override
  DateTime now() => delegate.now();

  @override
  DateTime dateOnly(DateTime date) => delegate.dateOnly(date);

  @override
  DateTimeRange<DateTime> datesOnly(DateTimeRange<DateTime> range) =>
      delegate.datesOnly(range);

  @override
  bool isSameDay(DateTime? dateA, DateTime? dateB) =>
      delegate.isSameDay(dateA, dateB);

  @override
  bool isSameMonth(DateTime? dateA, DateTime? dateB) =>
      delegate.isSameMonth(dateA, dateB);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      delegate.monthDelta(startDate, endDate);

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) =>
      delegate.addMonthsToMonthDate(monthDate, monthsToAdd);

  @override
  int firstDayOffset(
          int year, int month, MaterialLocalizations localizations) =>
      delegate.firstDayOffset(year, month, localizations);

  @override
  int getDaysInMonth(int year, int month) =>
      delegate.getDaysInMonth(year, month);

  @override
  DateTime getMonth(int year, int month) => delegate.getMonth(year, month);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      delegate.formatMonthYear(date, localizations);

  @override
  String formatYear(int year, MaterialLocalizations localizations) =>
      delegate.formatYear(year, localizations);

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      delegate.formatMediumDate(date, localizations);

  @override
  String formatShortMonthDay(
          DateTime date, MaterialLocalizations localizations) =>
      delegate.formatShortMonthDay(date, localizations);

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      delegate.formatShortDate(date, localizations);

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      delegate.formatFullDate(date, localizations);

  @override
  String formatCompactDate(
          DateTime date, MaterialLocalizations localizations) =>
      delegate.formatCompactDate(date, localizations);

  @override
  DateTime? parseCompactDate(
          String? inputString, MaterialLocalizations localizations) =>
      delegate.parseCompactDate(inputString, localizations);

  @override
  String dateHelpText(MaterialLocalizations localizations) =>
      delegate.dateHelpText(localizations);
}
