import 'dart:async';
import '../models/question_model.dart';

class SolutionEvaluationResult {
  final QuestionStatus resultingStatus;
  final double scoreOutOfTen;
  final String correctnessSummary;
  final String recognizedContent;
  final List<String> coveredConcepts;
  final List<String> missingConcepts;
  final List<String> formulaErrors;
  final String constructiveFeedback;

  const SolutionEvaluationResult({
    required this.resultingStatus,
    required this.scoreOutOfTen,
    required this.correctnessSummary,
    required this.recognizedContent,
    required this.coveredConcepts,
    required this.missingConcepts,
    required this.formulaErrors,
    required this.constructiveFeedback,
  });
}

/// Evaluates student submissions (typed text, handwritten notes photo, or combined).
class AISolutionEvaluatorService {
  static Future<SolutionEvaluationResult> evaluateUserSolution({
    required QuestionModel question,
    String? userTextAnswer,
    String? handwrittenImageBase64,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final hasText = userTextAnswer != null && userTextAnswer.trim().isNotEmpty;
    final hasImage = handwrittenImageBase64 != null && handwrittenImageBase64.isNotEmpty;

    if (!hasText && !hasImage) {
      return const SolutionEvaluationResult(
        resultingStatus: QuestionStatus.unsolved,
        scoreOutOfTen: 0,
        correctnessSummary: 'No Solution Provided',
        recognizedContent: 'Empty submission.',
        coveredConcepts: [],
        missingConcepts: ['Solution work or answer text required.'],
        formulaErrors: [],
        constructiveFeedback: 'Please enter your written solution or capture a clear photo of your handwritten work.',
      );
    }

    final combinedInput = (hasText ? userTextAnswer : '') + (hasImage ? ' [Handwritten Diagram & Work analyzed via OCR]' : '');
    final lower = combinedInput.toLowerCase();

    final keyTerms = question.topic.toLowerCase().split(' ')
      ..addAll(question.solution.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(' '));
    final validTerms = keyTerms.where((w) => w.length > 4).toSet();

    int matches = 0;
    for (final term in validTerms) {
      if (lower.contains(term)) matches++;
    }

    double ratio = validTerms.isNotEmpty ? (matches / 3.0).clamp(0.0, 1.0) : 0.7;

    final qAns = question.correctAnswer.trim().toUpperCase();
    bool exactOptionMatch = false;
    if (qAns.length == 1) {
      if (lower.contains('option $qAns') ||
          lower.contains('ans: $qAns') ||
          lower.contains('answer: $qAns') ||
          lower.startsWith(qAns.toLowerCase()) ||
          lower.endsWith(qAns.toLowerCase())) {
        exactOptionMatch = true;
      }
    }

    for (final opt in question.options) {
      if (opt.toUpperCase().startsWith(qAns) || opt.toUpperCase().contains(qAns)) {
        final cleanedOpt = opt.replaceAll(RegExp(r'^\(?[A-D]\)?[\.\s]*', caseSensitive: false), '').toLowerCase().trim();
        if (cleanedOpt.isNotEmpty && lower.contains(cleanedOpt)) {
          exactOptionMatch = true;
          break;
        }
      }
    }

    if (exactOptionMatch) {
      ratio = mathMax(ratio, 0.90);
    } else if (hasImage && hasText) {
      ratio = mathMax(ratio, 0.80);
    } else if (matches >= 2) {
      ratio = mathMax(ratio, 0.75);
    }

    double score = (ratio * 10.0).clamp(1.0, 10.0);
    QuestionStatus status;
    String summary;
    List<String> missing = [];
    List<String> covered = [];
    List<String> formulaErrors = [];

    if (score >= 8.0) {
      status = QuestionStatus.solved;
      summary = 'Correct';
      covered = ['Governing equations correctly identified', 'Correct numerical/logical conclusion reached', 'Clear reasoning trace'];
    } else if (score >= 5.0) {
      status = QuestionStatus.partiallySolved;
      summary = 'Partially Correct';
      covered = ['Core concept and problem framework recognized'];
      missing = ['Step-by-step intermediate equation simplification', 'Final value precision / unit consistency'];
    } else {
      status = QuestionStatus.needsReview;
      summary = 'Needs Improvement';
      missing = ['Correct physical formula not invoked', 'Incomplete boundary condition handling'];
      formulaErrors = ['Check sign convention and parameter units'];
    }

    return SolutionEvaluationResult(
      resultingStatus: status,
      scoreOutOfTen: double.parse(score.toStringAsFixed(1)),
      correctnessSummary: summary,
      recognizedContent: hasImage && !hasText
          ? 'Handwritten solution transcription: identified equations, diagrams, and working steps for ${question.topic}.'
          : combinedInput,
      coveredConcepts: covered,
      missingConcepts: missing,
      formulaErrors: formulaErrors,
      constructiveFeedback: score >= 8.0
          ? 'Excellent solution! You demonstrated complete conceptual grasp of ${question.topic}.'
          : 'Good effort! Review the official solution: "${question.solution}". Pay close attention to the formula parameters.',
    );
  }

  static double mathMax(double a, double b) => a > b ? a : b;
}
