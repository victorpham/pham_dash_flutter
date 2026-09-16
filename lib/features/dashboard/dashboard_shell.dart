import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/theme_controller.dart';
import '../notes/recent_notes_tab.dart';
import '../schedule/schedule_tab.dart';
import '../todo/todo_lists_tab.dart';
import '../weather/weather_tab.dart';

/// The dashboard's content tabs.
///
/// The mobile web bar carries eight buttons — Menu, Weather, Calendar,
/// Schedule, Lists, Birthdays, Notes, Theme. Two have been dropped here:
/// Calendar, because the Schedule tab already covers the next seven days and
/// the full calendar — four view modes, manual sync — is a drawer destination;
/// and Birthdays, because the People screen now sorts by whose birthday is next
/// and shows the same countdown on every row. Four tab destinations remain, in
/// the web's order.
///
/// Weather is the odd one out: it reaches weather.gov and Nominatim directly
/// rather than the PhamDash API, so it is the only tab that keeps working
/// while the API is down.
///
/// Lists diverges further: on the web it is `ScheduledListsWidget.vue`, a feed
/// of only what is due in the next few minutes. Here it is the full list
/// browser that the web keeps behind a drawer link, because a list with no
/// scheduled time never reached that feed. See `TodoListsTab`.
///
/// The bar around them differs from the web's: Menu still opens the drawer and
/// People pushes a full screen, but dark mode has moved into the drawer footer,
/// where a device-local setting sits better than in a row of destinations.
enum DashboardTab {
  weather('/dashboard/weather', 'Weather', Icons.wb_cloudy_outlined,
      Icons.wb_cloudy),
  // Keeps the bare `/dashboard` path, so this stays the tab the app opens on
  // even though it is no longer the first branch.
  schedule('/dashboard', 'Schedule', Icons.event_note_outlined,
      Icons.event_note),
  lists('/dashboard/lists', 'Lists', Icons.checklist_outlined, Icons.checklist),
  notes('/dashboard/notes', 'Notes', Icons.sticky_note_2_outlined,
      Icons.sticky_note_2);

  const DashboardTab(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  Widget build() => switch (this) {
        DashboardTab.weather => const WeatherTab(),
        DashboardTab.schedule => const ScheduleTab(),
        DashboardTab.lists => const TodoListsTab(),
        DashboardTab.notes => const RecentNotesTab(),
      };

  /// The action button for this tab, if it has one.
  ///
  /// It belongs to the shell rather than the tab: the tabs render into the
  /// shell's `Scaffold`, so a tab that built its own would be nesting one
  /// Scaffold inside another just to hang a button off it.
  Widget? get floatingActionButton => switch (this) {
        DashboardTab.notes => const AddNoteButton(),
        DashboardTab.lists => const CreateListButton(),
        _ => null,
      };

  /// The app bar actions for this tab. Same reasoning as
  /// [floatingActionButton]: the shell owns the AppBar, so a tab that built one
  /// of its own would be nesting a second Scaffold to get it.
  List<Widget> get appBarActions => switch (this) {
        DashboardTab.lists => const [ShowArchivedButton()],
        _ => const [],
      };

  /// The strip under the app bar title, if this tab has one.
  PreferredSizeWidget? get appBarBottom => switch (this) {
        DashboardTab.lists => const TodoLabelFilterBar(),
        _ => null,
      };
}

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back after an hour away, every tab still shows what it loaded
    // last time and nothing refetches - so the first tap that does reach the
    // API pays the whole database resume. Ping on resume so the wake starts
    // now instead; see `ServerWarmup`. Launch needs no ping of its own: the
    // Schedule tab's first fetch is one.
    _lifecycle = AppLifecycleListener(onResume: _warmUp);
  }

  void _warmUp() {
    // The shell only mounts behind the router's auth redirect, but a ping
    // with no session would 401, fail the refresh, and emit `sessionExpired`
    // - so never send one without a user.
    if (ref.read(authControllerProvider).value == null) return;
    ref.read(serverWarmupProvider).ping();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final tab = DashboardTab.values[navigationShell.currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label),
        actions: tab.appBarActions,
        bottom: tab.appBarBottom,
      ),
      drawer: const _AppDrawer(),

      // Tab content is deliberately full-bleed: the mobile web dashboard
      // strips card padding, radius and shadow so each widget fills the pane.
      body: navigationShell,
      floatingActionButton: tab.floatingActionButton,
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
            // People is a push, not a branch: it is a full screen with its own
            // app bar, search and FAB rather than a dashboard widget, so it
            // never reads as "selected" here.
            _BarButton(
              icon: Icons.people_outline,
              label: 'People',
              onTap: () => context.push('/people'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

            // Destination order matches the web drawer, less its Todo Lists
            // row: that page is the Lists tab now, one tap away in the bar
            // below. Spelling and Family Tree are shown but disabled — they are
            // a later phase, and leaving them visible keeps the information
            // architecture honest.
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(DashboardTab.schedule.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('People'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/people');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/calendar');
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
            // Dark mode is a device-local setting, not a destination — the
            // drawer's footer is where it belongs rather than spending a slot
            // in the tab bar.
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              ),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (_) => ref
                  .read(themeControllerProvider.notifier)
                  .toggleDarkMode(Theme.of(context).brightness),
            ),
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
