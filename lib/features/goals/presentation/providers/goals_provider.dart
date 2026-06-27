import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/financial_goal.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarFinancialGoal _goalToIsar(FinancialGoal g) => IsarFinancialGoal()
  ..goalId = g.id
  ..title = g.title
  ..iconCodePoint = g.icon.codePoint
  ..colorValue = g.color.toARGB32()
  ..current = g.current
  ..target = g.target
  ..deadline = g.deadline
  ..completed = g.isCompleted;

FinancialGoal _isarToGoal(IsarFinancialGoal ig) => FinancialGoal(
      id: ig.goalId,
      title: ig.title,
      icon: IconData(ig.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(ig.colorValue),
      current: ig.current,
      target: ig.target,
      deadline: ig.deadline,
      completed: ig.completed,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class GoalsNotifier extends StateNotifier<List<FinancialGoal>> {
  GoalsNotifier(this._isar) : super(const []) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final records = await _isar.isarFinancialGoals.where().findAll();
    if (records.isNotEmpty) {
      state = records.map(_isarToGoal).toList();
    }
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarFinancialGoals.clear();
        await _isar.isarFinancialGoals
            .putAll(state.map(_goalToIsar).toList());
      });


  Future<void> add(FinancialGoal goal) async {
    _isLoaded = true;
    state = [...state, goal];
    await _isar.writeTxn(() => _isar.isarFinancialGoals.put(_goalToIsar(goal)));
  }

  Future<void> addProgress(String id, double amount) async {
    _isLoaded = true;
    state = state.map((g) {
      if (g.id != id) return g;
      final newCurrent = (g.current + amount).clamp(0, g.target).toDouble();
      return g.copyWith(
        current: newCurrent,
        completed: newCurrent >= g.target,
      );
    }).toList();
    await _persistAll();
  }

  Future<void> update(FinancialGoal updated) async {
    _isLoaded = true;
    state = [for (final g in state) if (g.id == updated.id) updated else g];
    await _persistAll();
  }

  Future<void> remove(String id) async {
    _isLoaded = true;
    state = state.where((g) => g.id != id).toList();
    await _isar.writeTxn(() => _isar.isarFinancialGoals.deleteByGoalId(id));
  }

  Future<void> reset() async {
    _isLoaded = true;
    state = const [];
    await _isar.writeTxn(() => _isar.isarFinancialGoals.clear());
  }

  /// Datos de ejemplo (solo debug).
  Future<void> seed() async {
    if (kReleaseMode) return;
    _isLoaded = true;
    final now = DateTime.now();
    DateTime inMonths(int m) => DateTime(now.year, now.month + m, 1);
    state = [
      FinancialGoal(
        id: 'seed_goal_1',
        title: 'Fondo de emergencia',
        icon: Icons.shield_outlined,
        color: AppColors.emerald,
        current: 1800,
        target: 6000,
        deadline: inMonths(8),
      ),
      FinancialGoal(
        id: 'seed_goal_2',
        title: 'Vacaciones',
        icon: Icons.beach_access_outlined,
        color: AppColors.warning,
        current: 650,
        target: 1500,
        deadline: inMonths(4),
      ),
      FinancialGoal(
        id: 'seed_goal_3',
        title: 'Laptop nueva',
        icon: Icons.laptop_mac_rounded,
        color: AppColors.petroleum,
        current: 1200,
        target: 1200,
        deadline: inMonths(1),
        completed: true,
      ),
    ];
    await _persistAll();
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>(
  (ref) => GoalsNotifier(ref.watch(isarProvider)),
);

final activeGoalsProvider = Provider<List<FinancialGoal>>((ref) {
  return ref.watch(goalsProvider).where((g) => !g.isCompleted).toList();
});

final completedGoalsProvider = Provider<List<FinancialGoal>>((ref) {
  return ref.watch(goalsProvider).where((g) => g.isCompleted).toList();
});

final totalSavedProvider = Provider<double>((ref) {
  return ref.watch(goalsProvider).fold(0.0, (sum, g) => sum + g.current);
});

// How much of total savings goals is covered by current balance
final goalsProgressSummaryProvider = Provider<(int active, int completed, double totalSaved)>((ref) {
  final goals = ref.watch(goalsProvider);
  final active = goals.where((g) => !g.isCompleted).length;
  final completed = goals.where((g) => g.isCompleted).length;
  final totalSaved = goals.fold(0.0, (sum, g) => sum + g.current);
  return (active, completed, totalSaved);
});
