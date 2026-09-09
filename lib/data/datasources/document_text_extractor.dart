import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Service to reliably extract plain text from multi-format documents (PDF, DOCX, PPTX, TXT)
/// without blocking the UI thread or failing on binary streams.
class DocumentTextExtractor {
  /// Extracts plain text from the given binary file bytes.
  static Future<String> extractText({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lower = fileName.toLowerCase();

    if (_isPdf(bytes, lower)) {
      return _extractFromPdf(bytes);
    } else if (lower.endsWith('.docx')) {
      return _extractFromDocx(bytes);
    } else if (lower.endsWith('.pptx')) {
      return _extractFromPptx(bytes);
    } else {
      return _extractFromPlainText(bytes);
    }
  }

  static bool _isPdf(Uint8List bytes, String fileName) {
    if (fileName.endsWith('.pdf')) return true;
    if (bytes.length >= 5) {
      // PDF magic number: %PDF-
      return bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46 &&
          bytes[4] == 0x2D;
    }
    return false;
  }

  /// Extracts text from PDF bytes by decoding uncompressed and FlateDecode streams.
  static Future<String> _extractFromPdf(Uint8List bytes) async {
    final StringBuffer buffer = StringBuffer();
    final zlibDecoder = ZLibDecoder();

    // Scan for streams in the PDF
    final latin1String = latin1.decode(bytes);
    final streamStartRegex = RegExp(r'stream\r?\n');
    final streamEndRegex = RegExp(r'\r?\nendstream');

    final matches = streamStartRegex.allMatches(latin1String).toList();
    int streamsFound = 0;

    for (final m in matches) {
      final start = m.end;
      final endMatch = streamEndRegex.firstMatch(latin1String.substring(start));
      if (endMatch == null) continue;

      final end = start + endMatch.start;
      if (end <= start || end > bytes.length) continue;

      // Extract dictionary before stream to check filters
      final dictStart = latin1String.lastIndexOf('<<', start);
      final isFlate = dictStart != -1 &&
          latin1String.substring(dictStart, start).contains('/FlateDecode');

      final streamSlice = bytes.sublist(start, end);

      Uint8List decompressed;
      if (isFlate) {
        try {
          decompressed = Uint8List.fromList(zlibDecoder.decodeBytes(streamSlice));
        } catch (_) {
          decompressed = streamSlice;
        }
      } else {
        decompressed = streamSlice;
      }

      final text = _extractTextFromPdfStream(decompressed);
      if (text.trim().isNotEmpty) {
        buffer.writeln(text);
        streamsFound++;
      }

      // Yield event loop every 5 streams to prevent UI freezing
      if (streamsFound % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // Fallback: If streams yielded no text (e.g. uncompressed text outside streams)
    if (buffer.isEmpty) {
      final uncompressedText = _extractTextFromPdfStream(bytes);
      if (uncompressedText.trim().isNotEmpty) {
        buffer.writeln(uncompressedText);
      }
    }

    return _sanitizeExtractedText(buffer.toString());
  }

  /// Extracts textual characters from PDF BT...ET blocks and (string) Tj / TJ operators
  static String _extractTextFromPdfStream(Uint8List streamBytes) {
    final StringBuffer text = StringBuffer();
    final streamStr = latin1.decode(streamBytes);

    // Regular expressions for text operators in PDF content streams
    final tjRegex = RegExp(r'\((.*?)\)\s*Tj');
    final tjArrayRegex = RegExp(r'\[(.*?)\]\s*TJ');

    for (final match in tjRegex.allMatches(streamStr)) {
      final raw = match.group(1);
      if (raw != null) {
        text.write(_unescapePdfString(raw));
        text.write(' ');
      }
    }

    for (final match in tjArrayRegex.allMatches(streamStr)) {
      final inner = match.group(1);
      if (inner != null) {
        final innerStrings = RegExp(r'\((.*?)\)').allMatches(inner);
        for (final sMatch in innerStrings) {
          final raw = sMatch.group(1);
          if (raw != null) {
            text.write(_unescapePdfString(raw));
          }
        }
        text.write(' ');
      }
    }

    return text.toString();
  }

  static String _unescapePdfString(String str) {
    return str
        .replaceAll(r'\)', ')')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');
  }

  /// Extracts text from Word .docx file by extracting word/document.xml
  static Future<String> _extractFromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) return _extractFromPlainText(bytes);

      final xml = utf8.decode(docFile.content as List<int>, allowMalformed: true);
      return _extractTextFromXml(xml);
    } catch (_) {
      return _extractFromPlainText(bytes);
    }
  }

  /// Extracts text from PowerPoint .pptx file by extracting slide XMLs
  static Future<String> _extractFromPptx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final StringBuffer buffer = StringBuffer();

      final slideFiles = archive.files
          .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final slide in slideFiles) {
        final xml = utf8.decode(slide.content as List<int>, allowMalformed: true);
        buffer.writeln(_extractTextFromXml(xml));
        await Future.delayed(Duration.zero);
      }

      return _sanitizeExtractedText(buffer.toString());
    } catch (_) {
      return _extractFromPlainText(bytes);
    }
  }

  static String _extractTextFromXml(String xml) {
    final tagRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>|<a:t[^>]*>(.*?)</a:t>');
    final StringBuffer buffer = StringBuffer();
    final matches = tagRegex.allMatches(xml);

    for (final m in matches) {
      final t1 = m.group(1) ?? m.group(2);
      if (t1 != null) {
        buffer.write(t1);
        buffer.write(' ');
      }
    }

    return _sanitizeExtractedText(buffer.toString());
  }

  static String _extractFromPlainText(Uint8List bytes) {
    try {
      return _sanitizeExtractedText(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  /// Removes binary noise, replacement characters, and trims line length
  static String _sanitizeExtractedText(String input) {
    final clean = input
        .replaceAll('\u0000', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .replaceAll(RegExp(r'\r\n|\r'), '\n');

    final lines = clean.split('\n');
    final validLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Truncate excessively long binary noise lines
      if (trimmed.length > 2000) {
        validLines.add(trimmed.substring(0, 2000));
      } else {
        validLines.add(trimmed);
      }
    }

    return validLines.join('\n');
  }
}
