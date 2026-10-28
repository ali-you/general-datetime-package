# Calendar expansion review and implementation plan

Historical review, before Hebrew and Chinese implementation. Chinese chronology
is now implemented with ordinal months and separate leap identity; see
[Chinese calendar](chinese-calendar.md). Hebrew chronology is now
implemented in core 2.0.0 / wrapper 4.0.0; see [Hebrew calendar](hebrew-calendar.md)
and [migration](migration.md) for current APIs and release versions. The design
assessment below records the source state on 2026-10-06.

Reviewed: 2026-10-06. Scope: `lib/general_datetime.dart`, every Dart source file in `packages/general_datetime_core`, its tests, package metadata, example, README, changelog, and data provenance. Wrapper tests were inspected for integration and regression requirements. No calendar implementation was changed.

## Result

The existing package is a sound base for expansion, but the current public model supports calendars with twelve sequential months and midnight-based civil dates. Adding Hebrew, Chinese, and traditional Hindu calendars by copying the existing date-time classes would spread assumptions and duplicate conversion code.

Recommended path: retain the Flutter re-export, introduce calendar engines that convert civil fields to an integer day coordinate, enrich month identity, delegate period arithmetic to those engines, preserve existing date-time compatibility classes, then implement Hebrew, Chinese, and a precisely specified Hindu variant in that order.

This is a source and architecture review. Attempts to run `dart analyze` and `dart test` both failed inside the Dart CLI before project execution: `_Platform.resolvedExecutable` threw `type 'Null' is not a subtype of type 'String'`. Neither check is verified. This checkout also has no generated `.dart_tool/package_config.json` in the root or core package. Dependencies must be resolved once CLI execution works.

## 1. Existing architecture

| Component | Current responsibility | Assessment |
| --- | --- | --- |
| `lib/general_datetime.dart` | Re-exports the public core library | Keep this structure; no separate calendar implementation belongs here. |
| `lib/general_datetime_core.dart` in core | Exports civil dates, systems, serialization, utilities, interface, and concrete date-times | Add new public APIs here; wrapper consumers automatically see the resolved core version's exports. |
| `src/general_date_time_interface.dart` | Calendar-specific getters and instant operations | Useful compatibility contract, but lacks calendar ID and month identity. Static `now<T>()` explicitly selects only Persian and Hijri. |
| `src/calendar_system.dart` | Strict construction, bounds, conversion, data metadata, built-in registry | A facade over concrete date-time classes, rather than the underlying conversion engine. One private implementation switches on every calendar ID. |
| `src/calendar_date.dart` | Strict civil date, arithmetic, ranges, week rules | Best foundation for new calendars. Days and comparisons generalize; months, years, fields, and year starts need changes. |
| `src/calendar_serialization.dart` | Calendar ID enum, strict instant and civil JSON schemas | Good separation between instants and civil dates; ID discovery and validation are hard-coded and repeated. |
| `src/calendar_date_utils.dart` | Safe field replacement, midnight construction, native instant conversion | Native conversion generalizes. Field replacement explicitly dispatches on Persian/Hijri runtime types. |
| `src/calendars/persian/` | Date-time class, leap calculations, published source data | Preserve finite bounds and distinction between published dates and calculated extension. Conversion is mostly implemented inside the date-time class. |
| `src/calendars/hijri/` | Date-time class, Umm al-Qura month lengths and data | Useful template for a bounded data-backed engine, but its bit encoding assumes exactly twelve months. |
| `src/calendars/gregorian/gregorian_helper.dart` | Separate Gregorian/JDN helpers | No active references were found in core or wrapper library code. Do not build the new abstraction around this unused helper without independent validation. |
| `src/shared/` | Twelve-month overflow normalization, clock normalization, parser regex | Clock arithmetic can be reused. Month normalization and parsing are specific to the existing representation. |
| `src/persian_date_time.dart`, `src/hijri_date_time.dart` | Forwarding exports | Retain for compatibility. |

Current conversion dependency:

```text
CalendarDate -> CalendarSystems -> concrete DateTime subclass
                                  -> calculations / data
```

Recommended dependency:

