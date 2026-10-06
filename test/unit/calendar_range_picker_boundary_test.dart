import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:general_datetime/default_localizations.dart';
import 'package:general_datetime/delegates.dart';
import 'package:general_datetime/general_datetime.dart';

import '../support/calendar_test_case.dart';

void main() {
  testWidgets(
      'range builder repairs an omitted delegate and preserves wrappers',
      (tester) async {
    final delegate = const HijriCalendarDelegate().rangePickerDelegate;
    final first = HijriDateTime(1446, 1, 1);
    final last = HijriDateTime(1446, 1, 30);
    final builder = calendarDateRangePickerBuilder(delegate,
        builder: (context, child) => Padding(
              key: const ValueKey('application builder'),
              padding: const EdgeInsets.all(8),
              child: child,
            ));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [
        DefaultHijriCalendarMaterialLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        // Simulate Flutter 3.32 constructing the dialog with its default
        // Gregorian delegate, then applying locale/direction wrappers.
        return builder(
          context,
          Localizations.override(
            context: context,
            locale: const Locale('en', 'US'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _DialogWithoutDelegate(
                firstDate: first,
                lastDate: last,
                currentDate: first,
                initialDateRange: DateTimeRange(start: first, end: last),
                initialEntryMode: DatePickerEntryMode.input,
                helpText: 'Custom range help',
                fieldStartLabelText: 'Custom start',
                fieldEndLabelText: 'Custom end',
              ),
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dialog = find.byType(DateRangePickerDialog);
    expect(tester.widget<DateRangePickerDialog>(dialog).calendarDelegate,
        same(delegate));
    expect(Localizations.localeOf(tester.element(dialog)),
        const Locale('en', 'US'));
    expect(Directionality.of(tester.element(dialog)), TextDirection.rtl);
    expect(find.byKey(const ValueKey('application builder')), findsOneWidget);
    expect(find.text('Custom range help'), findsOneWidget);
    expect(find.text('Custom start'), findsOneWidget);
    expect(find.text('Custom end'), findsOneWidget);
  });

  for (final calendar in calendarTestCases) {
    test('${calendar.name} range probes preserve chronology and input guards',
        () {
      final delegate = _rangeDelegate(calendar);
      final minimum = calendar.make(calendar.minimumYear, 1, 1, isUtc: false);
      final maximum = calendar.make(calendar.maximumYear, 12, calendar.lastDay,
          isUtc: false);
      for (var day = -5; day <= 0; day++) {
        final probe = delegate.getDay(calendar.minimumYear, 1, day);
        expect(probe.runtimeType, DateTime);
        expect(probe.isBefore(minimum), isTrue);
        expect(() => delegate.dateOnly(probe), throwsArgumentError);
        expect(() => calendar.delegate.getDay(calendar.minimumYear, 1, day),
            throwsRangeError);
      }
      for (final days in [1, 7]) {
        expect(
            delegate.addDaysToDate(minimum, -days).isBefore(minimum), isTrue);
        expect(delegate.addDaysToDate(maximum, days).isAfter(maximum), isTrue);
      }
      expect(() => delegate.addDaysToDate(minimum, -8), throwsRangeError);
      expect(
          () => delegate.getDay(calendar.minimumYear, 1, -6), throwsRangeError);
      expect(() => delegate.getMonth(calendar.minimumYear - 1, 12),
          throwsRangeError);
      expect(
          () => delegate.addMonthsToMonthDate(minimum, -1), throwsRangeError);
      expect(() => calendar.make(calendar.minimumYear, 1, 0), throwsRangeError);
      expect(
          () => calendar.make(calendar.maximumYear, 12, calendar.lastDay + 1),
          throwsRangeError);
      final native = CalendarDateUtils.toGregorian(minimum);
      expect(() => delegate.addDaysToDate(native, -1), throwsArgumentError);
      expect(() => delegate.formatCompactDate(native, calendar.localizations),
          throwsArgumentError);
      expect(delegate.getDay(calendar.minimumYear, 1, 1).runtimeType,
          calendar.type);
    });
    for (final atMinimum in [true, false]) {
      for (var weekStart = 0; weekStart < 7; weekStart++) {
        testWidgets(
            '${calendar.name} range ${atMinimum ? 'minimum' : 'maximum'} '
            'weekStart=$weekStart', (tester) async {
          final year = atMinimum ? calendar.minimumYear : calendar.maximumYear;
          final month = atMinimum ? 1 : 12;
          final length = calendar.delegate.getDaysInMonth(year, month);
          final first = calendar.make(year, month, 1, isUtc: false);
          final last = calendar.make(year, month, length, isUtc: false);
          final endpoint = atMinimum ? first : last;
          final start = atMinimum
              ? first
              : calendar.make(year, month, length - 1, isUtc: false);
          final end =
              atMinimum ? calendar.make(year, month, 2, isUtc: false) : last;
          DateTimeRange<DateTime>? initial =
              DateTimeRange(start: start, end: end);
          DateTimeRange<DateTime>? selected;
          final localizations = calendar.name == 'Persian'
              ? _PersianWeekStart(weekStart)
              : _HijriWeekStart(weekStart);
          final rangeDelegate = _rangeDelegate(calendar);
          await tester.pumpWidget(MaterialApp(
            localizationsDelegates: [_ValueLocalizations(localizations)],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await showDateRangePicker(
                      context: context,
                      firstDate: first,
                      lastDate: last,
                      currentDate: endpoint,
                      initialDateRange: initial,
                      calendarDelegate: rangeDelegate,
                      builder: calendarDateRangePickerBuilder(rangeDelegate),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ));
          // Rendering an existing range exercises the highlight edges.
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(localizations.saveButtonLabel));
          await tester.pumpAndSettle();
          expect(selected, initial);

          // Selecting a new range must return real supported calendar dates.
          initial = null;
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final dayInk = tester.widget<InkResponse>(find
              .ancestor(
                  of: find.text('${endpoint.day}'),
                  matching: find.byType(InkResponse))
              .first);
          dayInk.focusNode!.requestFocus();
          await tester.pumpAndSettle();
          for (final key in atMinimum
              ? [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp]
              : [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowDown]) {
            await tester.sendKeyEvent(key);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(dayInk.focusNode!.hasFocus, isTrue);
          }
          await tester.tap(find.text('${start.day}'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('${end.day}'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(localizations.saveButtonLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(selected!.start.runtimeType, calendar.type);
          expect(selected!.end.runtimeType, calendar.type);
          expect(selected!.start, start);
          expect(selected!.end, end);
        });
      }

      testWidgets(
          '${calendar.name} range input rejects dates beyond '
          '${atMinimum ? 'minimum' : 'maximum'}', (tester) async {
        final year = atMinimum ? calendar.minimumYear : calendar.maximumYear;
        final month = atMinimum ? 1 : 12;
        final first = calendar.make(year, month, 1, isUtc: false);
        final last = calendar.make(
            year, month, calendar.delegate.getDaysInMonth(year, month),
            isUtc: false);
        final localizations = calendar.localizations;
        final rangeDelegate = _rangeDelegate(calendar);
        DateTimeRange<DateTime>? selected;
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: [calendar.localizationDelegate],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showDateRangePicker(
                    context: context,
                    firstDate: first,
                    lastDate: last,
                    currentDate: atMinimum ? first : last,
                    initialDateRange: DateTimeRange(start: first, end: last),
                    initialEntryMode: DatePickerEntryMode.input,
                    calendarDelegate: rangeDelegate,
                    builder: calendarDateRangePickerBuilder(rangeDelegate),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final field = atMinimum
            ? find.byType(TextField).first
            : find.byType(TextField).last;
        await tester.enterText(
            field, atMinimum ? '01/01/${year - 1}' : '01/01/${year + 1}');
        await tester.tap(find.text(localizations.okButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(selected, isNull);
        expect(find.text(localizations.invalidDateFormatLabel), findsOneWidget);
        await tester.enterText(
            field, localizations.formatCompactDate(atMinimum ? first : last));
        await tester.tap(find.text(localizations.okButtonLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(selected, DateTimeRange(start: first, end: last));
      });
    }
  }
}

// Flutter 3.32 exposes currentDate directly; newer SDKs normalize it through
// the dialog's delegate. Preserve the older behavior in this regression fixture.
class _DialogWithoutDelegate extends DateRangePickerDialog {
  const _DialogWithoutDelegate({
    required super.firstDate,
    required super.lastDate,
    required DateTime currentDate,
    super.initialDateRange,
    super.initialEntryMode,
    super.helpText,
    super.fieldStartLabelText,
    super.fieldEndLabelText,
  })  : _originalCurrentDate = currentDate,
        super(currentDate: currentDate);

  final DateTime _originalCurrentDate;

  @override
  DateTime get currentDate => _originalCurrentDate;
}

CalendarDelegate<DateTime> _rangeDelegate(CalendarTestCase calendar) =>
    switch (calendar.delegate) {
      PersianCalendarDelegate delegate => delegate.rangePickerDelegate,
      HijriCalendarDelegate delegate => delegate.rangePickerDelegate,
      _ => throw UnsupportedError('Unsupported test calendar'),
    };

class _PersianWeekStart extends DefaultPersianCalendarMaterialLocalizations {
  const _PersianWeekStart(this.firstDayOfWeekIndex);
  @override
  final int firstDayOfWeekIndex;
}

class _HijriWeekStart extends DefaultHijriCalendarMaterialLocalizations {
  const _HijriWeekStart(this.firstDayOfWeekIndex);
  @override
  final int firstDayOfWeekIndex;
}

class _ValueLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const _ValueLocalizations(this.value);
  final MaterialLocalizations value;
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';
  @override
  Future<MaterialLocalizations> load(Locale locale) => SynchronousFuture(value);
  @override
  bool shouldReload(_ValueLocalizations old) => old.value != value;
}
