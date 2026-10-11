/// Independent civil-date anchors, transcribed from Hebcal's converter
/// documentation and published 2024 calendar (before-sunset Gregorian dates).
/// https://www.hebcal.com/home/219/hebrew-date-converter-rest-api
/// https://www.hebcal.com/hebcal?year=2024&yt=G&d=on
/// Hebcal data: CC BY 4.0, attribution to Hebcal.com.
const hebrewReferenceDates = [
  (gregorian: (2011, 6, 2), hebrew: (5771, 9, 29)),
  (gregorian: (2021, 12, 29), hebrew: (5782, 4, 25)),
  (gregorian: (2022, 1, 1), hebrew: (5782, 4, 28)),
  (gregorian: (2022, 1, 3), hebrew: (5782, 5, 1)),
  (gregorian: (2024, 2, 10), hebrew: (5784, 6, 1)),
  (gregorian: (2024, 3, 11), hebrew: (5784, 7, 1)),
  (gregorian: (2024, 3, 20), hebrew: (5784, 7, 10)),
  (gregorian: (2024, 4, 9), hebrew: (5784, 8, 1)),
  (gregorian: (2024, 10, 3), hebrew: (5785, 1, 1)),
];
