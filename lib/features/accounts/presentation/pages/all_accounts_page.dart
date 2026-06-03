import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/domain/models/account.dart';
import 'account_detail_page.dart';

class AllAccountsPage extends ConsumerWidget {
  const AllAccountsPage({super.key});

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAccountSheet(
        onSave: (account) =>
            ref.read(accountsProvider.notifier).addAccount(account),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Mis cuentas',
                            style: AppTypography.headingM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          // Add account button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showAddAccount(context, ref);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: AppColors.emerald.withValues(alpha: 0.25),
                                    width: 0.5),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 18, color: AppColors.emerald),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Drag-to-reorder hint
                          Tooltip(
                            message: 'Arrastra para ordenar',
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.glassLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.glassBorder, width: 0.5),
                              ),
                              child: const Icon(Icons.swap_vert_rounded,
                                  size: 16, color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Total balance
                      Text(
                        'PATRIMONIO TOTAL',
                        style: AppTypography.eyebrow
                            .copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 8),
                      AnimatedNumber(
                        value: totalBalance,
                        style: AppTypography.displayM.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Text(
                        '${accounts.length} cuentas',
                        style: AppTypography.headingS
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // ── Reorderable list ─────────────────────────────────────
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      120,
                    ),
                    onReorderItem: (oldIndex, newIndex) {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(accountsProvider.notifier)
                          .reorder(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double elevation =
                              Tween<double>(begin: 0, end: 8)
                                  .evaluate(
                                      CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOut))
                                  .toDouble();
                          return Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Padding(
                        key: ValueKey(account.id),
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _AccountRow(account: account),
                      );
                    },
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

// ── Account row ───────────────────────────────────────────────────────────────

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final color = account.color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountDetailPage(accountId: account.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Account icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(account.icon.iconData, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: color.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedNumber(
                  value: account.balance,
                  style: AppTypography.headingS.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ver detalle',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.petroleum),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textTertiary),

            // Drag handle
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.drag_handle_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Add Account sheet ─────────────────────────────────────────────────────────

const _accountColors = [
  Color(0xFF1565C0),
  Color(0xFF820AD1),
  Color(0xFF00D68F),
  Color(0xFFFF6B35),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
];

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet({required this.onSave});
  final ValueChanged<Account> onSave;

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  AccountIcon _icon = AccountIcon.bank;
  int _colorIndex = 0;

  static const _icons = AccountIcon.values;
  static const _iconLabels = [
    'Banco', 'Tarjeta', 'Cartera', 'Ahorros', 'Inversión', 'Efectivo'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final balance = double.tryParse(
            _balanceCtrl.text.replaceAll(',', '.')) ??
        0.0;
    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(9999).toString(),
      name: name,
      balance: balance,
      color: _accountColors[_colorIndex],
      icon: _icon,
    );
    widget.onSave(account);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 24 + bottom),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: AppColors.glassBorderStrong, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + title
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
            child: Text('Nueva cuenta',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                _Label('Nombre'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ej. BBVA, Efectivo…',
                    hintStyle: AppTypography.labelL
                        .copyWith(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.glassLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.emerald, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Balance field
                _Label('Saldo inicial'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: AppTypography.labelL
                        .copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.glassLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(
                          color: AppColors.emerald, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Icon selector
                _Label('Tipo'),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _icons.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final selected = _icon == _icons[i];
                      final color = _accountColors[_colorIndex];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _icon = _icons[i]);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.15)
                                : AppColors.glassLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: selected
                                  ? color.withValues(alpha: 0.40)
                                  : AppColors.glassBorder,
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _icons[i].iconData,
                                size: 20,
                                color: selected
                                    ? color
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _iconLabels[i],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: selected
                                      ? color
                                      : AppColors.textTertiary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Color selector
                _Label('Color'),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _accountColors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final selected = i == _colorIndex;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _colorIndex = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accountColors[i],
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: AppColors.textPrimary, width: 2.5)
                                : null,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _accountColors[i]
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save button
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.30),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Crear cuenta',
                        style: AppTypography.labelL.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelS.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
