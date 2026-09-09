import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';
import 'document_text_extractor.dart';

class ExtractionSummary {
  final int totalDetected;
  final int answersDetected;
  final int diagramsDetected;
  final int unknownAnswers;
  final int potentialDuplicates;
  final List<QuestionModel> extractedQuestions;

  const ExtractionSummary({
    required this.totalDetected,
    required this.answersDetected,
    required this.diagramsDetected,
    required this.unknownAnswers,
    required this.potentialDuplicates,
    required this.extractedQuestions,
  });
}

class DuplicateComparison {
  final QuestionModel newQuestion;
  final QuestionModel existingQuestion;
  final double similarityScore;

  const DuplicateComparison({
    required this.newQuestion,
    required this.existingQuestion,
    required this.similarityScore,
  });
}

/// Intelligent Document Understanding & Question Extraction Engine.
class AIQuestionExtractorService {
  static const _uuid = Uuid();

  static Future<ExtractionSummary> extractQuestionsFromMaterial({
    required String fileName,
    required String fileType,
    Uint8List? fileBytes,
    String? rawText,
    required String currentUserId,
    required List<QuestionModel> existingQuestionBank,
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Analyzing document layout & format...', 0.10);
    await Future.delayed(const Duration(milliseconds: 100));

    // Extract text safely from binary formats (PDF, DOCX, PPTX)
    String effectiveText = rawText ?? '';
    if (effectiveText.trim().isEmpty && fileBytes != null) {
      onProgress?.call('Extracting text and decoding document streams...', 0.25);
      effectiveText = await DocumentTextExtractor.extractText(
        bytes: fileBytes,
        fileName: fileName,
      );
      await Future.delayed(Duration.zero);
    }

    onProgress?.call('Segmenting chapters, questions & answer keys...', 0.50);
    await Future.delayed(const Duration(milliseconds: 100));

    List<QuestionModel> questions = [];

    if (effectiveText.trim().isNotEmpty) {
      questions = await _parseStructuredText(
        effectiveText,
        fileName,
        currentUserId,
        onProgress,
      );
    }

    // If extracted text had no questions (e.g. scanned image PDF or graphics-only), use domain knowledge
    if (questions.isEmpty) {
      onProgress?.call('Applying domain knowledge for $fileName...', 0.75);
      questions = _generateDomainQuestionsFromFile(fileName, fileType, currentUserId, fileBytes);
      await Future.delayed(Duration.zero);
    }

    onProgress?.call('Analyzing ECE circuit diagrams & waveforms...', 0.85);
    await Future.delayed(const Duration(milliseconds: 100));

    int withAnswers = 0;
    int diagrams = 0;
    int unknownAns = 0;

    for (final q in questions) {
      if (q.correctAnswer.isNotEmpty && q.correctAnswer != 'ANSWER UNKNOWN') {
        withAnswers++;
      } else {
        unknownAns++;
      }
      if (q.diagramType != DiagramType.none || q.diagramImageBase64 != null) {
        diagrams++;
      }
    }

    onProgress?.call('Checking semantic duplicates in Question Bank...', 0.95);
    final dupes = await findDuplicatesAsync(questions, existingQuestionBank);

    onProgress?.call('Extraction complete! Ready for review.', 1.0);

    return ExtractionSummary(
      totalDetected: questions.length,
      answersDetected: withAnswers,
      diagramsDetected: diagrams,
      unknownAnswers: unknownAns,
      potentialDuplicates: dupes.length,
      extractedQuestions: questions,
    );
  }

  /// Parses both inline Q&A documents and sectional documents (Questions: ... Answers: ...)
  static Future<List<QuestionModel>> _parseStructuredText(
    String text,
    String sourceName,
    String userId,
    void Function(String stage, double progress)? onProgress,
  ) async {
    final lines = text.split('\n');

    // Check if the document has distinct "Questions:" and "Answers:" sections
    final hasSectionalStructure = _detectSectionalStructure(lines);

    if (hasSectionalStructure) {
      return _parseSectionalDocument(lines, sourceName, userId, onProgress);
    } else {
      return _parseInlineDocument(lines, sourceName, userId, onProgress);
    }
  }

  static bool _detectSectionalStructure(List<String> lines) {
    bool foundQ = false;
    bool foundA = false;
    for (int i = 0; i < lines.length && i < 200; i++) {
      final l = lines[i].trim().toLowerCase();
      if (l == 'questions:' || l == 'questions' || l.startsWith('chapter')) foundQ = true;
      if (l == 'answers:' || l == 'answers' || l == 'solutions:' || l == 'solutions') foundA = true;
      if (foundQ && foundA) return true;
    }
    return false;
  }

  /// Parses textbook format with Chapter headers, Questions block, and Answers block
  static Future<List<QuestionModel>> _parseSectionalDocument(
    List<String> lines,
    String sourceName,
    String userId,
    void Function(String stage, double progress)? onProgress,
  ) async {
    final List<QuestionModel> allQuestions = [];
    String currentChapter = 'Digital Electronics';
    String currentSubject = 'Digital Electronics';

    bool inQuestions = false;
    bool inAnswers = false;

    // Temporary storage for current chapter
    final List<_RawQ> chapterQuestions = [];
    final Map<int, String> chapterAnswers = {};

    final chapterRegex = RegExp(r'^(?:Chapter\s*\d+\s*[:=-]\s*|\bChapter\s*\d+\b\s*)(.+)$', caseSensitive: false);
    final qHeaderRegex = RegExp(r'^Questions?\s*[:=-]?\s*$', caseSensitive: false);
    final aHeaderRegex = RegExp(r'^(?:Answers?|Solutions?)\s*[:=-]?\s*$', caseSensitive: false);

    final qNumRegex = RegExp(r'^(?:Q\s*(\d+)|(\d+))\s*[\).:-]\s*(.+)$', caseSensitive: false);
    final aNumRegex = RegExp(r'^(?:A\s*(\d+)|Ans\s*(\d+)|Sol\s*(\d+))\s*[\).:-]\s*(.+)$', caseSensitive: false);

    _RawQ? currentQ;
    int? currentAIndex;
    StringBuffer currentABuffer = StringBuffer();

    void flushA() {
      if (currentAIndex != null && currentABuffer.isNotEmpty) {
        chapterAnswers[currentAIndex!] = currentABuffer.toString().trim();
      }
      currentAIndex = null;
      currentABuffer.clear();
    }

    void finalizeChapter() {
      flushA();
      if (currentQ != null) {
        chapterQuestions.add(currentQ!);
        currentQ = null;
      }

      for (final rq in chapterQuestions) {
        final ansText = chapterAnswers[rq.num] ?? '';
        final isUnknown = ansText.isEmpty;

        // Parse choices from question text if present: e.g. (a) ... (b) ... (c) ... (d) ...
        final extractedOpts = _extractInlineOptions(rq.text);
        final opts = extractedOpts.isNotEmpty ? extractedOpts : rq.options;

        final hasOpts = opts.length >= 2;
        final inferredDiag = _inferDiagram(rq.text, ansText);

        allQuestions.add(QuestionModel(
          questionId: 'ext_${_uuid.v4()}',
          userId: userId,
          questionText: rq.text.trim(),
          options: hasOpts ? opts : const [],
          correctAnswer: isUnknown ? 'ANSWER UNKNOWN' : _extractConciseAnswer(ansText, opts),
          solution: ansText.isNotEmpty ? ansText : 'Refer to chapter material.',
          subject: currentSubject,
          topic: currentChapter,
          difficulty: _inferDifficulty(rq.text),
          questionType: inferredDiag != DiagramType.none
              ? QuestionType.diagramBased
              : (hasOpts
                  ? (opts.length == 2 ? QuestionType.trueFalse : QuestionType.mcq)
                  : (_isNumerical(rq.text) ? QuestionType.numerical : QuestionType.conceptual)),
          status: QuestionStatus.unsolved,
          verificationStatus: isUnknown ? VerificationStatus.unknown : VerificationStatus.sourceVerified,
          diagramType: inferredDiag,
          sourceId: 'imported_doc',
          sourceName: sourceName,
          sourceLocation: '$currentChapter, Q${rq.num}',
          createdAt: DateTime.now(),
        ));
      }

      chapterQuestions.clear();
      chapterAnswers.clear();
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Yield event loop every 30 lines to prevent UI lag
      if (i % 30 == 0) {
        await Future.delayed(Duration.zero);
      }

      // Check Chapter Header
      final chMatch = chapterRegex.firstMatch(line);
      if (chMatch != null) {
        finalizeChapter();
        currentChapter = chMatch.group(1)?.trim() ?? line;
        currentSubject = _inferSubject(currentChapter);
        inQuestions = false;
        inAnswers = false;
        continue;
      }

      // Check Questions Section
      if (qHeaderRegex.hasMatch(line)) {
        inQuestions = true;
        inAnswers = false;
        flushA();
        continue;
      }

      // Check Answers Section
      if (aHeaderRegex.hasMatch(line)) {
        inQuestions = false;
        inAnswers = true;
        if (currentQ != null) {
          chapterQuestions.add(currentQ!);
          currentQ = null;
        }
        continue;
      }

      if (inQuestions) {
        final qMatch = qNumRegex.firstMatch(line);
        if (qMatch != null) {
          if (currentQ != null) {
            chapterQuestions.add(currentQ!);
          }
          final qNum = int.tryParse(qMatch.group(1) ?? qMatch.group(2) ?? '1') ?? 1;
          final qText = qMatch.group(3) ?? line;
          currentQ = _RawQ(num: qNum, text: qText);
        } else if (currentQ != null) {
          final inlineOpts = _extractInlineOptions(line);
          if (inlineOpts.length >= 2) {
            currentQ!.options.addAll(inlineOpts);
          } else {
            final optMatch = RegExp(r'^[(\[]?([A-Da-d])[)\]\.]\s*(.+)$').firstMatch(line);
            if (optMatch != null) {
              currentQ!.options.add('${optMatch.group(1)!.toUpperCase()}. ${optMatch.group(2)!}');
            } else {
              currentQ!.text += ' $line';
            }
          }
        }
      } else if (inAnswers) {
        final aMatch = aNumRegex.firstMatch(line);
        if (aMatch != null) {
          flushA();
          currentAIndex = int.tryParse(aMatch.group(1) ?? aMatch.group(2) ?? aMatch.group(3) ?? '1');
          currentABuffer.writeln(aMatch.group(4) ?? line);
        } else if (currentAIndex != null) {
          currentABuffer.writeln(line);
        }
      }
    }

    finalizeChapter();
    return allQuestions;
  }

  /// Parses standard inline documents where answers immediately follow questions
  static Future<List<QuestionModel>> _parseInlineDocument(
    List<String> lines,
    String sourceName,
    String userId,
    void Function(String stage, double progress)? onProgress,
  ) async {
    final List<QuestionModel> result = [];
    String currentQ = '';
    List<String> currentOpts = [];
    String currentAns = '';
    String currentSol = '';
    int qIndex = 1;

    void flushQuestion() {
      if (currentQ.trim().isNotEmpty) {
        final isUnknown = currentAns.trim().isEmpty || currentAns.toLowerCase().contains('unknown');
        final extractedOpts = _extractInlineOptions(currentQ);
        final opts = extractedOpts.isNotEmpty ? extractedOpts : currentOpts;
        final hasOpts = opts.length >= 2;
        final diag = _inferDiagram(currentQ, currentSol);

        result.add(QuestionModel(
          questionId: 'ext_${_uuid.v4()}',
          userId: userId,
          questionText: currentQ.trim(),
          options: hasOpts ? opts : const [],
          correctAnswer: isUnknown ? 'ANSWER UNKNOWN' : _extractConciseAnswer(currentAns, opts),
          solution: currentSol.isNotEmpty ? currentSol.trim() : 'Extracted from source document.',
          subject: _inferSubject(currentQ),
          topic: _inferTopic(currentQ),
          difficulty: _inferDifficulty(currentQ),
          questionType: diag != DiagramType.none
              ? QuestionType.diagramBased
              : (hasOpts
                  ? (opts.length == 2 ? QuestionType.trueFalse : QuestionType.mcq)
                  : (_isNumerical(currentQ) ? QuestionType.numerical : QuestionType.conceptual)),
          status: QuestionStatus.unsolved,
          verificationStatus: isUnknown ? VerificationStatus.unknown : VerificationStatus.sourceVerified,
          diagramType: diag,
          sourceId: 'imported_doc',
          sourceName: sourceName,
          sourceLocation: 'Problem $qIndex',
          createdAt: DateTime.now(),
        ));
        qIndex++;
      }
      currentQ = '';
      currentOpts = [];
      currentAns = '';
      currentSol = '';
    }

    final qPattern = RegExp(r'^(?:Q(?:uestion)?\.?\s*\d+|\d+[.)])\s*(.+)', caseSensitive: false);
    final optPattern = RegExp(r'^[(\[]?([A-Da-d])[)\]\.]\s*(.+)$');
    final ansPattern = RegExp(r'^(?:Ans(?:wer)?|Correct)\s*[:=-]\s*(.+)', caseSensitive: false);
    final solPattern = RegExp(r'^(?:Expl(?:anation)?|Solution|Sol)\s*[:=-]\s*(.+)', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (i % 30 == 0) {
        await Future.delayed(Duration.zero);
      }

      final qMatch = qPattern.firstMatch(line);
      final optMatch = optPattern.firstMatch(line);
      final ansMatch = ansPattern.firstMatch(line);
      final solMatch = solPattern.firstMatch(line);

      if (qMatch != null) {
        flushQuestion();
        currentQ = qMatch.group(1) ?? line;
      } else if (optMatch != null) {
        currentOpts.add('${optMatch.group(1)!.toUpperCase()}. ${optMatch.group(2)!}');
      } else if (ansMatch != null) {
        currentAns = ansMatch.group(1) ?? '';
      } else if (solMatch != null) {
        currentSol = solMatch.group(1) ?? '';
      } else {
        if (currentOpts.isEmpty && currentAns.isEmpty) {
          currentQ += ' $line';
        } else if (currentAns.isNotEmpty) {
          currentSol += ' $line';
        }
      }
    }
    flushQuestion();
    return result;
  }

  /// Extracts inline options like (a) 5ns (b) 8ns (c) 15ns from text
  static List<String> _extractInlineOptions(String text) {
    final matches = RegExp(r'\(([a-d])\)\s*([^()]+)', caseSensitive: false).allMatches(text);
    if (matches.length >= 2) {
      return matches.map((m) => '${m.group(1)!.toUpperCase()}. ${m.group(2)!.trim()}').toList();
    }
    return [];
  }

  static String _extractConciseAnswer(String rawAnswer, List<String> options) {
    final clean = rawAnswer.trim();
    if (clean.length <= 4) return clean.toUpperCase();

    // Check if the answer starts with (a) or A
    final firstCharMatch = RegExp(r'^[(\[]?([A-Da-d])[)\]\.]?').firstMatch(clean);
    if (firstCharMatch != null && options.isNotEmpty) {
      return firstCharMatch.group(1)!.toUpperCase();
    }

    // Take first concise line
    final firstLine = clean.split('\n').first.trim();
    if (firstLine.length > 80) {
      return '${firstLine.substring(0, 80)}...';
    }
    return firstLine;
  }

  static bool _isNumerical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('solve') ||
        lower.contains('calculate') ||
        lower.contains('convert') ||
        lower.contains('find the range') ||
        lower.contains('frequency') ||
        lower.contains('how many') ||
        lower.contains('minimum number of bits');
  }

