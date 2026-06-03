import 'dart:convert';
import '../../../../core/data/local_prefs_service.dart';

enum RecurrenceFrequency {
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
        weekly => 'Semanal',
        monthly => 'Mensual',
        yearly => 'Anual',
      };

  DateTime nextDate(DateTime from) => switch (this) {
        weekly => from.add(const Duration(days: 7)),
        monthly => DateTime(from.year, from.month + 1, from.day,
            from.hour, from.minute),
        yearly => DateTime(from.year + 1, from.month, from.day,
            from.hour, from.minute),
      };
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
