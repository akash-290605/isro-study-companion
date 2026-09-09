import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// A robust math segment representing either plain text or mathematical TeX.
class _MathSegment {
  final String text;
  final bool isMath;
  final bool isDisplay;

  const _MathSegment({
    required this.text,
    required this.isMath,
    this.isDisplay = false,
  });
}

/// Helper widget to render LaTeX equations cleanly, with fallback to styled text.
/// Supports display math (`\[ ... \]`, `$$ ... $$`), inline math (`\( ... \)`, `$ ... $`),
/// pure LaTeX commands (e.g. `\frac`, `\sum`, `V = IR`), engineering units, and multi-line equations.
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

  /// Identifies if a string contains LaTeX / mathematical notation.
  static final RegExp _mathCmdRegex = RegExp(
    r'(\$|\\\[|\\\]|\\\(|\\\)|\\frac|\\sqrt|\\sum|\\int|\\times|\\cdot|\\approx|\\leq|\\geq|\\alpha|\\beta|\\gamma|\\delta|\\Delta|\\epsilon|\\theta|\\lambda|\\mu|\\pi|\\rho|\\sigma|\\tau|\\omega|\\Omega|\\ohm|\\degree|\\partial|\^|_|\\begin|\\text\{)',
    caseSensitive: false,
  );

  /// Cleans and sanitizes TeX expressions for flutter_math_fork.
  static String cleanTex(String input) {
    var s = input.trim();
    if (s.isEmpty) return s;

    // Strip enclosing display or inline math delimiters if present
    if ((s.startsWith(r'\[') && s.endsWith(r'\]')) ||
        (s.startsWith(r'$$') && s.endsWith(r'$$')) ||
        (s.startsWith(r'\(') && s.endsWith(r'\)'))) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'$') && s.endsWith(r'$') && s.length >= 2) {
      s = s.substring(1, s.length - 1).trim();
    }

    // Strip unescaped double backslashes for delimiters like \\[ or \\]
    if (s.startsWith(r'\[') || s.startsWith(r'$$') || s.startsWith(r'\(')) {
      s = s.replaceAll(r'\[', '').replaceAll(r'\]', '').trim();
      s = s.replaceAll(r'$$', '').trim();
      s = s.replaceAll(r'\(', '').replaceAll(r'\)', '').trim();
    }

    // Engineering symbol replacements
    s = s.replaceAll(r'\ohm', r'\Omega');
    s = s.replaceAll(r'\degree', r'^\circ');
    s = s.replaceAll(r'\celsius', r'^\circ\text{C}');

    // Replace unescaped % (not preceded by \) with \% so TeX parser does not drop the rest of the string as a comment
    s = s.replaceAllMapped(RegExp(r'(?<!\\)%'), (m) => r'\%');

    return s;
  }

  /// Parses text into alternating text and math segments based on LaTeX delimiters:
  /// 1. `$$ ... $$`
  /// 2. `\[ ... \]` or `\\[ ... \\]`
  /// 3. `\( ... \)` or `\\( ... \\)`
  /// 4. `$ ... $`
  static List<_MathSegment> _parseSegments(String input) {
    final segments = <_MathSegment>[];
    if (input.trim().isEmpty) return segments;

    // Pattern matching standard math delimiters
    final pattern = RegExp(
      r'(\$\$(.+?)\$\$|(?:\\[\[]|\\\\\s*\[)([\s\S]+?)(?:\\[\]]|\\\\\s*\])|(?:\\[\(]|\\\\\s*\()([\s\S]+?)(?:\\[\)]|\\\\\s*\))|\$([^\$\n]+?)\$)',
      multiLine: true,
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(input)) {
      if (match.start > lastIndex) {
        final preceding = input.substring(lastIndex, match.start);
        if (preceding.isNotEmpty) {
          segments.add(_MathSegment(text: preceding, isMath: false));
        }
      }

      String content = '';
      bool isDisplay = false;

      if (match.group(2) != null) {
        content = match.group(2)!;
        isDisplay = true;
      } else if (match.group(3) != null) {
        content = match.group(3)!;
        isDisplay = true;
      } else if (match.group(4) != null) {
        content = match.group(4)!;
        isDisplay = false;
      } else if (match.group(5) != null) {
        content = match.group(5)!;
        isDisplay = false;
      }

      if (content.trim().isNotEmpty) {
        segments.add(_MathSegment(
          text: cleanTex(content),
          isMath: true,
          isDisplay: isDisplay,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < input.length) {
      final remaining = input.substring(lastIndex);
      if (remaining.isNotEmpty) {
        segments.add(_MathSegment(text: remaining, isMath: false));
      }
    }

    return segments;
  }

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

    if (isRawBinaryDump) {
      final safe = raw.length > 300 ? '${raw.substring(0, 300)}... [Corrupted document stream isolated]' : raw;
      return Text(safe, style: textStyle ?? Theme.of(context).textTheme.bodyLarge);
    }

    final defaultStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    // Step 1: Check if input contains LaTeX delimiters ($$, \[, \(, $)
    final segments = _parseSegments(raw);

    if (segments.isNotEmpty && segments.any((s) => s.isMath)) {
      // Check if all non-math segments are purely whitespace (e.g. user typed multiple display equations: \[ V = IR \] \[ I = V/R \])
      final nonMathContent = segments.where((s) => !s.isMath).map((s) => s.text.trim()).join();
      final mathSegments = segments.where((s) => s.isMath).toList();

      if (nonMathContent.isEmpty && mathSegments.isNotEmpty) {
        // Pure multi-equation presentation (like Formula Bank entries)
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: mathSegments.map((seg) {
              return _buildTexWidget(context, seg.text, defaultStyle);
            }).toList(),
          ),
        );
      }

      // Mixed text and inline / display math
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: segments.map((seg) {
          if (seg.isMath) {
            return _buildTexWidget(context, seg.text, defaultStyle);
          } else {
            return Text(seg.text, style: defaultStyle);
          }
        }).toList(),
      );
    }

    // Step 2: No delimiters found, but could be a pure TeX formula (e.g. "V = IR", "I = \frac{V}{R}", "\sum I_k = 0")
    if (_mathCmdRegex.hasMatch(raw) || raw.contains('=')) {
      final cleaned = cleanTex(raw);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildTexWidget(context, cleaned, defaultStyle),
      );
    }

    // Step 3: Plain text fallback
    return Text(raw, style: defaultStyle);
  }

  Widget _buildTexWidget(BuildContext context, String tex, TextStyle style) {
    try {
      return Math.tex(
        tex,
        textStyle: style,
        onErrorFallback: (err) {
          return Text(tex, style: style);
        },
      );
    } catch (_) {
      return Text(tex, style: style);
    }
  }
}
