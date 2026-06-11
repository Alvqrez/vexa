import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/challenge.dart';

class ChallengesNotifier extends StateNotifier<List<Challenge>> {
  ChallengesNotifier() : super(const []) {
    _load().catchError((e) => debugPrint('ChallengesNotifier._load failed: $e'));
  }

  Future<void> _load() async {
    state = await Challenge.loadAll();
  }

  Future<void> add(Challenge challenge) async {
    state = [challenge, ...state];
    await Challenge.saveAll(state);
  }

  Future<void> update(Challenge updated) async {
    state = [for (final c in state) if (c.id == updated.id) updated else c];
    await Challenge.saveAll(state);
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await Challenge.saveAll(state);
  }

  /// Marca o desmarca un día. Solo permite hoy o días pasados dentro del reto.
  Future<void> toggleDay(String id, DateTime day) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    if (target.isAfter(today)) return;

    state = state.map((c) {
      if (c.id != id || !c.isScheduled(target)) return c;
      final key = Challenge.dayKey(target);
      final days = Set<String>.from(c.completedDays);
      if (days.contains(key)) {
        days.remove(key);
      } else {
        days.add(key);
      }
      return c.copyWith(completedDays: days);
    }).toList();
    await Challenge.saveAll(state);
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<Challenge>>(
  (ref) => ChallengesNotifier(),
);

final activeChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref
      .watch(challengesProvider)
      .where((c) => !c.isArchived && !c.isFinished)
      .toList();
});

final finishedChallengesProvider = Provider<List<Challenge>>((ref) {
  return ref
      .watch(challengesProvider)
      .where((c) => !c.isArchived && c.isFinished)
      .toList();
});

/// Cuántos retos activos están pendientes de marcar hoy.
final pendingTodayProvider = Provider<int>((ref) {
  final now = DateTime.now();
  return ref
      .watch(activeChallengesProvider)
      .where((c) =>
          c.isScheduled(now) &&
          (c.frequency == ChallengeFrequency.weekly
              ? !c.isWeekDone(now)
              : !c.isDoneToday))
      .length;
});
