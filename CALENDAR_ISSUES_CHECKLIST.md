# Calendar packages issue checklist

Work through these items in the order used by [the review](CALENDAR_CORE_REVIEW.md). Finish and verify each item before moving to the next. Implementation and verification notes are recorded below each completed issue.

- [x] **1. P1 — Stop resolving the defective published datetime core.** Give the corrected implementations distinct release versions, require the corrected core, resolve local development/example dependencies to the neighboring source, and add integration regressions for chronology, UTC, and equality. Implemented and verified locally; release publication remains pending below.
- [x] **2. P1 — Prevent Gregorian reconstruction through generic DateTime helpers.** Added and verified safe application/calendar boundaries for copyWith and date-only operations. External Gregorian helpers require explicit native conversion; see the limitation below.
- [x] **3. P1 — Guard calendar delegate date types.** Both delegates now consistently reject incompatible runtime date arguments and non-null parser results with `ArgumentError`; explicit conversion and regression coverage are documented below.
- [ ] **4. P2 — Handle direct YearPicker currentDate.** Added `CalendarYearPicker` with a matching delegate-clock default, documentation, and regression coverage.
- [x] **5. P1 — Define safe serialization.** Added versioned Gregorian UTC instant records and tagged calendar-date records, strict decoding, documentation, and regression coverage.
- [x] **6. P2 — Validate conflicting strict-parser date fields.** Strict/loose parsing retains and checks weekday, quarter, ordinal day, and month/day constraints in either field order.
- [x] **7. P2 — Validate repeated parser fields.** Every occurrence is validated; consistent repetitions remain supported, including aliases and ambiguous names.
- [x] **8. P2 — Respect hour cycles when parsing AM/PM.** h/K use the day period; H/k keep their 24-hour value and require matching AM/PM in strict/loose parsing.
- [x] **9. P2 — Correct numeric c/cc weekday semantics.** Both emit unpadded locale-relative weekday numbers 1–7, with range and date-consistency validation.
- [x] **10. P2 — Preserve locale script during fallback.** Added shared language/script/region resolution for formatting, parsing, and Material date/number adapters, with regression coverage.
- [x] **11. P2 — Correct Persian Afrikaans localization.** Generated Afrikaans Persian names from pinned CLDR 48; reconciled shared language/week metadata with intl and documented provenance.
- [x] **12. P2 — Prevent constructor arithmetic overflow.** Exact normalization validates extreme fields before narrowing, preserving ordinary normalization and valid cancellation.
- [x] **13. P2 — Protect shared dateSymbols from mutation.** Symbol fields and collections are immutable; serialization returns detached snapshots.
- [x] **14. P3 — Define negative secondsSinceEpoch rounding.** Both calendars round down directly from microseconds; documented the containing-second contract and verified fractional boundaries.
- [x] **15. P2 — Make example tests deterministic.** Injected a once-per-screen clock, derived all calendars from one instant, and froze fixtures with midnight/rebuild regressions.
- [ ] **16. P2 — Separate pure Dart logic from Flutter integration.** Establish reusable package boundaries if backend/CLI use is required.
- [ ] **17. P2 — Define a complete calendar contract.** Cover identity, construction, conversion, validity, bounds, fields, and registration.
- [ ] **18. P2 — Add date-only and calendar-period policies.** Define civil-day/month/year arithmetic, clamping, and day counting.
- [ ] **19. P2 — Define timezone and scheduling capabilities.** Specify named zones, DST ambiguity, recurrence, and chronology policies.
- [ ] **20. P2 — Build the application calendar UI/controller layer.** Implement the required event views and verify keyboard, semantics, RTL, and layout behavior.
- [ ] **21. P2 — Expand automated integration/platform coverage.** Test the corrected pair, minimum/current Flutter, browser, devices, and explicit timezone expectations.
- [ ] **22. P3 — Improve locale/adapter maintenance.** Establish reproducible data generation, Flutter compatibility checks, and release performance measurements.

## Issue 1 implementation and verification

Status: **done locally**. Release publication remains pending.

