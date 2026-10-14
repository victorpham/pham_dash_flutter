import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/cache/freshness.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../core/ui/person_picker.dart';
import '../../core/ui/sync_indicator.dart';
import '../../data/models/converters.dart';
import '../../data/models/people_models.dart';
import '../dashboard/dashboard_shell.dart';
import '../notes/recent_notes_tab.dart';
import 'pending_creates.dart';
import 'pending_status.dart';
import 'people_providers.dart';
import 'person_edit_sheet.dart';
import 'person_picture_gallery.dart';
import 'person_tags_sheet.dart';
import 'home_address.dart';
import 'relationship_groups.dart';

/// A note younger than this is badged "New", as on the web timeline.
const Duration _recentNoteWindow = Duration(days: 7);

/// How many `/people/:id` pages are currently stacked.
///
/// Following relationships pushes one person page onto another with no limit,
/// and the count is what says whether the user is deep enough to need an
/// escape hatch.
int _personPagesInStack(BuildContext context) => GoRouter.of(context)
    .routerDelegate
    .currentConfiguration
    .matches
    .where((match) => match.matchedLocation.startsWith('$peopleListLocation/'))
    .length;

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The route may name a person who does not exist yet: `/people/pending-1`
    // is where the People list sends the user the moment "Add person" closes.
    // Until the create lands the page is the placeholder from the queue, and
    // nothing here fetches - `GET /people/pending-1` would only 404. Once it
    // lands the id resolves and the page is an ordinary one for the real id;
    // the route itself keeps the temp id, which nothing minds.
    ref.watch(pendingCreatesProvider);
    final queue = ref.read(pendingCreatesProvider.notifier);
    final id = queue.resolve(personId);
    final pending = isPendingPersonId(id) ? queue.person(id) : null;
    final isPlaceholder = isPendingPersonId(id);

    final AsyncValue<Person?> person;
    final Person? cached;
    if (isPlaceholder) {
      // Null when the placeholder has been discarded: "Person not found".
      person = AsyncData(pending?.placeholder);
      cached = null;
    } else {
      person = ref.watch(personProvider(id));
      // The directory cache already holds this person; show them from there
      // while the fetch waits on the database. A person who has just landed
      // is not in the directory yet - the placeholder stands in until the
      // first real fetch, so the page does not blink to a spinner between.
      cached = ref
              .watch(allPeopleProvider)
              .value
              ?.where((candidate) => candidate.id == id)
              .firstOrNull ??
          queue.person(personId)?.placeholder.copyWith(id: id);
    }

    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: DashboardBottomBar.people(context),
      appBar: AppBar(
        // A Scaffold with a drawer swaps the back arrow for a hamburger; the
        // bar's Menu button already opens the drawer, so keep back here.
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(person.value?.fullName ?? 'Person'),
        actions: [
          SyncIndicator(onFailedTap: () => showFailedChangesSheet(context)),
          // Only once a chain has formed. On the first person page the ordinary
          // back button already does this, and a second button that behaves
          // identically is just noise.
          if (_personPagesInStack(context) > 1)
            IconButton(
              tooltip: 'Back to the people list',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => showPeopleList(context),
            ),
          // Nothing to edit until the server has the person: the edit sheet
          // writes to `PUT /people/{id}`, and there is no id yet.
          if (person.value != null && !isPlaceholder)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showPersonEditSheet(context, person: person.value),
            ),
        ],
      ),
      body: AsyncView<Person?>(
        value: person,
        fallback: cached,
        // The header is the directory's copy until the person's own fetch
        // lands, so its stamp is the honest one to show meanwhile.
        updatedAt: isPlaceholder ? null : freshnessOf(ref, 'people'),
        onRetry: () => ref.invalidate(personProvider(id)),
        isEmpty: (data) => data == null,
        emptyIcon: Icons.person_off_outlined,
        emptyTitle: 'Person not found',
        builder: (data) => RefreshIndicator(
          onRefresh: () async {
            if (isPlaceholder) return;
            invalidatePerson(ref, id);
            await ref.read(personProvider(id).future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              if (pending != null) _PendingPersonBanner(entry: pending),
              _Header(person: data!, pending: pending),
              // Attached to the header rather than fenced off with a divider:
              // tags are an attribute of the person, not a section of records
              // peer to Relationships and Notes.
              _TagsRow(person: data, readOnly: isPlaceholder),
              const Divider(height: 32),
              _RelationshipsSection(person: data, isPlaceholder: isPlaceholder),
              const Divider(height: 32),
              _NotesSection(
                personId: id,
                firstName: data.firstName,
                isPlaceholder: isPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sits above the header of a person whose create is still out or has failed.
///
/// While sending it also says what the page is for meanwhile - notes and
/// relationships added here wait for the person and go once it exists - since
/// nothing else on the page hints that this is allowed. A discard pops the
/// page: the person it showed no longer exists anywhere.
class _PendingPersonBanner extends StatelessWidget {
  const _PendingPersonBanner({required this.entry});

  final PendingPerson entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('pending-person-banner'),
      width: double.infinity,
      color: entry.isFailed
          ? scheme.errorContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PendingStatusLine(
            entry: entry,
            onDiscarded: () => Navigator.of(context).maybePop(),
          ),
          if (entry.isSending) ...[
            const SizedBox(height: 4),
            Text(
              'Notes and relationships you add now are saved once '
              '${entry.placeholder.firstName} is.',
              style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.person, this.pending});

  final Person person;

  /// Set while the person is still the queue's placeholder: the avatar shows
  /// the picture chosen on the sheet, and the gallery - keyed by a server id
  /// there is not yet - stays shut.
  final PendingPerson? pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final birthDate = person.birthDate;
    final age = person.age;
    final address = person.homeAddress?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Tapping the avatar opens the gallery. The picture is the obvious
            // thing to reach for when you want to change the picture, and it
            // saves a trip through the edit sheet to get there.
            Semantics(
              button: true,
              label: 'Pictures of ${person.fullName}',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: pending != null
                    ? null
                    : () => showPersonPictureGallery(context, person: person),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    PersonAvatar(
                      storedPath: person.profilePictureUrl,
                      localPath: pending?.picturePath,
                      initials: person.initials,
                      size: 72,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 12,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (person.vietnameseName case final vietnamese?
                      when vietnamese.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      vietnamese,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 15,
                        color: scheme.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          birthDate == null
                              ? 'No birth date'
                              : [
                                  DateFormat('MMMM d, y').format(birthDate),
                                  if (age != null) '$age years old',
                                ].join(' · '),
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
          // Full width under the avatar rather than beside it: the column next
          // to a 72px avatar is too narrow for an address plus two affordances,
          // and a wrapped three-line address there reads badly.
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HomeAddressRow(address: address),
          ],
        ],
      ),
    );
  }
}

// --- relationships ---------------------------------------------------------

class _RelationshipsSection extends ConsumerWidget {
  const _RelationshipsSection({
    required this.person,
    required this.isPlaceholder,
  });

  final Person person;

  /// The person is still the queue's placeholder: nothing is fetched for
  /// them, and the section is the queued relationships alone.
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationships = isPlaceholder
        ? const AsyncData(<Relationship>[])
        : ref.watch(personRelationshipsProvider(person.id));
    // The bulk table seeds the section, and is also where the parents' own
    // rows - the grandparents - come from. Nothing shows for them until it
    // has loaded, or on an API without the route.
    final everyone = ref.watch(allRelationshipsProvider);
    final fallback = isPlaceholder
        ? null
        : relationshipsFor(everyone, person.id);
    final queue = ref.watch(pendingCreatesProvider);
    final resolve = ref.read(pendingCreatesProvider.notifier).resolve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Relationships',
          action: IconButton(
            tooltip: 'Add relationship',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => _add(context, ref),
          ),
        ),
        _SectionBody<Relationship>(
          value: relationships,
          fallback: fallback,
          builder: (data) {
            // Queued rows first, drawn among the fetched ones by group so a
            // pending spouse sits where the real one will.
            final pending = pendingRelationshipsFor(
              queue,
              person.id,
              shown: data,
              resolve: resolve,
            );
            return _RelationshipList(
              personId: person.id,
              groups: RelationshipGroups.from([
                for (final e in pending) e.placeholder,
                ...data,
              ], everyone: everyone.value ?? const []),
              pending: {for (final e in pending) e.placeholder.relationshipId: e},
            );
          },
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    // The cached directory is good enough for a picker, and after an hour
    // idle the fetch behind `.future` is the database wake itself.
    final List<Person> people = ref.read(allPeopleProvider).value ??
        await ref.read(allPeopleProvider.future);
    final queue = ref.read(pendingCreatesProvider.notifier);
    // The cached slice stands in while the person's own fetch is pending, so
    // the picker hides already-related people from the first tap - and so do
    // the relationships queued but not yet landed.
    final existing = [
      ...?(isPlaceholder
          ? null
          : ref.read(personRelationshipsProvider(person.id)).value ??
              relationshipsFor(ref.read(allRelationshipsProvider), person.id)),
      for (final e in pendingRelationshipsFor(
        ref.read(pendingCreatesProvider),
        person.id,
        shown: const [],
        resolve: queue.resolve,
      ))
        e.placeholder,
    ];

    // The web dropdown offers neither this person nor anyone already related to
    // them, which keeps the two guaranteed 400s off the menu.
    final related = existing.map((r) => r.relatedPersonId).toSet();
    final candidates = people
        .where((p) => p.id != person.id && !related.contains(p.id))
        .toList();

    if (!context.mounted) return;
    if (candidates.isEmpty) {
      _toast(context, 'Everyone is already related to ${person.firstName}.');
      return;
    }

    final selected = await pickPerson(
      context,
      people: candidates,
      title: 'Search people',
    );
    if (selected == null || !context.mounted) return;

    final type = await showModalBottomSheet<RelationshipType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${selected.fullName} is this person’s…',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final type in RelationshipType.values)
              ListTile(
                title: Text(type.label),
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;

    // Queued, not awaited: the row appears now and the queue re-reads both
    // people when the server answers - one create can write several rows (the
    // inverse, the whole sibling group, a spouse's copy of a child link), so
    // nothing is patched. A failure stays on the row with Retry and Discard.
    queue.addRelationship(
      person.id,
      related: selected,
      type: type,
      personName: person.firstName,
    );
  }
}

class _RelationshipList extends ConsumerWidget {
  const _RelationshipList({
    required this.personId,
    required this.groups,
    this.pending = const {},
  });

  final String personId;
  final RelationshipGroups groups;

  /// Queue entries by their placeholder's (negative) id, for the rows that
  /// are not the server's yet.
  final Map<int, PendingRelationship> pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groups.isEmpty) {
      return const _Message('No relationships recorded yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.hasImmediateFamily) ...[
          const _SubHeader('Immediate family'),
          if (groups.spouse case final spouse?)
            _RelationshipRow(
              personId: personId,
              relationship: spouse,
              pending: pending[spouse.relationshipId],
            ),
          for (final child in groups.children)
            _RelationshipRow(
              personId: personId,
              relationship: child,
              pending: pending[child.relationshipId],
            ),
        ],
        if (groups.otherCount > 0) ...[
          _SubHeader('Other relationships (${groups.otherCount})'),
          for (final row in groups.otherRows)
            _RelationshipRow(
              personId: personId,
              relationship: row.relationship,
              derived: row.derived,
              // A derived row is a server row of the parent's, never the
              // queue's; its id would not collide with a placeholder anyway.
              pending: row.derived
                  ? null
                  : pending[row.relationship.relationshipId],
            ),
        ],
      ],
    );
  }
}

