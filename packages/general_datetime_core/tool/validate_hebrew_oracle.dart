import 'dart:convert';
import 'dart:io';

import 'package:general_datetime_core/general_datetime_core.dart';

/// Validates every supported date against independently generated year tables.
/// Generate input using tool/generate_hebrew_oracle.mjs in the repository.
void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError('Provide the independent oracle JSON path.');
  }
  final data = jsonDecode(File(args.single).readAsStringSync()) as Map;
  var days = 0;
  var months = 0;
  final epoch = DateTime.utc(1970);
  for (final entry in data['years'] as List) {
    final year = entry['year'] as int;
    var index = entry['startDay'] as int;
    if (CalendarSystems.hebrew.daysInYear(year) != entry['yearLength']) {
      throw StateError('Year length $year');
    }
    final lengths = List<int>.from(entry['lengths']);
    for (var slot = 1; slot <= 13; slot++) {
      final size = lengths[slot - 1];
      if (size == 0) {
        if (HebrewDateTime.isValidDate(year, slot, 1)) {
          throw StateError('Absent slot $year/$slot');
        }
        continue;
      }
      months++;
      if (HebrewDateTime.daysInMonth(year, slot) != size) {
        throw StateError('Month length $year/$slot');
      }
      for (var day = 1; day <= size; day++, index++) {
        final gregorian = epoch.add(Duration(days: index));
        final actual = HebrewDateTime.fromDateTime(gregorian);
        if ((actual.year, actual.month, actual.day) != (year, slot, day)) {
          throw StateError('Conversion $gregorian expected $year/$slot/$day '
              'got $actual');
        }
        if (HebrewDateTime.utc(year, slot, day).toDateTime() != gregorian) {
          throw StateError('Reverse $year/$slot/$day');
        }
        if (actual.weekday != gregorian.weekday) {
          throw StateError('Weekday $year/$slot/$day');
        }
        days++;
      }
    }
  }
  print('Independent oracle passed: ${data['source']}, ${data['calendar']}; '
      '${(data['years'] as List).length} years, $months months, '
      '$days days in both directions.');
}