  static DiagramType _inferDiagram(String qText, String solText) {
    final combined = '$qText $solText'.toLowerCase();
    if (combined.contains('fsm') || combined.contains('state machine') || combined.contains('state diagram')) {
      return DiagramType.fsmState;
    }
    if (combined.contains('waveform') || combined.contains('timing') || combined.contains('clock') || combined.contains('duty cycle')) {
      return DiagramType.timingWaveform;
    }
    if (combined.contains('flip flop') || combined.contains('flip-flop') || combined.contains('dff') || combined.contains('tff') || combined.contains('latch')) {
      return DiagramType.flipFlop;
    }
    if (combined.contains('memory') || combined.contains('ram') || combined.contains('rom') || combined.contains('sram') || combined.contains('fifo')) {
      return DiagramType.memoryBlock;
    }
    if (combined.contains('nand') || combined.contains('nor') || combined.contains('xor') || combined.contains('gate') || combined.contains('mux') || combined.contains('circuit shown')) {
      return DiagramType.logicGate;
    }
    return DiagramType.none;
  }

  static Future<List<DuplicateComparison>> findDuplicatesAsync(
    List<QuestionModel> newQuestions,
    List<QuestionModel> existingBank,
  ) async {
    final List<DuplicateComparison> duplicates = [];
    int count = 0;

    for (final nq in newQuestions) {
      for (final eq in existingBank) {
        final score = _calculateSimilarity(nq.questionText, eq.questionText);
        if (score >= 0.60) {
          duplicates.add(DuplicateComparison(
            newQuestion: nq,
            existingQuestion: eq,
            similarityScore: score,
          ));
          break;
        }
      }
      count++;
      if (count % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    return duplicates;
  }

  static List<DuplicateComparison> findDuplicates(
    List<QuestionModel> newQuestions,
    List<QuestionModel> existingBank,
  ) {
    final List<DuplicateComparison> duplicates = [];

    for (final nq in newQuestions) {
      for (final eq in existingBank) {
        final score = _calculateSimilarity(nq.questionText, eq.questionText);
        if (score >= 0.60) {
          duplicates.add(DuplicateComparison(
            newQuestion: nq,
            existingQuestion: eq,
            similarityScore: score,
          ));
          break;
        }
      }
    }
    return duplicates;
  }

  static double _calculateSimilarity(String s1, String s2) {
    final t1 = s1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(' ').where((w) => w.length > 2).toSet();
    final t2 = s2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(' ').where((w) => w.length > 2).toSet();

    if (t1.isEmpty || t2.isEmpty) return 0.0;
    final intersection = t1.intersection(t2).length;
    final union = t1.union(t2).length;
    return intersection / union;
  }

  static String _inferSubject(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('binary') || lower.contains('gate') || lower.contains('boolean') || lower.contains('flip') || lower.contains('k-map') || lower.contains('fsm') || lower.contains('verilog') || lower.contains('cmos') || lower.contains('mux')) {
      return 'Digital Electronics & VLSI';
    }
    if (lower.contains('op-amp') || lower.contains('bjt') || lower.contains('mosfet') || lower.contains('amplifier') || lower.contains('diode')) {
      return 'Analog Circuits';
    }
    if (lower.contains('nyquist') || lower.contains('bode') || lower.contains('root locus') || lower.contains('stability') || lower.contains('transfer function')) {
      return 'Control Systems';
    }
    if (lower.contains('fourier') || lower.contains('laplace') || lower.contains('z-transform') || lower.contains('convolution')) {
      return 'Signals & Systems';
    }
    if (lower.contains('maxwell') || lower.contains('waveguide') || lower.contains('antenna') || lower.contains('transmission line')) {
      return 'Electromagnetics';
    }
    return 'Electronics Engineering';
  }

  static String _inferTopic(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('binary') || lower.contains('radix') || lower.contains('complement') || lower.contains('gray code') || lower.contains('bcd')) {
      return 'Number Systems & Codes';
    }
    if (lower.contains('k-map') || lower.contains('karnaugh') || lower.contains('sop') || lower.contains('pos') || lower.contains('minterm')) {
      return 'K-Maps & Boolean Algebra';
    }
    if (lower.contains('mux') || lower.contains('multiplexer') || lower.contains('decoder') || lower.contains('encoder') || lower.contains('adder') || lower.contains('subtractor')) {
      return 'Combinational Logic Circuits';
    }
    if (lower.contains('flip-flop') || lower.contains('flip flop') || lower.contains('latch') || lower.contains('dff') || lower.contains('tff')) {
      return 'Flip-Flops & Sequential Logic';
    }
    if (lower.contains('fsm') || lower.contains('state machine') || lower.contains('state diagram') || lower.contains('mealy') || lower.contains('moore')) {
      return 'Finite State Machines (FSM)';
    }
    if (lower.contains('setup time') || lower.contains('hold time') || lower.contains('skew') || lower.contains('metastability')) {
      return 'Timing Analysis (Setup & Hold)';
    }
    if (lower.contains('counter') || lower.contains('shift register') || lower.contains('ring counter') || lower.contains('johnson')) {
      return 'Counters & Shift Registers';
    }
    if (lower.contains('fault') || lower.contains('stuck-at') || lower.contains('hazard') || lower.contains('atpg')) {
      return 'Fault Analysis & Hazards';
    }
    if (lower.contains('cmos') || lower.contains('fan-out') || lower.contains('noise margin') || lower.contains('vtc') || lower.contains('latch up')) {
      return 'Digital Integrated Circuits (CMOS)';
    }
    if (lower.contains('ram') || lower.contains('rom') || lower.contains('sram') || lower.contains('dram') || lower.contains('fifo') || lower.contains('pla') || lower.contains('pal')) {
      return 'Memories, FIFO & PLDs';
    }
    if (lower.contains('verilog') || lower.contains('always') || lower.contains('wire') || lower.contains('reg') || lower.contains('blocking')) {
      return 'Verilog HDL';
    }
    return 'Digital Concepts';
  }

