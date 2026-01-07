import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:general_datetime/src/temp/ja_date_time.dart';
import 'package:general_datetime/src/temp/jalali_delegate.dart';
import 'package:general_datetime/src/localizations/default_jalali_material_localizations.dart';

void main() {
  // Create a Gregorian date and convert it to Jalali:
  JalaliDateTime jDate = JalaliDateTime.fromDateTime(DateTime(2025, 3, 1));
  print('Converted to Jalali: ${jDate.toString()}'); // e.g. "1403-12-11 00:00:00.000"

  // Create a Jalali date directly (auto-normalization applies):
  JalaliDateTime directDate = JalaliDateTime(1403, 12, 11, 14, 30);
  print('Direct Jalali: ${directDate.toString()}');

  // Perform arithmetic:
  JalaliDateTime futureDate = jDate.add(Duration(days: 5, hours: 3));
  print('Future Date: ${futureDate.toString()}');

  // Compare dates:
  bool isBefore = jDate.isBefore(JalaliDateTime(1403, 12, 12));
  print('Is jDate before 1403-12-12? $isBefore');

  // Parse a date string:
  JalaliDateTime parsed = JalaliDateTime.parse("1403-12-11 14:30:45.123456Z");
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

        DefaultJalaliMaterialLocalizations.delegate

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
                onDateChanged: (value) {
          
                },
              ),
          
              CalendarDatePicker(
                initialDate: JaDateTime.now(),
                firstDate: JaDateTime(1400, 1, 1),
                lastDate: JaDateTime(1450, 12, 31),
                currentDate: JaDateTime.now(),
                onDateChanged: (value) {
                  print(value.toString());
                  JaDateTime jDate = value as JaDateTime;
                  print(jDate);
                  print(jDate.toDateTime());
                },
                calendarDelegate: JalaliDelegate(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
