import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/general_datetime.dart' as flutter_api;
import 'package:general_datetime_core/general_datetime_core.dart' as core;

void main() {
  test('Flutter exports share date and serialization identities with Dart core',
      () {
    expect(flutter_api.PersianDateTime, core.PersianDateTime);
    expect(flutter_api.HijriDateTime, core.HijriDateTime);
    expect(flutter_api.GeneralDateTimeInterface, core.GeneralDateTimeInterface);
    expect(flutter_api.CalendarDateUtils, core.CalendarDateUtils);
    expect(flutter_api.CalendarInstant, core.CalendarInstant);
    expect(flutter_api.CalendarDateRecord, core.CalendarDateRecord);
    expect(flutter_api.CalendarId, core.CalendarId);
  });
}
