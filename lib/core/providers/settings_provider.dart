import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle: when false, all UI animations are disabled (reduced motion).
final animationsEnabledProvider = StateProvider<bool>((ref) => true);

/// When true, sensitive monetary values are hidden behind asterisks.
final hideAmountsProvider = StateProvider<bool>((ref) => false);

/// Currently selected currency symbol.
final currencySymbolProvider = StateProvider<String>((ref) => '\$');
