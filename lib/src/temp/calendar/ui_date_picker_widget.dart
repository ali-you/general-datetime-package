import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:general_date_format/general_date_format.dart';
import 'package:general_datetime/general_datetime.dart';
import 'package:ui_kit/enums/calendar_type.dart';
import 'package:ui_kit/theme/ui_color.dart';

class UiDatePickerWidget extends StatefulWidget {
  UiDatePickerWidget({
    super.key,
    this.calendarType = CalendarType.gregorian,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.onDateChanged,
  }) : assert(
         !lastDate.isBefore(firstDate),
         'lastDate $lastDate must be on or after firstDate $firstDate.',
       ),
       assert(
         !initialDate.isBefore(firstDate),
         'initialDate $initialDate must be on or after firstDate $firstDate.',
       ),
       assert(
         !initialDate.isAfter(lastDate),
         'initialDate $initialDate must be on or before lastDate $lastDate.',
       );

  final CalendarType calendarType;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime selectedDate)? onDateChanged;

  Future<DateTime?> dialog(BuildContext context) async {
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    DateTime? res = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime? result = initialDate;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(localizations.datePickerHelpText),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: UiDatePickerWidget(
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    calendarType: calendarType,
                    onDateChanged: (selectedDate) {
                      result = selectedDate;
                      onDateChanged?.call(selectedDate);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.black),
                      child: Text(localizations.cancelButtonLabel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, result),
                      child: Text(localizations.okButtonLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return res;
  }

  Future<DateTime?> modalBottomSheet(BuildContext context) async {
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    DateTime? res = await showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        DateTime? result = initialDate;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(localizations.datePickerHelpText),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: UiDatePickerWidget(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  calendarType: calendarType,
                  onDateChanged: (selectedDate) {
                    result = selectedDate;
                    onDateChanged?.call(selectedDate);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ContentColor.second,
                        side: BorderSide(color: BorderColor.first),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(localizations.cancelButtonLabel),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, result),
                      style: FilledButton.styleFrom(
                          backgroundColor: BgColor.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: Text(localizations.okButtonLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return res;
  }

  @override
  State<UiDatePickerWidget> createState() => _UiDatePickerWidgetState();
}

class _UiDatePickerWidgetState extends State<UiDatePickerWidget> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  late JalaliDateTime _focusedJalaliDate;
  List<Widget> _days = [];
  bool _yearMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    JalaliDateTime j = JalaliDateTime.fromDateTime(widget.initialDate);
    _focusedJalaliDate = JalaliDateTime(j.year, j.month);
  }

  void _nextMonth() {
    setState(() {
      switch (widget.calendarType) {
        case CalendarType.persian:
          _focusedJalaliDate = JalaliDateTime(
            _focusedJalaliDate.year,
            _focusedJalaliDate.month + 1,
          );
          break;
        case CalendarType.gregorian:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
      }
    });
  }

  bool get _isLastMonth {
    switch (widget.calendarType) {
      case CalendarType.persian:
        JalaliDateTime j = JalaliDateTime.fromDateTime(widget.lastDate);
        return !_focusedJalaliDate.isBefore(JalaliDateTime(j.year, j.month));
      case CalendarType.gregorian:
        return !_focusedDate.isBefore(
          DateTime(widget.lastDate.year, widget.lastDate.month),
        );
    }
  }

  bool get _isFirstMonth {
    switch (widget.calendarType) {
      case CalendarType.persian:
        JalaliDateTime j = JalaliDateTime.fromDateTime(widget.firstDate);
        return !_focusedJalaliDate.isAfter(JalaliDateTime(j.year, j.month));
      case CalendarType.gregorian:
        return !_focusedDate.isAfter(
          DateTime(widget.firstDate.year, widget.firstDate.month),
        );
    }
  }

  Function()? _prevMonth() {
    setState(() {
      switch (widget.calendarType) {
        case CalendarType.persian:
          _focusedJalaliDate = JalaliDateTime(
            _focusedJalaliDate.year,
            _focusedJalaliDate.month - 1,
          );
          break;
        case CalendarType.gregorian:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
      }
    });
    return null;
  }

  String _getMonthName(MaterialLocalizations localizations, Locale locale) {
    switch (widget.calendarType) {
      case CalendarType.persian:
        return GeneralDateFormat.yMMMM(
          locale.languageCode,
        ).format(_focusedJalaliDate);
      case CalendarType.gregorian:
        return localizations.formatMonthYear(_focusedDate);
    }
  }

  List<Widget> _dayHeaders(
    TextStyle? headerStyle,
    MaterialLocalizations localizations,
  ) {
    final List<Widget> result = <Widget>[];
    for (
      int i = localizations.firstDayOfWeekIndex;
      result.length < DateTime.daysPerWeek;
      i = (i + 1) % DateTime.daysPerWeek
    ) {
      final String weekday = localizations.narrowWeekdays[i];
      result.add(
        ExcludeSemantics(
          child: Center(child: Text(weekday, style: headerStyle)),
        ),
      );
    }
    return result;
  }

  Widget _monthHeader(MaterialLocalizations localizations, Locale locale) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _yearMode = !_yearMode;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    _getMonthName(localizations, locale),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _isFirstMonth ? null : _prevMonth,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _isLastMonth ? null : _nextMonth,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime? dateA, DateTime? dateB) {
    return dateA?.year == dateB?.year &&
        dateA?.month == dateB?.month &&
        dateA?.day == dateB?.day;
  }

  bool _isSameDayJalali(JalaliDateTime? dateA, JalaliDateTime? dateB) {
    return dateA?.year == dateB?.year &&
        dateA?.month == dateB?.month &&
        dateA?.day == dateB?.day;
  }

  int get _daysInMonth {
    switch (widget.calendarType) {
      case CalendarType.persian:
        return _focusedJalaliDate.monthLength;
      case CalendarType.gregorian:
        return GregorianCalendarDelegate().getDaysInMonth(
          _focusedDate.year,
          _focusedDate.month,
        );
    }
  }

  int _dayOffset(Locale locale) {
    late final int weekdayFromMonday;
    final weekdayOffset = locale.languageCode == "fa" ? 0 : 1;
    switch (widget.calendarType) {
      case CalendarType.persian:
        weekdayFromMonday = _focusedJalaliDate.weekday - weekdayOffset;
        break;
      case CalendarType.gregorian:
        weekdayFromMonday =
            DateTime(_focusedDate.year, _focusedDate.month).weekday -
            weekdayOffset;
        break;
    }
    int firstDayOfWeekIndex = 0;
    firstDayOfWeekIndex = (firstDayOfWeekIndex - 1) % 7;
    return (weekdayFromMonday - firstDayOfWeekIndex) % 7;
  }

  void _calculateMonthDays(Locale locale) {
    switch (widget.calendarType) {
      case CalendarType.persian:
        _jalaliDays(locale);
        break;
      case CalendarType.gregorian:
        _gregorianDays(locale);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _gregorianDays(Locale locale) {
    _days = [];
    final int dayOffset = _dayOffset(locale);
    int day = -dayOffset;
    while (day < _daysInMonth) {
      day++;
      if (day < 1) {
        _days.add(const SizedBox.shrink());
      } else {
        final DateTime dayToBuild = DateTime(
          _focusedDate.year,
          _focusedDate.month,
          day,
        );
        final bool isDisabled =
            dayToBuild.isAfter(widget.lastDate) ||
            dayToBuild.isBefore(_dateOnly(widget.firstDate));
        final bool isSelectedDay = _isSameDay(_selectedDate, dayToBuild);
        final bool isToday = _isSameDay(DateTime.now(), dayToBuild);

        _days.add(
          _Day(
            date: dayToBuild,
            day: day,
            isDisabled: isDisabled,
            isSelectedDay: isSelectedDay,
            isToday: isToday,
            onChanged: (value) {
              setState(() {
                _selectedDate = value;
              });
              widget.onDateChanged?.call(value);
            },
          ),
        );
      }
      if (day == _daysInMonth) {
        int rows = ((dayOffset + _daysInMonth) / 7).ceil();
        int reminded = ((dayOffset + _daysInMonth) % 7);
        if (rows < 6) {
          if (rows == 5 && reminded == 0) {
            _days.add(const SizedBox.shrink());
          } else {
            _days.addAll(
              List.generate(8 - (reminded), (index) => const SizedBox.shrink()),
            );
          }
        }
      }
    }
  }

  void _jalaliDays(Locale locale) {
    _days = [];
    final int dayOffset = _dayOffset(locale);
    int day = -dayOffset;
    while (day < _daysInMonth) {
      day++;
      if (day < 1) {
        _days.add(const SizedBox.shrink());
      } else {
        final JalaliDateTime dayToBuild = JalaliDateTime(
          _focusedJalaliDate.year,
          _focusedJalaliDate.month,
          day,
        );
        final bool isDisabled =
            dayToBuild.isAfter(widget.lastDate) ||
            dayToBuild.isBefore(_dateOnly(widget.firstDate));
        final bool isSelectedDay = _isSameDayJalali(
          JalaliDateTime.fromDateTime(_selectedDate),
          dayToBuild,
        );
        final bool isToday = _isSameDayJalali(JalaliDateTime.now(), dayToBuild);

        _days.add(
          _Day(
            date: dayToBuild.toDateTime(),
            day: day,
            isDisabled: isDisabled,
            isSelectedDay: isSelectedDay,
            isToday: isToday,
            onChanged: (value) {
              setState(() {
                _selectedDate = value;
              });
              widget.onDateChanged?.call(value);
            },
          ),
        );
      }
      if (day == _daysInMonth) {
        int rows = ((dayOffset + _daysInMonth) / 7).ceil();
        int reminded = ((dayOffset + _daysInMonth) % 7);
        if (rows < 6) {
          if (rows == 5 && reminded == 0) {
            _days.add(const SizedBox.shrink());
          } else {
            _days.addAll(
              List.generate(8 - (reminded), (index) => const SizedBox.shrink()),
            );
          }
        }
      }
    }
  }

  Widget _gridDays(bool isRTL) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity == null) return;

        final isRTL = Directionality.of(context) == TextDirection.rtl;
        final multiplier = isRTL ? -1 : 1;

        if (velocity * multiplier < 0 && !_isLastMonth) {
          _nextMonth();
        } else if (velocity * multiplier > 0 && !_isFirstMonth) {
          _prevMonth();
        }
      },
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: _days,
      ),
    );
  }

  Widget _yearPicker(BuildContext context) {
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 3.0).scale(14) /
        14;

    final double decorationHeight = 36.0 * textScaleFactor;
    final double decorationWidth = 72.0 * textScaleFactor;

    const double _maxDayPickerHeightM3 = 48 * (6 + 1);

    final double scaledMaxDayPickerHeight =
        textScaleFactor > 1.3
            ? _maxDayPickerHeightM3 + ((6 + 1) * ((textScaleFactor - 1) * 8))
            : _maxDayPickerHeightM3;

    return SizedBox(
      height: scaledMaxDayPickerHeight,
      child: _YearPicker(
        initialDate: _focusedDate,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        calendarType: widget.calendarType,
        onChanged: (value) {
          switch (widget.calendarType) {
            case CalendarType.persian:
              _focusedJalaliDate = JalaliDateTime(
                value,
                _focusedJalaliDate.month,
              );
              _focusedDate = _focusedJalaliDate.toDateTime();
              break;
            case CalendarType.gregorian:
              _focusedDate = DateTime(value, _focusedDate.month);
          }
          setState(() {
            _yearMode = false;
          });
          // widget.onDateChanged?.call(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final locale = Localizations.localeOf(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    _calculateMonthDays(locale);
    return Column(
      spacing: 3,
      children: [
        _monthHeader(localizations, locale),
        if (!_yearMode) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayHeaders(null, localizations),
          ),
          _gridDays(isRTL),
        ] else ...[
          _yearPicker(context),
        ],
      ],
    );
  }
}

