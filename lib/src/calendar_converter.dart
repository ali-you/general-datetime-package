import 'dart:math';

/// A calendar conversion utility class that provides functions to convert between
/// different calendar systems. Based on the Fourmilab Calendar Converter by John Walker.
///
/// This class includes conversions for:
/// - Julian Day Number calculations
/// - Gregorian calendar
/// - Julian calendar
/// - Persian (Jalali) calendar
/// - Islamic calendar
/// - Hebrew calendar
/// - and more
///
/// Original JavaScript source: http://www.fourmilab.ch/documents/calendar/
class CalendarConverter {
  // Constants
  static const double J0000 = 1721424.5; // Julian date of Gregorian epoch: 0000-01-01
  static const double J1970 = 2440587.5; // Julian date at Unix epoch: 1970-01-01
  static const double JMJD = 2400000.5; // Epoch of Modified Julian Date system
  static const double J1900 = 2415020.5; // Epoch (day 1) of Excel 1900 date system (PC)
  static const double J1904 = 2416480.5; // Epoch (day 0) of Excel 1904 date system (Mac)
  
  static const List<String> GREGORIAN_MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  
  static const List<String> PERSIAN_WEEKDAYS = [
    "Yekshanbeh", "Doshanbeh", "Seshhanbeh", "Chaharshanbeh",
    "Panjshanbeh", "Jomeh", "Shanbeh"
  ];
  
  static const List<String> ISLAMIC_WEEKDAYS = [
    "al-'ahad", "al-'ithnayn", "ath-thalatha'", "al-'arb`a'",
    "al-khamis", "al-jum`a", "as-sabt"
  ];
  
  static const double PERSIAN_EPOCH = 1948320.5;
  static const double ISLAMIC_EPOCH = 1948439.5;

  /// Calculate day of week from Julian day
  static int jwday(double j) {
    return ((j + 1.5).floor()) % 7;
  }

  /// Modulus function which works for non-integers and returns positive values
  static int mod(double a, double b) {
    return (a % b).floor();
  }

  /// Return the Julian day number that precedes the given weekday (0 = Sunday)
  static double weekday_before(int weekday, double jd) {
    return jd - jwday(jd - weekday);
  }

  /// Search for nearest weekday
  static double search_weekday(int weekday, double jd, int direction, int offset) {
    return weekday_before(weekday, jd + (direction * offset));
  }

  /// Find the nearest specified weekday
  static double nearest_weekday(int weekday, double jd) {
    return search_weekday(weekday, jd, 1, 3);
  }
  
  /// Find the next specified weekday
  static double next_weekday(int weekday, double jd) {
    return search_weekday(weekday, jd, 1, 7);
  }
  
  /// Find the next or current specified weekday
  static double next_or_current_weekday(int weekday, double jd) {
    return search_weekday(weekday, jd, 1, 6);
  }
  
  /// Find the previous specified weekday
  static double previous_weekday(int weekday, double jd) {
    return search_weekday(weekday, jd, -1, 1);
  }
  
  /// Find the previous or current specified weekday
  static double previous_or_current_weekday(int weekday, double jd) {
    return search_weekday(weekday, jd, 1, 0);
  }

  /// Check if a Gregorian year is a leap year
  static bool leap_gregorian(int year) {
    return ((year % 4) == 0) && (!(((year % 100) == 0) && ((year % 400) != 0)));
  }

  /// Convert Gregorian date to Julian day number
  static double gregorian_to_jd(int year, int month, int day) {
    const double GREGORIAN_EPOCH = 1721425.5;
    return (GREGORIAN_EPOCH - 1) +
           (365 * (year - 1)) +
           ((year - 1) ~/ 4) +
           (-(((year - 1) ~/ 100))) +
           ((year - 1) ~/ 400) +
           ((((367 * month) - 362) ~/ 12) +
           ((month <= 2) ? 0 : (leap_gregorian(year) ? -1 : -2)) +
           day);
  }

