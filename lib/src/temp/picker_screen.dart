import 'package:flutter/material.dart';
import 'package:ui_kit/enums/calendar_type.dart';
import 'package:ui_kit/widgets/ui_app_bar.dart';
import 'package:ui_kit/widgets/ui_date_picker.dart';
import 'package:ui_kit/widgets/ui_date_picker_2.dart';
import 'package:ui_kit/widgets/ui_date_time.dart';
import 'package:ui_kit/widgets/ui_date_time_picker.dart';
import 'package:ui_kit/widgets/ui_divider.dart';
import 'package:ui_kit/widgets/ui_range_picker.dart';
import 'package:ui_kit/widgets/ui_spinner.dart';
import 'package:ui_kit/widgets/ui_text.dart';
import 'package:ui_kit/widgets/ui_time_picker.dart';
import 'package:ui_kit/widgets/ui_time_picker_2.dart';
import 'package:ui_kit/widgets/calendar/ui_date_picker_widget.dart';
import 'package:ui_kit/widgets/calendar/ui_time_picker_widget.dart';
import 'package:ui_kit/widgets/calendar/ja_date_time.dart';
import 'package:ui_kit/widgets/calendar/jalali_delegate.dart';
import 'package:general_datetime/src/jalali_date_time.dart';

class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiAppBar(title: 'Pickers', elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          spacing: 16,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Date Picker"),
            ),
            UiDatePicker(
              hint: 'محل درج پاسخ',
              helpMessage: 'question.help',
              value: UiDate(year: 1367, month: 2, day: 10),
              displayFormat: 'yyyy/MM/dd',
              startDate: UiDate(year: 1360, month: 2, day: 10),
              endDate: UiDate(year: 1390, month: 2, day: 10),
              required: true,
              controller: TextEditingController(),
              widget: Container(),
              icon: 'assets/icons/ic_coffee.svg',
              persianCalendar: false,
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Date Picker 2"),
            ),
            UiDatePicker2(
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(3000),
              title: "Select Date",
              hint: "Select Date",
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      UiDatePickerWidget(
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(3000),
                      ).dialog(context);
                    },
                    child: Text("Dialog Date Picker"),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      UiDatePickerWidget(
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(3000),
                      ).modalBottomSheet(context);
                    },
                    child: Text(
                      "Modal Bottom Sheet Date Picker",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Time Picker"),
            ),
            UiTimePicker(
              icon: 'assets/icons/ic_coffee.svg',
              hint: 'محل درج پاسخ',
              helpMessage: 'question.help',
              value: UiTime(hour: 4, minute: 5),
              controller: TextEditingController(),
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Time Picker 2"),
            ),
            UiTimePicker2(
              initialTime: TimeOfDay.now(),
              onSubmit: (value) => print(value.toString()),
              title: "Select Time",
              hint: "Select Time",
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      UiTimePickerWidget(
                        initialTime: TimeOfDay.now(),
                      ).dialog(context);
                    },
                    child: Text("Dialog Time Picker"),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      var res = await UiTimePickerWidget(
                        initialTime: TimeOfDay.now(),
                        onTimeChanged: (time) => print(time.toString()),
                      ).modalBottomSheet(context);
                      print(res.toString());
                    },
                    child: Text(
                      "Modal Bottom Sheet Time Picker",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Range Picker"),
            ),
            UiRangePicker(
              icon: 'assets/icons/ic_coffee.svg',
              hint: 'تست',
              helpMessage: 'question.help',
              controller: TextEditingController(),
              startDate: UiDate(year: 1000, month: 1, day: 1),
              endDate: UiDate(year: 3000, month: 1, day: 1),
              displayFormat: '',
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "DateTime Picker"),
            ),
            UiDateTimePicker(
              hint: 'تست',
              helpMessage: 'question.help',
              initialDateTime: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(3000),
              onSubmit: (value) {
                print(value.toString());
              },
            ),
            UiDivider(axis: Axis.horizontal),
            Align(
              alignment: Alignment.centerLeft,
              child: UiText.h1(text: "Spinner"),
            ),
            UiSpinner(
              title: 'کد کشور',
              list: [
                UiSpinnerItem(
                  title: 'آرژانتین',
                  subtitle: '+93',
                  icon: Image.asset('assets/images/argentina.png'),
                ),
                UiSpinnerItem(
                  title: 'آلمان',
                  subtitle: '+11',
                  icon: Image.asset('assets/images/germany.png'),
                ),
                UiSpinnerItem(
                  title: 'ایتالیا',
                  subtitle: '+65',
                  icon: Image.asset('assets/images/italy.png'),
                ),
                UiSpinnerItem(
                  title: 'فرانسه',
                  subtitle: '+12',
                  icon: Image.asset('assets/images/france.png'),
                ),
                UiSpinnerItem(
                  title: 'انگلیس',
                  subtitle: '+87',
                  icon: Image.asset('assets/images/united_kingdom.png'),
                ),
                UiSpinnerItem(
                  title: 'پرتغال',
                  subtitle: '+56',
                  icon: Image.asset('assets/images/portugal.png'),
                ),
                UiSpinnerItem(
                  title: 'چین',
                  subtitle: '+36',
                  icon: Image.asset('assets/images/china.png'),
                ),
                UiSpinnerItem(
                  title: 'مکزیک',
                  subtitle: '+47',
                  icon: Image.asset('assets/images/mexico.png'),
                ),
              ],
              icon: 'assets/icons/ic_coffee.svg',
            ),

            // CalendarDatePicker(initialDate: JaDateTime.now(), firstDate: JaDateTime.now().subtract(Duration(days: 3)), lastDate: JaDateTime(2000), onDateChanged: (value) {
            //   print("value");
            //   print(value.toString());
            //   print(JaDateTime(1405, 2, 30).day);
            //   print("JalaliDateTime(1405, 2, 30).toString()");
            //   print(JalaliDateTime(1405, 2, 30).toString());
            //   print(JalaliDateTime(1405, 2, 30).monthLength);
            //   print(DateTime(1405, 2, 30).toString());
            // }, calendarDelegate: JalaliDelegate(),),
          ],
        ),
      ),
    );
  }
}
