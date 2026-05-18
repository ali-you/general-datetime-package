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
<a href="https://github.com/ali-you/general-datetime-package">
   <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/ali-you/general-datetime-package">
</a>

![Flutter CI](https://github.com/ali-you/general-date-package/actions/workflows/flutter.yml/badge.svg)

A Flutter/Dart Package for working with dates across several calendar systems. Using a unified
interface, you can convert, manipulate, and compare dates in Gregorian, Persian (Jalali),
Hijri (Umm Al-Qura), and other
calendar systems—all while preserving time components and handling timezone, leap year, and negative
value normalization gracefully.

## Related Packages

A Flutter/Dart Package for working with dates across several calendar systems. Using a unified
interface, you can convert, manipulate, and compare dates in Gregorian, Persian (Jalali),
Hijri (Umm Al-Qura), and other
calendar systems—all while preserving time components and handling timezone, leap year, and negative
value normalization gracefully.

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
}
```

### Hijri Calendar (Umm al-Qura)

```dart
void main() {
  // Create a Gregorian date and convert it to Hijri dates:
  HijriDateTime hDate = HijriDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(hDate.toString()); // 1446-08-30 00:00:00.000

  // Create a Hijri date directly:
  HijriDateTime directDate = HijriDateTime(1446, 9, 1);
}
```

## Flutter Integration (Localization & Delegates)

To use these calendars with Flutter's Material widgets like `CalendarDatePicker`, you need to configure `localizationsDelegates` and `calendarDelegate`.

### 1. Configure MaterialApp

Add the localization delegates to your `MaterialApp`:

```dart
import 'package:general_datetime/default_localizations.dart';

MaterialApp(
  localizationsDelegates: [
    DefaultPersianCalendarMaterialLocalizations.delegate,
    DefaultHijriCalendarMaterialLocalizations.delegate,
    // Add other delegates...
  ],
  // ...
)
```

### 2. Use with CalendarDatePicker

Pass the corresponding delegate to change the calendar system:

```dart
import 'package:general_datetime/delegates.dart';

CalendarDatePicker(
  initialDate: PersianDateTime.now(),
  firstDate: PersianDateTime(1400, 1, 1),
  lastDate: PersianDateTime(1450, 12, 31),
  calendarDelegate: PersianCalendarDelegate(),
  onDateChanged: (DateTime date) {
    print("Selected: $date");
  },
)
```

For Hijri, use `HijriCalendarDelegate()` and `HijriDateTime`.

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
> Ensure you implement a robust `_normalize()` method to handle invalid inputs (e.g., month 13, day 32) and a conversion path via Julian Day Number for accuracy.

## Calendars

### Persian Calendar

The Persian calendar (Jalali) is a solar calendar first formalized in 1079 CE under Omar Khayyam
that measures years by the true motion of the Earth around the Sun, yielding an average year length
of approximately 365.2424 days—more accurate over centuries than the Gregorian’s 365.2425-day
average. It begins its era on the vernal equinox of 622 CE (the Hijra), and structures time into
twelve months: the first six of 31 days, the next five of 30 days, and the final month of 29 days in
a common year or 30 days in a leap year. Leap years follow an intricate 33-year cycle (with
occasional 29- or 37-year adjustments), tracked in code by a series of “break points” that align
groups of eight leap years within each cycle. Converting between Persian dates and Gregorian dates uses the
Julian Day Number (JDN) as an intermediary—counting days from a fixed epoch—then applying standard
astronomical floor-division formulas to translate JDN to Gregorian and back. Overflow or negative
values in any date or time component are normalized by carrying into higher or lower units, so that
inputs like “month 13” or “day 0” correctly wrap into valid Persian dates. This blend of astronomical
anchoring, cycle-based leap determination, and normalization yields a calendar that keeps Nowruz (
the spring equinox) synchronized with the real equinox with minimal drift over millennia.

### Persian Calendar

The Persian calendar (Jalali) is a solar calendar first formalized in 1079 CE under Omar Khayyam
that measures years by the true motion of the Earth around the Sun, yielding an average year length
of approximately 365.2424 days—more accurate over centuries than the Gregorian’s 365.2425-day
average. It begins its era on the vernal equinox of 622 CE (the Hijra), and structures time into
twelve months: the first six of 31 days, the next five of 30 days, and the final month of 29 days in
a common year or 30 days in a leap year. Leap years follow an intricate 33-year cycle (with
occasional 29- or 37-year adjustments), tracked in code by a series of “break points” that align
groups of eight leap years within each cycle. Converting between Persian dates and Gregorian dates uses the
Julian Day Number (JDN) as an intermediary—counting days from a fixed epoch—then applying standard
astronomical floor-division formulas to translate JDN to Gregorian and back. Overflow or negative
values in any date or time component are normalized by carrying into higher or lower units, so that
inputs like “month 13” or “day 0” correctly wrap into valid Persian dates. This blend of astronomical
anchoring, cycle-based leap determination, and normalization yields a calendar that keeps Nowruz (
the spring equinox) synchronized with the real equinox with minimal drift over millennia.

Read
more: [Persian Calendar (EMP) paper](https://www.astro.uni.torun.pl/~kb/Papers/EMP/PersianC-EMP.htm)

### Hijri Calendar (Umm al-Qura)

The Hijri calendar is a lunar calendar consisting of 12 months in a year of 354 or 355 days. This implementation uses the **Umm al-Qura** calculation method, which is the official calendar of Saudi Arabia and is widely used for religious and administrative purposes. It is based on astronomical calculations of the moon's position. 

Leap years in this system are determined by a 30-year cycle where years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, and 29 are leap years. Similar to the Persian implementation, it uses Julian Day Numbers for precise conversion between Gregorian and Hijri systems and supports full normalization for overflow and underflow in all date and time components.

## Contributions

Contributions are welcome! If you have suggestions, fixes, or new features, please submit a pull
request or open an issue on GitHub.

## Licence

This project is licensed under the BSD 3-Clause License. See the [LICENSE](https://github.com/ali-you/general-datetime-package/blob/main/LICENSE) file for details.
