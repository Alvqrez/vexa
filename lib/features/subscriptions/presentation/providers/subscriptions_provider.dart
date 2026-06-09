import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/subscription.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';

const _kLegacySubsToWcId = {
  'food': 'wc1', 'transport': 'wc2', 'shopping': 'wc3',
  'entertainment': 'wc4', 'health': 'wc5', 'other': 'wc6', 'salary': 'wc7',
};

// ── Isar converters ───────────────────────────────────────────────────────────

IsarSubscription _subsToIsar(Subscription s) => IsarSubscription()
  ..subscriptionId = s.id
  ..name = s.name
  ..amount = s.amount
  ..nextBillingDate = s.nextBillingDate
  ..categoryStr = s.category
  ..iconCodePoint = s.icon.codePoint
  ..colorValue = s.color.toARGB32()
  ..frequencyStr = s.frequency.name
  ..isActive = s.isActive
  ..note = s.note;

Subscription _isarToSubs(IsarSubscription is_) => Subscription(
      id: is_.subscriptionId,
      name: is_.name,
      amount: is_.amount,
      nextBillingDate: is_.nextBillingDate,
      category: _kLegacySubsToWcId[is_.categoryStr] ?? is_.categoryStr,
      icon: IconData(is_.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(is_.colorValue),
      frequency: SubscriptionFrequency.values.firstWhere(
        (f) => f.name == is_.frequencyStr,
        orElse: () => SubscriptionFrequency.monthly,
      ),
      isActive: is_.isActive,
      note: is_.note,
    );

class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionsNotifier(this._ref, this._isar) : super(const []) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarSubscriptions.where().findAll();
    if (_isLoaded) return;
    if (records.isNotEmpty) {
      state = records.map(_isarToSubs).toList()
        ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    }
    _isLoaded = true;
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
        await _isar.isarSubscriptions.clear();
        await _isar.isarSubscriptions
            .putAll(state.map(_subsToIsar).toList());
      });

  Future<void> add(Subscription s) async {
    _isLoaded = true;
    state = [...state, s];
    await _isar.writeTxn(() => _isar.isarSubscriptions.put(_subsToIsar(s)));
  }

  Future<void> update(Subscription updated) async {
    _isLoaded = true;
    state = [
      for (final s in state) if (s.id == updated.id) updated else s,
    ];
    await _persistAll();
  }

  Future<void> delete(String id) async {
    _isLoaded = true;
    state = state.where((s) => s.id != id).toList();
    await _isar.writeTxn(
        () => _isar.isarSubscriptions.deleteBySubscriptionId(id));
  }

  Future<void> toggleActive(String id) async {
    _isLoaded = true;
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isActive: !s.isActive) else s,
    ];
    await _persistAll();
  }

  Future<void> chargeSubscription(Subscription s) async {
    try {
      final accounts = _ref.read(accountsProvider);
      final account = accounts.isEmpty
          ? null
          : accounts.firstWhere((a) => !a.isSavings, orElse: () => accounts.first);
      final transaction = Transaction(
        id: generateId(),
        merchant: s.name,
        amount: s.amount,
        type: TransactionType.expense,
        category: s.category,
        date: DateTime.now(),
        accountId: account?.id,
      );
      await _ref.read(transactionsProvider.notifier).add(transaction);

      final nextDate = s.nextAfterCurrent;
      await update(s.copyWith(nextBillingDate: nextDate));
    } catch (e) {
      debugPrint('SubscriptionsNotifier.chargeSubscription failed: $e');
      rethrow;
    }
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, List<Subscription>>(
  (ref) => SubscriptionsNotifier(ref, ref.watch(isarProvider)),
);

final activeSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  return ref
      .watch(subscriptionsProvider)
      .where((s) => s.isActive)
      .toList()
    ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
});

final upcomingSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(activeSubscriptionsProvider)
      .where((s) => s.nextBillingDate.difference(now).inDays <= 30)
      .toList();
});

final monthlySubscriptionsTotalProvider = Provider<double>((ref) {
  return ref.watch(activeSubscriptionsProvider).fold(
        0.0,
        (sum, s) => sum + s.monthlyEquivalent,
      );
});

final subscriptionsDueSoonProvider = Provider<List<Subscription>>((ref) {
  return ref
      .watch(activeSubscriptionsProvider)
      .where((s) => s.isDueSoon)
      .toList();
});
