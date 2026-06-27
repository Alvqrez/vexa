import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/id_gen.dart';
import '../../domain/models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../widgets/month_heatmap.dart';
import 'challenge_detail_page.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final active = ref.watch(activeChallengesProvider);
    final finished = ref.watch(finishedChallengesProvider);
    final all = ref.watch(challengesProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // ── Header ─────────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c.glass,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: c.glassBorder, width: 0.5),
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  size: 18, color: c.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text('Retos y hábitos',
                                style: AppTypography.headingM
                                    .copyWith(color: c.textPrimary)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Haptics.lightImpact();
                              showCreateChallengeSheet(context, ref);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.emerald,
                                  AppColors.emeraldDim
                                ]),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.pillRadius),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 14,
                                      color: AppColors.textInverse),
                                  const SizedBox(width: 4),
                                  Text('Nuevo reto',
                                      style: AppTypography.labelM.copyWith(
                                        color: AppColors.textInverse,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      if (all.isEmpty)
                        _EmptyChallenges(
                            onCreate: () =>
                                showCreateChallengeSheet(context, ref))
                      else ...[
                        // ── Heatmap global del mes ───────────────────
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: c.glassBorder, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tu constancia',
                                  style: AppTypography.labelL.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: AppSpacing.md),
                              MonthHeatmap(
                                dayBuilder: (day) =>
                                    _combinedDay(all, day),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // ── Retos activos ────────────────────────────
                        if (active.isNotEmpty) ...[
                          Text('En curso',
                              style: AppTypography.headingS.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: AppSpacing.md),
                          for (final ch in active) ...[
                            _ChallengeCard(challenge: ch),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],

                        // ── Terminados ───────────────────────────────
                        if (finished.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text('Terminados',
                              style: AppTypography.headingS.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: AppSpacing.md),
                          for (final ch in finished) ...[
                            _ChallengeCard(challenge: ch),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ],

                      const SizedBox(height: AppSpacing.huge),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Intensidad combinada de todos los retos para el heatmap global.
  HeatmapDay _combinedDay(List<Challenge> all, DateTime day) {
    final scheduled =
        all.where((c) => !c.isArchived && c.isScheduled(day)).toList();
    if (scheduled.isEmpty) {
      return const HeatmapDay(status: HeatmapDayStatus.unscheduled);
    }
    final done = scheduled.where((c) => c.isDoneOn(day)).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);

    if (done > 0) {
      return HeatmapDay(
        status: HeatmapDayStatus.done,
        intensity: done / scheduled.length,
      );
    }
    if (d.isBefore(today)) {
      return const HeatmapDay(status: HeatmapDayStatus.missed);
    }
    return const HeatmapDay(status: HeatmapDayStatus.pending);
  }
}

// ── Tarjeta de reto ───────────────────────────────────────────────────────────

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ch = challenge;
    final now = DateTime.now();
    final doneToday = ch.frequency == ChallengeFrequency.weekly
        ? ch.isWeekDone(now)
        : ch.isDoneToday;
    final canMarkToday = !ch.isFinished && ch.isScheduled(now);

    return GestureDetector(
      onTap: () {
        Haptics.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChallengeDetailPage(challengeId: ch.id),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ch.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(ch.icon, size: 19, color: ch.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch.name,
                          style: AppTypography.labelL.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(ch.frequency.shortLabel,
                              style: AppTypography.labelS
                                  .copyWith(color: c.textTertiary)),
                          Text('  ·  ',
                              style: AppTypography.labelS
                                  .copyWith(color: c.textTertiary)),
                          Icon(Icons.local_fire_department_rounded,
                              size: 12,
                              color: ch.currentStreak > 0
                                  ? AppColors.warning
                                  : c.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            '${ch.currentStreak}',
                            style: AppTypography.labelS.copyWith(
                              color: ch.currentStreak > 0
                                  ? AppColors.warning
                                  : c.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (ch.isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                    child: Text(
                      '${(ch.completionRate * 100).round()}%',
                      style: AppTypography.labelM.copyWith(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                else if (canMarkToday)
                  GestureDetector(
                    onTap: () {
                      Haptics.mediumImpact();
                      ref
                          .read(challengesProvider.notifier)
                          .toggleDay(ch.id, now);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: doneToday
                            ? ch.color
                            : ch.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: doneToday
                              ? ch.color
                              : ch.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 19,
                        color: doneToday
                            ? Colors.white
                            : ch.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Barra de avance temporal + cumplimiento
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                width: double.infinity,
                color: ch.color.withValues(alpha: 0.12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ch.timeProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        ch.color,
                        ch.color.withValues(alpha: 0.6)
                      ]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ch.isFinished
                      ? 'Reto terminado'
                      : '${ch.daysLeft} días restantes',
                  style:
                      AppTypography.labelS.copyWith(color: c.textSecondary),
                ),
                Text(
                  'Cumplimiento: ${(ch.completionRate * 100).round()}%',
                  style:
                      AppTypography.labelS.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.emeraldSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.emoji_events_outlined,
              size: 30, color: AppColors.emerald),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Sin retos aún',
            style: AppTypography.headingS.copyWith(color: c.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Los hábitos pequeños construyen finanzas grandes.\nCrea tu primer reto y mantén la racha.',
          style: AppTypography.bodyS
              .copyWith(color: c.textTertiary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        GestureDetector(
          onTap: onCreate,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.emerald, AppColors.emeraldDim]),
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
            child: Text('Crear primer reto',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ],
    );
  }
}

// ── Crear reto ────────────────────────────────────────────────────────────────

void showCreateChallengeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _CreateChallengeSheet(
      onCreate: (ch) => ref.read(challengesProvider.notifier).add(ch),
    ),
  );
}

class _ChallengeTemplate {
  const _ChallengeTemplate(this.name, this.description, this.icon, this.color);
  final String name;
  final String description;
  final IconData icon;
  final Color color;
}

class _CreateChallengeSheet extends StatefulWidget {
  const _CreateChallengeSheet({required this.onCreate});
  final Future<void> Function(Challenge) onCreate;

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ChallengeFrequency _frequency = ChallengeFrequency.daily;
  int _duration = 30;
  int _iconIdx = 0;
  int _colorIdx = 0;

  static const _templates = [
    _ChallengeTemplate('Ahorrar diariamente',
        'Guarda algo de dinero cada día, aunque sea poco.',
        Icons.savings_outlined, AppColors.emerald),
    _ChallengeTemplate('Sin refresco',
        'Cero refrescos. Tu salud y tu cartera lo agradecen.',
        Icons.no_drinks_outlined, AppColors.catTransport),
    _ChallengeTemplate('Sin comida rápida',
        'Evita la comida rápida y cocina en casa.',
        Icons.fastfood_outlined, AppColors.catFood),
    _ChallengeTemplate('Registrar gastos',
        'Registra todos tus gastos del día en Vexa.',
        Icons.edit_note_rounded, AppColors.petroleum),
    _ChallengeTemplate('Leer 10 minutos',
        'Lee al menos 10 minutos al día.',
        Icons.menu_book_outlined, AppColors.catShopping),
    _ChallengeTemplate('Caminar',
        'Sal a caminar todos los días.',
        Icons.directions_walk_rounded, AppColors.catHealth),
    _ChallengeTemplate('Tomar agua',
        'Toma suficiente agua durante el día.',
        Icons.water_drop_outlined, AppColors.catTransport),
  ];

  static const _icons = [
    Icons.savings_outlined,
    Icons.no_drinks_outlined,
    Icons.fastfood_outlined,
    Icons.edit_note_rounded,
    Icons.menu_book_outlined,
    Icons.directions_walk_rounded,
    Icons.water_drop_outlined,
    Icons.fitness_center_rounded,
    Icons.bedtime_outlined,
    Icons.emoji_events_outlined,
  ];
  static const _colors = [
    AppColors.emerald,
    AppColors.petroleum,
    AppColors.catFood,
    AppColors.catTransport,
    AppColors.catShopping,
    AppColors.catEntertainment,
    AppColors.catHealth,
    AppColors.warning,
  ];
  static const _durations = [7, 14, 21, 30, 60, 90];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(_ChallengeTemplate t) {
    Haptics.selectionClick();
    setState(() {
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description;
      final ic = _icons.indexOf(t.icon);
      if (ic >= 0) _iconIdx = ic;
      final col =
          _colors.indexWhere((c) => c.toARGB32() == t.color.toARGB32());
      if (col >= 0) _colorIdx = col;
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Haptics.heavyImpact();
      return;
    }
    final challenge = Challenge(
      id: generateId(),
      name: name,
      description: _descCtrl.text.trim(),
      icon: _icons[_iconIdx],
      color: _colors[_colorIdx],
      frequency: _frequency,
      durationDays: _duration,
      startDate: DateTime.now(),
    );
    Haptics.mediumImpact();
    await widget.onCreate(challenge);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md,
          AppSpacing.xxl, AppSpacing.xxl + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Nuevo reto',
                style:
                    AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.lg),

            // Plantillas sugeridas
            Text('Sugerencias',
                style: AppTypography.labelM.copyWith(color: c.textTertiary)),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (_, i) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final t = _templates[i];
                  return GestureDetector(
                    onTap: () => _applyTemplate(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                            color: t.color.withValues(alpha: 0.30),
                            width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(t.icon, size: 13, color: t.color),
                          const SizedBox(width: 5),
                          Text(t.name,
                              style: AppTypography.labelM.copyWith(
                                  color: t.color,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nombre y descripción
            _SheetField(_nameCtrl, 'Nombre del reto', Icons.flag_outlined),
            const SizedBox(height: AppSpacing.md),
            _SheetField(
                _descCtrl, 'Descripción (opcional)', Icons.notes_rounded),
            const SizedBox(height: AppSpacing.lg),

            // Frecuencia
            Text('Frecuencia',
                style: AppTypography.labelM.copyWith(color: c.textTertiary)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: ChallengeFrequency.values.map((f) {
                final sel = f == _frequency;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () {
                      Haptics.selectionClick();
                      setState(() => _frequency = f);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            sel ? AppColors.emeraldSurface : c.glass,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? AppColors.emerald.withValues(alpha: 0.4)
                              : c.glassBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Text(f.label,
                          style: TextStyle(
                            color: sel
                                ? AppColors.emerald
                                : c.textTertiary,
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Duración
            Text('Duración',
                style: AppTypography.labelM.copyWith(color: c.textTertiary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _durations.map((d) {
                final sel = d == _duration;
                return GestureDetector(
                  onTap: () {
                    Haptics.selectionClick();
                    setState(() => _duration = d);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.emeraldSurface : c.glass,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : c.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Text('$d días',
                        style: TextStyle(
                          color: sel ? AppColors.emerald : c.textTertiary,
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Icono
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, i) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final sel = i == _iconIdx;
                  final col = _colors[_colorIdx];
                  return GestureDetector(
                    onTap: () {
                      Haptics.selectionClick();
                      setState(() => _iconIdx = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel
                            ? col.withValues(alpha: 0.18)
                            : c.glass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? col.withValues(alpha: 0.5)
                              : c.glassBorder,
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Icon(_icons[i],
                          size: 20, color: sel ? col : c.textTertiary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Color
            Wrap(
              spacing: AppSpacing.sm,
              children: List.generate(_colors.length, (i) {
                final sel = i == _colorIdx;
                return GestureDetector(
                  onTap: () {
                    Haptics.selectionClick();
                    setState(() => _colorIdx = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              sel ? Colors.white : Colors.transparent,
                          width: 2.5),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Crear
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim]),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.30),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Text('Comenzar reto',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelL.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField(this.controller, this.hint, this.icon);
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypography.bodyM.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(color: c.textTertiary),
          prefixIcon: Icon(icon, size: 17, color: c.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
