# Flutter integration

[Documentation index](README.md)

Material pickers require matching calendar date values, calendar arithmetic,
and calendar localizations. Import all three public libraries:

```dart
import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/default_localizations.dart';
```

## Calendar and localization pairing

| Calendar | Date values | Arithmetic delegate | Built-in localization |
| --- | --- | --- | --- |
| Gregorian | Native `DateTime` | Flutter `GregorianCalendarDelegate` | App's ordinary Material localizations |
| Persian | `PersianDateTime` | `PersianCalendarDelegate` | `DefaultPersianCalendarMaterialLocalizations.delegate` |
| Umm al-Qura | `HijriDateTime` | `HijriCalendarDelegate` | `DefaultHijriCalendarMaterialLocalizations.delegate` |

The two built-in custom localizations support English (`en`). For translated
labels and localized input, use the companion formatter's matching localization
delegate, and configure Flutter widget localizations and text direction for the
app's supported locales.

Scope the localization with `Localizations.override` when an application mixes
calendars. Flutter selects the first supported Material localization delegate in
a scope; installing competing calendars globally can produce incorrect labels
or parsing.

## Single-date dialog

The following function can be called from a button inside a `MaterialApp`:

```dart
Future<DateTime?> pickPersianDate(BuildContext context) {
  return showDatePicker(
    context: context,
    initialDate: PersianDateTime(1403, 1, 1),
    firstDate: PersianDateTime(1400, 1, 1),
    lastDate: PersianDateTime(1410, 12, 29),
    currentDate: PersianDateTime.now(),
    calendarDelegate: const PersianCalendarDelegate(),
    builder: (context, child) => Localizations.override(
      context: context,
      locale: const Locale('en'),
      delegates: const [
        DefaultPersianCalendarMaterialLocalizations.delegate,
      ],
      child: child!,
    ),
  );
}
```

Cancellation returns `null`; selection returns a Persian calendar date-time.
Use the same pairing for an inline `CalendarDatePicker`. For a standalone
`YearPicker`, explicitly supply a matching `currentDate`; its native default
clock is Gregorian. The [example application](../example/lib/main.dart) embeds
all three calendars side by side.

## Range dialog

Use the bounded range adapter and compatibility builder:

```dart
Future<DateTimeRange<DateTime>?> pickPersianRange(
  BuildContext context, {
  DateTimeRange<DateTime>? initialDateRange,
}) {
  final delegate = const PersianCalendarDelegate().rangePickerDelegate;
  return showDateRangePicker(
    context: context,
    firstDate: PersianDateTime(1400, 1, 1),
    lastDate: PersianDateTime(1410, 12, 29),
    currentDate: PersianDateTime.now(),
    initialDateRange: initialDateRange,
    calendarDelegate: delegate,
    builder: calendarDateRangePickerBuilder(
      delegate,
      builder: (context, child) => Localizations.override(
        context: context,
        locale: const Locale('en'),
        delegates: const [
          DefaultPersianCalendarMaterialLocalizations.delegate,
        ],
        child: child!,
      ),
    ),
  );
}
```

Both returned endpoints are `PersianDateTime`, despite the `DateTime` return
type. The selected last date is inclusive. Civil ranges use an exclusive end;
see [calendar operations](calendar-operations.md) when converting them.

The source helper addresses delegate forwarding on the package's minimum
Flutter 3.32 SDK. Pass the same delegate instance to the picker and builder.
The helper preserves dialog options, locale, and direction; place application
localization/theme wrappers in its optional `builder`. A dialog already using
the supplied delegate passes through unchanged. When constructing
`DateRangePickerDialog` directly, set its `calendarDelegate` directly.

Flutter can probe empty leading cells or adjacent keyboard targets outside a
calendar's finite bounds. `rangePickerDelegate` handles those comparison probes
without allowing unsupported selectable dates. Use the ordinary delegate for
single-date pickers and general calendar arithmetic.

For Hijri, replace every date, delegate, and localization in the examples with
its corresponding Hijri type. Keep all values within that chronology's bounds.

## Switching calendars and diagnosing failures

Every date argument must have the matching runtime type, including bounds,
current date, selected values, comparisons, and non-null parser results. Delegate
guards throw `ArgumentError` for incompatible values even when their instants
are identical.

Convert saved native dates explicitly:

```dart
final converted = PersianDateTime.fromDateTime(savedGregorianDate);
```

Constructing `PersianDateTime(savedGregorianDate.year, ...)` instead treats the
Gregorian numbers as Persian fields. When switching calendars, convert or clear
the saved selection, then verify ordering and picker bounds.

| Symptom | Check |
| --- | --- |
| `ArgumentError` from a delegate | Runtime types of all dates and localization parser results |
| Incorrect month names or input help | Ambient Material localization matches the calendar |
| Range dialog behaves Gregorian | Same range delegate supplied to picker and compatibility builder |
| Boundary navigation throws | Range adapter in use and selectable dates within supported bounds |
| Calendar fields change after field replacement | Use `CalendarDateUtils` on `DateTime`-typed values |

Regression references:
[`calendar_delegate_type_guard_test.dart`](../test/unit/calendar_delegate_type_guard_test.dart),
[`calendar_picker_critical_test.dart`](../test/unit/calendar_picker_critical_test.dart),
and [`calendar_range_picker_boundary_test.dart`](../test/unit/calendar_range_picker_boundary_test.dart).
