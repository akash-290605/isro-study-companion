import 'package:uuid/uuid.dart';
import '../../data/models/source_model.dart';

class TextChunker {
  static const _uuid = Uuid();

  /// Chunks raw text into indexed chunks with page number and section labels.
  static List<SourceChunkModel> chunkText({
    required String sourceId,
    required String text,
    String defaultSection = 'Main Content',
    String topic = '',
    int wordsPerChunk = 250,
  }) {
    if (text.trim().isEmpty) return [];

    final lines = text.split('\n');
    final List<SourceChunkModel> chunks = [];

    StringBuffer currentChunk = StringBuffer();
    int currentWordCount = 0;
    int currentPage = 1;
    String currentSection = defaultSection;

    for (final line in lines) {
      final trimmed = line.trim();

      // Detect page header/footer markers like "Page 2" or "--- Page 3 ---"
      final pageMatch = RegExp(r'(?:page|--- page)\s*(\d+)', caseSensitive: false).firstMatch(trimmed);
      if (pageMatch != null) {
        final parsedPage = int.tryParse(pageMatch.group(1) ?? '');
        if (parsedPage != null) {
          currentPage = parsedPage;
        }
      }

      // Detect section headers (e.g. "# Heading", "Section:", "1.1 Title")
      if (trimmed.startsWith('#') || trimmed.startsWith('##') || trimmed.startsWith('Section:')) {
        currentSection = trimmed.replaceAll(RegExp(r'^[#\s]+'), '');
      }

      currentChunk.writeln(line);
      final wordsInLine = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      currentWordCount += wordsInLine;

      if (currentWordCount >= wordsPerChunk) {
        final chunkTextContent = currentChunk.toString().trim();
        if (chunkTextContent.isNotEmpty) {
          chunks.add(
            SourceChunkModel(
              chunkId: _uuid.v4(),
              sourceId: sourceId,
              pageNumber: currentPage,
              section: currentSection,
              content: chunkTextContent,
              topic: topic,
            ),
          );
        }
        currentChunk = StringBuffer();
        currentWordCount = 0;
      }
    }

    final leftover = currentChunk.toString().trim();
    if (leftover.isNotEmpty) {
      chunks.add(
        SourceChunkModel(
          chunkId: _uuid.v4(),
          sourceId: sourceId,
          pageNumber: currentPage,
          section: currentSection,
          content: leftover,
          topic: topic,
        ),
      );
    }

    return chunks;
  }
}