- Prepared `general_datetime` **3.0.0** and `general_date_format` **2.0.0** because the corrected chronology, instant/equality behavior, and finite Hijri range change the old contract.
- The formatter and its example now require `general_datetime: ^3.0.0`. The defective hosted 2.1.0 release cannot satisfy this constraint.
- Added documented local override templates for the formatter and its example; the active local overrides resolve both to the neighboring corrected core. These machine-local override files are ignored by Git, and the templates are tracked.
- Removed the formatter's obsolete Hijri UTC workaround, which compensated for the defective hosted implementation.
- Added five dependency-contract regression tests for the reported Hijri dates, instant round trips, UTC parsing, symmetric equality/hash-map lookup, and supported Hijri bounds.

Verification: **165/165 core tests and 493/493 formatter tests passed**. Both package analyzers reported no issues, the formatter format check passed, and both repositories passed `git diff --check`.

The example suite has **three failures** from its time-dependent fixtures and fixed expected calendar labels. These are recorded under issue 15 and were not fixed in this issue-1 change. The example resolves the corrected local core successfully.

### Pending release actions

These are separate from the checked local implementation. Neither release has been published.

- Publish the corrected `general_datetime` 3.0.0 release first.
- Remove the local overrides and repeat integration tests against hosted 3.0.0, verifying the same dependency contract.
- Publish `general_date_format` 2.0.0 after that verification. Until the core is published, consumers must use the documented local override; hosted resolution is expected to fail rather than silently select 2.1.0.

## Issue 2 implementation and verification

Status: **done locally**. See subsequent issue statuses below.

- Added public `CalendarDateUtils.copyWith` and `dateOnly` for values statically typed as `DateTime`. They dispatch to the correct Persian/Hijri constructor behavior, retaining calendar fields, precision, and UTC/local mode. Native inputs keep Gregorian behavior. Unregistered calendar interfaces fail explicitly.
- Added `CalendarDateUtils.toGregorian` as the external-helper boundary. It copies epoch microseconds and timezone mode, never custom year/month/day fields.
- Documented safe application usage, local DST normalization, timezone reinterpretation versus conversion, and the Material picker's separate local-date policy. Clarified the concrete classes' `copyWith` documentation.
- Dart extensions and Flutter static helpers cannot be overridden by a subclass. Raw `DateTime`-typed `.copyWith` and `DateUtils` calls on calendar subclasses remain unsafe; applications must use the new helpers or convert to native Gregorian first. A composition-based civil-date model remains tracked in issue 18.
- Added 18 regression tests spanning both calendars, native Gregorian behavior, and unsupported calendar rejection, with independent calendar reference fixtures.

Verification: **183/183 core tests and 493/493 formatter tests passed** against the corrected local core. Both package analyzers reported no issues, the core's full format check reported zero changes, and both repositories passed `git diff --check`. This completes the explicit adapter boundary; callers must adopt that boundary for the upstream-helper hazard to be avoided.

## Issue 3 implementation and verification

Status: **done locally**. See subsequent issue statuses below.

- Retained `CalendarDelegate<DateTime>` for Flutter compatibility and added explicit runtime validation: Persian accepts `PersianDateTime`; Hijri accepts `HijriDateTime`. Incompatible date arguments throw `ArgumentError` with the argument name, expected type, and explicit conversion guidance.
- Guarded date-only normalization, both range endpoints, day/month navigation, both month-delta operands, every date formatter, and both nullable day/month comparison operands. Mismatches are rejected even when the other comparison operand is null or the numeric fields happen to match.
- Guarded non-null localization parser results. Invalid text still returns null; wrong-calendar parser results raise `ArgumentError` for incompatible configuration. Matching parser results and custom formatting values are forwarded unchanged.
- Preserved matching-date calendar arithmetic and the delegates' existing local-midnight policy. Callers can convert native or other-calendar instants with the matching `fromDateTime` factory.
- Added 38 shared regression tests across both delegates, including Material picker constructor rejection. The direct `YearPicker` default remains tracked in issue 4; callers currently need a matching explicit `currentDate`.

