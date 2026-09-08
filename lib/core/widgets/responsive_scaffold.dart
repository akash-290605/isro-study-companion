import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/search/global_search_dialog.dart';
import '../services/providers.dart';
import 'real_time_clock.dart';
import 'sync_badge.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem(this.label, this.icon, this.route);
}

final List<NavItem> appNavItems = [
  const NavItem('Dashboard', Icons.dashboard_rounded, '/'),
  const NavItem('Timer', Icons.timer_rounded, '/timer'),
  const NavItem('Syllabus', Icons.menu_book_rounded, '/syllabus'),
  const NavItem('Notes', Icons.note_alt_rounded, '/notes'),
  const NavItem('Upload Hub', Icons.cloud_upload_rounded, '/uploads'),
  const NavItem('Source Library', Icons.folder_shared_rounded, '/source-library'),
  const NavItem('Question Bank', Icons.quiz_rounded, '/question-bank'),
  const NavItem('AI Test', Icons.auto_awesome_rounded, '/ai-test'),
  const NavItem('Performance', Icons.insights_rounded, '/performance'),
  const NavItem('Revision', Icons.repeat_rounded, '/revision'),
  const NavItem('Mistakes', Icons.error_outline_rounded, '/mistakes'),
  const NavItem('Flashcards', Icons.style_rounded, '/flashcards'),
  const NavItem('Formula Bank', Icons.functions_rounded, '/formula-bank'),
  const NavItem('Settings', Icons.settings_rounded, '/settings'),
];

class ResponsiveScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final auth = ref.watch(authRepositoryProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Padding(
          padding: EdgeInsets.only(left: isDesktop ? 16.0 : 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ISRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'STUDY COMPANION',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isDesktop ? 15 : 13,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Text(
                    'ECE PREPARATION',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Global Search trigger
          IconButton(
            tooltip: 'Global Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const GlobalSearchDialog(),
              );
            },
          ),
          // Real-time Date and Time Clock
          if (MediaQuery.of(context).size.width >= 640) ...[
            const RealTimeClockWidget(variant: ClockVariant.compact),
            const SizedBox(width: 8),
          ],
          // Multi-Device Sync Status Badge
          const SyncStatusBadge(),
          const SizedBox(width: 4),
          // Theme Switcher (visible on screens >= 420px, also available in Account Menu)
          if (MediaQuery.of(context).size.width >= 420) ...[
            IconButton(
              tooltip: 'Toggle Theme',
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).state =
                    themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
          ],
          // User Avatar & Logout
          PopupMenuButton<String>(
            tooltip: 'Account',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF1E3A8A),
                child: Text(
                  auth.currentUser?.displayName.isNotEmpty == true
                      ? auth.currentUser!.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            onSelected: (val) {
              if (val == 'theme') {
                ref.read(themeModeProvider.notifier).state =
                    themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              } else if (val == 'settings') {
                context.go('/settings');
              } else if (val == 'logout') {
                auth.signOut();
                context.go('/login');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  auth.currentUser?.email ?? 'Logged in',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Settings & Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop ? null : _buildMobileDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(context),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: appNavItems.map((item) {
                final isSelected = currentRoute == item.route;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF1E3A8A).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.go(item.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Tagline footer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Study → Practice → Analyze\n→ Revise → Improve',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1E36), Color(0xFF1E3A8A)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ISRO STUDY COMPANION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ECE Examination Preparation',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: appNavItems.map((item) {
                final isSelected = currentRoute == item.route;
                return ListTile(
                  leading: Icon(item.icon, color: isSelected ? const Color(0xFF1E3A8A) : null),
                  title: Text(item.label),
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.route);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    int getIndex() {
      if (currentRoute == '/') return 0;
      if (currentRoute == '/timer') return 1;
      if (currentRoute == '/syllabus') return 2;
      if (currentRoute == '/ai-test') return 3;
      return 4;
    }

    return BottomNavigationBar(
      currentIndex: getIndex(),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1E3A8A),
      unselectedItemColor: Colors.grey.shade600,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/timer');
            break;
          case 2:
            context.go('/syllabus');
            break;
          case 3:
            context.go('/ai-test');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Timer'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Syllabus'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Test'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'More'),
      ],
    );
  }
}

