import 'package:flutter/material.dart';

class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
    required this.deadline,
    this.note,
    this.completed = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final double current;
  final double target;
  final DateTime deadline;
  final String? note;
  final bool completed;

  double get progress => (current / target).clamp(0.0, 1.0);
  bool get isCompleted => current >= target;
  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  String get deadlineLabel {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${months[deadline.month - 1]} ${deadline.year}';
  }

  String get progressLabel {
    final pct = (progress * 100).toStringAsFixed(0);
    return '$pct%';
  }

  FinancialGoal copyWith({
    double? current,
    bool? completed,
  }) {
    return FinancialGoal(
      id: id,
      title: title,
      icon: icon,
      color: color,
      current: current ?? this.current,
      target: target,
      deadline: deadline,
      note: note,
      completed: completed ?? this.completed,
    );
  }
}
