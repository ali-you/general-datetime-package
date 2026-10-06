import 'package:flutter/material.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

import '../fixtures/umm_al_qura_openjdk21_fixture.dart';
import '../fixtures/university_tehran_persian_fixture.dart';

typedef CalendarConstructor = DateTime Function(
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond,
);

/// Shared public-API tests use independent fixtures for calendar expectations.
class CalendarTestCase {
  CalendarTestCase({
    required this.name,
    required this.type,
    required this.anchorYear,
    required this.minimumYear,
    required this.maximumYear,
    required this.minimumGregorian,
    required this.maximumGregorian,
    required this.lastDay,
    required this.fixtureMinimumYear,
    required this.fixtureMaximumYear,
    required this.utc,
    required this.local,
    required this.fromDateTime,
    required this.fromMicroseconds,
    required this.fromMilliseconds,
    required this.fromSeconds,
    required this.parse,
    required this.tryParse,
    required this.isValidDate,
    required this.referenceMonthLength,
    required this.referenceGregorian,
    required this.referenceFields,
    required this.delegate,
    required this.localizations,
    required this.localizationDelegate,
  });

  final String name;
  final Type type;
  final int anchorYear;
  final int minimumYear;
  final int maximumYear;
  final DateTime minimumGregorian;
  final DateTime maximumGregorian;
  final int lastDay;
  final int fixtureMinimumYear;
  final int fixtureMaximumYear;
  final CalendarConstructor utc;
  final CalendarConstructor local;
  final DateTime Function(DateTime) fromDateTime;
  final DateTime Function(int, bool) fromMicroseconds;
  final DateTime Function(int, bool) fromMilliseconds;
  final DateTime Function(int, bool) fromSeconds;
  final DateTime Function(String) parse;
  final DateTime? Function(String) tryParse;
  final bool Function(int, int, int) isValidDate;
  final int Function(int, int) referenceMonthLength;
  final DateTime Function(int, int, int) referenceGregorian;
  final (int, int, int) Function(DateTime) referenceFields;
  final CalendarDelegate<DateTime> delegate;
  final MaterialLocalizations localizations;
  final LocalizationsDelegate<MaterialLocalizations> localizationDelegate;

  DateTime make(int year, int month, int day,
          {int hour = 0,
          int minute = 0,
          int second = 0,
          int millisecond = 0,
          int microsecond = 0,
          bool isUtc = true}) =>
      (isUtc ? utc : local)(
          year, month, day, hour, minute, second, millisecond, microsecond);

  bool supportsWallDate(DateTime date) {
    final DateTime wall = DateTime.utc(date.year, date.month, date.day);
    return !wall.isBefore(minimumGregorian) && !wall.isAfter(maximumGregorian);
  }
}

final List<CalendarTestCase> calendarTestCases = <CalendarTestCase>[
  CalendarTestCase(
    name: 'Persian',
    type: PersianDateTime,
    anchorYear: 1403,
    minimumYear: -61,
    maximumYear: 3177,
    minimumGregorian: DateTime.utc(560, 3, 20),
    maximumGregorian: DateTime.utc(3799, 3, 19),
    lastDay: 29,
    fixtureMinimumYear: UniversityTehranPersianFixture.minimumYear,
    fixtureMaximumYear: UniversityTehranPersianFixture.maximumYear,
    utc: PersianDateTime.utc,
    local: PersianDateTime.new,
    fromDateTime: PersianDateTime.fromDateTime,
    fromMicroseconds: (int value, bool isUtc) =>
        PersianDateTime.fromMicrosecondsSinceEpoch(value, isUtc: isUtc),
    fromMilliseconds: (int value, bool isUtc) =>
        PersianDateTime.fromMillisecondsSinceEpoch(value, isUtc: isUtc),
    fromSeconds: (int value, bool isUtc) =>
        PersianDateTime.fromSecondsSinceEpoch(value, isUtc: isUtc),
    parse: PersianDateTime.parse,
    tryParse: PersianDateTime.tryParse,
    isValidDate: PersianDateTime.isValidDate,
    referenceMonthLength: UniversityTehranPersianFixture.monthLength,
    referenceGregorian: UniversityTehranPersianFixture.gregorianUtc,
    referenceFields: (DateTime date) {
      final int days = DateTime.utc(date.year, date.month, date.day)
          .difference(UniversityTehranPersianFixture.firstGregorianUtc)
          .inDays;
      final ReferencePersianDate expected =
          UniversityTehranPersianFixture.dateAfter(1206, 1, 1, days);
      return (expected.year, expected.month, expected.day);
    },
    delegate: const PersianCalendarDelegate(),
    localizations: const DefaultPersianCalendarMaterialLocalizations(),
    localizationDelegate: DefaultPersianCalendarMaterialLocalizations.delegate,
  ),
  CalendarTestCase(
    name: 'Hijri',
    type: HijriDateTime,
    anchorYear: 1446,
    minimumYear: 1300,
    maximumYear: 1600,
    minimumGregorian: DateTime.utc(1882, 11, 12),
    maximumGregorian: DateTime.utc(2174, 11, 25),
    lastDay: 30,
    fixtureMinimumYear: UmmAlQuraOpenJdk21Fixture.minimumYear,
    fixtureMaximumYear: UmmAlQuraOpenJdk21Fixture.maximumYear,
    utc: HijriDateTime.utc,
    local: HijriDateTime.new,
    fromDateTime: HijriDateTime.fromDateTime,
    fromMicroseconds: (int value, bool isUtc) =>
        HijriDateTime.fromMicrosecondsSinceEpoch(value, isUtc: isUtc),
    fromMilliseconds: (int value, bool isUtc) =>
        HijriDateTime.fromMillisecondsSinceEpoch(value, isUtc: isUtc),
    fromSeconds: (int value, bool isUtc) =>
        HijriDateTime.fromSecondsSinceEpoch(value, isUtc: isUtc),
    parse: HijriDateTime.parse,
    tryParse: HijriDateTime.tryParse,
    isValidDate: HijriDateTime.isValidDate,
    referenceMonthLength: UmmAlQuraOpenJdk21Fixture.monthLength,
    referenceGregorian: UmmAlQuraOpenJdk21Fixture.gregorianUtc,
    referenceFields: (DateTime date) {
      final int days = DateTime.utc(date.year, date.month, date.day)
          .difference(UmmAlQuraOpenJdk21Fixture.firstGregorianUtc)
          .inDays;
      final ReferenceHijriDate expected =
          UmmAlQuraOpenJdk21Fixture.dateAfter(1300, 1, 1, days);
      return (expected.year, expected.month, expected.day);
    },
    delegate: const HijriCalendarDelegate(),
    localizations: const DefaultHijriCalendarMaterialLocalizations(),
    localizationDelegate: DefaultHijriCalendarMaterialLocalizations.delegate,
  ),
];

DateTime nativeDate(DateTime value) =>
    (value as GeneralDateTimeInterface).toDateTime();

String isoYear(int year) =>
    '${year < 0 ? '-' : ''}${year.abs().toString().padLeft(4, '0')}';

String isoDate(int year, int month, int day) =>
    '${isoYear(year)}-${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';
