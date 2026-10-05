# General DateTime picker example

Displays Gregorian, Persian, and Umm al-Qura Material date pickers on one
screen. Each calendar picker has matching date values, a calendar delegate,
and its own localization scope. Startup also demonstrates converting a native
Gregorian instant to Persian and Hijri dates.

From this directory, resolve the neighboring unpublished packages and run:

```powershell
Copy-Item pubspec_overrides.yaml.example pubspec_overrides.yaml
flutter pub get
flutter run
```

Requires Dart 3.4 or newer and Flutter 3.32 or newer. See the
[package README](../README.md) for supported ranges, safe field operations,
JSON storage, and testing. The separate
[calendar demo](../apps/calendar_demo/README.md) adds event views and scheduling.
