import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subscription.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';

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
  SubscriptionsNotifier(this._ref) : super(_mockSubscriptions);

  final Ref _ref;

  void add(Subscription s) {
    state = [...state, s];
  }

  void update(Subscription updated) {
    state = [
      for (final s in state) if (s.id == updated.id) updated else s,
    ];
  }

  void delete(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void toggleActive(String id) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(isActive: !s.isActive) else s,
    ];
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
  (ref) => SubscriptionsNotifier(ref),
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
