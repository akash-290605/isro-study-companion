import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/formula_model.dart';

class FormulaBankScreen extends ConsumerStatefulWidget {
  const FormulaBankScreen({super.key});

  @override
  ConsumerState<FormulaBankScreen> createState() => _FormulaBankScreenState();
}

class _FormulaBankScreenState extends ConsumerState<FormulaBankScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubject;
  bool _onlyFavorites = false;

  void _openFormulaDialog([FormulaModel? formula]) {
    final titleCtrl = TextEditingController(text: formula?.title ?? '');
    final latexCtrl = TextEditingController(text: formula?.latexExpression ?? '');
    final descCtrl = TextEditingController(text: formula?.description ?? '');
    final subjectCtrl = TextEditingController(text: formula?.subject ?? 'Network Theory');
    final topicCtrl = TextEditingController(text: formula?.topic ?? 'Network Analysis');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(formula == null ? 'Add Formula' : 'Edit Formula'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Formula Name / Law'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: latexCtrl,
                  decoration: const InputDecoration(
                    labelText: 'LaTeX Expression (e.g. \\sum I_k = 0 or \\eta = 50\\%)',
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
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Engineering Description / Context'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || latexCtrl.text.trim().isEmpty) return;
              final user = ref.read(authRepositoryProvider).currentUser;
              final f = FormulaModel(
                formulaId: formula?.formulaId ?? const Uuid().v4(),
                userId: user?.id ?? '',
                subject: subjectCtrl.text.trim(),
                topic: topicCtrl.text.trim(),
                title: titleCtrl.text.trim(),
                latexExpression: latexCtrl.text.trim(),
                description: descCtrl.text.trim(),
                sourceId: 'custom_formula',
                sourceName: 'Personal Formula Bank',
                sourceLocation: 'Engineering Reference',
                createdAt: DateTime.now(),
              );
              ref.read(formulaRepositoryProvider).addFormula(f);
              Navigator.pop(ctx);
            },
            child: const Text('Save Formula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formRepo = ref.watch(formulaRepositoryProvider);
    var formulas = formRepo.searchFormulas(_searchQuery);

    if (_selectedSubject != null) {
      formulas = formulas.where((f) => f.subject == _selectedSubject).toList();
    }
    if (_onlyFavorites) {
      formulas = formulas.where((f) => f.isFavorite).toList();
    }

    final allSubjects = formRepo.formulas.map((f) => f.subject).where((s) => s.isNotEmpty).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Formula Bank'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Formula'),
            onPressed: () => _openFormulaDialog(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search formula name, law, or subject...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: _selectedSubject,
                      hint: const Text('Subject: All'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Subject: All')),
                        ...allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) => setState(() => _selectedSubject = v),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Favorites ★', style: TextStyle(fontSize: 12)),
                      selected: _onlyFavorites,
                      onSelected: (v) => setState(() => _onlyFavorites = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formulas Grid
            Expanded(
              child: formulas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.functions_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No formulas found.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _openFormulaDialog(),
                            child: const Text('Add Formula'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: formulas.length,
                      itemBuilder: (ctx, i) {
                        final f = formulas[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${f.subject} • ${f.topic}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Favorite',
                                      icon: Icon(
                                        f.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: f.isFavorite ? Colors.amber : Colors.grey,
                                      ),
                                      onPressed: () => formRepo.toggleFavorite(f.formulaId),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () => formRepo.deleteFormula(f.formulaId),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  f.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: MathFormulaView(
                                      formula: f.latexExpression,
                                      textStyle: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                if (f.description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    f.description,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Source: ${f.sourceName} (${f.sourceLocation})',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

