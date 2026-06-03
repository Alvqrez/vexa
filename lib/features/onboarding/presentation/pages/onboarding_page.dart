import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../shell/presentation/pages/main_shell.dart';

// Provider to track if onboarding was shown this session
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  int _selectedCurrencyIndex = 0;
  final _nameCtrl = TextEditingController();

  late AnimationController _bgCtrl;
  late AnimationController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    // _slides.length = name slide, _slides.length + 1 = currency (last)
    if (_page < _slides.length + 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
    } else {
      _complete();
    }
  }

  void _skipToCurrency() {
    HapticFeedback.selectionClick();
    _pageCtrl.animateToPage(
      _slides.length + 1,
      duration: const Duration(milliseconds: 380),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  Future<void> _complete() async {
    HapticFeedback.mediumImpact();
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await ref.read(userProfileProvider.notifier).update(name: name);
    }
    final currency = _currencies[_selectedCurrencyIndex];
    await LocalPrefsService.setString('currency_symbol', currency.symbol);
    await LocalPrefsService.setString('currency_code', currency.code);
    ref.read(currencySymbolProvider.notifier).state = currency.symbol;
    ref.read(onboardingDoneProvider.notifier).state = true;
    await LocalPrefsService.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secondary) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (ctx, animation, secondary, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  static const _slides = [
    _Slide(
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppColors.emerald,
      title: 'Controla\ntus gastos',
      body:
          'Registra ingresos y gastos en segundos. Categoriza automáticamente y entiende a dónde va tu dinero.',
    ),
    _Slide(
      icon: Icons.trending_up_rounded,
      accentColor: AppColors.petroleum,
      title: 'Construye\nhábitos financieros',
      body:
          'Establece presupuestos, rastrea tu progreso y recibe insights inteligentes sobre tus patrones de gasto.',
    ),
    _Slide(
      icon: Icons.flag_rounded,
      accentColor: AppColors.catFood,
      title: 'Alcanza\ntus metas',
      body:
          'Define objetivos de ahorro y visualiza tu avance. Vexa te ayuda a llegar ahí más rápido.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Animated background blob
            _OnboardingBg(page: _page, slides: _slides),

            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding, AppSpacing.lg,
                        AppSpacing.screenPadding, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_page < _slides.length)
                          GestureDetector(
                            onTap: _skipToCurrency,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.glassLight,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.pillRadius),
                                border: Border.all(
                                    color: AppColors.glassBorder, width: 0.5),
                              ),
                              child: Text('Omitir',
                                  style: AppTypography.labelM.copyWith(
                                      color: AppColors.textTertiary)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Pages
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _slides.length + 2,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        if (i < _slides.length) {
                          return _SlidePage(slide: _slides[i], index: i);
                        }
                        if (i == _slides.length) {
                          return _NameInputSlide(controller: _nameCtrl);
                        }
                        return _CurrencySlide(
                          selectedIndex: _selectedCurrencyIndex,
                          onSelect: (idx) =>
                              setState(() => _selectedCurrencyIndex = idx),
                        );
                      },
                    ),
                  ),

                  // Bottom area: dots + button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding, 0,
                        AppSpacing.screenPadding, AppSpacing.huge),
                    child: Column(
                      children: [
                        _PageIndicator(
                            current: _page, count: _slides.length + 2),
                        const SizedBox(height: AppSpacing.xxl),
                        _NextButton(
                          isLast: _page == _slides.length + 1,
                          accent: _page < _slides.length
                              ? _slides[_page].accentColor
                              : AppColors.emerald,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
}

// ── Animated background ───────────────────────────────────────────────────────

class _OnboardingBg extends StatelessWidget {
  const _OnboardingBg({required this.page, required this.slides});
  final int page;
  final List<_Slide> slides;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: const Cubic(0.22, 1.0, 0.36, 1.0),
            top: page == 0 ? -80 : page == 1 ? 100 : -40,
            right: page == 0 ? -60 : page == 1 ? -80 : 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  slides[page.clamp(0, slides.length - 1)].accentColor.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: const Cubic(0.22, 1.0, 0.36, 1.0),
            bottom: page == 0 ? 120 : page == 1 ? 60 : 180,
            left: page == 0 ? -80 : page == 1 ? 40 : -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  slides[page.clamp(0, slides.length - 1)].accentColor.withValues(alpha: 0.07),
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

// ── Slide page ────────────────────────────────────────────────────────────────

class _SlidePage extends StatefulWidget {
  const _SlidePage({required this.slide, required this.index});
  final _Slide slide;
  final int index;

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.9, curve: AppCurves.spring),
    ));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slide;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          FadeTransition(
            opacity: _iconFade,
            child: ScaleTransition(
              scale: _iconScale,
              child: _IllustrationCard(slide: s),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          // Text
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Column(
                children: [
                  Text(
                    s.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayM.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.body,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyL.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration card ─────────────────────────────────────────────────────────

class _IllustrationCard extends StatefulWidget {
  const _IllustrationCard({required this.slide});
  final _Slide slide;

  @override
  State<_IllustrationCard> createState() => _IllustrationCardState();
}

class _IllustrationCardState extends State<_IllustrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slide;
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) {
        final offset = math.sin(_float.value * math.pi) * 6.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: s.accentColor.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: s.accentColor.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: s.accentColor.withValues(alpha: 0.18),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: s.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(s.icon, size: 44, color: s.accentColor),
          ),
        ),
      ),
    );
  }
}

