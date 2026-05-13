import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Event({required this.title, required this.startTime, required this.endTime});
}

enum CalendarSelectionMode { single, range }

class CalendarWidget extends StatefulWidget {
  final CalendarSelectionMode selectionMode;
  final int? activeMinMaxMonth;
  final void Function(DateTime selectedDate, bool isChangedMonth)? onDateSelected;
  final void Function(DateTime start, DateTime? end)? onRangeSelected;
  final Map<DateTime, List<Event>> events;
  final DateTime? baseMonth;

  /// ✅ تاریخ حداقل قابل انتخاب
  final DateTime? minDate;

  /// ✅ تاریخ حداکثر قابل انتخاب
  final DateTime? maxDate;

  const CalendarWidget({
    Key? key,
    this.selectionMode = CalendarSelectionMode.single,
    this.activeMinMaxMonth,
    this.onDateSelected,
    this.onRangeSelected,
    this.events = const {},
    this.baseMonth,
    this.minDate,
    this.maxDate,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late final DateTime _baseMonth;
  late DateTime _focusedMonth;
  late DateTime _minMonth;
  late DateTime _maxMonth;

  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final List<String> _weekDays = ['mon'.tr, 'tue'.tr, 'wed'.tr, 'thu'.tr, 'fri'.tr, 'sat'.tr, 'sun'.tr];

  @override
  void initState() {
    super.initState();
    final bm = widget.baseMonth ?? DateTime.now();
    _baseMonth = DateTime(bm.year, bm.month, 1);
    _focusedMonth = DateTime(_baseMonth.year, _baseMonth.month, 1);

    _minMonth = DateTime(_baseMonth.year, _baseMonth.month - (widget.activeMinMaxMonth ?? 20), 1);
    _maxMonth = DateTime(_baseMonth.year, _baseMonth.month + (widget.activeMinMaxMonth ?? 20), 1);
  }

  String _getMonthName(int month) {
    final months = [
      'january'.tr, 'february'.tr, 'march'.tr, 'april'.tr, 'may'.tr, 'june'.tr,
      'july'.tr, 'august'.tr, 'september'.tr, 'october'.tr, 'november'.tr, 'december'.tr
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return !date.isBefore(_rangeStart!) && !date.isAfter(_rangeEnd!);
  }

  /// ✅ بررسی اینکه روز قابل انتخاب هست یا نه
  bool _isSelectable(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) return false;
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekDay = (firstDay.weekday + 6) % 7;
    final today = DateTime.now();

    final List<Widget> dayCells = [];

    // خالی‌های قبل از شروع ماه
    for (int i = 0; i < firstWeekDay; i++) {
      dayCells.add(Container());
    }

    // روزهای ماه
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isToday = _isSameDay(today, date);
      final isSelectable = _isSelectable(date);

      final isSelected = widget.selectionMode == CalendarSelectionMode.single
          ? _selectedDate != null && _isSameDay(_selectedDate!, date)
          : _rangeStart != null && _isSameDay(_rangeStart!, date) ||
          _rangeEnd != null && _isSameDay(_rangeEnd!, date);

      final isInRange = widget.selectionMode == CalendarSelectionMode.range && _isInRange(date);

      final List<Event> events = widget.events.keys
          .where((d) => _isSameDay(d, date))
          .expand((d) => widget.events[d]!)
          .toList();

      dayCells.add(_buildDayCell(
        context,
        date: date,
        day: day,
        isToday: isToday,
        isSelected: isSelected,
        isInRange: isInRange,
        isSelectable: isSelectable,
        events: events,
      ));
    }

    // پر کردن خالی‌های انتهای ماه
    final remainder = dayCells.length % 7;
    if (remainder != 0) {
      for (int i = 0; i < 7 - remainder; i++) {
        dayCells.add(Container());
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        bool changed = false;

        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0 && _focusedMonth.isBefore(_maxMonth)) {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
              changed = true;
            });
          } else if (details.primaryVelocity! > 0 && _focusedMonth.isAfter(_minMonth)) {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
              changed = true;
            });
          }

          if(changed) {
            widget.onDateSelected?.call(_focusedMonth, true);
          }
        }
      },
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 8),
          Row(
            children: _weekDays
                .map((d) => Expanded(
              child: Center(
                child: Text(d, style: const TextStyle(fontWeight: FontWeight.w400)),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: dayCells,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
      BuildContext context, {
        required DateTime date,
        required int day,
        required bool isToday,
        required bool isSelected,
        required bool isInRange,
        required bool isSelectable,
        required List<Event> events,
      }) {
    const int maxDots = 4;
    List<Widget> eventIndicators = [];
    if (events.length <= maxDots) {
      eventIndicators = events.map((e) => _buildDot()).toList();
    } else {
      final int extra = events.length - maxDots + 1;
      eventIndicators = events.take(maxDots - 1).map((e) => _buildDot()).toList();
      eventIndicators.add(_buildDotWithPlus(extra));
    }

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = Theme.of(context).primaryColor;
    } else if (isInRange) {
      bgColor = Theme.of(context).primaryColor.withOpacity(0.2);
    } else if (isToday) {
      bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
    }

    final textColor = !isSelectable
        ? Colors.grey.shade400
        : isSelected
        ? Colors.white
        : Colors.black87;

    return GestureDetector(
      onTap: isSelectable
          ? () {
        setState(() {
          if (widget.selectionMode == CalendarSelectionMode.single) {
            _selectedDate = date;
            widget.onDateSelected?.call(date, false);
          } else {
            if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
              _rangeStart = date;
              _rangeEnd = null;
            } else {
              if (date.isBefore(_rangeStart!)) {
                final temp = _rangeStart;
                _rangeStart = date;
                _rangeEnd = temp;
              } else {
                _rangeEnd = date;
              }
              widget.onRangeSelected?.call(_rangeStart!, _rangeEnd);
            }
          }
        });
      }
          : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelectable ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$day",
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            if (events.isNotEmpty && isSelectable)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: eventIndicators),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    final canGoPrev = _focusedMonth.isAfter(_minMonth);
    final canGoNext = _focusedMonth.isBefore(_maxMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoPrev
                  ? () => setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                widget.onDateSelected?.call(_focusedMonth, true);
              })
                  : null,
            ),
            Expanded(
              child: Text(
                textAlign: TextAlign.center,
                '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext
                  ? () => setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                widget.onDateSelected?.call(_focusedMonth, true);
              })
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
    );
  }

  Widget _buildDotWithPlus(int extra) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        "+$extra",
        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
