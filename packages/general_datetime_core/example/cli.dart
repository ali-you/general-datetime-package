import 'dart:convert';

import 'package:general_datetime_core/general_datetime_core.dart';

void main() {
  final instant = DateTime.utc(2024, 3, 20, 13, 5, 6, 123, 456);
  final persian = PersianDateTime.fromDateTime(instant);
  final hijri = HijriDateTime.fromDateTime(instant);
  print('${persian.year}/${persian.month}/${persian.day}');
  print('${hijri.year}/${hijri.month}/${hijri.day}');
  print(jsonEncode(CalendarInstant.fromDateTime(persian)));
}
