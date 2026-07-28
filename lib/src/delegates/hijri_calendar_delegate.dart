import 'package:flutter/material.dart';

import '../hijri_date_time.dart';

class HijriCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a calendar delegate that uses the Hijri calendar.
  ///
  /// Week layout follows the current [MaterialLocalizations], while Hijri date
  /// names, formatting, and parsing are provided by this delegate.
  const HijriCalendarDelegate();

  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _shortMonths = <String>[
    'Muh',
    'Saf',
    'Ra1',
    'Ra2',
    'Ju1',
    'Ju2',
    'Raj',
    'Sha',
    'Ram',
    'Shaw',
    'DhuQ',
    'DhuH',
  ];

  static const List<String> _months = <String>[
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const String _dateSeparator = '/';
  static const String _dateHelpText = 'dd/mm/yyyy';

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
    return '${_months[date.month - 1]} ${date.year}';
  }

  @override
  String formatYear(int year, MaterialLocalizations localizations) {
    return year.toString();
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) {
    final String weekday = _shortWeekdays[date.weekday - 1];
    final String month = _shortMonths[date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  @override
  String formatShortMonthDay(
      DateTime date, MaterialLocalizations localizations) {
    return '${_shortMonths[date.month - 1]} ${date.day}';
  }

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) {
    return '${_shortMonths[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) {
    final String weekday = _weekdays[date.weekday - 1];
    final String month = _months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    final String day = _twoDigits(date.day);
    final String month = _twoDigits(date.month);
    final String year = date.year.toString().padLeft(4, '0');
    return '$day$_dateSeparator$month$_dateSeparator$year';
  }

  @override
  DateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    if (inputString == null) return null;

    final List<String> parts = inputString.trim().split(_dateSeparator);
    if (parts.length != 3) return null;

    final int? day = int.tryParse(parts[0].trim(), radix: 10);
    final int? month = int.tryParse(parts[1].trim(), radix: 10);
    final int? year = int.tryParse(parts[2].trim(), radix: 10);
    if (day == null || month == null || year == null || year < 1) {
      return null;
    }
    if (month < 1 || month > HijriDateTime.monthsPerYear || day < 1) {
      return null;
    }

    try {
      if (day > getDaysInMonth(year, month)) return null;

      final HijriDateTime date = HijriDateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } on ArgumentError {
      return null;
    }
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return _dateHelpText;
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
