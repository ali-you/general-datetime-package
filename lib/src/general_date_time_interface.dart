import 'package:general_datetime/general_datetime.dart';

abstract class GeneralDateTimeInterface<T>
    implements Comparable<GeneralDateTimeInterface> {
  GeneralDateTimeInterface(
    this.year, [
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
    this.microsecond = 0,
    this.isUtc = false,
  ]);

  static GeneralDateTimeInterface now<T extends GeneralDateTimeInterface>() {
    if (T == JalaliDateTime) return JalaliDateTime.now();
    if (T == HijriDateTime) return HijriDateTime.now();
    throw TypeError();
  }

  final int year;
  final int month;
  final int day;

  final int hour;
  final int minute;
  final int second;
  final int millisecond;
  final int microsecond;

  final bool isUtc;

  /// The calendar name
  /// for example "jalali" for Persian calendar
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
  int get secondsSinceEpoch => toDateTime().millisecondsSinceEpoch ~/ 1000;

  /// Milliseconds since epoch
  int get millisecondsSinceEpoch => toDateTime().millisecondsSinceEpoch;

  /// Microseconds since epoch
  int get microsecondsSinceEpoch => toDateTime().microsecondsSinceEpoch;

  /// Compares this dateTime instance to another.
  /// This method allows comparison between different types that implement
  /// [GeneralDateTimeInterface] as well as native [DateTime] objects.
  /// Returns:
  /// - A negative integer if `this` occurs before [other]
  /// - Zero if `this` and [other] represent the same moment in time
  /// - A positive integer if `this` occurs after [other]
  /// Example:
  /// ```dart
  /// final a = JalaliDateTime(1403, 4, 15, 10);
  /// final b = JalaliDateTime(1403, 4, 15, 12);
  /// final c = DateTime(2024, 7, 5, 12);
  ///
  /// a.compareTo(b); // < 0
  /// b.compareTo(a); // > 0
  /// b.compareTo(b); // == 0
  /// b.compareTo(c); // works if toDateTime() maps them to the same moment
  /// ```
  /// Throws [ArgumentError] if [other] is not a [GeneralDateTimeInterface] or [DateTime].
  @override
  int compareTo(dynamic other) {
    final DateTime selfDate = toDateTime();
    if (other is GeneralDateTimeInterface) {
      return selfDate.compareTo(other.toDateTime());
    }
    if (other is DateTime) return selfDate.compareTo(other);
    throw ArgumentError(
        'compareTo function expected GeneralDateTimeInterface or DateTime, but got ${other.runtimeType}');
  }

  /// Checks whether this dateTime occurs before another.
  /// This method compares this instance with [other], which can be either:
  /// - Another object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if this dateTime is before [other], otherwise `false`.
  /// Example:
  /// ```dart
  /// final a = JalaliDateTime(1403, 4, 15, 10);
  /// final b = JalaliDateTime(1403, 4, 15, 12);
  ///
  /// a.isBefore(b); // true
  /// b.isBefore(a); // false
  ///
  /// final native = DateTime(2025, 7, 6, 14);
  /// b.isBefore(native); // true or false depending on internal conversion
  /// ```
  /// Throws [ArgumentError] if [other] is not a [GeneralDateTimeInterface] or [DateTime].
  bool isBefore(dynamic other) {
    final DateTime selfDate = toDateTime();
    if (other is GeneralDateTimeInterface) {
      return selfDate.isBefore(other.toDateTime());
    }
    if (other is DateTime) return selfDate.isBefore(other);
    throw ArgumentError(
        'isBefore function expected GeneralDateTimeInterface or DateTime, but got ${other.runtimeType}');
  }

  /// Checks whether this dateTime occurs after another.
  /// Compares this instance with [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if this dateTime is after [other], otherwise `false`.
  /// Example:
  /// ```dart
  /// final a = JalaliDateTime(1403, 4, 15, 12);
  /// final b = JalaliDateTime(1403, 4, 15, 10);
  ///
  /// a.isAfter(b); // true
  /// b.isAfter(a); // false
  /// ```
  /// Throws an [ArgumentError] if [other] is not a [GeneralDateTimeInterface] or [DateTime].
  bool isAfter(dynamic other) {
    final DateTime selfDate = toDateTime();
    if (other is GeneralDateTimeInterface) {
      return selfDate.isAfter(other.toDateTime());
    }
    if (other is DateTime) return selfDate.isAfter(other);
    throw ArgumentError(
        'isAfter function expected GeneralDateTimeInterface or DateTime, but got ${other.runtimeType}');
  }

  /// Checks whether this dateTime represents the same moment as another.
  /// Compares this instance with [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// Returns `true` if both datetimes represent the same point in time.
  /// Example:
  /// ```dart
  /// final a = JalaliDateTime(1403, 4, 15, 12, 30);
  /// final b = JalaliDateTime(1403, 4, 15, 12, 30);
  ///
  /// a.isAtSameMomentAs(b); // true
  ///
  /// final native = DateTime(2025, 7, 6, 14, 0);
  /// a.isAtSameMomentAs(native); // true or false depending on internal conversion
  /// ```
  /// Throws an [ArgumentError] if [other] is not a [GeneralDateTimeInterface] or [DateTime].
  bool isAtSameMomentAs(dynamic other) {
    final DateTime selfDate = toDateTime();
    if (other is GeneralDateTimeInterface) {
      return selfDate.isAtSameMomentAs(other.toDateTime());
    }
    if (other is DateTime) return selfDate.isAtSameMomentAs(other);
    throw ArgumentError(
        'isAtSameMomentAs function expected GeneralDateTimeInterface or DateTime, but got ${other.runtimeType}');
  }

  /// Returns the difference between this dateTime and another.
  /// Computes the [Duration] between this instance and [other], which can be either:
  /// - An object implementing [GeneralDateTimeInterface], or
  /// - A native [DateTime] instance.
  /// The result is positive if this dateTime is after [other], and negative if before.
  /// Example:
  /// ```dart
  /// final a = JalaliDateTime(1403, 4, 15, 12, 30);
  /// final b = JalaliDateTime(1403, 4, 15, 11, 0);
  ///
  /// final duration = a.difference(b); // 1 hour 30 minutes
  /// duration.inMinutes; // 90
  /// ```
  /// Throws an [ArgumentError] if [other] is not a [GeneralDateTimeInterface] or [DateTime].
  Duration difference(dynamic other) {
    final DateTime selfDate = toDateTime();
    if (other is GeneralDateTimeInterface) {
      return selfDate.difference(other.toDateTime());
    }
    if (other is DateTime) return selfDate.difference(other);
    throw ArgumentError(
        'difference function expected GeneralDatetimeInterface or DateTime, but got ${other.runtimeType}');
  }

  Duration get time => Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        microseconds: microsecond,
        milliseconds: millisecond,
      );

  String toIso8601String() {
    String y =
        (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-${d}T$h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-${d}T$h:$min:$sec.$ms$us";
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneralDateTimeInterface &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          hour == other.hour &&
          minute == other.minute &&
          second == other.second &&
          millisecond == other.millisecond &&
          microsecond == other.microsecond &&
          isUtc == other.isUtc;

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      day.hashCode ^
      hour.hashCode ^
      minute.hashCode ^
      second.hashCode ^
      millisecond.hashCode ^
      microsecond.hashCode ^
      isUtc.hashCode;

  @override
  String toString() {
    String y = _fourDigits(year);
    String m = _twoDigits(month);
    String d = _twoDigits(day);
    String h = _twoDigits(hour);
    String min = _twoDigits(minute);
    String sec = _twoDigits(second);
    String ms = _threeDigits(millisecond);
    String us = microsecond == 0 ? "" : _threeDigits(microsecond);
    if (isUtc) {
      return "$y-$m-$d $h:$min:$sec.$ms${us}Z";
    } else {
      return "$y-$m-$d $h:$min:$sec.$ms$us";
    }
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String _threeDigits(int n) {
    if (n >= 100) return "$n";
    if (n >= 10) return "0$n";
    return "00$n";
  }

  String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    int absN = n.abs();
    String sign = n < 0 ? "-" : "+";
    if (absN >= 100000) return "$sign$absN";
    return "${sign}0$absN";
  }
}
