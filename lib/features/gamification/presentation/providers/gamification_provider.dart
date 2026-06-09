import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/streak.dart';
import '../../../../core/data/local_prefs_service.dart';

// ── Streak ────────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<Streak> {
  StreakNotifier() : super(Streak.initial) {
    _load().catchError((e) => debugPrint('StreakNotifier._load failed: $e'));
  }

  Future<void> _load() async {
    try {
      final current = await LocalPrefsService.getInt('streak_current');
      final longest = await LocalPrefsService.getInt('streak_longest');
      final activeStr = await LocalPrefsService.getString('streak_last_active');
      final txStr = await LocalPrefsService.getString('streak_last_tx');

      DateTime lastActive = DateTime(2000);
      DateTime lastTx = DateTime(2000);

      if (activeStr != null) {
        try {
          lastActive = DateTime.parse(activeStr);
        } catch (e) {
          debugPrint('StreakNotifier: invalid lastActiveDate: $activeStr');
        }
      }

      if (txStr != null) {
        try {
          lastTx = DateTime.parse(txStr);
        } catch (e) {
          debugPrint('StreakNotifier: invalid lastTransactionDate: $txStr');
        }
      }

      state = Streak(
        currentStreak: current,
        longestStreak: longest,
        lastActiveDate: lastActive,
        lastTransactionDate: lastTx,
      );
    } catch (e) {
      debugPrint('StreakNotifier._load: error loading streak data: $e');
    }
  }

  Future<void> _save() async {
    await LocalPrefsService.setInt('streak_current', state.currentStreak);
    await LocalPrefsService.setInt('streak_longest', state.longestStreak);
    await LocalPrefsService.setString(
        'streak_last_active', state.lastActiveDate.toIso8601String());
    await LocalPrefsService.setString(
        'streak_last_tx', state.lastTransactionDate.toIso8601String());
  }

  Future<void> recordActivity() async {
    final now = DateTime.now();
    if (state.isActiveToday) return;

    final yesterday = now.subtract(const Duration(days: 1));
    final wasActiveYesterday = state.lastActiveDate.year == yesterday.year &&
        state.lastActiveDate.month == yesterday.month &&
        state.lastActiveDate.day == yesterday.day;

    final newStreak = wasActiveYesterday ? state.currentStreak + 1 : 1;
    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > state.longestStreak ? newStreak : state.longestStreak,
      lastActiveDate: now,
    );
    await _save();
  }

  Future<void> recordTransaction() async {
    await recordActivity();
    state = state.copyWith(lastTransactionDate: DateTime.now());
    await _save();
  }

  Future<void> reset() async {
    state = Streak.initial;
    await LocalPrefsService.setInt('streak_current', 0);
    await LocalPrefsService.setInt('streak_longest', 0);
    await LocalPrefsService.setString(
        'streak_last_active', DateTime(2000).toIso8601String());
    await LocalPrefsService.setString(
        'streak_last_tx', DateTime(2000).toIso8601String());
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, Streak>(
  (ref) => StreakNotifier(),
);
