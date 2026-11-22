# Expansion to other languages and frameworks

Assessment date: 2026-11-02. Scope: the local `general_date`,
`general_date_format`, and `general_calendar` working trees. This is an
architecture and source review, not an implemented port, new benchmark, or
verification of published package versions. Existing validation results below
are attributed to the repository reports; tests were not rerun for this review.

## Recommendation

Expansion is technically feasible. The chronology and formatter already have
Flutter-free Dart cores; the widgets require a new implementation for each UI
technology. For broad reuse across web applications and JavaScript backends,
start with a native TypeScript chronology and formatter, then a headless calendar
controller and one React adapter. Vue, Svelte, and Angular can share that same
TypeScript engine and controller. Choose a subsequent backend/native language
from demonstrated consumer demand.

The shared asset should be the calendar specification, pinned data, generators,
and conformance fixtures. Reproducing Dart's `DateTime` inheritance throughout
other languages would make the ports harder to integrate and maintain.

## Existing boundaries and readiness

| Component | Current evidence | Expansion assessment |
| --- | --- | --- |
| `general_datetime_core` | No runtime dependencies; five calendar IDs; civil dates, periods, weeks, instants, strict storage | Strong candidate for a direct algorithm/data port, with redesigned native-date integration |
| `general_datetime` | Re-exports the core; Material delegates and default localizations | Retain as the Flutter adapter; implement equivalent adapters per target framework |
| `general_date_format_core` | Depends only on chronology core; four non-Gregorian calendars; 120 locale identifiers | Good candidate, with substantial parsing and locale-policy compatibility work |
| `general_date_format` | Core re-export plus Material localization implementations | Reuse formatting behavior and data; rebuild framework localization integration |
| `general_calendar` | Runtime dependency only on Flutter; `CalendarDelegate<DateTime>`, Material types, widget state, painting and gestures | Portable behavior and design concepts; low direct UI-source reuse |

Measured source inventory, excluding tests/examples:

- Chronology core: 24 Dart files, 5,194 lines, 169,345 bytes.
- Formatter core: 21 Dart files, 68,155 lines, 1,257,647 bytes.
  Symbol-directory files and the shared pattern table account for 1,148,123
  bytes, approximately 91% of that source size. Most of the apparent volume is
  data; this is not a shipped bundle-size measurement.
- Calendar UI: 11 Dart files, 3,471 lines, 131,625 bytes. Ten files import
  Flutter. Selection and time rules also expose Flutter types, so they are not
  currently an independently reusable headless package.

Source anchors:
[chronology manifest](../packages/general_datetime_core/pubspec.yaml),
[calendar systems](../packages/general_datetime_core/lib/src/calendar_system.dart),
[civil dates](../packages/general_datetime_core/lib/src/calendar_date.dart),
[formatter manifest](../../general_date_format/packages/general_date_format_core/pubspec.yaml),
[formatter dispatch](../../general_date_format/packages/general_date_format_core/lib/src/general_date_format_internal.dart),
[calendar widget](../../general_calendar/lib/src/general_calendar.dart),
and [time rules](../../general_calendar/lib/src/time_rules.dart).

## Practical target order

The ranking below assumes broad web reach is the objective. It is an engineering
recommendation, not a market-demand study.

| Target | Approach | Main additional work | Priority under that assumption |
| --- | --- | --- | --- |
| TypeScript / JavaScript | Native chronology, formatter, and controller packages | Exact integer/instant handling; ESM packaging; browser and Node checks; locale subpath exports | First |
| React / Next.js | React bindings and components over the TypeScript packages | DOM semantics, focus, keyboard navigation, SSR/hydration, styling | First UI adapter |
| Vue / Nuxt, Svelte / SvelteKit, Angular | Reuse TypeScript packages; new bindings and views | Framework lifecycle, forms integration, SSR where applicable | After first adapter validates the boundary |
| Python | Pure Python chronology/formatter with native conversion helpers | Native date range limits; API ergonomics; packaging | Good backend follow-up when requested |
| Kotlin / Java / Compose | JVM engine plus optional Compose UI | Native time adapters; pinned chronology parity; new UI | Good Android/JVM follow-up |
| Swift / SwiftUI | Swift values plus Foundation adapters and new SwiftUI views | Native time/calendar mapping, precision and range checks, new UI | Good Apple follow-up |
| C# / .NET / Blazor / MAUI | .NET values/formatting and framework-specific components | Exact data/policy parity and native date conversions | Good .NET follow-up |
| Rust with bindings | Shared engine, generated bindings, optional Wasm target | Engine rewrite, ABI, ownership/errors, native builds and distribution | Consider when several native consumers justify it |
| Go / PHP and other server languages | Focused chronology/formatter ports | Same specification and fixture work; separate release ownership | Demand-driven |

