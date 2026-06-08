import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscriptions_provider.dart';

class SubscriptionProcessor {
  SubscriptionProcessor(this._ref);

  final Ref _ref;

  /// Procesa automáticamente suscripciones vencidas
  Future<int> processSubscriptions() async {
    final subscriptions = _ref.read(subscriptionsProvider);
    final now = DateTime.now().toUtc();
    int processed = 0;

    for (final subscription in subscriptions) {
      // Solo procesar si está activa
      if (!subscription.isActive) continue;

      // Comparar solo fecha (sin hora)
      final nextDate = subscription.nextBillingDate.toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final nextDay = DateTime.utc(
        nextDate.year,
        nextDate.month,
        nextDate.day,
      );

      // Procesar si la fecha de vencimiento es hoy o anterior
      if (nextDay.isBefore(today) || nextDay.isAtSameMomentAs(today)) {
        try {
          await _ref
              .read(subscriptionsProvider.notifier)
              .chargeSubscription(subscription);
          processed++;
        } catch (e) {
          // Continuar con otras suscripciones si hay error
        }
      }
    }

    return processed;
  }
}

final subscriptionProcessorProvider = Provider((ref) {
  return SubscriptionProcessor(ref);
});

/// Provider que maneja el estado del procesamiento automático
final subscriptionAutoProcessProvider =
    StateNotifierProvider<SubscriptionAutoProcessNotifier, bool>(
  (ref) => SubscriptionAutoProcessNotifier(ref),
);

class SubscriptionAutoProcessNotifier extends StateNotifier<bool> {
  SubscriptionAutoProcessNotifier(this._ref) : super(false) {
    _initializeAutoProcessing();
  }

  final Ref _ref;
  DateTime? _lastProcessed;

  void _initializeAutoProcessing() {
    // Procesar cada vez que la app se abre o se enfoca
    _ref.listen(subscriptionsProvider, (previous, next) {
      _scheduleProcessing();
    });
  }

  void _scheduleProcessing() {
    final now = DateTime.now();
    final lastProcessedToday = _lastProcessed != null &&
        _lastProcessed!.year == now.year &&
        _lastProcessed!.month == now.month &&
        _lastProcessed!.day == now.day;

    // Solo procesar una vez por día
    if (!lastProcessedToday) {
      _processSubscriptions();
    }
  }

  Future<void> _processSubscriptions() async {
    state = true;
    try {
      final processor = _ref.read(subscriptionProcessorProvider);
      await processor.processSubscriptions();
      _lastProcessed = DateTime.now();
    } finally {
      state = false;
    }
  }

  Future<void> processNow() async {
    state = true;
    try {
      final processor = _ref.read(subscriptionProcessorProvider);
      await processor.processSubscriptions();
      _lastProcessed = DateTime.now();
    } finally {
      state = false;
    }
  }
}
