import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_goal.dart';

class GoalsNotifier extends StateNotifier<List<FinancialGoal>> {
  GoalsNotifier() : super(_initial);

  static final _initial = [
    FinancialGoal(
      id: '1',
      title: 'Fondo de emergencia',
      icon: Icons.shield_outlined,
      color: const Color(0xFF1A7A9A),
      current: 1200,
      target: 5000,
      deadline: DateTime(2025, 12, 31),
    ),
    FinancialGoal(
      id: '2',
      title: 'Vacaciones Europa',
      icon: Icons.flight_outlined,
      color: const Color(0xFFCE93D8),
      current: 650,
      target: 2500,
      deadline: DateTime(2026, 6, 30),
    ),
    FinancialGoal(
      id: '3',
      title: 'Laptop nueva',
      icon: Icons.laptop_outlined,
      color: const Color(0xFF64B5F6),
      current: 980,
      target: 1500,
      deadline: DateTime(2026, 3, 31),
    ),
  ];

  void add(FinancialGoal goal) {
    state = [...state, goal];
  }

  void addProgress(String id, double amount) {
    state = state.map((g) {
      if (g.id != id) return g;
      final newCurrent = (g.current + amount).clamp(0, g.target).toDouble();
      return g.copyWith(
        current: newCurrent,
        completed: newCurrent >= g.target,
      );
    }).toList();
  }

  void remove(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<FinancialGoal>>(
  (ref) => GoalsNotifier(),
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
