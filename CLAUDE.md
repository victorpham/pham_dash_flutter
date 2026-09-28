# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter client for **PhamDash**, a single-family dashboard. It exists to give the
existing PhamDash web app an Android phone client. The backend and web frontend it
talks to are a separate solution on this machine, not vendored here:

**`D:\Development\PhamDash`** — read its own `CLAUDE.md` first when a question is
about server behaviour. What lives there:

| Path | What it is |
|---|---|
| `PhamDash.API/` | ASP.NET Core (.NET 10) + EF Core + SQL Server — the API this app calls. `Controllers/` is the endpoint contract; `Mappings/DtoMapper.cs` is the wire shape. |
| `PhamDash.UI/sakai-vue/` | The Vue 3 SPA this client is modelled on. `src/service/*.js`, `src/utils/httpClient.js`, and the `Mobile*` views. |
| `PhamDashAndroid/` | The earlier Kotlin / Compose client. Prior art this code frequently compares itself against. |
| `docs/API_AND_FRONTEND_REFERENCE.md` | ~900 lines of endpoint-by-endpoint contract, written so a mobile client could be built against it. The **first place to look** for a payload shape or a validation rule. |
| `Instructions/` | Dated per-feature implementation notes (an Obsidian vault) — why a feature is shaped the way it is. |

Two cautions. Those docs are point-in-time snapshots and drift — the reference doc
says there is no health controller, but `PhamDash.API/Controllers/HealthController.cs`
exists now; confirm anything load-bearing against the C# source. And **rules the web
client enforces in JavaScript are not enforced by the API** — the reference doc calls
those out, and this client has to re-implement each one itself.

For a full local stack, `dotnet run` in `PhamDash.API/` serves `http://localhost:5100`,
which is what this app's default `API_ORIGIN` of `http://10.0.2.2:5100` reaches from
the Android emulator. Port 5239 appears in older client config and in the Kotlin app —
it is stale, and nothing listens there.

Much of this project's code deliberately mirrors, or deliberately diverges from, the
web and Kotlin clients; the doc comments say which. Read them before changing
behaviour that looks arbitrary.

## Commands

```powershell
flutter pub get
flutter analyze                      # lints; analysis_options.yaml excludes build/ and platform dirs
flutter test                         # all tests
flutter test test/api_date_test.dart # one file
flutter test test/people_birthday_sort_test.dart --plain-name "a birthday today is zero"  # one test/group
flutter run                          # defaults API_ORIGIN to http://10.0.2.2:5100 (Android emulator)
flutter run --dart-define=API_ORIGIN=http://192.168.1.20:5100   # physical device: host LAN address
flutter run --dart-define=API_ORIGIN=http://localhost:5100      # iOS simulator
dart run build_runner build --delete-conflicting-outputs        # after editing any model in lib/data/models/
```

`*.freezed.dart` / `*.g.dart` are **committed**, so regenerate and commit them
alongside model changes. `riverpod_generator` is in `dev_dependencies` but unused —
every provider in this project is written by hand.

## Architecture

Layering is `feature widget → provider → repository → ApiClient`. Widgets never
touch Dio, and repositories never touch Riverpod.

- **`lib/core/`** — cross-cutting infrastructure: API client, auth, config, theme,
  shared UI (`AsyncView`, `PersonAvatar`, `PersonPicker`).
- **`lib/data/models/`** — Freezed + `json_serializable` wire models, one file per
  API area, with hand-written converters in `converters.dart`.
- **`lib/data/repositories/`** — thin endpoint wrappers returning models. Decoding
  goes through `decode.dart` (`decodeList` / `decodeOrNull` / `decodeRequired`),
  which tolerates the null payloads `ApiClient` produces for `204`.
- **`lib/features/<area>/`** — screens plus their feature-local providers
  (`*_providers.dart`, `*_controller.dart`).
- **`lib/core/providers.dart`** — the composition root: `sharedPreferencesProvider`
  (overridden in `main()` so it reads synchronously), `apiClientProvider`, one
  provider per repository, and `AuthController`.

### Things that will bite you