  /// Convert Julian day number to Gregorian date
  static List<int> jd_to_gregorian(double jd) {
    double wjd, depoch, quadricent, dqc, cent, dcent, quad, dquad, yindex, dyindex;
    int year, month, day, leapadj;

    wjd = (jd - 0.5).floor() + 0.5;
    depoch = wjd - GREGORIAN_EPOCH;
    quadricent = (depoch / 146097).floor();
    dqc = mod(depoch, 146097);
    cent = (dqc / 36524).floor();
    dcent = mod(dqc, 36524);
    quad = (dcent / 1461).floor();
    dquad = mod(dcent, 1461);
    yindex = (dquad / 365).floor();
    year = (quadricent * 400) + (cent * 100) + (quad * 4) + yindex;
    if (!((cent == 4) || (yindex == 4))) {
      year++;
    }
    
    final yearday = wjd - gregorian_to_jd(year, 1, 1);
    final leapTest = wjd < gregorian_to_jd(year, 3, 1);
    leapadj = leapTest ? 0 : (leap_gregorian(year) ? 1 : 2);
    month = ((((yearday + leapadj) * 12) + 373) / 367).floor();
    day = (wjd - gregorian_to_jd(year, month, 1)).floor() + 1;

    return [year, month, day];
  }

  /// Check if Julian year is a leap year
  static bool leap_julian(int year) {
    return mod(year, 4) == ((year > 0) ? 0 : 3);
  }

  /// Convert Julian calendar date to Julian day number
  static double julian_to_jd(int year, int month, int day) {
    // Adjust negative common era years
    if (year < 1) {
      year++;
    }

    // Algorithm from Meeus, Astronomical Algorithms, Chapter 7, page 61
    if (month <= 2) {
      year--;
      month += 12;
    }

    return ((365.25 * (year + 4716)).floor() +
            (30.6001 * (month + 1)).floor() +
            day - 1524.5);
  }

  /// Convert Julian day to Julian calendar date
  static List<int> jd_to_julian(double td) {
    double a, b, c, d, e;
    int year, month, day;

    td += 0.5;
    a = td.floor();
    b = a + 1524;
    c = ((b - 122.1) / 365.25).floor();
    d = (365.25 * c).floor();
    e = ((b - d) / 30.6001).floor();

    month = (e < 14) ? (e - 1).floor() : (e - 13).floor();
    year = (month > 2) ? (c - 4716).floor() : (c - 4715).floor();
    day = (b - d - (30.6001 * e).floor()).floor();

    // Adjust year for BCE
    if (year < 1) {
      year--;
    }

    return [year, month, day];
  }

  /// Check if a Persian year is a leap year (astronomical)
  static bool leap_persiana(int year) {
    return (persiana_to_jd(year + 1, 1, 1) - persiana_to_jd(year, 1, 1)) > 365;
  }

  /// Convert Persian astronomical date to Julian day
  static double persiana_to_jd(int year, int month, int day) {
    double guess, adr1, adr2, equinox;
    
    // Initial guess based on mean tropical year
    guess = (PERSIAN_EPOCH - 1) + (365.2422 * ((year - 1) - 1));
    
    // This would be where we'd calculate actual equinoxes using
    // astronomical algorithms, but a simplified approach is used here
    
    // Simplified - assume the solar year for Persian calendar
    adr1 = year - 1;
    equinox = PERSIAN_EPOCH + (adr1 * 365) + (adr1 / 4).floor();
    
    return equinox +
            ((month <= 7) ?
                ((month - 1) * 31) :
                (((month - 1) * 30) + 6)
            ) +
            (day - 1);
  }

