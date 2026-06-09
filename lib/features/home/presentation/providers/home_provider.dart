import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../../domain/models/transfer_record.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// Maps legacy TransactionCategory enum names to WalletCategory IDs.
const _kLegacyToWcId = {
  'food': 'wc1',
  'transport': 'wc2',
  'shopping': 'wc3',
  'entertainment': 'wc4',
  'health': 'wc5',
  'other': 'wc6',
  'salary': 'wc7',
};

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
  ..categoryStr = t.category
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
      category: _kLegacyToWcId[it.categoryStr] ?? it.categoryStr,
      date: it.date,
      accountId: it.accountId,
      note: it.note,
      tags: List.from(it.tags),
    );

// ── Notifiers ─────────────────────────────────────────────────────────────────

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier(this._isar) : super(const []) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final records = await _isar.isarAccounts.where().findAll();
    List<Account> accounts;
    if (records.isNotEmpty) {
      accounts = records.map(_isarToAccount).toList();
      // Migration: wallet_default must always be named "Cartera" regardless
      // of the name it was initially created with (e.g. user's first name).
      bool renamed = false;
      accounts = accounts.map((a) {
        if (a.id == 'wallet_default' && a.name != 'Cartera') {
          renamed = true;
          return a.copyWith(name: 'Cartera');
        }
        return a;
      }).toList();
      if (renamed) {
        // clear() + putAll is required — putAll alone with new IsarAccount()
        // objects (id = autoIncrement) would insert duplicates and throw.
        await _isar.writeTxn(() async {
          await _isar.isarAccounts.clear();
          await _isar.isarAccounts
              .putAll(accounts.map(_accountToIsar).toList());
        });
      }
    } else {
      final defaultWallet = Account(
        id: 'wallet_default',
        name: 'Cartera',
        balance: 0,
        color: const Color(0xFF00D68F),
        icon: AccountIcon.wallet,
      );
      const defaultSavings = Account(
        id: 'savings_default',
        name: 'Ahorro',
        balance: 0,
        color: Color(0xFFF59E0B),
        icon: AccountIcon.savings,
        isSavings: true,
      );
      accounts = [defaultWallet, defaultSavings];
      await _isar.writeTxn(() =>
          _isar.isarAccounts.putAll(accounts.map(_accountToIsar).toList()));
      // Mark the savings account in prefs
      await LocalPrefsService.setBool('account_savings_savings_default', true);
    }
    // Load isSavings flags from prefs (avoids Isar schema change)
    final withFlags = await Future.wait(accounts.map((a) async {
      final isSavings = await LocalPrefsService.getBool('account_savings_${a.id}');
      return isSavings ? a.copyWith(isSavings: true) : a;
    }));
    state = withFlags;
  }

  Future<void> seed() async {
    if (kReleaseMode) return;
    _isLoaded = true;
    state = _mockAccounts;
    await _isar.writeTxn(() async {
      await _isar.isarAccounts.clear();
      await _isar.isarAccounts.putAll(state.map(_accountToIsar).toList());
    });
  }

  // Full replace — safe because accounts are few.
  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarAccounts.clear();
        await _isar.isarAccounts
            .putAll(state.map(_accountToIsar).toList());
      });

  Future<void> correctBalance(String accountId, double newBalance) async {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == accountId) a.copyWith(balance: newBalance) else a,
    ];
    await _persistAll();
  }

  Future<void> adjustBalance(String accountId, double delta) async {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == accountId)
          a.copyWith(balance: a.balance + delta)
        else
          a,
    ];
    await _persistAll();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    _isLoaded = true;
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _persistAll();
  }

  Future<void> addAccount(Account account) async {
    _isLoaded = true;
    state = [...state, account];
    if (account.isSavings) {
      await LocalPrefsService.setBool('account_savings_${account.id}', true);
    }
    await _persistAll();
  }

  Future<void> updateAccount(Account account) async {
    _isLoaded = true;
    state = [for (final a in state) if (a.id == account.id) account else a];
    await LocalPrefsService.setBool(
        'account_savings_${account.id}', account.isSavings);
    await _persistAll();
  }

  Future<void> deleteAccount(String accountId) async {
    _isLoaded = true;
    state = state.where((a) => a.id != accountId).toList();
    await _persistAll();
  }

  Future<void> markAsSavings(String accountId, bool isSavings) async {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == accountId) a.copyWith(isSavings: isSavings) else a,
    ];
    await LocalPrefsService.setBool('account_savings_$accountId', isSavings);
  }

  Future<void> reset() async {
    _isLoaded = true;
    state = const [
      Account(
        id: 'wallet_default',
        name: 'Cartera',
        balance: 0,
        color: Color(0xFF00D68F),
        icon: AccountIcon.wallet,
      ),
      Account(
        id: 'savings_default',
        name: 'Ahorro',
        balance: 0,
        color: Color(0xFFF59E0B),
        icon: AccountIcon.savings,
        isSavings: true,
      ),
    ];
    await _isar.writeTxn(() async {
      await _isar.isarAccounts.clear();
      await _isar.isarAccounts.putAll(state.map(_accountToIsar).toList());
    });
    await LocalPrefsService.setBool('account_savings_savings_default', true);
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) => AccountsNotifier(ref.watch(isarProvider)),
);