Verification: **221/221 core tests and 493/493 formatter tests passed** against the corrected local core, including existing calendar navigation, input-picker, and formatter localization integration coverage. Both analyzers reported no issues, the core's full format check reported zero changes, and both repositories passed `git diff --check`.

## Issue 4 implementation and verification

Status: **done locally**. See subsequent issue statuses below.

- Added public `CalendarYearPicker`, exported from `general_datetime.dart`, as a standalone Flutter year-picker wrapper. An omitted `currentDate` uses the supplied `calendarDelegate.now()` once; an explicit date bypasses that clock.
- Normalized and validated current, first, last, and non-null selected dates through the delegate. Persian/Hijri inputs retain matching runtime types and the picker's local-date policy; incompatible dates continue to throw `ArgumentError`.
- Retained Flutter's year-selection behavior, including first-of-month callback dates, disabled years, nullable selection, keys, drag behavior, and Gregorian defaults. The current date may lie outside the selectable range.
- Documented wrapper usage with matching localizations and the explicit `PersianDateTime.now()`/`HijriDateTime.now()` requirement when using Flutter's `YearPicker` directly. The upstream widget still defaults to a native Gregorian clock; delegate guards remain strict.
- Added 11 regressions covering Persian/Hijri rendering and callback instants, the supplied delegate clock, explicit current dates, every incompatible date argument, direct Flutter constructor behavior, and Gregorian selection.

Verification: **232/232 core tests and 493/493 formatter tests passed** against the corrected local core. The core analyzer reported no issues, its source format check reported zero changes, and both repositories passed `git diff --check`.

## Issue 5 implementation and verification

Status: **done locally**. See subsequent issue statuses below.

- Added public immutable `CalendarInstant` and `CalendarDateRecord` with version-1 `toJson`/`fromJson` contracts and `dart:convert` round trips. `CalendarId` uses the Unicode identifiers `gregory`, `persian`, and `islamic-umalqura`; other Hijri algorithms are not silently aliased.
- Instant records convert epoch microseconds to native Gregorian UTC before formatting, retaining the exact instant and precision. Decoding returns native UTC and retains calendar/optional timezone presentation metadata separately. Metadata does not reinterpret the timestamp; named-zone resolution and scheduling remain issue 19.
- Calendar-date records contain only calendar/year/month/day, validate strict fields and supported bounds, and never assign a midnight instant or timezone. Extraction from `DateTime` explicitly discards the clock and mode without converting the wall date. Signed Persian years, including zero, are supported. Calendar arithmetic remains issue 18.
- Strict decoders reject malformed records, missing/unknown fields, wrong types or kinds, unknown calendars, unsupported versions, invalid/normalized dates, and excess timestamp precision. The timestamp schema uses four-digit Gregorian years 0000–9999, required seconds, optional one-to-six fractional digits, and `Z`; offsets, leap seconds, and RFC 9557 annotations require separate interchange support.
- Preserved existing calendar-specific `toIso8601String`/matching-parser behavior and added explicit storage warnings to both methods and the README. `toUtc()` alone retains the calendar subclass. Applications must use the new storage boundary (or explicit native Gregorian conversion); manually placing an untagged calendar string into a timestamp field remains inherently ambiguous.
- Added 31 regressions covering independent Gregorian reference fixtures, UTC/local equivalence, microseconds, negative epochs, calendar-date endpoints and signed years, strict schema/timestamp validation, immutable record storage, and unsupported calendar rejection. Documented the schema, error policy, calendar-data policy, and application examples.

Verification: **252/252 core tests and 493/493 formatter tests passed** against the corrected local core in the current working tree. The core analyzer reported no issues, its full source format check reported zero changes, and both repositories passed `git diff --check`.

## Issue 6 implementation and verification

Status: **done locally**.

