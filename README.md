# General DateTime (Dynamic Calendar)

<a href="https://pub.dev/packages/general_datetime">
   <img src="https://img.shields.io/pub/v/general_datetime?label=pub.dev&labelColor=333940&logo=dart">
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues">
   <img alt="Issues" src="https://img.shields.io/github/issues/ali-you/general-datetime-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues?q=is%3Aclosed">
   <img alt="Issues" src="https://img.shields.io/github/issues-closed/ali-you/general-datetime-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/pulls">
   <img alt="GitHub Pull Requests" src="https://badgen.net/github/prs/ali-you/general-datetime-package" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/blob/main/LICENSE" rel="ugc">
   <img src="https://img.shields.io/github/license/ali-you/general-datetime-package?color=#007A88&amp;labelColor=333940;" alt="GitHub">
</a>
<a href="https://github.com/ali-you/general-datetime-package">
   <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ali-you/general-datetime-package">
</a>

![Flutter CI](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml/badge.svg)

A Flutter/Dart Package for working with dates across several calendar systems. Using a unified
interface, you can convert, manipulate, and compare dates in Gregorian, Persian (Jalali),
Hijri (Umm al-Qura), and other
calendar systems—all while preserving time components and handling timezone, leap year, and negative
value normalization within each calendar's documented range.

## Related Packages

