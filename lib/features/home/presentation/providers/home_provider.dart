import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';

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
    balance: 2340.20,
    color: Color(0xFF1565C0),
    icon: AccountIcon.bank,
  ),
  const Account(
    id: '2',
    name: 'Nu',
    balance: 1280.50,
    color: Color(0xFF820AD1),
    icon: AccountIcon.creditCard,
  ),
  const Account(
    id: '3',
    name: 'Cartera',
    balance: 1199.80,
    color: Color(0xFF00D68F),
    icon: AccountIcon.wallet,
  ),
];

// ── Isar converters ───────────────────────────────────────────────────────────

IsarAccount _accountToIsar(Account a) => IsarAccount()
  ..accountId = a.id
  ..name = a.name
  ..balance = a.balance
  ..colorValue = a.color.toARGB32()
  ..iconStr = a.icon.name;

Account _isarToAccount(IsarAccount ia) => Account(
      id: ia.accountId,
      name: ia.name,
      balance: ia.balance,
      color: Color(ia.colorValue),
      icon: AccountIcon.values.firstWhere(
        (i) => i.name == ia.iconStr,
        orElse: () => AccountIcon.bank,
      ),
    );

IsarTransaction _txToIsar(Transaction t) => IsarTransaction()
  ..txId = t.id
  ..merchant = t.merchant
  ..amount = t.amount
  ..typeStr = t.type.name
  ..categoryStr = t.category.name
  ..date = t.date
  ..accountId = t.accountId
  ..note = t.note
  ..tags = List.from(t.tags);

Transaction _isarToTx(IsarTransaction it) => Transaction(
      id: it.txId,
      merchant: it.merchant,
      amount: it.amount,
      type: TransactionType.values.firstWhere(
        (t) => t.name == it.typeStr,
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (c) => c.name == it.categoryStr,
        orElse: () => TransactionCategory.other,
      ),
      date: it.date,
      accountId: it.accountId,
      note: it.note,
      tags: List.from(it.tags),
    );

// ── Notifiers ─────────────────────────────────────────────────────────────────

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier(this._isar) : super(_mockAccounts) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarAccounts.where().findAll();
    if (_isLoaded) return; // don't overwrite if mutations happened before load
    if (records.isEmpty) {
      await _isar.writeTxn(() => _isar.isarAccounts
          .putAll(state.map(_accountToIsar).toList()));
    } else {
      state = records.map(_isarToAccount).toList();
    }
    _isLoaded = true;
  }

  // Full replace — safe because accounts are few.
  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarAccounts.clear();
        await _isar.isarAccounts
            .putAll(state.map(_accountToIsar).toList());
      });

  void correctBalance(String accountId, double newBalance) {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == accountId) a.copyWith(balance: newBalance) else a,
    ];
    _persistAll();
  }

  void adjustBalance(String accountId, double delta) {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == accountId)
          a.copyWith(balance: a.balance + delta)
        else
          a,
    ];
    _persistAll();
  }

  void reorder(int oldIndex, int newIndex) {
    _isLoaded = true;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _persistAll();
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) => AccountsNotifier(ref.watch(isarProvider)),
);

// ── Transactions notifier ─────────────────────────────────────────────────────

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._ref, this._isar) : super(_initial) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarTransactions.where().findAll();
    if (_isLoaded) return; // don't overwrite if user added transactions first
    if (records.isEmpty) {
      // First launch: seed DB with current state (not _initial,
      // in case the user already added transactions before _load completed).
      await _isar.writeTxn(() => _isar.isarTransactions
          .putAll(state.map(_txToIsar).toList()));
    } else {
      state = records.map(_isarToTx).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    _isLoaded = true;
  }

  // Full replace: clear all records, re-insert current state.
  // Avoids unique-constraint failures from auto-increment IDs.
  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarTransactions.clear();
        await _isar.isarTransactions
            .putAll(state.map(_txToIsar).toList());
      });

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
    _isLoaded = true;
    state = [t, ...state];
    if (t.accountId != null) {
      final delta = t.isIncome ? t.amount : -t.amount;
      _ref.read(accountsProvider.notifier).adjustBalance(t.accountId!, delta);
    }
    // Single-record insert — no existing record with this txId, no conflict.
    _isar.writeTxn(() => _isar.isarTransactions.put(_txToIsar(t)));
  }

  void update(Transaction updated, Transaction original) {
    _isLoaded = true;
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    if (original.accountId != null) {
      final reverse = original.isIncome ? -original.amount : original.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(original.accountId!, reverse);
    }
    if (updated.accountId != null) {
      final delta = updated.isIncome ? updated.amount : -updated.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(updated.accountId!, delta);
    }
    _persistAll();
  }

  void delete(Transaction t) {
    _isLoaded = true;
    state = state.where((tx) => tx.id != t.id).toList();
    if (t.accountId != null) {
      final reverse = t.isIncome ? -t.amount : t.amount;
      _ref
          .read(accountsProvider.notifier)
          .adjustBalance(t.accountId!, reverse);
    }
    _isar.writeTxn(() => _isar.isarTransactions.deleteByTxId(t.id));
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(ref, ref.watch(isarProvider)),
);

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedCategoryProvider =
    StateProvider<TransactionCategory?>((ref) => null);

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  final filtered =
      selected == null ? all : all.where((t) => t.category == selected).toList();
  return [...filtered]..sort((a, b) => b.date.compareTo(a.date));
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

/// Updated by [totalBudgetLimitProvider] in budget_provider.dart.
/// Use [budgetSpendingRatioProvider] from budget_provider for full accuracy.
/// Kept here for widgets that only import home_provider.
final spendingRatioProvider = Provider<double>((ref) {
  // Deferred import to avoid circular dependency — budget_provider imports
  // home_provider, not the other way. We keep a safe fallback.
  final expenses = ref.watch(monthlyExpensesProvider);
  const fallbackLimit = 800.0; // sum of initial budget categories
  return (expenses / fallbackLimit).clamp(0.0, 1.0);
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

// ── Monthly spending trend (last 6 months) ────────────────────────────────────

final monthlySpendingTrendProvider =
    Provider<List<({String label, double value})>>((ref) {
  final now = DateTime.now();
  final transactions = ref.watch(transactionsProvider);

  return List.generate(6, (i) {
    final monthsAgo = 5 - i;
    var year = now.year;
    var month = now.month - monthsAgo;
    while (month <= 0) {
      month += 12;
      year--;
    }
    // Short month label: capitalise first letter
    final raw = _monthAbbr(month);
    final spending = transactions
        .where((t) =>
            !t.isIncome && t.date.month == month && t.date.year == year)
        .fold(0.0, (sum, t) => sum + t.amount);
    return (label: raw, value: spending);
  });
});

String _monthAbbr(int month) {
  const abbrs = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  return abbrs[(month - 1).clamp(0, 11)];
}

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
  final accounts = ref.watch(accountsProvider);
  final account = accounts.firstWhere(
    (a) => a.id == accountId,
    orElse: () => accounts.first,
  );
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
