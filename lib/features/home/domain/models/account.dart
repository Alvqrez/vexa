import 'package:flutter/material.dart';

enum AccountIcon { bank, creditCard, wallet, savings, investment, cash }

extension AccountIconData on AccountIcon {
  IconData get iconData {
    switch (this) {
      case AccountIcon.bank:
        return Icons.account_balance_outlined;
      case AccountIcon.creditCard:
        return Icons.credit_card_rounded;
      case AccountIcon.wallet:
        return Icons.account_balance_wallet_outlined;
      case AccountIcon.savings:
        return Icons.savings_outlined;
      case AccountIcon.investment:
        return Icons.trending_up_rounded;
      case AccountIcon.cash:
        return Icons.payments_outlined;
    }
  }
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final double balance;
  final Color color;
  final AccountIcon icon;

  Account copyWith({
    String? name,
    double? balance,
    Color? color,
    AccountIcon? icon,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
