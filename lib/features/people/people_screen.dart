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
import 'person_tag_counts.dart';
import 'person_tags_sheet.dart';

/// The two data-hygiene filters, persisted so they survive a restart.
///
/// The web keys these in local storage under the same names; keeping the keys
/// identical is pointless across devices but costs nothing and documents where
/// the behaviour came from.
const String _missingBirthdateKey = 'peopleFilterMissingBirthdate';
const String _missingPictureKey = 'peopleFilterMissingProfilePicture';

final _searchProvider = valueProvider<String>(() => '');

/// The tag the directory is narrowed to, or null for "all tags".
///
/// Public so `person_tags_sheet.dart` can clear it after deleting a tag.
///
/// Deliberately **not** persisted, unlike the two data-hygiene flags above:
/// those are work queues you want back after a restart, a tag filter is a lens.
/// A persisted one would also come back pointing at a tag somebody deleted on
/// the web in the meantime.
final tagFilterProvider = valueProvider<int?>(() => null);

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
      ref.watch(missingPictureFilterProvider) ||
      ref.watch(tagFilterProvider) != null,
);

/// Drops the search text and both data-hygiene filters.
///
/// The search box watches [_searchProvider] rather than owning its text, so
/// clearing it here is enough to empty the field as well.
void _clearAll(WidgetRef ref) {
  ref.read(_searchProvider.notifier).value = '';
  ref.read(missingBirthdateFilterProvider.notifier).set(false);
  ref.read(missingPictureFilterProvider.notifier).set(false);
  ref.read(tagFilterProvider.notifier).value = null;
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
  final tagId = ref.watch(tagFilterProvider);

  return people.where((person) {
    if (missingBirthdateOnly && person.birthDate != null) return false;
    if (missingPictureOnly && person.profilePictureUrl != null) return false;
    if (tagId != null && !person.hasTag(tagId)) return false;
    if (search.isEmpty) return true;
    return person.fullName.toLowerCase().contains(search) ||
        (person.vietnameseName ?? '').toLowerCase().contains(search);
  }).toList()
    ..sort(comparePeopleByUpcomingBirthday);
});

/// The search box plus the two data-hygiene chips.
const double _filtersHeight = 104;

/// ...plus the tag filter bar, which is only built when tags exist — reserving
/// the row unconditionally would leave 46px of dead space under the search box
/// for anyone who has not made a tag yet.
const double _filtersHeightWithTags = 150;

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(allPeopleProvider);
    final hasTags =
        (ref.watch(personTagsProvider).value ?? const []).isNotEmpty;

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
          // Permanent, because the filter bar below disappears when there are
          // no tags — this is how the first one gets made.
          IconButton(
            tooltip: 'Manage tags',
            icon: const Icon(Icons.sell_outlined),
            onPressed: () => showPersonTagsSheet(context),
          ),
        ],
        bottom: PreferredSize(
          // Grows one frame late on first open, while the vocabulary loads.
          preferredSize: Size.fromHeight(
            hasTags ? _filtersHeightWithTags : _filtersHeight,
          ),
          child: const _SearchAndFilters(),
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
          const _TagFilterBar(),
        ],
      ),
    );
  }
}

/// Narrows the directory to one tag.
///
/// Modelled on the todo screen's label bar, with one difference: the counts are
/// derived from the loaded directory rather than read off `tag.personCount`.
/// See [PersonTagCounts] for why.
class _TagFilterBar extends ConsumerWidget {
  const _TagFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(personTagsProvider).value ?? const <PersonTag>[];
    // Nothing at all rather than an empty 46px strip — PeopleScreen sizes the
    // app bar on the same condition.
    if (tags.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(tagFilterProvider);
    final counts = PersonTagCounts.from(
      ref.watch(allPeopleProvider).value ?? const <Person>[],
    );

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(tagFilterProvider.notifier).value = null,
            ),
          ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${tag.name} (${counts.of(tag.id)})'),
                // Compares against the loaded vocabulary, so a filter left
                // pointing at a tag deleted elsewhere simply shows nothing
                // selected. Checked passively — never write to a provider from
                // a build method.
                selected: selected == tag.id,
                backgroundColor: parseHexColor(tag.color),
                onSelected: (isSelected) => ref
                    .read(tagFilterProvider.notifier)
                    .value = isSelected ? tag.id : null,
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.tune, size: 16),
            label: const Text('Manage'),
            onPressed: () => showPersonTagsSheet(context),
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
    // The sort already floats today's birthdays to the top; this is what says
    // *why* they are up there. Three signals, because one pill is easy to skim
    // past: a tinted row, a cake on the avatar, and a filled pill.
    final isBirthday = daysUntil == 0;

    return ListTile(
      tileColor: isBirthday ? scheme.primary.withValues(alpha: 0.09) : null,
      leading: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PersonAvatar(
              storedPath: person.profilePictureUrl,
              initials: person.initials,
              size: 44,
            ),
            if (isBirthday)
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    // Rings the badge against the avatar behind it, which may
                    // be a photo of any colour.
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                  child: Icon(
                    Icons.cake,
                    size: 11,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
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
            _CountdownPill(text: countdown, isToday: isBirthday),
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
              // `age` has already rolled over by the time the day arrives, so
              // on a birthday it is the age being turned.
              if (age != null) isBirthday ? 'turns $age today' : '$age',
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

/// The days-until pill.
///
/// A tinted pill for anyone upcoming, as on the Birthdays dashboard tab. It
/// diverges on the day itself: a filled pill reading `Birthday today`, because
/// this list is read at a glance and a faint `Today!` is easy to miss.
class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.text, required this.isToday});

  final String text;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isToday ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isToday ? 9 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: isToday ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            Icon(Icons.cake, size: 12, color: scheme.onPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            isToday ? 'Birthday today' : text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isToday ? scheme.onPrimary : color,
            ),
          ),
        ],
      ),
    );
  }
}
