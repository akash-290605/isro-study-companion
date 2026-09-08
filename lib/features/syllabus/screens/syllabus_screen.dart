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

  void _showAddSubjectDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g. Microwave Engineering',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(syllabusRepositoryProvider).addCustomSubject(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(SyllabusSubject subject) {
    final ctrl = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(syllabusRepositoryProvider).editSubjectName(subject.id, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(SyllabusSubject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}" and all its topics and subtopics? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(syllabusRepositoryProvider).deleteSubject(subject.id);
              Navigator.pop(ctx);
              setState(() {
                _selectedSubjectId = null;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog(String subjectId) {
    final topicCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Topic'),
        content: TextField(
          controller: topicCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Topic Title',
            hintText: 'e.g. Waveguides & Cavities',
          ),
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

  void _showEditTopicDialog(String subjectId, SyllabusTopic topic) {
    final topicCtrl = TextEditingController(text: topic.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Topic Title'),
        content: TextField(
          controller: topicCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Topic Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (topicCtrl.text.trim().isNotEmpty) {
                ref.read(syllabusRepositoryProvider).editTopicName(subjectId, topic.id, topicCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(String subjectId, SyllabusTopic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Delete topic "${topic.name}" and all its subtopics?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(syllabusRepositoryProvider).deleteTopic(subjectId, topic.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddSubtopicDialog(String subjectId, String topicId) {
    final subtopicCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subtopic'),
        content: TextField(
          controller: subtopicCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subtopic Name',
            hintText: 'e.g. Cutoff frequency & dominant mode',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (subtopicCtrl.text.trim().isNotEmpty) {
                ref.read(syllabusRepositoryProvider).addSubtopic(subjectId, topicId, subtopicCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Subtopic'),
          ),
        ],
      ),
    );
  }

  void _showEditSubtopicDialog(String subjectId, String topicId, SyllabusSubtopic subtopic) {
    final subtopicCtrl = TextEditingController(text: subtopic.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subtopic Name'),
        content: TextField(
          controller: subtopicCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subtopic Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (subtopicCtrl.text.trim().isNotEmpty) {
                ref.read(syllabusRepositoryProvider).editSubtopicName(
                      subjectId,
                      topicId,
                      subtopic.id,
                      subtopicCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubtopic(String subjectId, String topicId, SyllabusSubtopic subtopic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subtopic'),
        content: Text('Delete subtopic "${subtopic.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(syllabusRepositoryProvider).deleteSubtopic(subjectId, topicId, subtopic.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syllabus = ref.watch(syllabusRepositoryProvider);
    final subjects = syllabus.subjects;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No subjects in syllabus.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
              onPressed: _showAddSubjectDialog,
            ),
          ],
        ),
      );
    }

    if (_selectedSubjectId == null || !subjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = subjects.first.id;
    }

    final currentSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.first,
    );

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // Starter Syllabus Disclaimer Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? Colors.amber.shade900.withOpacity(0.25) : Colors.amber.shade50,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppConstants.syllabusDisclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Overall Progress: ${syllabus.overallProgressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
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
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: _buildSubjectList(subjects, isDark),
                    ),
                    // Right Topic & Subtopic Hierarchy
                    Expanded(child: _buildTopicView(currentSubject, isDark)),
                  ],
                )
              : Column(
                  children: [
                    // Horizontal Subject Chips on mobile
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: subjects.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == subjects.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: ActionChip(
                                avatar: const Icon(Icons.add, size: 16),
                                label: const Text('Add Subject', style: TextStyle(fontSize: 12)),
                                onPressed: _showAddSubjectDialog,
                              ),
                            );
                          }
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
                    Expanded(child: _buildTopicView(currentSubject, isDark)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectList(List<SyllabusSubject> subjects, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUBJECTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
              IconButton(
                tooltip: 'Add New Subject',
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: _showAddSubjectDialog,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (ctx, i) {
              final s = subjects[i];
              final isSelected = s.id == _selectedSubjectId;
              final pct = s.completionPercentage;

              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
                        Text('${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  tooltip: 'Subject Options',
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showEditSubjectDialog(s);
                    } else if (action == 'delete') {
                      _confirmDeleteSubject(s);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Name'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Subject', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => setState(() => _selectedSubjectId = s.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicView(SyllabusSubject subject, bool isDark) {
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
            tooltip: 'Edit Subject Name',
            icon: const Icon(Icons.drive_file_rename_outline_rounded),
            onPressed: () => _showEditSubjectDialog(subject),
          ),
          IconButton(
            tooltip: 'Delete Subject',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDeleteSubject(subject),
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
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddTopicDialog(subject.id),
                    label: const Text('Add Topic'),
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
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size: 20),
                          tooltip: 'Topic Options',
                          onSelected: (action) {
                            if (action == 'add_subtopic') {
                              _showAddSubtopicDialog(subject.id, topic.id);
                            } else if (action == 'edit') {
                              _showEditTopicDialog(subject.id, topic);
                            } else if (action == 'delete') {
                              _confirmDeleteTopic(subject.id, topic);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'add_subtopic',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add Subtopic'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Topic Title'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Topic', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'No subtopics listed yet.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Subtopic', style: TextStyle(fontSize: 12)),
                                onPressed: () => _showAddSubtopicDialog(subject.id, topic.id),
                              ),
                            ],
                          ),
                        )
                      else ...[
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statusDropdown(
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
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  tooltip: 'Subtopic Options',
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _showEditSubtopicDialog(subject.id, topic.id, st);
                                    } else if (action == 'delete') {
                                      _confirmDeleteSubtopic(subject.id, topic.id, st);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit Name'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Subtopic', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showAddSubtopicDialog(subject.id, topic.id),
                            ),
                          ),
                        ),
                      ],
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

