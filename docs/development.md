# Development and testing

[Documentation index](README.md)

## Dependency resolution

The wrapper and calendar demo manifests use hosted core dependencies. CI uses
the `use-local-core` composite action to select this checkout's core for the
wrapper, picker example, and demo before resolving dependencies. This ensures
new core APIs are tested together with their Flutter integrations.
Running tests in
`packages/general_datetime_core` checks local core source; running wrapper tests
with its ordinary manifest checks the resolved hosted core.
The prepared release matrix uses chronology core 2.0.0, chronology wrapper
4.0.0, formatter core 2.0.0 and formatter wrapper 3.0.0. Consumer constraints
are aligned; use local overrides until those hosted versions are published.

When changing the core and wrapper together, a temporary root
`pubspec_overrides.yaml` can select local chronology source:

```yaml
dependency_overrides:
  general_datetime_core:
    path: packages/general_datetime_core
```

Run `flutter pub get` after adding or changing the override. For the separate
demo application, create `apps/calendar_demo/pubspec_overrides.yaml` with both
cores:

```yaml
dependency_overrides:
  general_datetime_core:
    path: ../../packages/general_datetime_core
  general_date_format_core:
    path: ../../../general_date_format/packages/general_date_format_core
```

Each package root has its own dependency resolution; a root override does not
automatically apply to independent demo commands.

Remove only overrides you created, preserve any existing developer overrides,
then resolve and test hosted dependencies before a release. Check
`.dart_tool/package_config.json` to confirm which core path a consumer selected.

## Local commands

Run from the repository root:

```console
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test example/lib packages apps/calendar_demo/lib apps/calendar_demo/test apps/calendar_demo/integration_test
```

Run from `packages/general_datetime_core`:

```console
dart pub get
dart analyze
dart test
dart compile exe example/cli.dart -o .dart_tool/calendar_cli
```

Run the compiled executable afterward (`.dart_tool/calendar_cli.exe` on Windows,
`.dart_tool/calendar_cli` on Unix; choose the corresponding output filename).

Run from `apps/calendar_demo`:

```console
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter test integration_test/calendar_smoke_test.dart -d <device-id>
```

Discover a device with `flutter devices`. For an interactive demo use
`flutter run -d chrome` from that application directory. The smaller picker
example lives in `example` and uses a path dependency on the wrapper.

## Focused regressions

| Change area | Relevant suites |
| --- | --- |
| Persian calculations/data | [`persian_date_time_test.dart`](../test/unit/persian_date_time_test.dart) |
| Umm al-Qura calculations/data | [`hijri_date_time_test.dart`](../test/unit/hijri_date_time_test.dart) |
| Hebrew calculation, month identities, arithmetic and pickers | [`hebrew_calendar_test.dart`](../packages/general_datetime_core/test/hebrew_calendar_test.dart), [`hebrew_calendar_delegate_test.dart`](../test/unit/hebrew_calendar_delegate_test.dart) |
| Normalization, precision, DST, interoperability | [`calendar_critical_test.dart`](../test/unit/calendar_critical_test.dart), [`constructor_overflow_test.dart`](../test/unit/constructor_overflow_test.dart), [`epoch_seconds_test.dart`](../test/unit/epoch_seconds_test.dart) |
| Field helpers | [`calendar_date_utils_test.dart`](../test/unit/calendar_date_utils_test.dart) |
| JSON contracts | [`calendar_serialization_test.dart`](../test/unit/calendar_serialization_test.dart) |
| Strict systems and civil arithmetic | [`calendar_system_test.dart`](../packages/general_datetime_core/test/calendar_system_test.dart), [`calendar_date_test.dart`](../packages/general_datetime_core/test/calendar_date_test.dart) |
| Delegate/runtime/localization behavior | [`calendar_delegate_type_guard_test.dart`](../test/unit/calendar_delegate_type_guard_test.dart), [`calendar_picker_critical_test.dart`](../test/unit/calendar_picker_critical_test.dart) |
| Range limits and builder compatibility | [`calendar_range_picker_boundary_test.dart`](../test/unit/calendar_range_picker_boundary_test.dart) |
| Core/wrapper type identity | [`core_package_identity_test.dart`](../test/unit/core_package_identity_test.dart) |
| Browser/platform smoke | [`platform_calendar_smoke_test.dart`](../test/platform_calendar_smoke_test.dart) |
| Demo controller, timezone policies, views | [`apps/calendar_demo/test/`](../apps/calendar_demo/test/) and [`integration_test/`](../apps/calendar_demo/integration_test/) |

For example:

```console
flutter test test/unit/calendar_serialization_test.dart
flutter test test/unit/calendar_range_picker_boundary_test.dart
flutter test --platform chrome test/platform_calendar_smoke_test.dart
```

Independent reference fixtures live in [`test/fixtures/`](../test/fixtures/).
Keep reference fixtures separate from production calculations: deriving an
expected result through the production algorithm cannot independently validate
that algorithm. Data changes require provenance, bounds, conversion anchors,
and exhaustive checks where feasible. See the
[Persian](persian-calendar-validation.md) and
[Umm al-Qura](hijri-calendar-validation.md) validation reports.

## Timezone testing

[`flutter.yml`](../.github/workflows/flutter.yml) configures Linux process
timezones UTC, Asia/Tehran, and America/New_York and passes
`CALENDAR_TEST_TZ` to the tests. The define describes the expected timezone; it
does not change the operating system's local timezone.

On Linux/macOS, run a focused case with matching environment and define:

```sh
TZ=Asia/Tehran flutter test --dart-define=CALENDAR_TEST_TZ=Asia/Tehran test/unit/calendar_critical_test.dart
```

Windows local behavior follows the OS timezone. Use CI for the process-timezone
matrix rather than assuming the Dart define switches zones. Named-zone demo
tests exercise the application's separate `timezone` rules and DST policies.

## CI and release evidence

The committed workflow configuration specifies:

| Workflow | Configured checks |
| --- | --- |
| [`flutter.yml`](../.github/workflows/flutter.yml) | Dart 3.4.0/current core checks and CLI; Flutter 3.32.0/current checks; three process timezones; demo analysis/tests |
| [`calendar_platforms.yml`](../.github/workflows/calendar_platforms.yml) | Browser JavaScript/Wasm smoke and demo checks/builds; Android emulator and iOS simulator integration smoke |

Workflow configuration is not evidence of a passing run. Record the commit,
resolved package versions, SDKs, platform/timezone, commands, and outcomes when
reporting validation. Historical local results in the root README and validation
reports apply to their recorded dates, not automatically to this checkout.

Before publishing, follow [release preparation](release-preparation.md),
check hosted dependency resolution without development overrides, run minimum
and current SDK checks, and review browser/device/timezone results. Preserve
source attribution and licenses when updating calendar data.
