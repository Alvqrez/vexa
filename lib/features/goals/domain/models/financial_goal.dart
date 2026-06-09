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

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => target > 0 && current >= target;
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
    String? title,
    IconData? icon,
    Color? color,
    double? current,
    double? target,
    DateTime? deadline,
    String? note,
    bool? completed,
  }) {
    return FinancialGoal(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      current: current ?? this.current,
      target: target ?? this.target,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      completed: completed ?? this.completed,
    );
  }
}
