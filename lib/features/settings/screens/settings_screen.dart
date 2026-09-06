import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _studyHoursCtrl;
  late TextEditingController _questionsTargetCtrl;
  late TextEditingController _testsTargetCtrl;
  late TextEditingController _streakDaysCtrl;

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _studyHoursCtrl = TextEditingController(
      text: '${((user?.dailyStudyGoalMinutes ?? 240) / 60).round()}',
    );
    _questionsTargetCtrl = TextEditingController(
      text: '${user?.dailyQuestionsGoal ?? 30}',
    );
    _testsTargetCtrl = TextEditingController(
      text: '${user?.dailyTestsGoal ?? 1}',
    );
    _streakDaysCtrl = TextEditingController(
      text: '${user?.streakDays ?? 12}',
    );
  }

  @override
  void dispose() {
    _studyHoursCtrl.dispose();
    _questionsTargetCtrl.dispose();
    _testsTargetCtrl.dispose();
    _streakDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStreak(int streak) async {
    await ref.read(authRepositoryProvider).updateStreak(streak);
    _streakDaysCtrl.text = streak.toString();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Study streak updated to $streak days! 🔥'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _saveGoals() async {
    final hours = int.tryParse(_studyHoursCtrl.text) ?? 4;
    final questions = int.tryParse(_questionsTargetCtrl.text) ?? 30;
    final tests = int.tryParse(_testsTargetCtrl.text) ?? 1;

    await ref.read(authRepositoryProvider).updateGoals(
          studyMinutes: hours * 60,
          questions: questions,
          tests: tests,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily study goals updated!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authRepositoryProvider);
    final user = auth.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final syncService = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'USER ACCOUNT & PROFILE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF1E3A8A),
                            child: Text(
                              user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            user?.displayName.isNotEmpty == true ? user!.displayName : 'ISRO Aspirant',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.email ?? 'offline@companion.edu'),
                              const SizedBox(height: 2),
                              Text('User ID: ${user?.id ?? "local"}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Theme Mode Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'APPEARANCE & THEME',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.settings_system_daydream_rounded, size: 16),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (set) {
                            ref.read(themeModeProvider.notifier).state = set.first;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Study Goals Editor
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY STUDY TARGETS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _studyHoursCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Study Goal (Hours/day)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _questionsTargetCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Daily Questions Target'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _testsTargetCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Daily Test Target'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _saveGoals,
                            child: const Text('Update Daily Targets'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Study Streak & Habit Tracking Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STUDY STREAK & HABIT TRACKING',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade400),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user?.streakDays ?? 0} DAYS ACTIVE',
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Modify your consecutive study streak days manually if you switched devices or want to adjust your preparation counter.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _streakDaysCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Consecutive Study Days',
                                  hintText: 'e.g. 15',
                                  prefixIcon: Icon(Icons.local_fire_department_rounded, color: Colors.amber),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Save Streak'),
                              onPressed: () {
                                final count = int.tryParse(_streakDaysCtrl.text) ?? 0;
                                _updateStreak(count);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.remove, size: 14),
                              label: const Text('-1 Day'),
                              onPressed: () {
                                final cur = int.tryParse(_streakDaysCtrl.text) ?? (user?.streakDays ?? 0);
                                if (cur > 0) _updateStreak(cur - 1);
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 14),
                              label: const Text('+1 Day'),
                              onPressed: () {
                                final cur = int.tryParse(_streakDaysCtrl.text) ?? (user?.streakDays ?? 0);
                                _updateStreak(cur + 1);
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.bolt, size: 14, color: Colors.amber),
                              label: const Text('+7 Days (1 Wk)'),
                              onPressed: () {
                                final cur = int.tryParse(_streakDaysCtrl.text) ?? (user?.streakDays ?? 0);
                                _updateStreak(cur + 7);
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.restart_alt, size: 14, color: Colors.grey),
                              label: const Text('Reset to 0'),
                              onPressed: () => _updateStreak(0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Device Sync & Offline Queue
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CROSS-DEVICE SYNCHRONIZATION',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sync_rounded, color: Color(0xFF1E3A8A)),
                          title: Text('Current Status: ${syncService.status.label}'),
                          subtitle: const Text('Offline-first architecture with local dirty queue flushing to Firestore.'),
                          trailing: OutlinedButton(
                            onPressed: () {
                              syncService.syncPendingData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Checking cloud synchronizations...')),
                              );
                            },
                            child: const Text('Sync Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notifications Toggle (FCM)
                Card(
                  child: SwitchListTile(
                    title: const Text('Study & Revision Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Daily goal reminders, test reminders, and flashcard revision alerts.'),
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Actions: Logout & Delete Account
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        onPressed: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text('Delete Account'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Account?'),
                              content: const Text(
                                'This will permanently remove all your study sessions, question bank, test history, and notes. This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await auth.deleteAccount();
                                    if (context.mounted) context.go('/login');
                                  },
                                  child: const Text('Permanently Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

