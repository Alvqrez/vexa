import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/data/local_prefs_service.dart';

// ── Frecuencia ────────────────────────────────────────────────────────────────

enum ChallengeFrequency {
  daily,
  weekdays,
  weekly;

  String get label => switch (this) {
        daily => 'Todos los días',
        weekdays => 'Lunes a viernes',
        weekly => '1 vez por semana',
      };

  String get shortLabel => switch (this) {
        daily => 'Diario',
        weekdays => 'Lun–Vie',
        weekly => 'Semanal',
      };
}

// ── Modelo ────────────────────────────────────────────────────────────────────

/// Un reto o hábito que el usuario quiere construir.
/// Se marca día a día; el progreso, rachas y porcentaje de cumplimiento
/// se derivan de [completedDays].
class Challenge {
  const Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.durationDays,
    required this.startDate,
    this.completedDays = const {},
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final ChallengeFrequency frequency;
  final int durationDays;
  final DateTime startDate;

  /// Días completados como claves 'yyyy-MM-dd'.
  final Set<String> completedDays;
  final bool isArchived;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime get _start => DateTime(startDate.year, startDate.month, startDate.day);
  DateTime get endDate => _start.add(Duration(days: durationDays - 1));

  bool get isFinished {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(endDate);
  }

  /// ¿Este día cuenta para el reto según su frecuencia?
  bool isScheduled(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(_start) || d.isAfter(endDate)) return false;
    return switch (frequency) {
      ChallengeFrequency.daily => true,
      ChallengeFrequency.weekdays => d.weekday <= DateTime.friday,
      // semanal: cualquier día de la semana sirve para marcarlo
      ChallengeFrequency.weekly => true,
    };
  }

  bool isDoneOn(DateTime day) => completedDays.contains(dayKey(day));

  bool get isDoneToday => isDoneOn(DateTime.now());

  /// Para frecuencia semanal: ¿la semana de [day] ya tiene un registro?
  bool isWeekDone(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    for (var i = 0; i < 7; i++) {
      if (isDoneOn(monday.add(Duration(days: i)))) return true;
    }
    return false;
  }

  int get completedCount => completedDays.length;

  /// Días (o semanas) que ya deberían haberse cumplido hasta hoy.
  int get scheduledSoFar {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.isAfter(endDate) ? endDate : today;
    if (limit.isBefore(_start)) return 0;

    if (frequency == ChallengeFrequency.weekly) {
      return (limit.difference(_start).inDays ~/ 7) + 1;
    }
    var count = 0;
    for (var d = _start;
        !d.isAfter(limit);
        d = d.add(const Duration(days: 1))) {
      if (frequency == ChallengeFrequency.daily ||
          d.weekday <= DateTime.friday) {
        count++;
      }
    }
    return count;
  }

  /// 0–1: cuánto del reto cumplido respecto a lo que ya debió ocurrir.
  double get completionRate {
    final scheduled = scheduledSoFar;
    if (scheduled == 0) return 0;
    if (frequency == ChallengeFrequency.weekly) {
      var weeksDone = 0;
      for (var w = _start;
          !w.isAfter(endDate) && !w.isAfter(DateTime.now());
          w = w.add(const Duration(days: 7))) {
        if (isWeekDone(w)) weeksDone++;
      }
      return (weeksDone / scheduled).clamp(0.0, 1.0);
    }
    return (completedCount / scheduled).clamp(0.0, 1.0);
  }

  /// 0–1: avance temporal del reto (días transcurridos / duración).
  double get timeProgress {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(_start)) return 0;
    final elapsed = today.difference(_start).inDays + 1;
    return (elapsed / durationDays).clamp(0.0, 1.0);
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final left = endDate.difference(today).inDays;
    return left < 0 ? 0 : left;
  }

  /// Racha actual: días (o semanas) programados consecutivos completados,
  /// contando hacia atrás. Hoy pendiente no rompe la racha.
  int get currentStreak {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (frequency == ChallengeFrequency.weekly) {
      var streak = 0;
      var week = today.subtract(Duration(days: today.weekday - 1));
      // Semana actual pendiente no rompe la racha
      if (isWeekDone(week)) streak++;
      week = week.subtract(const Duration(days: 7));
      while (!week.isBefore(_start.subtract(const Duration(days: 6)))) {
        if (!isWeekDone(week)) break;
        streak++;
        week = week.subtract(const Duration(days: 7));
      }
      return streak;
    }

    var streak = 0;
    var d = today;
    // Hoy pendiente no rompe la racha
    if (isScheduled(d) && !isDoneOn(d)) d = d.subtract(const Duration(days: 1));
    while (!d.isBefore(_start)) {
      if (isScheduled(d)) {
        if (!isDoneOn(d)) break;
        streak++;
      }
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (frequency == ChallengeFrequency.weekly) {
      var longest = 0;
      var current = 0;
      for (var w = _start;
          !w.isAfter(endDate) && !w.isAfter(DateTime.now());
          w = w.add(const Duration(days: 7))) {
        if (isWeekDone(w)) {
          current++;
          if (current > longest) longest = current;
        } else {
          current = 0;
        }
      }
      return longest;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.isAfter(endDate) ? endDate : today;
    var longest = 0;
    var current = 0;
    for (var d = _start;
        !d.isAfter(limit);
        d = d.add(const Duration(days: 1))) {
      if (!isScheduled(d)) continue;
      if (isDoneOn(d)) {
        current++;
        if (current > longest) longest = current;
      } else if (!(d == today)) {
        current = 0;
      }
    }
    return longest;
  }

  Challenge copyWith({
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    ChallengeFrequency? frequency,
    int? durationDays,
    DateTime? startDate,
    Set<String>? completedDays,
    bool? isArchived,
  }) {
    return Challenge(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // ── Persistencia JSON (LocalPrefsService) ──────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon.codePoint,
        'color': color.toARGB32(),
        'frequency': frequency.name,
        'durationDays': durationDays,
        'startDate': startDate.toIso8601String(),
        'completedDays': completedDays.toList(),
        'isArchived': isArchived,
      };

  factory Challenge.fromJson(Map<String, dynamic> j) {
    DateTime start = DateTime.now();
    final rawDate = j['startDate'];
    if (rawDate is String) {
      try {
        start = DateTime.parse(rawDate);
      } catch (e) {
        debugPrint('Challenge: invalid startDate: $rawDate');
      }
    }
    final rawDays = j['completedDays'];
    final days = rawDays is List
        ? rawDays.map((e) => e.toString()).toSet()
        : <String>{};

    return Challenge(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      icon: IconData(
        j['icon'] is int ? j['icon'] as int : 0xe153,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(j['color'] is int ? j['color'] as int : 0xFF00D68F),
      frequency: ChallengeFrequency.values.firstWhere(
        (f) => f.name == j['frequency'],
        orElse: () => ChallengeFrequency.daily,
      ),
      durationDays: (j['durationDays'] as int?) ?? 30,
      startDate: start,
      completedDays: days,
      isArchived: j['isArchived'] as bool? ?? false,
    );
  }

  static const _key = 'challenges';

  static Future<List<Challenge>> loadAll() async {
    final raw = await LocalPrefsService.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .map((e) =>
              Challenge.fromJson(e is Map<String, dynamic> ? e : {}))
          .where((c) => c.id.isNotEmpty)
          .toList();
    } catch (e, st) {
      debugPrint('Challenge.loadAll error: $e\n$st');
      return [];
    }
  }

  static Future<void> saveAll(List<Challenge> items) async {
    final json = jsonEncode(items.map((c) => c.toJson()).toList());
    await LocalPrefsService.setString(_key, json);
  }
}
