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
- **Preferences are read-only in this client.** `PUT /api/user-preferences` is a
  full replace that nulls omitted fields, so writing from here would wipe the web
  app's theme. Dark mode is stored device-locally in `SharedPreferences`.

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

## Tests

Plain `flutter_test`; no mocking package. Widget tests override providers in a
`ProviderScope` and fake repositories by **subclassing** them (a repository holds a
private `ApiClient`, so `implements` won't compile) and overriding only the methods
under test. Pure logic — birthday sorting, event layout, weather parsing, date
handling, scheduled-list rules — is tested directly against the exported function.