- Strict and loose parsing retain every explicit month/day, ordinal day, quarter, and weekday constraint and compare it with the resulting calendar date. Conflicts fail with `FormatException`; nullable parser APIs return null. Field order no longer lets a quarter or ordinal day hide invalid month/day input.
- A quarter supplies its first month and day 1 only when those fields are absent. Ordinal-only patterns retain their calendar-specific construction and year-length validation. Ordinary `parse` retains permissive date-field precedence and normalization.
- Textual weekdays retain all matching indices for ambiguous names such as English `T`, preserving valid narrow-name round trips while rejecting incompatible names. Loose names retain their case/whitespace rules without bypassing semantic validation.
- Added regressions for both field orders, matching redundant fields, partial quarter patterns, ordinal bounds, narrow-name ambiguity, local/UTC mode, and all three calendars.

Verification: the issue-6 targeted suite passed before proceeding to issue 7. Final verification for the combined changes is recorded under issue 9.

## Issue 7 implementation and verification

Status: **done locally**.

- Retain every year, month, day, ordinal, quarter, weekday, hour, minute, second, millisecond, era, and day-period occurrence. Invalid or conflicting earlier values cannot be overwritten into acceptance. Matching repetitions and semantic aliases remain supported.
- Validate each hour token's original range before comparing normalized hours. Two-digit years retain their per-occurrence century semantics, and all occurrences use one clock reading for a stable century window.
- Ambiguous month names retain all possible months and intersect with other month constraints; a quarter can also disambiguate a narrow name. Names that remain ambiguous preserve a compatible spelling without claiming a unique date.
- Added regressions for earlier invalid/conflicting fields, both AM/PM orders, repeated eras, matching aliases, narrow month names, two-digit/full-year combinations, and a moving clock at the century boundary.

Verification: the issue-7 targeted suite passed before proceeding to issue 8. Final verification for the combined changes is recorded under issue 9.

## Issue 8 implementation and verification

Status: **done locally**.

- Apply AM/PM conversion to h/K only. H/k retain their complete 24-hour value; k=24 represents midnight on the parsed date. Strict and loose parsing require any day-period marker to match that value.
- `HH:mm a` now round-trips `13:00 PM` as hour 13 and rejects contradictory `01:00 PM`, rather than shifting it to hour 13. Ordinary parsing uses the corrected hour-cycle conversion while retaining its permissive validation policy.
- Retain each occurrence's hour cycle so mixed/repeated hour symbols must describe the same hour. Day-period position does not change the result.
- Added midnight/noon/afternoon/end-of-day regressions for h/K/H/k, repeated and mixed cycles, invalid raw ranges, contradictory markers, both token orders, local/UTC mode, and all three calendars.

Verification: the issue-8 targeted suite passed before proceeding to issue 9. Final verification for the combined changes is recorded below.

## Issue 9 implementation and verification

Status: **done locally**. See subsequent issue statuses below.

- Numeric c/cc now use the selected calendar locale's FIRSTDAYOFWEEK to produce weekday numbers 1–7. Both widths emit one unpadded digit, as defined by the Unicode date field table; ccc/cccc/ccccc retain their weekday-name forms.
- Strict and loose parsing validate every numeric weekday's range and agreement with the resulting date, including repeated tokens and combinations with weekday names. Weekdays constrain the default date when date fields are absent; they do not search for a different date.
- Added locale-relative/native-digit regressions across all three calendars, including independent Monday expectations for en_US (2), en_GB (1), and fa (3) on the same instant. Updated four older Persian formatting expectations that asserted the defective day-of-month behavior.
- Documented redundant-field validation, hour-cycle/day-period behavior, quarter defaults, ambiguous names, numeric weekday semantics, and compatibility changes in the formatter README, API documentation, and changelog.

Final verification for issues 6–9: **252/252 core tests and 540/540 formatter tests passed** against the corrected neighboring core. The formatter includes **47 new regression tests**. Its analyzer reported no issues, the formatter source/test format check reported zero changes, and both repositories passed `git diff --check`. No release was published.

## Issue 10 implementation and verification

Status: **done locally**. Subsequent issue statuses are recorded below.

