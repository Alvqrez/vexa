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
import '../../../../core/utils/receipt_image_store.dart';
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
  ..subcategoryId = t.subcategoryId
  ..date = t.date
  ..accountId = t.accountId
  ..note = t.note
  ..tags = List.from(t.tags)
  ..imagePaths = List.from(t.imagePaths);

Transaction _isarToTx(IsarTransaction it) => Transaction(
      id: it.txId,
      merchant: it.merchant,
      amount: it.amount,
      type: TransactionType.values.firstWhere(
        (t) => t.name == it.typeStr,
        orElse: () => TransactionType.expense,
      ),
      category: _kLegacyToWcId[it.categoryStr] ?? it.categoryStr,
      subcategoryId: it.subcategoryId,
      date: it.date,
      accountId: it.accountId,
      note: it.note,
      tags: List.from(it.tags),
      imagePaths: List.from(it.imagePaths),
    );

// ── Notifiers ─────────────────────────────────────────────────────────────────

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier(this._ref, this._isar) : super(const []) {
    _load();
  }

  final Ref _ref;
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
    // Load isSavings flags from prefs (avoids Isar schema change).
    // Fallback: if no flag stored but account carries AccountIcon.savings,
    // treat it as savings and persist the flag so future loads are consistent.
    final withFlags = await Future.wait(accounts.map((a) async {
      final storedFlag =
          await LocalPrefsService.getBool('account_savings_${a.id}');
      final isSavings = storedFlag || a.icon == AccountIcon.savings;
      if (isSavings && !storedFlag) {
        await LocalPrefsService.setBool('account_savings_${a.id}', true);
      }
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

  Future<void> transfer(String fromId, String toId, double amount) async {
    _isLoaded = true;
    state = [
      for (final a in state)
        if (a.id == fromId)
          a.copyWith(balance: a.balance - amount)
        else if (a.id == toId)
          a.copyWith(balance: a.balance + amount)
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
    // Cascade: remove orphaned transactions that referenced this account.
    await _ref.read(transactionsProvider.notifier).deleteByAccountId(accountId);
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
  (ref) => AccountsNotifier(ref, ref.watch(isarProvider)),
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
    state = _buildSeed();
    await _isar.writeTxn(() async {
      await _isar.isarTransactions.clear();
      await _isar.isarTransactions.putAll(state.map(_txToIsar).toList());
    });
  }

  /// Genera ~4 meses de transacciones variadas (nómina + gastos por categoría)
  /// para poder ver con datos reales el Coach, insights, gráficas y proyección.
  /// Solo se usa en debug (ver [seed]).
  static List<Transaction> _buildSeed() {
    final now = DateTime.now();
    final txs = <Transaction>[];
    var seq = 0;
    String id() => 'seed_${seq++}';

    // Nómina mensual (últimos 4 meses), día 1.
    for (var m = 0; m < 4; m++) {
      final d = DateTime(now.year, now.month - m, 1, 9);
      if (d.isAfter(now)) continue;
      txs.add(Transaction(
        id: id(),
        merchant: 'Nómina',
        amount: 1850.00,
        type: TransactionType.income,
        category: 'wc7',
        date: d,
        accountId: '1',
      ));
    }

    // (merchant, categoryId, baseAmount, accountId)
    const templates = [
      ('Mercadona', 'wc1', 62.40, '3'),
      ('Glovo', 'wc1', 23.10, '3'),
      ('Cafetería', 'wc1', 6.80, '2'),
      ('Restaurante', 'wc1', 41.50, '2'),
      ('Metro', 'wc2', 12.50, '2'),
      ('Gasolina', 'wc2', 48.00, '1'),
      ('Uber', 'wc2', 14.30, '2'),
      ('Zara', 'wc3', 79.95, '2'),
      ('Amazon', 'wc3', 34.50, '1'),
      ('Cine', 'wc4', 18.00, '2'),
      ('Concierto', 'wc4', 55.00, '1'),
      ('Farmacia', 'wc5', 22.40, '1'),
      ('Dentista', 'wc5', 60.00, '1'),
      ('Luz', 'wc6', 54.20, '1'),
      ('Internet', 'wc6', 39.90, '1'),
    ];

    for (var m = 0; m < 4; m++) {
      for (var i = 0; i < templates.length; i++) {
        final t = templates[i];
        final day = ((3 + i * 2) % 27) + 1;
        final date = DateTime(now.year, now.month - m, day, 10 + (i % 9));
        if (date.isAfter(now)) continue;
        // Pequeña variación mensual para que las tendencias no sean planas.
        final amt = t.$3 * (1 + (m * 0.05) - 0.08);
        txs.add(Transaction(
          id: id(),
          merchant: t.$1,
          amount: double.parse(amt.toStringAsFixed(2)),
          type: TransactionType.expense,
          category: t.$2,
          date: date,
          accountId: t.$4,
        ));
      }
    }

    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

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
          _ref.read(balanceWarningProvider.notifier).state =
              'Transacción guardada, pero el saldo de la cuenta no se actualizó. Verifica el balance manualmente.';
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
    final prevState = state;
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    try {
      // Persist the record first — it's the operation most likely to fail.
      // Balances are only reconciled once the write succeeds, mirroring add()
      // and avoiding balances drifting away from a transaction that never saved.
      await _isar.writeTxn(
        () => _isar.isarTransactions.putByTxId(_txToIsar(updated)),
      );
      if (original.accountId == updated.accountId) {
        if (original.accountId != null) {
          final origEffect =
              original.isIncome ? original.amount : -original.amount;
          final updEffect =
              updated.isIncome ? updated.amount : -updated.amount;
          final delta = updEffect - origEffect;
          if (delta != 0) {
            await _ref
                .read(accountsProvider.notifier)
                .adjustBalance(original.accountId!, delta);
          }
        }
      } else {
        if (original.accountId != null) {
          final origEffect =
              original.isIncome ? original.amount : -original.amount;
          await _ref
              .read(accountsProvider.notifier)
              .adjustBalance(original.accountId!, -origEffect);
        }
        if (updated.accountId != null) {
          final updEffect =
              updated.isIncome ? updated.amount : -updated.amount;
          try {
            await _ref
                .read(accountsProvider.notifier)
                .adjustBalance(updated.accountId!, updEffect);
          } catch (e) {
            if (original.accountId != null) {
              final origEffect =
                  original.isIncome ? original.amount : -original.amount;
              await _ref
                  .read(accountsProvider.notifier)
                  .adjustBalance(original.accountId!, origEffect);
            }
            rethrow;
          }
        }
      }
    } catch (e) {
      state = prevState;
      // Best-effort: si la tx ya se había persistido pero la reconciliación de
      // balances falló, restaura el registro original para no dejar la DB con
      // el valor nuevo mientras el estado y los balances vuelven al anterior.
      try {
        await _isar.writeTxn(
          () => _isar.isarTransactions.putByTxId(_txToIsar(original)),
        );
      } catch (revertErr) {
        debugPrint('TransactionsNotifier.update: revert failed: $revertErr');
      }
      debugPrint('TransactionsNotifier.update: failed, rolled back: $e');
      rethrow;
    }
  }

  Future<void> delete(Transaction t) async {
    _isLoaded = true;
    try {
      await _isar.writeTxn(() => _isar.isarTransactions.deleteByTxId(t.id));
    } catch (e) {
      debugPrint('TransactionsNotifier.delete: Isar delete failed, state unchanged: $e');
      rethrow;
    }
    // Isar confirmed — now safe to update state and balance.
    state = state.where((tx) => tx.id != t.id).toList();
    if (t.accountId != null) {
      final reverse = t.isIncome ? -t.amount : t.amount;
      try {
        await _ref
            .read(accountsProvider.notifier)
            .adjustBalance(t.accountId!, reverse);
      } catch (e) {
        debugPrint('TransactionsNotifier.delete: balance adjustment failed: $e');
        _ref.read(balanceWarningProvider.notifier).state =
            'Transacción eliminada, pero el saldo de la cuenta no se actualizó. Verifica el balance manualmente.';
      }
    }
    // Limpieza de fotos adjuntas. No se borran al instante: el snackbar de
    // "Deshacer" puede re-insertar la transacción con sus mismas imágenes.
    if (t.imagePaths.isNotEmpty) {
      Future.delayed(const Duration(seconds: 6), () {
        final stillDeleted = !state.any((tx) => tx.id == t.id);
        if (stillDeleted) {
          ReceiptImageStore.deleteAll(t.imagePaths);
        }
      });
    }
  }

  Future<void> deleteByAccountId(String accountId) async {
    _isLoaded = true;
    final toDelete = state.where((t) => t.accountId == accountId).toList();
    if (toDelete.isEmpty) return;
    state = state.where((t) => t.accountId != accountId).toList();
    await _isar.writeTxn(() async {
      for (final t in toDelete) {
        await _isar.isarTransactions.deleteByTxId(t.id);
      }
    });
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

/// Filtro de subcategoría activo (solo aplica junto a [selectedCategoryProvider]).
final selectedSubcategoryProvider = StateProvider<String?>((ref) => null);

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref.watch(transactionsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  final selectedSub = ref.watch(selectedSubcategoryProvider);
  var filtered =
      selected == null ? all : all.where((t) => t.category == selected).toList();
  if (selected != null && selectedSub != null) {
    filtered = filtered.where((t) => t.subcategoryId == selectedSub).toList();
  }
  return filtered;
});

final totalBalanceProvider = Provider<double>((ref) {
  return ref
      .watch(accountsProvider)
      .fold(0.0, (sum, a) => sum + a.balance);
});

/// Single-pass provider: income, expenses AND category breakdown in one O(n).
/// All derived providers watch this to avoid redundant list scans.
/// [subBreakdown] agrupa gasto por categoría → subcategoría ('' = sin subcategoría).
final _monthlyStatsProvider = Provider<
    ({
      double income,
      double expenses,
      Map<String, double> breakdown,
      Map<String, Map<String, double>> subBreakdown,
    })>((ref) {
  final now = DateTime.now();
  double income = 0;
  double expenses = 0;
  final breakdown = <String, double>{};
  final subBreakdown = <String, Map<String, double>>{};
  for (final t in ref.watch(transactionsProvider)) {
    if (t.date.month == now.month && t.date.year == now.year) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expenses += t.amount;
        breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
        final subs = subBreakdown.putIfAbsent(t.category, () => {});
        final subKey = t.subcategoryId ?? '';
        subs[subKey] = (subs[subKey] ?? 0) + t.amount;
      }
    }
  }
  return (
    income: income,
    expenses: expenses,
    breakdown: breakdown,
    subBreakdown: subBreakdown,
  );
});

final monthlyIncomeProvider = Provider<double>(
  (ref) => ref.watch(_monthlyStatsProvider).income,
);

final monthlyExpensesProvider = Provider<double>(
  (ref) => ref.watch(_monthlyStatsProvider).expenses,
);

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

/// Ahorro (transferencias a cuentas de Ahorro) de un mes concreto.
/// Para el mes en curso reusa el notifier reactivo; para meses pasados lee
/// el valor persistido bajo su propia clave. Evita mostrar el ahorro del mes
/// actual cuando el usuario navega a un mes anterior en el análisis.
final savingsForMonthProvider =
    FutureProvider.family<double, ({int year, int month})>((ref, m) async {
  final now = DateTime.now();
  if (m.year == now.year && m.month == now.month) {
    return ref.watch(savingsTransfersProvider);
  }
  try {
    return await LocalPrefsService.getDouble('savings_${m.year}_${m.month}');
  } catch (e) {
    debugPrint('savingsForMonthProvider: error reading ${m.year}-${m.month}: $e');
    return 0.0;
  }
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

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Analysis month selector ───────────────────────────────────────────────────

final selectedAnalysisMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Single-pass provider for analysis tab: income, expenses, category breakdown.
/// [subBreakdown] agrupa gasto por categoría → subcategoría ('' = sin subcategoría).
final _analysisStatsProvider = Provider<
    ({
      double income,
      double expenses,
      Map<String, double> breakdown,
      Map<String, Map<String, double>> subBreakdown,
    })>((ref) {
  final m = ref.watch(selectedAnalysisMonthProvider);
  double income = 0;
  double expenses = 0;
  final breakdown = <String, double>{};
  final subBreakdown = <String, Map<String, double>>{};
  for (final t in ref.watch(transactionsProvider)) {
    if (t.date.month != m.month || t.date.year != m.year) continue;
    if (t.isIncome) {
      income += t.amount;
    } else {
      expenses += t.amount;
      breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
      final subs = subBreakdown.putIfAbsent(t.category, () => {});
      final subKey = t.subcategoryId ?? '';
      subs[subKey] = (subs[subKey] ?? 0) + t.amount;
    }
  }
  return (
    income: income,
    expenses: expenses,
    breakdown: breakdown,
    subBreakdown: subBreakdown,
  );
});

final analysisIncomeProvider = Provider<double>(
  (ref) => ref.watch(_analysisStatsProvider).income,
);

final analysisExpensesProvider = Provider<double>(
  (ref) => ref.watch(_analysisStatsProvider).expenses,
);

final analysisCategoryBreakdownProvider = Provider<Map<String, double>>(
  (ref) => ref.watch(_analysisStatsProvider).breakdown,
);

/// Desglose por subcategoría del mes de análisis:
/// categoryId → (subcategoryId → gasto). La clave '' agrupa "sin subcategoría".
final analysisSubcategoryBreakdownProvider =
    Provider<Map<String, Map<String, double>>>(
  (ref) => ref.watch(_analysisStatsProvider).subBreakdown,
);

final analysisTopCategoryProvider = Provider<WalletCategory?>((ref) {
  final breakdown = ref.watch(analysisCategoryBreakdownProvider);
  if (breakdown.isEmpty) return null;
  final topId = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final cats = ref.watch(walletCategoriesProvider);
  return resolveCategory(topId, cats);
});

// ── Category breakdown ────────────────────────────────────────────────────────

final categoryBreakdownProvider = Provider<Map<String, double>>(
  (ref) => ref.watch(_monthlyStatsProvider).breakdown,
);

/// Desglose por subcategoría del mes en curso:
/// categoryId → (subcategoryId → gasto). La clave '' agrupa "sin subcategoría".
final subcategoryBreakdownProvider =
    Provider<Map<String, Map<String, double>>>(
  (ref) => ref.watch(_monthlyStatsProvider).subBreakdown,
);

/// Top subcategorías del mes en curso (solo gastos), ordenadas de mayor a menor.
final topSubcategoriesProvider =
    Provider<List<({String categoryId, String subcategoryId, double amount})>>(
        (ref) {
  final subBreakdown = ref.watch(_monthlyStatsProvider).subBreakdown;
  final result =
      <({String categoryId, String subcategoryId, double amount})>[];
  subBreakdown.forEach((catId, subs) {
    subs.forEach((subId, amount) {
      if (subId.isEmpty) return; // omitir "sin subcategoría"
      result.add((categoryId: catId, subcategoryId: subId, amount: amount));
    });
  });
  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
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

  // Single O(n) pass to build month → spending map
  final spendingMap = <(int, int), double>{};
  for (final t in transactions) {
    if (!t.isIncome) {
      final key = (t.date.year, t.date.month);
      spendingMap[key] = (spendingMap[key] ?? 0) + t.amount;
    }
  }

  return List.generate(6, (i) {
    final monthsAgo = 5 - i;
    var year = now.year;
    var month = now.month - monthsAgo;
    while (month <= 0) {
      month += 12;
      year--;
    }
    return (label: _monthAbbr(month), value: spendingMap[(year, month)] ?? 0.0);
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

// ── Balance history (last 30 days, cumulative) ────────────────────────────────

class BalancePoint {
  const BalancePoint({required this.date, required this.balance});
  final DateTime date;
  final double balance;
}

/// Reconstructs the daily balance for the last 30 days by walking backward
/// from the current total balance and undoing each day's transactions.
final balanceHistoryProvider = Provider<List<BalancePoint>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final accounts = ref.watch(accountsProvider);

  if (accounts.isEmpty) return [];

  final currentBalance =
      accounts.fold(0.0, (sum, a) => sum + a.balance);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Group transactions by calendar day
  final txByDay = <DateTime, List<Transaction>>{};
  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    txByDay.putIfAbsent(day, () => []).add(t);
  }

  // Walk backward from today: balance[today] = current, then undo each day
  final points = <BalancePoint>[];
  var balance = currentBalance;

  for (var i = 0; i < 30; i++) {
    final day = today.subtract(Duration(days: i));
    points.add(BalancePoint(date: day, balance: balance));
    for (final t in (txByDay[day] ?? [])) {
      // Undo the transaction effect to get balance before that day
      if (t.type == TransactionType.income) {
        balance -= t.amount;
      } else {
        balance += t.amount;
      }
    }
  }

  // Return in chronological order (oldest → newest)
  return points.reversed.toList();
});

// ── UI feedback signals ───────────────────────────────────────────────────────

/// Incremented each time a transaction is saved via Quick Add.
/// The FAB listens to this and plays its pulse animation.
final fabPulseProvider = StateProvider<int>((ref) => 0);

/// IDs of transactions added in the current session that have not yet
/// been acknowledged by a flash animation in the list.
final newTransactionIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

/// Mensaje de advertencia cuando un ajuste de saldo falla después de guardar
/// una transacción. La UI lo consume mostrando un snackbar y lo limpia a null.
final balanceWarningProvider = StateProvider<String?>((ref) => null);
