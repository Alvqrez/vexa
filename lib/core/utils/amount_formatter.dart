/// Splits a raw amount string (e.g. "1234.5") into formatted integer and
/// decimal parts for display (e.g. integer: "1,234", decimal: ".50").
({String integer, String decimal}) splitAmount(String raw) {
  if (raw.isEmpty) return (integer: '0', decimal: '.00');

  String intPart;
  String decPart;

  if (raw.contains('.')) {
    final idx = raw.indexOf('.');
    intPart = raw.substring(0, idx).isEmpty ? '0' : raw.substring(0, idx);
    final d = raw.substring(idx + 1);
    if (d.isEmpty) {
      decPart = '.';
    } else if (d.length == 1) {
      decPart = '.${d}0';
    } else {
      decPart = '.$d';
    }
  } else {
    intPart = raw;
    decPart = '.00';
  }

  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }

  return (integer: buf.toString(), decimal: decPart);
}
