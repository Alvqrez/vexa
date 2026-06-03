import 'dart:convert';
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

  factory TransferRecord.fromJson(Map<String, dynamic> j) => TransferRecord(
        id: j['id'] as String,
        fromAccountId: j['fromAccountId'] as String,
        toAccountId: j['toAccountId'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        note: j['note'] as String?,
      );

  static const _key = 'transfer_history';

  static Future<List<TransferRecord>> loadAll() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TransferRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
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