```text
CalendarDate ---------------------> calendar engine -> calculations / data
Calendar date-time adapter -------> calendar engine
Serialization --------------------> calendar registry / field validation
Flutter wrapper ------------------> public core exports
```

An engine must not construct a calendar date-time just to calculate which civil day a date represents. This also avoids recursion when an adapter begins delegating to the engine.

## 2. Changes required before adding calendars

### 2.1 Rich month fields

The current `CalendarFields` record and `CalendarDate` contain only integer year/month/day. An integer could encode all months if a special convention were imposed, but the package currently defines no such convention. Simply accepting month 13 does not solve repeated Chinese month numbers or stable month identity across years.

Use three explicitly distinct concepts:

- `year`: one documented extended year coordinate for each implementation.
- `month`: the one-based position in that year's ordered month list, preserving current semantics for Gregorian, Persian, and Umm al-Qura.
- `monthCode`: stable calendar-specific identity, including an intercalary marker where applicable. Resolve codes through the engine; do not infer them from ordinal position.

Expose `isLeapMonth` as derived metadata where supported. A single leap boolean is not a complete model for every traditional Hindu month/day rule.

Prefer immutable value classes over adding fields to the public record typedef. Changing a record's shape breaks callers that construct, compare, or destructure it. Introduce the richer fields in a planned major release, or add a separately named API during a transition.

Construction should accept either an ordinal month or a month code. If both are supplied, validate that they identify the same month; never silently prefer one. Equality, hashing, conversion, copies, debug output, and JSON must all preserve the resolved identity.

### 2.2 Variable month structure and period arithmetic

Current fixed assumptions:

- `CalendarDate.addMonths`: calculates `year * 12 + month - 1`.
- `CalendarDate.addYears`: calls `addMonths(years * 12)`.
- `CalendarSystem.daysInYear`: sums twelve months.
- `normalizeCalendarMonth`: divides and reduces modulo twelve.
- Concrete class constants and data masks also assume twelve months; these are correct for those specific calendars and can remain there.

Each engine must provide an ordered month list per year and a way to advance through actual months. For bounded tables, cumulative month counts plus binary search provide efficient positive and negative offsets. Arithmetic implementations may use validated cycle formulas. Reject extreme offsets before loops or integer conversion; preserve the current BigInt protection where necessary.

Define separate rules:

- Add days: advance the civil-day coordinate.
- Add months: advance actual months, including an inserted month.
- Add years: advance the year coordinate and preserve month identity when it exists.
- Day overflow: keep the existing clamp/reject/overflow policy.
- Missing month after adding years: define a separate policy, initially reject or map to the corresponding regular month under documented calendar rules.

Do not let the existing day-overflow enum implicitly choose what happens to a missing leap month. Recurrence handling must retain original month/day intent because clamping loses information.

### 2.3 Conversion and bounds

Use `dayIndex` with 1970-01-01 = 0 as the engine's canonical civil-day coordinate. This aligns with the existing `CalendarDate.dayIndex` convention and avoids ambiguous fractional Julian dates. Keep Gregorian UTC midnight conversion as a compatibility bridge.

Expose inclusive minimum and maximum day indices, strict field validation, year start, month start, month lengths, and date-to/from-index conversion. Partial first/last supported years must be handled explicitly; the native Gregorian bounds already include partial years.

Existing behavior worth preserving:

- Instants are copied by epoch microseconds, never by custom calendar fields.
- Civil dates carry no event instant or timezone.
- Converting an instant to fields selects UTC or host-local wall fields explicitly.
- Duration arithmetic means elapsed time; civil day arithmetic has a separate API.
- Unsupported ranges fail explicitly.
- Strict construction rejects local DST normalization; this does not itself detect or resolve ambiguous DST folds.

The engine's reference meridian/time policy for astronomical calculations must be independent of the user's display timezone. Document both. Keep named timezone lookup in a separate layer.

### 2.4 Registration, identity, and validation

Move `CalendarId` to its own file, retaining its public export and existing wire strings. Currently chronology imports serialization merely to obtain an ID, and serialization independently repeats chronology validation.