Web-framework reuse does not imply that a React DOM component can be used
unchanged in React Native. React Native could share compatible TypeScript logic
but would need its own rendering, interaction, and accessibility adapter.

## Contracts that must survive a port

### Calendar policy and month identity

Preserve the exact calculation policy and bounds exposed by `CalendarSystem`:

- Persian: published Tehran data for SH 1206-1498; bounded Borkowski prediction
  outside that interval; supported SH years -61 through 3177, including zero.
- Umm al-Qura: AH 1300-1600 table, with explicit rejection beyond coverage.
- Hebrew: AM 1-9999; stable month slots with slot 6 absent in common years.
- Chinese: related years 1901-2099, chronological month ordinals, plus separate
  traditional lunar-month and leap-month identity.
- Gregorian: current broad Dart range; other platforms must either preserve it
  internally or declare narrower conversion support explicitly.

Do not silently replace these rules with a host's calendar implementation. The
existing [Chinese guide](chinese-calendar.md) records 417 differing days against
Node ICU 77.1 and 30 against the HKO reference. Those are previously recorded
comparisons, not newly reproduced measurements. The package deliberately follows
its pinned .NET table. Calendar names alone do not guarantee identical dates.
ECMA-402 also explicitly allows internationalization data to vary across
implementations and over time ([specification](https://tc39.es/ecma402/#sec-implementation-dependencies)).

Expose month descriptors containing the existing numeric slot/ordinal, month
code, and leap flag. Enumerate actual months rather than assuming twelve or
incrementing a stable slot blindly. Preserve the existing schema's numeric
month meaning when reading old JSON; any storage change needs a versioned
migration, rather than silently interpreting that number differently.

### Civil dates, instants, arithmetic and native types

Use composition with distinct values for a civil date, wall-clock fields, and an
instant. Keep host-native date conversion at the boundary. `PersianDateTime`
and its peers currently extend Dart `DateTime`; that compatibility strategy
should remain an adapter concern in new languages.

Use an integer day index for civil conversion and arithmetic. Use exact instant
storage, such as epoch seconds plus a nonnegative microsecond remainder, or an
appropriately sized exact integer. JavaScript `Date` has millisecond precision;
it cannot be the sole storage for microsecond-preserving values
([ECMAScript date specification](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-time-values-and-time-range)).
Offer explicitly documented lossy conversion if an application needs it.
Python's native `date` and `datetime` support years 1-9999, so they cannot cover
the complete current civil-date domain, including early Hebrew dates converted
to Gregorian ([Python documentation](https://docs.python.org/3/library/datetime.html#constants)).
Represent those values internally and reject unsupported native conversions.

Port division semantics deliberately: Dart uses truncating `~/`, Euclidean `%`,
and signed `remainder` in different places. Negative years, negative epochs and
overflow normalization will break if a target language's operators are used
without matching those choices. Preserve checked/exact arithmetic before
narrowing large results, including valid cancellation of extreme components.

Keep strict construction separate from normalizing constructors. Preserve
clamp/reject/overflow and missing-leap-month policies. Core `CalendarDateRange`
is half-open; the UI's selected date range includes both endpoints. Make the
conversion explicit in every adapter.

### Formatting and parsing

The current formatter handles Persian, Umm al-Qura, Hebrew, and Chinese.
Gregorian formatting is delegated to the consuming application's formatter.
Do not promise five-calendar formatter parity without implementing that extra
scope.

Reuse the pinned CLDR 48 sources and compatibility policy. The generator is
already Python and reads JSON inputs, but currently emits Dart; extend it with
a neutral intermediate representation and target-specific emitters. Preserve
locale aliases/fallback, native digits, standalone versus contextual names,
leap names, existing skeleton choices, and unsupported pattern behavior.
Not every existing skeleton is an exact CLDR calendar-specific match.

Port strict and loose parsing as behavior, rather than translating patterns to
a host formatter. Important cases include adjacent numeric/name fields,
conflicting repeated fields, day-of-year checks, fractions, localized digits,
and the clock-dependent two-digit-year window. The formatter currently selects
its calendar from runtime date types and maintains calendar-dependent cached
state. A new API can select the calendar explicitly and keep immutable compiled
patterns with per-operation state, while preserving documented output.

### Timezones and interchange

UTC and host-local mode are supported today. IANA IDs in `CalendarInstant` are
opaque metadata; the core does not resolve them. Named-zone support would be a
separate capability requiring a provider and explicit gap/fold policy.
Server rendering and clients must not independently infer calendar day, local
timezone, or today's date if that can change the initial rendered result.

Retain version-1 civil-date and UTC timestamp JSON contracts. Timestamp records
have a narrower Gregorian year range, 0000-9999, and at most six fraction digits.
Native conversion limits must not redefine storage validity. Keep strict
unknown-field rejection; place new data-version metadata in a package manifest
or a separately versioned schema.

## Implementation strategies

| Strategy | Benefit | Cost / limitation | Assessment |
| --- | --- | --- | --- |
| Native ports with shared spec/data/fixtures | Idiomatic APIs and packaging; independent runtime deployment | Each implementation needs maintained conformance | Recommended initial approach |
| Dart compiled to JS/Wasm with a facade | Reuses current engine for a proof of concept | Loader/interop, target-runtime support, bundle cost and precision need measurement; UI still needs an adapter | Useful experiment, not an automatic npm/native library |
| New Rust/C++ shared engine and bindings | A single algorithm implementation for multiple consumers | Largest upfront change; binding/build/distribution complexity | Reassess once multiple native ports are funded |
| Dart HTTP service | Central updates and identical server behavior | Network latency, deployment and offline constraints | Optional service product, unsuitable as the only local date engine |

Dart officially supports JavaScript and Wasm compilation, with explicit interop
mechanisms for exposing Dart values. Current Wasm documentation includes both
default JavaScript-hosted output and a standalone option; requirements depend
on the runtime and toolchain. Validate against the repository's actual SDK,
rather than assuming newer compiler options exist there
([compiler documentation](https://dart.dev/tools/dart-compile),
[Wasm requirements](https://dart.dev/web/wasm),
[JS export/interoperability](https://dart.dev/interop/js-interop/usage)).
Compilation support alone does not establish a stable C ABI, Python wheel,
Swift package, SSR-ready npm API, or compatibility with every Wasm host.

## Preparation and delivery gates

1. **Freeze the reference contract.** Record a compatible source revision for
   both cores; reconcile prepared dependency versions. The current chronology
   manifests are wrapper 5.0.0/core 3.0.0, while formatter manifests still
   require wrapper ^4.0.0/core ^2.0.0. Local overrides can hide this mismatch.
   Some architecture/index prose also predates implemented Chinese support.
2. **Publish portable fixtures and data.** Reuse the Chinese .NET JSON fixture
   and Persian CSV; export remaining Dart fixtures and parser/arithmetic/error
   cases to JSON. Keep independent oracle expectations separate from generated
   snapshots of Dart behavior. Generate all targets from the same approved
   source hashes and carry the existing license/third-party notices.
3. **Ship a TypeScript chronology core.** Cover all five calendars, strict civil
   dates, conversion, period policies and existing storage. Keep native `Date`
   helpers separate. Gate release on conformance, including negative dates,
   bounds, leap months, microseconds and invalid records.
4. **Ship the formatter.** Preserve the existing four-calendar scope. Offer
   calendar/locale subpath exports so consumers can avoid loading all 120 locale
   identifiers. Gate release on exact reference cases and intentional policy
   exceptions, and measure actual browser and server package costs.
5. **Extract headless UI behavior and build one adapter.** Model month/week/year
   grids, navigation, selection transitions, disabled interiors, date attributes,
   and time-slot validation outside React. Rebuild rendering, focus, semantics,
   RTL and motion in React; test browser interaction and SSR/hydration.
6. **Add targets selectively.** Each new language runs the same conformance suite;
   each UI gets framework-specific interaction tests. Require a maintainer and
   release pipeline before committing to another public port.

Existing reference validation is a useful advantage: the Chinese test walks all
72,674 supported civil days against independently exported .NET month fixtures.
See the [implementation audit](chinese-implementation-audit-2026-10-28.md) and
[oracle test](../packages/general_datetime_core/test/chinese_dotnet_validation_test.dart).
These provide a starting point for portable conformance rather than proof that
a future port is already correct.

The likely effort order is contract/data work, chronology port, formatter
compatibility, then a production-quality UI adapter. Full widget parity includes
many designs, selection modes and time inputs; it should be budgeted separately
from a first usable calendar. A credible calendar estimate needs a chosen target,
API scope, runtime matrix and UI feature list; line counts alone cannot provide it.
