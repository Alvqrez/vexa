import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';

/// Estado de un día dentro del heatmap.
enum HeatmapDayStatus { done, missed, pending, unscheduled }

class HeatmapDay {
  const HeatmapDay({required this.status, this.intensity = 1.0});

  final HeatmapDayStatus status;

  /// 0–1: qué tan "lleno" está el día (para heatmaps combinados).
  final double intensity;
}

/// Heatmap mensual estilo GitHub con navegación entre meses.
/// Columnas = semanas, filas = Lun…Dom.
class MonthHeatmap extends StatefulWidget {
  const MonthHeatmap({
    super.key,
    required this.dayBuilder,
    this.accentColor = AppColors.emerald,
    this.firstMonth,
  });

  /// Devuelve el estado de cada día del mes visible.
  final HeatmapDay Function(DateTime day) dayBuilder;
  final Color accentColor;

  /// Límite inferior de navegación (por defecto 12 meses atrás).
  final DateTime? firstMonth;

  @override
  State<MonthHeatmap> createState() => _MonthHeatmapState();
}

class _MonthHeatmapState extends State<MonthHeatmap> {
  late DateTime _month;

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _minMonth {
    final f = widget.firstMonth;
    if (f != null) return DateTime(f.year, f.month);
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month);
  }

  bool get _canGoBack => _month.isAfter(_minMonth);
  bool get _canGoForward {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _shift(int delta) {
    Haptics.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1=L
    final weeks = ((firstWeekday - 1 + daysInMonth) / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Navegación de mes ──────────────────────────────────────────
        Row(
          children: [
            _NavChevron(
              icon: Icons.chevron_left_rounded,
              enabled: _canGoBack,
              onTap: () => _shift(-1),
            ),
            Expanded(
              child: Text(
                '${_monthNames[_month.month - 1]} ${_month.year}',
                textAlign: TextAlign.center,
                style: AppTypography.labelL.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NavChevron(
              icon: Icons.chevron_right_rounded,
              enabled: _canGoForward,
              onTap: () => _shift(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Cuadrícula ─────────────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          const labelW = 18.0;
          const gap = 4.0;
          final cell =
              ((constraints.maxWidth - labelW - gap * weeks) / weeks)
                  .clamp(10.0, 30.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etiquetas de día
              Column(
                children: List.generate(7, (i) {
                  return Container(
                    width: labelW,
                    height: cell + gap,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _dayLabels[i],
                      style: AppTypography.labelS.copyWith(
                        color: c.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                  );
                }),
              ),
              // Semanas
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(weeks, (w) {
                    return Column(
                      children: List.generate(7, (d) {
                        final dayNum = w * 7 + d - (firstWeekday - 1) + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return _Cell(
                            size: cell,
                            gap: gap,
                            color: Colors.transparent,
                            border: Colors.transparent,
                          );
                        }
                        final date =
                            DateTime(_month.year, _month.month, dayNum);
                        final day = widget.dayBuilder(date);
                        return _buildDayCell(context, day, cell, gap, date);
                      }),
                    );
                  }),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.md),

        // ── Leyenda ────────────────────────────────────────────────────
        Row(
          children: [
            _LegendDot(
                color: widget.accentColor, label: 'Completado'),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(
                color: AppColors.negative.withValues(alpha: 0.35),
                label: 'Omitido'),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(color: c.glassMedium, label: 'Pendiente'),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, HeatmapDay day, double cell,
      double gap, DateTime date) {
    final c = context.colors;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    Color fill;
    Color border = Colors.transparent;
    switch (day.status) {
      case HeatmapDayStatus.done:
        fill = widget.accentColor
            .withValues(alpha: (0.30 + 0.70 * day.intensity).clamp(0.3, 1.0));
      case HeatmapDayStatus.missed:
        fill = AppColors.negative.withValues(alpha: 0.22);
      case HeatmapDayStatus.pending:
        fill = c.glassMedium;
      case HeatmapDayStatus.unscheduled:
        fill = c.glass;
    }
    if (isToday) border = widget.accentColor.withValues(alpha: 0.8);

    return _Cell(size: cell, gap: gap, color: fill, border: border);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.size,
    required this.gap,
    required this.color,
    required this.border,
  });
  final double size;
  final double gap;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: border, width: 1.2),
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? c.textSecondary
              : c.textTertiary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTypography.labelS
                .copyWith(color: c.textTertiary, fontSize: 10)),
      ],
    );
  }
}
