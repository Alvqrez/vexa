import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../features/home/domain/models/transaction.dart';
import '../../features/home/domain/models/account.dart';
import '../../features/wallet/domain/models/wallet_category.dart';
import '../../features/wallet/domain/models/subcategory.dart';

abstract final class ExportUtils {
  static String buildCsv(
    List<Transaction> transactions, {
    List<Account> accounts = const [],
    List<WalletCategory> categories = const [],
    List<Subcategory> subcategories = const [],
  }) {
    final accountMap = {for (final a in accounts) a.id: a.name};
    final subMap = {for (final s in subcategories) s.id: s.name};
    final buf = StringBuffer();

    buf.writeln(
        'Fecha,Hora,Descripción,Tipo,Categoría,Subcategoría,Monto,Cuenta,Etiquetas,Nota');

    final dateFmt = DateFormat('dd/MM/yyyy', 'es');
    final timeFmt = DateFormat('HH:mm', 'es');

    for (final t in transactions) {
      final accountName =
          t.accountId != null ? (accountMap[t.accountId] ?? t.accountId!) : '';
      final subName =
          t.subcategoryId != null ? (subMap[t.subcategoryId] ?? '') : '';
      final row = [
        dateFmt.format(t.date),
        timeFmt.format(t.date),
        _escape(t.merchant),
        t.isIncome ? 'Ingreso' : 'Gasto',
        resolveCategory(t.category, categories).name,
        _escape(subName),
        (t.isIncome ? t.amount : -t.amount).toStringAsFixed(2),
        _escape(accountName),
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
  static Future<int> copyToClipboard(
    List<Transaction> transactions, {
    List<Account> accounts = const [],
    List<WalletCategory> categories = const [],
    List<Subcategory> subcategories = const [],
  }) async {
    final csv = buildCsv(transactions,
        accounts: accounts,
        categories: categories,
        subcategories: subcategories);
    await Clipboard.setData(ClipboardData(text: csv));
    return transactions.length;
  }
}
