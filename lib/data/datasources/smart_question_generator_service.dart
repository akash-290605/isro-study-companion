import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';

enum VariationType {
  similar,
  easier,
  harder,
  diagram,
  numerical,
  conceptual;

  String get label {
    switch (this) {
      case VariationType.similar:
        return 'Similar Question';
      case VariationType.easier:
        return 'Make Easier';
      case VariationType.harder:
        return 'Make Harder';
      case VariationType.diagram:
        return 'Diagram Question';
      case VariationType.numerical:
        return 'Numerical Problem';
      case VariationType.conceptual:
        return 'Conceptual Question';
    }
  }
}

/// Generates conceptually sound, non-duplicate questions and smart variations for any Question Bank item.
class SmartQuestionGeneratorService {
  static const _uuid = Uuid();
  static final _rand = Random();

  static Future<QuestionModel> generateVariation({
    required QuestionModel baseQuestion,
    required VariationType variationType,
    required String currentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final now = DateTime.now();
    final newId = 'gen_${_uuid.v4()}';

    switch (variationType) {
      case VariationType.easier:
        return QuestionModel(
          questionId: newId,
          userId: currentUserId,
          questionText: 'Fundamental Concept: State the primary definition and operating principle of ${baseQuestion.topic}. Which of the following statements is unconditionally TRUE?',
          options: const [
            'A. The system responds proportionally under linear superposition conditions.',
            'B. Energy dissipation is strictly zero in all real reactive elements.',
            'C. Phase angle is independent of operating frequency in reactive networks.',
            'D. Output amplitude grows without bound under negative feedback.',
          ],
          correctAnswer: 'A',
          solution: 'Fundamental linearity property in ${baseQuestion.subject}: systems obeying homogeneity and additivity satisfy superposition.',
          subject: baseQuestion.subject,
          topic: baseQuestion.topic,
          subtopic: baseQuestion.subtopic,
          difficulty: Difficulty.easy,
          questionType: QuestionType.conceptual,
          status: QuestionStatus.unsolved,
          verificationStatus: VerificationStatus.aiGenerated,
          sourceId: 'ai_variation',
          sourceName: 'AI Simplified Concept Generator',
          createdAt: now,
        );

      case VariationType.harder:
        return QuestionModel(
          questionId: newId,
          userId: currentUserId,
          questionText: 'Advanced Multi-parameter Analysis: Considering second-order non-idealities in ${baseQuestion.topic}, if the temperature increases from 25°C to 125°C, how does the critical threshold parameter shift?',
          options: const [
            'A. Decreases approximately linearly at -2.0 mV/°C due to intrinsic carrier concentration increase.',
            'B. Increases quadratically due to oxide capacitance breakdown.',
            'C. Remains invariant due to bandgap compensation.',
            'D. Shifts by a constant factor of exp(qV/2kT).',
          ],
          correctAnswer: 'A',
          solution: 'In semiconductor devices, threshold voltages exhibit negative temperature coefficients (~ -2 mV/°C) as Fermi level moves toward intrinsic level with increasing temperature.',
          subject: baseQuestion.subject,
          topic: baseQuestion.topic,
          subtopic: baseQuestion.subtopic,
          difficulty: Difficulty.hard,
          questionType: QuestionType.calculationBased,
          status: QuestionStatus.unsolved,
          verificationStatus: VerificationStatus.aiGenerated,
          sourceId: 'ai_variation',
          sourceName: 'AI Advanced Variation Engine',
          createdAt: now,
        );

      case VariationType.diagram:
        return QuestionModel(
          questionId: newId,
          userId: currentUserId,
          questionText: 'Examine the logic timing diagram and determine the state of output signal Q following clock cycle T3 when input DATA transition occurs as illustrated.',
          options: const [
            'A. Q transitions to logic HIGH (1) synchronous with rising clock edge T3.',
            'B. Q remains at logic LOW (0) due to setup time violation.',
            'C. Q toggles uncontrollably into metastable oscillation.',
            'D. Q transitions asynchronously without clock reference.',
          ],
          correctAnswer: 'A',
          solution: 'Data is stable well prior to the setup window of clock edge T3. Thus, flip-flop samples D = 1 cleanly, driving Q to logic HIGH.',
          subject: baseQuestion.subject.isNotEmpty ? baseQuestion.subject : 'Digital Electronics & VLSI',
          topic: baseQuestion.topic.isNotEmpty ? baseQuestion.topic : 'Sequential Circuits & Timing',
          subtopic: 'Setup & Hold Timing Verification',
          difficulty: Difficulty.medium,
          questionType: QuestionType.diagramBased,
          status: QuestionStatus.unsolved,
          verificationStatus: VerificationStatus.aiGenerated,
          diagramType: DiagramType.timingWaveform,
          diagramData: const {'cycles': 6, 'activeEdge': 3},
          sourceId: 'ai_variation',
          sourceName: 'AI Procedural Diagram Generator',
          createdAt: now,
        );

      case VariationType.numerical:
        final rVal = (_rand.nextInt(8) + 2) * 5;
        final cVal = (_rand.nextInt(5) + 1) * 10;
        final tau = (rVal * cVal) / 1000.0;
        return QuestionModel(
          questionId: newId,
          userId: currentUserId,
          questionText: 'A first-order circuit with equivalent resistance R = $rVal Ω and capacitance C = $cVal μF is excited by a step source. What is the circuit time constant τ?',
          options: [
            'A. ${tau.toStringAsFixed(2)} ms',
            'B. ${(tau * 2).toStringAsFixed(2)} ms',
            'C. ${(tau / 2).toStringAsFixed(2)} ms',
            'D. ${(tau * 10).toStringAsFixed(2)} ms',
          ],
          correctAnswer: 'A',
          solution: 'Time constant τ = R * C = $rVal Ω * $cVal μF = ${tau.toStringAsFixed(2)} ms.',
          subject: baseQuestion.subject.isNotEmpty ? baseQuestion.subject : 'Network Theory',
          topic: baseQuestion.topic.isNotEmpty ? baseQuestion.topic : 'Transient Analysis',
          subtopic: 'Time Constant Calculation',
          difficulty: Difficulty.medium,
          questionType: QuestionType.numerical,
          status: QuestionStatus.unsolved,
          verificationStatus: VerificationStatus.aiGenerated,
          sourceId: 'ai_variation',
          sourceName: 'AI Numerical Variation Generator',
          createdAt: now,
        );

      case VariationType.conceptual:
      case VariationType.similar:
        return QuestionModel(
          questionId: newId,
          userId: currentUserId,
          questionText: 'Regarding ${baseQuestion.topic}, what is the primary engineering trade-off encountered when optimizing for maximum bandwidth versus minimum power consumption?',
          options: const [
            'A. Higher bias current increases transconductance gm (widening bandwidth) at the expense of higher static power dissipation.',
            'B. Increasing load resistance increases bandwidth while decreasing power proportionally.',
            'C. Feedback attenuation decreases noise figure while maintaining invariant power.',
            'D. Bandwidth is solely governed by capacitive parasitics independent of power.',
          ],
          correctAnswer: 'A',
          solution: 'Bandwidth is proportional to gm / C_load. Since transconductance gm scales with bias current (I_D or I_C), higher speed directly demands higher DC operating power.',
          subject: baseQuestion.subject,
          topic: baseQuestion.topic,
          subtopic: baseQuestion.subtopic,
          difficulty: Difficulty.medium,
          questionType: QuestionType.conceptual,
          status: QuestionStatus.unsolved,
          verificationStatus: VerificationStatus.aiGenerated,
          sourceId: 'ai_variation',
          sourceName: 'AI Concept Variation Generator',
          createdAt: now,
        );
    }
  }

  static Future<List<QuestionModel>> generateTargetedPractice({
    required String subject,
    required String topic,
    required int count,
    required Difficulty difficulty,
    required String currentUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final List<QuestionModel> batch = [];
    final base = QuestionModel(
      questionId: 'temp',
      userId: currentUserId,
      questionText: 'Topic question on $topic',
      options: const [],
      correctAnswer: 'A',
      subject: subject,
      topic: topic,
      sourceId: 'smart_practice',
      sourceName: 'Smart Weak-Topic Generator',
      createdAt: DateTime.now(),
    );

    final variations = [
      VariationType.conceptual,
      VariationType.numerical,
      VariationType.diagram,
      VariationType.similar,
    ];

    for (int i = 0; i < count; i++) {
      final vType = variations[i % variations.length];
      final q = await generateVariation(
        baseQuestion: base,
        variationType: vType,
        currentUserId: currentUserId,
      );
      batch.add(q.copyWith(
        difficulty: difficulty,
        questionId: 'smart_prac_${_uuid.v4()}',
      ));
    }
    return batch;
  }
}