// ── Page indicator ────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.count});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.emerald
                : AppColors.textTertiary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Next button ───────────────────────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  const _NextButton(
      {required this.isLast, required this.accent, required this.onTap});
  final bool isLast;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accent,
                widget.accent.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.30),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLast ? 'Comenzar' : 'Continuar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Currency data ─────────────────────────────────────────────────────────────

class _Currency {
  const _Currency({
    required this.flag,
    required this.code,
    required this.name,
    required this.symbol,
  });
  final String flag;
  final String code;
  final String name;
  final String symbol;
}

const _currencies = [
  _Currency(flag: '🇺🇸', code: 'USD', name: 'Dólar americano', symbol: '\$'),
  _Currency(flag: '🇲🇽', code: 'MXN', name: 'Peso mexicano', symbol: '\$'),
  _Currency(flag: '🇦🇷', code: 'ARS', name: 'Peso argentino', symbol: '\$'),
  _Currency(flag: '🇨🇴', code: 'COP', name: 'Peso colombiano', symbol: '\$'),
  _Currency(flag: '🇨🇱', code: 'CLP', name: 'Peso chileno', symbol: '\$'),
  _Currency(flag: '🇧🇷', code: 'BRL', name: 'Real brasileño', symbol: 'R\$'),
  _Currency(flag: '🇵🇪', code: 'PEN', name: 'Sol peruano', symbol: 'S/'),
  _Currency(flag: '🇺🇾', code: 'UYU', name: 'Peso uruguayo', symbol: '\$U'),
  _Currency(flag: '🇪🇺', code: 'EUR', name: 'Euro', symbol: '€'),
  _Currency(flag: '🇬🇧', code: 'GBP', name: 'Libra esterlina', symbol: '£'),
];

// ── Name input slide ──────────────────────────────────────────────────────────

class _NameInputSlide extends StatelessWidget {
  const _NameInputSlide({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.person_outline_rounded,
                size: 40, color: AppColors.emerald),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '¿Cómo te llamas?',
            textAlign: TextAlign.center,
            style: AppTypography.displayM.copyWith(
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Así te saludaremos cada vez que abras Vexa.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Tu nombre',
                hintStyle: AppTypography.headingS.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Puedes cambiarlo después en tu perfil.',
            textAlign: TextAlign.center,
            style: AppTypography.labelS
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Currency slide ────────────────────────────────────────────────────────────

class _CurrencySlide extends StatelessWidget {
  const _CurrencySlide({
    required this.selectedIndex,
    required this.onSelect,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.currency_exchange_rounded,
                size: 40, color: AppColors.emerald),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Tu moneda',
            textAlign: TextAlign.center,
            style: AppTypography.displayM.copyWith(
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Elige la moneda que usas en tu día a día.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _currencies.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final c = _currencies[i];
                final selected = i == selectedIndex;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.emerald.withValues(alpha: 0.10)
                          : AppColors.card,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                        color: selected
                            ? AppColors.emerald.withValues(alpha: 0.40)
                            : AppColors.glassBorder,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c.flag,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: AppTypography.labelL.copyWith(
                                    color: AppColors.textPrimary),
                              ),
                              Text(
                                c.code,
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          c.symbol,
                          style: AppTypography.headingS.copyWith(
                            color: selected
                                ? AppColors.emerald
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (selected)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: AppSpacing.sm),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 12,
                                  color: AppColors.textInverse),
                            ),
                          )
                        else
                          const SizedBox(width: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
