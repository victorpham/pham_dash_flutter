import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/calendar_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/todo_repository.dart';
import 'api/api_client.dart';
import 'auth/auth_service.dart';

/// Overridden in `main()` once `SharedPreferences` has loaded, so the rest of
/// the app can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(authServiceProvider));
  ref.onDispose(client.dispose);
  return client;
});

final calendarRepositoryProvider = Provider(
  (ref) => CalendarRepository(ref.watch(apiClientProvider)),
);

final eventCategoryRepositoryProvider = Provider(
  (ref) => EventCategoryRepository(ref.watch(apiClientProvider)),
);

final todoRepositoryProvider = Provider(
  (ref) => TodoRepository(ref.watch(apiClientProvider)),
);

final peopleRepositoryProvider = Provider(
  (ref) => PeopleRepository(ref.watch(apiClientProvider)),
);

final notesRepositoryProvider = Provider(
  (ref) => NotesRepository(ref.watch(apiClientProvider)),
);

final relationshipsRepositoryProvider = Provider(
  (ref) => RelationshipsRepository(ref.watch(apiClientProvider)),
);

final userPreferenceRepositoryProvider = Provider(
  (ref) => UserPreferenceRepository(ref.watch(apiClientProvider)),
);

/// The signed-in user, or null.
///
/// Seeded from secure storage at startup so a returning user does not see the
/// login screen flash before their session is restored.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // The API client signs the user out when a 401 survives the retry; reflect
    // that here so the router redirects.
    final subscription =
        ref.watch(apiClientProvider).sessionExpired.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(subscription.cancel);

    return ref.watch(authServiceProvider).restore();
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(),
    );
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

/// A plain mutable value, replacing Riverpod 2's `StateProvider` (removed in 3).
///
/// Used for small pieces of UI state — the calendar's anchor date, its view
/// mode, the "hide Tu meetings" toggle — where a full notifier class would be
/// noise.
class SimpleValue<T> extends Notifier<T> {
  SimpleValue(this._initial);

  final T Function() _initial;

  @override
  T build() => _initial();

  set value(T next) => state = next;

  T get value => state;
}

/// Convenience constructor for a [SimpleValue] provider.
NotifierProvider<SimpleValue<T>, T> valueProvider<T>(T Function() initial) =>
    NotifierProvider<SimpleValue<T>, T>(() => SimpleValue<T>(initial));