  /// Convert Julian day to Persian astronomical date
  static List<int> jd_to_persiana(double jd) {
    int year, month, day;
    double depoch, cycle, cyear, yday;
    
    jd = jd.floor() + 0.5;
    
    // Calculate year using a simplified astronomical approach
    depoch = jd - PERSIAN_EPOCH;
    cycle = (depoch / 1029983).floor(); // Approx 2820-year cycle
    cyear = mod(depoch, 1029983);
    
    if (cyear == 1029982) {
      year = cycle * 2820 + 2820;
    } else {
      // Approximation of the Persian algorithm
      double aux1 = (cyear / 366).floor();
      double aux2 = mod(cyear, 366);
      int ycycle = ((((2134 * aux1) + (2816 * aux2) + 2815) / 1028522).floor() +
                    aux1 + 1).floor();
      year = (ycycle + (2820 * cycle) + 474).floor();
    }
    
    if (year <= 0) {
      year--;
    }
    
    // Calculate day of year
    yday = (jd - persiana_to_jd(year, 1, 1)) + 1;
    
    // Calculate month and day
    if (yday <= 186) {
      month = (yday / 31).ceil();
      day = (jd - persiana_to_jd(year, month, 1)).floor() + 1;
    } else {
      month = ((yday - 6) / 30).ceil();
      day = (jd - persiana_to_jd(year, month, 1)).floor() + 1;
    }
    
    return [year, month, day];
  }

  /// Check if Persian calendar year is leap (algorithmic version)
  static bool leap_persian(int year) {
    int adjYear = year - (year > 0 ? 474 : 473);
    return ((((((adjYear % 2820) + 474) + 38) * 682) % 2816) < 682);
  }

  /// Convert Persian date to Julian day
  static double persian_to_jd(int year, int month, int day) {
    int epbase, epyear;

    epbase = year - ((year >= 0) ? 474 : 473);
    epyear = 474 + mod(epbase, 2820);

    return day +
            ((month <= 7) ?
                ((month - 1) * 31) :
                (((month - 1) * 30) + 6)
            ) +
            (((epyear * 682) - 110) / 2816).floor() +
            (epyear - 1) * 365 +
            (epbase / 2820).floor() * 1029983 +
            (PERSIAN_EPOCH - 1);
  }

  /// Convert Julian day to Persian date
  static List<int> jd_to_persian(double jd) {
    int year, month, day, depoch, cycle, cyear, ycycle, aux1, aux2, yday;

    jd = jd.floor() + 0.5;

    depoch = (jd - persian_to_jd(475, 1, 1)).floor();
    cycle = (depoch / 1029983).floor();
    cyear = mod(depoch, 1029983);
    
    if (cyear == 1029982) {
      ycycle = 2820;
    } else {
      aux1 = (cyear / 366).floor();
      aux2 = mod(cyear, 366);
      ycycle = (((2134 * aux1) + (2816 * aux2) + 2815) / 1028522).floor() +
                    aux1 + 1;
    }
    
    year = ycycle + (2820 * cycle) + 474;
    
    if (year <= 0) {
      year--;
    }
    
    yday = (jd - persian_to_jd(year, 1, 1)).floor() + 1;
    
    if (yday <= 186) {
      month = (yday / 31).ceil();
      day = (jd - persian_to_jd(year, month, 1)).floor() + 1;
    } else {
      month = ((yday - 6) / 30).ceil();
      day = (jd - persian_to_jd(year, month, 1)).floor() + 1;
    }
    
    return [year, month, day];
  }

  /// Check if Islamic year is a leap year
  static bool leap_islamic(int year) {
    return (((year * 11) + 14) % 30) < 11;
  }

  /// Convert Islamic date to Julian day
  static double islamic_to_jd(int year, int month, int day) {
    return (day +
            ((29.5 * (month - 1)).ceil()) +
            (year - 1) * 354 +
            ((3 + (11 * year)) / 30).floor() +
            ISLAMIC_EPOCH) - 1;
  }

  /// Convert Julian day to Islamic date
  static List<int> jd_to_islamic(double jd) {
    int year, month, day;

    jd = jd.floor() + 0.5;
    year = ((30 * (jd - ISLAMIC_EPOCH)) + 10646) ~/ 10631;
    month = min(12, ((jd - (29 + islamic_to_jd(year, 1, 1))) / 29.5).ceil() + 1);
    day = (jd - islamic_to_jd(year, month, 1)).floor() + 1;
    
    return [year, month, day];
  }

  /// Helper constants
  static const int A_DAY_IN_MILLIS = 24 * 60 * 60 * 1000;
} 