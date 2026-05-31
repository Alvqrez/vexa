class Streak {
  const Streak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.lastTransactionDate,
  });

  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final DateTime lastTransactionDate;

  bool get isActiveToday {
    final now = DateTime.now();
    return lastActiveDate.year == now.year &&
        lastActiveDate.month == now.month &&
        lastActiveDate.day == now.day;
  }

  bool get hasTransactionToday {
    final now = DateTime.now();
    return lastTransactionDate.year == now.year &&
        lastTransactionDate.month == now.month &&
        lastTransactionDate.day == now.day;
  }

  static Streak get initial => Streak(
        currentStreak: 1,
        longestStreak: 7,
        lastActiveDate: DateTime.now(),
        lastTransactionDate: DateTime.now(),
      );

  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    DateTime? lastTransactionDate,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }
}
