import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Helper widget to render LaTeX equations cleanly, with fallback to styled text.
/// Optimized to avoid blocking the JavaScript event loop on Flutter Web.
class MathFormulaView extends StatelessWidget {
  final String formula;
  final TextStyle? textStyle;
  final bool isSelectable;

  const MathFormulaView({
    super.key,
    required this.formula,
    this.textStyle,
    this.isSelectable = false,
  });

  // Identifies legitimate LaTeX math expressions:
  // Must have $...$ or specific LaTeX commands like \frac, \sqrt, \sum, \int, \times, etc.
  static final RegExp _mathCmdRegex = RegExp(
    r'(\$[^$]+\$|\\frac\{|\\sqrt\{|\\sum[_\^]|\\int[_\^]|\\times|\\cdot|\\approx|\\leq|\\geq|\\alpha|\\beta|\\omega|\\pi|\\mu|\\eta|\\theta|\\partial|\\int\b|\\sum\b|\^[0-9a-zA-Z]|\^\{[^}]+\}|_\{[^}]+\})',
  );

  @override
  Widget build(BuildContext context) {
    final raw = formula.trim();
    if (raw.isEmpty) return const SizedBox.shrink();

    // Prevent catastrophic layout freeze on raw document / binary stream dumps
    final bool isRawBinaryDump = raw.startsWith('%PDF') ||
        raw.startsWith('PDF-') ||
        raw.contains('1 0 obj') ||
        raw.contains('<< /Type') ||
        raw.contains('<</Type');

    final safeFormula = isRawBinaryDump
        ? (raw.length > 300 ? '${raw.substring(0, 300)}... [Corrupted document stream isolated]' : raw)
        : (raw.length > 1500 ? '${raw.substring(0, 1500)}... [Content truncated for display]' : raw);

    // Fast path: If formula is binary dump or does not contain real LaTeX math commands or $...$,
    // render standard high-speed native Text widget without invoking TeX parser!
    if (isRawBinaryDump || !_mathCmdRegex.hasMatch(safeFormula)) {
      return Text(
        safeFormula,
        style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      );
    }

    // If formula contains inline math $...$, split and render text + math segments
    if (safeFormula.contains(r'$')) {
      return _buildInlineMath(context, safeFormula);
    }

    // Pure mathematical expression (e.g. Formula Bank entry)
    try {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          safeFormula,
          textStyle: textStyle ??
              TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          onErrorFallback: (error) {
            return Text(
              safeFormula,
              style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
            );
          },
        ),
      );
    } catch (_) {
      return Text(
        safeFormula,
        style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      );
    }
  }

  Widget _buildInlineMath(BuildContext context, String input) {
    final parts = input.split(r'$');
    final defaultStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(parts.length, (idx) {
        final part = parts[idx];
        if (part.isEmpty) return const SizedBox.shrink();
        final isMath = idx % 2 == 1;

        if (isMath) {
          try {
            return Math.tex(
              part,
              textStyle: defaultStyle,
              onErrorFallback: (_) => Text(part, style: defaultStyle),
            );
          } catch (_) {
            return Text(part, style: defaultStyle);
          }
        } else {
          return Text(part, style: defaultStyle);
        }
      }),
    );
  }
}

