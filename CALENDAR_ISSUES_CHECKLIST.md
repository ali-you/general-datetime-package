# Calendar packages issue checklist

Work through these items in the order used by [the review](CALENDAR_CORE_REVIEW.md). Finish and verify each item before moving to the next. This turn addresses issue 1 only.

- [x] **1. P1 — Stop resolving the defective published datetime core.** Give the corrected implementations distinct release versions, require the corrected core, resolve local development/example dependencies to the neighboring source, and add integration regressions for chronology, UTC, and equality. Implemented and verified locally; release publication remains pending below.
- [ ] **2. P1 — Prevent Gregorian reconstruction through generic DateTime helpers.** Define safe application/calendar boundaries for copyWith and date-only operations.
- [ ] **3. P1 — Guard calendar delegate date types.** Reject or explicitly convert incompatible inputs consistently.
- [ ] **4. P2 — Handle direct YearPicker currentDate.** Provide a safe matching default and regression coverage.
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

Status: **done locally**. Issues 2–22 remain open.

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
