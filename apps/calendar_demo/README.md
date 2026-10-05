# Calendar application demo

This separate application consumes the pure Dart chronology and formatter
packages, with `timezone` used directly in the demo. It provides month, week,
day and agenda views, Gregorian/Persian/Umm al-Qura selection, named-zone
event presentation,
secondary dates, asynchronous controller state, deterministic overlap columns,
all-day events and midnight splitting. Its sample event source is in memory.

From the two neighboring repositories, resolve local sources:

```sh
python tool/resolve_calendar_pair.py --chronology . --formatter ../general_date_format
cd apps/calendar_demo
flutter pub get
flutter run -d chrome
```

Named-zone conversion and explicit DST policies live in `lib/demo_time_zones.dart`.
The demo initializes the bundled `timezone` data at startup.
The alternative local `pubspec_overrides.yaml.example` resolves both cores
directly. On a device, run `flutter run -d <device-id>`.

For checks:

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter test integration_test/calendar_smoke_test.dart -d <device-id>
```

Month cells support arrows (left/right follow RTL), Page Up/Down and Home.
Event buttons open a keyboard-accessible dialog with previous/next-day move
actions. Long-press an event to drag it onto a month cell. Moving timed events
preserves the selected-zone clock and elapsed duration; missing/repeated times
reject by default and show a recoverable error. Application adapters can expose
additional policy choices. Rebuilds/language changes retain the controller.

Timelines use actual elapsed minutes within named-zone day bounds, so DST days
have 23 or 25 hours and repeated hour labels remain visible. Minimum visual
event targets may exceed a short event's duration; their occupancy reserves
separate columns to prevent collisions without changing its timestamps.
All-day events remain civil ranges and do not receive midnight timestamps.

`CalendarEventSource` owns fetching and `onReschedule` owns persistence.
Generation tokens discard old asynchronous results. Duplicate event IDs fail
explicitly. Loading/error/retry states, semantics and selected events are
independent of the locale. The demo offers English/Persian date presentation and
RTL; action text is an English sample application, not a full translation pack.

Widget tests cover controller ordering/recovery, DST/skipped days, midnight
splitting, real/visual overlap, all four views, selection/rescheduling and
keyboard/semantics/RTL/large-text narrow layouts. Mobile smoke workflows are
configured; Windows-local execution does not certify Android/iOS results.

Gregorian labels use the application's `intl.DateFormat`. The demo chooses
Flutter's Material localization delegates for intl locale initialization.
When embedding `CalendarScreen` independently, initialize the intl locale data
you choose before building it (the widget tests use bundled local data).
