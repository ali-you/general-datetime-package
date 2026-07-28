import 'package:flutter/material.dart';

import '../persian_date_time.dart';

/// The language and date pattern used by [PersianCalendarDelegate].
enum PersianCalendarPresentation {
  /// English weekday names, transliterated month names, and `dd/mm/yyyy`.
  english,

  /// Persian names and digits, with the Iranian `yyyy/mm/dd` date order.
  persian,
}

/// A Material calendar delegate for the Persian (Solar Hijri) calendar.
///
/// Calendar-specific names, formatting, and parsing are owned by this delegate
/// and therefore do not depend on the ambient [MaterialLocalizations]. Week
/// layout still follows the ambient locale so it remains aligned with the
/// weekday headers rendered by Flutter's date picker.
class PersianCalendarDelegate extends CalendarDelegate<DateTime> {
  /// Creates a Persian calendar delegate.
  ///
  /// The default remains English for compatibility with earlier releases.
  const PersianCalendarDelegate({
    this.presentation = PersianCalendarPresentation.english,
  });

  /// Creates a delegate with English Solar Hijri presentation.
  const PersianCalendarDelegate.english()
      : presentation = PersianCalendarPresentation.english;

  /// Creates a delegate with Persian Solar Hijri presentation.
  const PersianCalendarDelegate.persian()
      : presentation = PersianCalendarPresentation.persian;

  /// The names, digits, and compact date order used by this delegate.
  final PersianCalendarPresentation presentation;

  static const List<String> _englishShortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _englishWeekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _persianWeekdays = <String>[
    'دوشنبه',
    'سه\u200cشنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];

  static const List<String> _englishShortMonths = <String>[
    'Far',
    'Ord',
    'Kho',
    'Tir',
    'Mor',
    'Sha',
    'Meh',
    'Aba',
    'Aza',
    'Dey',
    'Bah',
    'Esf',
  ];

  static const List<String> _englishMonths = <String>[
    'Farvardin',
    'Ordibehesht',
    'Khordad',
    'Tir',
    'Mordad',
    'Shahrivar',
    'Mehr',
    'Aban',
    'Azar',
    'Dey',
    'Bahman',
    'Esfand',
  ];

  static const List<String> _persianMonths = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const String _dateSeparator = '/';

  bool get _usesPersianPresentation =>
      presentation == PersianCalendarPresentation.persian;

  List<String> get _shortWeekdays =>
      _usesPersianPresentation ? _persianWeekdays : _englishShortWeekdays;

  List<String> get _weekdays =>
      _usesPersianPresentation ? _persianWeekdays : _englishWeekdays;

  List<String> get _shortMonths =>
      _usesPersianPresentation ? _persianMonths : _englishShortMonths;

  List<String> get _months =>
      _usesPersianPresentation ? _persianMonths : _englishMonths;

  @override
  DateTime now() => PersianDateTime.now();

  @override
  DateTime dateOnly(DateTime date) =>
      PersianDateTime(date.year, date.month, date.day);

  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return PersianDateTime(monthDate.year, monthDate.month + monthsToAdd);
  }

  @override
  DateTime addDaysToDate(DateTime date, int days) {
    return PersianDateTime(date.year, date.month, date.day + days);
  }

  @override
  int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
    // 0-based day of week for the month and year, with 0 representing Monday.
    final int weekdayFromMonday = PersianDateTime(year, month).weekday - 1;

    // Convert the Sunday-based localization index to a Monday-based index.
    final int firstDayOfWeekFromMonday =
        (localizations.firstDayOfWeekIndex - 1) % DateTime.daysPerWeek;

