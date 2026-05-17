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

  // Hijri Example:
  HijriDateTime hDate = HijriDateTime.fromDateTime(DateTime(2025, 3, 1));
  print('Converted to Hijri: ${hDate.toString()}');

  runApp(AppStartup());
}

class AppStartup extends StatelessWidget {
  const AppStartup({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      localizationsDelegates: [
        DefaultPersianCalendarMaterialLocalizations.delegate,
        DefaultHijriCalendarMaterialLocalizations.delegate,
      ],
      locale: Locale('en'),
      supportedLocales: [Locale('en'), Locale('fa')],
      home: Scaffold(
        appBar: AppBar(
          title: Text("Calendar delegates"),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Text("Gregorian Calendar"),
              CalendarDatePicker(
                initialDate: DateTime.now(),
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2030, 12, 31),
                currentDate: DateTime.now(),
                calendarDelegate: GregorianCalendarDelegate(),
                onDateChanged: (value) {},
              ),
              Divider(),
              Text("Persian Calendar"),
              CalendarDatePicker(
                initialDate: PersianDateTime.now(),
                firstDate: PersianDateTime(1400, 1, 1),
                lastDate: PersianDateTime(1450, 12, 31),
                currentDate: PersianDateTime.now(),
                onDateChanged: (value) {
                  print('Persian selected: $value');
                },
                calendarDelegate: PersianCalendarDelegate(),
              ),
              Divider(),
              Text("Hijri Calendar"),
              CalendarDatePicker(
                initialDate: HijriDateTime.now(),
                firstDate: HijriDateTime(1440, 1, 1),
                lastDate: HijriDateTime(1460, 12, 31),
                currentDate: HijriDateTime.now(),
                onDateChanged: (value) {
                  print('Hijri selected: $value');
                },
                calendarDelegate: HijriCalendarDelegate(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
