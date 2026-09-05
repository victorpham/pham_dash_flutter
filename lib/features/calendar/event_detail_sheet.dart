import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/calendar_models.dart';
import '../../data/models/people_models.dart';
import 'event_providers.dart';
import 'event_utils.dart';

Future<void> showEventDetailSheet(BuildContext context, CalendarEvent event) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          EventDetailSheet(event: event, scrollController: controller),
    ),
  );
}

/// Everything PhamDash knows about one calendar event.
///
/// The event itself is read-only — Google Calendar owns it. Everything editable
/// here is PhamDash's own metadata layer.
class EventDetailSheet extends ConsumerWidget {
  const EventDetailSheet({
    super.key,
    required this.event,
    required this.scrollController,
  });

  final CalendarEvent event;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final description = EventUtils.stripHtml(event.description);
    final location = event.location;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          event.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _IconLine(icon: Icons.schedule, text: EventUtils.timeRange(event)),
        if (location != null && location.isNotEmpty)
          _IconLine(icon: Icons.place_outlined, text: location),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],

        const SizedBox(height: 20),
        _CategoriesSection(event: event),

        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Who\'s coming',
          action: TextButton.icon(
            onPressed: () => _addAttendee(context, ref),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Add'),
          ),
        ),
        _AttendeesSection(eventId: event.id),

        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Notes',
          action: TextButton.icon(
            onPressed: () => _addNote(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
        _NotesSection(eventId: event.id),

        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Linked lists',
          action: TextButton.icon(
            onPressed: () => _linkList(context, ref),
            icon: const Icon(Icons.playlist_add, size: 18),
            label: const Text('Link'),
          ),
        ),
        _LinkedListsSection(eventId: event.id),

        const SizedBox(height: 20),
        _TagsSection(eventId: event.id),

        if (event.htmlLink != null) ...[
          const SizedBox(height: 24),
          Text(
            'This event lives in Google Calendar and cannot be edited here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Future<void> _addAttendee(BuildContext context, WidgetRef ref) async {
    final people = await ref.read(allPeopleProvider.future);
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PersonPicker(people: people),
    );
    if (selected == null || !context.mounted) return;

    try {
      await ref
          .read(calendarRepositoryProvider)
          .addAttendee(event.id, personId: selected.id);
      ref.invalidate(eventAttendeesProvider(event.id));
      ref.invalidate(eventSummaryProvider(event.id));
    } on ApiException catch (error) {
      if (!context.mounted) return;
      // 409 here means "already an attendee", which is worth stating plainly
      // rather than showing as a generic failure.
      _toast(
        context,
        error.isConflict
            ? '${selected.fullName} is already an attendee.'
            : error.message,
      );
    }
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final content = await _promptForText(context, title: 'Add a note');
    if (content == null || !context.mounted) return;

    try {
      await ref.read(calendarRepositoryProvider).addNote(event.id, content);
      ref.invalidate(eventNotesProvider(event.id));
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    }
  }

  Future<void> _linkList(BuildContext context, WidgetRef ref) async {
    final lists = await ref.read(todoRepositoryProvider).lists();
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final list in lists)
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(list.title),
              subtitle: Text('${list.completedItems}/${list.totalItems} done'),
              onTap: () => Navigator.of(context).pop(list.id),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;

    try {
      await ref.read(calendarRepositoryProvider).linkList(event.id, selected);
      ref.invalidate(eventLinkedListsProvider(event.id));
    } on ApiException catch (error) {
      if (context.mounted) _toast(context, error.message);
    }
  }
}

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = ref.watch(eventCategoriesProvider(event.id));
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final category in assigned.value ?? event.categories)
          InputChip(
            label: Text(category.name),
            backgroundColor: (parseHexColor(category.color) ?? scheme.primary)
                .withValues(alpha: 0.16),
            onDeleted: () async {
              await ref
                  .read(calendarRepositoryProvider)
                  .unassignCategory(event.id, category.id);
              ref.invalidate(eventCategoriesProvider(event.id));
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Category'),
          onPressed: () => _assign(context, ref),
        ),
      ],
    );
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final all = await ref.read(allEventCategoriesProvider.future);
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<EventCategory>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final category in all)
            ListTile(
              leading: CircleAvatar(
                radius: 10,
                backgroundColor: parseHexColor(category.color) ??
                    Theme.of(context).colorScheme.primary,
              ),
              title: Text(category.name),
              onTap: () => Navigator.of(context).pop(category),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;

    try {
      await ref
          .read(calendarRepositoryProvider)
          .assignCategory(event.id, selected.id);
      ref.invalidate(eventCategoriesProvider(event.id));
    } on ApiException catch (error) {
      if (context.mounted) {
        _toast(
          context,
          error.isConflict
              ? '"${selected.name}" is already on this event.'
              : error.message,
        );
      }
    }
  }
}

