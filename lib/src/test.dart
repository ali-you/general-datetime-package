import 'dart:math' as math;

class Test {

  static double PERSIAN_EPOCH = 1948320.5;
  static double TropicalYear = 365.24219878;           // Mean solar tropical year

  static double persianToJd(int year, int month, int day) {
    var adr, equinox, guess, jd;
    guess = (PERSIAN_EPOCH - 1) + (TropicalYear * ((year - 1) - 1));
    adr = [year - 1, 0];
    while (adr[0] < year){
      adr = persianYear(guess);
      guess = adr[1] + (TropicalYear + 2);
    }
    equinox = adr[1];
    jd = equinox +
        ((month <= 7) ?
        ((month - 1) * 31) :
        (((month - 1) * 30) + 6)
        ) +
        (day - 1);
    return jd;
  }

  static List persianYear(double jd){
    var guess = jd_to_gregorian(jd)[0] - 2,
        lasteq, nexteq, adr;

    lasteq = tehran_equinox_jd(guess);
    while (lasteq > jd) {
      guess--;
      lasteq = tehran_equinox_jd(guess);
    }
    nexteq = lasteq - 1;
    while (!((lasteq <= jd) && (jd < nexteq))) {
      lasteq = nexteq;
      guess++;
      nexteq = tehran_equinox_jd(guess);
    }
    adr = ((lasteq - PERSIAN_EPOCH) / TropicalYear).round + 1;

    return [adr, lasteq];
  }

  static tehran_equinox_jd(year)
  {
    double ep;
    int epg;

    ep = tehran_equinox(year);
    epg = ep.floor();

    return epg;
  }

  static double tehran_equinox(year)
  {
    var equJED, equJD, equAPP, equTehran, dtTehran;

    equJED = equinox(year, 0);

    equJD = equJED - (deltat(year) / (24 * 60 * 60));

    equAPP = equJD + equationOfTime(equJED);


    dtTehran = (52 + (30 / 60.0) + (0 / (60.0 * 60.0))) / 360;
    equTehran = equAPP + dtTehran;

    return equTehran;
  }

  static double J2000 = 2451545.0;
  static double JulianCentury     = 36525.0;
  static double JulianMillennium  = (JulianCentury * 10);

  static equationOfTime(jd)
  {
    var alpha, deltaPsi, E, epsilon, L0, tau;

    tau = (jd - J2000) / JulianMillennium;
//document.debug.log.value += "equationOfTime.  tau = " + tau + "\n";
    L0 = 280.4664567 + (360007.6982779 * tau) +
        (0.03032028 * tau * tau) +
        ((tau * tau * tau) / 49931) +
        (-((tau * tau * tau * tau) / 15300)) +
        (-((tau * tau * tau * tau * tau) / 2000000));
//document.debug.log.value += "L0 = " + L0 + "\n";
    L0 = fixangle(L0);
//document.debug.log.value += "L0 = " + L0 + "\n";
    alpha = sunpos(jd)[10];
//document.debug.log.value += "alpha = " + alpha + "\n";
    deltaPsi = nutation(jd)[0];
//document.debug.log.value += "deltaPsi = " + deltaPsi + "\n";
    epsilon = obliqeq(jd) + nutation(jd)[1];
//document.debug.log.value += "epsilon = " + epsilon + "\n";
    E = L0 + (-0.0057183) + (-alpha) + (deltaPsi * math.cos(epsilon));
//document.debug.log.value += "E = " + E + "\n";
    E = E - 20.0 * (((E / 20.0) as double).floor());
//document.debug.log.value += "Efixed = " + E + "\n";
    E = E / (24 * 60);
//document.debug.log.value += "Eday = " + E + "\n";

    return E;
  }

  static List deltaTtab =
      [121, 112, 103, 95, 88, 82, 77, 72, 68, 63, 60, 56, 53, 51, 48, 46,
      44, 42, 40, 38, 35, 33, 31, 29, 26, 24, 22, 20, 18, 16, 14, 12,
      11, 10, 9, 8, 7, 7, 7, 7, 7, 7, 8, 8, 9, 9, 9, 9, 9, 10, 10, 10,
      10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13,
      13, 14, 14, 14, 14, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16,
      16, 16, 15, 15, 14, 13, 13.1, 12.5, 12.2, 12, 12, 12, 12, 12, 12,
      11.9, 11.6, 11, 10.2, 9.2, 8.2, 7.1, 6.2, 5.6, 5.4, 5.3, 5.4, 5.6,
      5.9, 6.2, 6.5, 6.8, 7.1, 7.3, 7.5, 7.6, 7.7, 7.3, 6.2, 5.2, 2.7,
      1.4, -1.2, -2.8, -3.8, -4.8, -5.5, -5.3, -5.6, -5.7, -5.9, -6,
      -6.3, -6.5, -6.2, -4.7, -2.8, -0.1, 2.6, 5.3, 7.7, 10.4, 13.3, 16,
      18.2, 20.2, 21.1, 22.4, 23.5, 23.8, 24.3, 24, 23.9, 23.9, 23.7,
      24, 24.3, 25.3, 26.2, 27.3, 28.2, 29.1, 30, 30.7, 31.4, 32.2,
      33.1, 34, 35, 36.5, 38.3, 40.2, 42.2, 44.5, 46.5, 48.5, 50.5,
      52.2, 53.8, 54.9, 55.8, 56.9, 58.3, 60, 61.6, 63, 65, 66.6];

