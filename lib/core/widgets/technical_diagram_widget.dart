import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/question_model.dart';

/// Renders procedural vector diagrams for ECE / VLSI technical questions.
/// Supports Logic Gates, Timing Waveforms, Flip-Flops, FSM States, and Memory Blocks.
class TechnicalDiagramWidget extends StatelessWidget {
  final DiagramType diagramType;
  final Map<String, dynamic>? diagramData;
  final String? diagramImageBase64;
  final double height;
  final bool showBorder;

  const TechnicalDiagramWidget({
    super.key,
    required this.diagramType,
    this.diagramData,
    this.diagramImageBase64,
    this.height = 200,
    this.showBorder = true,
  });

  factory TechnicalDiagramWidget.fromQuestion(
    QuestionModel question, {
    double height = 200,
    bool showBorder = true,
  }) {
    return TechnicalDiagramWidget(
      diagramType: question.diagramType,
      diagramData: question.diagramData,
      diagramImageBase64: question.diagramImageBase64,
      height: height,
      showBorder: showBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (diagramType == DiagramType.none &&
        (diagramImageBase64 == null || diagramImageBase64!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Widget childWidget;

    if (diagramImageBase64 != null && diagramImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(diagramImageBase64!);
        childWidget = Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text('Unable to render image diagram'),
            ),
          ),
        );
      } catch (_) {
        childWidget = const Center(child: Text('Invalid diagram image data'));
      }
    } else {
      switch (diagramType) {
        case DiagramType.logicGate:
          childWidget = CustomPaint(
            painter: LogicGatePainter(
              data: diagramData ?? {},
              isDark: isDark,
              primaryColor: primaryColor,
            ),
            size: Size.infinite,
          );
          break;
        case DiagramType.timingWaveform:
          childWidget = CustomPaint(
            painter: TimingWaveformPainter(
              data: diagramData ?? {},
              isDark: isDark,
              primaryColor: primaryColor,
            ),
            size: Size.infinite,
          );
          break;
        case DiagramType.flipFlop:
          childWidget = CustomPaint(
            painter: FlipFlopPainter(
              data: diagramData ?? {},
              isDark: isDark,
              primaryColor: primaryColor,
            ),
            size: Size.infinite,
          );
          break;
        case DiagramType.fsmState:
          childWidget = CustomPaint(
            painter: FSMStatePainter(
              data: diagramData ?? {},
              isDark: isDark,
              primaryColor: primaryColor,
            ),
            size: Size.infinite,
          );
          break;
        case DiagramType.circuit:
        case DiagramType.memoryBlock:
          childWidget = CustomPaint(
            painter: MemoryBlockPainter(
              data: diagramData ?? {},
              isDark: isDark,
              primaryColor: primaryColor,
            ),
            size: Size.infinite,
          );
          break;
        case DiagramType.customImage:
        case DiagramType.none:
          return const SizedBox.shrink();
      }
    }