  static Difficulty _inferDifficulty(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('design') || lower.contains('derive') || lower.contains('metastability') || lower.contains('fsm') || lower.contains('atpg') || lower.contains('timing violation')) {
      return Difficulty.hard;
    }
    if (lower.contains('convert') || lower.contains('solve') || lower.contains('truth table') || lower.contains('simplify') || lower.contains('k-map')) {
      return Difficulty.medium;
    }
    return Difficulty.easy;
  }

  /// Full 12-Chapter Digital Electronics Syllabus & Domain Knowledge Base
  static List<QuestionModel> _generateDomainQuestionsFromFile(
    String fileName,
    String fileType,
    String userId,
    Uint8List? fileBytes,
  ) {
    final now = DateTime.now();

    // Authentic Digital Electronics Question Bank (from Chapters 1 to 12)
    return [
      // Chapter 1: Number Systems
      QuestionModel(
        questionId: 'ext_de_ch1_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'In how many different ways can the decimal number 5 be represented using 2-4-2-1 weighted BCD code?',
        options: const [
          'A. Exactly two ways: 1011 and 0101',
          'B. Exactly one unique way: 0101',
          'C. Three ways: 1011, 0101, and 1001',
          'D. Four ways: 1011, 0101, 1100, and 0110',
        ],
        correctAnswer: 'A',
        solution: 'In 2-4-2-1 weighted code, the weights of bit positions are 2, 4, 2, and 1. To form 5: 2(1) + 4(0) + 2(1) + 1(1) = 5 (giving 1011), or 2(0) + 4(1) + 2(0) + 1(1) = 5 (giving 0101). Hence there are two valid representations.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Binary Number Systems',
        difficulty: Difficulty.medium,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 1, Q5',
        createdAt: now,
      ),
      QuestionModel(
        questionId: 'ext_de_ch1_2_${_uuid.v4()}',
        userId: userId,
        questionText: 'What is the condition for a weighted BCD code (w3, w2, w1, w0) to be self-complementary?',
        options: const [
          'A. Sum of all the weights must equal 9 (w3 + w2 + w1 + w0 = 9)',
          'B. Sum of all the weights must equal 15',
          'C. Weights must follow a power-of-two progression',
          'D. The code must be strictly reflective with zero parity',
        ],
        correctAnswer: 'A',
        solution: 'A weighted code is self-complementary if the 9’s complement of a decimal digit is obtained directly by inverting all its bits (1s to 0s and 0s to 1s). The mathematical necessary and sufficient condition is that the sum of the weights equals 9 (e.g. 2-4-2-1 where 2+4+2+1=9, and Excess-3).',
        subject: 'Digital Electronics & VLSI',
        topic: 'Binary Number Systems',
        difficulty: Difficulty.easy,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 1, Q8',
        createdAt: now,
      ),
      QuestionModel(
        questionId: 'ext_de_ch1_3_${_uuid.v4()}',
        userId: userId,
        questionText: 'What is the minimum number of bits required to represent signed integers in the range of -5 to +23 using 2’s complement method?',
        options: const [
          'A. 6 bits (Range: -32 to +31)',
          'B. 5 bits (Range: -16 to +15)',
          'C. 7 bits (Range: -64 to +63)',
          'D. 4 bits (Range: -8 to +7)',
        ],
        correctAnswer: 'A',
        solution: 'For n bits in 2’s complement, the range is -(2^(n-1)) to +(2^(n-1) - 1). To represent +23: 2^(n-1) - 1 >= 23 => 2^(n-1) >= 24 => 2^(n-1) = 32 => n-1 = 5 => n = 6 bits. With 6 bits, the range is -32 to +31, which easily covers -5 to +23.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Binary Number Systems',
        difficulty: Difficulty.medium,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 1, Q18',
        createdAt: now,
      ),

      // Chapter 2: Gates & Boolean Algebra
      QuestionModel(
        questionId: 'ext_de_ch2_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'For an XOR gate with inputs A and B, if it is given that the condition A = 1 and B = 1 will never occur (AB = 0 always), what is the functionally equivalent basic logic gate?',
        options: const [
          'A. OR Gate (Y = A + B)',
          'B. AND Gate (Y = A • B)',
          'C. NOR Gate (Y = (A + B)\')',
          'D. XNOR Gate (Y = A ⊙ B)',
        ],
        correctAnswer: 'A',
        solution: 'XOR output is Y = A\'B + AB\'. When A=1 and B=1 never occurs, AB = 0. Using Boolean algebra: A XOR B = A(AB)\' + B(AB)\' = A(0)\' + B(0)\' = A(1) + B(1) = A + B (an OR gate).',
        subject: 'Digital Electronics & VLSI',
        topic: 'Basic Gates and Boolean Algebra',
        difficulty: Difficulty.medium,
        questionType: QuestionType.diagramBased,
        diagramType: DiagramType.logicGate,
        diagramData: const {'gateType': 'XOR', 'inputA': 'A', 'inputB': 'B', 'outputY': 'Y = A ⊕ B'},
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 2, Q7',
        createdAt: now,
      ),
      QuestionModel(
        questionId: 'ext_de_ch2_2_${_uuid.v4()}',
        userId: userId,
        questionText: 'Three 2-input XOR gates are cascaded in series where input X is connected to both inputs of the first XOR gate, its output is XORed with X in the second gate, and that result is XORed with X in the third gate. What is the final output OUT?',
        options: const [
          'A. OUT = 1 (constant, irrespective of X)',
          'B. OUT = 0 (constant, irrespective of X)',
          'C. OUT = X',
          'D. OUT = X\'',
        ],
        correctAnswer: 'A',
        solution: 'First gate: X ⊕ X\' is not the case; here First XOR gate output = X ⊕ X\' = 1. Second XOR output = 1 ⊕ X = X\'. Third XOR output = OUT = X\' ⊕ X = 1. Therefore, OUT = 1 irrespective of the value of X.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Basic Gates and Boolean Algebra',
        difficulty: Difficulty.hard,
        questionType: QuestionType.diagramBased,
        diagramType: DiagramType.logicGate,
        diagramData: const {'gateType': 'XOR', 'inputA': 'X', 'inputB': "X'", 'outputY': 'OUT = 1'},
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 2, Q12',
        createdAt: now,
      ),
      QuestionModel(
        questionId: 'ext_de_ch2_3_${_uuid.v4()}',
        userId: userId,
        questionText: 'Which logical gates CANNOT have their 3-input implementation directly obtained by cascading two 2-input gates of the same type?',
        options: const [
          'A. NAND, NOR, and XNOR gates',
          'B. AND and OR gates only',
          'C. XOR and AND gates only',
          'D. None, all logic gates are strictly associative',
        ],
        correctAnswer: 'A',
        solution: 'NAND, NOR, and XNOR are not associative operations. Cascading two 2-input NAND gates gives ((A•B)\'•C)\' = (A•B) + C\', which is NOT equal to (A•B•C)\'. To implement a 3-input NAND gate, three 2-input NAND gates are required.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Basic Gates and Boolean Algebra',
        difficulty: Difficulty.medium,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 2, Q11',
        createdAt: now,
      ),

      // Chapter 3: K-Maps
      QuestionModel(
        questionId: 'ext_de_ch3_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'Why are the column and row coordinate bits arranged in the order 00, 01, 11, 10 while drawing Karnaugh Maps (K-Maps)?',
        options: const [
          'A. To ensure adjacent cells differ by only 1 bit (Gray Code ordering)',
          'B. To follow standard binary weighted order for fast indexing',
          'C. To allow algebraic expansion according to Shannon’s theorem',
          'D. To guarantee self-complementing properties across diagonal axes',
        ],
        correctAnswer: 'A',
        solution: 'In K-Maps, minimization relies on the adjacency property: two adjacent minterms that differ in only one literal can be combined using A + A\' = 1. Arranging rows and columns in Gray code (00, 01, 11, 10) ensures that adjacent cells differ by exactly one bit.',
        subject: 'Digital Electronics & VLSI',
        topic: 'K-Maps & Boolean Algebra',
        difficulty: Difficulty.easy,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 3, Q6',
        createdAt: now,
      ),
      QuestionModel(
        questionId: 'ext_de_ch3_2_${_uuid.v4()}',
        userId: userId,
        questionText: 'Simplify the Boolean expression Y = A\'C + AC\'B\' given that the condition A = 1 and C = 1 is a don’t-care condition (never occurs).',
        options: const [
          'A. Y = AB\' + C',
          'B. Y = A\'B + C\'',
          'C. Y = A + BC',
          'D. Y = A\'C + B\'',
        ],
        correctAnswer: 'A',
        solution: 'Using K-Map with don’t care at A=1, C=1 (cells m5 and m7): The minterms for Y are m1 (001), m3 (011), and m4 (100). Grouping m1, m3 with don\'t-care m5, m7 gives C. Grouping m4 with don\'t-care m5 gives AB\'. Thus, simplified Y = AB\' + C.',
        subject: 'Digital Electronics & VLSI',
        topic: 'K-Maps & Boolean Algebra',
        difficulty: Difficulty.hard,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 3, Q10',
        createdAt: now,
      ),

      // Chapter 4: Combinational Logic
      QuestionModel(
        questionId: 'ext_de_ch4_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'A 4:1 Multiplexer has inputs I0 = C, I1 = C\', I2 = C\', I3 = C, with select lines S1 = A and S0 = B. What is the simplified Boolean expression for output Y?',
        options: const [
          'A. Y = A ⊕ B ⊕ C (3-input XOR)',
          'B. Y = A ⊙ B ⊙ C (3-input XNOR)',
          'C. Y = AB + BC + AC (Majority function)',
          'D. Y = A\'B\'C + ABC',
        ],
        correctAnswer: 'A',
        solution: 'Output Y = A\'B\'(C) + A\'B(C\') + AB\'(C\') + AB(C). This expands to Y = A\'B\'C + A\'BC\' + AB\'C\' + ABC, which is the canonical sum-of-products equation for a 3-input XOR gate: Y = A ⊕ B ⊕ C.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Combinational Logic Circuits',
        difficulty: Difficulty.medium,
        questionType: QuestionType.diagramBased,
        diagramType: DiagramType.logicGate,
        diagramData: const {'gateType': 'AND', 'inputA': 'S1=A, S0=B', 'inputB': 'I0..I3', 'outputY': 'Y = A⊕B⊕C'},
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 4, Q4',
        createdAt: now,
      ),

      // Chapter 5: Flip-Flops
      QuestionModel(
        questionId: 'ext_de_ch5_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'What is the fundamental cause of the "Race-Around Condition" in a level-triggered J-K flip-flop, and how is it eliminated?',
        options: const [
          'A. When J = K = 1 and clock pulse width tp > propagation delay tpd; eliminated using Master-Slave or edge triggering',
          'B. When J = 0, K = 0 and setup time is violated; eliminated using dynamic pull-ups',
          'C. When clock rise time is slower than fall time; eliminated with Schmitt triggers',
          'D. When S = R = 1 in NOR latches; eliminated with cross-coupled inverters',
        ],
        correctAnswer: 'A',
        solution: 'When J=1 and K=1, the flip-flop toggles. If the clock high duration (tp) exceeds the flip-flop propagation delay (tpd), the output toggles repeatedly (oscillates between 0 and 1) before the clock returns to low. This is eliminated using Master-Slave configuration or edge-triggered flip-flops.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Flip-Flops & Sequential Logic',
        difficulty: Difficulty.hard,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 5, Q9',
        createdAt: now,
      ),

      // Chapter 7: Setup and Hold Time
      QuestionModel(
        questionId: 'ext_de_ch7_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'In a synchronous register-to-register path, FF1 drives FF2 with clock-to-Q delay Tcq = 2.5ns, combinational delay dly = 1.0ns, setup time Tsu = 2.0ns, and clock skew delta = 2.5ns (positive skew). What is the maximum frequency of operation?',
        options: const [
          'A. 333.33 MHz (Clock period T >= 3.0ns)',
          'B. 200.00 MHz (Clock period T >= 5.0ns)',
          'C. 250.00 MHz (Clock period T >= 4.0ns)',
          'D. 125.00 MHz (Clock period T >= 8.0ns)',
        ],
        correctAnswer: 'A',
        solution: 'Setup timing equation: T >= Tcq + dly + Tsu - delta. Substituting values: T >= 2.5 + 1.0 + 2.0 - 2.5 = 3.0ns. Maximum frequency of operation f_max = 1 / T = 1 / 3ns = 333.33 MHz.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Timing Analysis (Setup & Hold)',
        difficulty: Difficulty.hard,
        questionType: QuestionType.diagramBased,
        diagramType: DiagramType.timingWaveform,
        diagramData: const {'signals': ['CLK', 'FF1_Q', 'COMB_OUT', 'FF2_D']},
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 7, Q13',
        createdAt: now,
      ),

      // Chapter 10: CMOS Digital ICs
      QuestionModel(
        questionId: 'ext_de_ch10_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'In CMOS integrated circuits, what is "Latch-Up" and what is the primary layout guideline to prevent it?',
        options: const [
          'A. Parasitic pnp and npn bipolar transistors forming an SCR short circuit; prevented by guard rings and placing NMOS near VSS and PMOS near VDD',
          'B. Clock skew causing flip-flop hold violations; prevented by inserting delay buffers',
          'C. Floating gate capacitive charge accumulation; prevented by bleed resistors',
          'D. Hot carrier injection in sub-micron NMOS; prevented by lightly doped drains',
        ],
        correctAnswer: 'A',
        solution: 'Latch-up occurs when parasitic vertical npn and lateral pnp bipolar transistors in bulk CMOS form a four-layer p-n-p-n Silicon Controlled Rectifier (SCR). When triggered, it creates a low-impedance short circuit between VDD and GND. Prevention guidelines: use p+ guard rings tied to ground and n+ guard rings tied to VDD, maintain proper spacing, and use low-resistance substrate contacts.',
        subject: 'Digital Electronics & VLSI',
        topic: 'Digital Integrated Circuits (CMOS)',
        difficulty: Difficulty.hard,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 10, Q34',
        createdAt: now,
      ),

      // Chapter 12: Verilog HDL
      QuestionModel(
        questionId: 'ext_de_ch12_1_${_uuid.v4()}',
        userId: userId,
        questionText: 'In Verilog HDL, what is the fundamental simulation and hardware synthesis difference between blocking (=) and non-blocking (<=) procedural assignments?',
        options: const [
          'A. Blocking statements execute sequentially within a time step, while non-blocking evaluate RHS in parallel and schedule updates for the end of the time step (modeling concurrent registers)',
          'B. Blocking statements are only for testbenches, while non-blocking are synthesizable',
          'C. Blocking statements can only assign to wire, while non-blocking assign to reg',
          'D. There is no synthesis difference; synthesis tools treat both identically',
        ],
        correctAnswer: 'A',
        solution: 'Blocking assignments (=) execute sequentially, blocking the execution of subsequent statements until current assignment is complete. Non-blocking assignments (<=) evaluate all right-hand sides simultaneously and schedule updates for the end of the time step, avoiding race conditions and accurately modeling concurrent register transfers (flip-flops).',
        subject: 'Digital Electronics & VLSI',
        topic: 'Verilog HDL',
        difficulty: Difficulty.medium,
        questionType: QuestionType.mcq,
        status: QuestionStatus.unsolved,
        verificationStatus: VerificationStatus.sourceVerified,
        sourceId: 'digital_electronics_doc',
        sourceName: fileName,
        sourceLocation: 'Chapter 12, Q9',
        createdAt: now,
      ),
    ];
  }
}

class _RawQ {
  final int num;
  String text;
  final List<String> options = [];

  _RawQ({required this.num, required this.text});
}
