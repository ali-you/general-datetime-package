import 'dart:math';

class AstroConstants {
  static const double J2000 = 2451545.0;
  static const double JulianCentury = 36525.0;
  static const double JulianMillennium = JulianCentury * 10;
  static const double AstronomicalUnit = 149597870.0;
  static const double TropicalYear = 365.24219878;
}

class AstroUtils {
  static double degreesToRadians(double degrees) => degrees * (pi / 180.0);
  static double radiansToDegrees(double radians) => radians * (180.0 / pi);

  static double fixAngle(double angle) =>
      angle - 360.0 * (angle / 360.0).floor();

  static double fixAngleRad(double angle) =>
      angle - (2 * pi) * (angle / (2 * pi)).floor();

  static double sinDeg(double degrees) => sin(degreesToRadians(degrees));
  static double cosDeg(double degrees) => cos(degreesToRadians(degrees));

  static double mod(double a, double b) => a - b * (a / b).floor();

  static double amod(double a, double b) => mod(a - 1, b) + 1;
}

class PersianAstronomy {
  static const double persianEpoch = 1948320.5;

  static double persianToJD(int year, int month, int day) {
    int epBase = year - (year >= 0 ? 474 : 473);
    int epYear = 474 + epBase % 2820;

    return day +
        (month <= 7 ? ((month - 1) * 31) : (((month - 1) * 30) + 6)) +
        ((epYear * 682 - 110) ~/ 2816) +
        (epYear - 1) * 365 +
        (epBase ~/ 2820) * 1029983 +
        (persianEpoch - 1);
  }

  static List<int> jdToPersian(double jd) {
    jd = (jd + 0.5).floorToDouble();
    int depoch = (jd - persianToJD(475, 1, 1)).toInt();
    int cycle = depoch ~/ 1029983;
    int cyear = depoch % 1029983;

    int ycycle;
    if (cyear == 1029982) {
      ycycle = 2820;
    } else {
      int aux1 = cyear ~/ 366;
      int aux2 = cyear % 366;
      ycycle = ((2134 * aux1 + 2816 * aux2 + 2815) ~/ 1028522) + aux1 + 1;
    }

    int year = ycycle + 2820 * cycle + 474;
    if (year <= 0) year--;

    int yday = (jd - persianToJD(year, 1, 1)).toInt() + 1;
    int month = (yday <= 186) ? ((yday / 31).ceil()) : (((yday - 6) / 30).ceil());
    int day = (jd - persianToJD(year, month, 1)).toInt() + 1;

    return [year, month, day];
  }

  static bool isLeapPersian(int year) {
    return ((((year - (year > 0 ? 474 : 473)) % 2820 + 474) + 38) * 682 % 2816) < 682;
  }
}
