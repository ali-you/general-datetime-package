abstract class GeneralDatetimeInterface<T>
    implements Comparable<GeneralDatetimeInterface> {
  GeneralDatetimeInterface(
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
  String get timeZoneName;

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
  Duration get timeZoneOffset;

  /// Calculate weekday according to the calendar type
  int get weekday;

  /// Get days in the current month according to the calendar
  int get monthLength;

  int get dayOfYear;

  /// Check if the year is a leap year according to the calendar
  bool get isLeapYear;

  /// Julian Day Number getter
  int get julianDay;

  int get secondsSinceEpoch;

  int get millisecondsSinceEpoch;

  int get microsecondsSinceEpoch;

  /// Convert T calendar type to DateTime
  DateTime toDatetime();

  @override
  int compareTo(GeneralDatetimeInterface other);

  bool isBefore(GeneralDatetimeInterface other);

  bool isAfter(GeneralDatetimeInterface other);

  bool isAtSameMomentAs(GeneralDatetimeInterface other);

  T add(Duration duration);

  T subtract(Duration duration);

  Duration difference(GeneralDatetimeInterface other);

  // DateTime toLocal() {
  //   if (isUtc) {
  //     return _withUtc(isUtc: false);
  //   }
  //   return this;
  // }
  //
  // DateTime toUtc() {
  //   if (isUtc) return this;
  //   return _withUtc(isUtc: true);
  // }

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
      other is GeneralDatetimeInterface &&
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