/// Attendees, rendered from the `summary` payload.
///
/// `GET .../summary` is a single call that carries each attendee's age, three
/// most recent notes and immediate family — the alternative is several round
/// trips per person.
class _AttendeesSection extends ConsumerWidget {
  const _AttendeesSection({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(eventSummaryProvider(eventId));
    final attendees = ref.watch(eventAttendeesProvider(eventId));
    final scheme = Theme.of(context).colorScheme;

    return summary.when(
      loading: () => const _SectionLoading(),
      error: (error, _) => _SectionMessage(
        text: error is ApiException ? error.message : 'Could not load attendees.',
      ),
      data: (people) {
        if (people.isEmpty) {
          return const _SectionMessage(text: 'No one linked to this event yet.');
        }

        return Column(
          children: [
            for (final person in people)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.rowSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PersonAvatar(
                          storedPath: person.profilePictureUrl,
                          initials: _initials(person.name),
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (person.age != null)
                                Text(
                                  'Age ${person.age}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _remove(
                            ref,
                            attendees.value,
                            person.personId,
                          ),
                        ),
                      ],
                    ),
                    if (person.immediateFamily.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Already formatted server-side as "Name (Type)".
                          for (final relative in person.immediateFamily)
                            Chip(
                              label: Text(
                                relative,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                    if (person.recentNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final note in person.recentNotes)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${note.content}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _remove(
    WidgetRef ref,
    List<CalendarEventAttendee>? attendees,
    String personId,
  ) async {
    // The summary payload has no attendee row id, so map through the attendee
    // list to find the row to delete.
    final match =
        attendees?.where((a) => a.personId == personId).firstOrNull;
    if (match == null) return;

    await ref
        .read(calendarRepositoryProvider)
        .removeAttendee(eventId, match.id);
    ref.invalidate(eventAttendeesProvider(eventId));
    ref.invalidate(eventSummaryProvider(eventId));
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _NotesSection extends ConsumerWidget {
  const _NotesSection({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(eventNotesProvider(eventId));
    final scheme = Theme.of(context).colorScheme;

    return notes.when(
      loading: () => const _SectionLoading(),
      error: (error, _) => _SectionMessage(
        text: error is ApiException ? error.message : 'Could not load notes.',
      ),
      data: (data) {
        if (data.isEmpty) {
          return const _SectionMessage(text: 'No notes on this event.');
        }
        return Column(
          children: [
            for (final note in data)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                decoration: BoxDecoration(
                  color: scheme.rowSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(note.content)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () async {
                        final updated = await _promptForText(
                          context,
                          title: 'Edit note',
                          initial: note.content,
                        );
                        if (updated == null) return;
                        await ref
                            .read(calendarRepositoryProvider)
                            .updateNote(eventId, note.id, updated);
                        ref.invalidate(eventNotesProvider(eventId));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () async {
                        await ref
                            .read(calendarRepositoryProvider)
                            .deleteNote(eventId, note.id);
                        ref.invalidate(eventNotesProvider(eventId));
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LinkedListsSection extends ConsumerWidget {
  const _LinkedListsSection({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(eventLinkedListsProvider(eventId));

    return lists.when(
      loading: () => const _SectionLoading(),
      error: (error, _) => _SectionMessage(
        text: error is ApiException ? error.message : 'Could not load lists.',
      ),
      data: (data) {
        if (data.isEmpty) {
          return const _SectionMessage(
            // Worth explaining: linking is what surfaces a list on the
            // dashboard ahead of the event.
            text: 'No lists linked. Linking one makes it appear in the Lists '
                'tab before this event.',
          );
        }
        return Column(
          children: [
            for (final list in data)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.checklist),
                title: Text(list.title),
                subtitle: Text('${list.itemCount} items'),
                trailing: IconButton(
                  icon: const Icon(Icons.link_off, size: 18),
                  onPressed: () async {
                    await ref
                        .read(calendarRepositoryProvider)
                        .unlinkList(eventId, list.id);
                    ref.invalidate(eventLinkedListsProvider(eventId));
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Read-only in the MVP; tag editing can wait.
class _TagsSection extends ConsumerWidget {
  const _TagsSection({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(eventTagsProvider(eventId)).value ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Chip(
            label: Text(tag.tag),
            backgroundColor: (parseHexColor(tag.color) ?? scheme.secondary)
                .withValues(alpha: 0.16),
          ),
      ],
    );
  }
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({required this.people});

  final List<Person> people;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final matches = widget.people.where((person) {
      if (query.isEmpty) return true;
      return person.fullName.toLowerCase().contains(query) ||
          (person.vietnameseName ?? '').toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final person = matches[index];
                return ListTile(
                  leading: PersonAvatar(
                    storedPath: person.profilePictureUrl,
                    initials: person.initials,
                    size: 36,
                  ),
                  title: Text(person.fullName),
                  subtitle: person.vietnameseName == null
                      ? null
                      : Text(person.vietnameseName!),
                  onTap: () => Navigator.of(context).pop(person),
                );
              },
            ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        ?action,
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

Future<String?> _promptForText(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        minLines: 1,
        decoration: const InputDecoration(hintText: 'Type here…'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}
