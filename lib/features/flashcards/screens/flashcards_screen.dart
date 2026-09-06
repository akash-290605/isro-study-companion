import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../data/models/question_model.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  int _currentIndex = 0;
  bool _showBack = false;

  void _openCreateCardDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'Network Theory');
    final topicCtrl = TextEditingController(text: 'Network Analysis');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Source-Grounded Flashcard'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(labelText: 'Question (Front)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Answer (Back) - Grounded in study notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: topicCtrl,
                        decoration: const InputDecoration(labelText: 'Topic'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (qCtrl.text.trim().isEmpty || aCtrl.text.trim().isEmpty) return;
              final user = ref.read(authRepositoryProvider).currentUser;
              final card = FlashcardModel(
                cardId: const Uuid().v4(),
                userId: user?.id ?? '',
                sourceId: 'custom_flashcard',
                sourceName: 'Personal Study Material',
                sourceLocation: 'User Note Entry',
                sourceChunk: aCtrl.text.trim(),
                subject: subjectCtrl.text.trim(),
                topic: topicCtrl.text.trim(),
                question: qCtrl.text.trim(),
                answer: aCtrl.text.trim(),
                difficulty: Difficulty.medium,
                reviewDate: DateTime.now(),
                createdAt: DateTime.now(),
              );
              ref.read(flashcardsRepositoryProvider).addFlashcard(card);
              Navigator.pop(ctx);
            },
            child: const Text('Save Card'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fcRepo = ref.watch(flashcardsRepositoryProvider);
    final cards = fcRepo.cards;

    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.style_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No flashcards found.'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create First Flashcard'),
                onPressed: _openCreateCardDialog,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentIndex >= cards.length) {
      _currentIndex = 0;
    }
    final card = cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards (${_currentIndex + 1}/${cards.length})'),
        actions: [
          IconButton(
            tooltip: 'Add Flashcard',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openCreateCardDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                // Subject & Topic Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${card.subject} • ${card.topic}',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Interactive Flip Card
                GestureDetector(
                  onTap: () => setState(() => _showBack = !_showBack),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 280),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _showBack ? const Color(0xFF0F172A) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showBack ? const Color(0xFF0284C7) : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _showBack ? Colors.cyan.shade900 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _showBack ? 'BACK (ANSWER)' : 'FRONT (QUESTION)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _showBack ? Colors.cyan.shade200 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: MathFormulaView(
                            formula: _showBack ? card.answer : card.question,
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _showBack ? Colors.white : null,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flip_rounded, size: 14, color: _showBack ? Colors.white54 : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Tap card to flip',
                              style: TextStyle(fontSize: 11, color: _showBack ? Colors.white54 : Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Source Reference Footer
                Text(
                  'Source: ${card.sourceName} (${card.sourceLocation})',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),

                // Spaced Repetition Buttons (Need Review / Got It)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Need Review'),
                      onPressed: () {
                        fcRepo.answerCard(card.cardId, false);
                        setState(() {
                          _showBack = false;
                          _currentIndex = ((_currentIndex + 1) % cards.length).toInt();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Got It!'),
                      onPressed: () {
                        fcRepo.answerCard(card.cardId, true);
                        setState(() {
                          _showBack = false;
                          _currentIndex = ((_currentIndex + 1) % cards.length).toInt();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _currentIndex > 0
                          ? () => setState(() {
                                _showBack = false;
                                _currentIndex -= 1;
                              })
                          : null,
                    ),
                    Text('${_currentIndex + 1} of ${cards.length}'),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _currentIndex < cards.length - 1
                          ? () => setState(() {
                                _showBack = false;
                                _currentIndex += 1;
                              })
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

