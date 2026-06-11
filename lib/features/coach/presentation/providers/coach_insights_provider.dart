import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/insights_engine.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../core/providers/settings_provider.dart';

/// Insights generados localmente a partir de los datos del usuario.
final coachInsightsProvider = Provider<List<CoachInsight>>((ref) {
  final engine = InsightsEngine(
    transactions: ref.watch(transactionsProvider),
    categories: ref.watch(walletCategoriesProvider),
    monthlySavings: ref.watch(monthlySavingsProvider),
    currency: ref.watch(currencySymbolProvider),
  );
  return engine.build();
});
