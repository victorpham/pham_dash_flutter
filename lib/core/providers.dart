import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/calendar_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/picture_book_repository.dart';
import '../data/repositories/todo_repository.dart';
import '../data/repositories/weather_repository.dart';
import 'api/api_client.dart';
import 'api/server_warmup.dart';
import 'auth/auth_service.dart';
import 'cache/cache_log.dart';
import 'cache/preferences_storage.dart';

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

final personTagsRepositoryProvider = Provider(
  (ref) => PersonTagsRepository(ref.watch(apiClientProvider)),
);

final pictureBookRepositoryProvider = Provider(
  (ref) => PictureBookRepository(ref.watch(apiClientProvider)),
);

final userPreferenceRepositoryProvider = Provider(
  (ref) => UserPreferenceRepository(ref.watch(apiClientProvider)),
);

final serverWarmupProvider = Provider(
  (ref) => ServerWarmup(ref.watch(userPreferenceRepositoryProvider)),
);

/// Where `CachedList` notifiers keep their last result. Typed as the abstract
/// [Storage] so tests override it with `Storage.inMemory()`.
final cacheStorageProvider = Provider<Storage<String, String>>(
  (ref) => PreferencesStorage(
    ref.watch(sharedPreferencesProvider),
    log: ref.watch(cacheLogProvider),
  ),
);

/// Weather is not a PhamDash feature: this one talks to weather.gov and
/// Nominatim, so it takes no [ApiClient] and carries no bearer token.
final weatherRepositoryProvider = Provider((ref) => WeatherRepository());

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
        ref.watch(apiClientProvider).sessionExpired.listen((reason) {
      state = const AsyncData(null);
      _endSession(reason);
    });
    ref.onDispose(subscription.cancel);

    final user = await ref.watch(authServiceProvider).restore();
    if (user != null) await _claim(user);
    return user;
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authServiceProvider).signIn();
      await _claim(user);
      return user;
    });
  }

  Future<void> signOut() async {
    ref
        .read(cacheLogProvider)
        .record(CacheEventKind.authSignOut, '*', detail: 'from the menu');
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
    await _clearCache();
  }

  /// Hands the cache to [user], clearing it first if it was somebody else's.
  ///
  /// Doing this on sign-*in* is what lets a session that merely expired keep
  /// its saved copy while still guaranteeing that the next person to sign in on
  /// this phone never sees the last one's todo lists - see
  /// [PreferencesStorage.claimFor].
  Future<void> _claim(AuthUser user) => PreferencesStorage.claimFor(
        ref.read(sharedPreferencesProvider),
        user.id,
        log: ref.read(cacheLogProvider),
      );

  /// A session that ended without the user asking.
  ///
  /// Drops in-memory session state - the queue of people writes still on their
  /// way - but **keeps the cache**. A forced expiry is almost always the same
  /// user whose token lapsed, and the failure that causes it (a 401 the retry
  /// could not clear) tends to arrive exactly when the network is unreliable
  /// and the saved copy is the only thing the app can still show. If somebody
  /// else does sign in next, [_claim] clears it before they see anything.
  void _endSession(String reason) {
    ref.read(sessionEndedProvider.notifier).bump();
    ref.read(cacheLogProvider).record(
          CacheEventKind.sessionExpired,
          '*',
          detail: '$reason; cache kept',
        );
  }

  /// A deliberate sign-out: the phone is being handed over, so the cached
  /// lists - which are per-user - go now rather than at the next sign-in.
  Future<void> _clearCache() {
    ref.read(sessionEndedProvider.notifier).bump();
    return PreferencesStorage.clearAll(
      ref.read(sharedPreferencesProvider),
      log: ref.read(cacheLogProvider),
    );
  }
}

/// Ticks once per sign-out, whether the user asked for it or a 401 forced it.
///
/// Feature state that belongs to the signed-in session - the queue of people
/// writes still on their way, say - listens to this to drop itself. A counter
/// rather than a stream, so a listener registered in a notifier's `build` is
/// enough; and its own provider rather than a watch on [authControllerProvider],
/// because reading that one restores the session from secure storage, which
/// is nothing a widget test of a people screen should be dragged into.
final sessionEndedProvider = NotifierProvider<SessionEnded, int>(
  SessionEnded.new,
);

class SessionEnded extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
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
