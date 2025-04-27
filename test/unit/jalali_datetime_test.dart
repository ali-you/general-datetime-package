import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_date_time.dart';
import 'package:general_datetime/src/gregorian_helper.dart';

void main() {
  group('Gregorian to Jalali Conversion Single Date', () {
    test('Normal Year', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2025, 3, 1));
      expect(j.toString(), "1403-12-11 00:00:00.000");
    });

    test('Leap Year', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2024, 2, 29));
      expect(j.toString(), "1402-12-10 00:00:00.000");
    });

    test('Beginning of Year', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2025, 1, 1));
      expect(j.toString(), "1403-10-12 00:00:00.000");
    });

    test('End of Year', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2025, 12, 31));
      expect(j.toString(), "1404-10-10 00:00:00.000");
    });

    test('Normal Year Conversion', () {
      final JalaliDateTime j =
          JalaliDateTime.fromDateTime(DateTime(2025, 3, 1));
      expect(j.toString(), equals("1403-12-11 00:00:00.000"));
    });

    test('Leap Year Conversion', () {
      final JalaliDateTime j =
          JalaliDateTime.fromDateTime(DateTime(2024, 2, 29));
      expect(j.toString(), equals("1402-12-10 00:00:00.000"));
    });

    test('Beginning of Year Conversion', () {
      final JalaliDateTime j =
          JalaliDateTime.fromDateTime(DateTime(2025, 1, 1));
      expect(j.toString(), equals("1403-10-12 00:00:00.000"));
    });

    test('End of Year Conversion', () {
      final JalaliDateTime j =
          JalaliDateTime.fromDateTime(DateTime(2025, 12, 31));
      expect(j.toString(), equals("1404-10-10 00:00:00.000"));
    });

    test('Gregorian/Jalali New Year Alignment', () {
      // March 20/21 is Farvardin 1
      final j1 = JalaliDateTime.fromDateTime(DateTime(2024, 3, 20));
      expect(j1.toString(), startsWith("1403-01-01"));

      final j2 = JalaliDateTime.fromDateTime(DateTime(2025, 3, 21));
      expect(j2.toString(), startsWith("1404-01-01"));
    });
  });

  group('Jalali to Gregorian Conversion Single Date', () {
    test('Normal Year', () {
      JalaliDateTime j = JalaliDateTime(1403, 12, 11);
      expect(j.toDateTime(), DateTime(2025, 3, 1));
    });

    test('Leap Year', () {
      JalaliDateTime j = JalaliDateTime(1402, 12, 10);
      expect(j.toDateTime(), DateTime(2024, 2, 29));
    });

    test('Beginning of Year', () {
      JalaliDateTime j = JalaliDateTime(1403, 10, 11);
      expect(j.toDateTime(), DateTime(2024, 12, 31));
    });

    test('End of Year', () {
      JalaliDateTime j = JalaliDateTime(1404, 10, 10);
      expect(j.toDateTime(), DateTime(2025, 12, 31));
    });

    test('Normal Year', () {
      final JalaliDateTime j = JalaliDateTime(1403, 12, 11);
      expect(j.toDateTime(), equals(DateTime(2025, 3, 1)));
    });

    test('Leap Year', () {
      final JalaliDateTime j = JalaliDateTime(1402, 12, 10);
      expect(j.toDateTime(), equals(DateTime(2024, 2, 29)));
    });

    test('Beginning of Year', () {
      final JalaliDateTime j = JalaliDateTime(1403, 10, 11);
      expect(j.toDateTime(), equals(DateTime(2024, 12, 31)));
    });

    test('End of Year', () {
      final JalaliDateTime j = JalaliDateTime(1404, 10, 10);
      expect(j.toDateTime(), equals(DateTime(2025, 12, 31)));
    });
  });

  group('Jalali Leap Year Handling', () {
    test('Leap Year Detection', () {
      expect(JalaliDateTime(1403).isLeapYear, true);
      expect(JalaliDateTime(1402).isLeapYear, false);
    });

    test('Valid Leap Day Conversion', () {
      JalaliDateTime j = JalaliDateTime(1403, 12, 30);
      expect(j.toDateTime(), DateTime(2025, 3, 20));
    });

    test('Invalid Leap Day Auto-Correction', () {
      JalaliDateTime j = JalaliDateTime(1402, 12, 30);
      expect(j.toDateTime(), DateTime(2024, 3, 20));
    });
  });

  group('Edge Cases and Special Dates', () {
    test('Nowruz (Farvardin 1)', () {
      JalaliDateTime j = JalaliDateTime(1403, 1, 1);
      expect(j.toDateTime(), DateTime(2024, 3, 20));
    });

    test('Shahrivar 30 Conversion', () {
      JalaliDateTime j = JalaliDateTime(1402, 6, 30);
      expect(j.toDateTime(), DateTime(2023, 9, 21));
    });

    test('Historical Date Conversion', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(1799, 3, 21));
      expect(j.toString(), "1178-01-01 00:00:00.000");
    });

    test('Future Date Conversion', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2100, 12, 31));
      expect(j.toString(), "1479-10-10 00:00:00.000");
    });

    test('Convert Oldest Jalali Date (Year 1)', () {
      JalaliDateTime j = JalaliDateTime(1, 1, 1); // Start of Jalali calendar
      DateTime g = j.toDateTime();
      expect(g, DateTime(622, 3, 22)); // Gregorian equivalent
    });

    test('Convert Shahrivar 31 (Valid 31-Day Month)', () {
      JalaliDateTime j = JalaliDateTime(1403, 6, 31); // Shahrivar ends on 31
      DateTime g = j.toDateTime();
      expect(g, DateTime(2024, 9, 21));
    });

    test('Cross-Check Mid-Year Conversion (1403-04-15)', () {
      JalaliDateTime j = JalaliDateTime(1403, 4, 15); // Tir 15
      DateTime g = j.toDateTime();
      expect(g, DateTime(2024, 7, 5));
    });
  });

  group('Time Handling', () {
    test('Time Component Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.hour, 14);
      expect(j.minute, 30);
      expect(j.second, 45);
    });

    test('Microsecond Preservation', () {
      DateTime gDate = DateTime(2025, 3, 1, 14, 30, 45, 123, 456);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.millisecond, 123);
      expect(j.microsecond, 456);
    });
  });

  group('Invalid Date Handling', () {
    test('Invalid Jalali Date Auto-Correction', () {
      JalaliDateTime j = JalaliDateTime(1403, 7, 31);
      expect(j.toDateTime(), DateTime(2024, 10, 22));
    });

    test('Invalid Gregorian Date Handling', () {
      JalaliDateTime j = JalaliDateTime(1403, 11, 30);
      expect(j.toDateTime(), DateTime(2025, 2, 18));
    });
  });

  group('Advanced Scenarios', () {
    test('Round-Trip Conversion', () {
      DateTime original = DateTime(2024, 3, 20);
      JalaliDateTime j = JalaliDateTime.fromDateTime(original);
      expect(j.toDateTime(), original);
    });

    test('Weekday Consistency', () {
      DateTime gDate = DateTime(2024, 3, 20);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.weekday, gDate.weekday);
    });

    test('Large Year Conversion', () {
      JalaliDateTime j = JalaliDateTime(2000, 1, 1);
      expect(j.toDateTime(), DateTime(2621, 3, 21));
    });

    test('Seasonal Conversion Check', () {
      JalaliDateTime j = JalaliDateTime.fromDateTime(DateTime(2024, 6, 21));
      expect(j.toString(), "1403-04-01 00:00:00.000");
    });
  });

  group('Time Zone Handling', () {
    test('UTC Time Preservation', () {
      DateTime gDate = DateTime.utc(2025, 3, 1, 14, 30);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.toString(), "1403-12-11 14:30:00.000Z");
    });

    test('DST Transition Handling', () {
      DateTime gDate = DateTime(2024, 3, 31, 2, 30);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.hour, 2);
    });
  });

  group('Time Zone Handling', () {
    test('UTC Time Preservation', () {
      DateTime gDate = DateTime.utc(2025, 3, 1, 14, 30);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.toString(), "1403-12-11 14:30:00.000Z");
    });

    test('DST Transition Handling', () {
      DateTime gDate = DateTime(2024, 3, 31, 2, 30);
      JalaliDateTime j = JalaliDateTime.fromDateTime(gDate);
      expect(j.hour, 2);
    });
  });

  group('Negative Date Normalization', () {
    test('Negative day normalization', () {
      // Starting at Jalali 1400/1/0 should roll back to the last day of the previous month.
      // Since 1400/1/0 → becomes 1399/12/day, and for 1399 the 12th month is 30 days (1399 % 33 == 13, a leap year)
      final dt = JalaliDateTime(1400, 1, 0);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
    });

    test('Negative month normalization', () {
      // A negative month should be normalized by adding 12 and decrementing the year.
      // For example, JalaliDateTime(1400, -1, 15) should become 1399/11/15.
      final dt = JalaliDateTime(1400, -1, 15);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(11));
      expect(dt.day, equals(15));
    });

    test('Negative hour normalization', () {
      // An hour underflow: JalaliDateTime(1400, 1, 1, -3)
      // Negative hours are added to 24 and one day is subtracted.
      // Expected: date becomes previous day; for 1400/1/1, it rolls back to 1399/12 with last day 30.
      final dt = JalaliDateTime(1400, 1, 1, -3);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, equals(21));
    });

    test('Negative minute normalization', () {
      // For negative minutes: JalaliDateTime(1400, 1, 1, 0, -90)
      // -90 minutes gives a -1 hour offset and remainder minutes.
      // Expected: hour decreases by 1 (from 0 to -1, then normalized to 23 of previous day) and minute becomes 30.
      final dt = JalaliDateTime(1400, 1, 1, 0, -90);
      final gt = DateTime(2025, 1, 1, 0, -90);
      expect(dt.year,
          equals(1399)); // Day normalization occurs only in the time component.
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
    });

    test('Negative second normalization', () {
      // For negative seconds: JalaliDateTime(1400, 1, 1, 0, 0, -75)
      // -75 seconds result in borrowing from minutes.
      // Expected: minute decreases by 1 and second becomes 45.
      final dt = JalaliDateTime(1400, 1, 1, 0, 0, -75);
      final gt = DateTime(1400, 1, 1, 0, 0, -75);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
      expect(dt.second, gt.second);
    });

    test('Negative microsecond normalization', () {
      // For negative microseconds: JalaliDateTime(1400, 1, 1, 0, 0, 0, 0, -1500)
      // -1500 microseconds should reduce the millisecond count.
      // Expected: microseconds become 500 and one millisecond is subtracted.
      final dt = JalaliDateTime(1400, 1, 1, 0, 0, 0, 0, -1500);
      final gt = DateTime(1400, 1, 1, 0, 0, 0, 0, -1500);
      expect(dt.year, equals(1399));
      expect(dt.month, equals(12));
      expect(dt.day, equals(30));
      // Since time is midnight and we borrow from the same unit, the date remains unchanged.
      // The hour, minute, and second remain zero.
      expect(dt.hour, gt.hour);
      expect(dt.minute, gt.minute);
      expect(dt.second, gt.second);
      // Check that the normalization yields 999 microseconds (after subtracting one millisecond)
      // if your normalization rolls the negative microsecond into the millisecond unit.
      // (Adjust this expected value according to your intended behavior.)
      expect(dt.millisecond,
          gt.millisecond); // This is an example; modify as needed.
      expect(dt.microsecond,
          gt.microsecond); // This is an example; modify as needed.
    });

    test('Negative day with hour zero', () {
      final dt = JalaliDateTime(1402, 9, 2, 0, -90);
      expect(dt.year, equals(1402));
      expect(dt.month, equals(9));
      expect(dt.day, equals(1));
      expect(dt.hour, equals(22));
      expect(dt.minute, equals(30));
    });

    test('test normal', () {
      final dt = JalaliDateTime(1402, 9, 1, 0, -90);
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
      final JalaliDateTime j = JalaliDateTime.fromDateTime(dt);
      // Expected output from your conversion logic.
      expect(j.toString(), equals("1403-12-11 14:30:45.123456"));
    });

    test('now returns valid JalaliDateTime', () {
      final JalaliDateTime jNow = JalaliDateTime.now();
      expect(jNow.year, isNotNull);
      expect(jNow.month, inInclusiveRange(1, 12));
      expect(jNow.day, inInclusiveRange(1, 31));
    });

    test('utc factory preserves UTC flag', () {
      final JalaliDateTime jUtc = JalaliDateTime.utc(1403, 12, 11, 14, 30);
      expect(jUtc.toDateTime().isUtc, isTrue);
    });

    test('fromSecondsSinceEpoch', () {
      final JalaliDateTime j =
          JalaliDateTime.fromSecondsSinceEpoch(1722782031, isUtc: true);
      expect(j.toString().endsWith("Z"), isTrue,
          reason: 'UTC marker expected in string');
    });

    test('fromMillisecondsSinceEpoch', () {
      final JalaliDateTime j =
          JalaliDateTime.fromMillisecondsSinceEpoch(1722782031520);
      expect(j.year, isNotNull);
    });

    test('Unix Epoch Conversion', () {
      final j = JalaliDateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      expect(j.year, 1348);
      expect(j.month, 10);
      expect(j.day, 11);
      expect(j.toString(), "1348-10-11 00:00:00.000Z");
    });

    test('fromMicrosecondsSinceEpoch', () {
      final JalaliDateTime j =
          JalaliDateTime.fromMicrosecondsSinceEpoch(1722782031520000);
      expect(j.day, inInclusiveRange(1, 31));
    });

    test('parse and tryParse', () {
      final String isoStr = "1403-12-11 14:30:45.123456Z";
      final JalaliDateTime parsed = JalaliDateTime.parse(isoStr);
      final JalaliDateTime? tryParsed = JalaliDateTime.tryParse(isoStr);
      expect(parsed.toString(), equals(tryParsed?.toString()));
      expect(() => JalaliDateTime.parse("invalid"), throwsFormatException);
    });

    test('Parse Jalali Date String', () {
      final j = JalaliDateTime.parse("1403-04-15 14:30:45");
      final j2 = JalaliDateTime(1403, 4, 15, 14, 30, 45);
      expect(j, j2);
    });
  });

  group('Date Arithmetic', () {
    test('Add Duration Across Months', () {
      final j = JalaliDateTime(1403, 6, 31).add(const Duration(days: 2));
      expect(j.toString(), "1403-07-02 00:00:00.000");
    });

    test('Subtract Months with Year Rollover', () {
      final j = JalaliDateTime(1403, 1, 1).subtract(Duration(days: 89));
      expect(j.toString(), "1402-10-01 00:00:00.000");
    });
  });

  group('Negative Normalization', () {
    test('Negative Day', () {
      final JalaliDateTime j = JalaliDateTime(1400, 1, 0);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
    });
    test('Negative Month', () {
      final JalaliDateTime j = JalaliDateTime(1400, -1, 15);
      expect(j.year, equals(1399));
      expect(j.month, equals(11));
      expect(j.day, equals(15));
    });
    test('Negative Hour', () {
      final JalaliDateTime j = JalaliDateTime(1400, 1, 1, -3);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(21));
    });
    test('Negative Minute', () {
      final JalaliDateTime j = JalaliDateTime(1400, 1, 1, 0, -90);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(22));
      expect(j.minute, equals(30));
    });
    test('Negative Second', () {
      final JalaliDateTime j = JalaliDateTime(1400, 1, 1, 0, 0, -75);
      expect(j.year, equals(1399));
      expect(j.month, equals(12));
      expect(j.day, equals(30));
      expect(j.hour, equals(23));
      expect(j.minute, equals(58));
      expect(j.second, equals(45));
    });
  });

  group('Julian Day Comparison', () {
    test('Compare with Gregorian in List', () {
      GregorianHelper gregorianHelper = GregorianHelper();
      for (int year = -5000; year <= 5000; year++) {
        final JalaliDateTime jalaliDatetime = JalaliDateTime(year);
        final DateTime dateTime = jalaliDatetime.toDateTime();
        expect(
            jalaliDatetime.julianDay,
            gregorianHelper.julianDay(
                dateTime.year, dateTime.month, dateTime.day),
            reason: "$year");
      }
    });
  });

  ///TODO: implement this high precision test cases
  // group("Bidirectional conversion", () {
  //   test("Check DateTime/JalaliDateTime in a Row From 1,1,1 Jalali", () {
  //     for (int day = 1; day <= 9000000; day++) {
  //       DateTime dateTime = DateTime(622, 3, 21 + day);
  //       JalaliDateTime jalaliDateTime = JalaliDateTime(1, 1, day);
  //       expect(jalaliDateTime.toDatetime(), dateTime);
  //     }
  //   });
  //
  //   test("Check DateTime/JalaliDateTime in a Row From 1,1,1 Gregorian", () {
  //     for (int day = 1; day <= 9000000; day++) {
  //       DateTime dateTime = DateTime(1, 1, day);
  //       JalaliDateTime jalaliDateTime = JalaliDateTime(-621, 10, 10 + day);
  //       expect(jalaliDateTime.toDatetime(), dateTime);
  //     }
  //   });
  // test('Beginning of Gregorian Calendar', () {
  //   final JalaliDateTime j =
  //   JalaliDateTime.fromDateTime(DateTime(1, 1, 1));
  //   expect(j.toString(), equals("-0621-10-11 00:00:00.000"));
  // });
  // });

  // group('Compare with another package', () {
  //   test('compare leap year', () {
  //     final Jalali another = Jalali(1635);
  //     final JalaliDatetime own = JalaliDatetime(1635);
  //     expect(own.isLeapYear, another.isLeapYear());
  //   });
  //
  //   test('compare leap year with conversion', () {
  //     final Jalali another = Jalali.fromDateTime(DateTime(2256));
  //     final JalaliDatetime own = JalaliDatetime.fromDateTime(DateTime(2256));
  //     print(own);
  //     print(another);
  //     print(another.isLeapYear());
  //     expect(own.isLeapYear, another.isLeapYear());
  //     // Expected: <1635>
  //     // Actual: <1634>
  //     // Year mismatch on 2256,3,20 => own:1634-12-30 00:00:00.000, another:Jalali(1635, 1, 1, 0, 0, 0, 0)
  //   });
  //
  //   test('compare leap year in list', () {
  //     for (int year = -60; year <= 3176; year++) {
  //       final Jalali another = Jalali(year);
  //       final JalaliDatetime own = JalaliDatetime(year);
  //       expect(own.isLeapYear, another.isLeapYear());
  //     }
  //   });
  //
  //   test('compare months', () {
  //     for (int year = 0; year <= 3000; year++) {
  //       for (int month = 1; month <= 12; month++) {
  //         final int another = Jalali(year, month).monthLength;
  //         final int own = JalaliDatetime(year, month).monthLength;
  //         expect(own, another, reason: 'Year mismatch on $year,$month => ');
  //       }
  //     }
  //   });
  //
  //   test('convert jalali to gregorian', () {
  //     for (int year = -60; year <= 1; year++) {
  //       for (int month = 1; month <= 12; month++) {
  //         for (int day = 1; day <= Jalali(year, month).monthLength; day++) {
  //           final Jalali another = Jalali(year, month, day);
  //           final JalaliDatetime own = JalaliDatetime(year, month, day);
  //           if (own.toDatetime() != another.toDateTime())
  //             print(
  //                 "$year, $month, $day, ${own.julianDay}, ${another.julianDayNumber}");
  //           expect(own.toDatetime(), another.toDateTime(),
  //               reason: 'Year mismatch on year:$year, month:$month');
  //         }
  //       }
  //     }
  //   });
  //
  //   test('convert gregorian to jalali list', () {
  //     GregorianHelper gregorianHelper = GregorianHelper();
  //     for (int year = 562; year <= 3797; year++) {
  //       for (int month = 1; month <= 12; month++) {
  //         for (int day = 1;
  //             day <= gregorianHelper.monthLength(year, month);
  //             day++) {
  //           final Jalali another =
  //               Jalali.fromDateTime(DateTime(year, month, day));
  //           final JalaliDatetime own =
  //               JalaliDatetime.fromDateTime(DateTime(year, month, day));
  //           expect(own.year, another.year,
  //               reason:
  //                   'Year mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
  //           expect(own.month, another.month,
  //               reason:
  //                   'Month mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
  //           expect(own.day, another.day,
  //               reason:
  //                   'Day mismatch on $year,$month,$day => own:${own.toString()}, another:${another.toString()}');
  //         }
  //       }
  //     }
  //   });
  //
  //   test('single convert gregorian to jalali', () {
  //     DateTime dateTime = DateTime(2256, 3, 20);
  //     final JalaliDatetime own = JalaliDatetime.fromDateTime(dateTime);
  //     final Jalali another = Jalali.fromDateTime(dateTime);
  //     print(own);
  //     print(another);
  //     print(own.isLeapYear);
  //     print(another.isLeapYear());
  //     expect(own.year, another.year);
  //     expect(own.month, another.month);
  //     expect(own.day, another.day);
  //   });
  // });
}
