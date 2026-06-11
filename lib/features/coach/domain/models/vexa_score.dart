import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Nivel cualitativo del Vexa Score.
enum VexaScoreLevel { atRisk, building, stable, solid, elite }

extension VexaScoreLevelX on VexaScoreLevel {
  String get label => switch (this) {
        VexaScoreLevel.atRisk => 'En riesgo',
        VexaScoreLevel.building => 'En construcción',
        VexaScoreLevel.stable => 'Estable',
        VexaScoreLevel.solid => 'Sólido',
        VexaScoreLevel.elite => 'Élite',
      };

  Color get color => switch (this) {
        VexaScoreLevel.atRisk => AppColors.negative,
        VexaScoreLevel.building => AppColors.warning,
        VexaScoreLevel.stable => AppColors.petroleumLight,
        VexaScoreLevel.solid => AppColors.emerald,
        VexaScoreLevel.elite => AppColors.emerald,
      };
}

/// Score financiero integral (0–100) calculado localmente a partir de:
/// ahorro, cumplimiento de presupuesto, consistencia de registro,
/// control de gastos excesivos y salud general.
class VexaScore {
  const VexaScore({
    required this.score,
    required this.savingsScore,
    required this.budgetScore,
    required this.consistencyScore,
    required this.excessScore,
    required this.healthScore,
    required this.hasData,
  });

  final double score;
  final double savingsScore; // tasa de ahorro vs objetivo 20%
  final double budgetScore; // cumplimiento de límites de presupuesto
  final double consistencyScore; // constancia registrando movimientos
  final double excessScore; // ausencia de días de gasto desproporcionado
  final double healthScore; // salud general (ingresos, balance, ahorro)
  final bool hasData;

  VexaScoreLevel get level => score >= 90
      ? VexaScoreLevel.elite
      : score >= 75
          ? VexaScoreLevel.solid
          : score >= 60
              ? VexaScoreLevel.stable
              : score >= 40
                  ? VexaScoreLevel.building
                  : VexaScoreLevel.atRisk;

  /// El factor más débil, para explicar qué mejorar primero.
  ({String name, double value, String advice}) get weakestFactor {
    final factors = [
      (
        name: 'Ahorro',
        value: savingsScore,
        advice: 'Aparta al menos el 20% de tus ingresos cada mes.'
      ),
      (
        name: 'Presupuesto',
        value: budgetScore,
        advice: 'Define límites por categoría y respétalos.'
      ),
      (
        name: 'Consistencia',
        value: consistencyScore,
        advice: 'Registra tus gastos con regularidad para ver el panorama real.'
      ),
      (
        name: 'Control de excesos',
        value: excessScore,
        advice: 'Evita días de gasto muy por encima de tu promedio.'
      ),
      (
        name: 'Salud general',
        value: healthScore,
        advice: 'Procura que tus ingresos superen tus gastos cada mes.'
      ),
    ];
    factors.sort((a, b) => a.value.compareTo(b.value));
    return factors.first;
  }

  static const empty = VexaScore(
    score: 0,
    savingsScore: 0,
    budgetScore: 0,
    consistencyScore: 0,
    excessScore: 0,
    healthScore: 0,
    hasData: false,
  );
}
