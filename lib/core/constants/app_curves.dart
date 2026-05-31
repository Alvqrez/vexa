import 'package:flutter/material.dart';

abstract final class AppCurves {
  // Spring physics — primary interactions (matches cubic-bezier(0.32, 0.72, 0, 1))
  static const Cubic spring = Cubic(0.32, 0.72, 0.00, 1.00);

  // Gentle deceleration — scroll entry, fade reveals
  static const Cubic gentle = Cubic(0.25, 0.46, 0.45, 0.94);

  // Overshoot subtle — icon state changes
  static const Cubic pop = Cubic(0.34, 1.36, 0.64, 1.00);

  // Snappy exit — elements leaving screen
  static const Cubic exit = Cubic(0.55, 0.00, 1.00, 0.45);

  // Number counter — weighted deceleration
  static const Cubic counter = Cubic(0.16, 1.00, 0.30, 1.00);
}
