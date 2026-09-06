import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesRepo = ref.watch(notesRepositoryProvider);
    final questionsRepo = ref.watch(questionsRepositoryProvider);
    final sourcesRepo = ref.watch(sourcesRepositoryProvider);
    final formulaRepo = ref.watch(formulaRepositoryProvider);
    final mistakesRepo = ref.watch(mistakesRepositoryProvider);
    final flashcardsRepo = ref.watch(flashcardsRepositoryProvider);

    final matchingNotes = _query.isEmpty ? [] : notesRepo.searchNotes(_query);
    final matchingQuestions = _query.isEmpty
        ? []
        : questionsRepo.filterQuestions(searchQuery: _query);
    final matchingSources = _query.isEmpty ? [] : sourcesRepo.searchSources(_query);
    final matchingFormulas = _query.isEmpty ? [] : formulaRepo.searchFormulas(_query);
    final matchingMistakes = _query.isEmpty
        ? []
        : mistakesRepo.mistakes.where((m) {
            final q = _query.toLowerCase();
            return m.questionText.toLowerCase().contains(q) ||
                m.topic.toLowerCase().contains(q) ||
                m.subject.toLowerCase().contains(q);
          }).toList();
    final matchingFlashcards = _query.isEmpty
        ? []
        : flashcardsRepo.cards.where((c) {
            final q = _query.toLowerCase();
            return c.question.toLowerCase().contains(q) ||
                c.answer.toLowerCase().contains(q) ||
                c.topic.toLowerCase().contains(q);
          }).toList();

    final totalResults = matchingNotes.length +
        matchingQuestions.length +
        matchingSources.length +
        matchingFormulas.length +
        matchingMistakes.length +
        matchingFlashcards.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        height: 580,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Input Header
            Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search Notes, Questions, Sources, Formulas, Mistakes...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _query = val.trim();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (_query.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.manage_search_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Type to search across all study materials and exam data',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: "Kirchhoff", "Boolean", "Thevenin", "Mesh"',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else if (totalResults == 0)
              Expanded(
                child: Center(
                  child: Text(
                    'No matching records found for "$_query"',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    if (matchingNotes.isNotEmpty) ...[
                      _sectionHeader('Notes (${matchingNotes.length})', Icons.edit_note_rounded),
                      ...matchingNotes.map((n) => ListTile(
                            title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${n.subject} • ${n.topic}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/notes');
                            },
                          )),
                    ],
                    if (matchingQuestions.isNotEmpty) ...[
                      _sectionHeader('Question Bank (${matchingQuestions.length})', Icons.quiz_rounded),
                      ...matchingQuestions.map((q) => ListTile(
                            title: Text(q.questionText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${q.subject} • ${q.difficulty.label} • ${q.sourceName}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/question-bank');
                            },
                          )),
                    ],
                    if (matchingFormulas.isNotEmpty) ...[
                      _sectionHeader('Formulas (${matchingFormulas.length})', Icons.functions_rounded),
                      ...matchingFormulas.map((f) => ListTile(
                            title: Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${f.subject} • ${f.topic}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/formula-bank');
                            },
                          )),
                    ],
                    if (matchingSources.isNotEmpty) ...[
                      _sectionHeader('Study Materials (${matchingSources.length})', Icons.folder_shared_rounded),
                      ...matchingSources.map((s) => ListTile(
                            title: Text(s.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${s.subject} • ${s.sourceType.label}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/source-library');
                            },
                          )),
                    ],
                    if (matchingMistakes.isNotEmpty) ...[
                      _sectionHeader('Mistakes (${matchingMistakes.length})', Icons.error_outline_rounded),
                      ...matchingMistakes.map((m) => ListTile(
                            title: Text(m.questionText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${m.subject} • ${m.topic}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/mistakes');
                            },
                          )),
                    ],
                    if (matchingFlashcards.isNotEmpty) ...[
                      _sectionHeader('Flashcards (${matchingFlashcards.length})', Icons.style_rounded),
                      ...matchingFlashcards.map((c) => ListTile(
                            title: Text(c.question, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${c.subject} • ${c.topic}', maxLines: 1),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/flashcards');
                            },
                          )),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }
}

