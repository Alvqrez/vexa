import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/loan.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';

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
    final records = await _isar.isarLoans.where().findAll();
    if (_isLoaded) return;
    if (records.isNotEmpty) {
      state = records.map(_isarToLoan).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    _isLoaded = true;
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarLoans.clear();
        await _isar.isarLoans.putAll(state.map(_loanToIsar).toList());
      });

  void _addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required String? accountId,
  }) {
    if (accountId == null) return;
    _ref.read(transactionsProvider.notifier).add(Transaction(
          id: generateId(),
          merchant: merchant,
          amount: amount,
          type: type,
          category: TransactionCategory.other,
          date: DateTime.now(),
          accountId: accountId,
        ));
  }

  void add(Loan l) {
    _isLoaded = true;
    state = [l, ...state];
    _isar.writeTxn(() => _isar.isarLoans.put(_loanToIsar(l)));

    // Prestar dinero = gasto. Recibir prestado = ingreso.
    _addTransaction(
      merchant: 'Préstamo: ${l.name}',
      amount: l.amount,
      type: l.type == LoanType.lentByMe
          ? TransactionType.expense
          : TransactionType.income,
      accountId: l.accountId,
    );
  }

  void update(Loan updated) {
    _isLoaded = true;
    state = [
      for (final l in state) if (l.id == updated.id) updated else l,
    ];
    _persistAll();
  }

  void delete(String id) {
    _isLoaded = true;
    state = state.where((l) => l.id != id).toList();
    _isar.writeTxn(() => _isar.isarLoans.deleteByLoanId(id));
  }

  void addPayment(String id, double paymentAmount, {String? accountId}) {
    final loan = state.firstWhere((l) => l.id == id);
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
    _persistAll();

    // Cobrar lo prestado = ingreso. Pagar lo debido = gasto.
    final effectiveAccountId = accountId ?? loan.accountId;
    _addTransaction(
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
