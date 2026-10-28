import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/general_datetime.dart';

void main() {
  const localizations = DefaultChineseCalendarMaterialLocalizations();
  test(
      'English picker accepts decimal civil dates and rejects numeric syntax masquerading as dates',
      () {
    for (final input in ['1/7/2025', '01/07/2025', ' 01 / 07 / 2025 ']) {
      expect(localizations.parseCompactDate(input), ChineseDateTime(2025, 7));
    }
    for (final input in [
      '0x1/7/2025',
      '1/0x7/2025',
      '1/7/0x7e9',
      '+1/7/2025',
      '1/+7/2025',
      '1/7/+2025',
      '001/007/2025',
      '1/7/2025.0',
      '1/7/2e3',
      '١/٧/٢٠٢٥',
      '1/7/2025extra',
      '1//7/2025',
      '1/7/2025/1',
      '30/7/2025'
    ]) {
      expect(localizations.parseCompactDate(input), isNull, reason: input);
    }
  });
}