- Added one shared locale resolver that normalizes hyphens/underscores and language/script/region casing, checks exact and base locale keys, retains supported language-plus-script data, then tries compatible region data and language fallback. Legacy language aliases retain script/region components; default `en_US`, `C`/`en_ISO`, and unsupported-language errors remain supported.
- `sr_Latn_RS` and `sr-Latn-RS` now select `sr_Latn`, retaining Latin weekday/month names in formatting and strict/loose parsing across all three calendars. Regional patterns such as `en_Latn_GB` and numeric-region `es_Latn_419` remain regional.
- Mapped Chinese script requests to the bundled regional tables: `zh_Hant_HK`/`zh_Hant_MO` prefer `zh_HK`, other `zh_Hant` requests prefer `zh_TW`, and `zh_Hans` uses `zh_CN`. Explicit scripts take precedence over conflicting region defaults; an exact supported key still wins.
- Reused the resolver for Material support checks and date/number adapters against their respective data sets, while retaining Flutter's original locale for translated labels. Corrected advertised-locale tests to place script codes in `Locale.fromSubtags` rather than the country field.
- Added **29 regressions** for normalization, candidate priority, aliases, date/number agreement, independent Serbian/Chinese weekday expectations, named-date parsing, regional patterns, and both Material adapters. Documented the policy in the README, constructor documentation, and changelog. Variants/extensions are tried as exact keys, then ignored for fallback; unsupported scripts can fall back to language data. Full CLDR matching, calendar selection through Unicode extensions, and numbering-system extension preferences are outside this resolver's contract.

Verification: **252/252 core tests and 569/569 formatter tests passed** against the corrected neighboring core. The formatter analyzer reported no issues, its complete source/test format check reported zero changes, and both repositories passed `git diff --check`. No release was published.

## Issue 11 implementation and verification

Status: **done locally**.

- Generated Afrikaans Persian month and era names from Unicode CLDR 48, tag `48.0.0`. Added a reproducible generator with a non-writing `--check`, source URL, input SHA-256, and Unicode license attribution. Afrikaans now formats `Farvardin`, `Woensdag`, and `nm.`; Material weekday headers use `[S, M, D, W, D, V, S]`.
- Reconciled Persian weekday names, quarters, AM/PM markers, time/date-time formats, and week metadata against the same intl locale source used by Gregorian and Hijri. Calendar month/era names, native-digit defaults, and existing calendar date patterns retain their separate policies. Updated older Persian weekday/quarter golden expectations after independently checking CLDR spellings.
- Retained Monday for `en_MY` and the deliberate `en_ISO` convention. intl/CLDR's Malaysia data differs from Flutter's English fallback; the formatter adapters intentionally retain their selected source rather than copying that fallback's Sunday convention.
- Added four regressions for independently specified Afrikaans text and strict parsing, picker headers/dates, every supported locale's neutral metadata, and Malaysia/ISO conventions. Documented generation and provenance in the formatter's `tool/README.md`, README, changelog, and third-party notice.
- Other Persian month/era translations and the separate skeleton-pattern table still use legacy sources. A complete CLDR migration/translation audit remains issue 22; this fix does not claim authoritative generation of those remaining tables.

Verification: the four new regressions and the complete formatter suite passed. Final combined verification for issues 11–13 is recorded below.

## Issue 12 implementation and verification

Status: **done locally**.

- Both date classes use shared exact month and clock normalization. Ordinary bounded components use safe integer arithmetic; extreme inputs use BigInt before multiplication, addition, subtraction, and supported-range validation. BigInt results are narrowed only after they fit the calendar's range.
- Oversized positive/negative hours, minutes, seconds, milliseconds, microseconds, and month/day/year combinations can no longer wrap into valid dates. Addition overflow is covered even when each individual multiplication fits.
- Preserved normal negative/overflow normalization, valid cancellation of extreme fields, microsecond precision, UTC/local behavior, and the maximum-date end sentinel. The same protection applies to calendar copyWith paths. Exact out-of-range results throw RangeError.
- Added 28 regressions across both calendars and UTC/local mode, covering the reproduced wraps, int64 endpoints, month/year cancellation, large clock/day cancellation, normal fields, supported endpoints, and copyWith. Documented the constructor policy in the core README and changelog.

