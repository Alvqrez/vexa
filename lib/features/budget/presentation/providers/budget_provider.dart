import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarBudgetItem _budgetToIsar(BudgetItem b) => IsarBudgetItem()
  ..budgetId = b.id
  ..name = b.name
  ..iconCodePoint = b.icon.codePoint
  ..colorValue = b.color.toARGB32()
  ..limit = b.limit
  ..categoryStr = b.category?.name;

BudgetItem _isarToBudget(IsarBudgetItem ib) => BudgetItem(
      id: ib.budgetId,
      name: ib.name,
      icon: IconData(ib.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(ib.colorValue),
      limit: ib.limit,
      category: ib.categoryStr != null
          ? TransactionCategory.values.firstWhere(
              (c) => c.name == ib.categoryStr,
              orElse: () => TransactionCategory.other,
            )
          : null,
    );

// ── Budget item model ─────────────────────────────────────────────────────────

class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.category,
    required this.limit,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  /// If non-null, spent amount is drawn from matching transactions.
  final TransactionCategory? category;
  final double limit;

  double get surface => 0; // placeholder — use withValues in UI

  BudgetItem copyWith({double? limit}) => BudgetItem(
        id: id,
        name: name,
        icon: icon,
        color: color,
        category: category,
        limit: limit ?? this.limit,
      );
}

// ── Budget item with real spent amount ────────────────────────────────────────

class BudgetItemWithSpent {
  const BudgetItemWithSpent({required this.item, required this.spent});

  final BudgetItem item;
  final double spent;

  double get ratio =>
      item.limit == 0 ? 0.0 : (spent / item.limit).clamp(0.0, 1.0);
  double get remaining => item.limit == 0 ? 0.0 : item.limit - spent;
  bool get isWarning => item.limit == 0 ? false : ratio >= 0.80;
  bool get isOver => item.limit == 0 ? false : spent > item.limit;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<List<BudgetItem>> {
  BudgetNotifier(this._isar) : super(const []) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarBudgetItems.where().findAll();
    if (_isLoaded) return;
    if (records.isNotEmpty) {
      state = records.map(_isarToBudget).toList();
    }
    _isLoaded = true;
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarBudgetItems.clear();
        await _isar.isarBudgetItems
            .putAll(state.map(_budgetToIsar).toList());
      });


  void add(BudgetItem item) {
    _isLoaded = true;
    state = [...state, item];
    _isar.writeTxn(() => _isar.isarBudgetItems.put(_budgetToIsar(item)));
  }

  void update(BudgetItem item) {
    _isLoaded = true;
    state = [
      for (final b in state) if (b.id == item.id) item else b,
    ];
    _persistAll();
  }

  void updateLimit(String id, double newLimit) {
    _isLoaded = true;
    state = [
      for (final b in state)
        if (b.id == id) b.copyWith(limit: newLimit) else b,
    ];
    _persistAll();
  }

  void delete(String id) {
    _isLoaded = true;
    state = state.where((b) => b.id != id).toList();
    _isar.writeTxn(() => _isar.isarBudgetItems.deleteByBudgetId(id));
  }
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, List<BudgetItem>>(
  (ref) => BudgetNotifier(ref.watch(isarProvider)),
);

// ── Budget items with real spent amounts from transactions ────────────────────

final budgetWithSpentProvider = Provider<List<BudgetItemWithSpent>>((ref) {
  final items = ref.watch(budgetProvider);
  final breakdown = ref.watch(categoryBreakdownProvider);
  return items.map((item) {
    final spent =
        item.category != null ? (breakdown[item.category] ?? 0.0) : 0.0;
    return BudgetItemWithSpent(item: item, spent: spent);
  }).toList();
});

/// Total budget limit across all categories.
final totalBudgetLimitProvider = Provider<double>((ref) {
  return ref
      .watch(budgetProvider)
      .where((b) => b.limit > 0)
      .fold(0.0, (sum, b) => sum + b.limit);
});

/// Total spent this month across all budget categories.
final totalBudgetSpentProvider = Provider<double>((ref) {
  return ref
      .watch(budgetWithSpentProvider)
      .fold(0.0, (sum, b) => sum + b.spent);
});

/// Accurate spending ratio: total monthly expenses / total budget limit.
final budgetSpendingRatioProvider = Provider<double>((ref) {
  final expenses = ref.watch(monthlyExpensesProvider);
  final totalLimit = ref.watch(totalBudgetLimitProvider);
  if (totalLimit <= 0) return 0;
  return (expenses / totalLimit).clamp(0.0, 1.0);
});
