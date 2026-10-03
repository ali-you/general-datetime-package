import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A [YearPicker] whose current date defaults to [CalendarDelegate.now].
///
/// Use this widget with a matching calendar delegate and Material localizations
/// for Persian or Hijri year selection. Flutter's direct [YearPicker] defaults
/// to a native Gregorian [DateTime.now], even with a custom delegate.
///
/// All supplied dates are normalized with [CalendarDelegate.dateOnly], so the
/// delegate's calendar type checks and local-date policy apply to every input.
class CalendarYearPicker extends YearPicker {
  /// Creates a year picker using the supplied calendar's current date.
  ///
  /// An explicit [currentDate] takes precedence over [calendarDelegate.now].
  /// The current date may be outside the selectable [firstDate]/[lastDate] range.
  CalendarYearPicker({
    super.key,
    DateTime? currentDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime? selectedDate,
    required super.onChanged,
    super.dragStartBehavior = DragStartBehavior.start,
    super.calendarDelegate = const GregorianCalendarDelegate(),
  }) : super(
          currentDate: currentDate ?? calendarDelegate.now(),
          firstDate: calendarDelegate.dateOnly(firstDate),
          lastDate: calendarDelegate.dateOnly(lastDate),
          selectedDate: selectedDate == null
              ? null
              : calendarDelegate.dateOnly(selectedDate),
        );
}
