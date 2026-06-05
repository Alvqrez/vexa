import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/services/local_auth_service.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  bool _pinEnabled = false;
  bool _passwordEnabled = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _load();
  }

  Future<void> _load() async {
    final pin = await LocalAuthService.isPinEnabled();
    final pass = await LocalAuthService.isPasswordEnabled();
    final bio = await LocalAuthService.isBiometricEnabled();
    setState(() {
      _pinEnabled = pin;
      _passwordEnabled = pass;
      _biometricEnabled = bio;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, int total, Widget child) {
    final start = (i / total * 0.5).clamp(0.0, 1.0);
    final end = (start + 0.6).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.gentle)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _stagger,
                curve: Interval(start, end, curve: AppCurves.spring))),
        child: child,
      ),
    );
  }

  bool get _anyActive => _pinEnabled || _passwordEnabled || _biometricEnabled;

  // ── PIN ──────────────────────────────────────────────────────────────────────

  Future<void> _onPinToggle(bool value) async {
    if (value) {
      final ok = await _showPinSetup();
      if (ok == true) setState(() => _pinEnabled = true);
    } else {
      final ok = await _confirmDisable('PIN');
      if (ok == true) {
        await LocalAuthService.disablePin();
        setState(() => _pinEnabled = false);
      }
    }
  }

  Future<bool?> _showPinSetup() => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _PinSetupSheet(),
      );

  // ── Password ─────────────────────────────────────────────────────────────────

  Future<void> _onPasswordToggle(bool value) async {
    if (value) {
      final ok = await _showPasswordSetup();
      if (ok == true) setState(() => _passwordEnabled = true);
    } else {
      final ok = await _confirmDisable('contraseña');
      if (ok == true) {
        await LocalAuthService.disablePassword();
        setState(() => _passwordEnabled = false);
      }
    }
  }

  Future<bool?> _showPasswordSetup() => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _PasswordSetupSheet(),
      );

  // ── Change ────────────────────────────────────────────────────────────────────

  Future<void> _changePin() async {
    if (!_pinEnabled) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PinSetupSheet(isChange: true),
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordEnabled) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PasswordSetupSheet(isChange: true),
    );
  }

  // ── Biometric ─────────────────────────────────────────────────────────────────

  Future<void> _onBiometricToggle(bool value) async {
    HapticFeedback.selectionClick();
    await LocalAuthService.setBiometric(value);
    setState(() => _biometricEnabled = value);
  }

  // ── Confirm disable ───────────────────────────────────────────────────────────

  Future<bool?> _confirmDisable(String what) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
          title: Text('Desactivar $what',
              style: AppTypography.headingS
                  .copyWith(color: AppColors.textPrimary)),
          content: Text(
              '¿Seguro que quieres desactivar el $what? La app quedará sin protección.',
              style: AppTypography.bodyM
                  .copyWith(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Desactivar',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.negative)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                      _reveal(0, 4, const _SubPageHeader(title: 'Seguridad')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Status banner
                      _reveal(
                        1,
                        4,
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: _anyActive
                                ? AppColors.emeraldSurface
                                : AppColors.negativeSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: _anyActive
                                  ? AppColors.emeraldGlow
                                  : AppColors.negative.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _anyActive
                                    ? Icons.shield_outlined
                                    : Icons.shield_outlined,
                                color: _anyActive
                                    ? AppColors.emerald
                                    : AppColors.negative,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _anyActive
                                          ? 'Cuenta protegida'
                                          : 'Sin protección',
                                      style: AppTypography.labelL.copyWith(
                                        color: _anyActive
                                            ? AppColors.emerald
                                            : AppColors.negative,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _anyActive
                                          ? 'Al menos una medida de seguridad activa.'
                                          : 'Activa PIN o contraseña para proteger tu app.',
                                      style: AppTypography.labelS.copyWith(
                                        color: _anyActive
                                            ? AppColors.emerald
                                                .withValues(alpha: 0.7)
                                            : AppColors.negative
                                                .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Options card
                      _reveal(
                        2,
                        4,
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              _SecurityToggle(
                                icon: Icons.fingerprint_rounded,
                                color: AppColors.petroleum,
                                title: 'Autenticación biométrica',
                                subtitle: 'Usa huella o Face ID al entrar.',
                                value: _biometricEnabled,
                                onChanged: _onBiometricToggle,
                              ),
                              _divider(),
                              _SecurityToggle(
                                icon: Icons.pin_outlined,
                                color: AppColors.catTransport,
                                title: 'PIN de acceso',
                                subtitle: _pinEnabled
                                    ? 'Activo — se solicita al abrir la app.'
                                    : 'Desactivado.',
                                value: _pinEnabled,
                                onChanged: _onPinToggle,
                              ),
                              if (_pinEnabled) ...[
                                _divider(),
                                _SecurityAction(
                                  icon: Icons.edit_rounded,
                                  color: AppColors.catTransport,
                                  title: 'Cambiar PIN',
                                  subtitle: 'Actualiza tu código de acceso.',
                                  onTap: _changePin,
                                ),
                              ],
                              _divider(),
                              _SecurityToggle(
                                icon: Icons.lock_outline_rounded,
                                color: AppColors.warning,
                                title: 'Contraseña',
                                subtitle: _passwordEnabled
                                    ? 'Activa — se solicita al abrir la app.'
                                    : 'Desactivada.',
                                value: _passwordEnabled,
                                onChanged: _onPasswordToggle,
                              ),
                              if (_passwordEnabled) ...[
                                _divider(),
                                _SecurityAction(
                                  icon: Icons.edit_rounded,
                                  color: AppColors.warning,
                                  title: 'Cambiar contraseña',
                                  subtitle: 'Actualiza tu contraseña.',
                                  onTap: _changePassword,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Widget _divider() => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Divider(
            height: 1, thickness: 0.5, color: AppColors.glassBorder),
      );
}

// ── PIN Setup Sheet ───────────────────────────────────────────────────────────

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet({this.isChange = false});
  final bool isChange;

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  final List<String> _digits = [];
  List<String>? _firstPin;
  String _step = 'enter'; // 'enter' | 'confirm'
  bool _error = false;

  void _addDigit(String d) {
    if (_digits.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _digits.add(d);
      _error = false;
    });
    if (_digits.length == 4) _next();
  }

  void _removeDigit() {
    if (_digits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _digits.removeLast());
  }

  Future<void> _next() async {
    if (_step == 'enter') {
      setState(() {
        _firstPin = List.from(_digits);
        _digits.clear();
        _step = 'confirm';
      });
    } else {
      if (_digits.join() == _firstPin!.join()) {
        await LocalAuthService.setPin(_digits.join());
        HapticFeedback.mediumImpact();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = true;
          _digits.clear();
          _firstPin = null;
          _step = 'enter';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            _step == 'enter'
                ? (widget.isChange ? 'Nuevo PIN' : 'Elige un PIN')
                : 'Confirma el PIN',
            style: AppTypography.headingS
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error ? 'Los PINs no coinciden. Inténtalo de nuevo.' : 'Introduce 4 dígitos',
            style: AppTypography.labelM.copyWith(
              color: _error ? AppColors.negative : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _digits.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.emerald : AppColors.glassLight,
                    border: Border.all(
                      color: filled
                          ? Colors.transparent
                          : AppColors.glassBorderStrong,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _Keypad(onDigit: _addDigit, onDelete: _removeDigit),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Password Setup Sheet ──────────────────────────────────────────────────────

class _PasswordSetupSheet extends StatefulWidget {
  const _PasswordSetupSheet({this.isChange = false});
  final bool isChange;

  @override
  State<_PasswordSetupSheet> createState() => _PasswordSetupSheetState();
}

class _PasswordSetupSheetState extends State<_PasswordSetupSheet> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMsg;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pass.length < 4) {
      setState(() => _errorMsg = 'Mínimo 4 caracteres');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMsg = 'Las contraseñas no coinciden');
      return;
    }
    await LocalAuthService.setPassword(pass);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.isChange ? 'Nueva contraseña' : 'Elige una contraseña',
              style:
                  AppTypography.headingS.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PassField(
              controller: _passCtrl,
              hint: 'Contraseña (mínimo 4 caracteres)',
              obscure: _obscure1,
              onToggle: () => setState(() => _obscure1 = !_obscure1),
            ),
            const SizedBox(height: AppSpacing.md),
            _PassField(
              controller: _confirmCtrl,
              hint: 'Confirmar contraseña',
              obscure: _obscure2,
              onToggle: () => setState(() => _obscure2 = !_obscure2),
              onSubmitted: (_) => _submit(),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_errorMsg!,
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.negative)),
            ],
            const SizedBox(height: AppSpacing.xxl),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim]),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text('Guardar contraseña',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  const _PassField({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.textTertiary),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppColors.textTertiary,
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SecurityToggle extends StatelessWidget {
  const _SecurityToggle({
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
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
    );
  }
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
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
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onDelete});
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _KeyRow(keys: const ['1', '2', '3'], onDigit: onDigit),
        const SizedBox(height: AppSpacing.md),
        _KeyRow(keys: const ['4', '5', '6'], onDigit: onDigit),
        const SizedBox(height: AppSpacing.md),
        _KeyRow(keys: const ['7', '8', '9'], onDigit: onDigit),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            const SizedBox(width: AppSpacing.md),
            _KeyButton(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Center(
                  child: Icon(Icons.backspace_outlined,
                      size: 22, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys, required this.onDigit});
  final List<String> keys;
  final ValueChanged<String> onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys
          .expand((k) => [
                _KeyButton(label: k, onTap: () => onDigit(k)),
                if (k != keys.last) const SizedBox(width: AppSpacing.md),
              ])
          .toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Center(
          child: Text(label,
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22,
              )),
        ),
      ),
    );
  }
}

// ── Background / header (reused from other profile pages) ────────────────────

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
            width: 40, height: 40,
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
        Text(title,
            style: AppTypography.headingS
                .copyWith(color: AppColors.textPrimary)),
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
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
