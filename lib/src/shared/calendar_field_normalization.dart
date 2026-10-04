// Ordinary components stay well below int64 and JavaScript's exact-integer
// limits. Extreme components use BigInt so cancellation remains meaningful.
const _ordinaryLimit = 1000000;

bool _ordinary(int value) =>
    value >= -_ordinaryLimit && value <= _ordinaryLimit;

int _floorDiv(int value, int divisor) {
  final quotient = value ~/ divisor;
  return value.remainder(divisor) < 0 ? quotient - 1 : quotient;
}

/// Normalize the month before the calendar checks its supported year range.
/// The extra year is available only for the calendar's end sentinel.
(int, int) normalizeCalendarMonth(
    int year, int month, int minimumYear, int maximumYear) {
  if (_ordinary(year) && _ordinary(month)) {
    final index = month - 1;
    return (year + _floorDiv(index, 12), index % 12 + 1);
  }
  final index = BigInt.from(month) - BigInt.one;
  final remainder = index % BigInt.from(12);
  final normalizedYear =
      BigInt.from(year) + (index - remainder) ~/ BigInt.from(12);
  if (normalizedYear < BigInt.from(minimumYear) ||
      normalizedYear > BigInt.from(maximumYear + 1)) {
    throw RangeError('Normalized year $normalizedYear is outside the '
        'supported calendar range ($minimumYear through $maximumYear)');
  }
  return (normalizedYear.toInt(), remainder.toInt() + 1);
}

/// Return a supported day offset and the nonnegative clock within that day.
/// Validate exact results before converting BigInt values back to int.
(int, int) normalizeCalendarTime(
  int monthStartOffset,
  int supportedDayCount,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond,
) {
  const microsPerDay = Duration.microsecondsPerDay;
  if (_ordinary(day) &&
      _ordinary(hour) &&
      _ordinary(minute) &&
      _ordinary(second) &&
      _ordinary(millisecond) &&
      _ordinary(microsecond)) {
    final time = hour * Duration.microsecondsPerHour +
        minute * Duration.microsecondsPerMinute +
        second * Duration.microsecondsPerSecond +
        millisecond * Duration.microsecondsPerMillisecond +
        microsecond;
    return (
      monthStartOffset + day - 1 + _floorDiv(time, microsPerDay),
      time % microsPerDay
    );
  }
  final time = BigInt.from(hour) * BigInt.from(Duration.microsecondsPerHour) +
      BigInt.from(minute) * BigInt.from(Duration.microsecondsPerMinute) +
      BigInt.from(second) * BigInt.from(Duration.microsecondsPerSecond) +
      BigInt.from(millisecond) *
          BigInt.from(Duration.microsecondsPerMillisecond) +
      BigInt.from(microsecond);
  final divisor = BigInt.from(microsPerDay);
  final remainder = time % divisor;
  final offset = BigInt.from(monthStartOffset) +
      BigInt.from(day) -
      BigInt.one +
      (time - remainder) ~/ divisor;
  if (offset.isNegative || offset >= BigInt.from(supportedDayCount)) {
    throw RangeError('Normalized date is outside the supported calendar range');
  }
  return (offset.toInt(), remainder.toInt());
}
