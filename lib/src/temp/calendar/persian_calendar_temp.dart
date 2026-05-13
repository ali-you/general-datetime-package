import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Event({required this.title, required this.startTime, required this.endTime});
}

class SimplePersianCalendar extends StatefulWidget {
  final void Function(Jalali selectedDate)? onDateSelected;
  final Map<Jalali, List<Event>> events;

  const SimplePersianCalendar({
    Key? key,
    this.onDateSelected,
    this.events = const {},
  }) : super(key: key);

  @override
  State<SimplePersianCalendar> createState() => _SimplePersianCalendarState();
}

class _SimplePersianCalendarState extends State<SimplePersianCalendar> {
  Jalali _focusedMonth = Jalali.now();
  Jalali? _selectedDate;

  final List<String> _weekDays = [
    "شنبه","یکشنبه","دوشنبه","سه‌شنبه","چهارشنبه","پنجشنبه","جمعه"
  ];

  String _getPersianMonthName(int month) {
    const months = [
      "فروردین","اردیبهشت","خرداد","تیر","مرداد","شهریور",
      "مهر","آبان","آذر","دی","بهمن","اسفند"
    ];
    return months[month-1];
  }

  String _toPersianNumber(int number){
    const persian = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    return number.toString().split('').map((ch){
      if(RegExp(r'\d').hasMatch(ch)) return persian[int.parse(ch)];
      return ch;
    }).join();
  }

  int _firstWeekdayIndexOfMonth(Jalali month){
    final first = Jalali(month.year, month.month, 1);
    return first.weekDay-1;
  }

  void _prevMonth(){ setState(()=>_focusedMonth=_focusedMonth.addMonths(-1)); }
  void _nextMonth(){ setState(()=>_focusedMonth=_focusedMonth.addMonths(1)); }

  String _formatTime(TimeOfDay time){
    final h = _toPersianNumber(time.hour);
    final m = _toPersianNumber(time.minute);
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context){
    final firstDay = Jalali(_focusedMonth.year,_focusedMonth.month,1);
    final daysInMonth = firstDay.monthLength;
    final firstWeekDay = _firstWeekdayIndexOfMonth(_focusedMonth);

    final List<Widget> dayCells = [];
    for(int i=0;i<firstWeekDay;i++) dayCells.add(Container());

    final today = Jalali.now();

    for(int day=1; day<=daysInMonth; day++){
      final date = Jalali(_focusedMonth.year,_focusedMonth.month,day);

      final isSelected = _selectedDate!=null &&
          _selectedDate!.year==date.year &&
          _selectedDate!.month==date.month &&
          _selectedDate!.day==date.day;

      final isToday = today.year==date.year &&
          today.month==date.month &&
          today.day==date.day;

      final List<Event> events = widget.events.keys
          .where((d)=>d.year==date.year && d.month==date.month && d.day==date.day)
          .expand((d)=>widget.events[d]!).toList();

      // برای نمایش دایره‌های پایین روز
      List<Widget> eventIndicators = [];
      int maxDots = 4;
      if(events.length<=maxDots){
        eventIndicators = events.map((e)=>_buildDot()).toList();
      } else {
        int extra = events.length - maxDots +1;
        // سه دایره اول
        eventIndicators = events.take(maxDots-1).map((e)=>_buildDot()).toList();
        // آخرین دایره با +n
        eventIndicators.add(_buildDotWithPlus(extra));
      }

      dayCells.add(
        GestureDetector(
          onTap: (){
            setState(()=>_selectedDate=date);
            if(widget.onDateSelected!=null) widget.onDateSelected!(date);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : isToday
                  ? Colors.blue.shade100
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _toPersianNumber(day),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height:4),
                if(events.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: eventIndicators,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final remainder = dayCells.length%7;
    if(remainder!=0){
      for(int i=0;i<7-remainder;i++) dayCells.add(Container());
    }

    // ایونت‌های روز انتخاب‌شده
    List<Event> selectedEvents=[];
    if(_selectedDate!=null){
      widget.events.forEach((key,value){
        if(key.year==_selectedDate!.year &&
            key.month==_selectedDate!.month &&
            key.day==_selectedDate!.day){
          selectedEvents=value;
        }
      });
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal:8, vertical:6),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed:_prevMonth),
              Expanded(child: Center(child: Text("${_getPersianMonthName(_focusedMonth.month)} ${_toPersianNumber(_focusedMonth.year)}", style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)))),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed:_nextMonth),
            ],
          ),
        ),
        // Weekdays
        Row(
          children: _weekDays.map((d)=>Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600))))).toList(),
        ),
        const SizedBox(height:6),
        // Days
        Flexible(
          flex:0,
          child: GridView.count(
            shrinkWrap:true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount:7,
            childAspectRatio:1,
            padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
            children: dayCells,
          ),
        ),
        // Event texts
        if(selectedEvents.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ایونت‌ها:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...selectedEvents.map((e)=>Padding(
                  padding: const EdgeInsets.symmetric(vertical:2),
                  child: Text("• ${e.title} (${_formatTime(e.startTime)} - ${_formatTime(e.endTime)})"),
                ))
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDot(){
    return Container(
      width:6,
      height:6,
      margin: const EdgeInsets.symmetric(horizontal:1),
      decoration: const BoxDecoration(color:Colors.redAccent, shape: BoxShape.circle),
    );
  }

  Widget _buildDotWithPlus(int extra){
    return Container(
      width:14,
      height:14,
      margin: const EdgeInsets.symmetric(horizontal:1),
      decoration: BoxDecoration(
        color:Colors.redAccent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text("+$extra", style: const TextStyle(fontSize:8, color:Colors.white, fontWeight:FontWeight.bold)),
    );
  }
}
