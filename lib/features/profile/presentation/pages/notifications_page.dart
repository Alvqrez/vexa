import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../education/domain/models/financial_tip.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  bool _transactions = true;
  bool _budgetAlerts = true;
  bool _weeklySummary = true;
  bool _marketing = false;
  bool _security = true;
  bool _prediction = true;
  bool _dailyTip = true;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, int total, Widget child) {
    final start = i / total * 0.5;
    final end = (start + 0.6).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.gentle)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _stagger,
            curve: Interval(start, end, curve: AppCurves.spring))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ProfileSubBg(),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),
                      _reveal(
                          0, 4, const _SubPageHeader(title: 'Notificaciones')),
                      const SizedBox(height: AppSpacing.xxl),

                      _reveal(
                          0,
                          5,
                          _IntelligenceSection(
                            prediction: ref.watch(predictionProvider),
                            tip: FinancialTips.daily,
                            predictionEnabled: _prediction,
                            tipEnabled: _dailyTip,
                            onPredictionChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _prediction = v);
                            },
                            onTipChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _dailyTip = v);
                            },
                          )),
                      const SizedBox(height: AppSpacing.lg),

                      _reveal(
                          1,
                          5,
                          _NotifSection(
                            title: 'Actividad',
                            items: [
                              _NotifItem(
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.petroleum,
                                title: 'Transacciones',
                                subtitle:
                                    'Recibe un aviso en cada movimiento.',
                                value: _transactions,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _transactions = v);
                                },
                              ),
                              _NotifItem(
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                title: 'Alertas de presupuesto',
                                subtitle:
                                    'Avisa al acercarte al límite mensual.',
                                value: _budgetAlerts,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _budgetAlerts = v);
                                },
                              ),
                            ],
                          )),
                      const SizedBox(height: AppSpacing.lg),

                      _reveal(
                          2,
                          4,
                          _NotifSection(
                            title: 'Resúmenes',
                            items: [
                              _NotifItem(
                                icon: Icons.bar_chart_rounded,
                                color: AppColors.emerald,
                                title: 'Resumen semanal',
                                subtitle:
                                    'Un vistazo a tus finanzas cada lunes.',
                                value: _weeklySummary,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _weeklySummary = v);
                                },
                              ),
                            ],
                          )),
                      const SizedBox(height: AppSpacing.lg),

                      _reveal(
                          3,
                          4,
                          _NotifSection(
                            title: 'Seguridad y otros',
                            items: [
                              _NotifItem(
                                icon: Icons.lock_outline_rounded,
                                color: AppColors.catTransport,
                                title: 'Alertas de seguridad',
                                subtitle:
                                    'Inicio de sesión y cambios de cuenta.',
                                value: _security,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _security = v);
                                },
                              ),
                              _NotifItem(
                                icon: Icons.campaign_outlined,
                                color: AppColors.textTertiary,
                                title: 'Ofertas y novedades',
                                subtitle: 'Noticias y promociones de Vexa.',
                                value: _marketing,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _marketing = v);
                                },
                              ),
                            ],
                          )),
                      const SizedBox(height: AppSpacing.xxxl),
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
}

class _NotifItem {
  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _NotifSection extends StatelessWidget {
  const _NotifSection({required this.title, required this.items});
  final String title;
  final List<_NotifItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            title,
            style: AppTypography.labelL.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _NotifRow(item: items[i]),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.glassBorder),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.item});
  final _NotifItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 17, color: item.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTypography.labelL
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch.adaptive(
            value: item.value,
            onChanged: item.onChanged,
            activeThumbColor: AppColors.emerald,
            activeTrackColor: AppColors.emeraldSurface,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.glassLight,
          ),
        ],
      ),
    );
  }
}

// ── Intelligence section ──────────────────────────────────────────────────────

class _IntelligenceSection extends StatefulWidget {
  const _IntelligenceSection({
    required this.prediction,
    required this.tip,
    required this.predictionEnabled,
    required this.tipEnabled,
    required this.onPredictionChanged,
    required this.onTipChanged,
  });

  final MonthlyPrediction prediction;
  final FinancialTip tip;
  final bool predictionEnabled;
  final bool tipEnabled;
  final ValueChanged<bool> onPredictionChanged;
  final ValueChanged<bool> onTipChanged;

  @override
  State<_IntelligenceSection> createState() => _IntelligenceSectionState();
}

class _IntelligenceSectionState extends State<_IntelligenceSection> {
  bool _showPredDetail = false;
  bool _showTipDetail = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            'Inteligencia financiera',
            style: AppTypography.labelL.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Column(
            children: [
              // Prediction toggle + expandable detail
              _IntelRow(
                icon: Icons.auto_graph_rounded,
                color: widget.prediction.isOnTrack
                    ? AppColors.emerald
                    : AppColors.negative,
                title: 'Predicción del mes',
                subtitle: 'Proyección diaria de tu cierre mensual.',
                value: widget.predictionEnabled,
                onChanged: widget.onPredictionChanged,
                expanded: _showPredDetail,
                onExpand: () =>
                    setState(() => _showPredDetail = !_showPredDetail),
                expandedContent: _PredictionDetail(
                    prediction: widget.prediction),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Divider(
                    height: 1, thickness: 0.5, color: AppColors.glassBorder),
              ),
              // Tip toggle + expandable detail
              _IntelRow(
                icon: Icons.lightbulb_outline_rounded,
                color: widget.tip.category.color,
                title: 'Consejo del día',
                subtitle: 'Un consejo financiero nuevo cada día.',
                value: widget.tipEnabled,
                onChanged: widget.onTipChanged,
                expanded: _showTipDetail,
                onExpand: () =>
                    setState(() => _showTipDetail = !_showTipDetail),
                expandedContent: _TipDetail(tip: widget.tip),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntelRow extends StatelessWidget {
  const _IntelRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.expanded,
    required this.onExpand,
    required this.expandedContent,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool expanded;
  final VoidCallback onExpand;
  final Widget expandedContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.labelL
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTypography.labelS
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 18, color: AppColors.textTertiary),
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.emerald,
                activeTrackColor: AppColors.emeraldSurface,
                inactiveThumbColor: AppColors.textTertiary,
                inactiveTrackColor: AppColors.glassLight,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: expandedContent,
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

class _PredictionDetail extends StatelessWidget {
  const _PredictionDetail({required this.prediction});
  final MonthlyPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final color =
        prediction.isOnTrack ? AppColors.emerald : AppColors.negative;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border:
            Border.all(color: color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gasto estimado',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary)),
              Text('\$${prediction.predictedExpenses.toStringAsFixed(0)}',
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.negative)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ahorro estimado',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary)),
              Text(
                prediction.predictedSavings >= 0
                    ? '+\$${prediction.predictedSavings.toStringAsFixed(0)}'
                    : '-\$${prediction.predictedSavings.abs().toStringAsFixed(0)}',
                style: AppTypography.labelL.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            prediction.isOnTrack
                ? 'Vas bien este mes. Sigue así.'
                : 'Tus gastos superarán tus ingresos si continúas así.',
            style: AppTypography.labelS.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TipDetail extends StatelessWidget {
  const _TipDetail({required this.tip});
  final FinancialTip tip;

  @override
  Widget build(BuildContext context) {
    final color = tip.category.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border:
            Border.all(color: color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tip.category.icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(tip.category.label,
                  style: AppTypography.labelS.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(tip.title,
              style: AppTypography.labelL.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(tip.content,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style:
              AppTypography.headingS.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _ProfileSubBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
