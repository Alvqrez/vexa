import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Injected at app startup via ProviderScope overrides in main.dart.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider not initialised'),
);
