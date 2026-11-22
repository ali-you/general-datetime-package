import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart'
    show AmantaDate, AmantaDateTime;

import 'range_picker_calendar_delegate.dart';

/// Material picker support for [AmantaDateTime].
///
/// Compact input uses ASCII Vikrama year, ordinal month, and civil day
/// (YYYY-MM-DD). Supply Amanta values for the initial date and bounds.
/// Dates use local midnight where available, the normalized local time when
/// only midnight is skipped, and UTC midnight when the entire day is skipped.
class AmantaCalendarDelegate extends CalendarDelegate<DateTime> {
  const AmantaCalendarDelegate();

  CalendarDelegate<DateTime> get rangePickerDelegate =>
      RangePickerCalendarDelegate(this, minimumYear: AmantaDate.minimumYear);

  AmantaDate _civil(DateTime date) {
    if (date is AmantaDateTime) return date.civilDate;
    throw ArgumentError('AmantaCalendarDelegate requires AmantaDateTime');
  }

  @override
  AmantaDateTime now() => AmantaDateTime.now();

  @override
  AmantaDateTime dateOnly(DateTime date) =>
      AmantaDateTime.atStartOfDay(_civil(date));

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      _civil(startDate).monthsUntil(_civil(endDate));

  @override
  AmantaDateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    final date = _civil(monthDate);
    return AmantaDateTime.atStartOfDay(
        AmantaDate(date.year, date.month).addMonths(monthsToAdd));
  }

  @override
  AmantaDateTime addDaysToDate(DateTime date, int days) =>
      AmantaDateTime.atStartOfDay(_civil(date).addDays(days));

  @override
  int firstDayOffset(
          int year, int month, MaterialLocalizations localizations) =>
      (getMonth(year, month).weekday - localizations.firstDayOfWeekIndex) % 7;

  @override
  int getDaysInMonth(int year, int month) =>
      AmantaDate(year, month).monthLength;

  @override
  AmantaDateTime getMonth(int year, int month) {
    // Flutter carries the previous month's ordinal when selecting a year.
    final count = AmantaDate.monthsInYear(year);
    return AmantaDateTime.atStartOfDay(
        AmantaDate(year, month > count ? count : month));
  }

  @override
  AmantaDateTime getDay(int year, int month, int day) =>
      AmantaDateTime.atStartOfDay(AmantaDate(year, month).addDays(day - 1));

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    final value = _civil(date);
    return '${_monthName(value)} ${formatYear(value.year, localizations)}';
  }

  @override
  String formatShortMonthDay(
      DateTime date, MaterialLocalizations localizations) {
    final value = _civil(date);
    return '${_monthName(value)} ${localizations.formatDecimal(value.day)}';
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      formatFullDate(date, localizations);

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      formatCompactDate(date, localizations);

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      '${formatShortMonthDay(date, localizations)}, '
      '${formatYear(_civil(date).year, localizations)}';

  @override
  String formatCompactDate(
          DateTime date, MaterialLocalizations localizations) =>
      _civil(date).toString();

  @override
  String dateHelpText(MaterialLocalizations localizations) => 'YYYY-MM-DD';

  @override
  AmantaDateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    if (inputString == null) return null;
    try {
      return AmantaDateTime.atStartOfDay(AmantaDate.parse(inputString.trim()));
    } on FormatException {
      return null;
    }
  }

  String _monthName(AmantaDate date) =>
      '${date.isLeapMonth ? 'Adhika ' : ''}${_monthNames[date.lunarMonth - 1]}';

  static const _monthNames = [
    'Chaitra',
    'Vaishakha',
    'Jyeshtha',
    'Ashadha',
    'Shravana',
    'Bhadrapada',
    'Ashvina',
    'Kartika',
    'Margashirsha',
    'Pausha',
    'Magha',
    'Phalguna',
  ];
}
