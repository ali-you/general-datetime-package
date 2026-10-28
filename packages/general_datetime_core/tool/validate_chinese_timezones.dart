import 'package:general_datetime_core/general_datetime_core.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  const zone = String.fromEnvironment('CALENDAR_TEST_TZ');
  final january = DateTime(2021, 1, 1, 12).timeZoneOffset.inMinutes;
  final july = DateTime(2021, 7, 1, 12).timeZoneOffset.inMinutes;
  final offsets = switch (zone) {
    'UTC' => (0, 0),
    'America/New_York' => (-300, -240),
    'Asia/Tehran' => (210, 270),
    'Asia/Shanghai' => (480, 480),
    'Pacific/Apia' => (840, 780),
    _ => throw ArgumentError('Unknown test timezone: $zone'),
  };
  require((january, july) == offsets, '$zone process timezone was not applied');

  for (final native in [
    DateTime(2025, 7, 25, 23, 59, 59, 999, 123),
    DateTime(1969, 12, 31, 23, 59, 59, 999, 999)
  ]) {
    final date = ChineseDateTime.fromDateTime(native);
    require(
        date.toDateTime() == native, '$zone local conversion lost precision');
    require(date.toUtc().toLocal() == date,
        '$zone UTC/local round trip changed instant');
    require(date.timeZoneOffset == native.timeZoneOffset, '$zone wrong offset');
    require(
        date.toUtc().microsecond == native.microsecond, '$zone lost fraction');
    final midnight = CalendarDateUtils.dateOnly(date);
    require(!midnight.isUtc && midnight.hour == 0,
        '$zone dateOnly changed local mode');
    final reinterpreted = CalendarDateUtils.copyWith(date, isUtc: true);
    require(reinterpreted.isUtc && reinterpreted.hour == date.hour,
        '$zone copyWith did not reinterpret wall fields');
  }

  if (zone == 'America/New_York') {
    checkGap(2021, 3, 14, 2, 30);
    checkCivilDay(2021, 3, 13, 23);
    checkCivilDay(2021, 11, 6, 25);
    for (final instant in [
      DateTime.utc(2021, 11, 7, 5, 30),
      DateTime.utc(2021, 11, 7, 6, 30)
    ]) {
      final date = ChineseDateTime.fromDateTime(instant.toLocal());
      require(date.hour == 1 && date.minute == 30, 'Fold wall time is wrong');
      require(date.toUtc().toDateTime() == instant, 'Fold instant collapsed');
    }
  } else if (zone == 'Asia/Tehran') {
    checkGap(2019, 3, 22, 0, 30);
    checkCivilDay(2019, 3, 21, 23);
    checkCivilDay(2019, 9, 21, 25);
  } else if (zone == 'Pacific/Apia') {
    checkGap(2011, 12, 30, 12, 0);
  }

  // Conversion is range-checked in the resulting wall calendar, including
  // positive/negative historical offsets at the finite table endpoints.
  for (final native in [
    DateTime(1901, 2, 19),
    DateTime(2100, 2, 8, 23, 59, 59, 999, 999)
  ]) {
    final date = ChineseDateTime.fromDateTime(native);
    final target = native.toUtc();
    if (ChineseDateTime.isSupportedDateTime(target)) {
      require(date.toUtc().toDateTime() == target, 'Endpoint instant changed');
    } else {
      var rejected = false;
      try {
        date.toUtc();
      } on RangeError {
        rejected = true;
      }
      require(rejected, 'Unsupported endpoint UTC wall day was accepted');
    }
  }
  print(
      'PASS $zone: verified offsets, precision, local/UTC modes, DST and bounds');
}

void checkGap(int year, int month, int day, int hour, int minute) {
  final civil = ChineseDateTime.fromDateTime(DateTime.utc(year, month, day));
  final normalized = DateTime(year, month, day, hour, minute);
  require(
      (
            normalized.year,
            normalized.month,
            normalized.day,
            normalized.hour,
            normalized.minute
          ) !=
          (year, month, day, hour, minute),
      'The expected DST gap was not observed');
  final permissive =
      ChineseDateTime(civil.year, civil.month, civil.day, hour, minute);
  require(permissive.toDateTime() == normalized,
      'Constructor lost native gap policy');
  var rejected = false;
  try {
    CalendarSystems.chinese.construct(civil.year, civil.month, civil.day,
        hour: hour, minute: minute, isUtc: false);
  } on ArgumentError {
    rejected = true;
  }
  require(rejected, 'Strict construction accepted a normalized DST gap');
}

void checkCivilDay(int year, int month, int day, int expectedHours) {
  final start = DateTime(year, month, day, 12);
  final next = DateTime(year, month, day + 1, 12);
  require(
      next.difference(start).inHours == expectedHours, 'DST duration mismatch');
  final date = ChineseDateTime.fromDateTime(start);
  final civilNext = CalendarDate.fromDateTime(date).addDays(1);
  final end = CalendarSystems.chinese.construct(
      civilNext.year, civilNext.month, civilNext.day,
      hour: 12, isUtc: false);
  require(end == next, 'Civil day arithmetic moved away from local noon');
  require(
      date.add(const Duration(hours: 24)).toDateTime() ==
          start.add(const Duration(hours: 24)),
      'Duration arithmetic changed instant');
}