    return RepaintBoundary(
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: showBorder
              ? Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1.2,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: childWidget,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. LOGIC GATE PAINTER (AND, OR, NAND, NOR, XOR, Inverter)
// ---------------------------------------------------------------------------
class LogicGatePainter extends CustomPainter {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color primaryColor;

  LogicGatePainter({
    required this.data,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white70 : const Color(0xFF1E293B);
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withOpacity(0.5)
          : const Color(0xFFE2E8F0).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final gateType = (data['gateType'] as String? ?? 'NAND').toUpperCase();
    final inputA = data['inputA'] as String? ?? 'A';
    final inputB = data['inputB'] as String? ?? 'B';
    final outputY = data['outputY'] as String? ?? 'Y = (A • B)\'';

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const gateWidth = 90.0;
    const gateHeight = 70.0;

    final gateLeft = centerX - gateWidth / 2;
    final gateRight = centerX + gateWidth / 2;
    final gateTop = centerY - gateHeight / 2;
    final gateBottom = centerY + gateHeight / 2;

    // Draw Input Wires
    canvas.drawLine(Offset(gateLeft - 45, centerY - 16), Offset(gateLeft, centerY - 16), linePaint);
    canvas.drawLine(Offset(gateLeft - 45, centerY + 16), Offset(gateLeft, centerY + 16), linePaint);

    // Draw Input Labels
    _drawText(canvas, inputA, Offset(gateLeft - 60, centerY - 24), strokeColor, 12, true);
    _drawText(canvas, inputB, Offset(gateLeft - 60, centerY + 8), strokeColor, 12, true);

    final path = Path();
    if (gateType.contains('OR') || gateType.contains('NOR') || gateType.contains('XOR')) {
      // OR style curved back
      path.moveTo(gateLeft, gateTop);
      path.quadraticBezierTo(gateLeft + 15, centerY, gateLeft, gateBottom);
      path.quadraticBezierTo(gateLeft + 45, gateBottom, gateRight, centerY);
      path.quadraticBezierTo(gateLeft + 45, gateTop, gateLeft, gateTop);
      path.close();

      if (gateType.contains('XOR')) {
        // Extra input curve
        final xorPath = Path()
          ..moveTo(gateLeft - 8, gateTop)
          ..quadraticBezierTo(gateLeft + 7, centerY, gateLeft - 8, gateBottom);
        canvas.drawPath(xorPath, linePaint);
      }
    } else {
      // AND / NAND style
      path.moveTo(gateLeft, gateTop);
      path.lineTo(gateLeft + 35, gateTop);
      path.arcToPoint(
        Offset(gateLeft + 35, gateBottom),
        radius: const Radius.circular(gateHeight / 2),
        clockwise: true,
      );
      path.lineTo(gateLeft, gateBottom);
      path.close();
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Inversion Bubble for NAND / NOR / NOT
    double wireStartX = gateRight;
    if (gateType.startsWith('N') || gateType.contains('NOT') || gateType.contains('NAND') || gateType.contains('NOR')) {
      canvas.drawCircle(Offset(gateRight + 5, centerY), 4.5, fillPaint);
      canvas.drawCircle(Offset(gateRight + 5, centerY), 4.5, linePaint);
      wireStartX = gateRight + 10;
    }

    // Output Wire
    canvas.drawLine(Offset(wireStartX, centerY), Offset(wireStartX + 50, centerY), linePaint);
    _drawText(canvas, outputY, Offset(wireStartX + 56, centerY - 9), accentColor, 13, true);

    // Gate Title at top
    _drawText(canvas, 'Logic Gate: $gateType', Offset(centerX - 40, 10), strokeColor, 11, false);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 2. TIMING WAVEFORM PAINTER (Clocks, Setups, Digital Signals)
// ---------------------------------------------------------------------------
class TimingWaveformPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color primaryColor;

  TimingWaveformPainter({
    required this.data,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final gridColor = isDark ? Colors.white10 : Colors.black12;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF334155);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final startX = 65.0;
    final endX = size.width - 20;
    final period = (endX - startX) / 6.0;

    // Draw grid vertical cycle lines
    for (int i = 0; i <= 6; i++) {
      final x = startX + i * period;
      canvas.drawLine(Offset(x, 15), Offset(x, size.height - 15), gridPaint);
      _drawText(canvas, 'T$i', Offset(x - 6, size.height - 14), labelColor, 9);
    }

    // Signal 1: CLOCK
    _drawText(canvas, 'CLK', Offset(10, 32), labelColor, 11, bold: true);
    final clkPath = Path();
    for (int i = 0; i < 6; i++) {
      final x = startX + i * period;
      final mid = x + period / 2;
      if (i == 0) clkPath.moveTo(x, 48);
      clkPath.lineTo(x, 26);
      clkPath.lineTo(mid, 26);
      clkPath.lineTo(mid, 48);
      clkPath.lineTo(x + period, 48);
    }
    canvas.drawPath(clkPath, linePaint);

    // Signal 2: DATA INPUT
    _drawText(canvas, 'DATA', Offset(10, 80), labelColor, 11, bold: true);
    final dataPaint = Paint()
      ..color = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dPath = Path()
      ..moveTo(startX, 95)
      ..lineTo(startX + period * 1.5, 95)
      ..lineTo(startX + period * 1.5, 73)
      ..lineTo(startX + period * 3.5, 73)
      ..lineTo(startX + period * 3.5, 95)
      ..lineTo(endX, 95);
    canvas.drawPath(dPath, dataPaint);

    // Signal 3: OUTPUT Q (Triggered on rising edge)
    _drawText(canvas, 'Q(t)', Offset(10, 130), labelColor, 11, bold: true);
    final qPaint = Paint()
      ..color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final qPath = Path()
      ..moveTo(startX, 145)
      ..lineTo(startX + period * 2, 145)
      ..lineTo(startX + period * 2, 122)
      ..lineTo(startX + period * 4, 122)
      ..lineTo(startX + period * 4, 145)
      ..lineTo(endX, 145);
    canvas.drawPath(qPath, qPaint);

    // Setup time indicator marker
    final markerPaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(startX + period * 2, 20), Offset(startX + period * 2, 155), markerPaint);
    _drawText(canvas, 'Active Edge', Offset(startX + period * 2 - 25, 6), Colors.red.shade400, 9);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 3. FLIP-FLOP PAINTER (D, JK, T, Master-Slave)
// ---------------------------------------------------------------------------
class FlipFlopPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color primaryColor;

  FlipFlopPainter({
    required this.data,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white70 : const Color(0xFF1E293B);
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFE2E8F0).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final type = (data['flipFlopType'] as String? ?? 'JK Flip-Flop').toUpperCase();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const boxW = 110.0;
    const boxH = 120.0;

    final rect = Rect.fromCenter(center: Offset(centerX, centerY), width: boxW, height: boxH);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), linePaint);

    // Title inside box
    _drawText(canvas, type, Offset(centerX - 35, centerY - 48), accentColor, 11, bold: true);

    // Input wires
    canvas.drawLine(Offset(rect.left - 35, rect.top + 28), Offset(rect.left, rect.top + 28), linePaint);
    _drawText(canvas, type.contains('JK') ? 'J' : (type.contains('T') ? 'T' : 'D'), Offset(rect.left - 48, rect.top + 20), strokeColor, 12, bold: true);

    // Clock wire & triangle symbol
    canvas.drawLine(Offset(rect.left - 35, centerY), Offset(rect.left, centerY), linePaint);
    final clkSymbol = Path()
      ..moveTo(rect.left, centerY - 7)
      ..lineTo(rect.left + 9, centerY)
      ..lineTo(rect.left, centerY + 7);
    canvas.drawPath(clkSymbol, linePaint);
    _drawText(canvas, 'CLK', Offset(rect.left - 52, centerY - 7), strokeColor, 10);

    // Bottom Input wire (e.g. K in JK)
    if (type.contains('JK')) {
      canvas.drawLine(Offset(rect.left - 35, rect.bottom - 28), Offset(rect.left, rect.bottom - 28), linePaint);
      _drawText(canvas, 'K', Offset(rect.left - 48, rect.bottom - 36), strokeColor, 12, bold: true);
    }

    // Output wires (Q and Q')
    canvas.drawLine(Offset(rect.right, rect.top + 28), Offset(rect.right + 35, rect.top + 28), linePaint);
    _drawText(canvas, 'Q', Offset(rect.right + 40, rect.top + 20), strokeColor, 12, bold: true);

    canvas.drawLine(Offset(rect.right, rect.bottom - 28), Offset(rect.right + 35, rect.bottom - 28), linePaint);
    _drawText(canvas, "Q'", Offset(rect.right + 40, rect.bottom - 36), strokeColor, 12, bold: true);
    // Bubble on Q'
    canvas.drawCircle(Offset(rect.right + 4, rect.bottom - 28), 3.5, linePaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 4. FSM STATE PAINTER (Mealy / Moore State Transition Graph)
// ---------------------------------------------------------------------------
class FSMStatePainter extends CustomPainter {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color primaryColor;

  FSMStatePainter({
    required this.data,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white70 : const Color(0xFF1E293B);
    final nodeFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = nodeFill
      ..style = PaintingStyle.fill;

    final stateR = 24.0;
    final cy = size.height / 2;
    final s0 = Offset(size.width * 0.22, cy);
    final s1 = Offset(size.width * 0.50, cy);
    final s2 = Offset(size.width * 0.78, cy);

    // Draw State Nodes
    for (final pt in [s0, s1, s2]) {
      canvas.drawCircle(pt, stateR, fillPaint);
      canvas.drawCircle(pt, stateR, linePaint);
    }

    _drawText(canvas, 'S0', Offset(s0.dx - 8, s0.dy - 7), accentColor, 12, bold: true);
    _drawText(canvas, 'S1', Offset(s1.dx - 8, s1.dy - 7), accentColor, 12, bold: true);
    _drawText(canvas, 'S2', Offset(s2.dx - 8, s2.dy - 7), accentColor, 12, bold: true);

    // Transitions: S0 -> S1
    canvas.drawLine(Offset(s0.dx + stateR, cy - 6), Offset(s1.dx - stateR, cy - 6), linePaint);
    _drawText(canvas, '1/0', Offset((s0.dx + s1.dx) / 2 - 8, cy - 22), strokeColor, 10);

    // Transitions: S1 -> S2
    canvas.drawLine(Offset(s1.dx + stateR, cy - 6), Offset(s2.dx - stateR, cy - 6), linePaint);
    _drawText(canvas, '1/1', Offset((s1.dx + s2.dx) / 2 - 8, cy - 22), strokeColor, 10);

    // Transition: S2 -> S0 (Looping curved back)
    final loopBack = Path()
      ..moveTo(s2.dx, cy + stateR)
      ..quadraticBezierTo((s0.dx + s2.dx) / 2, cy + stateR + 42, s0.dx, cy + stateR);
    canvas.drawPath(loopBack, linePaint);
    _drawText(canvas, 'Reset: 0/0', Offset((s0.dx + s2.dx) / 2 - 25, cy + stateR + 24), strokeColor, 10);

    // Self loop on S0
    final selfLoop = Path()
      ..moveTo(s0.dx - 12, cy - stateR)
      ..quadraticBezierTo(s0.dx - 28, cy - stateR - 25, s0.dx, cy - stateR - 20)
      ..quadraticBezierTo(s0.dx + 12, cy - stateR - 25, s0.dx + 10, cy - stateR);
    canvas.drawPath(selfLoop, linePaint);
    _drawText(canvas, '0/0', Offset(s0.dx - 8, cy - stateR - 34), strokeColor, 9);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 5. MEMORY BLOCK / REGISTER ARRAY PAINTER
// ---------------------------------------------------------------------------
class MemoryBlockPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final bool isDark;
  final Color primaryColor;

  MemoryBlockPainter({
    required this.data,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isDark ? Colors.white70 : const Color(0xFF1E293B);
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final fillPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFE2E8F0).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Address Decoder Box
    final decRect = Rect.fromCenter(center: Offset(cx - 90, cy), width: 70, height: 100);
    canvas.drawRect(decRect, fillPaint);
    canvas.drawRect(decRect, linePaint);
    _drawText(canvas, 'Address\nDecoder\nk x 2^k', Offset(decRect.left + 8, cy - 20), strokeColor, 10);

    // Memory Cell Array Box
    final memRect = Rect.fromCenter(center: Offset(cx + 60, cy), width: 140, height: 110);
    canvas.drawRect(memRect, fillPaint);
    canvas.drawRect(memRect, linePaint);
    _drawText(canvas, '2^k x m Memory Array\n(SRAM / Register Bank)', Offset(memRect.left + 12, cy - 14), accentColor, 10, bold: true);

    // Word lines between decoder and memory
    for (int i = 0; i < 4; i++) {
      final y = decRect.top + 20 + i * 20;
      canvas.drawLine(Offset(decRect.right, y), Offset(memRect.left, y), linePaint);
    }
    _drawText(canvas, 'Word Lines (WL)', Offset(cx - 50, decRect.top + 2), strokeColor, 8);

    // Address bus input
    canvas.drawLine(Offset(decRect.left - 40, cy), Offset(decRect.left, cy), linePaint);
    _drawText(canvas, 'k Address Bits', Offset(decRect.left - 65, cy - 16), strokeColor, 9);

    // Data output bus
    canvas.drawLine(Offset(memRect.right, cy), Offset(memRect.right + 40, cy), linePaint);
    _drawText(canvas, 'm Data Bits', Offset(memRect.right + 5, cy - 16), strokeColor, 9);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