// ── Transactions notifier ─────────────────────────────────────────────────────

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._ref, this._isar) : super(const []) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final records = await _isar.isarTransactions.where().findAll();
      if (records.isNotEmpty) {
        state = records.map(_isarToTx).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      debugPrint('TransactionsNotifier._load: failed to load transactions: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<void> seed() async {
    if (kReleaseMode) return;
    _isLoaded = true;
    state = _initial;
    await _isar.writeTxn(() async {
      await _isar.isarTransactions.clear();
      await _isar.isarTransactions.putAll(state.map(_txToIsar).toList());
    });
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
      category: 'wc4', // Entretenimiento
      date: DateTime.now().subtract(const Duration(hours: 2)),
      accountId: '1',
    ),
    Transaction(
      id: '2',
      merchant: 'Nómina Mayo',
      amount: 1800.00,
      type: TransactionType.income,
      category: 'wc7', // Salario
      date: DateTime.now().subtract(const Duration(days: 1)),
      accountId: '1',
    ),
    Transaction(
      id: '3',
      merchant: 'Mercadona',
      amount: 67.40,
      type: TransactionType.expense,
      category: 'wc1', // Comida
      date: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      accountId: '3',
    ),
    Transaction(
      id: '4',
      merchant: 'Glovo',
      amount: 24.80,
      type: TransactionType.expense,
      category: 'wc1', // Comida
      date: DateTime.now().subtract(const Duration(days: 2)),
      accountId: '3',
    ),
    Transaction(
      id: '5',
      merchant: 'Metro Madrid',
      amount: 12.50,
      type: TransactionType.expense,
      category: 'wc2', // Transporte
      date: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      accountId: '2',
    ),
    Transaction(
      id: '6',
      merchant: 'Zara',
      amount: 89.95,
      type: TransactionType.expense,
      category: 'wc3', // Compras
      date: DateTime.now().subtract(const Duration(days: 3)),
      accountId: '2',
    ),
    Transaction(
      id: '7',
      merchant: 'Clínica Sanitas',
      amount: 45.00,
      type: TransactionType.expense,
      category: 'wc5', // Salud
      date: DateTime.now().subtract(const Duration(days: 4)),
      accountId: '1',
    ),
  ];

  Future<void> add(Transaction t) async {
    _isLoaded = true;
    try {
      // Insert into database first, then update state (fail-safe order)
      await _isar.writeTxn(() => _isar.isarTransactions.put(_txToIsar(t)));

      // Only update state after DB write succeeds
      state = [t, ...state];

      // Update balance after state sync
      if (t.accountId != null) {
        final delta = t.isIncome ? t.amount : -t.amount;
        try {
          await _ref.read(accountsProvider.notifier).adjustBalance(t.accountId!, delta);
        } catch (e) {
          debugPrint('TransactionsNotifier.add: balance adjustment failed: $e');
          // Transaction was added but balance wasn't updated — notify user
          // (UI should show warning or trigger manual balance correction)
        }
      }
    } catch (e) {
      debugPrint('TransactionsNotifier.add: failed to add transaction: $e');
      // Revert state change if DB write failed
      state = state.where((tx) => tx.id != t.id).toList();
      rethrow;
    }
  }

  Future<void> update(Transaction updated, Transaction original) async {
    _isLoaded = true;
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    if (original.accountId != null) {
      final reverse = original.isIncome ? -original.amount : original.amount;
      await _ref
          .read(accountsProvider.notifier)
          .adjustBalance(original.accountId!, reverse);
    }
    if (updated.accountId != null) {
      final delta = updated.isIncome ? updated.amount : -updated.amount;
      await _ref
          .read(accountsProvider.notifier)
          .adjustBalance(updated.accountId!, delta);
    }
    await _persistAll();
  }

  Future<void> delete(Transaction t) async {
    _isLoaded = true;
    state = state.where((tx) => tx.id != t.id).toList();
    if (t.accountId != null) {
      final reverse = t.isIncome ? -t.amount : t.amount;
      await _ref
          .read(accountsProvider.notifier)
          .adjustBalance(t.accountId!, reverse);
    }
    await _isar.writeTxn(() => _isar.isarTransactions.deleteByTxId(t.id));
  }

  Future<void> reset() async {
    _isLoaded = true;
    state = [];
    await _isar.writeTxn(() => _isar.isarTransactions.clear());
    await _ref.read(accountsProvider.notifier).reset();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(ref, ref.watch(isarProvider)),
);

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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
    if (t.isIncome && t.date.month == now.month && t.date.year == now.year) return sum + t.amount;
    return sum;
  });
});

final monthlyExpensesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return ref.watch(transactionsProvider).fold(0.0, (sum, t) {
    if (!t.isIncome && t.date.month == now.month && t.date.year == now.year) return sum + t.amount;
    return sum;
  });
});

// ── Savings transfers tracker ─────────────────────────────────────────────────

class SavingsTransfersNotifier extends StateNotifier<double> {
  SavingsTransfersNotifier() : super(0.0) {
    _load().catchError((e) => debugPrint('SavingsTransfersNotifier._load failed: $e'));
  }

  String get _key {
    final n = DateTime.now();
    return 'savings_${n.year}_${n.month}';
  }

  Future<void> _load() async {
    try {
      state = await LocalPrefsService.getDouble(_key);
    } catch (e) {
      debugPrint('SavingsTransfersNotifier._load: error loading value: $e');
      state = 0.0;
    }
  }

  Future<void> addTransfer(double amount) async {
    state = (state + amount).clamp(0.0, double.infinity);
    await LocalPrefsService.setDouble(_key, state);
  }

  Future<void> removeTransfer(double amount) async {
    state = (state - amount).clamp(0.0, double.infinity);
    await LocalPrefsService.setDouble(_key, state);
  }
}

final savingsTransfersProvider =
    StateNotifierProvider<SavingsTransfersNotifier, double>(
  (ref) => SavingsTransfersNotifier(),
);

final monthlySavingsProvider = Provider<double>((ref) {
  return ref.watch(savingsTransfersProvider);
});

/// Percentage change in income vs the previous month.
/// Returns null when there is no previous-month data to compare against.
final monthOverMonthProvider = Provider<double?>((ref) {
  final now = DateTime.now();
  final transactions = ref.watch(transactionsProvider);
  final thisIncome = ref.watch(monthlyIncomeProvider);

  var lastYear = now.year;
  var lastMonth = now.month - 1;
  if (lastMonth == 0) {
    lastMonth = 12;
    lastYear--;
  }

  final lastIncome = transactions
      .where((t) =>
          t.isIncome &&
          t.date.year == lastYear &&
          t.date.month == lastMonth)
      .fold(0.0, (s, t) => s + t.amount);

  if (lastIncome == 0) return null;
  return ((thisIncome - lastIncome) / lastIncome) * 100;
});