class _RelationshipRow extends ConsumerWidget {
  const _RelationshipRow({
    required this.personId,
    required this.relationship,
    this.pending,
    this.derived = false,
  });

  final String personId;
  final Relationship relationship;

  /// Set while the row is the queue's, not the server's. No Remove button then
  /// - there is no `relationshipId` to delete - and the status line, with its
  /// own Retry and Discard, takes the subtitle instead.
  final PendingRelationship? pending;

  /// A grandparent: [relationship] is the *parent's* Parent row, so it reads
  /// "Grandparent" rather than its own type, and has no Remove button -
  /// deleting it here would silently edit the parent's page. The link still
  /// works, because the related person is the grandparent.
  final bool derived;

  String get _label => derived ? 'Grandparent' : relationship.type.label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final birthDate = relationship.relatedPersonBirthDate;
    final pending = this.pending;

    return ListTile(
      leading: PersonAvatar(
        storedPath: relationship.relatedPersonProfilePictureUrl,
        initials: _initials(relationship),
        size: 40,
      ),
      title: Text(
        relationship.relatedPersonName.isEmpty
            ? 'Unknown'
            : relationship.relatedPersonName,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: pending != null && !pending.isDone
          ? Row(
              children: [
                Text(
                  _label,
                  style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
                ),
                const SizedBox(width: 8),
                Flexible(child: PendingStatusLine(entry: pending)),
              ],
            )
          : Text(
              [
                _label,
                if (birthDate != null) DateFormat('MMM d, y').format(birthDate),
              ].join(' · '),
              style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
            ),
      trailing: pending != null || derived
          ? null
          : IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.link_off, size: 20),
              onPressed: () => _remove(context, ref),
            ),
      // Each row is a link to that person, as on the web. The related person
      // is always a real one, so the link works from a pending row too.
      onTap: () => context.push('/people/${relationship.relatedPersonId}'),
    );
  }

  static String _initials(Relationship relationship) {
    final first = relationship.relatedPersonFirstName ?? '';
    final last = relationship.relatedPersonLastName ?? '';
    final combined =
        '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}';
    return combined.isEmpty ? '?' : combined.toUpperCase();
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${relationship.type.label.toLowerCase()}?'),
        content: Text(
          'This removes the link to ${relationship.relatedPersonName} and its '
          'inverse. Relationships created alongside it — siblings linked to '
          'each other, a spouse’s copy of a child link — are left alone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(relationshipsRepositoryProvider)
          .delete(personId, relationship.relationshipId);
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
      return;
    }
    invalidatePerson(ref, personId);
    invalidatePerson(ref, relationship.relatedPersonId);
  }
}