  static deltat(year) {
    var dt, f, i, t;

    if ((year >= 1620) && (year <= 2000)) {
      i = (((year - 1620) / 2) as double).floor();
      f = ((year - 1620) / 2) - i;  /* Fractional part of year */
      dt = deltaTtab[i] + ((deltaTtab[i + 1] - deltaTtab[i]) * f);
    } else {
      t = (year - 2000) / 100;
      if (year < 948) {
        dt = 2177 + (497 * t) + (44.1 * t * t);
      } else {
        dt = 102 + (102 * t) + (25.3 * t * t);
        if ((year > 2000) && (year < 2100)) {
          dt += 0.37 * (year - 2100);
        }
      }
    }
    return dt;
  }

  static List JDE0tab1000 = [
  [1721139.29189, 365242.13740,  0.06134,  0.00111, -0.00071],
  [1721233.25401, 365241.72562, -0.05323,  0.00907,  0.00025],
  [1721325.70455, 365242.49558, -0.11677, -0.00297,  0.00074],
  [1721414.39987, 365242.88257, -0.00769, -0.00933, -0.00006]
  ];

  static List JDE0tab2000 = [
  [2451623.80984, 365242.37404,  0.05169, -0.00411, -0.00057],
  [2451716.56767, 365241.62603,  0.00325,  0.00888, -0.00030],
  [2451810.21715, 365242.01767, -0.11575,  0.00337,  0.00078],
  [2451900.05952, 365242.74049, -0.06223, -0.00823,  0.00032]
  ];

  static List EquinoxpTerms =
      [485, 324.96,   1934.136,
      203, 337.23,  32964.467,
      199, 342.08,     20.186,
      182,  27.85, 445267.112,
      156,  73.14,  45036.886,
      136, 171.52,  22518.443,
      77, 222.54,  65928.934,
      74, 296.72,   3034.906,
      70, 243.58,   9037.513,
      58, 119.81,  33718.147,
      52, 297.17,    150.678,
      50,  21.02,   2281.226,
      45, 247.54,  29929.562,
      44, 325.15,  31555.956,
      29,  60.93,   4443.417,
      18, 155.12,  67555.328,
      17, 288.79,   4562.452,
      16, 198.04,  62894.029,
      14, 199.76,  31436.921,
      12,  95.39,  14577.848,
      12, 287.11,  31931.756,
      12, 320.81,  34777.259,
      9, 227.73,   1222.114,
      8,  15.45,  16859.074]
  ;

  static equinox(year, which)
  {
    var deltaL, i, j, JDE0, JDE, JDE0tab, S, T, W, Y;

/*  Initialise terms for mean equinox and solstices.  We
        have two sets: one for years prior to 1000 and a second
        for subsequent years.  */

    if (year < 1000) {
      JDE0tab = JDE0tab1000;
      Y = year / 1000;
    } else {
      JDE0tab = JDE0tab2000;
      Y = (year - 2000) / 1000;
    }

    JDE0 =  JDE0tab[which][0] +
        (JDE0tab[which][1] * Y) +
        (JDE0tab[which][2] * Y * Y) +
        (JDE0tab[which][3] * Y * Y * Y) +
        (JDE0tab[which][4] * Y * Y * Y * Y);

//document.debug.log.value += "JDE0 = " + JDE0 + "\n";

    T = (JDE0 - 2451545.0) / 36525;
//document.debug.log.value += "T = " + T + "\n";
    W = (35999.373 * T) - 2.47;
//document.debug.log.value += "W = " + W + "\n";
    deltaL = 1 + (0.0334 * math.cos(W)) + (0.0007 * math.cos(2 * W));
//document.debug.log.value += "deltaL = " + deltaL + "\n";

//  Sum the periodic terms for time T

    S = 0;
    for (i = j = 0; i < 24; i++) {
      S += EquinoxpTerms[j] * math.cos(EquinoxpTerms[j + 1] + (EquinoxpTerms[j + 2] * T));
      j += 3;
    }

//document.debug.log.value += "S = " + S + "\n";
//document.debug.log.value += "Corr = " + ((S * 0.00001) / deltaL) + "\n";

    JDE = JDE0 + ((S * 0.00001) / deltaL);

    return JDE;
  }

  static bool leapPersian(int jy) {
    return persianToJd(jy + 1, 1, 1) - persianToJd(jy, 1, 1) > 365;
  }
}
