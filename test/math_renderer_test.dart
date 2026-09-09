import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/core/utils/math_renderer.dart';

void main() {
  testWidgets('MathFormulaView renders display math with multiple \\[ \\] blocks', (tester) async {
    const input = r'\[ V = IR \] \[ I = \frac{V}{R} \] \[ R = \frac{V}{I} \]';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathFormulaView(formula: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MathFormulaView), findsOneWidget);
  });

  testWidgets('MathFormulaView renders pure LaTeX without delimiters', (tester) async {
    const input = r'I = \frac{V}{R}';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathFormulaView(formula: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MathFormulaView), findsOneWidget);
  });

  testWidgets('MathFormulaView renders mixed text with inline dollar delimiters', (tester) async {
    const input = r'Given $V = 10\text{V}$ and $R = 5\Omega$, find current.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathFormulaView(formula: input),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MathFormulaView), findsOneWidget);
  });
}
