class PersianConvert {
  static const double persianEpoch = 1948320.5;
  static const List<String> persianWeekdays = [
    "Yekshanbeh",
    "Doshanbeh",
    "Seshhanbeh",
    "Chaharshanbeh",
    "Panjshanbeh",
    "Jomeh",
    "Shanbeh"
  ];

  static const double tropicalYear = 365.242189;

  static double mod(double a, double b) {
    return a - (b * (a / b).floor());
  }

  static double equinox(int year, int season) {
    // Placeholder approximation for March equinox (season == 0)
    // Based on Jean Meeus approximation (not highly accurate)
    return gregorianToJd(year, 3, 20) + 0.5;
  }

  static double deltaT(int year) {
    // Simple approximation of Delta T based on historical trend
    return 68.0 + (year - 2000) * 0.6; // in seconds
  }

  static double equationOfTime(double jed) {
    // Very rough dummy equation of time model: returns zero
    return 0.0;
  }

  static List<int> jdToGregorian(double jd) {
    double wjd = (jd + 0.5).floorToDouble();
    double depoch = wjd - 1721425.5;
    double quadricent = (depoch / 146097).floorToDouble();
    double dqc = mod(depoch, 146097);
    double cent = (dqc / 36524).floorToDouble();
    double dcent = mod(dqc, 36524);
    double quad = (dcent / 1461).floorToDouble();
    double dquad = mod(dcent, 1461);
    double yindex = (dquad / 365).floorToDouble();
    int year = (quadricent * 400 + cent * 100 + quad * 4 + yindex).toInt();
    if (!(cent == 4 || yindex == 4)) {
      year++;
    }
    double yearday = wjd - gregorianToJd(year, 1, 1);
    int leapadj = (wjd < gregorianToJd(year, 3, 1))
        ? 0
        : (leapGregorian(year) ? 1 : 2);
    int month = (((yearday + leapadj) * 12 + 373) / 367).floor();
    int day = (wjd - gregorianToJd(year, month, 1)).toInt() + 1;
    return [year, month, day];
  }

  static double gregorianToJd(int year, int month, int day) {
    const double GREGORIAN_EPOCH = 1721425.5;
    return (GREGORIAN_EPOCH - 1) +
        365 * (year - 1) +
        ((year - 1) / 4).floor() -
        ((year - 1) / 100).floor() +
        ((year - 1) / 400).floor() +
        (((367 * month) - 362) / 12).floor() +
        ((month <= 2)
            ? 0
            : (leapGregorian(year) ? -1 : -2)) +
        day;
  }

  static bool leapGregorian(int year) {
    return (year % 4 == 0) && (!(year % 100 == 0 && year % 400 != 0));
  }

  static double tehranEquinox(int year) {
    double equJED = equinox(year, 0);
    double equJD = equJED - (deltaT(year) / (24 * 60 * 60));
    double equAPP = equJD + equationOfTime(equJED);
    double dtTehran = (52 + 30 / 60.0) / 360.0;
    return equAPP + dtTehran;
  }

  static double tehranEquinoxJD(int year) {
    return tehranEquinox(year).floorToDouble();
  }

  static List persianaYear(double jd) {
    int guess = jdToGregorian(jd)[0] - 2;
    double lasteq = tehranEquinoxJD(guess);
    while (lasteq > jd) {
      guess--;
      lasteq = tehranEquinoxJD(guess);
    }
    double nexteq = lasteq - 1;
    while (!(lasteq <= jd && jd < nexteq)) {
      lasteq = nexteq;
      guess++;
      nexteq = tehranEquinoxJD(guess);
    }
    int adr = ((lasteq - persianEpoch) / tropicalYear).round() + 1;
    return [adr, lasteq];
  }

  static List<int> jdToPersiana(double jd) {
    jd = jd.floorToDouble() + 0.5;
    List adr = persianaYear(jd);
    int year = adr[0];
    double equinox = adr[1];
    int yday = (jd.floor() - persianaToJd(year, 1, 1)).toInt() + 1;
    int month = (yday <= 186) ? ((yday / 31.0).ceil()) : (((yday - 6) / 30.0).ceil());
    int day = (jd.floor() - persianaToJd(year, month, 1)).toInt() + 1;
    return [year, month, day];
  }

  static double persianaToJd(int year, int month, int day) {
    double guess = (persianEpoch - 1) + (tropicalYear * ((year - 1) - 1));
    List adr = [year - 1, 0];
    while (adr[0] < year) {
      adr = persianaYear(guess);
      guess = adr[1] + (tropicalYear + 2);
    }
    double equinox = adr[1];
    double jd = equinox +
        ((month <= 7) ? ((month - 1) * 31) : ((month - 1) * 30 + 6)) +
        (day - 1);
    return jd;
  }

  static bool leapPersiana(int year) {
    return persianaToJd(year + 1, 1, 1) - persianaToJd(year, 1, 1) > 365;
  }

  static bool leapPersian(int year) {
    return ((((year - ((year > 0) ? 474 : 473)) % 2820 + 474 + 38) * 682) % 2816) < 682;
  }

  static double persianToJd(int year, int month, int day) {
    int epbase = year - ((year >= 0) ? 474 : 473);
    int epyear = 474 + mod(epbase.toDouble(), 2820).toInt();
    return day +
        ((month <= 7) ? ((month - 1) * 31) : ((month - 1) * 30 + 6)) +
        ((epyear * 682 - 110) / 2816).floor() +
        (epyear - 1) * 365 +
        (epbase ~/ 2820) * 1029983 +
        (persianEpoch - 1);
  }

  static List<int> jdToPersian(double jd) {
    jd = jd.floorToDouble() + 0.5;
    double depoch = jd - persianToJd(475, 1, 1);
    int cycle = (depoch / 1029983).floor();
    double cyear = mod(depoch, 1029983);
    int ycycle;
    if (cyear == 1029982) {
      ycycle = 2820;
    } else {
      int aux1 = (cyear / 366).floor();
      int aux2 = mod(cyear, 366).toInt();
      ycycle = ((2134 * aux1 + 2816 * aux2 + 2815) / 1028522).floor() + aux1 + 1;
    }
    int year = ycycle + (2820 * cycle) + 474;
    if (year <= 0) year--;
    int yday = (jd - persianToJd(year, 1, 1)).toInt() + 1;
    int month = (yday <= 186) ? ((yday / 31.0).ceil()) : (((yday - 6) / 30.0).ceil());
    int day = (jd - persianToJd(year, month, 1)).toInt() + 1;
    return [year, month, day];
  }
}