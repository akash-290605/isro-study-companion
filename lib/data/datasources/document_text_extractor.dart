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
  /// Uses index scanning, skips non-text/image streams, and yields the event loop
  /// so the browser UI thread never freezes.
  static Future<String> _extractFromPdf(Uint8List bytes) async {
    final StringBuffer buffer = StringBuffer();
    final zlibDecoder = ZLibDecoder();
    final latin1String = latin1.decode(bytes);

    int searchIdx = 0;
    int streamsProcessed = 0;

    while (true) {
      final streamStart = latin1String.indexOf('stream', searchIdx);
      if (streamStart == -1) break;

      // Stream content starts after stream\r?\n
      int contentStart = streamStart + 6;
      if (contentStart < latin1String.length && latin1String[contentStart] == '\r') contentStart++;
      if (contentStart < latin1String.length && latin1String[contentStart] == '\n') contentStart++;

      // Find endstream
      final streamEnd = latin1String.indexOf('endstream', contentStart);
      if (streamEnd == -1) break;

      searchIdx = streamEnd + 9;
      streamsProcessed++;

      // Periodically yield event loop every 15 streams to keep UI 100% responsive
      if (streamsProcessed % 15 == 0) {
        await Future.delayed(Duration.zero);
      }

      // Check dictionary before stream (within last 350 chars)
      final dictSearchStart = (streamStart - 350) > 0 ? (streamStart - 350) : 0;
      final dictSnippet = latin1String.substring(dictSearchStart, streamStart);

      // Skip image streams, XObjects, and font data - they NEVER contain questions
      if (dictSnippet.contains('/Subtype /Image') ||
          dictSnippet.contains('/Subtype/Image') ||
          (dictSnippet.contains('/Type /XObject') && dictSnippet.contains('/Subtype /Image')) ||
          dictSnippet.contains('/Type /Font') ||
          dictSnippet.contains('/FontDescriptor')) {
        continue;
      }

      final isFlate = dictSnippet.contains('/FlateDecode');
      final rawSlice = bytes.sublist(contentStart, streamEnd);

      Uint8List decompressed;
      if (isFlate) {
        try {
          decompressed = Uint8List.fromList(zlibDecoder.decodeBytes(rawSlice));
        } catch (_) {
          continue;
        }
      } else {
        decompressed = rawSlice;
      }

      final text = _extractTextFromPdfStream(decompressed);
      if (text.trim().isNotEmpty) {
        buffer.writeln(text);
      }
    }

    // Fallback if no streams returned text
    if (buffer.isEmpty) {
      final uncompressedText = _extractTextFromPdfStream(bytes);
      if (uncompressedText.trim().isNotEmpty) {
        buffer.writeln(uncompressedText);
      }
    }

    return _sanitizeExtractedText(buffer.toString());
  }

  /// Extracts textual characters from PDF stream, parsing string literals,
  /// TJ arrays, and preserving line breaks between text blocks.
  static String _extractTextFromPdfStream(Uint8List streamBytes) {
    final str = latin1.decode(streamBytes);
    final sb = StringBuffer();

    int i = 0;
    final len = str.length;

    while (i < len) {
      // Newlines on block terminators or text positioning
      if (str.startsWith('ET', i) || str.startsWith('T*', i)) {
        sb.writeln();
        i += 2;
        continue;
      }

      if (str[i] == '(') {
        // String literal with escaped parentheses support \( and \)
        int j = i + 1;
        int parenDepth = 1;
        final strChars = StringBuffer();

        while (j < len && parenDepth > 0) {
          if (str[j] == '\\' && j + 1 < len) {
            final next = str[j + 1];
            if (next == '(' || next == ')' || next == '\\') {
              strChars.write(next);
              j += 2;
              continue;
            } else if (next == 'n') {
              strChars.write('\n');
              j += 2;
              continue;
            } else if (next == 'r') {
              strChars.write('\r');
              j += 2;
              continue;
            } else if (next == 't') {
              strChars.write('\t');
              j += 2;
              continue;
            }
          }
          if (str[j] == '(') {
            parenDepth++;
          } else if (str[j] == ')') {
            parenDepth--;
            if (parenDepth == 0) {
              j++;
              break;
            }
          }
          strChars.write(str[j]);
          j++;
        }

        sb.write(strChars.toString());
        sb.write(' ');
        i = j;
        continue;
      }

      if (str[i] == '[') {
        // TJ array: [ (string1) -120 (string2) ] TJ
        int j = i + 1;
        while (j < len && str[j] != ']') {
          if (str[j] == '(') {
            int k = j + 1;
            int pDepth = 1;
            final strChars = StringBuffer();
            while (k < len && pDepth > 0) {
              if (str[k] == '\\' && k + 1 < len) {
                final next = str[k + 1];
                if (next == '(' || next == ')' || next == '\\') {
                  strChars.write(next);
                  k += 2;
                  continue;
                }
              }
              if (str[k] == '(') {
                pDepth++;
              } else if (str[k] == ')') {
                pDepth--;
                if (pDepth == 0) {
                  k++;
                  break;
                }
              }
              strChars.write(str[k]);
              k++;
            }
            sb.write(strChars.toString());
            j = k;
          } else {
            j++;
          }
        }
        sb.write(' ');
        i = j + 1;
        continue;
      }

      i++;
    }

    return sb.toString();
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
