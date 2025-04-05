class Constants {
  /*
   * date ::= yeardate time_opt timezone_opt
   * yeardate ::= year colon_opt month colon_opt day
   * year ::= sign_opt digit{4,6}
   * colon_opt ::= <empty> | ':'
   * sign ::= '+' | '-'
   * sign_opt ::=  <empty> | sign
   * month ::= digit{2}
   * day ::= digit{2}
   * time_opt ::= <empty> | (' ' | 'T') hour minutes_opt
   * minutes_opt ::= <empty> | colon_opt digit{2} seconds_opt
   * seconds_opt ::= <empty> | colon_opt digit{2} millis_opt
   * micros_opt ::= <empty> | ('.' | ',') digit+
   * timezone_opt ::= <empty> | space_opt timezone
   * space_opt ::= ' ' | <empty>
   * timezone ::= 'z' | 'Z' | sign digit{2} timezonemins_opt
   * timezonemins_opt ::= <empty> | colon_opt digit{2}
   */
  static final RegExp parseFormat = RegExp(
    r'^([+-]?\d{4,6})-?(\d\d)-?(\d\d)' // Day part.
    r'(?:[ T](\d\d)(?::?(\d\d)(?::?(\d\d)(?:[.,](\d+))?)?)?' // Time part.
    r'( ?[zZ]| ?([-+])(\d\d)(?::?(\d\d))?)?)?$',
  );
}