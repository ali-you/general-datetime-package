import 'package:general_datetime_core/general_datetime_core.dart';

// Set AMANTA_TEST_TZ at compilation and TZ at execution to the same zone.
void main() {
  const zone = String.fromEnvironment('AMANTA_TEST_TZ');
  final (year, month, day, expectedHour, expectedUtc) = switch (zone) {
    'America/Sao_Paulo' => (2018, 11, 4, 1, false),
    'Pacific/Apia' => (2011, 12, 30, 0, true),
    'UTC' => (2011, 12, 30, 0, false),
    _ => throw ArgumentError('Unsupported test zone'),
  };
  final date = AmantaDate.fromGregorian(year, month, day);
  final result = AmantaDateTime.atStartOfDay(date);
  final previous = AmantaDateTime.atStartOfDay(date.addDays(-1));
  final next = AmantaDateTime.atStartOfDay(date.addDays(1));
  final input = AmantaDateTime.fromCivilDate(
    date,
    isUtc: expectedUtc,
    hour: 14,
  );
  final dateOnly = CalendarDateUtils.dateOnly(input) as AmantaDateTime;
  if (result.civilDate != date ||
      result.hour != expectedHour ||
      result.isUtc != expectedUtc ||
      !previous.isBefore(result) ||
      !result.isBefore(next) ||
      dateOnly != result ||
      dateOnly.civilDate != date ||
      CalendarDateUtils.dateOnly(result) != result) {
    throw StateError('Incorrect picker representation in $zone: '
        '$previous < $result < $next, UTC=${result.isUtc}');
  }
  if (expectedHour != 0 || expectedUtc) {
    try {
      AmantaDateTime.fromCivilDate(date);
      throw StateError('Strict local construction accepted a nonexistent time');
    } on ArgumentError {
      // The picker fallback must not weaken explicit date-time construction.
    }
  }
  // ignore: avoid_print
  print('$zone: $date retained as $result');
}
