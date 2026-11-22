# Chinese package publication — 2026-11-11

All five releases were uploaded to pub.dev and verified through their individual
version API endpoints. `main` was not changed; review branches and pull requests
were pushed for the repository owner to merge.

| Package | Published version | Archive SHA-256 |
| --- | --- | --- |
| general_datetime_core | 3.0.1 | 5a8da4c6630fdecb7f757211eeffcbcf79fedb8a15c9d00949e71183a7ceefcd |
| general_datetime | 5.0.1 | a773cc8a21a58eae928c9afbcf7146009bd7bf46fb433f472c26599f8add1390 |
| general_date_format_core | 3.1.0 | 890594cdab6a9e690eddd4a77a32b8018441e8afed32bf2f302fe04d4933e6ad |
| general_date_format | 4.1.0 | 4ceea42e7085752f3b013e8591e42c6037148d777cfa17e137cc5c17d73efb9e |
| general_calendar | 1.1.1 | e84b909e32a2917b08135765ef85ef22c3ad4dfb089b2ede226073e712a67c8c |

Ran `dart format .` in each repository. Before uploading each dependent package,
removed its development overrides temporarily, resolved hosted dependencies and
passed its full suite: chronology wrapper 352, formatter core 99, formatter
wrapper 519, and calendar 152 tests. Local overrides were restored afterward.
The preceding independent validation also passed chronology core's 57 native /
51 Node cases, formatter's 98 Node cases, minimum SDK, Chrome JS/Wasm, timezone
and exhaustive .NET reference checks. See the [implementation report](chinese-release-readiness-2026-11-11.md).

The chronology CI now uses hosted formatter core 3.1.0; the obsolete formatter
source bootstrap was removed. The formatter CI pins the pushed chronology
release commit. Example lockfiles were resolved against hosted releases.

Review and merge:

- [Chronology PR 3](https://github.com/ali-you/general-datetime-package/pull/3)
- [Formatter PR 3](https://github.com/ali-you/general-date-format-package/pull/3)
- [Calendar PR 1](https://github.com/ali-you/general-calendar-package/pull/1)

The pre-existing documentation index edit and cross-language expansion draft
remain outside these release commits. Remote CI results are separate from the
completed local validation; no merge was performed.
