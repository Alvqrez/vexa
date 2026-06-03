import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../features/home/domain/models/transaction.dart';

abstract final class ExportUtils {
  static String buildCsv(List<Transaction> transactions) {
    final buf = StringBuffer();

    // Header row
    buf.writeln(
        'Fecha,Hora,Descripción,Tipo,Categoría,Monto,Cuenta,Etiquetas,Nota');

    final dateFmt = DateFormat('dd/MM/yyyy', 'es');
    final timeFmt = DateFormat('HH:mm', 'es');

    for (final t in transactions) {
      final row = [
        dateFmt.format(t.date),
        timeFmt.format(t.date),
        _escape(t.merchant),
        t.isIncome ? 'Ingreso' : 'Gasto',
        t.category.label,
        (t.isIncome ? t.amount : -t.amount).toStringAsFixed(2),
        t.accountId ?? '',
        t.tags.join(' | '),
        _escape(t.note ?? ''),
      ].join(',');
      buf.writeln(row);
    }

    return buf.toString();
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Copies the CSV to clipboard and returns the number of rows exported.
  static Future<int> copyToClipboard(List<Transaction> transactions) async {
    final csv = buildCsv(transactions);
    await Clipboard.setData(ClipboardData(text: csv));
    return transactions.length;
  }
}
