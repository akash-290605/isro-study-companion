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

  Widget _buildMathChip(
    String code,
    String label,
    TextEditingController ctrl,
    StateSetter setDialogState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          final text = ctrl.text;
          final sel = ctrl.selection;
          if (sel.isValid && sel.start >= 0 && sel.end >= 0) {
            final newText = text.replaceRange(sel.start, sel.end, code);
            ctrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: sel.start + code.length),
            );
          } else {
            ctrl.text = '$text $code'.trim();
          }
          setDialogState(() {});
        },
      ),
    );
  }

  void _openFormulaDialog([FormulaModel? formula]) {
    final titleCtrl = TextEditingController(text: formula?.title ?? '');
    final latexCtrl = TextEditingController(text: formula?.latexExpression ?? '');
    final descCtrl = TextEditingController(text: formula?.description ?? '');
    final subjectCtrl = TextEditingController(text: formula?.subject ?? 'Network Theory');
    final topicCtrl = TextEditingController(text: formula?.topic ?? 'Network Analysis');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final theme = Theme.of(context);
          final currentLatex = latexCtrl.text.trim();

          return AlertDialog(
            title: Text(formula == null ? 'Add Formula' : 'Edit Formula'),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Formula Name / Law'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latexCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'LaTeX Expression (e.g. \\sum I_k = 0 or \\[ V = IR \\])',
                        suffixIcon: currentLatex.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  latexCtrl.clear();
                                  setDialogState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Live Interactive LaTeX Math Preview
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentLatex.isEmpty
                              ? Colors.grey.withOpacity(0.2)
                              : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Live Math Preview',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: currentLatex.isEmpty
                                ? Text(
                                    'Type or paste LaTeX to see rendered math formula here',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : MathFormulaView(
                                    formula: currentLatex,
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Insert Chips for Engineering LaTeX
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMathChip(r'\[ V = IR \]', r'\[ Eq \]', latexCtrl, setDialogState),
                          _buildMathChip(r'\frac{a}{b}', 'Fraction', latexCtrl, setDialogState),
                          _buildMathChip(r'x^{2}', 'Power', latexCtrl, setDialogState),
                          _buildMathChip(r'\sqrt{x}', 'Square Root', latexCtrl, setDialogState),
                          _buildMathChip(r'\sum', 'Sum \u03A3', latexCtrl, setDialogState),
                          _buildMathChip(r'\int', 'Integral \u222B', latexCtrl, setDialogState),
                          _buildMathChip(r'\Omega', 'Ohm \u03A9', latexCtrl, setDialogState),
                          _buildMathChip(r'\mu', 'Micro \u03BC', latexCtrl, setDialogState),
                          _buildMathChip(r'\pi', 'Pi \u03C0', latexCtrl, setDialogState),
                          _buildMathChip(r'\approx', 'Approx \u2248', latexCtrl, setDialogState),
                        ],
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
                    sourceId: formula?.sourceId ?? 'custom_formula',
                    sourceName: formula?.sourceName ?? 'Personal Formula Bank',
                    sourceLocation: formula?.sourceLocation ?? 'Engineering Reference',
                    isFavorite: formula?.isFavorite ?? false,
                    createdAt: formula?.createdAt ?? DateTime.now(),
                  );
                  ref.read(formulaRepositoryProvider).saveFormula(f);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Formula'),
              ),
            ],
          );
        },
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
                        final theme = Theme.of(context);
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
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${f.subject} • ${f.topic}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Edit Formula',
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _openFormulaDialog(f),
                                    ),
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
                                    color: Colors.grey.withOpacity(0.08),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Source: ${f.sourceName} (${f.sourceLocation})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                  ),
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

