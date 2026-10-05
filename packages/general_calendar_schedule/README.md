# Named zones and civil scheduling

This optional, unpublished Dart application-support package depends on
`general_datetime_core` and `timezone`; the chronology core has no zone dependency.
For local development, copy `pubspec_overrides.yaml.example` to
`pubspec_overrides.yaml`, then run `dart pub get` and `dart test`.

Initialize a timezone dataset explicitly and supply its actual data revision:

```dart
import 'package:timezone/data/latest.dart' as data;
import 'package:general_calendar_schedule/general_calendar_schedule.dart';
import 'package:general_datetime_core/general_datetime_core.dart';

data.initializeTimeZones();
// Verify this revision against the resolved data/latest.dart when updating.
final zones = IanaTimeZoneProvider(databaseRevision: 'IANA 2025c');
final date = CalendarDate(calendar: CalendarId.persian,
    year: 1403, month: 1, day: 1);
final instant = zones.resolve(date, WallClock(9), 'Asia/Tehran');
```

Provider resolution converts civil calendar fields into Gregorian wall fields
and searches for matching UTC instants. Native UTC/local calendar subclasses
do not retain named zones. Do not pass a TZDateTime to a calendar subclass and
assume the named zone will survive; use `dateAt` and `timeAt` explicitly.

Missing wall times reject by default, or can skip/advance to the next valid
minute within 48 hours. That adjustment preserves seconds/fractions; it is not
the same as adding the DST gap size. Repeated times reject by default, or select
the earlier/later UTC instant. Unknown zones and supported-calendar range
violations fail explicitly. `UTC` has an explicit alias for both supported
timezone package APIs.

`CalendarSchedule` supports daily/weekly/monthly/yearly rules with positive
intervals, optional candidate count/inclusive last date, calendar date policies,
exclusions and moved exceptions. Monthly/yearly candidates always derive from
the original date. Count measures anchored candidate slots, including skipped
or cancelled slots; this is a documented application policy, **not RFC 5545
RRULE semantics or an ICS importer**. Expansion has an explicit candidate limit
and throws on exhaustion rather than returning partial results. Queries use
half-open UTC windows and include events overlapping the window.

Store a future rule's calendar, starting civil date, wall clock, named zone,
date/gap/fold policies, limits and exceptions separately from generated instants.
The application owns its rule schema. `ScheduleOccurrence` exposes chronology
and zone revisions; store completed occurrences as native UTC instants through
`CalendarInstant`. Recompute future occurrences after a zone-data change under
the retained policies, while preserving already stored historical instants.
Durations are elapsed time; wall-clock end times require a separate resolution.

Umm al-Qura is explicitly the finite table chronology, not every religious or
observational Hijri calendar. Persian published-data coverage remains distinct
from calculated coverage. `BusinessDayPolicy` accepts explicit weekend and
holiday dates; it does not download or infer a country's holidays.
`ReminderDelivery` is an interface for OS/backend delivery, not a background
worker or notification permission flow.

Expansion seeks the first anchored slot that could overlap the UTC query using
the zone's possible offsets, elapsed duration, and the gap policy's maximum
48-hour advance. It does not resolve irrelevant historical gaps/folds. Monthly
overflow can contribute an occurrence from the preceding anchor month, and moved
overrides are queried independently by their replacement instants. `count` still
measures slots from the original start; `maxCandidates` limits relevant slots
examined by the current query, including skipped/cancelled slots. Exceeding that
limit still throws. An inclusive `lastDate` is checked in slot coordinates before
constructing a following date, so an ended rule cannot fail on a later missing
day or chronology boundary. A relevant invalid slot still fails under rejection
policies.

Custom `TimeZoneProvider` implementations must provide `offsets(zone)`: a finite,
nonempty set containing every possible UTC offset for that zone, including
historical offsets. The supplied `IanaTimeZoneProvider` obtains this directly
from its initialized timezone dataset. Providers must also honor the 48-hour
maximum for `MissingTimePolicy.nextValidMinute`.

SDK 3.4 can select timezone 0.10; newer SDKs can select 0.11. Offset representation
differences are adapted explicitly. Calendar engine/version-1 storage contracts
are unchanged.
