import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/src/persian_date_time.dart';

abstract class GeneralDateTimeInterface<T> {
  static GeneralDateTimeInterface now<T extends GeneralDateTimeInterface>() {
    if (T == PersianDateTime) return PersianDateTime.now();
    if (T == HijriDateTime) return HijriDateTime.now();
    throw TypeError();
  }

  /// The calendar name
  /// for example "Persian" for Persian calendar
  String get name;

  /// The time zone name.
  ///
  /// This value is provided by the operating system and may be an
  /// abbreviation or a full name.
  ///
  /// In the browser or on Unix-like systems commonly returns abbreviations,
  /// such as "CET" or "CEST". On Windows returns the full name, for example
  /// "Pacific Standard Time".
  String get timeZoneName => toDateTime().timeZoneName;

  /// The time zone offset, which is the difference between local time and UTC.
  /// The offset is positive for time zones east of UTC.
  ///
  /// Note, that JavaScript, Python and C return the difference between UTC and
  /// local time. Java, C# and Ruby return the difference between local time and
  /// UTC.
  ///
  /// For example, using local time in San Francisco, United States:
  /// ```dart
  /// final dateUS = DateTime.parse('2021-11-01 20:18:04Z').toLocal();
  /// print(dateUS); // 2021-11-01 13:18:04.000
  /// print(dateUS.timeZoneName); // PDT ( Pacific Daylight Time )
  /// print(dateUS.timeZoneOffset.inHours); // -7
  /// print(dateUS.timeZoneOffset.inMinutes); // -420
  /// ```
  ///
  /// For example, using local time in Canberra, Australia:
  /// ```dart
  /// final dateAus = DateTime.parse('2021-11-01 20:18:04Z').toLocal();
  /// print(dateAus); // 2021-11-02 07:18:04.000
  /// print(dateAus.timeZoneName); // AEDT ( Australian Eastern Daylight Time )
  /// print(dateAus.timeZoneOffset.inHours); // 11
  /// print(dateAus.timeZoneOffset.inMinutes); // 660
  /// ```
  Duration get timeZoneOffset => toDateTime().timeZoneOffset;

  /// Calculate weekday according to the calendar type
  int get weekday;

  /// Get days in the current month according to the calendar
  int get monthLength;

  int get dayOfYear;

  /// Check if the year is a leap year according to the calendar
  bool get isLeapYear;

  /// Julian Day Number getter
  int get julianDay;

  /// Convert T calendar type to DateTime
  DateTime toDateTime();

  /// Add a Duration to the custom date
  T add(Duration duration);

  /// Subtract a Duration from the custom date
  T subtract(Duration duration);

  /// Convert to local time
  T toLocal();

  /// Convert to UTC time
  T toUtc();

  /// Seconds since epoch
  int get secondsSinceEpoch;

  /// Milliseconds since epoch
  int get millisecondsSinceEpoch;

  /// Microseconds since epoch
  int get microsecondsSinceEpoch;

  /// Compares this dateTime instance to another.
  /// This method allows comparison between different types that implement
  /// [GeneralDateTimeInterface] as well as native [DateTime] objects.
  /// Returns:
  /// - A negative integer if `this` occurs before [other]
  /// - Zero if `this` and [other] represent the same moment in time
  /// - A positive integer if `this` occurs after [other]
  /// Example:
  /// ```dart
  /// final a = PersianDateTime(1403, 4, 15, 10);
  /// final b = PersianDateTime(1403, 4, 15, 12);
  /// final c = DateTime(2024, 7, 5, 12);
  ///
  /// a.compareTo(b); // < 0
  /// b.compareTo(a); // > 0
  /// b.compareTo(b); // == 0
  /// b.compareTo(c); // Compare to native DateTime
  /// ```
  int compareTo(DateTime other);

  /// Checks whether this dateTime occurs before another.
  /// This method compares this instance with [other], which can be either:
  /// - Another object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if this dateTime is before [other], otherwise `false`.
  /// Example:
  /// ```dart
  /// final a = PersianDateTime(1403, 4, 15, 10);
  /// final b = PersianDateTime(1403, 4, 15, 12);
  ///
  /// a.isBefore(b); // true
  /// b.isBefore(a); // false
  ///
  /// final native = DateTime(2025, 7, 6, 14);
  /// b.isBefore(native); // true or false depending on internal conversion
  /// ```
  bool isBefore(DateTime other);

  /// Checks whether this dateTime occurs after another.
  /// Compares this instance with [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if this dateTime is after [other], otherwise `false`.
  /// Example:
  /// ```dart
  /// final a = PersianDateTime(1403, 4, 15, 12);
  /// final b = PersianDateTime(1403, 4, 15, 10);
  ///
  /// a.isAfter(b); // true
  /// b.isAfter(a); // false
  ///
  /// final native = DateTime(2025, 7, 6, 14);
  /// b.isAfter(native); // true or false depending on internal conversion
  /// ```
  bool isAfter(DateTime other);

  /// Checks whether this dateTime represents the same moment as another.
  /// Compares this instance with [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if both datetime represent the same point in time.
  /// Example:
  /// ```dart
  /// final a = PersianDateTime(1403, 4, 15, 12, 30);
  /// final b = PersianDateTime(1403, 4, 15, 12, 30);
  ///
  /// a.isAtSameMomentAs(b); // true
  ///
  /// final native = DateTime(2025, 7, 6, 14, 0);
  /// a.isAtSameMomentAs(native); // true or false depending on internal conversion
  /// ```
  bool isAtSameMomentAs(DateTime other);

  /// Returns the difference between this dateTime and another.
  /// Computes the [Duration] between this instance and [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// The result is positive if this dateTime is after [other], and negative if before.
  /// Example:
  /// ```dart
  /// final a = PersianDateTime(1403, 4, 15, 12, 30);
  /// final b = PersianDateTime(1403, 4, 15, 11, 0);
  ///
  /// final duration = a.difference(b); // 1 hour 30 minutes
  /// duration.inMinutes; // 90
  ///
  /// final native = DateTime(2025, 7, 6, 14, 0);
  /// a.difference(native);
  /// ```
  Duration difference(DateTime other);
}
