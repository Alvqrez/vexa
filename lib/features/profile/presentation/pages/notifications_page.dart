import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/data/local_prefs_service.dart';

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

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final transactions = await LocalPrefsService.getBool('notif_transactions', defaultValue: true);
    final budgetAlerts = await LocalPrefsService.getBool('notif_budget_alerts', defaultValue: true);
    final weeklySummary = await LocalPrefsService.getBool('notif_weekly_summary', defaultValue: true);
    final marketing = await LocalPrefsService.getBool('notif_marketing', defaultValue: false);
    final security = await LocalPrefsService.getBool('notif_security', defaultValue: true);
    final prediction = await LocalPrefsService.getBool('notif_prediction', defaultValue: true);
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _budgetAlerts = budgetAlerts;
      _weeklySummary = weeklySummary;
      _marketing = marketing;
      _security = security;
      _prediction = prediction;
    });
  }

  Future<void> _save(String key, bool value) async {
    await LocalPrefsService.setBool(key, value);
    if (key == 'notif_prediction') {
      ref.read(notifPrefsProvider.notifier).reload();
    }
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
                            predictionEnabled: _prediction,
                            onPredictionChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _prediction = v);
                              _save('notif_prediction', v);
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
                                  _save('notif_transactions', v);
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
                                  _save('notif_budget_alerts', v);
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
                                  _save('notif_weekly_summary', v);
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
                                  _save('notif_security', v);
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
                                  _save('notif_marketing', v);
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
    required this.predictionEnabled,
    required this.onPredictionChanged,
  });

  final MonthlyPrediction prediction;
  final bool predictionEnabled;
  final ValueChanged<bool> onPredictionChanged;

  @override
  State<_IntelligenceSection> createState() => _IntelligenceSectionState();
}

class _IntelligenceSectionState extends State<_IntelligenceSection> {
  bool _showPredDetail = false;

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

class _PredictionDetail extends ConsumerWidget {
  const _PredictionDetail({required this.prediction});
  final MonthlyPrediction prediction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
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
              Text('$currency${prediction.predictedExpenses.toStringAsFixed(0)}',
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.negative)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(prediction.predictedIncome > 0 ? 'Neto estimado' : 'Gasto diario',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary)),
              Text(
                prediction.predictedIncome > 0
                    ? (prediction.predictedSavings >= 0
                        ? '+$currency${prediction.predictedSavings.toStringAsFixed(0)}'
                        : '-$currency${prediction.predictedSavings.abs().toStringAsFixed(0)}')
                    : '$currency${prediction.dailyAvgExpense.toStringAsFixed(0)}/día',
                style: AppTypography.labelL.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            prediction.predictedIncome > 0
                ? (prediction.isOnTrack
                    ? 'Vas bien este mes. Sigue así.'
                    : 'Tus gastos superarán tus ingresos si continúas así.')
                : 'Sin ingresos registrados aún este mes.',
            style: AppTypography.labelS.copyWith(color: color),
          ),
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
