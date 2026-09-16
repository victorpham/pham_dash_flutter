import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../core/ui/person_picker.dart';
import '../../data/models/converters.dart';
import '../../data/models/people_models.dart';
import '../notes/recent_notes_tab.dart';
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

/// Drops the whole chain of person pages and lands on the people list.
///
/// Popping to the list is preferred over navigating to it, so that whatever sat
/// underneath the chain — the dashboard, usually — survives as the back target.
/// A chain that began at a birthday row or a recent note has no list beneath it
/// to land on, so one is pushed instead; either way the button does what it
/// says.
void _backToPeopleList(BuildContext context) {
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

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(personProvider(personId));

    return Scaffold(
      appBar: AppBar(
        title: Text(person.value?.fullName ?? 'Person'),
        actions: [
          // Only once a chain has formed. On the first person page the ordinary
          // back button already does this, and a second button that behaves
          // identically is just noise.
          if (_personPagesInStack(context) > 1)
            IconButton(
              tooltip: 'Back to the people list',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => _backToPeopleList(context),
            ),
          if (person.value != null)
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
        onRetry: () => ref.invalidate(personProvider(personId)),
        isEmpty: (data) => data == null,
        emptyIcon: Icons.person_off_outlined,
        emptyTitle: 'Person not found',
        builder: (data) => RefreshIndicator(
          onRefresh: () async {
            invalidatePerson(ref, personId);
            await ref.read(personProvider(personId).future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _Header(person: data!),
              // Attached to the header rather than fenced off with a divider:
              // tags are an attribute of the person, not a section of records
              // peer to Relationships and Notes.
              _TagsRow(person: data),
              const Divider(height: 32),
              _RelationshipsSection(person: data),
              const Divider(height: 32),
              _NotesSection(personId: personId, firstName: data.firstName),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.person});

  final Person person;

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
                onTap: () => showPersonPictureGallery(context, person: person),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    PersonAvatar(
                      storedPath: person.profilePictureUrl,
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
  const _RelationshipsSection({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationships = ref.watch(personRelationshipsProvider(person.id));

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
        switch (relationships) {
          AsyncError(:final error) => _Message(_messageFor(error)),
          AsyncValue(hasValue: false) => const _SectionLoading(),
          AsyncValue(value: final data) => _RelationshipList(
              personId: person.id,
              groups: RelationshipGroups.from(data ?? const []),
            ),
        },
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final people = await ref.read(allPeopleProvider.future);
    final existing = ref.read(personRelationshipsProvider(person.id)).value ??
        const <Relationship>[];

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

    try {
      await ref.read(relationshipsRepositoryProvider).create(
            person.id,
            relatedPersonId: selected.id,
            type: type,
          );
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
      return;
    }

    // One create can write several rows — the inverse, the whole sibling group,
    // a spouse's copy of a child link — so both people are re-read rather than
    // patched.
    invalidatePerson(ref, person.id);
    invalidatePerson(ref, selected.id);
  }
}

class _RelationshipList extends ConsumerWidget {
  const _RelationshipList({required this.personId, required this.groups});

  final String personId;
  final RelationshipGroups groups;

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
            _RelationshipRow(personId: personId, relationship: spouse),
          for (final child in groups.children)
            _RelationshipRow(personId: personId, relationship: child),
        ],
        if (groups.others.isNotEmpty) ...[
          _SubHeader('Other relationships (${groups.others.length})'),
          for (final other in groups.others)
            _RelationshipRow(personId: personId, relationship: other),
        ],
      ],
    );
  }
}

class _RelationshipRow extends ConsumerWidget {
  const _RelationshipRow({required this.personId, required this.relationship});

  final String personId;
  final Relationship relationship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final birthDate = relationship.relatedPersonBirthDate;

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
      subtitle: Text(
        [
          relationship.type.label,
          if (birthDate != null) DateFormat('MMM d, y').format(birthDate),
        ].join(' · '),
        style: TextStyle(fontSize: 12.5, color: scheme.mutedForeground),
      ),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.link_off, size: 20),
        onPressed: () => _remove(context, ref),
      ),
      // Each row is a link to that person, as on the web.
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
  const _NotesSection({required this.personId, required this.firstName});

  final String personId;
  final String firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(personNotesProvider(personId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Notes'),
        _NoteComposer(personId: personId, firstName: firstName),
        switch (notes) {
          AsyncError(:final error) => _Message(_messageFor(error)),
          AsyncValue(hasValue: false) => const _SectionLoading(),
          AsyncValue(value: final data) when (data ?? const []).isEmpty =>
            const _Message('No notes yet. Add one above.'),
          AsyncValue(value: final data) => Column(
              children: [
                for (final note in data!)
                  _NoteCard(personId: personId, note: note),
              ],
            ),
        },
      ],
    );
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
  bool _saving = false;
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
                  onPressed: _saving ? null : _cancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 40),
                  ),
                  onPressed: _saving || _content.text.trim().isEmpty
                      ? null
                      : _save,
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

  Future<void> _save() async {
    setState(() => _saving = true);
    final category = _category.text.trim();

    try {
      await ref.read(notesRepositoryProvider).create(
            widget.personId,
            content: _content.text.trim(),
            category: category.isEmpty ? null : category,
          );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _toast(context, error.message);
      }
      return;
    }

    ref.invalidate(personNotesProvider(widget.personId));
    // The dashboard's recent-notes feed is now a note behind.
    ref.invalidate(recentNotesProvider);
    if (mounted) {
      setState(() => _saving = false);
      _cancel();
    }
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.personId, required this.note});

  final String personId;
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final createdAt = note.createdAt;
    final isRecent = createdAt != null &&
        DateTime.now().difference(createdAt) < _recentNoteWindow;

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

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
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
  const _TagsRow({required this.person});

  final Person person;

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