Create one immutable built-in registry mapping IDs to individual engines. A closed registry is sufficient for these additions; a mutable global plugin registry is not required. If external calendar plugins become a separate product requirement, design an explicitly supplied registry and identifier type then.

Centralize ID detection for compatibility date-time objects and delegate field validation to the engine. Update:

- `CalendarSystems.forId` and named getters.
- `CalendarId._of` or its replacement.
- `CalendarDateUtils.copyWith`.
- `GeneralDateTimeInterface.now<T>()`.
- Public exports, documentation, and examples.

Adding enum values can break exhaustive switches in downstream Dart code. Treat release compatibility explicitly even if existing calendar behavior is preserved.

### 2.5 Date-time compatibility

The existing subclasses preserve a true native instant via `super.fromMicrosecondsSinceEpoch`, while overriding exposed civil fields. Retain their public constructors and instant equality/hash behavior.

Their implementations duplicate parsing, clock decomposition, epoch construction, comparison, copy operations, formatting, and range handling. Extract small internal helpers after independent engine conversion exists; avoid making a generic base class depend on the existing subclasses.

For new calendars, implement civil dates first. If DateTime-compatible classes are needed for picker integration, add explicit adapters backed by the engines. A month ordinal of 13 and custom year fields remain unsafe for Gregorian utilities. Keep the existing calendar-safe helpers and require native conversion at external integration boundaries.

Calendar-aware ISO-like strings are already distinct from Gregorian timestamps. New text formats need to preserve leap-month identity; the shared numeric regex cannot represent that identity on its own. Keep native UTC timestamps as the canonical instant storage format.

### 2.6 Storage and metadata

Version 1 rejects unknown fields, versions, and calendar identifiers. Adding `monthCode` or a leap marker to a version-1 record would violate this contract.

Recommended migration:

- Continue decoding old version-1 records unchanged.
- Preserve version-1 writing for the three existing calendars where possible.
- Add version 2 for richer civil-date records; store calendar, extended year, month code, and day. Derive the ordinal from the engine.
- Define an explicit allowed identifier set per schema version. Existing readers cannot consume new calendar identifiers automatically.
- Preserve instant storage as native Gregorian UTC, with optional presentation metadata. A new calendar does not require changing how an instant is represented.

Keep data revision and calculation policy available. For data-backed/astronomical mappings, offer optional provenance on persisted records and specify how revision mismatches are handled. A revision is provenance, not a different date identity; do not silently alter equality semantics to include it.

Illustrative new civil record, not a finalized wire standard:

```json
{
  "version": 2,
  "kind": "calendar-date",
  "calendar": "chinese",
  "year": 4660,
  "monthCode": "M02L",
  "day": 1
}
```

The Chinese year epoch and month-code conventions must be chosen and documented before this example becomes a supported record.

### 2.7 Ranges and weeks

`CalendarDateRange` can retain its half-open day-index semantics. Preserve the existing explicit inclusive count helper.

`CalendarWeekRules.weekOfYear` constructs month 1/day 1 and derives the next start from year length. Replace this with engine-provided year-start coordinates. A partial supported year may not contain its first date, and a numbering scheme need not make month 1 the civil new year. Specify boundary behavior when the neighboring week-year is unsupported. A generic week numbering rule is not automatically a traditional calendar convention.

## 3. Proposed engine contract

Conceptual API; names may be adjusted during implementation. This is a civil chronology contract, separate from instant adapters.

```dart
abstract interface class CalendarEngine {
  CalendarId get id;
  CalendarMetadata get metadata;
  int get minimumDayIndex;
  int get maximumDayIndex;

  List<CalendarMonth> monthsOfYear(int year);
  int yearStartDayIndex(int year);
  int daysInYear(int year);
  int daysInMonth(int year, CalendarMonthCode monthCode);

  bool isValidDate(CalendarDateFields fields);
  int toDayIndex(CalendarDateFields fields);
  CalendarDateFields fromDayIndex(int dayIndex);

  CalendarDateFields addMonths(
    CalendarDateFields fields,
    int count, {
    required CalendarOverflow dayOverflow,
  });

  CalendarDateFields addYears(
    CalendarDateFields fields,
    int count, {
    required CalendarOverflow dayOverflow,
    required MissingMonthPolicy missingMonth,
  });
}
```

