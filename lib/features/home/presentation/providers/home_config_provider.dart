import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../domain/models/home_config.dart';

class HomeConfigNotifier extends StateNotifier<HomeConfig> {
  HomeConfigNotifier() : super(HomeConfig.defaultConfig) {
    _load();
  }

  static const _key = 'home_config_v3';

  Future<void> _load() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw != null) {
      try {
        state = HomeConfig.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    await LocalPrefsService.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> toggleVisibility(HomeSection section) async {
    final entry = state.sections.firstWhere((e) => e.section == section);
    state = state.copyWithEntry(entry.copyWith(visible: !entry.visible));
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    state = state.reordered(oldIndex, newIndex);
    await _save();
  }

  Future<void> reset() async {
    state = HomeConfig.defaultConfig;
    await _save();
  }
}

final homeConfigProvider =
    StateNotifierProvider<HomeConfigNotifier, HomeConfig>(
  (_) => HomeConfigNotifier(),
);
