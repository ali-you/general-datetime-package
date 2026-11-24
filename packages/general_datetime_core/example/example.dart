import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final saka = SakaDateTime.fromDateTime(DateTime.utc(2026, 3, 22));
  final nextMonth = CalendarDate.fromDateTime(saka).addMonths(1);
  print(nextMonth); // indian:1948-02-01
  print(nextMonth.gregorianDay); // 2026-04-21 00:00:00.000Z
}
