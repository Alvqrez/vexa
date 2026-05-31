import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';

// ── Account stats ─────────────────────────────────────────────────────────────

class AccountStats {
  const AccountStats({
    required this.account,
    required this.income,
    required this.expenses,
    required this.transactions,
  });

  final Account account;
  final double income;
  final double expenses;
  final List<Transaction> transactions;

  double get balance => account.balance;
  double get net => income - expenses;
}

// ── Accounts notifier ─────────────────────────────────────────────────────────

final _mockAccounts = [
  const Account(
    id: '1',
    name: 'BBVA',
    balance: 2_340.20,
    color: Color(0xFF1565C0),
    icon: AccountIcon.bank,
  ),
  const Account(
    id: '2',
    name: 'Nu',
    balance: 1_280.50,
    color: Color(0xFF820AD1),
    icon: AccountIcon.creditCard,
  ),
  const Account(
    id: '3',
    name: 'Cartera',
    balance: 1_199.80,
    color: Color(0xFF00D68F),
    icon: AccountIcon.wallet,
  ),
];

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier() : super(_mockAccounts);

  void correctBalance(String accountId, double newBalance) {
    state = [
      for (final a in state)
        if (a.id == accountId) a.copyWith(balance: newBalance) else a,
    ];
  }

  void adjustBalance(String accountId, double delta) {
    state = [
      for (final a in state)
        if (a.id == accountId)
          a.copyWith(balance: a.balance + delta)
        else
          a,
    ];
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) => AccountsNotifier(),
);

// ── Transactions notifier ─────────────────────────────────────────────────────

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._ref) : super(_initial);

  final Ref _ref;

  static final _initial = [
    Transaction(
      id: '1',
      merchant: 'Spotify Premium',
      amount: 9.99,
      type: TransactionType.expense,
      category: TransactionCategory.entertainment,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      accountId: '1',
    ),
    Transaction(
      id: '2',
      merchant: 'Nómina Mayo',
      amount: 1800.00,
      type: TransactionType.income,
      category: TransactionCategory.salary,
      date: DateTime.now().subtract(const Duration(days: 1)),
      accountId: '1',
    ),
    Transaction(
      id: '3',
      merchant: 'Mercadona',
      amount: 67.40,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      accountId: '3',
    ),
    Transaction(
      id: '4',
      merchant: 'Glovo',
      amount: 24.80,
      type: TransactionType.expense,
      category: TransactionCategory.food,
      date: DateTime.now().subtract(const Duration(days: 2)),
      accountId: '3',
    ),
    Transaction(
      id: '5',
      merchant: 'Metro Madrid',
      amount: 12.50,
      type: TransactionType.expense,
      category: TransactionCategory.transport,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      accountId: '2',
    ),
    Transaction(
      id: '6',
      merchant: 'Zara',
      amount: 89.95,
      type: TransactionType.expense,
      category: TransactionCategory.shopping,
      date: DateTime.now().subtract(const Duration(days: 3)),
      accountId: '2',
    ),
    Transaction(
      id: '7',
      merchant: 'Clínica Sanitas',
      amount: 45.00,
      type: TransactionType.expense,
      category: TransactionCategory.health,
      date: DateTime.now().subtract(const Duration(days: 4)),
      accountId: '1',
    ),
  ];

  void add(Transaction t) {
    state = [t, ...state];
    if (t.accountId != null) {
      final delta = t.isIncome ? t.amount : -t.amount;
      _ref.read(accountsProvider.notifier).adjustBalance(t.accountId!, delta);
    }
  }

  /// Updates an existing transaction and adjusts account balances accordingly.
  void update(Transaction updated, Transaction original) {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    // Reverse original effect
    if (original.accountId != null) {
      final reverse = original.isIncome ? -original.amount : original.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(original.accountId!, reverse);
    }
    // Apply new effect
    if (updated.accountId != null) {
      final delta = updated.isIncome ? updated.amount : -updated.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(updated.accountId!, delta);
    }
  }

  void delete(Transaction t) {
    state = state.where((tx) => tx.id != t.id).toList();
    if (t.accountId != null) {
      final reverse = t.isIncome ? -t.amount : t.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(t.accountId!, reverse);
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(ref),
);

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedCategoryProvider =
    StateProvider<TransactionCategory?>((ref) => null);

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  if (selected == null) return all;
  return all.where((t) => t.category == selected).toList();
});

final totalBalanceProvider = Provider<double>((ref) {
  return ref
      .watch(accountsProvider)
      .fold(0.0, (sum, a) => sum + a.balance);
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref.watch(transactionsProvider).fold(0.0, (sum, t) {
    if (t.isIncome && t.date.month == now.month) return sum + t.amount;
    return sum;
  });
});

final monthlyExpensesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref.watch(transactionsProvider).fold(0.0, (sum, t) {
    if (!t.isIncome && t.date.month == now.month) return sum + t.amount;
    return sum;
  });
});

final monthlySavingsProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  return income - expenses;
});

final spendingRatioProvider = Provider<double>((ref) {
  final expenses = ref.watch(monthlyExpensesProvider);
  const limit = 2000.0;
  return (expenses / limit).clamp(0.0, 1.0);
});

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Category breakdown ────────────────────────────────────────────────────────

final categoryBreakdownProvider =
    Provider<Map<TransactionCategory, double>>((ref) {
  final now = DateTime.now();
  final transactions = ref
      .watch(transactionsProvider)
      .where((t) => !t.isIncome && t.date.month == now.month)
      .toList();

  final map = <TransactionCategory, double>{};
  for (final t in transactions) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final topCategoryProvider = Provider<TransactionCategory?>((ref) {
  final breakdown = ref.watch(categoryBreakdownProvider);
  if (breakdown.isEmpty) return null;
  return breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
});

// ── Financial prediction ──────────────────────────────────────────────────────

class MonthlyPrediction {
  const MonthlyPrediction({
    required this.predictedExpenses,
    required this.predictedIncome,
    required this.daysLeft,
    required this.dailyAvgExpense,
  });

  final double predictedExpenses;
  final double predictedIncome;
  final int daysLeft;
  final double dailyAvgExpense;

  double get predictedBalance => predictedIncome - predictedExpenses;
  double get predictedSavings => predictedIncome - predictedExpenses;
  bool get isOnTrack => predictedExpenses <= predictedIncome;
}

final predictionProvider = Provider<MonthlyPrediction>((ref) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysElapsed = now.day;
  final daysLeft = daysInMonth - daysElapsed;

  final currentExpenses = ref.watch(monthlyExpensesProvider);
  final currentIncome = ref.watch(monthlyIncomeProvider);

  final dailyAvg = daysElapsed > 0 ? currentExpenses / daysElapsed : 0.0;
  final predictedExpenses = currentExpenses + (dailyAvg * daysLeft);
  final predictedIncome =
      currentIncome > 0 ? currentIncome : currentExpenses * 1.3;

  return MonthlyPrediction(
    predictedExpenses: predictedExpenses,
    predictedIncome: predictedIncome,
    daysLeft: daysLeft,
    dailyAvgExpense: dailyAvg,
  );
});

// ── Per-account stats ─────────────────────────────────────────────────────────

final accountStatsProvider =
    Provider.family<AccountStats, String>((ref, accountId) {
  final account =
      ref.watch(accountsProvider).firstWhere((a) => a.id == accountId);
  final transactions = ref
      .watch(transactionsProvider)
      .where((t) => t.accountId == accountId)
      .toList();

  final income = transactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);
  final expenses = transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  return AccountStats(
    account: account,
    income: income,
    expenses: expenses,
    transactions: transactions,
  );
});
