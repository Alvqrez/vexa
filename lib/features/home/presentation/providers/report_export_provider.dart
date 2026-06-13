import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/domain/models/subcategory.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/subcategories_provider.dart';

class TransactionReportExporter {
  TransactionReportExporter(this._ref);

  final Ref _ref;

  /// Genera un reporte CSV de todas las transacciones
  String generateCSV() {
    final transactions = _ref.read(transactionsProvider);
    final accounts = _ref.read(accountsProvider);
    final categories = _ref.read(walletCategoriesProvider);
    final subcategories = _ref.read(subcategoriesProvider);

    // Header del CSV
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Descripción,Cuenta,Categoría,Subcategoría,Tipo,Monto');

    // Agregar cada transacción
    for (final tx in transactions.asMap().entries.toList().reversed) {
      final transaction = tx.value;
      final accountName = _getAccountName(transaction.accountId, accounts);

      final type = transaction.isIncome ? 'Ingreso' : 'Gasto';
      final amount = transaction.amount.toStringAsFixed(2);
      final date = _formatDate(transaction.date);

      // Escapar comillas en los campos de texto
      final merchant = _escapeCsv(transaction.merchant);
      final category =
          _escapeCsv(resolveCategory(transaction.category, categories).name);
      final subcategory = _escapeCsv(
          resolveSubcategory(transaction.subcategoryId, subcategories)?.name ??
              '');

      buffer.writeln(
          '$date,$merchant,$accountName,$category,$subcategory,$type,$amount');
    }

    return buffer.toString();
  }

  String _getAccountName(String? accountId, List<dynamic> accounts) {
    if (accountId == null) return 'Desconocida';
    try {
      final account = accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => null,
      );
      return account?.name ?? 'Desconocida';
    } catch (e) {
      debugPrint('TransactionReportExporter._getAccountName: $e');
      return 'Desconocida';
    }
  }

  /// Genera un reporte CSV con resumen mensual
  String generateMonthlySummaryCSV() {
    final transactions = _ref.read(transactionsProvider);

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

  /// Genera un reporte con resumen por categoría y subcategoría
  String generateCategoryReportCSV() {
    final transactions = _ref.read(transactionsProvider);
    final categories = _ref.read(walletCategoriesProvider);
    final subcategories = _ref.read(subcategoriesProvider);

    // Agrupar por (categoría, subcategoría)
    final categoryData = <(String, String?), (int count, double amount)>{};

    for (final tx in transactions) {
      if (tx.isIncome) continue; // Solo gastos

      final key = (tx.category, tx.subcategoryId);
      final current = categoryData[key] ?? (0, 0.0);
      categoryData[key] = (current.$1 + 1, current.$2 + tx.amount);
    }

    // Header
    final buffer = StringBuffer();
    buffer.writeln('Categoría,Subcategoría,Transacciones,Monto Total');

    // Agregar categorías ordenadas por monto
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    for (final entry in sortedCategories) {
      final (count, amount) = entry.value;
      final catName =
          _escapeCsv(resolveCategory(entry.key.$1, categories).name);
      final subName = _escapeCsv(
          resolveSubcategory(entry.key.$2, subcategories)?.name ?? '');
      buffer.writeln('$catName,$subName,$count,${amount.toStringAsFixed(2)}');
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
