import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global toggle: when false, all UI animations are disabled (reduced motion).
final animationsEnabledProvider = StateProvider<bool>((ref) => true);
