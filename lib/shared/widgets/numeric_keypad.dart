import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vexa_colors_ext.dart';

/// Premium numeric keypad that replaces the native keyboard.
///
/// Layout:
///   1  2  3
///   4  5  6
///   7  8  9
///   .  0  ⌫
///   [  CONFIRMAR  ]
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.value,
    required this.onValueChanged,
    required this.onConfirm,
    this.confirmColor = AppColors.emerald,
    this.currencySymbol = '\$',
    this.keyHeight = 58,
    this.confirmHeight = 58,
  });

  final String value;
  final ValueChanged<String> onValueChanged;
  final VoidCallback onConfirm;
  final Color confirmColor;
  final String currencySymbol;
  final double keyHeight;
  final double confirmHeight;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  void _press(String key) {
    HapticFeedback.selectionClick();
    String next = value;

    if (key == '⌫') {
      if (next.isNotEmpty) next = next.substring(0, next.length - 1);
    } else if (key == '.') {
      if (!next.contains('.')) {
        next = next.isEmpty ? '0.' : '$next.';
      }
    } else {
      // Digit
      if (next.contains('.')) {
        final parts = next.split('.');
        if (parts[1].length >= 2) return; // max 2 decimal places
      }
      // Replace leading zero only if followed by a digit
      if (next == '0') {
        next = key;
      } else if (next.replaceAll('.', '').replaceAll('-', '').length < 10) {
        next = '$next$key';
      }
    }

    onValueChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final btnBgAlt = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);
    final btnFg = context.colors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Digit + decimal rows
        for (final row in _rows) ...[
          Row(
            children: row.map((key) {
              final isBackspace = key == '⌫';
              final isDot = key == '.';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _KeyButton(
                    label: key,
                    bg: isBackspace ? btnBgAlt : btnBg,
                    fg: isBackspace
                        ? context.colors.textSecondary
                        : btnFg,
                    isDot: isDot,
                    isBackspace: isBackspace,
                    height: keyHeight,
                    onTap: () => _press(key),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Confirm button
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: _ConfirmButton(
            color: confirmColor,
            height: confirmHeight,
            onTap: () {
              HapticFeedback.mediumImpact();
              onConfirm();
            },
          ),
        ),
      ],
    );
  }
}

// ── Single key button ─────────────────────────────────────────────────────────

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.isDot,
    required this.isBackspace,
    required this.height,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool isDot;
  final bool isBackspace;
  final double height;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.92,
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
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: widget.isBackspace
              ? Icon(Icons.backspace_outlined, size: 20, color: widget.fg)
              : widget.isDot
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.fg,
                    shape: BoxShape.circle,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: widget.fg,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Confirm button ─────────────────────────────────────────────────────────────

class _ConfirmButton extends StatefulWidget {
  const _ConfirmButton({
    required this.color,
    required this.height,
    required this.onTap,
  });
  final Color color;
  final double height;
  final VoidCallback onTap;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
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
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha: 0.78)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.30),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Guardar',
                style: AppTypography.labelL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
