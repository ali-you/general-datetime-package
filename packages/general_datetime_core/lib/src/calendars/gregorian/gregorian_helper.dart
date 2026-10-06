class GregorianHelper {
  final List<int> _months = [
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  int julianDay(int year, int month, int day) =>
      (((year + ((month - 8) ~/ 6) + 100100) * 1461) ~/ 4) +
      ((153 * ((month + 9) % 12) + 2) ~/ 5) +
      day -
      34840408 -
      ((((year + 100100 + ((month - 8) ~/ 6)) ~/ 100) * 3) ~/ 4) +
      752;

  bool isLeapYear(int year) {
    if (year % 4 == 0) {
      if (year % 100 == 0) {
        return year % 400 == 0;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  int monthLength(int year, int month) {
    if (month == 2) return isLeapYear(year) ? 29 : 28;
    return _months[month - 1];
  }
}