// --- notes -----------------------------------------------------------------

class _NotesSection extends ConsumerWidget {
  const _NotesSection({
    required this.personId,
    required this.firstName,
    required this.isPlaceholder,
  });

  final String personId;
  final String firstName;

  /// See [_RelationshipsSection.isPlaceholder].
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = isPlaceholder
        ? const AsyncData(<Note>[])
        : ref.watch(personNotesProvider(personId));
    final fallback =
        isPlaceholder ? null : notesFor(ref.watch(allNotesProvider), personId);
    final queue = ref.watch(pendingCreatesProvider);
    final resolve = ref.read(pendingCreatesProvider.notifier).resolve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Notes'),
        _NoteComposer(personId: personId, firstName: firstName),
        _SectionBody<Note>(
          value: notes,
          fallback: fallback,
          // An empty slice for a person nobody has written about is correct
          // data, not a missing answer: it renders the empty state under the
          // bar rather than a spinner.
          builder: (data) {
            // Queued notes lead: they are the newest, and newest-first is the
            // order the server returns.
            final pending = pendingNotesFor(
              queue,
              personId,
              shown: data,
              resolve: resolve,
            );
            if (data.isEmpty && pending.isEmpty) {
              return const _Message('No notes yet. Add one above.');
            }
            return Column(
              children: [
                for (final e in pending.reversed)
                  _NoteCard(personId: personId, note: e.note, pending: e),
                for (final note in data) _NoteCard(personId: personId, note: note),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A section's list, with the bulk cache's copy standing in until the
/// person's own fetch answers - the inline counterpart of `AsyncView.fallback`,
/// which is not used here because its spinner, empty state and banner are all
/// sized for a whole screen.
///
/// The person's own value always wins once it exists, including through a
/// refresh and after a refresh that failed. That last case is a change from
/// the section's earlier `switch`, which matched the error first and replaced
/// a list the user was looking at with one line of error text; `AsyncView`'s
/// rule - a value, once shown, is never taken away - applies here too now.
///
/// No progress indicator of its own: the page header already carries the
/// refreshing strip (and the waking-up hint) for the person fetch, and a
/// second bar per section under it read as three things loading, not one.
/// With nothing cached the section is simply blank until its fetch lands.
class _SectionBody<T> extends StatelessWidget {
  const _SectionBody({
    required this.value,
    required this.fallback,
    required this.builder,
  });

  final AsyncValue<List<T>> value;

  /// This person's slice of the bulk cache; null when nothing is cached yet.
  final List<T>? fallback;

  final Widget Function(List<T> data) builder;

  @override
  Widget build(BuildContext context) {
    final own = value.value;
    if (own != null) return builder(own);

    final fallback = this.fallback;
    if (fallback != null) {
      if (!value.hasError) return builder(fallback);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Message(RefreshFailedBanner.title),
          builder(fallback),
        ],
      );
    }

    final error = value.error;
    if (error != null) return _Message(_messageFor(error));
    return const SizedBox.shrink();
  }
}

class _NoteComposer extends ConsumerStatefulWidget {
  const _NoteComposer({required this.personId, required this.firstName});

  final String personId;
  final String firstName;

  @override
  ConsumerState<_NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends ConsumerState<_NoteComposer> {
  final _content = TextEditingController();
  final _category = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _content.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _content,
            minLines: _expanded ? 3 : 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What’s new with ${widget.firstName}?',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onTap: () => setState(() => _expanded = true),
            onChanged: (_) => setState(() {}),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                hintText: 'Category (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 40),
                  ),
                  onPressed: _content.text.trim().isEmpty ? null : _save,
                  child: const Text('Save note'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _cancel() {
    _content.clear();
    _category.clear();
    setState(() => _expanded = false);
    FocusScope.of(context).unfocus();
  }

  /// Queued, not awaited: the card appears in the section at once and the
  /// composer clears, while the queue posts the note - after the person, if
  /// the person is still on their way - and re-reads the lists when it lands.
  /// A failure stays on the card with Retry and Discard.
  void _save() {
    final category = _category.text.trim();
    ref.read(pendingCreatesProvider.notifier).addNote(
          widget.personId,
          content: _content.text.trim(),
          category: category.isEmpty ? null : category,
          personName: widget.firstName,
        );
    _cancel();
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.personId, required this.note, this.pending});

  final String personId;
  final Note note;

  /// Set while the card is the queue's, not the server's: no Edit or Delete
  /// (there is no `noteId` to address), the status line in their place.
  final PendingNote? pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final createdAt = note.createdAt;
    final isRecent = createdAt != null &&
        DateTime.now().difference(createdAt) < _recentNoteWindow;
    final pending = this.pending;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        // A note from the last week carries an accent edge, as on the web
        // timeline, alongside its "New" badge.
        border: Border.all(
          color: isRecent
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (createdAt != null)
                Text(
                  DateFormat('MMM d, y').format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.mutedForeground,
                  ),
                ),
              if (note.category case final category?
                  when category.isNotEmpty) ...[
                const SizedBox(width: 6),
                _Pill(text: category, color: scheme.onSurfaceVariant),
              ],
              if (isRecent) ...[
                const SizedBox(width: 6),
                _Pill(text: 'New', color: scheme.completed),
              ],
              const Spacer(),
              if (pending != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PendingStatusLine(entry: pending),
                  ),
                )
              else ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _edit(context, ref),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            // Authored as Markdown — the web renders it with `marked`, so plain
            // text here would show raw syntax.
            child: MarkdownBlock(
              data: note.content,
              selectable: false,
              config: Theme.of(context).brightness == Brightness.dark
                  ? MarkdownConfig.darkConfig
                  : MarkdownConfig.defaultConfig,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String content, String? category})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NoteEditSheet(note: note),
    );
    if (result == null) return;

