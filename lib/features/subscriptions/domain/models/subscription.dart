import 'package:flutter/material.dart';

enum SubscriptionFrequency { weekly, monthly, quarterly, annual }

extension SubscriptionFrequencyX on SubscriptionFrequency {
  String get label => switch (this) {
        SubscriptionFrequency.weekly => 'Semanal',
        SubscriptionFrequency.monthly => 'Mensual',
        SubscriptionFrequency.quarterly => 'Trimestral',
        SubscriptionFrequency.annual => 'Anual',
      };

  String get shortLabel => switch (this) {
        SubscriptionFrequency.weekly => '/sem',
        SubscriptionFrequency.monthly => '/mes',
        SubscriptionFrequency.quarterly => '/trim',
        SubscriptionFrequency.annual => '/año',
      };

  int get daysInterval => switch (this) {
        SubscriptionFrequency.weekly => 7,
        SubscriptionFrequency.monthly => 30,
        SubscriptionFrequency.quarterly => 90,
        SubscriptionFrequency.annual => 365,
      };

  double get monthlyFactor => switch (this) {
        // 52.14 weeks per year ÷ 12 months = 4.345 weeks per month
        SubscriptionFrequency.weekly => 52.14 / 12.0,
        SubscriptionFrequency.monthly => 1.0,
        // Quarterly = every 3 months = 1/3 of monthly
        SubscriptionFrequency.quarterly => 1.0 / 3.0,
        // Annual = 1 payment per 12 months = 1/12 per month
        SubscriptionFrequency.annual => 1.0 / 12.0,
      };
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.nextBillingDate,
    required this.category,
    required this.icon,
    required this.color,
    required this.frequency,
    this.isActive = true,
    this.note,
  });

  final String id;
  final String name;
  final double amount;
  final DateTime nextBillingDate;
  /// WalletCategory.id (e.g. 'wc4').
  final String category;
  final IconData icon;
  final Color color;
  final SubscriptionFrequency frequency;
  final bool isActive;
  final String? note;

  double get monthlyEquivalent => amount * frequency.monthlyFactor;

  int get daysUntilBilling =>
      nextBillingDate.difference(DateTime.now()).inDays.clamp(0, 999);

  bool get isDueSoon => daysUntilBilling <= 7;
  bool get isDueToday => daysUntilBilling == 0;

  DateTime get nextAfterCurrent {
    final d = nextBillingDate;
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return d.add(const Duration(days: 7));
      case SubscriptionFrequency.monthly:
        final nm = d.month == 12 ? 1 : d.month + 1;
        final ny = d.month == 12 ? d.year + 1 : d.year;
        final lastDay = DateTime(ny, nm + 1, 0).day;
        return DateTime(ny, nm, d.day.clamp(1, lastDay), d.hour, d.minute);
      case SubscriptionFrequency.quarterly:
        var qm = d.month + 3;
        var qy = d.year;
        while (qm > 12) {
          qm -= 12;
          qy += 1;
        }
        final lastDay = DateTime(qy, qm + 1, 0).day;
        return DateTime(qy, qm, d.day.clamp(1, lastDay), d.hour, d.minute);
      case SubscriptionFrequency.annual:
        final lastDay = DateTime(d.year + 1, d.month + 1, 0).day;
        return DateTime(d.year + 1, d.month, d.day.clamp(1, lastDay), d.hour, d.minute);
    }
  }

  Subscription copyWith({
    String? name,
    double? amount,
    DateTime? nextBillingDate,
    String? category,
    IconData? icon,
    Color? color,
    SubscriptionFrequency? frequency,
    bool? isActive,
    String? note,
    bool clearNote = false,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}
