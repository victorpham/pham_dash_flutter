import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_controller.dart';
import '../birthdays/birthdays_tab.dart';
import '../calendar/calendar_grid_tab.dart';
import '../notes/recent_notes_tab.dart';
import '../schedule/schedule_tab.dart';
import '../scheduled_lists/scheduled_lists_tab.dart';

/// The dashboard's content tabs.
///
/// The mobile web bar carries eight buttons — Menu, Weather, Calendar,
/// Schedule, Lists, Birthdays, Notes, Theme. Menu and Theme are actions rather
/// than destinations, and Weather is deferred (it talks to weather.gov and
/// Nominatim, not to the PhamDash API), so five destinations remain, in the
/// web's order.
enum DashboardTab {
  calendar('/dashboard/calendar', 'Calendar', Icons.calendar_month_outlined,
      Icons.calendar_month),
  schedule('/dashboard', 'Schedule', Icons.event_note_outlined,
      Icons.event_note),
  lists('/dashboard/lists', 'Lists', Icons.checklist_outlined, Icons.checklist),
  birthdays('/dashboard/birthdays', 'Birthdays', Icons.cake_outlined,
      Icons.cake),
  notes('/dashboard/notes', 'Notes', Icons.sticky_note_2_outlined,
      Icons.sticky_note_2);

  const DashboardTab(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  Widget build() => switch (this) {
        DashboardTab.calendar => const CalendarGridTab(),
        DashboardTab.schedule => const ScheduleTab(),
        DashboardTab.lists => const ScheduledListsTab(),
        DashboardTab.birthdays => const BirthdaysTab(),
        DashboardTab.notes => const RecentNotesTab(),
      };
}

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = DashboardTab.values[navigationShell.currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(tab.label)),
      drawer: const _AppDrawer(),

      // Tab content is deliberately full-bleed: the mobile web dashboard
      // strips card padding, radius and shadow so each widget fills the pane.
      body: navigationShell,
      bottomNavigationBar: _BottomBar(navigationShell: navigationShell),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            // Menu — the web's first tab-bar button opens the nav drawer.
            _BarButton(
              icon: Icons.menu,
              label: 'Menu',
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
            for (final tab in DashboardTab.values)
              _BarButton(
                icon: navigationShell.currentIndex == tab.index
                    ? tab.selectedIcon
                    : tab.icon,
                label: tab.label,
                selected: navigationShell.currentIndex == tab.index,
                onTap: () => navigationShell.goBranch(
                  tab.index,
                  // Tapping the active tab returns it to its root, the
                  // conventional bottom-nav behaviour.
                  initialLocation: tab.index == navigationShell.currentIndex,
                ),
              ),
            // Theme — the web's last button toggles dark mode.
            _BarButton(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: 'Theme',
              onTap: () => ref
                  .read(themeControllerProvider.notifier)
                  .toggleDarkMode(Theme.of(context).brightness),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: Center(
            // The active icon scales up and takes the accent colour, as in the
            // web tab bar.
            child: AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                icon,
                size: 24,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PhamDash',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                  ),
                  if (user?.displayName != null || user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName ?? user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),

            // Destination order matches the web drawer. People, Spelling and
            // Family Tree are shown but disabled — they are a later phase, and
            // leaving them visible keeps the information architecture honest.
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(DashboardTab.schedule.path);
              },
            ),
            const ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('People'),
              subtitle: Text('Coming soon'),
              enabled: false,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/calendar');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Todo Lists'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/todo');
              },
            ),
            const ListTile(
              leading: Icon(Icons.spellcheck_outlined),
              title: Text('Spelling'),
              subtitle: Text('Coming soon'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.account_tree_outlined),
              title: Text('Family Tree'),
              subtitle: Text('Coming soon'),
              enabled: false,
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
