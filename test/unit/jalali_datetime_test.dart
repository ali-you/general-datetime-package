import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {

  double toJulianDate(DateTime date) {
    final year = date.toUtc().year;
    final month = date.toUtc().month;
    final day = date.toUtc().day;
    final hour = date.toUtc().hour;
    final minute = date.toUtc().minute;
    final second = date.toUtc().second;

    int y = month <= 2 ? year - 1 : year;
    int m = month <= 2 ? month + 12 : month;

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    final jdDay = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day + b - 1524.5;

    final dayFraction = (hour + minute / 60 + second / 3600) / 24;

    return jdDay + dayFraction;
  }

  double jdn(DateTime date) {
    double res = (1461 * (date.year + 4800 + (date.month - 14)/12)) / 4 +
        (367 * (date.month - 2 - 12 * ((date.month - 14)/12))) / 12 -
        (3 * ((date.year + 4900 + (date.month - 14)/12) / 100)) / 4 +
        date.day - 32075;
    return res;
  }

  int getDaysInMonth(int year, int month) {
    DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);
    DateTime lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(Duration(days: 1));
    return lastDayOfCurrentMonth.day;
  }

  group('Gregorian to Jalali Conversion', () {
    test('Normal Year', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2025, 3, 1));
      expect(j.toString(), "1403-12-11 00:00:00.000");
    });

    test('Leap Year', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2024, 2, 29));
      expect(j.toString(), "1402-12-10 00:00:00.000");
    });

    test('Beginning of Year', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2025, 1, 1));
      expect(j.toString(), "1403-10-12 00:00:00.000");
    });

    test('End of Year', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2025, 12, 31));
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
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(1799, 3, 21));
      expect(j.toString(), "1178-01-01 00:00:00.000");
    });

    test('Future Date Conversion', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2100, 12, 31));
      expect(j.toString(), "1479-10-10 00:00:00.000");
    });
  });

  group('Time Handling', () {
    test('Time Component Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45);
      JalaliDatetime j = JalaliDatetime.fromDateTime(gDate);
      expect(j.hour, 14);
      expect(j.minute, 30);
      expect(j.second, 45);
    });

    test('Microsecond Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45, 123, 456);
      JalaliDatetime j = JalaliDatetime.fromDateTime(gDate);
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
      JalaliDatetime j = JalaliDatetime.fromDateTime(original);
      expect(j.toDatetime(), original);
    });

    test('Weekday Consistency', () {
      DateTime gDate = DateTime(2024, 3, 20);
      JalaliDatetime j = JalaliDatetime.fromDateTime(gDate);
      expect(j.weekday, gDate.weekday);
    });

    test('Large Year Conversion', () {
      JalaliDatetime j = JalaliDatetime(2000, 1, 1);
      expect(j.toDatetime(), DateTime(2621, 3, 21));
    });

    test('Seasonal Conversion Check', () {
      JalaliDatetime j = JalaliDatetime.fromDateTime(DateTime(2024, 6, 21));
      expect(j.toString(), "1403-04-01 00:00:00.000");
    });
  });

  group('Time Zone Handling', () {
    test('UTC Time Preservation', () {
      DateTime gDate = DateTime.utc(2025, 3, 1, 14, 30);
      JalaliDatetime j = JalaliDatetime.fromDateTime(gDate);
      expect(j.toString(), "1403-12-11 14:30:00.000Z");
    });

    test('DST Transition Handling', () {
      DateTime gDate = DateTime(2024, 3, 31, 2, 30);
      JalaliDatetime j = JalaliDatetime.fromDateTime(gDate);
      expect(j.hour, 2);
    });
  });

  test('Convert Oldest Jalali Date (Year 1)', () {
    JalaliDatetime j = JalaliDatetime(1, 1, 1); // Start of Jalali calendar
    DateTime g = j.toDatetime();
    expect(g, DateTime(622, 3, 22)); // Gregorian equivalent
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
      expect(dt.year, equals(1402));
      expect(dt.month, equals(9));
      expect(dt.day, equals(1));
      expect(dt.hour, equals(22));
      expect(dt.minute, equals(30));
    });

    test('test normal', () {
      final dt = JalaliDatetime(1402, 9, 1, 0, -90);
      final gt = DateTime(2025, 9, 1, 0, -90);
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
      expect(dt.second, gt.second);
      expect(dt.millisecond, gt.millisecond);
    });
  });
  group('Factory Constructors', () {
    test('fromDateTime conversion', () {
      final DateTime dt = DateTime(2025, 3, 1, 14, 30, 45, 123, 456);
      final JalaliDatetime j = JalaliDatetime.fromDateTime(dt);
      // Expected output from your conversion logic.
      expect(j.toString(), equals("1403-12-11 14:30:45.123456"));
    });

    test('now returns valid JalaliDatetime', () {
      final JalaliDatetime jNow = JalaliDatetime.now();
      expect(jNow.year, isNotNull);
      expect(jNow.month, inInclusiveRange(1, 12));
      expect(jNow.day, inInclusiveRange(1, 31));
    });

    test('utc factory preserves UTC flag', () {
      final JalaliDatetime jUtc = JalaliDatetime.utc(1403, 12, 11, 14, 30);
      expect(jUtc.toDatetime().isUtc, isTrue);
    });

    test('fromSecondsSinceEpoch', () {
      final JalaliDatetime j =
          JalaliDatetime.fromSecondsSinceEpoch(1722782031, isUtc: true);
      expect(j.toString().endsWith("Z"), isTrue,
          reason: 'UTC marker expected in string');
    });

    test('fromMillisecondsSinceEpoch', () {
      final JalaliDatetime j =
          JalaliDatetime.fromMillisecondsSinceEpoch(1722782031520);
      expect(j.year, isNotNull);
    });

    test('Unix Epoch Conversion', () {
      final j = JalaliDatetime.fromMillisecondsSinceEpoch(0, isUtc: true);
      print(Jalali.fromMillisecondsSinceEpoch(0, isUtc: true));
      print(j);
      expect(j.year, 1348);
      expect(j.month, 10);
      expect(j.day, 11);
      expect(j.toString(), "1348-10-11 00:00:00.000Z");
    });

    test('fromMicrosecondsSinceEpoch', () {
      final JalaliDatetime j =
          JalaliDatetime.fromMicrosecondsSinceEpoch(1722782031520000);
      expect(j.day, inInclusiveRange(1, 31));
    });

    test('parse and tryParse', () {
      final String isoStr = "1403-12-11 14:30:45.123456Z";
      final JalaliDatetime parsed = JalaliDatetime.parse(isoStr);
      final JalaliDatetime? tryParsed = JalaliDatetime.tryParse(isoStr);
      expect(parsed.toString(), equals(tryParsed?.toString()));
      expect(() => JalaliDatetime.parse("invalid"), throwsFormatException);
    });

    test('Parse Jalali Date String', () {
      final j = JalaliDatetime.parse("1403-04-15 14:30:45");
      final j2 = JalaliDatetime(1403, 4, 15, 14, 30, 45);
      expect(j, j2);
    });
  });

  group('Gregorian to Jalali Conversion', () {
    test('Normal Year Conversion', () {
      final JalaliDatetime j =
          JalaliDatetime.fromDateTime(DateTime(2025, 3, 1));
      expect(j.toString(), equals("1403-12-11 00:00:00.000"));
    });

    test('Leap Year Conversion', () {
      final JalaliDatetime j =
          JalaliDatetime.fromDateTime(DateTime(2024, 2, 29));
      expect(j.toString(), equals("1402-12-10 00:00:00.000"));
    });

    test('Beginning of Year Conversion', () {
      final JalaliDatetime j =
          JalaliDatetime.fromDateTime(DateTime(2025, 1, 1));
      expect(j.toString(), equals("1403-10-12 00:00:00.000"));
    });

    test('End of Year Conversion', () {
      final JalaliDatetime j =
          JalaliDatetime.fromDateTime(DateTime(2025, 12, 31));
      expect(j.toString(), equals("1404-10-10 00:00:00.000"));
    });

    test('Gregorian/Jalali New Year Alignment', () {
      // March 20/21 is Farvardin 1
      final j1 = JalaliDatetime.fromDateTime(DateTime(2024, 3, 20));
      expect(j1.toString(), startsWith("1403-01-01"));

      final j2 = JalaliDatetime.fromDateTime(DateTime(2025, 3, 21));
      expect(j2.toString(), startsWith("1404-01-01"));
    });
  });

  group('Jalali to Gregorian Conversion', () {
    test('Normal Year', () {
      final JalaliDatetime j = JalaliDatetime(1403, 12, 11);
      expect(j.toDatetime(), equals(DateTime(2025, 3, 1)));
    });

    test('Leap Year', () {
      final JalaliDatetime j = JalaliDatetime(1402, 12, 10);
      expect(j.toDatetime(), equals(DateTime(2024, 2, 29)));
    });

    test('Beginning of Year', () {
      final JalaliDatetime j = JalaliDatetime(1403, 10, 11);
      expect(j.toDatetime(), equals(DateTime(2024, 12, 31)));
    });

    test('End of Year', () {
      final JalaliDatetime j = JalaliDatetime(1404, 10, 10);
      expect(j.toDatetime(), equals(DateTime(2025, 12, 31)));
    });
  });

  group('Time Handling', () {
    test('Time Component Preservation', () {
      final DateTime g = DateTime(2025, 3, 1, 14, 30, 45, 123, 456);
      final JalaliDatetime j = JalaliDatetime.fromDateTime(g);
      expect(j.hour, equals(14));
      expect(j.minute, equals(30));
      expect(j.second, equals(45));
      expect(j.millisecond, equals(123));
      expect(j.microsecond, equals(456));
    });
  });

  group('Date Arithmetic', () {
    test('Add Duration Across Months', () {
      final j = JalaliDatetime(1403, 6, 31).add(const Duration(days: 2));
      expect(j.toString(), "1403-07-02 00:00:00.000");
    });

    test('Subtract Months with Year Rollover', () {
      final j = JalaliDatetime(1403, 1, 1).subtract(Duration(days: 89));
      expect(j.toString(), "1402-10-01 00:00:00.000");
    });
  });

  group('Negative Normalization', () {
    test('Negative Day', () {
      final JalaliDatetime j = JalaliDatetime(1400, 1, 0);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
    });
    test('Negative Month', () {
      final JalaliDatetime j = JalaliDatetime(1400, -1, 15);
      expect(j.year, equals(1399));
      expect(j.month, equals(11));
      expect(j.day, equals(15));
    });
    test('Negative Hour', () {
      final JalaliDatetime j = JalaliDatetime(1400, 1, 1, -3);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(21));
    });
    test('Negative Minute', () {
      final JalaliDatetime j = JalaliDatetime(1400, 1, 1, 0, -90);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(22));
      expect(j.minute, equals(30));
    });
    test('Negative Second', () {
      final JalaliDatetime j = JalaliDatetime(1400, 1, 1, 0, 0, -75);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(23));
      expect(j.minute, equals(58));
      expect(j.second, equals(45));
    });
  });

  group('Julian day comparison', () {
    test('Compare with gregorian', () {
        for (int year = 0; year <= 3176; year++) {
          final JalaliDatetime jalaliDatetime = JalaliDatetime(year);
          expect(jalaliDatetime.julianDay, toJulianDate(jalaliDatetime.toDatetime()).floor());
        }
    });
  });


  group('Compare with another package', () {

    test('compare leap year', () {
      final Jalali another = Jalali(1635);
      final JalaliDatetime own = JalaliDatetime(1635);
      expect(own.isLeapYear, another.isLeapYear());
    });
    
    test('compare leap year with conversion', () {
      final Jalali another = Jalali.fromDateTime(DateTime(2256));
      final JalaliDatetime own = JalaliDatetime.fromDateTime(DateTime(2256));
      print(own);
      print(another);
      expect(own.isLeapYear, another.isLeapYear());
      // Expected: <1635>
      // Actual: <1634>
      // Year mismatch on 2256,3,20 => own:1634-12-30 00:00:00.000, another:Jalali(1635, 1, 1, 0, 0, 0, 0)
    });

    test('compare leap year in list', () {
      for (int year = -60; year <= 3176; year++) {
        final Jalali another = Jalali(year);
        final JalaliDatetime own = JalaliDatetime(year);
        expect(own.isLeapYear, another.isLeapYear());
        }
    });

    test('compare months', () {
      for (int year = 0; year <= 3000; year++) {
        for (int month = 1; month <= 12; month++) {
          final int another = Jalali(year, month).monthLength;
          final int own = JalaliDatetime(year, month).monthLength;
          expect(own, another, reason: 'Year mismatch on $year,$month => ');
        }
      }
    });

    test('convert jalali to gregorian', () {
      for (int year = 1; year <= 3176; year++) {
        for (int month = 1; month <= 12; month++) {
          for (int day = 1; day <= Jalali(year, month).monthLength; day++){
            final Jalali another = Jalali(year, month, day);
            final JalaliDatetime own = JalaliDatetime(year, month, day);
            expect(own.toDatetime(), another.toDateTime(), reason: 'Year mismatch on $year,$month => ');
          }
        }
      }
    });

      test('convert gregorian to jalali list', () {
        for (int year = 1000; year <= 3000; year++) {
          for (int month = 1; month <= 12; month++) {
            for (int day = 1; day <= getDaysInMonth(year, month); day++) {
              final Jalali another = Jalali.fromDateTime(DateTime(year, month, day));
              final JalaliDatetime own = JalaliDatetime.fromDateTime(DateTime(year, month, day));
                expect(own.year, another.year, reason: 'Year mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
                expect(own.month, another.month, reason: 'Month mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
                expect(own.day, another.day, reason: 'Day mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
            }
          }
        }
      });

      test('single convert gregorian to jalali', () {
        DateTime dateTime = DateTime(2256, 3, 30);
        final Jalali another = Jalali.fromDateTime(dateTime);
        final JalaliDatetime own = JalaliDatetime.fromDateTime(dateTime);
        print(own);
        print(another);
        print(own.isLeapYear);
        print(another.isLeapYear());
        expect(own.year, another.year);
        expect(own.month, another.month);
        expect(own.day, another.day);
      });
  });

  // group("julian date tests", () {
  //   test("check julian date with gregorian", () {
  //     double gregorian = toJulianDate(DateTime(2025).toUtc());
  //     int jalali = JalaliDatetime.fromDateTime(DateTime(2025).toUtc()).julianDay;
  //     expect(jalali, gregorian);
  //   });
  // });



}
