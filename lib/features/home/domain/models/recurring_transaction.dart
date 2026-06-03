import 'dart:convert';
import '../../../../core/data/local_prefs_service.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        daily => 'Diario',
        weekly => 'Semanal',
        monthly => 'Mensual',
        yearly => 'Anual',
      };

  /// Returns the next date without weekday filtering.
  /// Use [nextDateFrom] when weekDays restrictions apply.
  DateTime nextDate(DateTime from) {
    switch (this) {
      case daily:
        return from.add(const Duration(days: 1));
      case weekly:
        return from.add(const Duration(days: 7));
      case monthly:
        final nm = from.month == 12 ? 1 : from.month + 1;
        final ny = from.month == 12 ? from.year + 1 : from.year;
        final last = DateTime(ny, nm + 1, 0).day;
        return DateTime(ny, nm, from.day.clamp(1, last),
            from.hour, from.minute);
      case yearly:
        final last = DateTime(from.year + 1, from.month + 1, 0).day;
        return DateTime(from.year + 1, from.month,
            from.day.clamp(1, last), from.hour, from.minute);
    }
  }

  /// Next date considering allowed weekdays (1=Mon…7=Sun). Null = every day.
  DateTime nextDateFrom(DateTime from, List<int>? weekDays) {
    if (weekDays == null || weekDays.isEmpty) return nextDate(from);
    var next = from.add(const Duration(days: 1));
    for (var i = 0; i < 8; i++) {
      if (weekDays.contains(next.weekday)) return next;
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    required this.frequency,
    required this.nextDate,
    this.note,
    this.isActive = true,
    this.timesPerOccurrence = 1,
    this.weekDays,
  });

  final String id;
  final String merchant;
  final double amount;
  final String type;
  final String category;
  final String? accountId;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime nextDate;
  final bool isActive;
  /// How many transactions to post each time this fires (e.g., 2 for round-trip).
  final int timesPerOccurrence;
  /// Allowed weekdays (1=Mon…7=Sun). Null means every day.
  final List<int>? weekDays;

  RecurringTransaction copyWith({DateTime? nextDate}) => RecurringTransaction(
        id: id,
        merchant: merchant,
        amount: amount,
        type: type,
        category: category,
        accountId: accountId,
        note: note,
        frequency: frequency,
        nextDate: nextDate ?? this.nextDate,
        isActive: isActive,
        timesPerOccurrence: timesPerOccurrence,
        weekDays: weekDays,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'type': type,
        'category': category,
        'accountId': accountId,
        'note': note,
        'frequency': frequency.name,
        'nextDate': nextDate.toIso8601String(),
        'isActive': isActive,
        'timesPerOccurrence': timesPerOccurrence,
        if (weekDays != null) 'weekDays': weekDays,
      };

  factory RecurringTransaction.fromJson(Map<String, dynamic> j) =>
      RecurringTransaction(
        id: j['id'] as String,
        merchant: j['merchant'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] as String,
        category: j['category'] as String,
        accountId: j['accountId'] as String?,
        note: j['note'] as String?,
        frequency: RecurrenceFrequency.values.firstWhere(
            (f) => f.name == j['frequency'],
            orElse: () => RecurrenceFrequency.monthly),
        nextDate: DateTime.parse(j['nextDate'] as String),
        isActive: j['isActive'] as bool? ?? true,
        timesPerOccurrence: (j['timesPerOccurrence'] as int?) ?? 1,
        weekDays: (j['weekDays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(),
      );

  static const _key = 'recurring_transactions';

  static Future<List<RecurringTransaction>> loadAll() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<RecurringTransaction> items) async {
    final json = jsonEncode(items.map((r) => r.toJson()).toList());
    await LocalPrefsService.setString(_key, json);
  }
}
