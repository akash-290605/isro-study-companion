import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/real_time_clock.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final user = auth.currentUser;
    final sessionsRepo = ref.watch(studySessionsRepositoryProvider);
    final testRepo = ref.watch(testRepositoryProvider);
    final mistakesRepo = ref.watch(mistakesRepositoryProvider);
    final flashcardsRepo = ref.watch(flashcardsRepositoryProvider);
    final syllabusRepo = ref.watch(syllabusRepositoryProvider);

    // Compute Today's metrics
    final todayStudyMinutes = (sessionsRepo.todayStudySeconds / 60).round();
    final dailyGoalMinutes = user?.dailyStudyGoalMinutes ?? 240;
    final studyGoalProgress = (todayStudyMinutes / dailyGoalMinutes).clamp(0.0, 1.0);

    // Today's tests & question attempts
    final today = DateTime.now();
    final todayResults = testRepo.results.where((r) {
      return r.completedAt.year == today.year &&
          r.completedAt.month == today.month &&
          r.completedAt.day == today.day;
    }).toList();

    final questionsAttempted = todayResults.fold(0, (sum, r) => sum + r.correctCount + r.wrongCount);
    final questionsCorrect = todayResults.fold(0, (sum, r) => sum + r.correctCount);
    final todayAccuracy = questionsAttempted > 0
        ? ((questionsCorrect / questionsAttempted) * 100).toStringAsFixed(1)
        : (testRepo.results.isNotEmpty
            ? (testRepo.results.fold(0.0, (s, r) => s + r.percentage) / testRepo.results.length)
                .toStringAsFixed(1)
            : '0.0');

    // Aggregate topic performance to identify weak topics (< 75%)
    final Map<String, List<double>> topicScores = {};
    for (final r in testRepo.results) {
      for (final entry in r.topicBreakdown.entries) {
        topicScores.putIfAbsent(entry.key, () => []).add(entry.value.accuracy);
      }
    }

    final List<MapEntry<String, double>> weakTopicsList = [];
    topicScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      weakTopicsList.add(MapEntry(topic, avg));
    });

    // Default weak topics if user has taken few tests yet
    if (weakTopicsList.isEmpty) {
      weakTopicsList.addAll([
        const MapEntry('Digital Electronics', 54.0),
        const MapEntry('Network Theory', 62.0),
        const MapEntry('Signals and Systems', 71.0),
      ]);
    }
    weakTopicsList.sort((a, b) => a.value.compareTo(b.value));

    // Recommendation logic: "What should I study now?"
    final topWeakTopic = weakTopicsList.first.key;
    final dueFlashcardsCount = flashcardsRepo.dueCards.length;
    final unresolvedMistakesCount = mistakesRepo.unresolvedCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Streak Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1E36), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.displayName.isNotEmpty == true ? user!.displayName : "Aspirant"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ISRO Scientist/Engineer (ECE) Study Companion',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '${user?.streakDays ?? 1} DAY STREAK',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const RealTimeClockWidget(variant: ClockVariant.headerBanner),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.displayName.isNotEmpty == true ? user!.displayName : "Aspirant"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ISRO Scientist/Engineer (ECE) Study Companion',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const RealTimeClockWidget(variant: ClockVariant.headerBanner),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                '${user?.streakDays ?? 1} DAY STREAK',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // "What should I study now?" Smart Recommendation Card
          Card(
            color: const Color(0xFFEFF6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (ctx, cardConstraints) {
                  final isCardNarrow = cardConstraints.maxWidth < 600;
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WHAT SHOULD I STUDY NOW?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review "$topWeakTopic" & practice ${unresolvedMistakesCount > 0 ? "$unresolvedMistakesCount logged mistakes" : "exam questions"}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recommended based on your recent test accuracy (${weakTopicsList.first.value.toStringAsFixed(0)}%) and unrevised notes.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                      ),
                    ],
                  );

                  final startButton = ElevatedButton.icon(
                    onPressed: () => context.go('/ai-test'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Test'),
                  );

                  if (isCardNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: content),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: startButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      startButton,
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Today's Progress Stats Grid
          const Text(
            "TODAY'S PROGRESS",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.6 : 1.25,
                children: [
                  _statCard(
                    context,
                    title: 'Study Time',
                    value: '${(todayStudyMinutes / 60).toStringAsFixed(1)} hrs',
                    subtitle: 'Goal: ${(dailyGoalMinutes / 60).toStringAsFixed(0)} hrs',
                    progress: studyGoalProgress,
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  _statCard(
                    context,
                    title: 'Questions Solved',
                    value: '$questionsAttempted',
                    subtitle: 'Target: ${user?.dailyQuestionsGoal ?? 30}',
                    progress: (questionsAttempted / (user?.dailyQuestionsGoal ?? 30)).clamp(0.0, 1.0),
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _statCard(
                    context,
                    title: 'Accuracy',
                    value: '$todayAccuracy%',
                    subtitle: 'Correct: $questionsCorrect / $questionsAttempted',
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _statCard(
                    context,
                    title: 'Tests Completed',
                    value: '${todayResults.length}',
                    subtitle: 'Target: ${user?.dailyTestsGoal ?? 1}',
                    progress: (todayResults.length / (user?.dailyTestsGoal ?? 1)).clamp(0.0, 1.0),
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Two-column section: Weak Topics & Revision Due
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 800;
              final leftCol = _buildWeakTopicsCard(context, weakTopicsList);
              final rightCol = _buildRevisionSummaryCard(
                context,
                dueFlashcardsCount: dueFlashcardsCount,
                unresolvedMistakesCount: unresolvedMistakesCount,
                syllabusRepo: syllabusRepo,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftCol),
                    const SizedBox(width: 16),
                    Expanded(child: rightCol),
                  ],
                );
              } else {
                return Column(
                  children: [
                    leftCol,
                    const SizedBox(height: 16),
                    rightCol,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Weekly & Monthly Study Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STUDY TIME CONSISTENCY',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('Detailed Performance'),
                        onPressed: () => context.go('/performance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (ctx, summaryConstraints) {
                      final isSummaryNarrow = summaryConstraints.maxWidth < 600;
                      if (isSummaryNarrow) {
                        return Column(
                          children: [
                            _summaryBox(
                              'Last 7 Days',
                              '${(sessionsRepo.weeklyStudySeconds / 3600).toStringAsFixed(1)} hrs',
                              Icons.date_range_rounded,
                            ),
                            const SizedBox(height: 8),
                            _summaryBox(
                              'Last 30 Days',
                              '${(sessionsRepo.monthlyStudySeconds / 3600).toStringAsFixed(1)} hrs',
                              Icons.calendar_month_rounded,
                            ),
                            const SizedBox(height: 8),
                            _summaryBox(
                              'Syllabus Covered',
                              '${syllabusRepo.overallProgressPercentage.toStringAsFixed(1)}%',
                              Icons.pie_chart_outline_rounded,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _summaryBox(
                              'Last 7 Days',
                              '${(sessionsRepo.weeklyStudySeconds / 3600).toStringAsFixed(1)} hrs',
                              Icons.date_range_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryBox(
                              'Last 30 Days',
                              '${(sessionsRepo.monthlyStudySeconds / 3600).toStringAsFixed(1)} hrs',
                              Icons.calendar_month_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryBox(
                              'Syllabus Covered',
                              '${syllabusRepo.overallProgressPercentage.toStringAsFixed(1)}%',
                              Icons.pie_chart_outline_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    double? progress,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakTopicsCard(
    BuildContext context,
    List<MapEntry<String, double>> weakTopics,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WEAK TOPICS ANALYSIS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Requires Focus',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...weakTopics.take(4).map((entry) {
              final pct = entry.value;
              final isSevere = pct < 60;
              final color = isSevere ? Colors.red : Colors.orange;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevisionSummaryCard(
    BuildContext context, {
    required int dueFlashcardsCount,
    required int unresolvedMistakesCount,
    required dynamic syllabusRepo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REVISION QUEUE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => context.go('/revision'),
                  child: const Text('Open Revision', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _revisionRow(
              icon: Icons.menu_book_rounded,
              label: 'Topics Due for Revision',
              count: '3 Topics',
              color: const Color(0xFF1E3A8A),
              onTap: () => context.go('/syllabus'),
            ),
            const Divider(height: 16),
            _revisionRow(
              icon: Icons.error_outline_rounded,
              label: 'Mistakes to Review',
              count: '$unresolvedMistakesCount Mistakes',
              color: Colors.red,
              onTap: () => context.go('/mistakes'),
            ),
            const Divider(height: 16),
            _revisionRow(
              icon: Icons.style_rounded,
              label: 'Flashcards Scheduled Today',
              count: '$dueFlashcardsCount Cards',
              color: Colors.purple,
              onTap: () => context.go('/flashcards'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revisionRow({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

