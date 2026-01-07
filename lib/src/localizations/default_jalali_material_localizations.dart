import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../temp/ja_date_time.dart';

class _JalaliMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _JalaliMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultJalaliMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_JalaliMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultMaterialLocalizations.delegate(en_US)';
}

class DefaultJalaliMaterialLocalizations implements MaterialLocalizations {
  /// Constructs an object that defines the material widgets' localized strings
  /// for US English (only).
  ///
  /// [LocalizationsDelegate] implementations typically call the static [load]
  /// function, rather than constructing this class directly.
  const DefaultJalaliMaterialLocalizations();

  // Ordered to match DateTime.monday=1, DateTime.sunday=6
  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Ordered to match DateTime.monday=1, DateTime.sunday=6
  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _narrowWeekdays = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S'
  ];

  static const List<String> _shortMonths = <String>[
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

  static const List<String> _months = <String>[
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

  /// Returns the number of days in a month, according to the proleptic
  /// Gregorian calendar.
  ///
  /// This applies the leap year logic introduced by the Gregorian reforms of
  /// 1582. It will not give valid results for dates prior to that time.
  int _getDaysInMonth(int year, int month) {
    if (month == JaDateTime.esfand) {
      final bool isLeapYear = JaDateTime(year).isLeapYear;
      if (isLeapYear) return 30;
      return 29;
    }
    const List<int> daysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      30,
      -1
    ];
    return daysInMonth[month - 1];
  }

  @override
  String formatHour(TimeOfDay timeOfDay, {bool alwaysUse24HourFormat = false}) {
    final TimeOfDayFormat format =
        timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat);
    switch (format) {
      case TimeOfDayFormat.h_colon_mm_space_a:
        return formatDecimal(
            timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod);
      case TimeOfDayFormat.HH_colon_mm:
        return _formatTwoDigitZeroPad(timeOfDay.hour);
      case TimeOfDayFormat.a_space_h_colon_mm:
      case TimeOfDayFormat.frenchCanadian:
      case TimeOfDayFormat.H_colon_mm:
      case TimeOfDayFormat.HH_dot_mm:
        throw AssertionError('$runtimeType does not support $format.');
    }
  }

  /// Formats [number] using two digits, assuming it's in the 0-99 inclusive
  /// range. Not designed to format values outside this range.
  String _formatTwoDigitZeroPad(int number) {
    assert(0 <= number && number < 100);
    if (number < 10) return '0$number';
    return '$number';
  }

  @override
  String formatMinute(TimeOfDay timeOfDay) {
    final int minute = timeOfDay.minute;
    return minute < 10 ? '0$minute' : minute.toString();
  }

  @override
  String formatYear(DateTime date) => date.year.toString();

  @override
  String formatCompactDate(DateTime date) {
    // Assumes IR dd/mm/yyyy format
    final String month = _formatTwoDigitZeroPad(date.month);
    final String day = _formatTwoDigitZeroPad(date.day);
    final String year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  @override
  String formatShortDate(DateTime date) {
    final String month = _shortMonths[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  @override
  String formatMediumDate(DateTime date) {
    final String day = _shortWeekdays[date.weekday - 1];
    final String month = _shortMonths[date.month - 1];
    return '$day, $month ${date.day}';
  }

  @override
  String formatFullDate(DateTime date) {
    final String month = _months[date.month - 1];
    return '${_weekdays[date.weekday - 1]}, $month ${date.day}, ${date.year}';
  }

  @override
  String formatMonthYear(DateTime date) {
    final String year = formatYear(date);
    final String month = _months[date.month - 1];
    return '$month $year';
  }

  @override
  String formatShortMonthDay(DateTime date) {
    final String month = _shortMonths[date.month - 1];
    return '$month ${date.day}';
  }

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;

    // Assumes Iran dd/mm/yyyy format
    final List<String> inputParts = inputString.split('/');
    if (inputParts.length != 3) return null;

    final int? year = int.tryParse(inputParts[2], radix: 10);
    if (year == null || year < 1) return null;

    final int? month = int.tryParse(inputParts[1], radix: 10);
    if (month == null || month < 1 || month > 12) return null;

    final int? day = int.tryParse(inputParts[0], radix: 10);
    if (day == null || day < 1 || day > _getDaysInMonth(year, month)) {
      return null;
    }

    try {
      return JaDateTime(year, month, day);
    } on ArgumentError {
      return null;
    }
  }

  @override
  List<String> get narrowWeekdays => _narrowWeekdays;

  @override
  int get firstDayOfWeekIndex => 0; // narrowWeekdays[0] is 'S' for Sunday

  @override
  String get dateSeparator => '/';

  @override
  String get dateHelpText => 'mm/dd/yyyy';

  @override
  String get selectYearSemanticsLabel => 'Select year';

  @override
  String get unspecifiedDate => 'Date';

  @override
  String get unspecifiedDateRange => 'Date Range';

  @override
  String get dateInputLabel => 'Enter Date';

  @override
  String get dateRangeStartLabel => 'Start Date';

  @override
  String get dateRangeEndLabel => 'End Date';

  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      'Start date $formattedDate';

  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      'End date $formattedDate';

  @override
  String get invalidDateFormatLabel => 'Invalid format.';

  @override
  String get invalidDateRangeLabel => 'Invalid range.';

  @override
  String get dateOutOfRangeLabel => 'Out of range.';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get datePickerHelpText => 'Select date';

  @override
  String get dateRangePickerHelpText => 'Select range';

  @override
  String get calendarModeButtonLabel => 'Switch to calendar';

  @override
  String get inputDateModeButtonLabel => 'Switch to input';

  @override
  String get timePickerDialHelpText => 'Select time';

  @override
  String get timePickerInputHelpText => 'Enter time';

  @override
  String get timePickerHourLabel => 'Hour';

  @override
  String get timePickerMinuteLabel => 'Minute';

  @override
  String get invalidTimeLabel => 'Enter a valid time';

  @override
  String get dialModeButtonLabel => 'Switch to dial picker mode';

  @override
  String get inputTimeModeButtonLabel => 'Switch to text input mode';

  String _formatDayPeriod(TimeOfDay timeOfDay) {
    return switch (timeOfDay.period) {
      DayPeriod.am => anteMeridiemAbbreviation,
      DayPeriod.pm => postMeridiemAbbreviation,
    };
  }

  @override
  String formatDecimal(int number) {
    if (number > -1000 && number < 1000) return number.toString();

    final String digits = number.abs().toString();
    final StringBuffer result = StringBuffer(number < 0 ? '-' : '');
    final int maxDigitIndex = digits.length - 1;
    for (int i = 0; i <= maxDigitIndex; i += 1) {
      result.write(digits[i]);
      if (i < maxDigitIndex && (maxDigitIndex - i) % 3 == 0) {
        result.write(',');
      }
    }
    return result.toString();
  }

  @override
  String formatTimeOfDay(TimeOfDay timeOfDay,
      {bool alwaysUse24HourFormat = false}) {
    // Not using intl.DateFormat for two reasons:
    //
    // - DateFormat supports more formats than our material time picker does,
    //   and we want to be consistent across time picker format and the string
    //   formatting of the time of day.
    // - DateFormat operates on DateTime, which is sensitive to time eras and
    //   time zones, while here we want to format hour and minute within one day
    //   no matter what date the day falls on.
    final StringBuffer buffer = StringBuffer();

    // Add hour:minute.
    buffer
      ..write(
          formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat))
      ..write(':')
      ..write(formatMinute(timeOfDay));

    if (alwaysUse24HourFormat) {
      // There's no AM/PM indicator in 24-hour format.
      return '$buffer';
    }

    // Add AM/PM indicator.
    buffer
      ..write(' ')
      ..write(_formatDayPeriod(timeOfDay));
    return '$buffer';
  }

  @override
  String get openAppDrawerTooltip => 'Open navigation menu';

  @override
  String get backButtonTooltip => 'Back';

  @override
  String get clearButtonTooltip => 'Clear text';

  @override
  String get closeButtonTooltip => 'Close';

  @override
  String get deleteButtonTooltip => 'Delete';

  @override
  String get moreButtonTooltip => 'More';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get previousMonthTooltip => 'Previous month';

  @override
  String get nextPageTooltip => 'Next page';

  @override
  String get previousPageTooltip => 'Previous page';

  @override
  String get firstPageTooltip => 'First page';

  @override
  String get lastPageTooltip => 'Last page';

  @override
  String get showMenuTooltip => 'Show menu';

  @override
  String get drawerLabel => 'Navigation menu';

  @override
  String get menuBarMenuLabel => 'Menu bar menu';

  @override
  String get popupMenuLabel => 'Popup menu';

  @override
  String get dialogLabel => 'Dialog';

  @override
  String get alertDialogLabel => 'Alert';

  @override
  String get searchFieldLabel => 'Search';

  @override
  String get currentDateLabel => 'Today';

  @override
  String get selectedDateLabel => 'Selected';

  @override
  String get scrimLabel => 'Scrim';

  @override
  String get bottomSheetLabel => 'Bottom Sheet';

  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      'Close $modalRouteContentName';

  @override
  String aboutListTileTitle(String applicationName) => 'About $applicationName';

  @override
  String get licensesPageTitle => 'Licenses';

  @override
  String licensesPackageDetailText(int licenseCount) {
    assert(licenseCount >= 0);
    return switch (licenseCount) {
      0 => 'No licenses.',
      1 => '1 license.',
      _ => '$licenseCount licenses.',
    };
  }

  @override
  String pageRowsInfoTitle(
      int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    return rowCountIsApproximate
        ? '$firstRow–$lastRow of about $rowCount'
        : '$firstRow–$lastRow of $rowCount';
  }

  @override
  String get rowsPerPageTitle => 'Rows per page:';

  @override
  String tabLabel({required int tabIndex, required int tabCount}) {
    assert(tabIndex >= 1);
    assert(tabCount >= 1);
    return 'Tab $tabIndex of $tabCount';
  }

  @override
  String selectedRowCountTitle(int selectedRowCount) {
    return switch (selectedRowCount) {
      0 => 'No items selected',
      1 => '1 item selected',
      _ => '$selectedRowCount items selected',
    };
  }

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get closeButtonLabel => 'Close';

  @override
  String get continueButtonLabel => 'Continue';

  @override
  String get copyButtonLabel => 'Copy';

  @override
  String get cutButtonLabel => 'Cut';

  @override
  String get scanTextButtonLabel => 'Scan text';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get pasteButtonLabel => 'Paste';

  @override
  String get selectAllButtonLabel => 'Select all';

  @override
  String get lookUpButtonLabel => 'Look Up';

  @override
  String get searchWebButtonLabel => 'Search Web';

  @override
  String get shareButtonLabel => 'Share';

  @override
  String get viewLicensesButtonLabel => 'View licenses';

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get timePickerHourModeAnnouncement => 'Select hours';

  @override
  String get timePickerMinuteModeAnnouncement => 'Select minutes';

  @override
  String get modalBarrierDismissLabel => 'Dismiss';

  @override
  String get menuDismissLabel => 'Dismiss menu';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.englishLike;

  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) {
    return alwaysUse24HourFormat
        ? TimeOfDayFormat.HH_colon_mm
        : TimeOfDayFormat.h_colon_mm_space_a;
  }

  @override
  String get signedInLabel => 'Signed in';

  @override
  String get hideAccountsLabel => 'Hide accounts';

  @override
  String get showAccountsLabel => 'Show accounts';

  @override
  String get reorderItemUp => 'Move up';

  @override
  String get reorderItemDown => 'Move down';

  @override
  String get reorderItemLeft => 'Move left';

  @override
  String get reorderItemRight => 'Move right';

  @override
  String get reorderItemToEnd => 'Move to the end';

  @override
  String get reorderItemToStart => 'Move to the start';

  @override
  String get expandedIconTapHint => 'Collapse';

  @override
  String get collapsedIconTapHint => 'Expand';

  @override
  String get expansionTileExpandedHint => 'double tap to collapse';

  @override
  String get expansionTileCollapsedHint => 'double tap to expand';

  @override
  String get expansionTileExpandedTapHint => 'Collapse';

  @override
  String get expansionTileCollapsedTapHint => 'Expand for more details';

  @override
  String get expandedHint => 'Collapsed';

  @override
  String get collapsedHint => 'Expanded';

  @override
  String get refreshIndicatorSemanticLabel => 'Refresh';

  /// Creates an object that provides US English resource values for the material
  /// library widgets.
  ///
  /// The [locale] parameter is ignored.
  ///
  /// This method is typically used to create a [LocalizationsDelegate].
  /// The [MaterialApp] does so by default.
  static Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
        const DefaultJalaliMaterialLocalizations());
  }

  /// A [LocalizationsDelegate] that uses [DefaultJalaliMaterialLocalizations.load]
  /// to create an instance of this class.
  ///
  /// [MaterialApp] automatically adds this value to [MaterialApp.localizationsDelegates].
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _JalaliMaterialLocalizationsDelegate();

  @override
  String remainingTextFieldCharacterCount(int remaining) {
    return switch (remaining) {
      0 => 'No characters remaining',
      1 => '1 character remaining',
      _ => '$remaining characters remaining',
    };
  }

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyAltGraph => 'AltGr';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyCapsLock => 'Caps Lock';

  @override
  String get keyboardKeyChannelDown => 'Channel Down';

  @override
  String get keyboardKeyChannelUp => 'Channel Up';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEject => 'Eject';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyFn => 'Fn';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaMacOs => 'Command';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyNumLock => 'Num Lock';

  @override
  String get keyboardKeyNumpad1 => 'Num 1';

  @override
  String get keyboardKeyNumpad2 => 'Num 2';

  @override
  String get keyboardKeyNumpad3 => 'Num 3';

  @override
  String get keyboardKeyNumpad4 => 'Num 4';

  @override
  String get keyboardKeyNumpad5 => 'Num 5';

  @override
  String get keyboardKeyNumpad6 => 'Num 6';

  @override
  String get keyboardKeyNumpad7 => 'Num 7';

  @override
  String get keyboardKeyNumpad8 => 'Num 8';

  @override
  String get keyboardKeyNumpad9 => 'Num 9';

  @override
  String get keyboardKeyNumpad0 => 'Num 0';

  @override
  String get keyboardKeyNumpadAdd => 'Num +';

  @override
  String get keyboardKeyNumpadComma => 'Num ,';

  @override
  String get keyboardKeyNumpadDecimal => 'Num .';

  @override
  String get keyboardKeyNumpadDivide => 'Num /';

  @override
  String get keyboardKeyNumpadEnter => 'Num Enter';

  @override
  String get keyboardKeyNumpadEqual => 'Num =';

  @override
  String get keyboardKeyNumpadMultiply => 'Num *';

  @override
  String get keyboardKeyNumpadParenLeft => 'Num (';

  @override
  String get keyboardKeyNumpadParenRight => 'Num )';

  @override
  String get keyboardKeyNumpadSubtract => 'Num -';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeyPower => 'Power';

  @override
  String get keyboardKeyPowerOff => 'Power Off';

  @override
  String get keyboardKeyPrintScreen => 'Print Screen';

  @override
  String get keyboardKeyScrollLock => 'Scroll Lock';

  @override
  String get keyboardKeySelect => 'Select';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeySpace => 'Space';
}
