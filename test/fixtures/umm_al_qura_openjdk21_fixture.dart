/// Independent Umm al-Qura reference data derived from Unicode ICU 78.3's
/// `IslamicCalendar` data under the Unicode License V3 documented in
/// `THIRD_PARTY_NOTICES.md`. The resulting month sequence and endpoints were
/// independently cross-checked against OpenJDK 21's `Hijrah-umalqura`
/// chronology.
///
/// Each three-hex-digit word represents one Hijri year from AH 1300 through
/// AH 1600. Bit `month - 1` is one for a 30-day month and zero for a 29-day
/// month. The fixture deliberately does not import package implementation code.
final class UmmAlQuraOpenJdk21Fixture {
  static const int minimumYear = 1300;
  static const int maximumYear = 1600;

  static final DateTime firstGregorianUtc = DateTime.utc(1882, 11, 12);
  static final DateTime lastGregorianUtc = DateTime.utc(2174, 11, 25);

  static const String _encodedMonthLengths = '''
5552ab9372b657636cb55aaa95649e95d2ba5b53aab4ba9652e2ad56db5a
752f25e8ad16a56ab56b4da9b92b2564ba9b35a6d95d4da5d4aa95536975
2f46e96d46a953525d4bd9ba3b4b69b2aa554ada5d2da6d9eaae94d2ac56
4aea6d56ad55d4aa9352ba5b53a6b5ea9d52d29a554ad56daea6e4ed1da2
aaa95a2da5b9bb27646c95552ab4dbaba5b4da9d52aa592d26d8ed2daad5
aa5a4b4979372b6975d69d52c9592b25b4db9d55d2da5d4aa9554daad3aa
bd2bc4b89a9552d5adb6a6d4dc9d92aa69562ae56d36ab55aaa94d49d95d
2ba5b55aad55a9a92e26e55dada6d46a5b27a4d4ad56db5a754f49e92d26
a563566b5baab92b2568ba9b55aada5b4da9b52a9a536276575af26d46a9
5552ad4bd9ba574b69b52a9552da5d4daad96b2e95e2ac9692eaad56ad65
d4ad1562bc5b53a6b5db2d64d29a554ad96daea6e8ed1da4d4aa6a2da5b9
b72b686d16554ab95b2ba5b5da9d52ca694e46e95d4daad5aaaa4d49b937
4b6975d6ad52aa594b2ab55bad95d2dc5d92b25555ab55b4ba97a2745593
aab4d69d65d2ba5b4aa954ad15d2dd9da5b45a952d25b8b717656db6aaca
a9652b15b2bb5b6daab94d46a8d52da9d55a755749f13e4aa965566b5baa
b94
''';

  static final List<int> _yearMasks = _decodeYearMasks();

  static int get encodedYearCount => _yearMasks.length;

  static int monthLength(int year, int month) {
    RangeError.checkValueInInterval(
      year,
      minimumYear,
      maximumYear,
      'year',
    );
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    final int mask = _yearMasks[year - minimumYear];
    return 29 + ((mask >> (month - 1)) & 1);
  }

  static int yearLength(int year) {
    int result = 0;
    for (int month = 1; month <= 12; month++) {
      result += monthLength(year, month);
    }
    return result;
  }

  static int get totalSupportedDays {
    int result = 0;
    for (int year = minimumYear; year <= maximumYear; year++) {
      result += yearLength(year);
    }
    return result;
  }

  static int dayOffset(int year, int month, int day) {
    final int daysInMonth = monthLength(year, month);
    RangeError.checkValueInInterval(day, 1, daysInMonth, 'day');

    int result = 0;
    for (int currentYear = minimumYear; currentYear < year; currentYear++) {
      result += yearLength(currentYear);
    }
    for (int currentMonth = 1; currentMonth < month; currentMonth++) {
      result += monthLength(year, currentMonth);
    }
    return result + day - 1;
  }

  static DateTime gregorianUtc(int year, int month, int day) =>
      firstGregorianUtc.add(Duration(days: dayOffset(year, month, day)));

  static ReferenceHijriDate dateAfter(
    int year,
    int month,
    int day,
    int days,
  ) {
    int remaining = dayOffset(year, month, day) + days;
    RangeError.checkValueInInterval(
      remaining,
      0,
      totalSupportedDays - 1,
      'day offset',
    );

    int resultYear = minimumYear;
    while (remaining >= yearLength(resultYear)) {
      remaining -= yearLength(resultYear);
      resultYear++;
    }

    int resultMonth = 1;
    while (remaining >= monthLength(resultYear, resultMonth)) {
      remaining -= monthLength(resultYear, resultMonth);
      resultMonth++;
    }
    return ReferenceHijriDate(resultYear, resultMonth, remaining + 1);
  }

  static List<int> _decodeYearMasks() {
    final String encoded = _encodedMonthLengths.replaceAll(RegExp(r'\s+'), '');
    if (encoded.length % 3 != 0) {
      throw StateError('The OpenJDK Umm al-Qura fixture is truncated.');
    }
    return <int>[
      for (int index = 0; index < encoded.length; index += 3)
        int.parse(encoded.substring(index, index + 3), radix: 16),
    ];
  }
}

final class ReferenceHijriDate {
  const ReferenceHijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  String toString() => '$year-$month-$day';
}
