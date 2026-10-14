# General DateTime picker example

Displays Gregorian, Persian, and Umm al-Qura Material date pickers on one
screen. Each calendar picker has matching date values, a calendar delegate,
and its own localization scope. Startup also demonstrates converting a native
Gregorian instant to Persian and Hijri dates.

This example uses the local `general_datetime` 4.0.0 wrapper, which requires
`general_datetime_core ^2.0.0`. Before the core release is published, create
an ignored `pubspec_overrides.yaml` in this directory:

```yaml
dependency_overrides:
  general_datetime_core:
    path: ../packages/general_datetime_core
```

Then run:

```powershell
flutter pub get
flutter run
```

Requires Dart 3.4 or newer and Flutter 3.32 or newer. See the
[package README](../README.md) for supported ranges, safe field operations,
JSON storage, and testing. The separate
[calendar demo](../apps/calendar_demo/README.md) adds event views and scheduling.
