import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/loan.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/data/local_prefs_service.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarLoan _loanToIsar(Loan l) => IsarLoan()
  ..loanId = l.id
  ..name = l.name
  ..amount = l.amount
  ..paidAmount = l.paidAmount
  ..typeStr = l.type.name
  ..date = l.date
  ..accountId = l.accountId
  ..dueDate = l.dueDate
  ..iconCodePoint = l.icon.codePoint
  ..colorValue = l.color.toARGB32()
  ..note = l.note;

Loan _isarToLoan(IsarLoan il) => Loan(
      id: il.loanId,
      name: il.name,
      amount: il.amount,
      paidAmount: il.paidAmount,
      type: LoanType.values.firstWhere(
        (t) => t.name == il.typeStr,
        orElse: () => LoanType.lentByMe,
      ),
      date: il.date,
      accountId: il.accountId,
      dueDate: il.dueDate,
      icon: IconData(il.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(il.colorValue),
      note: il.note,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class LoansNotifier extends StateNotifier<List<Loan>> {
  LoansNotifier(this._ref, this._isar) : super(const []) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final records = await _isar.isarLoans.where().findAll();
    if (records.isNotEmpty) {
      state = records.map(_isarToLoan).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarLoans.clear();
        await _isar.isarLoans.putAll(state.map(_loanToIsar).toList());
      });

  // Returns the generated transaction ID so callers can persist it.
  Future<String?> _addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required String? accountId,
  }) async {
    if (accountId == null) return null;
    final txId = generateId();
    await _ref.read(transactionsProvider.notifier).add(Transaction(
          id: txId,
          merchant: merchant,
          amount: amount,
          type: type,
          category: 'wc6',
          date: DateTime.now(),
          accountId: accountId,
        ));
    return txId;
  }

  Future<void> add(Loan l) async {
    _isLoaded = true;
    state = [l, ...state];
    await _isar.writeTxn(() => _isar.isarLoans.put(_loanToIsar(l)));

    // Prestar dinero = gasto. Recibir prestado = ingreso.
    final txId = await _addTransaction(
      merchant: 'Préstamo: ${l.name}',
      amount: l.amount,
      type: l.type == LoanType.lentByMe
          ? TransactionType.expense
          : TransactionType.income,
      accountId: l.accountId,
    );
    // Persist the origin txId so delete() can reverse the balance.
    if (txId != null) {
      await LocalPrefsService.setString('loan_origin_tx_${l.id}', txId);
    }
  }

  Future<void> update(Loan updated) async {
    _isLoaded = true;
    state = [
      for (final l in state) if (l.id == updated.id) updated else l,
    ];
    await _persistAll();
  }

  Future<void> delete(String id) async {
    _isLoaded = true;
    // Capture before removing from state so we can use name/date for fallback.
    final loan = state.where((l) => l.id == id).firstOrNull;
    state = state.where((l) => l.id != id).toList();
    await _isar.writeTxn(() => _isar.isarLoans.deleteByLoanId(id));

    // Reverse the originating transaction to restore the account balance.
    final txId = await LocalPrefsService.getString('loan_origin_tx_$id');
    if (txId != null) {
      // Fast path: known txId from LocalPrefs.
      final tx = _ref
          .read(transactionsProvider)
          .where((t) => t.id == txId)
          .firstOrNull;
      if (tx != null) {
        await _ref.read(transactionsProvider.notifier).delete(tx);
      }
      await LocalPrefsService.remove('loan_origin_tx_$id');
    } else if (loan != null && loan.accountId != null) {
      // Fallback: LocalPrefs lost — locate originating tx by merchant name + date + account.
      final expectedMerchant = 'Préstamo: ${loan.name}';
      final loanDay = DateTime(loan.date.year, loan.date.month, loan.date.day);
      final tx = _ref.read(transactionsProvider).where((t) {
        final tDay = DateTime(t.date.year, t.date.month, t.date.day);
        return t.merchant == expectedMerchant &&
            tDay == loanDay &&
            t.accountId == loan.accountId;
      }).firstOrNull;
      if (tx != null) {
        await _ref.read(transactionsProvider.notifier).delete(tx);
      }
    }
  }

  /// Datos de ejemplo (solo debug). No crea transacciones de origen.
  Future<void> seed() async {
    if (kReleaseMode) return;
    _isLoaded = true;
    final now = DateTime.now();
    state = [
      Loan(
        id: 'seed_loan_1',
        name: 'Carlos',
        amount: 500,
        paidAmount: 200,
        type: LoanType.lentByMe,
        date: DateTime(now.year, now.month - 1, 10),
        dueDate: DateTime(now.year, now.month, now.day + 15),
        icon: Icons.person_outline_rounded,
        color: AppColors.emerald,
        accountId: '1',
      ),
      Loan(
        id: 'seed_loan_2',
        name: 'Préstamo personal',
        amount: 1200,
        paidAmount: 400,
        type: LoanType.borrowedByMe,
        date: DateTime(now.year, now.month - 2, 5),
        dueDate: DateTime(now.year, now.month + 2, 1),
        icon: Icons.account_balance_rounded,
        color: AppColors.negative,
        accountId: '1',
      ),
    ];
    await _persistAll();
  }

  Future<void> addPayment(String id, double paymentAmount, {String? accountId}) async {
    // Validate payment amount
    if (paymentAmount <= 0) {
      debugPrint('LoansNotifier.addPayment: invalid amount: $paymentAmount');
      return;
    }

    final loan = state.where((l) => l.id == id).firstOrNull;
    if (loan == null) {
      debugPrint('LoansNotifier.addPayment: loan $id not found, skipping');
      return;
    }
    _isLoaded = true;
    state = [
      for (final l in state)
        if (l.id == id)
          l.copyWith(
              paidAmount:
                  (l.paidAmount + paymentAmount).clamp(0.0, l.amount))
        else
          l,
    ];
    await _persistAll();

    // Cobrar lo prestado = ingreso. Pagar lo debido = gasto.
    final effectiveAccountId = accountId ?? loan.accountId;
    await _addTransaction(
      merchant: loan.type == LoanType.lentByMe
          ? 'Cobro préstamo: ${loan.name}'
          : 'Pago deuda: ${loan.name}',
      amount: paymentAmount,
      type: loan.type == LoanType.lentByMe
          ? TransactionType.income
          : TransactionType.expense,
      accountId: effectiveAccountId,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final loansProvider = StateNotifierProvider<LoansNotifier, List<Loan>>(
  (ref) => LoansNotifier(ref, ref.watch(isarProvider)),
);

final activeLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider).where((l) => !l.isSettled).toList();
});

final settledLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider).where((l) => l.isSettled).toList();
});

final lentByMeProvider = Provider<List<Loan>>((ref) {
  return ref
      .watch(activeLoansProvider)
      .where((l) => l.type == LoanType.lentByMe)
      .toList();
});

final borrowedByMeProvider = Provider<List<Loan>>((ref) {
  return ref
      .watch(activeLoansProvider)
      .where((l) => l.type == LoanType.borrowedByMe)
      .toList();
});

final totalLentProvider = Provider<double>((ref) {
  return ref
      .watch(lentByMeProvider)
      .fold(0.0, (sum, l) => sum + l.remainingAmount);
});

final totalBorrowedProvider = Provider<double>((ref) {
  return ref
      .watch(borrowedByMeProvider)
      .fold(0.0, (sum, l) => sum + l.remainingAmount);
});
