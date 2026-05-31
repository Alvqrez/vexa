import 'package:flutter/material.dart';
import '../../../home/domain/models/transaction.dart';

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
  final TransactionCategory category;
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

  DateTime get nextAfterCurrent =>
      nextBillingDate.add(Duration(days: frequency.daysInterval));

  Subscription copyWith({
    String? name,
    double? amount,
    DateTime? nextBillingDate,
    TransactionCategory? category,
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