- **Two kinds of timestamp.** The API is .NET and serializes most `DateTime`s with
  no zone marker. `calendarEvent.start`/`end`, `person.birthDate` and
  `todoList.reminderDateTime` are **wall-clock** readings and must not be shifted;
  `createdAt`/`updatedAt`/`completedAt` are **UTC instants** missing their `Z`.
  Always go through `ApiDate` / the `WallClock` and `UtcStamp` converters — never
  `DateTime.parse` an API string directly. `lib/core/api/api_date.dart` explains why.
- **The bearer is the ID token, not the access token.** See `AuthService`.
- **401 contract:** `ApiClient` force-refreshes and retries a request exactly once;
  a second 401 signs out and emits on `sessionExpired`, which `AuthController`
  turns into a router redirect. Pass `noAuthKey` in `extra` to opt a request out.
  **A refresh that never reached the IdP is not a second 401.** `AuthService._refresh`
  returns null only when the session is genuinely over (nothing to renew with, or an
  OAuth error code back from the server) and throws `NetworkException` otherwise;
  `ApiClient` reports that and leaves the user signed in. The bare `catch` this
  replaced made a dropped connection look like a revoked token, and the sign-out that
  followed wiped the whole offline cache — see `PreferencesStorage.claimFor`.
- **Media URLs are signed.** `AppConfig.apiOrigin` is the server root *without*
  `/api`; `AppConfig.mediaUrl` re-hosts a stored path against it. The query string
  (`?exp=&sig=`) is the credential — dropping it turns every avatar into a 401.
  Paths outside `/uploads/` return null on purpose; callers fall back to initials.
- **Error bodies are not uniform.** `ApiClient.messageFromBody` degrades through
  `{message}` → validation-problem `errors` → bare-string body → status code.
  Repositories throw `ApiException` (`isConflict`/`isNotFound` are load-bearing on
  forms), `SessionExpiredException`, or `NetworkException`.
- **Enums on the wire:** `AttendanceStatus` is a string; every other enum,
  including `RelationshipType`, is an integer.
- **People are not user-scoped.** `Person`, notes and relationships have no
  `UserId` — every authenticated user sees the same directory.
- **Weather is off-API.** `WeatherRepository` talks to weather.gov and Nominatim
  directly, takes no `ApiClient`, and must not carry the bearer token; it needs its
  own `User-Agent`. It is the one tab that works while the API is down.
- **The production database naps.** Azure SQL serverless auto-pauses after an
  hour idle and takes tens of seconds to resume; the API holds the request open
  meanwhile. `ServerWarmup` pings on app resume and `PatientLoading` explains
  the wait after 5 s. `GET /health` is deliberately dependency-free and wakes
  nothing - the ping is `GET /api/user-preferences`.
- **The nine list providers behind a first screen are cached.** `CachedList`
  (`lib/core/cache/`) uses Riverpod 3's *experimental* `persist` over a
  `SharedPreferences` `Storage`; a cold launch renders the last result under a
  thin bar while the fetch runs. `PreferencesStorage.delete` deliberately keeps
  unexpired entries, because Riverpod deletes on provider error and a failed
  wake is exactly when the saved copy matters. `AsyncView` keeps data on error
  (banner + Retry) rather than swapping to the error view. **Riverpod reads the
  store only at an element's first build** (`ref.isFirstBuild`), so an
  invalidate, a refresh or a changed dependency never re-seeds — what holds
  data on screen after that is `copyWithPrevious`. A screen that can arrive
  with neither wants `cachedSeedOf` + `AsyncView.fallback`, which the Schedule,
  Lists and Notes tabs pass. The seed also tolerates a single unreadable row
  (`tolerantDecodeList`, for a cached copy written before a model changed) while
  the API path (`decodeList`) stays strict. **An explicit sign-out clears the
  cache; a forced session expiry does not** — `PreferencesStorage.claimFor`
  records the owning user id on sign-in and clears only when it changes, which
  keeps the per-user guarantee without losing offline data to a lapsed token.
  Every outcome goes to `CacheLog` and the drawer's "Cache diagnostics" screen,
  because all of these paths used to fail silently. Tests override
  `cacheStorageProvider` with `Storage.inMemory()`, and
  the cached providers are notifiers, so fake them with `overrideWithBuild`.
  Detail screens are not cached separately: the todo list detail and the
  person header pass the matching record from the lists / people cache as
  `AsyncView.fallback`, which renders it like a seed while the real fetch runs
  (`AsyncValue.copyWithPrevious` is `@internal`, so this is the public route).
  The person page's Relationships and Notes sections do the same inline
  (`_SectionBody`) from two whole-table caches, `allNotesProvider` and
  `allRelationshipsProvider` (`GET /api/notes`, `GET /api/relationships` —
  added to the API for this; the per-person providers stay authoritative and
  an API without those routes just degrades to the old spinner). Pictures are
  a per-person `CachedList` family (`pictures:<id>`), no bulk route. The API
  has no delta support, so "check for new data" is a full refetch:
  `StaleRefresh` re-reads the four keep-alive directory caches on launch,
  resume and People-list open when older than 15 min, chained behind
  `ServerWarmup.ping()`. Android backup is off (`allowBackup="false"`) so the
  cache never leaves the device.
