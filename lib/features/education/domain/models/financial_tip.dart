import 'package:flutter/material.dart';

enum TipCategory { saving, budgeting, investing, debt, habits, mindset }

extension TipCategoryX on TipCategory {
  String get label => switch (this) {
        TipCategory.saving => 'Ahorro',
        TipCategory.budgeting => 'Presupuesto',
        TipCategory.investing => 'Inversión',
        TipCategory.debt => 'Deudas',
        TipCategory.habits => 'Hábitos',
        TipCategory.mindset => 'Mentalidad',
      };

  IconData get icon => switch (this) {
        TipCategory.saving => Icons.savings_rounded,
        TipCategory.budgeting => Icons.account_balance_wallet_rounded,
        TipCategory.investing => Icons.trending_up_rounded,
        TipCategory.debt => Icons.credit_card_off_rounded,
        TipCategory.habits => Icons.repeat_rounded,
        TipCategory.mindset => Icons.psychology_rounded,
      };

  Color get color => switch (this) {
        TipCategory.saving => const Color(0xFF00D68F),
        TipCategory.budgeting => const Color(0xFF1A7A9A),
        TipCategory.investing => const Color(0xFFFFD54F),
        TipCategory.debt => const Color(0xFFFF5F82),
        TipCategory.habits => const Color(0xFFCE93D8),
        TipCategory.mindset => const Color(0xFF64B5F6),
      };
}

class FinancialTip {
  const FinancialTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  final String id;
  final String title;
  final String content;
  final TipCategory category;
}

abstract final class FinancialTips {
  static const List<FinancialTip> all = [
    FinancialTip(
      id: 't1',
      title: 'La regla 50/30/20',
      content:
          'Destina el 50% de tus ingresos a necesidades, el 30% a deseos y el 20% al ahorro. Es la base de una buena salud financiera.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't2',
      title: 'Fondo de emergencia',
      content:
          'Antes de invertir, asegúrate de tener entre 3 y 6 meses de gastos en una cuenta de ahorro fácilmente accesible.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't3',
      title: 'El poder del interés compuesto',
      content:
          'Invertir \$100 al mes durante 30 años al 8% anual te da más de \$150,000. Empieza hoy, aunque sea poco.',
      category: TipCategory.investing,
    ),
    FinancialTip(
      id: 't4',
      title: 'Elimina deuda de alto interés',
      content:
          'Pagar una tarjeta con 20% de interés es equivalente a una inversión garantizada del 20%. Prioriza liquidarla.',
      category: TipCategory.debt,
    ),
    FinancialTip(
      id: 't5',
      title: 'Automatiza tu ahorro',
      content:
          'Configura una transferencia automática el día de cobro. Lo que no ves, no lo gastas.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't6',
      title: 'Presupuesto de gastos hormiga',
      content:
          'Un café de \$5 diario son \$1,825 al año. Identifica tus gastos pequeños recurrentes y evalúa cuáles valen la pena.',
      category: TipCategory.budgeting,
    ),
    FinancialTip(
      id: 't7',
      title: 'Invierte en ti mismo',
      content:
          'Aprender una nueva habilidad puede multiplicar tus ingresos más que cualquier inversión financiera. Tu mayor activo eres tú.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't8',
      title: 'Diversificación',
      content:
          'No pongas todos los huevos en una sola canasta. Diversifica entre diferentes tipos de activos para reducir riesgo.',
      category: TipCategory.investing,
    ),
    FinancialTip(
      id: 't9',
      title: 'Revisa tus suscripciones',
      content:
          'Una vez al mes revisa qué suscripciones tienes activas. Es común pagar por servicios que ya no usas.',
      category: TipCategory.habits,
    ),
    FinancialTip(
      id: 't10',
      title: 'Espera 24 horas',
      content:
          'Antes de una compra impulsiva, espera 24 horas. El 80% de las veces ya no querrás comprarlo.',
      category: TipCategory.mindset,
    ),
    FinancialTip(
      id: 't11',
      title: 'Negocia tus tarifas',
      content:
          'Llama a tus proveedores (internet, seguro, celular) y pide una tarifa mejor. Funciona más del 50% de las veces.',
      category: TipCategory.saving,
    ),
    FinancialTip(
      id: 't12',
      title: 'El método avalancha',
      content:
          'Para pagar deudas, ordénalas de mayor a menor interés y ataca la más costosa primero. Ahorras más en intereses.',
      category: TipCategory.debt,
    ),
  ];

  static FinancialTip get daily {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return all[dayOfYear % all.length];
  }
}
