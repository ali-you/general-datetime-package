import 'package:flutter/material.dart';

/// Keeps [calendarDelegate] on the dialog created by [showDateRangePicker].
///
/// Flutter 3.32 omits the delegate when constructing [DateRangePickerDialog].
/// Supply this as the picker's `builder`, along with the same `calendarDelegate`
/// argument. Locale, text direction, dialog options, and an optional application
/// [builder] are preserved. Newer Flutter versions already preserve the delegate
/// and their dialog is passed through unchanged.
TransitionBuilder calendarDateRangePickerBuilder(
  CalendarDelegate<DateTime> calendarDelegate, {
  TransitionBuilder? builder,
}) {
  return (context, child) {
    final dialog = _withCalendarDelegate(child!, calendarDelegate);
    return builder == null ? dialog : builder(context, dialog);
  };
}

Widget _withCalendarDelegate(
    Widget child, CalendarDelegate<DateTime> calendarDelegate) {
  if (child is DateRangePickerDialog) {
    if (identical(child.calendarDelegate, calendarDelegate)) return child;
    return DateRangePickerDialog(
      key: child.key,
      initialDateRange: child.initialDateRange,
      firstDate: child.firstDate,
      lastDate: child.lastDate,
      currentDate: child.currentDate,
      initialEntryMode: child.initialEntryMode,
      helpText: child.helpText,
      cancelText: child.cancelText,
      confirmText: child.confirmText,
      saveText: child.saveText,
      errorInvalidRangeText: child.errorInvalidRangeText,
      errorFormatText: child.errorFormatText,
      errorInvalidText: child.errorInvalidText,
      fieldStartHintText: child.fieldStartHintText,
      fieldEndHintText: child.fieldEndHintText,
      fieldStartLabelText: child.fieldStartLabelText,
      fieldEndLabelText: child.fieldEndLabelText,
      keyboardType: child.keyboardType,
      restorationId: child.restorationId,
      switchToInputEntryModeIcon: child.switchToInputEntryModeIcon,
      switchToCalendarEntryModeIcon: child.switchToCalendarEntryModeIcon,
      selectableDayPredicate: child.selectableDayPredicate,
      calendarDelegate: calendarDelegate,
    );
  }
  // showDateRangePicker applies these wrappers before invoking its builder.
  if (child is Localizations) {
    return Localizations(
      key: child.key,
      locale: child.locale,
      delegates: child.delegates,
      child: _withCalendarDelegate(child.child!, calendarDelegate),
    );
  }
  if (child is Directionality) {
    return Directionality(
      key: child.key,
      textDirection: child.textDirection,
      child: _withCalendarDelegate(child.child, calendarDelegate),
    );
  }
  return child;
}
