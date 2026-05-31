import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  bool _editing = false;

  final _nameController =
      TextEditingController(text: 'Leonardo Alvarez');
  final _emailController =
      TextEditingController(text: 'leoo.azdz@gmail.com');
  final _phoneController =
      TextEditingController(text: '+52 55 1234 5678');
  final _birthdateController =
      TextEditingController(text: '15 / 03 / 1998');

  static const _sectionCount = 3;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final start = i / _sectionCount * 0.5;
    final end = (start + 0.6).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.gentle)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _stagger,
            curve: Interval(start, end, curve: AppCurves.spring))),
        child: child,
      ),
    );
  }

  void _toggleEdit() {
    setState(() => _editing = !_editing);
    if (!_editing) HapticFeedback.lightImpact();
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
                      _reveal(0, _SubPageHeader(
                        title: 'Datos personales',
                        trailing: GestureDetector(
                          onTap: _toggleEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _editing
                                  ? AppColors.emeraldSurface
                                  : AppColors.glassLight,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.pillRadius),
                              border: Border.all(
                                color: _editing
                                    ? AppColors.emeraldGlow
                                    : AppColors.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _editing ? 'Guardar' : 'Editar',
                              style: AppTypography.labelM.copyWith(
                                color: _editing
                                    ? AppColors.emerald
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: AppSpacing.xxl),

                      // Avatar
                      _reveal(1, Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.petroleum,
                                    AppColors.emeraldDim
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'L',
                                  style: AppTypography.headingM.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ),
                            if (_editing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.petroleum,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),
                      const SizedBox(height: AppSpacing.xxl),

                      // Fields
                      _reveal(2, _FieldsCard(
                        editing: _editing,
                        fields: [
                          _FieldData(
                            label: 'Nombre completo',
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                          ),
                          _FieldData(
                            label: 'Correo electrónico',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _FieldData(
                            label: 'Teléfono',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          _FieldData(
                            label: 'Fecha de nacimiento',
                            controller: _birthdateController,
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.datetime,
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

// ── Fields card ───────────────────────────────────────────────────────────────

class _FieldData {
  const _FieldData({
    required this.label,
    required this.controller,
    required this.icon,
    required this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.editing, required this.fields});
  final bool editing;
  final List<_FieldData> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            _FormField(data: fields[i], editing: editing),
            if (i < fields.length - 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.glassBorder),
              ),
          ],
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.data, required this.editing});
  final _FieldData data;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon,
                size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTypography.labelS.copyWith(
                      color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                editing
                    ? TextField(
                        controller: data.controller,
                        keyboardType: data.keyboardType,
                        style: AppTypography.bodyM
                            .copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        data.controller.text,
                        style: AppTypography.bodyM
                            .copyWith(color: AppColors.textPrimary),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-page components ────────────────────────────────────────────────

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

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
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary),
          ),
        ),
        ?trailing,
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
