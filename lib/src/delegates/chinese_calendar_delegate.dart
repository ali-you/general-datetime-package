import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart'
    show ChineseDateTime, CalendarDate, CalendarId;

import 'range_picker_calendar_delegate.dart';

/// A Material calendar delegate that accepts only [ChineseDateTime] values.
///
/// All date inputs and non-null localization parser results are checked at
/// runtime. Incompatible values throw [ArgumentError]; convert Gregorian or
/// other-calendar instants with [ChineseDateTime.fromDateTime] explicitly.
/// Date-only and navigation results use the picker's local-midnight policy.
class ChineseCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Chinese calendar and the
  /// conventions of the current [MaterialLocalizations].
  const ChineseCalendarDelegate();

  /// Delegate for [showDateRangePicker], including supported-range endpoints.
  ///
  /// Flutter probes empty leading cells and keyboard targets before checking
  /// bounds. This adapter supplies native comparison dates for those probes;
  /// all selectable dates and results remain [ChineseDateTime]. Use this only
  /// with the range picker, and this delegate for general calendar arithmetic.
  /// On Flutter 3.32, also pass `calendarDateRangePickerBuilder` from
  /// `package:general_datetime/delegates.dart` as the range picker's builder.
  CalendarDelegate<DateTime> get rangePickerDelegate =>
      RangePickerCalendarDelegate(this,
          minimumYear: ChineseDateTime.minimumYear);

  @override
  DateTime now() => ChineseDateTime.now();

  @override
  DateTime dateOnly(DateTime date) {
    final value = _requireCalendarDate(date, 'date');
    return ChineseDateTime(value.year, value.month, value.day);
  }

  @override
  DateTimeRange<DateTime> datesOnly(DateTimeRange<DateTime> range) {
    _requireCalendarDate(range.start, 'range.start');
    _requireCalendarDate(range.end, 'range.end');
    return super.datesOnly(range);
  }

  @override
  bool isSameDay(DateTime? dateA, DateTime? dateB) {
    if (dateA != null) _requireCalendarDate(dateA, 'dateA');
    if (dateB != null) _requireCalendarDate(dateB, 'dateB');
    return super.isSameDay(dateA, dateB);
  }

  @override
  bool isSameMonth(DateTime? dateA, DateTime? dateB) {
    if (dateA != null) _requireCalendarDate(dateA, 'dateA');
    if (dateB != null) _requireCalendarDate(dateB, 'dateB');
    return super.isSameMonth(dateA, dateB);
  }

  @override
  int monthDelta(DateTime startDate, DateTime endDate) {
    _requireCalendarDate(startDate, 'startDate');
    _requireCalendarDate(endDate, 'endDate');
    return ChineseDateTime.monthIndex(endDate.year, endDate.month) -
        ChineseDateTime.monthIndex(startDate.year, startDate.month);
  }

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    _requireCalendarDate(monthDate, 'monthDate');
    final target = CalendarDate(
            calendar: CalendarId.chinese,
            year: monthDate.year,
            month: monthDate.month,
            day: 1)
        .addMonths(monthsToAdd);
    return ChineseDateTime(target.year, target.month);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    _requireCalendarDate(date, 'date');
    return ChineseDateTime(date.year, date.month, date.day + days);
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week for the month and year, with 0 representing Monday.
    final int weekdayFromMonday = getMonth(year, month).weekday - 1;

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
  int getDaysInMonth(int year, int month) => getMonth(year, month).monthLength;

  @override
  ChineseDateTime getMonth(int year, int month) {
    // Flutter carries an ordinal into another year; its thirteenth month
    // maps to the final month when the destination has only twelve.
    if (month == 13 && ChineseDateTime.monthsInYear(year) == 12) month = 12;
    return ChineseDateTime(year, month);
  }

  @override
  ChineseDateTime getDay(int year, int month, int day) =>
      ChineseDateTime(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatMonthYear(_requireCalendarDate(date, 'date'));
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatMediumDate(_requireCalendarDate(date, 'date'));
  }

  @override
  String formatShortMonthDay(
      DateTime date, MaterialLocalizations localizations) {
    return localizations
        .formatShortMonthDay(_requireCalendarDate(date, 'date'));
  }

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatShortDate(_requireCalendarDate(date, 'date'));
  }

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatFullDate(_requireCalendarDate(date, 'date'));
  }

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    return localizations.formatCompactDate(_requireCalendarDate(date, 'date'));
  }

  /// Returns null for invalid input. A non-null result in another calendar
  /// throws [ArgumentError], indicating incompatible localization configuration.
  @override
  DateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    final parsed = localizations.parseCompactDate(inputString);
    return parsed == null
        ? null
        : _requireCalendarDate(parsed, 'localizations.parseCompactDate result');
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return localizations.dateHelpText;
  }

  ChineseDateTime _requireCalendarDate(DateTime date, String argumentName) {
    if (date is ChineseDateTime) return date;
    throw ArgumentError.value(
      date,
      argumentName,
      'ChineseCalendarDelegate requires ChineseDateTime, received '
      '${date.runtimeType}. Convert explicitly with ChineseDateTime.fromDateTime.',
    );
  }
}