    return (weekdayFromMonday - firstDayOfWeekFromMonday) %
        DateTime.daysPerWeek;
  }

  @override
  int getDaysInMonth(int year, int month) =>
      PersianDateTime.daysInMonth(year, month);

  @override
  PersianDateTime getMonth(int year, int month) => PersianDateTime(year, month);

  @override
  PersianDateTime getDay(int year, int month, int day) =>
      PersianDateTime(year, month, day);

  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) {
    return '${_months[date.month - 1]} ${_formatNumber(date.year)}';
  }

  @override
  String formatYear(int year, MaterialLocalizations localizations) {
    return _formatNumber(year);
  }

  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) {
    final String weekday = _shortWeekdays[date.weekday - 1];
    final String month = _shortMonths[date.month - 1];
    final String day = _formatNumber(date.day);
    if (_usesPersianPresentation) return '$weekday $day $month';
    return '$weekday, $month $day';
  }

  @override
  String formatShortMonthDay(
      DateTime date, MaterialLocalizations localizations) {
    final String month = _shortMonths[date.month - 1];
    final String day = _formatNumber(date.day);
    if (_usesPersianPresentation) return '$day $month';
    return '$month $day';
  }

  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) {
    final String month = _shortMonths[date.month - 1];
    final String day = _formatNumber(date.day);
    final String year = _formatNumber(date.year);
    if (_usesPersianPresentation) return '$day $month $year';
    return '$month $day, $year';
  }

  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) {
    final String weekday = _weekdays[date.weekday - 1];
    final String month = _months[date.month - 1];
    final String day = _formatNumber(date.day);
    final String year = _formatNumber(date.year);
    if (_usesPersianPresentation) return '$year $month $day، $weekday';
    return '$weekday, $month $day, $year';
  }

  @override
  String formatCompactDate(DateTime date, MaterialLocalizations localizations) {
    final String day = _formatNumber(date.day, minimumWidth: 2);
    final String month = _formatNumber(date.month, minimumWidth: 2);
    final String year = _formatNumber(date.year, minimumWidth: 4);
    if (_usesPersianPresentation) {
      return '$year$_dateSeparator$month$_dateSeparator$day';
    }
    return '$day$_dateSeparator$month$_dateSeparator$year';
  }

  @override
  DateTime? parseCompactDate(
      String? inputString, MaterialLocalizations localizations) {
    if (inputString == null) return null;

    final String normalizedInput = _normalizeDigits(inputString.trim());
    final List<String> parts = normalizedInput.split(_dateSeparator);
    if (parts.length != 3) return null;

    final int yearIndex = _usesPersianPresentation ? 0 : 2;
    final int dayIndex = _usesPersianPresentation ? 2 : 0;
    final int? year = int.tryParse(parts[yearIndex].trim(), radix: 10);
    final int? month = int.tryParse(parts[1].trim(), radix: 10);
    final int? day = int.tryParse(parts[dayIndex].trim(), radix: 10);
    if (year == null || month == null || day == null) return null;
    if (!PersianDateTime.isValidDate(year, month, day)) return null;

    try {
      return PersianDateTime(year, month, day);
    } on RangeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  @override
  String dateHelpText(MaterialLocalizations localizations) {
    return _usesPersianPresentation ? 'yyyy/mm/dd' : 'dd/mm/yyyy';
  }

  String _formatNumber(int value, {int minimumWidth = 1}) {
    final String formatted = value.toString().padLeft(minimumWidth, '0');
    return _usesPersianPresentation ? _toPersianDigits(formatted) : formatted;
  }

  static String _normalizeDigits(String value) {
    final StringBuffer result = StringBuffer();
    for (final int rune in value.runes) {
      if (rune >= 0x06f0 && rune <= 0x06f9) {
        result.writeCharCode(0x30 + rune - 0x06f0);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        result.writeCharCode(0x30 + rune - 0x0660);
      } else {
        result.writeCharCode(rune);
      }
    }
    return result.toString();
  }

  static String _toPersianDigits(String value) {
    final StringBuffer result = StringBuffer();
    for (final int rune in value.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        result.writeCharCode(0x06f0 + rune - 0x30);
      } else {
        result.writeCharCode(rune);
      }
    }
    return result.toString();
  }
}
