import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/local_auth_service.dart';
import '../../../shell/presentation/pages/main_shell.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage>
    with SingleTickerProviderStateMixin {
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  final List<String> _digits = [];
  bool _usePassword = false;
  bool _hasPinEnabled = false;
  bool _hasPasswordEnabled = false;
  bool _error = false;
  bool _loading = true;
  int _failedAttempts = 0;
  DateTime? _lockUntil;
  Timer? _lockTimer;
  int _lockSecondsLeft = 0;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  bool get _isLockedOut =>
      _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _init();
  }

  Future<void> _init() async {
    _hasPinEnabled = await LocalAuthService.isPinEnabled();
    _hasPasswordEnabled = await LocalAuthService.isPasswordEnabled();
    setState(() {
      _usePassword = !_hasPinEnabled && _hasPasswordEnabled;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _shakeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _lockUntil!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _lockTimer?.cancel();
        setState(() {
          _lockUntil = null;
          _lockSecondsLeft = 0;
          _error = false;
        });
      } else {
        setState(() => _lockSecondsLeft = left);
      }
    });
  }

  void _registerFailure() {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      _lockUntil = DateTime.now().add(_lockDuration);
      _lockSecondsLeft = _lockDuration.inSeconds;
      _failedAttempts = 0;
      _startLockTimer();
    }
  }

  void _addDigit(String d) {
    if (_digits.length >= 4 || _isLockedOut) return;
    Haptics.selectionClick();
    setState(() {
      _digits.add(d);
      _error = false;
    });
    if (_digits.length == 4) _verifyPin();
  }

  void _removeDigit() {
    if (_digits.isEmpty || _isLockedOut) return;
    Haptics.lightImpact();
    setState(() => _digits.removeLast());
  }

  Future<void> _verifyPin() async {
    final pin = _digits.join();
    final ok = await LocalAuthService.verifyPin(pin);
    if (ok) {
      _unlock();
    } else {
      Haptics.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error = true;
        _digits.clear();
      });
      _registerFailure();
    }
  }

  Future<void> _verifyPassword() async {
    if (_isLockedOut) return;
    final ok = await LocalAuthService.verifyPassword(_passCtrl.text);
    if (ok) {
      _unlock();
    } else {
      Haptics.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() => _error = true);
      _passCtrl.clear();
      _registerFailure();
    }
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const MainShell(),
        transitionsBuilder: (_, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emeraldSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.emeraldGlow, width: 0.5),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.emerald, size: 28),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _usePassword ? 'Introduce tu contraseña' : 'Introduce tu PIN',
                style: AppTypography.headingS.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isLockedOut
                    ? 'Demasiados intentos. Espera $_lockSecondsLeft s'
                    : _error
                        ? (_usePassword
                            ? 'Contraseña incorrecta'
                            : 'PIN incorrecto. ${_maxAttempts - _failedAttempts} intento${(_maxAttempts - _failedAttempts) == 1 ? '' : 's'} restante${(_maxAttempts - _failedAttempts) == 1 ? '' : 's'}')
                        : 'Vexa está protegida',
                style: AppTypography.labelM.copyWith(
                  color: _isLockedOut || _error
                      ? AppColors.negative
                      : c.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (_usePassword) ...[
                // Password field
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                        8 * (_shakeAnim.value < 0.5
                            ? _shakeAnim.value
                            : 1 - _shakeAnim.value) *
                            (_error ? -1 : 1),
                        0),
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                        color: _error
                            ? AppColors.negative.withValues(alpha: 0.4)
                            : c.glassBorder,
                        width: _error ? 1.5 : 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      autofocus: true,
                      style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                      onSubmitted: (_) => _verifyPassword(),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: AppTypography.bodyM
                            .copyWith(color: c.textTertiary),
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            size: 18, color: c.textTertiary),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: c.textTertiary,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: _isLockedOut ? null : _verifyPassword,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: _isLockedOut
                              ? [c.glass, c.glass]
                              : [AppColors.emerald, AppColors.emeraldDim]),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: Text('Entrar',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelL.copyWith(
                          color: _isLockedOut
                              ? c.textTertiary
                              : AppColors.textInverse,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ] else ...[
                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                        12 *
                            (_shakeAnim.value < 0.5
                                ? _shakeAnim.value * 2
                                : (1 - _shakeAnim.value) * 2) *
                            (_error ? -1 : 1),
                        0),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _digits.length;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? (_error
                                    ? AppColors.negative
                                    : AppColors.emerald)
                                : c.glass,
                            border: Border.all(
                              color: filled
                                  ? Colors.transparent
                                  : c.glassBorderStrong,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Numeric keypad
                _Keypad(
                  onDigit: _addDigit,
                  onDelete: _removeDigit,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Switch mode
              if (_hasPinEnabled && _hasPasswordEnabled)
                GestureDetector(
                  onTap: () => setState(() {
                    _usePassword = !_usePassword;
                    _digits.clear();
                    _error = false;
                    _passCtrl.clear();
                  }),
                  child: Text(
                    _usePassword ? 'Usar PIN' : 'Usar contraseña',
                    style: AppTypography.labelM
                        .copyWith(color: AppColors.petroleum),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────

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
            _DeleteButton(onDelete: onDelete),
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
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: c.card,
          shape: BoxShape.circle,
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.headingS.copyWith(
              color: c.textPrimary,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(Icons.backspace_outlined,
              size: 22, color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
