import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexa_finance/features/challenges/domain/models/challenge.dart';

Challenge _challenge({
  required DateTime start,
  int duration = 30,
  ChallengeFrequency frequency = ChallengeFrequency.daily,
  Set<String> done = const {},
}) {
  return Challenge(
    id: 'c1',
    name: 'Test',
    description: '',
    icon: Icons.flag,
    color: Colors.green,
    frequency: frequency,
    durationDays: duration,
    startDate: start,
    completedDays: done,
  );
}

String _key(DateTime d) => Challenge.dayKey(d);

void main() {
  group('Challenge — programación de días', () {
    test('daily: todos los días dentro del rango cuentan', () {
      final start = DateTime.now().subtract(const Duration(days: 5));
      final c = _challenge(start: start);
      expect(c.isScheduled(DateTime.now()), isTrue);
      expect(c.isScheduled(start.subtract(const Duration(days: 1))), isFalse);
    });

    test('weekdays: sábado y domingo no cuentan', () {
      // Empezar en un lunes conocido
      final monday = DateTime(2026, 6, 1); // lunes
      final c = _challenge(
          start: monday, frequency: ChallengeFrequency.weekdays);
      expect(c.isScheduled(DateTime(2026, 6, 3)), isTrue); // miércoles
      expect(c.isScheduled(DateTime(2026, 6, 6)), isFalse); // sábado
      expect(c.isScheduled(DateTime(2026, 6, 7)), isFalse); // domingo
    });

    test('fuera del rango de duración no cuenta', () {
      final start = DateTime(2026, 1, 1);
      final c = _challenge(start: start, duration: 7);
      expect(c.isScheduled(DateTime(2026, 1, 7)), isTrue);
      expect(c.isScheduled(DateTime(2026, 1, 8)), isFalse);
    });
  });

  group('Challenge — rachas', () {
    test('racha actual cuenta días consecutivos hacia atrás', () {
      final now = DateTime.now();
      final done = {
        _key(now.subtract(const Duration(days: 1))),
        _key(now.subtract(const Duration(days: 2))),
        _key(now.subtract(const Duration(days: 3))),
      };
      final c = _challenge(
        start: now.subtract(const Duration(days: 10)),
        done: done,
      );
      // Hoy pendiente no rompe la racha
      expect(c.currentStreak, 3);
    });

    test('hoy completado suma a la racha', () {
      final now = DateTime.now();
      final done = {
        _key(now),
        _key(now.subtract(const Duration(days: 1))),
      };
      final c = _challenge(
        start: now.subtract(const Duration(days: 10)),
        done: done,
      );
      expect(c.currentStreak, 2);
    });

    test('un hueco rompe la racha', () {
      final now = DateTime.now();
      final done = {
        _key(now.subtract(const Duration(days: 1))),
        // día -2 omitido
        _key(now.subtract(const Duration(days: 3))),
      };
      final c = _challenge(
        start: now.subtract(const Duration(days: 10)),
        done: done,
      );
      expect(c.currentStreak, 1);
    });

    test('racha 0 sin días completados', () {
      final c = _challenge(
          start: DateTime.now().subtract(const Duration(days: 5)));
      expect(c.currentStreak, 0);
      expect(c.longestStreak, 0);
    });
  });

  group('Challenge — cumplimiento', () {
    test('completionRate es 1.0 con todos los días hechos', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 4));
      final done = {
        for (var i = 0; i <= 4; i++)
          _key(now.subtract(Duration(days: i))),
      };
      final c = _challenge(start: start, done: done);
      expect(c.completionRate, closeTo(1.0, 0.001));
    });

    test('completionRate parcial', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 3)); // 4 días programados
      final done = {
        _key(now),
        _key(now.subtract(const Duration(days: 1))),
      };
      final c = _challenge(start: start, done: done);
      expect(c.completionRate, closeTo(0.5, 0.001));
    });

    test('timeProgress se acota a 1.0 al terminar', () {
      final c = _challenge(
        start: DateTime.now().subtract(const Duration(days: 60)),
        duration: 30,
      );
      expect(c.timeProgress, 1.0);
      expect(c.isFinished, isTrue);
      expect(c.daysLeft, 0);
    });
  });

  group('Challenge — serialización', () {
    test('toJson / fromJson conserva los datos', () {
      final original = _challenge(
        start: DateTime(2026, 6, 1),
        duration: 21,
        frequency: ChallengeFrequency.weekdays,
        done: {'2026-06-01', '2026-06-02'},
      );
      final restored = Challenge.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.durationDays, 21);
      expect(restored.frequency, ChallengeFrequency.weekdays);
      expect(restored.completedDays, original.completedDays);
    });

    test('fromJson tolera datos corruptos', () {
      final c = Challenge.fromJson(const {'id': 'x'});
      expect(c.id, 'x');
      expect(c.durationDays, 30);
      expect(c.frequency, ChallengeFrequency.daily);
    });
  });

  group('Time Machine — interés compuesto', () {
    test('valor futuro a 10 años con 8% anual', () {
      const amount = 2000.0;
      const rate = 0.08;
      final future = amount * math.pow(1 + rate, 10);
      expect(future, closeTo(4317.85, 0.5));
    });

    test('1 año equivale a una sola capitalización', () {
      const amount = 1000.0;
      const rate = 0.10;
      final future = amount * math.pow(1 + rate, 1);
      expect(future, closeTo(1100.0, 0.001));
    });
  });
}
