import 'package:flutter_test/flutter_test.dart';

import 'package:general_date/src/jalali_datetime.dart';

void main() {
  test('Convert Gregorian to Jalali - Normal Year', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 3, 1));
    expect(j.toString(), "JalaliDatetime: 1403-12-11 0:0:0");
  });

  test('Convert Gregorian to Jalali - Leap Year', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2024, 2, 29));
    expect(j.toString(), "JalaliDatetime: 1402-12-10 0:0:0");
  });

  test('Convert Jalali to Gregorian - Normal Year', () {
    JalaliDatetime j = JalaliDatetime(1403, 12, 11);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2025, 3, 1));
  });

  test('Convert Jalali to Gregorian - Leap Year', () {
    JalaliDatetime j = JalaliDatetime(1402, 12, 10);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2024, 2, 29));
  });

  test('Convert Gregorian to Jalali - Beginning of Year', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 1, 1));
    expect(j.toString(), "JalaliDatetime: 1403-10-12 0:0:0");
  });

  test('Convert Gregorian to Jalali - End of Year', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 12, 31));
    expect(j.toString(), "JalaliDatetime: 1404-10-10 0:0:0");
  });

  test('Convert Jalali to Gregorian - Beginning of Year', () {
    JalaliDatetime j = JalaliDatetime(1403, 10, 11);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2024, 12, 31));
  });

  test('Convert Jalali to Gregorian - End of Year', () {
    JalaliDatetime j = JalaliDatetime(1404, 10, 10);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2025, 12, 31));
  });

  test('Leap Year Check - Leap Year', () {
    expect(JalaliDatetime(1403).isLeapYear, true);
    expect(JalaliDatetime(1402).isLeapYear, false);
  });

  test('Time Component Preservation', () {
    DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45);
    JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
    expect(j.hour, 14);
    expect(j.minute, 30);
    expect(j.second, 45);
  });

  test('Handling of Invalid Jalali Date (e.g., Esfand 30 in a non-leap year)', () {
    JalaliDatetime j = JalaliDatetime(1403, 12, 30);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2025, 3, 20)); // Should correct to Farvardin 1
  });

  test('Handling of Invalid Gregorian Date (e.g., Feb 30)', () {
    JalaliDatetime j = JalaliDatetime(1403, 11, 30);
    DateTime g = j.toDatetime();
    expect(g, DateTime(2025, 2, 18));
  });


  test('Convert Historical Gregorian Date (1799-03-21)', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(1799, 3, 21));
    expect(j.toString(), "JalaliDatetime: 1178-1-1 0:0:0"); // Farvardin 1, 1177
  });

  test('Convert Future Gregorian Date (2100-12-31)', () {
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime.utc(2100, 12, 31));
    expect(j.toString(), "JalaliDatetime: 1479-10-10 0:0:0");
  });

  test('Convert Valid Jalali Leap Year Date (Esfand 30)', () {
    JalaliDatetime j = JalaliDatetime(1403, 12, 30); // Leap year
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2025, 3, 20));
  });

  test('Convert Invalid Jalali Date in Non-Leap Year (Esfand 30 → Farvardin 1)', () {
    JalaliDatetime j = JalaliDatetime(1402, 12, 30); // Non-leap year
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2024, 3, 20)); // Farvardin 1, 1403
  });

  test('Convert Farvardin 1 to Gregorian (Nowruz)', () {
    JalaliDatetime j = JalaliDatetime(1403, 1, 1);
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2024, 3, 20));
  });

  test('Convert Gregorian Dates Around Nowruz Transition', () {
    // Day before Nowruz
    JalaliDatetime j1 = JalaliDatetime.fromDatetime(DateTime.utc(2024, 3, 19));
    expect(j1.toString(), "JalaliDatetime: 1402-12-29 0:0:0");

    // Nowruz
    JalaliDatetime j2 = JalaliDatetime.fromDatetime(DateTime.utc(2024, 3, 20));
    expect(j2.toString(), "JalaliDatetime: 1403-1-1 0:0:0");
  });

  test('Adjust Invalid Jalali Month Day (Mehr 31 → Aban 1)', () {
    JalaliDatetime j = JalaliDatetime(1403, 7, 31); // Mehr has 30 days
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2024, 10, 22)); // Aban 1, 1403
  });

  test('Preserve Time Components with UTC DateTime', () {
    DateTime gDate = DateTime.utc(2025, 3, 1, 14, 30, 45);
    JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
    expect(j.hour, 14);
    expect(j.minute, 30);
    expect(j.second, 45);
  });

  test('Convert Oldest Jalali Date (Year 1)', () {
    JalaliDatetime j = JalaliDatetime(1, 1, 1); // Start of Jalali calendar
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(622, 3, 22)); // Gregorian equivalent
  });

  test('Convert Shahrivar 31 (Valid 31-Day Month)', () {
    JalaliDatetime j = JalaliDatetime(1403, 6, 31); // Shahrivar ends on 31
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2024, 9, 22));
  });

  test('Cross-Check Mid-Year Conversion (1403-04-15)', () {
    JalaliDatetime j = JalaliDatetime(1403, 4, 15); // Tir 15
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2024, 7, 6));
  });

  test('Convert Gregorian to Jalali in Different Seasons', () {
    // Summer solstice in Gregorian (June 21)
    JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime.utc(2024, 6, 21));
    expect(j.toString(), "JalaliDatetime: 1403-4-1 0:0:0"); // Tir 1
  });

  test('Handle Large Jalali Year (Year 2000)', () {
    JalaliDatetime j = JalaliDatetime(2000, 1, 1);
    DateTime g = j.toDatetime();
    expect(g, DateTime.utc(2621, 3, 21)); // Approximate conversion
  });

}
