# General Datetime (Dynamic Calendar)

<a href="https://pub.dev/packages/general_datetime">
   <img src="https://img.shields.io/pub/v/general_datetime?label=pub.dev&labelColor=333940&logo=dart">
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues">
   <img alt="Issues" src="https://img.shields.io/github/issues/ali-you/general-datetime-package?color=0088ff" />
</a>
<a href="https://github.com/ali-you/general-datetime-package/issues?q=is%3Aclosed">
   <img alt="Issues" src="https://img.shields.io/github/issues-closed/ali-you/general-datetime-package?color=0088ff" />
</a>
<!-- <a href="https://github.com/ali-you/ambient-light-plugin/pulls">
   <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/ali-you/ambient-light-plugin?color=0088ff" />
</a> -->
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
interface, you can convert, manipulate, and compare dates in Gregorian, Jalali (Persian Calendar),
Hijri (Umm Al-Qura Calendar), and other
calendar systems—all while preserving time components and handling timezone, leap year, and negative
value normalization gracefully.

## Features

- **Gregorian ↔ Other calendars:**
  Convert between Gregorian and other dates with high precision, preserving time components (hours,
  minutes, seconds, milliseconds, and microseconds).

- **Leap Year Handling:**
  Detect and correctly handle leap years and leap days, including automatic correction of invalid
  leap dates.

- **Custom Arithmetic:**
  Perform date arithmetic using custom implementations of add, subtract, and difference that work
  directly on calendar fields.

- **Negative Normalization:**
  Automatically normalize negative values in day, month, hour, minute, second, millisecond and
  microsecond components.

- **Time Zone Support:**
  Retrieve the time zone name and offset matching Flutter’s DateTime behavior for both local and UTC
  dates.

- **Parsing and Formatting:**
  Create JalaliDatetime instances from formatted strings and output a consistent string
  representation.

## Installation

To use this plugin, you can add it to your Flutter project in one of two ways:

### 1. Add to `pubspec.yaml`

Include the following dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  jalali_datetime: ^0.1.1

```

### 2. Add directly from the terminal

Run the following command to add the plugin directly to your project:

```bash
flutter pub add jalali_datetime
```

## Usage

Import the package into your Dart code. The library exposes a unified interface for working with
dates across multiple calendar systems. For example, you can work with the Jalali calendar using the
provided implementation:

```dart
import 'package:general_datetime/general_datetime.dart';
import 'package:shamsi_date/shamsi_date.dart'; // Your concrete implementation

void main() {
  // Create a Gregorian date and convert it to Jalali:
  JalaliDatetime jDate = JalaliDatetime.fromDatetime(DateTime(2025, 3, 1));
  print('Converted to Jalali: ${jDate.toString()}'); // e.g. "1403-12-11 00:00:00.000"

  // Create a Jalali date directly (auto-normalization applies):
  JalaliDatetime directDate = JalaliDatetime(1403, 12, 11, 14, 30);
  print('Direct Jalali: ${directDate.toString()}');

  // Perform arithmetic:
  JalaliDatetime futureDate = jDate.add(Duration(days: 5, hours: 3));
  print('Future Date: ${futureDate.toString()}');

  // Compare dates:
  bool isBefore = jDate.isBefore(JalaliDatetime(1403, 12, 12));
  print('Is jDate before 1403-12-12? $isBefore');

  // Parse a date string:
  JalaliDatetime parsed = JalaliDatetime.parse("1403-12-11 14:30:45.123456Z");
  print('Parsed Date: ${parsed.toString()}');

  // Time zone information:
  print('Time Zone Name: ${jDate.timeZoneName}');
  print('Time Zone Offset: ${jDate.timeZoneOffset}');
}

```

- Checkout [Example](https://pub.dev/packages/general_datetime/example) for complete explanation

## API Overview

### Factory Constructors

- `fromDatetime(DateTime datetime)`
  Converts a Gregorian [DateTime] to a calendar-specific date (e.g. Jalali).

- `now()`
  Returns the current date and time in the default calendar.

- `utc(...)`
  Creates a UTC date with normalization.

- `fromSecondsSinceEpoch(...)`
  Creates an instance from Unix seconds.

- `fromMillisecondsSinceEpoch(...)`
  Creates an instance from Unix milliseconds.

- `fromMicrosecondsSinceEpoch(...)`
  Creates an instance from Unix microseconds.

- `parse(String formattedString)` and `tryParse(String formattedString)`
  Parse ISO-like formatted strings into a calendar date.

### Core Properties

- **Date Components:**
  `year`, `month`, `day`, `hour`, `minute`, `second`, `millisecond`, `microsecond`

- **Time Zone Information:**
  `timeZoneName` and `timeZoneOffset` behave similar to Flutter’s DateTime.

- `isLeapYear`
  Returns true if the current year is a leap year in the current calendar system.

- `dayOfYear`
  Returns the day of the year (1-based).

- `julianDay`
  The calculated Julian day number for the date.

### Arithmetic & Comparison

- **Arithmetic Methods:**
  `add(Duration duration)`, `subtract(Duration duration)` Implemented independently (without relying
  on native DateTime arithmetic).

- **Difference:**
  `difference(dynamic other)` returns a Duration representing the difference between two dates.

- **Comparison:**
  `compareTo(dynamic other)`, `isBefore`, `isAfter`, `isAtSameMomentAs` Compare calendar dates
  across systems.

## Customization

Since this plugin is based on a general date interface, you can extend its functionality to support
additional calendar systems.

> [!IMPORTANT] Always Normalize and Convert Internally:
> It’s critical that you implement a robust _normalize() method to ensure that any invalid date or
> time input is adjusted to a valid state, avoiding exceptions. Additionally, provide a private
> conversion function (e.g., _toCustomCalendar()) that converts from the base calendar (usually
> Gregorian) to your custom calendar. These helper functions must be private and only used within
> the factory constructors so that users always receive a fully normalized, valid date instance.

> [!TIP] Separate Raw Construction from Normalization:
> When adding support for a new calendar, it’s recommended to implement factory constructors that
> use a private “raw” constructor. This raw factory should create an instance with unmodified input
> data. Then, call private helper methods (e.g., _normalize() and a conversion method such as
> _toCustomCalendar()) to validate and adjust the values. This approach keeps raw data creation
> separate from data manipulation, making the code more modular and easier to debug.

[//]: # (> [!NOTE])

[//]: # (> Useful information that users should know, even when skimming content.)

[//]: # ()

[//]: # (> [!TIP])

[//]: # (> Helpful advice for doing things better or more easily.)

[//]: # ()

[//]: # (> [!IMPORTANT])

[//]: # (> Key information users need to know to achieve their goal.)

[//]: # ()

[//]: # (> [!WARNING])

[//]: # (> Urgent info that needs immediate user attention to avoid problems.)

[//]: # ()

[//]: # (> [!CAUTION])

[//]: # (> Advises about risks or negative outcomes of certain actions.)

## Contributions

Contributions are welcome! If you have suggestions, fixes, or new features, please submit a pull
request or open an issue on GitHub.

## Licence

This project is licensed under the BSD 3-Clause License. See
the [LICENSE](https://github.com/ali-you/general-datetime-package?tab=BSD-3-Clause-1-ov-file)  file
for details.
