import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';

import 'package:shamsi_date/shamsi_date.dart';

void main() {
  group('Gregorian to Jalali Conversion', () {
    test('Normal Year', () {
      DateTime now = DateTime.now();
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 3, 1));
      expect(j.toString(), "1403-12-11 00:00:00.000");
    });

    test('Leap Year', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2024, 2, 29));
      expect(j.toString(), "1402-12-10 00:00:00.000");
    });

    test('Beginning of Year', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 1, 1));
      expect(j.toString(), "1403-10-12 00:00:00.000");
    });

    test('End of Year', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2025, 12, 31));
      expect(j.toString(), "1404-10-10 00:00:00.000");
    });
  });

  group('Jalali to Gregorian Conversion', () {
    test('Normal Year', () {
      JalaliDatetime j = JalaliDatetime(1403, 12, 11);
      expect(j.toDatetime(), DateTime(2025, 3, 1));
    });

    test('Leap Year', () {
      JalaliDatetime j = JalaliDatetime(1402, 12, 10);
      expect(j.toDatetime(), DateTime(2024, 2, 29));
    });

    test('Beginning of Year', () {
      JalaliDatetime j = JalaliDatetime(1403, 10, 11);
      expect(j.toDatetime(), DateTime(2024, 12, 31));
    });

    test('End of Year', () {
      JalaliDatetime j = JalaliDatetime(1404, 10, 10);
      expect(j.toDatetime(), DateTime(2025, 12, 31));
    });
  });

  group('Leap Year Handling', () {
    test('Leap Year Detection', () {
      expect(JalaliDatetime(1403).isLeapYear, true);
      expect(JalaliDatetime(1402).isLeapYear, false);
    });

    test('Valid Leap Day Conversion', () {
      JalaliDatetime j = JalaliDatetime(1403, 12, 30);
      expect(j.toDatetime(), DateTime(2025, 3, 20));
    });

    test('Invalid Leap Day Auto-Correction', () {
      JalaliDatetime j = JalaliDatetime(1402, 12, 30);
      expect(j.toDatetime(), DateTime(2024, 3, 20));
    });
  });

  group('Edge Cases and Special Dates', () {
    test('Nowruz (Farvardin 1)', () {
      JalaliDatetime j = JalaliDatetime(1403, 1, 1);
      expect(j.toDatetime(), DateTime(2024, 3, 20));
    });

    test('Shahrivar 30 Conversion', () {
      JalaliDatetime j = JalaliDatetime(1402, 6, 30);
      expect(j.toDatetime(), DateTime(2023, 9, 21));
    });

    test('Historical Date Conversion', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(1799, 3, 21));
      expect(j.toString(), "1178-01-01 00:00:00.000");
    });

    test('Future Date Conversion', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2100, 12, 31));
      expect(j.toString(), "1479-10-10 00:00:00.000");
    });
  });

  group('Time Handling', () {
    test('Time Component Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45);
      JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
      expect(j.hour, 14);
      expect(j.minute, 30);
      expect(j.second, 45);
    });

    test('Microsecond Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45, 123, 456);
      JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
      expect(j.millisecond, 123);
      expect(j.microsecond, 456);
    });
  });

  group('Invalid Date Handling', () {
    test('Invalid Jalali Date Auto-Correction', () {
      JalaliDatetime j = JalaliDatetime(1403, 7, 31);
      expect(j.toDatetime(), DateTime(2024, 10, 22));
    });

    test('Invalid Gregorian Date Handling', () {
      JalaliDatetime j = JalaliDatetime(1403, 11, 30);
      expect(j.toDatetime(), DateTime(2025, 2, 18));
    });
  });

  group('Advanced Scenarios', () {
    test('Round-Trip Conversion', () {
      DateTime original = DateTime(2024, 3, 20);
      JalaliDatetime j = JalaliDatetime.fromDatetime(original);
      expect(j.toDatetime(), original);
    });

    test('Weekday Consistency', () {
      DateTime gDate = DateTime(2024, 3, 20);
      JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
      expect(j.weekday, gDate.weekday);
    });

    test('Large Year Conversion', () {
      JalaliDatetime j = JalaliDatetime(2000, 1, 1);
      expect(j.toDatetime(), DateTime(2621, 3, 21));
    });

    test('Seasonal Conversion Check', () {
      JalaliDatetime j = JalaliDatetime.fromDatetime(DateTime(2024, 6, 21));
      expect(j.toString(), "1403-04-01 00:00:00.000");
    });
  });

  group('Time Zone Handling', () {
    test('UTC Time Preservation', () {
      DateTime gDate = DateTime.utc(2025, 3, 1, 14, 30);
      print(gDate.toString());
      JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
      print(j.isUtc);
      print(j.toString());
      // expect(j.isUtc, true);
      expect(j.toString(), "1403-12-11 14:30:00.000Z");
    });

    test('DST Transition Handling', () {
      DateTime gDate = DateTime(2024, 3, 31, 2, 30);
      JalaliDatetime j = JalaliDatetime.fromDatetime(gDate);
      expect(j.hour, 2);
    });
  });

  test('Convert Oldest Jalali Date (Year 1)', () {
    Jalali jalali = Jalali(1, 12, 1);
    JalaliDatetime j = JalaliDatetime(1, 12, 1); // Start of Jalali calendar
    DateTime g = j.toDatetime();
    print(j.julianDay);
    print(j.monthLength);
    print(jalali.julianDayNumber);
    print(jalali.monthLength);
    expect(j.julianDay, jalali.julianDayNumber);
    expect(g, jalali.toDateTime());
    // expect(g, DateTime(622, 3, 22)); // Gregorian equivalent
  });

  test('Convert Shahrivar 31 (Valid 31-Day Month)', () {
    JalaliDatetime j = JalaliDatetime(1403, 6, 31); // Shahrivar ends on 31
    DateTime g = j.toDatetime();
    expect(g, DateTime(2024, 9, 21));
  });

  test('Cross-Check Mid-Year Conversion (1403-04-15)', () {
    JalaliDatetime j = JalaliDatetime(1403, 4, 15); // Tir 15
    DateTime g = j.toDatetime();
    expect(g, DateTime(2024, 7, 5));
  });

  group('Negative Date Normalization', () {
    test('Negative day normalization', () {
      // Starting at Jalali 1400/1/0 should roll back to the last day of the previous month.
      // Since 1400/1/0 → becomes 1399/12/day, and for 1399 the 12th month is 30 days (1399 % 33 == 13, a leap year)
      final dt = JalaliDatetime(1400, 1, 0);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
    });

    test('Negative month normalization', () {
      // A negative month should be normalized by adding 12 and decrementing the year.
      // For example, JalaliDatetime(1400, -1, 15) should become 1399/11/15.
      final dt = JalaliDatetime(1400, -1, 15);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(11));
      expect(dt.day, equals(15));
    });

    test('Negative hour normalization', () {
      // An hour underflow: JalaliDatetime(1400, 1, 1, -3)
      // Negative hours are added to 24 and one day is subtracted.
      // Expected: date becomes previous day; for 1400/1/1, it rolls back to 1399/12 with last day 30.
      final dt = JalaliDatetime(1400, 1, 1, -3);
      print(dt.monthLength);
      print(Jalali(1399, 12, 29).monthLength);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, equals(21));
    });

    test('Negative minute normalization', () {
      // For negative minutes: JalaliDatetime(1400, 1, 1, 0, -90)
      // -90 minutes gives a -1 hour offset and remainder minutes.
      // Expected: hour decreases by 1 (from 0 to -1, then normalized to 23 of previous day) and minute becomes 30.
      final dt = JalaliDatetime(1400, 1, 1, 0, -90);
      final gt = DateTime(2025, 1, 1, 0, -90);
      expect(dt.year,
          equals(1399)); // Day normalization occurs only in the time component.
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
    });

    test('Negative second normalization', () {
      // For negative seconds: JalaliDatetime(1400, 1, 1, 0, 0, -75)
      // -75 seconds result in borrowing from minutes.
      // Expected: minute decreases by 1 and second becomes 45.
      final dt = JalaliDatetime(1400, 1, 1, 0, 0, -75);
      final gt = DateTime(1400, 1, 1, 0, 0, -75);
      print(dt.toString());
      print(gt.toString());
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, equals(23));
      expect(dt.minute, equals(58));
      expect(dt.second, equals(45));
    });

    test('Negative microsecond normalization', () {
      // For negative microseconds: JalaliDatetime(1400, 1, 1, 0, 0, 0, 0, -1500)
      // -1500 microseconds should reduce the millisecond count.
      // Expected: microseconds become 500 and one millisecond is subtracted.
      final dt = JalaliDatetime(1400, 1, 1, 0, 0, 0, 0, -1500);
      final gt = DateTime(1400, 1, 1, 0, 0, 0, 0, -1500);
      print(dt.toString());
      print(gt.toString());
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      // Since time is midnight and we borrow from the same unit, the date remains unchanged.
      // The hour, minute, and second remain zero.
      expect(dt.hour, equals(23));
      expect(dt.minute, equals(59));
      expect(dt.second, equals(59));
      // Check that the normalization yields 999 microseconds (after subtracting one millisecond)
      // if your normalization rolls the negative microsecond into the millisecond unit.
      // (Adjust this expected value according to your intended behavior.)
      expect(
          dt.millisecond, equals(998)); // This is an example; modify as needed.
      expect(
          dt.microsecond, equals(500)); // This is an example; modify as needed.
    });

    test('Negative day with hour zero', () {
      final dt = JalaliDatetime(1402, 9, 2, 0, -90);
      print(DateTime(2025, 8, -1, 0));
      print(dt.toString());
      expect(dt.year, equals(1402));
      expect(dt.month, equals(9));
      expect(dt.day, equals(1));
      expect(dt.hour, equals(22));
      expect(dt.minute, equals(30));
    });

    test('test normal', () {
      final dt = JalaliDatetime(1402, 9, 1, 0, -90);
      final gt = DateTime(2025, 9, 1, 0, -90);
      final test = DateTime(2025, 10, 10, 10, -70);

      print("test$test");
      print(gt.toString());
      print(dt.toString());
      // expect(dt.month, gt.month);
      // expect(dt.day, gt.day);
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
      expect(dt.second, gt.second);
      expect(dt.millisecond, gt.millisecond);
    });
  });
}