    try {
      await ref.read(notesRepositoryProvider).update(
            personId,
            note.noteId,
            content: result.content,
            category: result.category,
          );
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
      return;
    }
    ref.invalidate(personNotesProvider(personId));
    ref.invalidate(allNotesProvider);
    ref.invalidate(recentNotesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
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
      await ref.read(notesRepositoryProvider).delete(personId, note.noteId);
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
      return;
    }
    ref.invalidate(personNotesProvider(personId));
    ref.invalidate(allNotesProvider);
    ref.invalidate(recentNotesProvider);
  }
}

class _NoteEditSheet extends StatefulWidget {
  const _NoteEditSheet({required this.note});

  final Note note;

  @override
  State<_NoteEditSheet> createState() => _NoteEditSheetState();
}

class _NoteEditSheetState extends State<_NoteEditSheet> {
  late final _content = TextEditingController(text: widget.note.content);
  late final _category =
      TextEditingController(text: widget.note.category ?? '');

  @override
  void dispose() {
    _content.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit note',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _content,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Note (Markdown)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final content = _content.text.trim();
              if (content.isEmpty) return;
              final category = _category.text.trim();
              Navigator.of(context).pop((
                content: content,
                category: category.isEmpty ? null : category,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- small shared pieces ---------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, action == null ? 16 : 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
      );
}

/// A person's tags, and the way in to changing them.
///
/// No provider and no `AsyncValue` to unwrap — tags ride on the [Person] the
/// page already loaded, which is the whole point of embedding them.
///
/// Add and remove go through the sheet rather than a delete "x" on each chip:
/// one tap target instead of a 20px one beside a 30px one, one code path, and
/// the sheet has to exist anyway for the people screen.
class _TagsRow extends ConsumerWidget {
  const _TagsRow({required this.person, this.readOnly = false});

  final Person person;

  /// True while the person is the queue's placeholder.
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in person.tags)
            _Pill(
              text: tag.name,
              color: parseHexColor(tag.color) ?? scheme.onSurfaceVariant,
            ),
          // Attach and detach are keyed by the person's id, so a placeholder
          // shows its ticked tags and offers nothing to change them yet.
          if (!readOnly)
            ActionChip(
              avatar: const Icon(Icons.sell_outlined, size: 16),
              label: Text(person.tags.isEmpty ? 'Add tags' : 'Edit'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showPersonTagsSheet(context, person: person),
            ),
        ],
      ),
    );
  }
}

