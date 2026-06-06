import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/streak.dart';
import '../../../../core/data/local_prefs_service.dart';

// ── Streak ────────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<Streak> {
  StreakNotifier() : super(Streak.initial) {
    _load();
  }

  Future<void> _load() async {
    final current = await LocalPrefsService.getInt('streak_current');
    final longest = await LocalPrefsService.getInt('streak_longest');
    final activeStr = await LocalPrefsService.getString('streak_last_active');
    final txStr = await LocalPrefsService.getString('streak_last_tx');

    state = Streak(
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate:
          activeStr != null ? DateTime.parse(activeStr) : DateTime(2000),
      lastTransactionDate:
          txStr != null ? DateTime.parse(txStr) : DateTime(2000),
    );
  }

  Future<void> _save() async {
    await LocalPrefsService.setInt('streak_current', state.currentStreak);
    await LocalPrefsService.setInt('streak_longest', state.longestStreak);
    await LocalPrefsService.setString(
        'streak_last_active', state.lastActiveDate.toIso8601String());
    await LocalPrefsService.setString(
        'streak_last_tx', state.lastTransactionDate.toIso8601String());
  }

  void recordActivity() {
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
    _save();
  }

  void recordTransaction() {
    recordActivity();
    state = state.copyWith(lastTransactionDate: DateTime.now());
    _save();
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