| Version                                                                                                                      | Package                                                             | Description                                                             |
|------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|
| [![general_date_format](https://img.shields.io/pub/v/general_date_format.svg)](https://pub.dev/packages/general_date_format) | [general_date_format](https://pub.dev/packages/general_date_format) | Date formatting for multiple calendar systems with localization support |

## Features

- **Gregorian ↔ Other calendars:**
  Convert between Gregorian and other dates with high precision, preserving time components (hours,
  minutes, seconds, milliseconds, and microseconds).

- **Leap Year Handling:**
  Detect and correctly handle leap years and leap days, including automatic correction of invalid
  leap dates.

- **Custom Arithmetic:**
  Perform date arithmetic using custom implementations of `add`, `subtract`, and `difference` that work
  directly on calendar fields.

- **Negative Normalization:**
  Automatically normalize negative or overflow values in day, month, hour, minute, second, millisecond, and
  microsecond components.

- **Time Zone Support:**
  Retrieve the time zone name and offset matching Flutter’s `DateTime` behavior for both local and UTC
  dates.

- **Parsing and Formatting:**
  Create custom datetime (`PersianDateTime`, `HijriDateTime`) instances from formatted strings.

- **Flutter Integration:**
  Full support for `MaterialLocalizations` and `CalendarDelegate` for both Persian and Hijri calendars, allowing seamless integration with Flutter's `DatePicker`.

## Installation

To use this plugin, add it to your project:

### 1. Add to `pubspec.yaml`

```yaml
dependencies:
  general_datetime: <latest_version>

```

### 2. Install from terminal

```bash
flutter pub add general_datetime
```

## Usage

Import the package into your Dart code:

```dart
import 'package:general_datetime/general_datetime.dart';
```

### Persian Calendar (Jalali)

```dart
void main() {
  // Create a Gregorian date and convert it to Persian dates:
  PersianDateTime pDate = PersianDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(pDate.toString()); // 1403-12-11 00:00:00.000

  // Create a Persian date directly (auto-normalization applies):
  PersianDateTime directDate = PersianDateTime(1403, 12, 11, 14, 30);
  
  // Arithmetic:
  var nextWeek = directDate.add(Duration(days: 7));

  // The implementation is bounded by the official source data:
  print(PersianDateTime.minimumYear); // 1206
  print(PersianDateTime.maximumYear); // 1498
}
```

### Hijri Calendar (Umm al-Qura)

```dart
void main() {
  // Create a Gregorian date and convert it to Hijri dates:
  HijriDateTime hDate = HijriDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(hDate.toString()); // 1446-09-01 00:00:00.000

  // Create a Hijri date directly:
  HijriDateTime directDate = HijriDateTime(1446, 9, 1);
}
```

## Flutter Integration (Localization & Delegates)

Use the matching `CalendarDelegate` with Flutter Material date pickers. Both
delegates own their calendar-specific formatting and parsing, so neither needs
a replacement global `MaterialLocalizations`.

### Use with CalendarDatePicker

Pass the corresponding delegate to change the calendar system:

```dart
import 'package:general_datetime/delegates.dart';

CalendarDatePicker(
  initialDate: PersianDateTime.now(),
  firstDate: PersianDateTime(1380, 1, 1),
  lastDate: PersianDateTime(1450, 12, 29),
  calendarDelegate: PersianCalendarDelegate.persian(),
  onDateChanged: (DateTime date) {
    print("Selected: $date");
  },
)
```

The old replacement localization delegates remain available for compatibility,
but are not needed with `PersianCalendarDelegate` or `HijriCalendarDelegate`.
Do not register both legacy replacements in one `MaterialApp`: both provide the
same `MaterialLocalizations` type, so Flutter can load only one per locale.

## API Overview

### Factory Constructors

- `fromDateTime(DateTime datetime)`: Converts Gregorian to target calendar.
- `now()`: Current date and time in the target calendar.
- `utc(...)`: Creates a UTC date with normalization.
- `parse(String formattedString)`: Parse ISO-like strings.

### Core Properties

- `year`, `month`, `day`, `hour`, `minute`, `second`, `millisecond`, `microsecond`.
- `timeZoneName`, `timeZoneOffset`.
- `isLeapYear`: Whether the year is a leap year in that specific calendar.
- `dayOfYear`: 1-based day of the year.
- `julianDay`: The calculated Julian day number.

### Generic Current Time

Use the generic interface to get the current time for any supported type:

```dart
var nowPersian = GeneralDateTimeInterface.now<PersianDateTime>();
var nowHijri = GeneralDateTimeInterface.now<HijriDateTime>();
```

## Customization

You can extend `GeneralDateTimeInterface` to support additional calendar systems.

> [!IMPORTANT]
> Ensure custom calendars define their supported range, normalization rules,
> and an independently verified conversion model.

## Calendars

### Persian Calendar

The Iranian Solar Hijri calendar is astronomical; it is not safely represented
by an indefinitely repeating 33-year or 2820-year arithmetic cycle. This
implementation uses the University of Tehran Calendar Center's published leap
results for SH 1206 through 1498, anchored to its official annual calendars.
The supported civil interval is SH 1206-01-01 through 1498-12-30 (Gregorian
1827-03-22 through 2120-03-20). Dates outside it throw `RangeError` instead of
silently switching algorithms.

The first six months contain 31 days, the next five contain 30, and Esfand has
29 or 30 according to the published leap data. Gregorian conversion, UTC/local
behavior, parsing, epoch constructors, arithmetic, equality, hashing, and
overflow normalization preserve the true native `DateTime` instant at
microsecond precision.

The official-source decision, a discrepancy found in one source PDF, exact
data hashes, and exhaustive validation method are documented in
[`PERSIAN_CALENDAR_VALIDATION.md`](PERSIAN_CALENDAR_VALIDATION.md).

### Hijri Calendar (Umm al-Qura)

The Hijri calendar is lunar and has 12 months. This implementation uses the
published **Umm al-Qura** month data used by Unicode ICU and OpenJDK, rather
than the repeating 30-year arithmetic Islamic calendar. The verified range is
AH 1300-01-01 through AH 1600-12-30 (Gregorian 1882-11-12 through
2174-11-25). Dates outside that finite range throw `RangeError`; the
implementation never silently falls back to a different Hijri calendar.

Month lengths and 354/355-day years come directly from the Umm al-Qura data.
Gregorian conversion, UTC/local behavior, parsing, epoch constructors,
arithmetic, and overflow normalization all preserve the native `DateTime`
instant at microsecond precision.

Data provenance and the Unicode license notice are recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Contributions

Contributions are welcome! If you have suggestions, fixes, or new features, please submit a pull
request or open an issue on GitHub.

## Licence

This project is licensed under the BSD 3-Clause License. See the [LICENSE](https://github.com/ali-you/general-datetime-package/blob/main/LICENSE) file for details.
