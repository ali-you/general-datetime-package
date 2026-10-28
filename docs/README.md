# General DateTime documentation

Guides for the APIs implemented in this repository. Start with
[getting started](getting-started.md), then choose the guide that matches your
application.

| Guide | What it covers |
| --- | --- |
| [Getting started](getting-started.md) | Package choice, requirements, imports, and a first conversion |
| [Architecture](architecture.md) | Core/wrapper boundaries, source layout, and extension constraints |
| [Calendar operations](calendar-operations.md) | Bounds, validation, parsing, instants, civil arithmetic, and weeks |
| [Serialization](serialization.md) | Version-1 JSON schemas, timestamps, all-day dates, and decoder errors |
| [Flutter integration](flutter-integration.md) | Material pickers, localization scopes, range adapters, and calendar switching |
| [Migration](migration.md) | Aligned release versions, Hebrew enum/month compatibility and existing integration changes |
| [Release preparation](release-preparation.md) | Coordinated core/wrapper versions, publication order and outstanding verification |
| [Development and testing](development.md) | Local checks, fixtures, CI coverage, and release gates |
| [Persian calendar validation](persian-calendar-validation.md) | Published leap data, calculation bounds, source decisions, and verification history |
| [Umm al-Qura validation](hijri-calendar-validation.md) | Month-table provenance, independent checks, and verification history |
| [Hebrew calendar](hebrew-calendar.md) | Stable month slots, leap-month arithmetic, storage, English Material pickers, and verification |
| [Hebrew release validation](hebrew-release-validation-2026-10-28.md) | Exhaustive independent comparison of all supported Hebrew dates and current package checks |
| [Hebrew package validation](hebrew-package-validation-2026-10-12.md) | Full package suites, independent Hebrew comparison, browser and Android checks, and remaining release gates |
| [Persian/Hijri regression review](hebrew-existing-calendar-regression-2026-10-12.md) | Before/after checks for existing calendars, shared formatter state, enum compatibility and compiled size |
| [Calendar expansion review](calendar-expansion-review.md) | Proposed architecture for additional calendars; a design plan rather than available APIs |

The [root README](../README.md) contains a combined API overview. The
[core README](../packages/general_datetime_core/README.md) focuses on pure Dart.
The [picker example](../example/lib/main.dart) and
[calendar application demo](../apps/calendar_demo/README.md) provide working
integration references.

Package entry points, release history, and licensing remain beside the packages
and applications they describe:

- [Third-party notices](../THIRD_PARTY_NOTICES.md)
- [License](../LICENSE)
- [Changelog](../CHANGELOG.md)

The core retains its own [changelog](../packages/general_datetime_core/CHANGELOG.md),
[third-party notices](../packages/general_datetime_core/THIRD_PARTY_NOTICES.md),
and [license](../packages/general_datetime_core/LICENSE) for independent distribution.
The [picker example README](../example/README.md) and
[demo README](../apps/calendar_demo/README.md) retain component-specific run instructions.

These guides describe the prepared `general_datetime` **4.0.0** and core
**2.0.0** source releases, paired with formatter wrapper **3.0.0** and core
**2.0.0**. See [migration](migration.md) and [release preparation](release-preparation.md)
for compatible constraints. Preparation does not publish packages.
