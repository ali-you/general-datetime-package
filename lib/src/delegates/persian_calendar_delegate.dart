import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart'
    show PersianDateTime;

import 'range_picker_calendar_delegate.dart';

/// A Material calendar delegate that accepts only [PersianDateTime] values.
///
/// All date inputs and non-null localization parser results are checked at
/// runtime. Incompatible values throw [ArgumentError]; convert Gregorian or
/// other-calendar instants with [PersianDateTime.fromDateTime] explicitly.
/// Date-only and navigation results use the picker's local-midnight policy.
class PersianCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Persian calendar and the
  /// conventions of the current [MaterialLocalizations].
  const PersianCalendarDelegate();

  /// Delegate for [showDateRangePicker], including supported-range endpoints.
  ///
  /// Flutter probes empty leading cells and keyboard targets before checking
  /// bounds. This adapter supplies native comparison dates for those probes;
  /// all selectable dates and results remain [PersianDateTime]. Use this only
  /// with the range picker, and this delegate for general calendar arithmetic.
  /// On Flutter 3.32, also pass `calendarDateRangePickerBuilder` from
  /// `package:general_datetime/delegates.dart` as the range picker's builder.
  CalendarDelegate<DateTime> get rangePickerDelegate =>
      RangePickerCalendarDelegate(this,
          minimumYear: PersianDateTime.minimumYear);

  @override
  DateTime now() => PersianDateTime.now();

  @override
  DateTime dateOnly(DateTime date) {
    final value = _requireCalendarDate(date, 'date');
    return PersianDateTime(value.year, value.month, value.day);
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
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    _requireCalendarDate(monthDate, 'monthDate');
    return PersianDateTime(monthDate.year, monthDate.month + monthsToAdd);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    _requireCalendarDate(date, 'date');
    return PersianDateTime(date.year, date.month, date.day + days);
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week for the month and year, with 0 representing Monday.
    final int weekdayFromMonday = PersianDateTime(year, month).weekday - 1;

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
      PersianDateTime(year, month).monthLength;

  @override
  PersianDateTime getMonth(int year, int month) => PersianDateTime(year, month);

  @override
  PersianDateTime getDay(int year, int month, int day) =>
      PersianDateTime(year, month, day);

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

  PersianDateTime _requireCalendarDate(DateTime date, String argumentName) {
    if (date is PersianDateTime) return date;
    throw ArgumentError.value(
      date,
      argumentName,
      'PersianCalendarDelegate requires PersianDateTime, received '
      '${date.runtimeType}. Convert explicitly with PersianDateTime.fromDateTime.',
    );
  }
}