/// The home address: tap it to copy, or use the button to open it in a map app.
///
/// Rendered only when there is an address — no label, no "No address"
/// placeholder, unlike the birth-date line above it. A birthday is something
/// every person has and the directory actively nags for; an address is not.
///
/// Two targets rather than one overloaded gesture: a single tap that sometimes
/// copies and sometimes navigates is the kind of thing nobody trusts twice.
/// Long-press was avoided as the second action — it is undiscoverable, and
/// Android already owns it for text selection.
class _HomeAddressRow extends StatelessWidget {
  const _HomeAddressRow({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: scheme.mutedForeground);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Tooltip(
            message: 'Tap to copy',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _copy(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      // The same icon an event's location carries, so the two
                      // read as the same kind of thing.
                      Icons.place_outlined,
                      size: 15,
                      color: scheme.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(address, style: muted)),
                    const SizedBox(width: 6),
                    // Carries the whole discoverability story for the copy: a
                    // bare tappable paragraph hints at nothing.
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Open in maps',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.map_outlined),
          onPressed: () => _openInMaps(context),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    await HapticFeedback.selectionClick();
    // Android 13+ shows its own "Copied" chip, so a modern phone confirms
    // twice. Kept anyway: it is the only feedback below API 33, and it matches
    // every other confirmation in this app.
    if (context.mounted) _toast(context, 'Address copied');
  }

  Future<void> _openInMaps(BuildContext context) async {
    var launched = false;
    try {
      // No canLaunchUrl first: that is a second IPC whose answer depends on the
      // <queries> entry in the manifest being right, while launchUrl reports
      // the truth either way — it returns false rather than throwing when
      // nothing can handle the intent.
      launched = await launchUrl(
        mapSearchUri(address),
        // Never platformDefault: on iOS that sends an https URL to an in-app
        // Safari view, which would show the Maps web page instead of opening
        // the app.
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      // No activity attached — rare, and indistinguishable from "couldn't".
      launched = false;
    }

    if (!launched && context.mounted) {
      _toast(context, 'No app on this phone can open a map.');
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

String _messageFor(Object error) =>
    error is ApiException ? error.message : 'Something went wrong.';

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
