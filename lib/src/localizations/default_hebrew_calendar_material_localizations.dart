import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart'
    show HebrewDateTime;

/// US-English Material strings with Hebrew civil date formatting and parsing.
/// Install [delegate] alongside a Hebrew calendar picker. Numeric months use
/// stable slots 1..13, with slot 6 absent in common years.
class DefaultHebrewCalendarMaterialLocalizations
    extends DefaultMaterialLocalizations {
  const DefaultHebrewCalendarMaterialLocalizations();

  static const _months = [
    'Tishri',
    'Cheshvan',
    'Kislev',
    'Tevet',
    'Shevat',
    'Adar I',
    'Adar',
    'Nisan',
    'Iyar',
    'Sivan',
    'Tammuz',
    'Av',
    'Elul',
  ];
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _shortWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  HebrewDateTime _require(DateTime date) {
    if (date is HebrewDateTime) return date;
    throw ArgumentError.value(date, 'date', 'Expected HebrewDateTime');
  }

  String _month(DateTime date) {
    final value = _require(date);
    if (value.month == HebrewDateTime.adar && value.isLeapYear) {
      return 'Adar II';
    }
    return _months[value.month - 1];
  }

  @override
  String formatYear(DateTime date) => date.year.toString();

  @override
  String formatCompactDate(DateTime date) {
    final value = _require(date);
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year.toString().padLeft(4, '0')}';
  }

  @override
  String formatShortDate(DateTime date) =>
      '${_month(date)} ${date.day}, ${date.year}';

  @override
  String formatMediumDate(DateTime date) =>
      '${_shortWeekdays[_require(date).weekday - 1]}, ${_month(date)} ${date.day}';

  @override
  String formatFullDate(DateTime date) =>
      '${_weekdays[_require(date).weekday - 1]}, ${_month(date)} ${date.day}, ${date.year}';

  @override
  String formatMonthYear(DateTime date) => '${_month(date)} ${date.year}';

  @override
  String formatShortMonthDay(DateTime date) => '${_month(date)} ${date.day}';

  @override
  HebrewDateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    final parts = inputString.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0].trim());
    final month = int.tryParse(parts[1].trim());
    final year = int.tryParse(parts[2].trim());
    if (year == null ||
        month == null ||
        day == null ||
        !HebrewDateTime.isValidDate(year, month, day)) {
      return null;
    }
    return HebrewDateTime(year, month, day);
  }

  @override
  String get dateHelpText => 'dd/mm/yyyy';

  static Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
          const DefaultHebrewCalendarMaterialLocalizations());

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _HebrewCalendarMaterialLocalizationsDelegate();
}

class _HebrewCalendarMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _HebrewCalendarMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultHebrewCalendarMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_HebrewCalendarMaterialLocalizationsDelegate old) => false;
}
