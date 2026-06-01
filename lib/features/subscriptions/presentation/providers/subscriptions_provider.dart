import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/subscription.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarSubscription _subsToIsar(Subscription s) => IsarSubscription()
  ..subscriptionId = s.id
  ..name = s.name
  ..amount = s.amount
  ..nextBillingDate = s.nextBillingDate
  ..categoryStr = s.category.name
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
      category: TransactionCategory.values.firstWhere(
        (c) => c.name == is_.categoryStr,
        orElse: () => TransactionCategory.other,
      ),
      icon: IconData(is_.iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(is_.colorValue),
      frequency: SubscriptionFrequency.values.firstWhere(
        (f) => f.name == is_.frequencyStr,
        orElse: () => SubscriptionFrequency.monthly,
      ),
      isActive: is_.isActive,
      note: is_.note,
    );

final _mockSubscriptions = [
  Subscription(
    id: 's1',
    name: 'Netflix',
    amount: 15.99,
    nextBillingDate: DateTime.now().add(const Duration(days: 3)),
    category: TransactionCategory.entertainment,
    icon: Icons.play_circle_rounded,
    color: const Color(0xFFE50914),
    frequency: SubscriptionFrequency.monthly,
  ),
  Subscription(
    id: 's2',
    name: 'Spotify',
    amount: 9.99,
    nextBillingDate: DateTime.now().add(const Duration(days: 8)),
    category: TransactionCategory.entertainment,
    icon: Icons.music_note_rounded,
    color: const Color(0xFF1DB954),
    frequency: SubscriptionFrequency.monthly,
  ),
  Subscription(
    id: 's3',
    name: 'ChatGPT Plus',
    amount: 20.00,
    nextBillingDate: DateTime.now().add(const Duration(days: 15)),
    category: TransactionCategory.other,
    icon: Icons.smart_toy_rounded,
    color: const Color(0xFF10A37F),
    frequency: SubscriptionFrequency.monthly,
  ),
  Subscription(
    id: 's4',
    name: 'YouTube Premium',
    amount: 13.99,
    nextBillingDate: DateTime.now().add(const Duration(days: 22)),
    category: TransactionCategory.entertainment,
    icon: Icons.ondemand_video_rounded,
    color: const Color(0xFFFF0000),
    frequency: SubscriptionFrequency.monthly,
  ),
  Subscription(
    id: 's5',
    name: 'Amazon Prime',
    amount: 4.99,
    nextBillingDate: DateTime.now().add(const Duration(days: 28)),
    category: TransactionCategory.shopping,
    icon: Icons.local_shipping_rounded,
    color: const Color(0xFFFF9900),
    frequency: SubscriptionFrequency.monthly,
  ),
];

class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionsNotifier(this._ref, this._isar) : super(_mockSubscriptions) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    final records = await _isar.isarSubscriptions.where().findAll();
    if (_isLoaded) return;
    if (records.isEmpty) {
      await _isar.writeTxn(() => _isar.isarSubscriptions
          .putAll(state.map(_subsToIsar).toList()));
    } else {
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

  void add(Subscription s) {
    _isLoaded = true;
    state = [...state, s];
    _isar.writeTxn(() => _isar.isarSubscriptions.put(_subsToIsar(s)));
  }

  void update(Subscription updated) {
    _isLoaded = true;
    state = [
      for (final s in state) if (s.id == updated.id) updated else s,
    ];
    _persistAll();
  }

  void delete(String id) {
    _isLoaded = true;
    state = state.where((s) => s.id != id).toList();
    _isar.writeTxn(
        () => _isar.isarSubscriptions.deleteBySubscriptionId(id));
  }

  void toggleActive(String id) {
    _isLoaded = true;
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isActive: !s.isActive) else s,
    ];
    _persistAll();
  }

  void chargeSubscription(Subscription s) {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      merchant: s.name,
      amount: s.amount,
      type: TransactionType.expense,
      category: s.category,
      date: DateTime.now(),
    );
    _ref.read(transactionsProvider.notifier).add(transaction);

    final nextDate = s.nextAfterCurrent;
    update(s.copyWith(nextBillingDate: nextDate));
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
