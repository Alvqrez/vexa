import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

abstract final class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'vexa_finance';
  static const _channelName = 'Vexa Finance';

  static const _idDailyTip = 1;
  static const _idBudgetBase = 200;
  static const _idSubsBase = 100;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    _initialized = true;
  }

  static AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      );

  static NotificationDetails get _details =>
      NotificationDetails(android: _androidDetails);

  // ── Daily tip ────────────────────────────────────────────────────────────────

  static const _tips = [
    'Registra cada gasto, por pequeño que sea. Los pequeños gastos suman mucho.',
    'El 50/30/20: 50% necesidades, 30% deseos, 20% ahorro.',
    'Revisa tus suscripciones. ¿Usas todas las que pagas?',
    'Comer en casa ahorra hasta un 60% frente a restaurantes.',
    'Un fondo de emergencia ideal cubre 3-6 meses de gastos.',
    'Automatiza tu ahorro. Transfiérelo apenas cobres.',
    'Evita compras impulsivas: espera 24h antes de decidir.',
    'Compara precios antes de comprar. Pequeñas diferencias suman.',
    'Revisa tu presupuesto cada semana. Lo que se mide, mejora.',
    'Invierte en educación financiera — es el mejor retorno.',
  ];

  static Future<void> scheduleDailyTip() async {
    await _plugin.cancel(_idDailyTip);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 9); // 9 AM
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final tip = _tips[now.weekday % _tips.length];

    await _plugin.zonedSchedule(
      _idDailyTip,
      '💡 Tip financiero del día',
      tip,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyTip() async {
    await _plugin.cancel(_idDailyTip);
  }

  // ── Subscription expiry ──────────────────────────────────────────────────────

  static Future<void> showSubscriptionAlert({
    required String name,
    required int daysLeft,
    required int index,
  }) async {
    final body = daysLeft == 0
        ? '¡Vence hoy! Revisa tu cuenta.'
        : 'Vence en $daysLeft día${daysLeft == 1 ? '' : 's'}.';
    await _plugin.show(
      _idSubsBase + (index % 99),
      '📅 $name',
      body,
      _details,
    );
  }

  // ── Budget alert (≥ 80 %) ────────────────────────────────────────────────────

  static Future<void> showBudgetAlert({
    required String categoryName,
    required int percent,
    required int index,
  }) async {
    final emoji = percent >= 100 ? '🚨' : '⚠️';
    final body = percent >= 100
        ? 'Superaste el límite de $categoryName.'
        : 'Alcanzaste el $percent% del presupuesto en $categoryName.';
    await _plugin.show(
      _idBudgetBase + (index % 99),
      '$emoji Alerta de presupuesto',
      body,
      _details,
    );
  }
}
