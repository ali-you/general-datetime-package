import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart'
    show ChineseDateTime;

/// US-English Material strings for the .NET Chinese civil calendar.
/// Numeric input uses chronological ordinal months, including month 13.
class DefaultChineseCalendarMaterialLocalizations
    extends DefaultMaterialLocalizations {
  const DefaultChineseCalendarMaterialLocalizations();

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

  ChineseDateTime _require(DateTime date) {
    if (date is ChineseDateTime) return date;
    throw ArgumentError.value(date, 'date', 'Expected ChineseDateTime');
  }

  String _month(DateTime date) {
    final value = _require(date);
    return '${value.isLeapMonth ? 'Leap ' : ''}Month ${value.lunarMonth}';
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
  ChineseDateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    // int.tryParse alone also accepts hexadecimal and signed components.
    final match =
        RegExp(r'^\s*([0-9]{1,2})\s*/\s*([0-9]{1,2})\s*/\s*([0-9]{4})\s*$')
            .firstMatch(inputString);
    if (match == null || match.end != inputString.length) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    if (!ChineseDateTime.isValidDate(year, month, day)) {
      return null;
    }
    return ChineseDateTime(year, month, day);
  }

  @override
  String get dateHelpText => 'dd/mm/yyyy';

  static Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
          const DefaultChineseCalendarMaterialLocalizations());

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _ChineseCalendarMaterialLocalizationsDelegate();
}

class _ChineseCalendarMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ChineseCalendarMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultChineseCalendarMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_ChineseCalendarMaterialLocalizationsDelegate old) => false;
}
