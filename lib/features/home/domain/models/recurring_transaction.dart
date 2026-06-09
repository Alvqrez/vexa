import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        final lastDay = DateTime(ny, nm + 1, 0).day;
        return DateTime(ny, nm, from.day.clamp(1, lastDay), from.hour, from.minute);
      case yearly:
        final lastDay = DateTime(from.year + 1, from.month + 1, 0).day;
        return DateTime(from.year + 1, from.month, from.day.clamp(1, lastDay), from.hour, from.minute);
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

  factory RecurringTransaction.fromJson(Map<String, dynamic> j) {
    final amountValue = j['amount'];
    double amount = 0.0;
    if (amountValue is num) {
      amount = amountValue.toDouble();
    } else if (amountValue is String) {
      amount = double.tryParse(amountValue) ?? 0.0;
    }

    DateTime nextDate = DateTime.now();
    final dateValue = j['nextDate'];
    if (dateValue is String) {
      try {
        nextDate = DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('RecurringTransaction: invalid nextDate format: $dateValue');
      }
    }

    List<int>? weekDays;
    final weekDaysValue = j['weekDays'] as List<dynamic>?;
    if (weekDaysValue != null) {
      weekDays = weekDaysValue
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    return RecurringTransaction(
      id: j['id'] as String? ?? '',
      merchant: j['merchant'] as String? ?? '',
      amount: amount,
      type: j['type'] as String? ?? 'expense',
      category: j['category'] as String? ?? '',
      accountId: j['accountId'] as String?,
      note: j['note'] as String?,
      frequency: RecurrenceFrequency.values.firstWhere(
          (f) => f.name == j['frequency'],
          orElse: () => RecurrenceFrequency.monthly),
      nextDate: nextDate,
      isActive: j['isActive'] as bool? ?? true,
      timesPerOccurrence: (j['timesPerOccurrence'] as int?) ?? 1,
      weekDays: weekDays,
    );
  }

  static const _key = 'recurring_transactions';

  static Future<List<RecurringTransaction>> loadAll() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        debugPrint('RecurringTransaction.loadAll: expected List, got ${decoded.runtimeType}');
        return [];
      }
      return decoded
          .map((e) => RecurringTransaction.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } catch (e, st) {
      debugPrint('RecurringTransaction.loadAll error: $e\n$st');
      return [];
    }
  }

  static Future<void> saveAll(List<RecurringTransaction> items) async {
    final json = jsonEncode(items.map((r) => r.toJson()).toList());
    await LocalPrefsService.setString(_key, json);
  }
}
