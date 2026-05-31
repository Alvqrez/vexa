import 'package:flutter/material.dart';

enum AchievementTier { bronze, silver, gold, platinum }

extension AchievementTierX on AchievementTier {
  String get label => switch (this) {
        AchievementTier.bronze => 'Bronce',
        AchievementTier.silver => 'Plata',
        AchievementTier.gold => 'Oro',
        AchievementTier.platinum => 'Platino',
      };

  Color get color => switch (this) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silver => const Color(0xFFC0C0C0),
        AchievementTier.gold => const Color(0xFFFFD700),
        AchievementTier.platinum => const Color(0xFF00D68F),
      };
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.xpReward,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final int xpReward;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Achievement unlock() => Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        tier: tier,
        xpReward: xpReward,
        unlockedAt: DateTime.now(),
      );
}

// All achievements defined as constants
abstract final class Achievements {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_transaction',
      title: 'Primer paso',
      description: 'Registra tu primera transacción',
      icon: Icons.add_circle_outline_rounded,
      tier: AchievementTier.bronze,
      xpReward: 50,
    ),
    Achievement(
      id: 'five_transactions',
      title: 'En racha',
      description: 'Registra 5 transacciones',
      icon: Icons.bolt_rounded,
      tier: AchievementTier.bronze,
      xpReward: 75,
    ),
    Achievement(
      id: 'twenty_transactions',
      title: 'Hábito formado',
      description: 'Registra 20 transacciones',
      icon: Icons.auto_awesome_rounded,
      tier: AchievementTier.silver,
      xpReward: 150,
    ),
    Achievement(
      id: 'first_goal',
      title: 'Soñador',
      description: 'Crea tu primera meta de ahorro',
      icon: Icons.flag_rounded,
      tier: AchievementTier.bronze,
      xpReward: 50,
    ),
    Achievement(
      id: 'goal_50pct',
      title: 'A mitad de camino',
      description: 'Llega al 50% de una meta',
      icon: Icons.trending_up_rounded,
      tier: AchievementTier.silver,
      xpReward: 100,
    ),
    Achievement(
      id: 'goal_complete',
      title: 'Meta cumplida',
      description: 'Completa una meta de ahorro',
      icon: Icons.emoji_events_rounded,
      tier: AchievementTier.gold,
      xpReward: 300,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Una semana',
      description: '7 días consecutivos registrando',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.bronze,
      xpReward: 100,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Mes completo',
      description: '30 días consecutivos registrando',
      icon: Icons.whatshot_rounded,
      tier: AchievementTier.gold,
      xpReward: 500,
    ),
    Achievement(
      id: 'saver_month',
      title: 'Buen ahorrador',
      description: 'Ahorra más del 20% de tus ingresos en un mes',
      icon: Icons.savings_rounded,
      tier: AchievementTier.silver,
      xpReward: 200,
    ),
    Achievement(
      id: 'health_excellent',
      title: 'Salud financiera',
      description: 'Alcanza salud financiera Excelente',
      icon: Icons.favorite_rounded,
      tier: AchievementTier.gold,
      xpReward: 250,
    ),
    Achievement(
      id: 'explorer',
      title: 'Explorador',
      description: 'Visita todas las secciones de la app',
      icon: Icons.explore_rounded,
      tier: AchievementTier.bronze,
      xpReward: 50,
    ),
    Achievement(
      id: 'budget_master',
      title: 'Presupuesto maestro',
      description: 'Mantén todos los presupuestos bajo control',
      icon: Icons.account_balance_wallet_rounded,
      tier: AchievementTier.silver,
      xpReward: 150,
    ),
  ];
}
