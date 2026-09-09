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

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final missingBirthdateFilterProvider =
    NotifierProvider<_StoredFlag, bool>(() => _StoredFlag(_missingBirthdateKey));

final missingPictureFilterProvider =
    NotifierProvider<_StoredFlag, bool>(() => _StoredFlag(_missingPictureKey));

/// The directory after both filters and the search box.
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
  }).toList();
});

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(allPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
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
              return const EmptyStateView(
                icon: Icons.search_off,
                title: 'No matches',
                message: 'Try a different search, or clear the filters.',
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

class _SearchAndFilters extends ConsumerWidget {
  const _SearchAndFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            decoration: const InputDecoration(
              hintText: 'Search name or Vietnamese name',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
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

    return ListTile(
      leading: PersonAvatar(
        storedPath: person.profilePictureUrl,
        initials: person.initials,
        size: 44,
      ),
      title: Text(
        person.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
              DateFormat('MMM d, y').format(birthDate),
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
