import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/theme/app_colors.dart';
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
  ..note = s.note
  ..accountId = s.accountId;

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
      accountId: is_.accountId,
    );

class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionsNotifier(this._ref, this._isar) : super(const []) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final records = await _isar.isarSubscriptions.where().findAll();
    if (records.isNotEmpty) {
      state = records.map(_isarToSubs).toList()
        ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    }
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
      if (accounts.isEmpty) {
        debugPrint('SubscriptionsNotifier.chargeSubscription: no accounts, skipping ${s.name}');
        return;
      }
      final account = s.accountId != null
          ? accounts.firstWhere((a) => a.id == s.accountId,
              orElse: () => accounts.firstWhere((a) => !a.isSavings,
                  orElse: () => accounts.first))
          : accounts.firstWhere((a) => !a.isSavings, orElse: () => accounts.first);

      // Recupera TODOS los periodos vencidos: por cada fecha de cobro que ya
      // pasó (o es hoy) se crea un cargo fechado en su día real y se avanza la
      // fecha. El avance se persiste tras cada cargo para que un cierre abrupto
      // no provoque doble cobro (a lo sumo se repite el último periodo). El
      // guard evita un bucle infinito si la frecuencia no avanzara la fecha.
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      var current = s;
      var guard = 0;
      while (guard < 600) {
        final billing = current.nextBillingDate;
        final billingDate =
            DateTime(billing.year, billing.month, billing.day);
        if (billingDate.isAfter(todayDate)) break; // ya al día
        await _ref.read(transactionsProvider.notifier).add(Transaction(
              id: generateId(),
              merchant: s.name,
              amount: s.amount,
              type: TransactionType.expense,
              category: s.category,
              date: billing, // fecha real de cobro, no "hoy"
              accountId: account.id,
            ));
        final next = current.nextAfterCurrent;
        if (!next.isAfter(billing)) break; // seguridad: la fecha no avanza
        current = current.copyWith(nextBillingDate: next);
        await update(current); // persiste el avance de inmediato (crash-safe)
        guard++;
      }
    } catch (e) {
      debugPrint('SubscriptionsNotifier.chargeSubscription failed: $e');
      rethrow;
    }
  }

  Future<void> reset() async {
    state = const [];
    _isLoaded = false;
  }

  /// Datos de ejemplo (solo debug).
  Future<void> seed() async {
    if (kReleaseMode) return;
    _isLoaded = true;
    final now = DateTime.now();
    DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);
    state = [
      Subscription(
        id: 'seed_sub_1',
        name: 'Netflix',
        amount: 12.99,
        nextBillingDate: inDays(2),
        category: 'wc4',
        icon: Icons.movie_outlined,
        color: AppColors.negative,
        frequency: SubscriptionFrequency.monthly,
        accountId: '1',
      ),
      Subscription(
        id: 'seed_sub_2',
        name: 'Spotify',
        amount: 9.99,
        nextBillingDate: inDays(12),
        category: 'wc4',
        icon: Icons.music_note_outlined,
        color: AppColors.emerald,
        frequency: SubscriptionFrequency.monthly,
        accountId: '1',
      ),
      Subscription(
        id: 'seed_sub_3',
        name: 'Gimnasio',
        amount: 29.99,
        nextBillingDate: inDays(20),
        category: 'wc5',
        icon: Icons.fitness_center_rounded,
        color: AppColors.petroleum,
        frequency: SubscriptionFrequency.monthly,
        accountId: '1',
      ),
      Subscription(
        id: 'seed_sub_4',
        name: 'iCloud',
        amount: 2.99,
        nextBillingDate: inDays(5),
        category: 'wc6',
        icon: Icons.cloud_outlined,
        color: AppColors.catTransport,
        frequency: SubscriptionFrequency.monthly,
        accountId: '1',
      ),
    ];
    await _persistAll();
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