Verification: **280/280 core tests passed**, including the existing exhaustive independent calendar fixtures. The core analyzer reported no issues. Final combined verification is recorded below.

## Issue 13 implementation and verification

Status: **done locally**. Subsequent issue statuses are recorded below.

- DateSymbols scalar fields are final; lists and maps are defensively copied and unmodifiable for Gregorian, Persian, and Hijri. Symbol access can no longer replace month names, digit metadata, or week conventions globally.
- serializeToMap returns a detached mutable snapshot, including all nested lists/maps. Snapshot edits are available for application-owned labels and do not customize the formatter. Direct construction and deserialization also isolate caller-owned collections.
- Updated Gregorian initialization to set digit metadata before constructing immutable symbols. Documented the breaking removal of symbol setters and the getter's most-recent-calendar policy in API docs, the README, and changelog.
- Added 11 regressions covering field and collection mutation attempts, unaffected existing/new formatters and strict parsing, detached snapshots, and caller-owned constructor/deserializer inputs across all three calendars.

Final verification for issues 11–13: **280/280 core tests and 584/584 formatter tests passed** against the corrected neighboring core. Both analyzers reported no issues. Both source/test format checks reported zero changes; the CLDR generator's `--check` passed, and both repositories passed `git diff --check`. Browser/device execution and release publication were not performed.

## Issue 14 analysis, implementation and verification

Status: **done locally**.

- Confirmed the getter still reduced microseconds through native milliseconds and then truncated seconds. This mixed rounding did not consistently identify the second containing a negative fractional instant. The new boundary/reconstruction regressions failed against both old implementations; exact-second tests already passed.
- Defined a single policy: floor the exact microsecond epoch value to the containing Unix second. Both getters now use direct integer division plus a negative-remainder adjustment, without passing through milliseconds or floating point. For example, -1 and -999999 microseconds map to -1 second; -1000001 maps to -2 seconds. Positive fractions and exact integer seconds retain their expected values.
- Documented the policy, timezone independence, fractional precision loss, and compatibility change in both concrete getters, the shared interface, README and changelog. Microseconds/CalendarInstant remain the precision-preserving storage boundary.
- Added six shared regressions with 25 independent signed boundary fixtures, UTC/local construction, timezone conversion, containing-second reconstruction bounds, and exact second round trips beyond 32-bit limits.

Verification: **286/286 core tests passed**, including the existing exhaustive calendar/reference suites and all six new epoch tests. The corrected formatter dependency integration also passed. Both analyzers reported no issues. Final combined verification is recorded below.

## Issue 15 analysis, implementation and verification

Status: **done locally**. Issues 16–22 remain open.

- Reproduced all three existing example test failures: fixed Farvardin/Ramadan/date expectations no longer matched the three independent now() calls. Reading separate clocks on every build also allowed calendar displays to describe different instants near midnight.
- Added an optional native clock callback to MyApp/FormatExample. The screen samples it once during initialization, defaulting to DateTime.now, and derives Persian and Hijri values from that same native instant. Locale changes and picker rebuilds retain the snapshot; creating a fresh screen reads the clock again. No new dependency was needed.
- Froze every example test with an explicit UTC fixture: Gregorian 2024-03-20, Persian 1403-01-01, and Umm al-Qura 1445-09-10. Asserted independent ASCII/native-digit dates and exact selected picker labels, while retaining localized headers, RTL behavior and widget exception checks.
- Added two widget regressions for a clock crossing midnight during locale rebuilds and fresh-screen capture. The five example tests now use injected time, with no expectations tied to the execution date. Documented the snapshot and test-clock policy in the example README, package README and changelog.

Final verification for issues 14–15: **286/286 core tests, 584/584 formatter tests, and 5/5 example tests passed** against the corrected neighboring packages. Both analyzers reported no issues, including the formatter example. Core and formatter/example format checks reported zero changes; both repositories passed `git diff --check`. Browser/device execution and release publication were not performed.
