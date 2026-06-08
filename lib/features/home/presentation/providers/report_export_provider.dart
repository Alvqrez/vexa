import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_provider.dart';

class TransactionReportExporter {
  TransactionReportExporter(this._ref);

  final Ref _ref;

  /// Genera un reporte CSV de todas las transacciones
  String generateCSV() {
    final transactions = _ref.read(transactionsProvider);
    final accounts = _ref.read(accountsProvider);

    // Header del CSV
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Descripción,Cuenta,Categoría,Tipo,Monto');

    // Agregar cada transacción
    for (final tx in transactions.asMap().entries.toList().reversed) {
      final transaction = tx.value;
      final accountName = _getAccountName(transaction.accountId, accounts);

      final type = transaction.isIncome ? 'Ingreso' : 'Gasto';
      final amount = transaction.amount.toStringAsFixed(2);
      final date = _formatDate(transaction.date);

      // Escapar comillas en los campos de texto
      final merchant = _escapeCsv(transaction.merchant);
      final category = _escapeCsv(transaction.category);

      buffer.writeln('$date,$merchant,$accountName,$category,$type,$amount');
    }

    return buffer.toString();
  }

  String _getAccountName(String? accountId, List<dynamic> accounts) {
    if (accountId == null) return 'Desconocida';
    try {
      return accounts
          .firstWhere((a) => a.id == accountId, orElse: () => throw Exception())
          .name;
    } catch (_) {
      return 'Desconocida';
    }
  }

  /// Genera un reporte CSV con resumen mensual
  String generateMonthlySummaryCSV() {
    final transactions = _ref.read(transactionsProvider);
    final accounts = _ref.read(accountsProvider);

    // Agrupar transacciones por mes
    final monthlyData = <String, (double income, double expense)>{};

    for (final tx in transactions) {
      final monthKey =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      final current = monthlyData[monthKey] ?? (0.0, 0.0);

      if (tx.isIncome) {
        monthlyData[monthKey] = (current.$1 + tx.amount, current.$2);
      } else {
        monthlyData[monthKey] = (current.$1, current.$2 + tx.amount);
      }
    }

    // Header
    final buffer = StringBuffer();
    buffer.writeln('Mes,Ingresos,Gastos,Neto');

    // Agregar datos ordenados
    final sortedMonths = monthlyData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final month in sortedMonths) {
      final (income, expense) = monthlyData[month]!;
      final net = income - expense;

      buffer.writeln(
        '$month,${income.toStringAsFixed(2)},${expense.toStringAsFixed(2)},${net.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Genera un reporte con resumen por categoría
  String generateCategoryReportCSV() {
    final transactions = _ref.read(transactionsProvider);

    // Agrupar por categoría
    final categoryData = <String, (int count, double amount)>{};

    for (final tx in transactions) {
      if (tx.isIncome) continue; // Solo gastos

      final current = categoryData[tx.category] ?? (0, 0.0);
      categoryData[tx.category] = (current.$1 + 1, current.$2 + tx.amount);
    }

    // Header
    final buffer = StringBuffer();
    buffer.writeln('Categoría,Transacciones,Monto Total');

    // Agregar categorías ordenadas por monto
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    for (final entry in sortedCategories) {
      final (count, amount) = entry.value;
      buffer.writeln('${entry.key},$count,${amount.toStringAsFixed(2)}');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

final reportExporterProvider = Provider((ref) {
  return TransactionReportExporter(ref);
});
