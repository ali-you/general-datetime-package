import 'package:general_datetime/general_datetime.dart';

void main() {
  // Create a Gregorian date and convert it to Jalali:
  JalaliDatetime jDate = JalaliDatetime.fromDatetime(DateTime(2025, 3, 1));
  print(
      'Converted to Jalali: ${jDate.toString()}'); // e.g. "1403-12-11 00:00:00.000"

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
