import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';

class PersonalDataPage extends ConsumerStatefulWidget {
  const PersonalDataPage({super.key});

  @override
  ConsumerState<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends ConsumerState<PersonalDataPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  bool _editing = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();

  static const _sectionCount = 3;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _populateControllers(ref.read(userProfileProvider));
    });
  }

  void _populateControllers(UserProfile p) {
    _nameController.text = p.name;
    _emailController.text = p.email;
    _phoneController.text = p.phone;
    _birthdateController.text = p.birthdate;
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final source = await _showSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // Copy to app documents so the path survives gallery clean-ups
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/profile_photo.jpg');
    await File(picked.path).copy(dest.path);

    await ref.read(userProfileProvider.notifier).update(photoPath: dest.path);
    if (mounted) setState(() {});
  }

  Future<ImageSource?> _showSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SourceSheet(),
    );
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime? initial;
    try {
      final parts = _birthdateController.text.split('/');
      if (parts.length == 3) {
        initial = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('es'),
    );
    if (picked == null) return;
    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    _birthdateController.text = '$day/$month/${picked.year}';
  }

  Future<void> _toggleEdit() async {
    if (_editing) {
      await ref.read(userProfileProvider.notifier).update(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        birthdate: _birthdateController.text.trim(),
      );
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Re-populate controllers if the provider finishes loading after this page opens.
    ref.listen<UserProfile>(userProfileProvider, (_, profile) {
      if (!_editing) _populateControllers(profile);
    });

    return Scaffold(
      backgroundColor: c.background,
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
                                  : c.glass,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.pillRadius),
                              border: Border.all(
                                color: _editing
                                    ? AppColors.emeraldGlow
                                    : c.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              _editing ? 'Guardar' : 'Editar',
                              style: AppTypography.labelM.copyWith(
                                color: _editing
                                    ? AppColors.emerald
                                    : c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: AppSpacing.xxl),

                      // Avatar
                      _reveal(1, Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            children: [
                              _ProfileAvatar(
                                profile: ref.watch(userProfileProvider),
                                size: 80,
                                radius: 24,
                              ),
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
                                      color: c.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            keyboardType: TextInputType.none,
                            onTap: _pickDate,
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
    this.onTap,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.editing, required this.fields});
  final bool editing;
  final List<_FieldData> fields;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: editing
              ? AppColors.emeraldGlow.withValues(alpha: 0.45)
              : c.glassBorder,
          width: editing ? 1.0 : 0.5,
        ),
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
                    color: c.glassBorder),
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: editing ? AppColors.emeraldSurface : c.glass,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon,
                size: 16,
                color: editing ? AppColors.emerald : c.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTypography.labelS.copyWith(
                      color: c.textTertiary),
                ),
                const SizedBox(height: 4),
                editing
                    ? TextField(
                        controller: data.controller,
                        keyboardType: data.keyboardType,
                        readOnly: data.onTap != null,
                        onTap: data.onTap,
                        style: AppTypography.bodyM
                            .copyWith(color: c.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        data.controller.text,
                        style: AppTypography.bodyM
                            .copyWith(color: c.textPrimary),
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
    final c = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: c.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingS.copyWith(
                color: c.textPrimary),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ProfileSubBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
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

// ── Reusable profile avatar (photo or gradient+initial) ───────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    this.size = 40,
    this.radius = 12,
  });

  final UserProfile profile;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = profile.photoPath;
    final file = path != null ? File(path) : null;
    final hasPhoto = file != null && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasPhoto
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.petroleum, AppColors.emeraldDim],
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.initial,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.4,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Source sheet (modal) ──────────────────────────────────────────────────────

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Foto de perfil',
              style: AppTypography.headingS.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xl),
          _SourceOption(
            icon: Icons.photo_library_outlined,
            label: 'Elegir de la galería',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceOption(
            icon: Icons.camera_alt_outlined,
            label: 'Tomar una foto',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

// ── Source picker option row ──────────────────────────────────────────────────

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: AppColors.emerald),
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(label,
                style: AppTypography.labelL
                    .copyWith(color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}

