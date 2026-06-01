import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
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
  GoalsNotifier(this._isar) : super(_initial) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarFinancialGoals.where().findAll();
    if (_isLoaded) return;
    if (records.isEmpty) {
      await _isar.writeTxn(() => _isar.isarFinancialGoals
          .putAll(state.map(_goalToIsar).toList()));
    } else {
      state = records.map(_isarToGoal).toList();
    }
    _isLoaded = true;
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarFinancialGoals.clear();
        await _isar.isarFinancialGoals
            .putAll(state.map(_goalToIsar).toList());
      });

  static final _initial = [
    FinancialGoal(
      id: '1',
      title: 'Fondo de emergencia',
      icon: Icons.shield_outlined,
      color: const Color(0xFF1A7A9A),
      current: 1200,
      target: 5000,
      deadline: DateTime(2026, 12, 31),
    ),
    FinancialGoal(
      id: '2',
      title: 'Vacaciones Europa',
      icon: Icons.flight_outlined,
      color: const Color(0xFFCE93D8),
      current: 650,
      target: 2500,
      deadline: DateTime(2026, 12, 30),
    ),
    FinancialGoal(
      id: '3',
      title: 'Laptop nueva',
      icon: Icons.laptop_outlined,
      color: const Color(0xFF64B5F6),
      current: 980,
      target: 1500,
      deadline: DateTime(2027, 3, 31),
    ),
  ];

  void add(FinancialGoal goal) {
    _isLoaded = true;
    state = [...state, goal];
    _isar.writeTxn(() => _isar.isarFinancialGoals.put(_goalToIsar(goal)));
  }

  void addProgress(String id, double amount) {
    _isLoaded = true;
    state = state.map((g) {
      if (g.id != id) return g;
      final newCurrent = (g.current + amount).clamp(0, g.target).toDouble();
      return g.copyWith(
        current: newCurrent,
        completed: newCurrent >= g.target,
      );
    }).toList();
    _persistAll();
  }

  void remove(String id) {
    _isLoaded = true;
    state = state.where((g) => g.id != id).toList();
    _isar.writeTxn(() => _isar.isarFinancialGoals.deleteByGoalId(id));
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
