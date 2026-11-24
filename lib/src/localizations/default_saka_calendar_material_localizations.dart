import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:general_datetime_core/general_datetime_core.dart';

/// English Material date labels and input for the Indian National Calendar.
class DefaultSakaCalendarMaterialLocalizations
    extends DefaultMaterialLocalizations {
  const DefaultSakaCalendarMaterialLocalizations();

  static const _months = [
    'Chaitra',
    'Vaisakha',
    'Jyaistha',
    'Asadha',
    'Sravana',
    'Bhadra',
    'Asvina',
    'Kartika',
    'Agrahayana',
    'Pausa',
    'Magha',
    'Phalguna',
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
  static final _compactDate = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');

  SakaDateTime _requireDate(DateTime date) {
    if (date is SakaDateTime) return date;
    throw ArgumentError.value(date, 'date', 'Expected a SakaDateTime');
  }

  String _month(DateTime date) => _months[_requireDate(date).month - 1];

  @override
  String formatYear(DateTime date) => date.year.toString();

  @override
  String formatCompactDate(DateTime date) {
    final value = _requireDate(date);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  @override
  String formatShortDate(DateTime date) =>
      '${formatShortMonthDay(date)}, ${date.year}';

  @override
  String formatMediumDate(DateTime date) =>
      '${_weekdays[date.weekday - 1].substring(0, 3)}, ${formatShortMonthDay(date)}';

  @override
  String formatFullDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${formatShortDate(date)}';

  @override
  String formatMonthYear(DateTime date) => '${_month(date)} ${date.year}';

  @override
  String formatShortMonthDay(DateTime date) => '${_month(date)} ${date.day}';

  @override
  SakaDateTime? parseCompactDate(String? inputString) {
    final match = _compactDate.firstMatch(inputString?.trim() ?? '');
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    return SakaDateTime.isValidDate(year, month, day)
        ? SakaDateTime.atStartOfDay(year, month, day)
        : null;
  }

  @override
  String get dateHelpText => 'yyyy-mm-dd';

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _SakaMaterialLocalizationsDelegate();
}

class _SakaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _SakaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultSakaCalendarMaterialLocalizations());

  @override
  bool shouldReload(_SakaMaterialLocalizationsDelegate old) => false;
}
