import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/theme/ui_color.dart';

class UiTimePickerWidget extends StatelessWidget {
  const UiTimePickerWidget({
    super.key,
    required this.initialTime,
    this.use24hFormat = true,
    this.onTimeChanged,
  });

  final TimeOfDay initialTime;
  final bool use24hFormat;
  final Function(TimeOfDay time)? onTimeChanged;

  Future<TimeOfDay?> dialog(BuildContext context) async {
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    TimeOfDay? res = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        TimeOfDay? result = initialTime;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(localizations.timePickerDialHelpText),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16,
                  ),
                  child: UiTimePickerWidget(
                    initialTime: initialTime,
                    use24hFormat: use24hFormat,
                    onTimeChanged: (time) {
                      result = time;
                      onTimeChanged?.call(time);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
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

  Future<TimeOfDay?> modalBottomSheet(BuildContext context) async {
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    TimeOfDay? res = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        TimeOfDay? result = initialTime;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(localizations.timePickerDialHelpText),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: UiTimePickerWidget(
                  initialTime: initialTime,
                  use24hFormat: use24hFormat,
                  onTimeChanged: (time) {
                    result = time;
                    onTimeChanged?.call(time);
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: use24hFormat,
          initialDateTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            initialTime.hour,
            initialTime.minute,
          ),
          onDateTimeChanged:
              (value) => onTimeChanged?.call(TimeOfDay.fromDateTime(value)),
          showTimeSeparator: true,
        ),
      ),
    );
  }
}
