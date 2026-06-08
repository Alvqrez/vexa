import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget_provider.dart';

enum BudgetNotificationType { warning, critical, overspent }

class BudgetNotification {
  const BudgetNotification({
    required this.id,
    required this.budgetId,
    required this.budgetName,
    required this.type,
    required this.spent,
    required this.limit,
    required this.timestamp,
    this.dismissed = false,
  });

  final String id;
  final String budgetId;
  final String budgetName;
  final BudgetNotificationType type;
  final double spent;
  final double limit;
  final DateTime timestamp;
  final bool dismissed;

  double get percentage => (spent / limit * 100).clamp(0, 999);

  String get message {
    switch (type) {
      case BudgetNotificationType.warning:
        return 'Acercándote al límite de presupuesto';
      case BudgetNotificationType.critical:
        return 'Has alcanzado el límite de presupuesto';
      case BudgetNotificationType.overspent:
        return 'Has superado el límite de presupuesto';
    }
  }

  BudgetNotification copyWith({bool? dismissed}) => BudgetNotification(
        id: id,
        budgetId: budgetId,
        budgetName: budgetName,
        type: type,
        spent: spent,
        limit: limit,
        timestamp: timestamp,
        dismissed: dismissed ?? this.dismissed,
      );
}

class BudgetNotificationsNotifier extends StateNotifier<List<BudgetNotification>> {
  BudgetNotificationsNotifier(this._ref) : super([]) {
    _initializeMonitoring();
  }

  final Ref _ref;
  final Map<String, BudgetNotificationType> _lastNotified = {};

  void _initializeMonitoring() {
    // Monitorear cambios en budgets y transacciones
    _ref.listen(budgetWithSpentProvider, (previous, next) {
      _checkBudgetThresholds(next);
    });
  }

  void _checkBudgetThresholds(List<BudgetItemWithSpent> budgets) {
    for (final budget in budgets) {
      final ratio = budget.ratio;
      final budgetId = budget.item.id;

      // Determinar tipo de notificación según el gasto
      BudgetNotificationType? notificationType;
      if (budget.isOver) {
        notificationType = BudgetNotificationType.overspent;
      } else if (ratio >= 1.0) {
        notificationType = BudgetNotificationType.critical;
      } else if (ratio >= 0.75) {
        notificationType = BudgetNotificationType.warning;
      }

      // Solo notificar si:
      // 1. Hay un nuevo tipo de notificación
      // 2. Es diferente al último notificado
      // 3. No está en la lista de notificaciones activas
      if (notificationType != null) {
        final lastType = _lastNotified[budgetId];
        final alreadyNotified = state.any((n) =>
            n.budgetId == budgetId &&
            n.type == notificationType &&
            !n.dismissed);

        if (lastType != notificationType && !alreadyNotified) {
          _addNotification(budget.item, notificationType, budget.spent);
          _lastNotified[budgetId] = notificationType;
        }
      } else {
        // Reset si el budget vuelve a estar ok
        _lastNotified.remove(budgetId);
      }
    }
  }

  void _addNotification(
    BudgetItem budget,
    BudgetNotificationType type,
    double spent,
  ) {
    final notification = BudgetNotification(
      id: '${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
      budgetId: budget.id,
      budgetName: budget.name,
      type: type,
      spent: spent,
      limit: budget.limit,
      timestamp: DateTime.now(),
    );
    state = [notification, ...state];
  }

  void dismiss(String notificationId) {
    state = [
      for (final n in state)
        if (n.id == notificationId) n.copyWith(dismissed: true) else n,
    ];
  }

  void clearDismissed() {
    state = state.where((n) => !n.dismissed).toList();
  }
}

final budgetNotificationsProvider =
    StateNotifierProvider<BudgetNotificationsNotifier, List<BudgetNotification>>(
  (ref) => BudgetNotificationsNotifier(ref),
);

final activeBudgetNotificationsProvider =
    Provider<List<BudgetNotification>>((ref) {
  return ref.watch(budgetNotificationsProvider).where((n) => !n.dismissed).toList();
});
