/// Copies an instant without combining its millisecond and microsecond parts.
/// JavaScript epoch microseconds can exceed its exact-integer range even when
/// the native DateTime still preserves both components separately.
DateTime copyNativeDateTime(DateTime value, {bool? isUtc}) {
  final result = DateTime.fromMillisecondsSinceEpoch(
      floorEpochMilliseconds(value),
      isUtc: isUtc ?? value.isUtc);
  return value.microsecond == 0
      ? result
      : result.add(Duration(microseconds: value.microsecond));
}

/// Older VM SDKs truncate negative epoch milliseconds toward zero. The clock
/// millisecond component identifies that case without combining a large epoch
/// with its fractional part or rounding on JavaScript.
int floorEpochMilliseconds(DateTime value) {
  final millis = value.millisecondsSinceEpoch;
  return millis % Duration.millisecondsPerSecond == value.millisecond
      ? millis
      : millis - 1;
}
