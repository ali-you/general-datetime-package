import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';

void main() {
  // Create a Gregorian date and convert it to Persian dates:
  PersianDateTime jDate = PersianDateTime.fromDateTime(DateTime(2025, 3, 1));
  print(
      'Converted to Jalali: ${jDate.toString()}'); // e.g. "1403-12-11 00:00:00.000"

  // Create a Jalali date directly (auto-normalization applies):
  PersianDateTime directDate = PersianDateTime(1403, 12, 11, 14, 30);
  print('Direct Jalali: ${directDate.toString()}');

  // Perform arithmetic:
  PersianDateTime futureDate = jDate.add(Duration(days: 5, hours: 3));
  print('Future Date: ${futureDate.toString()}');

  // Compare dates:
  bool isBefore = jDate.isBefore(PersianDateTime(1403, 12, 12));
  print('Is jDate before 1403-12-12? $isBefore');

  // Parse a date string:
  PersianDateTime parsed = PersianDateTime.parse("1403-12-11 14:30:45.123456Z");
  print('Parsed Date: ${parsed.toString()}');

  // Time zone information:
  print('Time Zone Name: ${jDate.timeZoneName}');
  print('Time Zone Offset: ${jDate.timeZoneOffset}');

  runApp(AppStartup());
}

class AppStartup extends StatelessWidget {
  const AppStartup({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      localizationsDelegates: [
        DefaultPersianCalendarMaterialLocalizations.delegate

        // GlobalMaterialLocalizations.delegate,
        // GlobalWidgetsLocalizations.delegate,
        // GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('en'),
      supportedLocales: [Locale('en'), Locale('fa')],
      home: Scaffold(
        appBar: AppBar(
          title: Text("Calendar delegate"),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime(1400, 1, 1),
                lastDate: DateTime(2500, 12, 31),
                currentDate: DateTime.now(),
                calendarDelegate: GregorianCalendarDelegate(),
                onDateChanged: (value) {},
              ),
              CalendarDatePicker(
                initialDate: PersianDateTime.now(),
                firstDate: PersianDateTime(1400, 1, 1),
                lastDate: PersianDateTime(1450, 12, 31),
                currentDate: PersianDateTime.now(),
                onDateChanged: (value) {
                  print(value.toString());
                  PersianDateTime jDate = value as PersianDateTime;
                  print(jDate);
                  print(jDate.toDateTime());
                },
                calendarDelegate: PersianCalendarDelegate(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
