import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

/// Gateway de feedback háptico que respeta el ajuste "Vibración y hápticos".
/// Cuando [enabled] es false, cada llamada es un no-op. El flag se sincroniza
/// desde LocalPrefsService al arrancar (splash) y desde el toggle de Ajustes.
///
/// Replica la API de [HapticFeedback] para que los call sites se lean igual.
/// Este archivo re-exporta `services.dart`, de modo que los archivos que solo
/// lo importaban para hápticos siguen teniendo el resto de la API a mano.
abstract final class Haptics {
  static bool enabled = true;

  static void selectionClick() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void vibrate() {
    if (enabled) HapticFeedback.vibrate();
  }
}
