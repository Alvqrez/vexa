import 'package:flutter/material.dart';

enum LoanType { lentByMe, borrowedByMe }

extension LoanTypeX on LoanType {
  String get label => this == LoanType.lentByMe ? 'Yo presté' : 'Pedí prestado';
  String get shortLabel => this == LoanType.lentByMe ? 'presté' : 'debo';
  String get actionLabel =>
      this == LoanType.lentByMe ? 'Registrar cobro' : 'Registrar pago';
}

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.amount,
    required this.paidAmount,
    required this.type,
    required this.date,
    required this.icon,
    required this.color,
    this.accountId,
    this.dueDate,
    this.note,
  });

  final String id;
  final String name;
  final double amount;
  final double paidAmount;
  final LoanType type;
  final DateTime date;
  final String? accountId;
  final DateTime? dueDate;
  final IconData icon;
  final Color color;
  final String? note;

  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, double.infinity);
  // Allow tolerance of 1 cent for floating point precision
  bool get isSettled => remainingAmount <= 0.01;
  double get progressFraction =>
      amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  bool get isDueSoon {
    if (dueDate == null || isSettled) return false;
    final days = dueDate!.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 7;
  }

  bool get isOverdue {
    if (dueDate == null || isSettled) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  Loan copyWith({
    String? name,
    double? amount,
    double? paidAmount,
    LoanType? type,
    DateTime? date,
    String? accountId,
    DateTime? dueDate,
    IconData? icon,
    Color? color,
    String? note,
    bool clearDueDate = false,
    bool clearNote = false,
  }) {
    return Loan(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}
