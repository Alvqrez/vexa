import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/data/local_prefs_service.dart';

class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'date': date.toIso8601String(),
        if (note != null) 'note': note,
      };

  factory TransferRecord.fromJson(Map<String, dynamic> j) {
    final amountValue = j['amount'];
    final dateValue = j['date'];

    double amount = 0.0;
    if (amountValue is num) {
      amount = amountValue.toDouble();
    } else if (amountValue is String) {
      amount = double.tryParse(amountValue) ?? 0.0;
    }

    DateTime date = DateTime.now();
    if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('TransferRecord: invalid date format: $dateValue');
      }
    }

    return TransferRecord(
      id: j['id'] as String? ?? '',
      fromAccountId: j['fromAccountId'] as String? ?? '',
      toAccountId: j['toAccountId'] as String? ?? '',
      amount: amount,
      date: date,
      note: j['note'] as String?,
    );
  }

  static const _key = 'transfer_history';

  static Future<List<TransferRecord>> loadAll() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        debugPrint('TransferRecord.loadAll: expected List, got ${decoded.runtimeType}');
        return [];
      }
      return decoded
          .map((e) => TransferRecord.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } catch (e, st) {
      debugPrint('TransferRecord.loadAll error: $e\n$st');
      return [];
    }
  }

  static Future<void> saveAll(List<TransferRecord> records) async {
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    await LocalPrefsService.setString(_key, json);
  }

  static Future<void> add(TransferRecord record) async {
    final all = await loadAll();
    all.insert(0, record);
    await saveAll(all);
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((r) => r.id == id);
    await saveAll(all);
  }
}
