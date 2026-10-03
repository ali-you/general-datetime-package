# Calendar packages issue checklist

Work through these items in the order used by [the review](CALENDAR_CORE_REVIEW.md). Finish and verify each item before moving to the next. Implementation and verification notes are recorded below each completed issue.

- [x] **1. P1 — Stop resolving the defective published datetime core.** Give the corrected implementations distinct release versions, require the corrected core, resolve local development/example dependencies to the neighboring source, and add integration regressions for chronology, UTC, and equality. Implemented and verified locally; release publication remains pending below.
- [x] **2. P1 — Prevent Gregorian reconstruction through generic DateTime helpers.** Added and verified safe application/calendar boundaries for copyWith and date-only operations. External Gregorian helpers require explicit native conversion; see the limitation below.
- [x] **3. P1 — Guard calendar delegate date types.** Both delegates now consistently reject incompatible runtime date arguments and non-null parser results with `ArgumentError`; explicit conversion and regression coverage are documented below.
- [x] **4. P2 — Handle direct YearPicker currentDate.** Added `CalendarYearPicker` with a matching delegate-clock default, documentation, and regression coverage.
- [ ] **5. P1 — Define safe serialization.** Separate Gregorian UTC timestamps from tagged calendar date records.
- [ ] **6. P2 — Validate conflicting strict-parser date fields.** Check weekday, quarter, ordinal day, and month/day consistency.
- [ ] **7. P2 — Validate repeated parser fields.** Reject invalid or inconsistent earlier occurrences.
- [ ] **8. P2 — Respect hour cycles when parsing AM/PM.** Handle or reject combinations with H/k explicitly.
- [ ] **9. P2 — Correct numeric c/cc weekday semantics.** Use locale-relative weekday numbers and validation.
- [ ] **10. P2 — Preserve locale script during fallback.** Resolve language/script/region consistently in formatting and Material adapters.
- [ ] **11. P2 — Correct Persian Afrikaans localization.** Reconcile locale-neutral weekday/time/week metadata and document authoritative data generation.
- [ ] **12. P2 — Prevent constructor arithmetic overflow.** Check extreme wall-clock/month/day inputs before multiplication and addition wrap.
- [ ] **13. P2 — Protect shared dateSymbols from mutation.** Expose immutable data or explicit instance-local customization.
- [ ] **14. P3 — Define negative secondsSinceEpoch rounding.** Compute directly from microseconds and test fractional boundaries.
- [ ] **15. P2 — Make example tests deterministic.** Inject/freeze time and derive all displayed calendars from one instant.
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

Status: **done locally**. Issues 5–22 remain open.

- Added public `CalendarYearPicker`, exported from `general_datetime.dart`, as a standalone Flutter year-picker wrapper. An omitted `currentDate` uses the supplied `calendarDelegate.now()` once; an explicit date bypasses that clock.
- Normalized and validated current, first, last, and non-null selected dates through the delegate. Persian/Hijri inputs retain matching runtime types and the picker's local-date policy; incompatible dates continue to throw `ArgumentError`.
- Retained Flutter's year-selection behavior, including first-of-month callback dates, disabled years, nullable selection, keys, drag behavior, and Gregorian defaults. The current date may lie outside the selectable range.
- Documented wrapper usage with matching localizations and the explicit `PersianDateTime.now()`/`HijriDateTime.now()` requirement when using Flutter's `YearPicker` directly. The upstream widget still defaults to a native Gregorian clock; delegate guards remain strict.
- Added 11 regressions covering Persian/Hijri rendering and callback instants, the supplied delegate clock, explicit current dates, every incompatible date argument, direct Flutter constructor behavior, and Gregorian selection.

Verification: **232/232 core tests and 493/493 formatter tests passed** against the corrected local core. The core analyzer reported no issues, its source format check reported zero changes, and both repositories passed `git diff --check`.
