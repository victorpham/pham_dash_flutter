import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/cache_diagnostics_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/login/login_screen.dart';
import '../features/people/people_screen.dart';
import '../features/people/person_detail_screen.dart';
import '../features/todo/todo_list_detail_screen.dart';

/// Where to send the user once they finish signing in.
///
/// Mirrors the web router's behaviour: an unauthenticated navigation stores the
/// attempted path and returns to it after login, instead of always dumping the
/// user on the dashboard.
final _pendingDestination = ValueNotifier<String?>(null);

/// The `RouteSettings.name` carried by every `/people/:id` page.
///
/// Person pages stack on each other through the relationship rows, so they need
/// to be identifiable as a group to be popped as one.
const String personPageName = 'person-detail';

/// The people list's location, as matched by the router.
const String peopleListLocation = '/people';

/// Shows the people list, dropping any chain of person pages above it.
///
/// Popping to the list is preferred over navigating to it, so that whatever sat
/// underneath — the dashboard, usually — survives as the back target. With no
/// list beneath (from the dashboard, or a chain that began at a birthday row or
/// a recent note) one is pushed instead; on the list itself this does nothing.
/// That is what lets the bottom bar's People button and the drawer's People
/// row behave the same from every screen.
void showPeopleList(BuildContext context) {
  final router = GoRouter.of(context);
  final listIsBelow = router.routerDelegate.currentConfiguration.matches
      .any((match) => match.matchedLocation == peopleListLocation);

  Navigator.of(context).popUntil(
    // `isFirst` guards the case where a person page is the whole stack, as a
    // deep link would leave it — popping that far would empty the navigator.
    (route) => route.isFirst || route.settings.name != personPageName,
  );

  if (!listIsBelow) router.push(peopleListLocation);
}

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuilding the router on every auth change would lose navigation state, so
  // instead we expose auth as a Listenable and let go_router re-run `redirect`.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // Say nothing until the stored session has been read back, so a returning
      // user does not see the login screen flash before being restored.
      if (auth.isLoading && !auth.hasValue) return null;

      final signedIn = auth.value != null;
      final atLogin = state.matchedLocation == '/login';

      if (!signedIn) {
        if (atLogin) return null;
        _pendingDestination.value = state.uri.toString();
        return '/login';
      }

      if (atLogin) {
        final pending = _pendingDestination.value;
        _pendingDestination.value = null;
        return pending ?? '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // The five dashboard tabs. An indexed stack keeps each tab's state alive
      // across switches, matching the <KeepAlive> the mobile web layout wraps
      // its widgets in.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DashboardShell(navigationShell: navigationShell),
        branches: [
          for (final tab in DashboardTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => tab.build(),
                ),
              ],
            ),
        ],
      ),

      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/people',
        builder: (context, state) => const PeopleScreen(),
      ),
      // Pushed from the people list, the birthdays and notes tabs, and from one
      // relationship row to another — so it is reachable without /people ever
      // having been opened.
      //
      // The page is named because relationships stack person on person without
      // limit, and unwinding that a tap at a time is the thing users complain
      // about. [personPageName] is what lets one action drop the whole chain.
      GoRoute(
        path: '/people/:id',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          name: personPageName,
          child: PersonDetailScreen(
            personId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/todo/:id',
        builder: (context, state) => TodoListDetailScreen(
          listId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // Reached from the drawer footer. Not a destination anyone browses to —
      // it is what to open when a tab came up empty and the question is why.
      GoRoute(
        path: '/cache',
        builder: (context, state) => const CacheDiagnosticsScreen(),
      ),
    ],
  );
});
