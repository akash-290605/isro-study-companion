import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Helper widget to render LaTeX equations cleanly, with fallback to styled text.
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

  @override
  Widget build(BuildContext context) {
    // If formula contains LaTeX indicators like \frac, \sum, \int, ^, _, etc.
    final hasLatex = formula.contains('\\') ||
        formula.contains('^') ||
        formula.contains('_') ||
        formula.contains('{');

    if (!hasLatex) {
      return Text(
        formula,
        style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      );
    }

    try {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          formula,
          textStyle: textStyle ??
              TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          onErrorFallback: (error) {
            return Text(
              formula,
              style: (textStyle ?? Theme.of(context).textTheme.bodyLarge)
                  ?.copyWith(fontFamily: 'monospace'),
            );
          },
        ),
      );
    } catch (_) {
      return Text(
        formula,
        style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
      );
    }
  }
}

