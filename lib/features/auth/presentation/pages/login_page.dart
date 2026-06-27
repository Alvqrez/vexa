import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/local_auth_service.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isRegistration = false;
  bool _loading = true;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final setup = await LocalAuthService.isAccountSetup();
    final email = await LocalAuthService.getAccountEmail();
    if (mounted) {
      setState(() {
        _isRegistration = !setup;
        _loading = false;
        if (email != null) _emailCtrl.text = email;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Introduce un email válido');
      return;
    }
    if (pass.length < 4) {
      setState(() => _errorMsg = 'La contraseña debe tener al menos 4 caracteres');
      return;
    }

    if (_isRegistration) {
      final confirm = _confirmCtrl.text;
      if (pass != confirm) {
        setState(() => _errorMsg = 'Las contraseñas no coinciden');
        return;
      }
      await LocalAuthService.setupAccount(email, pass);
      Haptics.mediumImpact();
      _goToApp();
    } else {
      final ok = await LocalAuthService.verifyAccount(email, pass);
      if (ok) {
        Haptics.mediumImpact();
        _goToApp();
      } else {
        Haptics.heavyImpact();
        setState(() => _errorMsg = 'Email o contraseña incorrectos');
        _passCtrl.clear();
      }
    }
  }

  void _goToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const MainShell(),
        transitionsBuilder: (_, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (route) => false,
    );
  }

  Future<void> _showForgotPassword() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        ),
        title: Text('¿Olvidaste tu contraseña?',
            style: AppTypography.headingS.copyWith(color: c.textPrimary)),
        content: Text(
          'Esta app guarda tus datos solo en tu dispositivo. '
          'No hay forma de recuperar tu contraseña sin borrar los datos.\n\n'
          '⚠️ Si continúas, se eliminarán todas tus cuentas, transacciones y configuración.',
          style: AppTypography.bodyM.copyWith(color: c.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: AppTypography.labelM.copyWith(color: c.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Borrar todo y empezar',
                style: AppTypography.labelM.copyWith(
                    color: AppColors.negative, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await LocalAuthService.wipeAll();
      await LocalPrefsService.clear();
      if (mounted) {
        setState(() {
          _isRegistration = true;
          _emailCtrl.clear();
          _passCtrl.clear();
          _confirmCtrl.clear();
          _errorMsg = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.emeraldSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.emeraldGlow, width: 0.5),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.emerald, size: 26),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                _isRegistration ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                style: AppTypography.headingL.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isRegistration
                    ? 'Configura tu acceso a Vexa.'
                    : 'Inicia sesión para continuar.',
                style: AppTypography.bodyM.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Email
              _Label('Correo electrónico'),
              const SizedBox(height: AppSpacing.sm),
              _Field(
                controller: _emailCtrl,
                hint: 'tu@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: !_isRegistration,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Password
              _Label('Contraseña'),
              const SizedBox(height: AppSpacing.sm),
              _PasswordField(
                controller: _passCtrl,
                hint: 'Mínimo 4 caracteres',
                obscure: _obscurePass,
                onToggle: () =>
                    setState(() => _obscurePass = !_obscurePass),
                onSubmitted: _isRegistration ? null : (_) => _submit(),
              ),

              if (_isRegistration) ...[
                const SizedBox(height: AppSpacing.lg),
                _Label('Confirmar contraseña'),
                const SizedBox(height: AppSpacing.sm),
                _PasswordField(
                  controller: _confirmCtrl,
                  hint: 'Repite tu contraseña',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmitted: (_) => _submit(),
                ),
              ],

              if (_errorMsg != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: AppColors.negative),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: AppTypography.labelM
                              .copyWith(color: AppColors.negative)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Submit button
              GestureDetector(
                onTap: () {
                  setState(() => _errorMsg = null);
                  _submit();
                },
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
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _isRegistration ? 'Crear cuenta' : 'Entrar',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!_isRegistration) ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: GestureDetector(
                    onTap: _showForgotPassword,
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: AppTypography.labelM.copyWith(
                        color: context.colors.textTertiary,
                        decoration: TextDecoration.underline,
                        decorationColor: context.colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.labelM.copyWith(
          color: context.colors.textSecondary, fontWeight: FontWeight.w600));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? c.glass.withValues(alpha: 0.5) : c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: AppTypography.bodyM.copyWith(
          color: readOnly ? c.textTertiary : c.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(color: c.textTertiary),
          prefixIcon: Icon(icon, size: 18, color: c.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onSubmitted;

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
        obscureText: obscure,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyM.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(color: c.textTertiary),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              size: 18, color: c.textTertiary),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: c.textTertiary,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
