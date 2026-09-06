import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../data/models/syllabus_model.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  String? _selectedSubjectId;

  void _showAddTopicDialog(String subjectId) {
    final topicCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Topic'),
        content: TextField(
          controller: topicCtrl,
          decoration: const InputDecoration(labelText: 'Topic Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (topicCtrl.text.trim().isNotEmpty) {
                ref.read(syllabusRepositoryProvider).addCustomTopic(subjectId, topicCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syllabus = ref.watch(syllabusRepositoryProvider);
    final subjects = syllabus.subjects;
    if (subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _selectedSubjectId ??= subjects.first.id;
    final currentSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.first,
    );

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // Starter Syllabus Disclaimer Banner (Mandatory per Section 12)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppConstants.syllabusDisclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              Text(
                'Overall Progress: ${syllabus.overallProgressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: isWide
              ? Row(
                  children: [
                    // Left Subject List
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: _buildSubjectList(subjects),
                    ),
                    // Right Topic & Subtopic Hierarchy
                    Expanded(child: _buildTopicView(currentSubject)),
                  ],
                )
              : Column(
                  children: [
                    // Horizontal Subject Chips on mobile
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: subjects.length,
                        itemBuilder: (ctx, i) {
                          final s = subjects[i];
                          final isSelected = s.id == _selectedSubjectId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(s.name, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedSubjectId = s.id),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(child: _buildTopicView(currentSubject)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectList(List<SyllabusSubject> subjects) {
    return ListView.builder(
      itemCount: subjects.length,
      itemBuilder: (ctx, i) {
        final s = subjects[i];
        final isSelected = s.id == _selectedSubjectId;
        final pct = s.completionPercentage;

        return ListTile(
          selected: isSelected,
          selectedTileColor: const Color(0xFF1E3A8A).withOpacity(0.08),
          title: Text(
            s.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${s.topics.length} topics', style: const TextStyle(fontSize: 11)),
                  Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 100 ? Colors.green : const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          onTap: () => setState(() => _selectedSubjectId = s.id),
        );
      },
    );
  }

  Widget _buildTopicView(SyllabusSubject subject) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Add Custom Topic',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddTopicDialog(subject.id),
          ),
          IconButton(
            tooltip: 'View Subject Notes',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => context.go('/notes'),
          ),
        ],
      ),
      body: subject.topics.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No topics created yet for this subject.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddTopicDialog(subject.id),
                    child: const Text('Add Topic'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subject.topics.length,
              itemBuilder: (ctx, i) {
                final topic = subject.topics[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      topic.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: _statusDropdown(
                      currentStatus: topic.status,
                      onChanged: (newStatus) {
                        ref
                            .read(syllabusRepositoryProvider)
                            .updateTopicStatus(subject.id, topic.id, newStatus);
                      },
                    ),
                    children: [
                      if (topic.subtopics.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No subtopics listed. Study main topic concepts.'),
                        )
                      else
                        ...topic.subtopics.map((st) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            leading: Icon(
                              st.status == SyllabusStatus.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: st.status == SyllabusStatus.completed
                                  ? Colors.green
                                  : Colors.grey,
                              size: 20,
                            ),
                            title: Text(st.name, style: const TextStyle(fontSize: 13)),
                            trailing: _statusDropdown(
                              currentStatus: st.status,
                              onChanged: (newStatus) {
                                ref.read(syllabusRepositoryProvider).updateSubtopicStatus(
                                      subject.id,
                                      topic.id,
                                      st.id,
                                      newStatus,
                                    );
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusDropdown({
    required SyllabusStatus currentStatus,
    required ValueChanged<SyllabusStatus> onChanged,
  }) {
    Color badgeColor;
    switch (currentStatus) {
      case SyllabusStatus.completed:
        badgeColor = Colors.green;
        break;
      case SyllabusStatus.inProgress:
        badgeColor = Colors.orange;
        break;
      case SyllabusStatus.notStarted:
        badgeColor = Colors.grey;
        break;
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<SyllabusStatus>(
        value: currentStatus,
        isDense: true,
        items: SyllabusStatus.values.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Text(
              s.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: s == currentStatus ? badgeColor : null,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }
}