`CalendarMonth` describes identity, ordinal, and length within a year. Shared period algorithms can operate on these descriptors; individual engines override only where their rules require it. `CalendarDate` remains the public value object and forwards chronology operations to its engine. Existing `CalendarSystem.construct` and `fromInstant` can remain compatibility facade operations during migration.

## 4. Proposed source organization

Paths below are relative to `packages/general_datetime_core/lib/src` and describe a target structure, not files already implemented.

```text
calendar_id.dart
calendar_fields.dart
calendar_month.dart
calendar_metadata.dart
calendar_engine.dart
calendar_registry.dart
calendar_system.dart              # compatibility facade
calendar_date.dart
calendar_date_range.dart          # optional separation for maintainability
calendar_week_rules.dart          # optional separation
calendar_serialization.dart
calendar_date_utils.dart
general_date_time_interface.dart

shared/
  civil_day_coordinate.dart
  calendar_period_arithmetic.dart
  calendar_field_normalization.dart
  calendar_datetime_helpers.dart
  constants.dart

calendars/
  gregorian/gregorian_calendar_engine.dart
  persian/persian_calendar_engine.dart
  persian/persian_date_time.dart
  persian/persian_calendar_calculation.dart
  persian/iranian_calendar_data.dart
  hijri/umm_al_qura_calendar_engine.dart
  hijri/hijri_date_time.dart
  hijri/hijri_calendar_calculation.dart
  hijri/umm_al_qura_data.dart
  hebrew/hebrew_calendar_engine.dart
  hebrew/hebrew_calendar_calculation.dart
  chinese/chinese_calendar_engine.dart
  chinese/chinese_calendar_data.dart
```

Add a Hindu directory only after its variant is selected. Extract files when they clarify ownership; the folder split alone does not provide extensibility.

## 5. Calendar-specific implementation decisions

### Hebrew: first implementation

Implement the fixed Hebrew calendar with arithmetic year starts, postponement rules, leap-month insertion, and year-dependent month lengths. Choose a civil year starting at Tishri. Use stable month codes and document any mapping to ICU's numeric month scheme; ICU numbers include an absent month slot in common years, unlike a contiguous ordinal scheme.

Define supported years, treatment of year zero, missing Adar-month policy for year addition, and conversion boundaries. Use midnight civil mapping for consistency with this package. Sunset-based observance requires location and a separate API; it should not silently replace the civil date semantics.

Reference: [ICU HebrewCalendar](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/HebrewCalendar.html), which documents intercalation, postponements, month variability, and its midnight convention.

### Chinese: second implementation

Choose the Chinese calendar variant, extended-year epoch, and reference time policy before implementation. A 60-year cycle label is display metadata and cannot uniquely identify a stored year.

Start with a bounded table recording each year's chronological months, stable identities, month lengths, and a Gregorian anchor. Store or derive prefix day/month indices. Do not reuse the twelve-bit Umm al-Qura year mask without extending it to record inserted-month position and identity.

Validate against published civil conversion tables and a pinned independent implementation. Record source revisions and hashes; do not extrapolate beyond the table or claim every astronomical calculation is an official civil date.

