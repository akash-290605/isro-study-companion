import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final Paint paint;
  final bool isEraser;

  DrawingPoint({
    required this.point,
    required this.paint,
    this.isEraser = false,
  });
}

class SketchDrawingDialog extends StatefulWidget {
  final String title;

  const SketchDrawingDialog({
    super.key,
    this.title = 'Draw Circuit / Diagram / Formula',
  });

  static Future<String?> show(BuildContext context, {String title = 'Draw Circuit / Diagram / Formula'}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SketchDrawingDialog(title: title),
    );
  }

  @override
  State<SketchDrawingDialog> createState() => _SketchDrawingDialogState();
}

class _SketchDrawingDialogState extends State<SketchDrawingDialog> {
  final List<List<DrawingPoint>> _strokes = [];
  List<DrawingPoint> _currentStroke = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  final List<Color> _colors = [
    Colors.black,
    const Color(0xFF1E3A8A), // Navy / Blue
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.deepOrange,
    Colors.purple,
  ];

  Paint _createPaint() {
    return Paint()
      ..color = _isEraser ? Colors.white : _selectedColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = _isEraser ? _strokeWidth * 3.5 : _strokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<void> _exportAndSave() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw on the canvas before saving.')),
      );
      return;
    }

    try {
      const width = 800.0;
      const height = 500.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      // White background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

      // Draw all strokes
      for (final stroke in _strokes) {
        if (stroke.isEmpty) continue;
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i].point, stroke[i + 1].point, stroke[i].paint);
        }
        if (stroke.length == 1) {
          canvas.drawCircle(stroke[0].point, stroke[0].paint.strokeWidth / 2, stroke[0].paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate PNG image data');
      }

      final uint8List = byteData.buffer.asUint8List();
      final base64Str = base64Encode(uint8List);

      if (mounted) {
        Navigator.of(context).pop(base64Str);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export sketch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 840,
        height: 640,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(Icons.draw_rounded, color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: _strokes.isNotEmpty ? _undo : null,
                ),
                IconButton(
                  tooltip: 'Clear Canvas',
                  icon: const Icon(Icons.delete_sweep_rounded),
                  onPressed: _strokes.isNotEmpty ? _clear : null,
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const Divider(),

            // Toolbar Row: Colors, Stroke, Eraser
            Row(
              children: [
                // Color Palette
                ..._colors.map((color) {
                  final isSelected = !_isEraser && _selectedColor == color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _isEraser = false;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue.shade900 : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),

                // Stroke widths
                const Text('Size: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ...[2.0, 4.0, 7.0].map((width) {
                  final isSelected = !_isEraser && _strokeWidth == width;
                  return IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Width ${width.toInt()}',
                    icon: CircleAvatar(
                      radius: width * 1.5,
                      backgroundColor: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _strokeWidth = width;
                        _isEraser = false;
                      });
                    },
                  );
                }),
                const SizedBox(width: 8),

                // Eraser button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isEraser ? Colors.red.shade50 : null,
                    side: BorderSide(color: _isEraser ? Colors.red : Colors.grey.shade300),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: Icon(Icons.cleaning_services_rounded, size: 16, color: _isEraser ? Colors.red : null),
                  label: Text('Eraser', style: TextStyle(color: _isEraser ? Colors.red : null, fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _isEraser = !_isEraser;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Drawing Canvas Area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (details) {
                          final point = details.localPosition;
                          _currentStroke = [
                            DrawingPoint(point: point, paint: _createPaint(), isEraser: _isEraser),
                          ];
                          setState(() {
                            _strokes.add(_currentStroke);
                          });
                        },
                        onPanUpdate: (details) {
                          final point = details.localPosition;
                          // Constrain to canvas
                          if (point.dx >= 0 && point.dx <= constraints.maxWidth &&
                              point.dy >= 0 && point.dy <= constraints.maxHeight) {
                            setState(() {
                              _currentStroke.add(
                                DrawingPoint(point: point, paint: _createPaint(), isEraser: _isEraser),
                              );
                            });
                          }
                        },
                        onPanEnd: (_) {
                          _currentStroke = [];
                        },
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _SketchPainter(strokes: _strokes),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💡 Draw using mouse or touchscreen. Click "Save Sketch" to attach.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save Sketch'),
                      onPressed: _exportAndSave,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;

  _SketchPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i].point, stroke[i + 1].point, stroke[i].paint);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0].point, stroke[0].paint.strokeWidth / 2, stroke[0].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}

