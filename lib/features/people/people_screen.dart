import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/people_models.dart';
import 'people_providers.dart';
import 'person_edit_sheet.dart';

/// The two data-hygiene filters, persisted so they survive a restart.
///
/// The web keys these in local storage under the same names; keeping the keys
/// identical is pointless across devices but costs nothing and documents where
/// the behaviour came from.
const String _missingBirthdateKey = 'peopleFilterMissingBirthdate';
const String _missingPictureKey = 'peopleFilterMissingProfilePicture';

final _searchProvider = valueProvider<String>(() => '');

class _StoredFlag extends Notifier<bool> {
  _StoredFlag(this._key);

  final String _key;

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> toggle() => set(!state);

  Future<void> set(bool value) async {
    if (state == value) return;
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final missingBirthdateFilterProvider =
    NotifierProvider<_StoredFlag, bool>(() => _StoredFlag(_missingBirthdateKey));

final missingPictureFilterProvider =
    NotifierProvider<_StoredFlag, bool>(() => _StoredFlag(_missingPictureKey));

/// Whether anything is narrowing the directory right now.
final _isFilteredProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref.watch(_searchProvider).trim().isNotEmpty ||
      ref.watch(missingBirthdateFilterProvider) ||
      ref.watch(missingPictureFilterProvider),
);

/// Drops the search text and both data-hygiene filters.
///
/// The search box watches [_searchProvider] rather than owning its text, so
/// clearing it here is enough to empty the field as well.
void _clearAll(WidgetRef ref) {
  ref.read(_searchProvider.notifier).value = '';
  ref.read(missingBirthdateFilterProvider.notifier).set(false);
  ref.read(missingPictureFilterProvider.notifier).set(false);
}

/// Orders the directory by whose birthday is next.
///
/// The API returns people by last name, then first. Re-sorting here turns the
/// screen into a "who is coming up" list, which is what it is mostly used for.
///
///  * Anyone with a birth date sorts by days until it, soonest first, so
///    today's birthday leads.
///  * Two people sharing a date fall back to last name, then first.
///  * Anyone without a birth date sinks to the bottom, alphabetically by last
///    name — a group whose order would otherwise be arbitrary, and the same
///    group the "No birthday" filter exists to help fill in.
int comparePeopleByUpcomingBirthday(Person a, Person b) {
  final daysA = a.daysUntilBirthday;
  final daysB = b.daysUntilBirthday;

  if (daysA != daysB) {
    if (daysA == null) return 1;
    if (daysB == null) return -1;
    return daysA.compareTo(daysB);
  }
  return _byName(a, b);
}

int _byName(Person a, Person b) {
  final lastName =
      a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
  if (lastName != 0) return lastName;
  return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
}

/// The directory after both filters and the search box, ordered by
/// [comparePeopleByUpcomingBirthday].
///
/// All client-side, over the single `GET /api/people` payload — there is no
/// search endpoint.
final filteredPeopleProvider = Provider.autoDispose<List<Person>>((ref) {
  final people = ref.watch(allPeopleProvider).value ?? const <Person>[];
  final search = ref.watch(_searchProvider).trim().toLowerCase();
  final missingBirthdateOnly = ref.watch(missingBirthdateFilterProvider);
  final missingPictureOnly = ref.watch(missingPictureFilterProvider);

  return people.where((person) {
    if (missingBirthdateOnly && person.birthDate != null) return false;
    if (missingPictureOnly && person.profilePictureUrl != null) return false;
    if (search.isEmpty) return true;
    return person.fullName.toLowerCase().contains(search) ||
        (person.vietnameseName ?? '').toLowerCase().contains(search);
  }).toList()
    ..sort(comparePeopleByUpcomingBirthday);
});

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(allPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          // Only offered when something is actually being hidden, so it never
          // reads as a button that does nothing.
          if (ref.watch(_isFilteredProvider))
            IconButton(
              tooltip: 'Clear search and filters',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () => _clearAll(ref),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(104),
          child: _SearchAndFilters(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add person',
        onPressed: () async {
          final created = await showPersonEditSheet(context);
          if (created != null && context.mounted) {
            context.push('/people/${created.id}');
          }
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allPeopleProvider.future),
        child: AsyncView<List<Person>>(
          value: people,
          onRetry: () => ref.invalidate(allPeopleProvider),
          emptyIcon: Icons.people_outline,
          emptyTitle: 'No people yet',
          emptyMessage: 'Add the first one with the button below.',
          builder: (_) {
            // Filtering happens outside the AsyncView so "no matches" reads as
            // a filter result rather than an empty directory.
            final matches = ref.watch(filteredPeopleProvider);
            if (matches.isEmpty) {
              return ListView(
                // A scrollable, so pull-to-refresh still works on the empty
                // state rather than dead-ending here.
                children: [
                  const SizedBox(height: 40),
                  const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Nobody matches the current search and filters.',
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _clearAll(ref),
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear search and filters'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
              itemBuilder: (context, index) =>
                  _PersonRow(person: matches[index]),
            );
          },
        ),
      ),
    );
  }
}

class _SearchAndFilters extends ConsumerStatefulWidget {
  const _SearchAndFilters();

  @override
  ConsumerState<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends ConsumerState<_SearchAndFilters> {
  /// Seeded from the provider rather than starting blank.
  ///
  /// The search outlives this widget — leaving for a person's page and coming
  /// back rebuilds the field but not the provider. An uncontrolled field would
  /// come back empty over a still-filtered list, with nothing on screen
  /// admitting a search was active.
  late final _controller = TextEditingController(text: ref.read(_searchProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Follow the provider when something else changes it — the clear button in
    // the field, or "Clear search and filters" on the empty state.
    ref.listen(_searchProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });

    // Counts are over the whole directory, not the filtered view — they say how
    // much data is missing, so filtering them would make them meaningless.
    final people = ref.watch(allPeopleProvider).value ?? const <Person>[];
    final missingBirthdate =
        people.where((p) => p.birthDate == null).length;
    final missingPicture =
        people.where((p) => p.profilePictureUrl == null).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search name or Vietnamese name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ref.watch(_searchProvider).isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        ref.read(_searchProvider.notifier).value = '';
                        FocusScope.of(context).unfocus();
                      },
                    ),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(_searchProvider.notifier).value = value,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text('No birthday ($missingBirthdate)'),
                  selected: ref.watch(missingBirthdateFilterProvider),
                  onSelected: (_) => ref
                      .read(missingBirthdateFilterProvider.notifier)
                      .toggle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: Text('No photo ($missingPicture)'),
                  selected: ref.watch(missingPictureFilterProvider),
                  onSelected: (_) =>
                      ref.read(missingPictureFilterProvider.notifier).toggle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final birthDate = person.birthDate;
    final age = person.age;
    final daysUntil = person.daysUntilBirthday;

    return ListTile(
      leading: PersonAvatar(
        storedPath: person.profilePictureUrl,
        initials: person.initials,
        size: 44,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              person.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Without this the ordering reads as arbitrary — the countdown is
          // the sort key made visible.
          if (person.birthdayCountdown case final countdown?)
            _CountdownPill(text: countdown, isToday: daysUntil == 0),
        ],
      ),
      subtitle: Text(
        [
          if (person.vietnameseName case final vietnamese?
              when vietnamese.isNotEmpty)
            vietnamese,
          if (birthDate == null)
            'No birthday'
          else
            [
              DateFormat('MMM d').format(birthDate),
              if (age != null) '$age',
            ].join(' · '),
        ].join(' · '),
        style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'edit' => showPersonEditSheet(context, person: person),
          _ => _delete(context, ref),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => context.push('/people/${person.id}'),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${person.fullName}?'),
        content: const Text(
          'Their notes and relationships go with them. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(peopleRepositoryProvider).delete(person.id);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    ref.invalidate(allPeopleProvider);
  }
}

/// The days-until pill, matching the one on the Birthdays dashboard tab.
class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.text, required this.isToday});

  final String text;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isToday ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
