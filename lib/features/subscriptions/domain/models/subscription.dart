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
        SubscriptionFrequency.weekly => 365.0 / 12.0 / 7.0,
        SubscriptionFrequency.monthly => 1.0,
        SubscriptionFrequency.quarterly => 1.0 / 3.0,
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
        final last = DateTime(ny, nm + 1, 0).day;
        return DateTime(ny, nm, d.day.clamp(1, last));
      case SubscriptionFrequency.quarterly:
        final nm = d.month + 3;
        final ny = d.year + (nm - 1) ~/ 12;
        final m = ((nm - 1) % 12) + 1;
        final last = DateTime(ny, m + 1, 0).day;
        return DateTime(ny, m, d.day.clamp(1, last));
      case SubscriptionFrequency.annual:
        final last = DateTime(d.year + 1, d.month + 1, 0).day;
        return DateTime(d.year + 1, d.month, d.day.clamp(1, last));
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