/// Fallback spending ratio for widgets that only import home_provider.
/// Use [budgetSpendingRatioProvider] from budget_provider for full accuracy
/// when a budget has been configured.
final spendingRatioProvider = Provider<double>((ref) => 0.0);

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Analysis month selector ───────────────────────────────────────────────────

final selectedAnalysisMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final analysisIncomeProvider = Provider<double>((ref) {
  final m = ref.watch(selectedAnalysisMonthProvider);
  return ref.watch(transactionsProvider).fold(0.0, (sum, t) {
    if (t.isIncome && t.date.month == m.month && t.date.year == m.year) return sum + t.amount;
    return sum;
  });
});

final analysisExpensesProvider = Provider<double>((ref) {
  final m = ref.watch(selectedAnalysisMonthProvider);
  return ref.watch(transactionsProvider).fold(0.0, (sum, t) {
    if (!t.isIncome && t.date.month == m.month && t.date.year == m.year) return sum + t.amount;
    return sum;
  });
});

final analysisCategoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final m = ref.watch(selectedAnalysisMonthProvider);
  final transactions = ref
      .watch(transactionsProvider)
      .where((t) => !t.isIncome && t.date.month == m.month && t.date.year == m.year);
  final map = <String, double>{};
  for (final t in transactions) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final analysisTopCategoryProvider = Provider<WalletCategory?>((ref) {
  final breakdown = ref.watch(analysisCategoryBreakdownProvider);
  if (breakdown.isEmpty) return null;
  final topId = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final cats = ref.watch(walletCategoriesProvider);
  return resolveCategory(topId, cats);
});

// ── Category breakdown ────────────────────────────────────────────────────────

final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final now = DateTime.now();
  final transactions = ref
      .watch(transactionsProvider)
      .where((t) => !t.isIncome && t.date.month == now.month && t.date.year == now.year)
      .toList();

  final map = <String, double>{};
  for (final t in transactions) {
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
});

final topCategoryProvider = Provider<WalletCategory?>((ref) {
  final breakdown = ref.watch(categoryBreakdownProvider);
  if (breakdown.isEmpty) return null;
  final topId = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final cats = ref.watch(walletCategoriesProvider);
  return resolveCategory(topId, cats);
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
  double get predictedSavings => (predictedIncome - predictedExpenses).clamp(0.0, double.infinity);
  /// Only meaningful when there is actual income data.
  bool get isOnTrack =>
      predictedIncome > 0 && predictedExpenses <= predictedIncome;
  bool get hasData => predictedIncome > 0 || predictedExpenses > 0;
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
  // Use real income only — never invent figures.
  final predictedIncome = currentIncome;

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
    orElse: () => accounts.isNotEmpty
        ? accounts.first
        : const Account(
            id: '',
            name: '',
            balance: 0,
            color: Color(0xFF00D68F),
            icon: AccountIcon.wallet,
          ),
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

// ── Transfer history ──────────────────────────────────────────────────────────

class TransferHistoryNotifier extends StateNotifier<List<TransferRecord>> {
  TransferHistoryNotifier() : super(const []) {
    _load().catchError((e) => debugPrint('TransferHistoryNotifier._load failed: $e'));
  }

  Future<void> _load() async {
    try {
      state = await TransferRecord.loadAll();
    } catch (e) {
      debugPrint('TransferHistoryNotifier._load: error loading transfers: $e');
      state = const [];
    }
  }

  Future<void> add(TransferRecord record) async {
    state = [record, ...state];
    await TransferRecord.saveAll(state);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await TransferRecord.saveAll(state);
  }
}

final transferHistoryProvider =
    StateNotifierProvider<TransferHistoryNotifier, List<TransferRecord>>(
  (ref) => TransferHistoryNotifier(),
);