References: [ICU ChineseCalendar](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/ChineseCalendar.html), [Hong Kong Observatory calendar information](https://www.hko.gov.hk/en/gts/time/calendarinfo.htm).

### Hindu: select the target before implementation

Do not create one undifferentiated `HinduDateTime` and silently choose a tradition. Specify solar versus lunar, Amanta versus Purnimanta where relevant, era/year-start rules, calculation method, and location/day-boundary policy.

For a traditional lunar calendar, tithi is not automatically a one-to-one sequential civil day. A civil day can omit or repeat a tithi label under the selected observation rule. Design a separate Panchanga result for astronomical labels/events if required; an integer `day` plus `daysInMonth` is not enough to encode every such result reversibly.

If the intended target is Indian national Saka, implement it as a separately named civil calendar. It does not substitute for traditional Hindu lunar coverage.

References: [India Meteorological Department Panchanga explanation](https://packolkata.imd.gov.in/panchang/en/explanation), [ICU IndianCalendar](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4j/com/ibm/icu/util/IndianCalendar.html), [Unicode intercalary-month design discussion](https://cldr.unicode.org/development/development-process/design-proposals/chinese-and-other-calendar-support-intercalary-months-year-cycles).

## 6. Compatibility and package integration

The root wrapper currently depends on hosted `general_datetime_core: ^1.0.0`; it does not point to this local directory. Editing the local core alone will not make wrapper tests consume those edits. Use a local development dependency override, then restore the intended release dependency. A core 2.x API release requires changing the wrapper constraint because `^1.0.0` excludes 2.x.

The core README mentions wrapper 4.0.0, while the root `pubspec.yaml` currently says 3.0.0. Reconcile repository release metadata before publishing; this review does not verify external publication state.

Keep the core pure Dart. Keep formatter data and Flutter localizations outside it. New formatter selection/parsing must use month identity rather than a fixed array indexed only by numeric month. Material delegates must count actual months, preserve leap identity through navigation, and handle bounds. Audit picker assumptions with integration tests before promising support for all calendars.

Update data attribution and reproducible generation scripts for new source tables. Preserve existing notices and source hashes.

## 7. Required tests

The core currently has three test files covering representative conversions, strict construction, civil arithmetic, records, ranges, week rules, identity, precision, and bounds. Larger fixture/overflow/serialization regression coverage lives in wrapper tests. Move or share chronology-only coverage into core so a core release can be validated without Flutter.

Change generic tests that reject month 13 or randomly choose months 1 through 12: those are correct for existing specific calendars, not universal engine invariants.

Required acceptance coverage:

1. Existing Persian and Umm al-Qura fixtures and constructor overflow behavior remain unchanged.
2. Independent expected dates, not only same-engine round trips.
3. Regular/leap month identity, every transition through inserted months, and common/leap year boundaries.
4. `toDayIndex`/`fromDayIndex` round trips across supported data; exhaustive coverage for practical bounded tables.
5. Month advancement in both directions, large offsets, year addition with missing-month policies, and day overflow policies.
6. Month ordinal/code consistency and rejection of conflicting constructor fields.
7. Equality, hashing, civil-day comparison, and record conversion preserve identity.
8. Version-1 regression fixtures, version-2 round trips, and rejection of malformed or unsupported records.
9. Minimum/maximum supported dates, partial years, and adjacent unsupported days.
10. UTC/local conversion, microsecond preservation, negative epoch rounding, DST gaps and folds for adapters.
11. Native and browser execution for integer arithmetic and precision; document native DateTime platform limits rather than asserting precision beyond them.
12. Wrapper/core type identity and dependency resolution against the edited local core.
13. Leap-month formatting/parsing and picker navigation when those layers are added.

## 8. Implementation sequence and completion gates

| Phase | Work | Completion gate |
| --- | --- | --- |
| 1: Baseline | Restore runnable Dart tooling, resolve dependencies, run current tests, move/share core regressions | Current behavior has a verified baseline. |
| 2: Engine extraction | Separate IDs/validation, extract Gregorian/Persian/Umm al-Qura civil conversion, keep adapters | Existing fixture outputs, bounds, and date-time behavior unchanged. |
| 3: Rich civil model | Add month codes/descriptors, variable month arithmetic, year-start APIs, storage migration | A synthetic variable-month test engine exercises generic logic independently of Hebrew calculations. |
| 4: Hebrew | Implement arithmetic engine and fixtures, then adapters/formatting if required | Independent dates, all year structures, and missing-month policies pass. |
| 5: Chinese | Add documented bounded data engine and generation/provenance | Every supported month transition and independent fixture passes. |
| 6: Hindu variant | Specify required tradition and scope, then implement civil or Panchanga API | Variant-specific reference results and boundary semantics pass. |
| 7: Integration/release | Formatter, delegates, migration examples, dependency versions, notices and release checks | Consumers use the new core and existing applications have a documented migration path. |

The highest-value first implementation is engine extraction plus the richer month model. Hebrew then proves the abstraction with variable month counts; Chinese proves repeated month identity and bounded data; traditional Hindu support proves whether an additional astronomical result model is needed.
