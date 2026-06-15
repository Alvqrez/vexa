import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/local_prefs_service.dart';
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
          debugPrint('SubscriptionProcessor: failed to charge ${subscription.name}: $e');
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
  bool _initialized = false;
  bool _isProcessing = false;

  static const _kLastProcessedKey = 'subs_last_processed_date';

  Future<bool> _processedToday() async {
    final stored = await LocalPrefsService.getString(_kLastProcessedKey);
    if (stored == null) return false;
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    return stored == today;
  }

  Future<void> _markProcessedToday() async {
    final now = DateTime.now();
    await LocalPrefsService.setString(
        _kLastProcessedKey, '${now.year}-${now.month}-${now.day}');
  }

  void _initializeAutoProcessing() {
    if (_initialized) return;
    _initialized = true;
    _ref.listen(subscriptionsProvider, (previous, next) {
      _scheduleProcessing();
    });
  }

  void _scheduleProcessing() {
    _processedToday().then((alreadyDone) {
      if (!alreadyDone) _processSubscriptions();
    });
  }

  Future<void> _processSubscriptions() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = true;
    try {
      final processor = _ref.read(subscriptionProcessorProvider);
      final processed = await processor.processSubscriptions();
      if (processed > 0) {
        debugPrint('SubscriptionAutoProcessor: processed $processed subscriptions');
      }
      await _markProcessedToday();
    } catch (e, st) {
      debugPrint('SubscriptionAutoProcessor._processSubscriptions error: $e\n$st');
    } finally {
      _isProcessing = false;
      state = false;
    }
  }

  Future<void> processNow() async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = true;
    try {
      final processor = _ref.read(subscriptionProcessorProvider);
      final processed = await processor.processSubscriptions();
      if (processed > 0) {
        debugPrint('SubscriptionAutoProcessor: manual trigger processed $processed subscriptions');
      }
      await _markProcessedToday();
    } catch (e, st) {
      debugPrint('SubscriptionAutoProcessor.processNow error: $e\n$st');
      rethrow;
    } finally {
      _isProcessing = false;
      state = false;
    }
  }
}
