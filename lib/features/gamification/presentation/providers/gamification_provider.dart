import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/streak.dart';
import '../../domain/models/achievement.dart';
import '../../../home/presentation/providers/home_provider.dart';

// ── Streak ────────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<Streak> {
  StreakNotifier() : super(Streak.initial);

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
  }

  void recordTransaction() {
    recordActivity();
    state = state.copyWith(lastTransactionDate: DateTime.now());
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, Streak>(
  (ref) => StreakNotifier(),
);

// ── Achievements ──────────────────────────────────────────────────────────────

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  AchievementsNotifier(this.ref) : super(Achievements.all);

  final Ref ref;

  void checkAndUnlock() {
    final transactions = ref.read(transactionsProvider);
    final streak = ref.read(streakProvider);

    final updates = <Achievement>[];

    for (final a in state) {
      if (a.isUnlocked) {
        updates.add(a);
        continue;
      }

      final shouldUnlock = switch (a.id) {
        'first_transaction' => transactions.isNotEmpty,
        'five_transactions' => transactions.length >= 5,
        'twenty_transactions' => transactions.length >= 20,
        'streak_7' => streak.currentStreak >= 7,
        'streak_30' => streak.currentStreak >= 30,
        _ => false,
      };

      updates.add(shouldUnlock ? a.unlock() : a);
    }

    state = updates;
  }

  void unlockById(String id) {
    state = state.map((a) => a.id == id ? a.unlock() : a).toList();
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, List<Achievement>>(
  (ref) => AchievementsNotifier(ref),
);

final unlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  return ref.watch(achievementsProvider).where((a) => a.isUnlocked).toList();
});

final lockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  return ref.watch(achievementsProvider).where((a) => !a.isUnlocked).toList();
});

final totalXpProvider = Provider<int>((ref) {
  return ref
      .watch(unlockedAchievementsProvider)
      .fold(0, (sum, a) => sum + a.xpReward);
});
