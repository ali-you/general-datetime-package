import 'dart:convert';
import 'dart:io';

import 'package:general_datetime_core/general_datetime_core.dart';
import 'package:test/test.dart';

void main() {
  test('Dart dependency graph has no Flutter packages or compatibility wrapper',
      () {
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final names = (config['packages'] as List)
        .map((entry) => (entry as Map)['name'])
        .toSet();
    expect(names, contains('general_datetime_core'));
    expect(names, isNot(contains('flutter')));
    expect(names, isNot(contains('flutter_test')));
    expect(names, isNot(contains('general_datetime')));
  });

  test('calendars retain one independent Gregorian instant and precision', () {
    final instant = DateTime.utc(2024, 3, 20, 13, 5, 6, 123, 456);
    final persian = PersianDateTime.fromDateTime(instant);
    final hijri = HijriDateTime.fromDateTime(instant);
    expect([persian.year, persian.month, persian.day], [1403, 1, 1]);
    expect([hijri.year, hijri.month, hijri.day], [1445, 9, 10]);
    for (final date in <DateTime>[persian, hijri]) {
      expect(date.isUtc, isTrue);
      expect(date.microsecondsSinceEpoch, instant.microsecondsSinceEpoch);
      expect(CalendarDateUtils.toGregorian(date), instant);
      expect(date, instant);
      expect(instant, date);
      expect({instant: 'shared'}[date], 'shared');
    }
  });

  test('field helpers preserve the selected chronology', () {
    final date = PersianDateTime.utc(1403, 1, 1, 13, 5);
    final next = CalendarDateUtils.copyWith(date, day: 2);
    expect(next, isA<PersianDateTime>());
    expect(
        CalendarDateUtils.toGregorian(next), DateTime.utc(2024, 3, 21, 13, 5));
    final civil = CalendarDateUtils.dateOnly(next);
    expect(civil, isA<PersianDateTime>());
    expect(civil.isUtc, isTrue);
    expect(civil.hour, 0);
  });

  test('instant and civil records round trip without a Flutter runtime', () {
    final date = HijriDateTime.utc(1445, 9, 10, 13, 5, 6, 123, 456);
    final instant = CalendarInstant.fromDateTime(date);
    final restored = CalendarInstant.fromJson(jsonDecode(jsonEncode(instant)));
    expect(restored.instant, DateTime.utc(2024, 3, 20, 13, 5, 6, 123, 456));
    expect(restored.calendar, CalendarId.islamicUmalqura);
    final civil = CalendarDateRecord.fromDateTime(date);
    final restoredCivil =
        CalendarDateRecord.fromJson(jsonDecode(jsonEncode(civil)));
    expect(restoredCivil.toJson(), civil.toJson());
  });

  test('corrected negative epoch rounding and finite Hijri bounds remain', () {
    expect(
      PersianDateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true)
          .secondsSinceEpoch,
      -1,
    );
    expect(() => HijriDateTime.utc(1601), throwsRangeError);
    expect(() => HijriDateTime.utc(1299), throwsRangeError);
  });
}
