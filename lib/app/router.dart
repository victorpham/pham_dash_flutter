import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/calendar/calendar_screen.dart';
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
    ],
  );
});
