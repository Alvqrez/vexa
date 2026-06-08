import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/report_export_provider.dart';

class ExportReportsSheet extends ConsumerWidget {
  const ExportReportsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportar reportes',
                style: AppTypography.headingM.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ExportButton(
                title: 'Todas las transacciones',
                subtitle: 'Exportar historial completo en CSV',
                icon: Icons.receipt_long_rounded,
                onTap: () {
                  _exportReport(
                    context,
                    ref,
                    'todas_transacciones',
                    () => ref.read(reportExporterProvider).generateCSV(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ExportButton(
                title: 'Resumen mensual',
                subtitle: 'Ingresos, gastos y neto por mes',
                icon: Icons.calendar_month_rounded,
                onTap: () {
                  _exportReport(
                    context,
                    ref,
                    'resumen_mensual',
                    () =>
                        ref.read(reportExporterProvider).generateMonthlySummaryCSV(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ExportButton(
                title: 'Análisis por categoría',
                subtitle: 'Gastos agrupados por categoría',
                icon: Icons.pie_chart_rounded,
                onTap: () {
                  _exportReport(
                    context,
                    ref,
                    'analisis_categorias',
                    () => ref.read(reportExporterProvider).generateCategoryReportCSV(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cerrar',
                    style: AppTypography.labelM.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportReport(
    BuildContext context,
    WidgetRef ref,
    String filename,
    String Function() csvGenerator,
  ) {
    try {
      final csv = csvGenerator();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFilename = '${filename}_$timestamp.csv';

      // Copiar al clipboard y mostrar notificación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte generado: $finalFilename'),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () {
              // En una app real, usarías share o escribirías a archivo
              // Por ahora mostramos el contenido en un diálogo
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Contenido del reporte'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar reporte: $e'),
          backgroundColor: AppColors.negative,
        ),
      );
    }
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: c.glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.petroleum.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.petroleum,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelM.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelS.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: c.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