class _YearPickerGridDelegate extends SliverGridDelegate {
  const _YearPickerGridDelegate(this.context);

  final BuildContext context;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 3.0).scale(14) /
        14;
    final int scaledYearPickerColumnCount = textScaleFactor > 1.65 ? 3 - 1 : 3;
    final double tileWidth =
        (constraints.crossAxisExtent - (scaledYearPickerColumnCount - 1) * 8) /
        scaledYearPickerColumnCount;
    final double scaledYearPickerRowHeight =
        textScaleFactor > 1 ? 52 + ((textScaleFactor - 1) * 9) : 52;
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: scaledYearPickerRowHeight,
      crossAxisCount: scaledYearPickerColumnCount,
      crossAxisStride: tileWidth + 8,
      mainAxisStride: scaledYearPickerRowHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_YearPickerGridDelegate oldDelegate) => false;
}

class _Day extends StatelessWidget {
  const _Day({
    super.key,
    required this.date,
    required this.day,
    required this.isDisabled,
    required this.isSelectedDay,
    required this.isToday,
    required this.onChanged,
  });

  final DateTime date;
  final int day;
  final bool isDisabled;
  final bool isSelectedDay;
  final bool isToday;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    if (isSelectedDay) {
      bgColor = Theme.of(context).primaryColor;
    } else if (isToday) {
      bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
    }

