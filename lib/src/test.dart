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
    deltaL = 1 + (0.0334 * dcos(W)) + (0.0007 * dcos(2 * W));
//document.debug.log.value += "deltaL = " + deltaL + "\n";

//  Sum the periodic terms for time T

    S = 0;
    for (i = j = 0; i < 24; i++) {
      S += EquinoxpTerms[j] * dcos(EquinoxpTerms[j + 1] + (EquinoxpTerms[j + 2] * T));
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