- **Preferences are read-only in this client.** `PUT /api/user-preferences` is a
  full replace that nulls omitted fields, so writing from here would wipe the web
  app's theme. Dark mode is stored device-locally in `SharedPreferences`, and so
  is the per-list "shopping list" sort (`shoppingSortedListsProvider`, one key
  holding the list ids, cleared on sign-out by `PreferencesStorage.clearAll`) —
  the API has no sort field on a list, and the sort is presentation only:
  `TodoList.shoppingSorted` never touches `displayOrder`.

### Routing

`go_router` in `lib/app/router.dart`. A `StatefulShellRoute.indexedStack` drives the
four `DashboardTab`s (each tab keeps its state), with `/calendar`, `/people`,
`/people/:id` and `/todo/:id` pushed on top. `redirect` stays silent while the
stored session is still loading, stashes the attempted path in `_pendingDestination`,
and returns to it after login. Person pages stack on each other through relationship
rows, so they all carry `personPageName` to be popped as a group.

### Async UI

Route every async screen through `AsyncView`, which renders the loading / error /
empty triad (and `ErrorStateView` knows how to show an `ApiException` message).
After a write, invalidate rather than patch local state — see `invalidatePerson`,
which exists because one relationship write fans out into several server-side rows.
The one exception is `TodoListDetailNotifier` (and `TodoListsNotifier.togglePin`):
the shopping list is used while the database is asleep, so item writes patch
state first, splice in the server's answer, and roll back on failure. Route new
item writes through its methods and `_tryWrite`, not the repository.

The three people-directory **creates** (person, note, relationship) go through
`PendingCreates` (`lib/features/people/pending_creates.dart`) instead of the
repository: the sheet closes at once and the record shows while the request runs.
It is an *overlay*, not a cache patch — the per-person providers are plain
`FutureProvider`s with nothing to patch — so every list that can show one of these
merges the queue's entries in at render time (`pendingPeopleNotIn`,
`pendingNotesFor`, `pendingRelationshipsFor`) and drops a `done` entry once the
fetched list contains it. A new person has a `pending-<n>` id until the server
answers (a hyphen never appears in a server id); `/people/pending-1` is a real
route that renders the placeholder, and notes/relationships queued on that page
wait for the person and take its real id. In memory only and cleared on sign-out
(`sessionEndedProvider`): a create whose response was lost may have landed, so
nothing is replayed on launch. Failures stay as "couldn't save" with Retry /
Discard, and their count drives the red state of `SyncIndicator`
(`PendingWrites.failed`). The write on the *edit* path, and every update/delete,
still awaits the repository directly.

## Tests

Plain `flutter_test`; no mocking package. Widget tests override providers in a
`ProviderScope` and fake repositories by **subclassing** them (a repository holds a
private `ApiClient`, so `implements` won't compile) and overriding only the methods
under test. Pure logic — birthday sorting, event layout, weather parsing, date
handling — is tested directly against the exported function.