    final textColor =
        isDisabled
            ? Colors.grey.shade400
            : isSelectedDay
            ? Colors.white
            : Colors.black87;

    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged.call(date),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelectedDay ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            "$day",
            style: TextStyle(
              color: textColor,
              fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _YearPicker extends StatefulWidget {
  const _YearPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    required this.calendarType,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<int> onChanged;
  final CalendarType calendarType;

  @override
  State<_YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<_YearPicker> {
  ScrollController? _scrollController;
  late int _initYear;
  late int _firstYear;
  late int _lastYear;

  @override
  void initState() {
    super.initState();
    _initializeYear();
    _scrollController = ScrollController(
      initialScrollOffset: _scrollOffsetForYear(_initYear),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _initializeYear() {
    switch (widget.calendarType) {
      case CalendarType.persian:
        _initYear = JalaliDateTime.fromDateTime(widget.initialDate).year;
        _firstYear = JalaliDateTime.fromDateTime(widget.firstDate).year;
        _lastYear = JalaliDateTime.fromDateTime(widget.lastDate).year;
        break;
      case CalendarType.gregorian:
        _initYear = widget.initialDate.year;
        _firstYear = widget.firstDate.year;
        _lastYear = widget.lastDate.year;
    }
  }

  Widget _yearItem({
    required int year,
    required bool isSelected,
    required bool isDisabled,
    required double decorationHeight,
    required double decorationWidth,
    required Function(int) onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(year),
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue : null,
        ),
        alignment: Alignment.center,
        child: Text(
          year.toString(),
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  double _scrollOffsetForYear(int year) {
    final int initialYearIndex = year - _firstYear;
    final int initialYearRow = initialYearIndex ~/ 3;
    final int centeredYearRow = initialYearRow - 2;
    return centeredYearRow * 52;
  }

  Widget _buildYearItem(BuildContext context, int index) {
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 3.0).scale(14) /
        14;

    final int year = _firstYear + index;
    final bool isSelected = year == _initYear;
    final bool isDisabled = year < _firstYear || year > _lastYear;
    final double decorationHeight = 36.0 * textScaleFactor;
    final double decorationWidth = 72.0 * textScaleFactor;

    return _yearItem(
      year: year,
      isSelected: isSelected,
      isDisabled: isDisabled,
      decorationHeight: decorationHeight,
      decorationWidth: decorationWidth,
      onTap: (value) => widget.onChanged(year),
    );
  }

  int get _itemCount => widget.lastDate.year - widget.firstDate.year + 1;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: _YearPickerGridDelegate(context),
      itemCount: _itemCount,
      dragStartBehavior: DragStartBehavior.start,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: _buildYearItem,
    );
  }
}
