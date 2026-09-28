import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../core/cache/cached_list.dart';
import '../../core/cache/freshness.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/people_models.dart';
import '../calendar/event_utils.dart';
import '../people/pending_creates.dart';
import '../people/pending_status.dart';
import '../people/people_providers.dart';
import 'add_note_sheet.dart';

/// The only notes endpoint that embeds the author `person`, so every row can
/// show an avatar without an extra request.
final recentNotesProvider =
    AsyncNotifierProvider.autoDispose<RecentNotesNotifier, List<Note>>(
  RecentNotesNotifier.new,
);

class RecentNotesNotifier extends AsyncNotifier<List<Note>>
    with CachedList<Note> {
  @override
  Future<List<Note>> build() {
    persistList(
      'recent_notes',
      fromJson: Note.fromJson,
      toJson: (note) => note.toJson(),
    );
    return ref.watch(notesRepositoryProvider).recent(count: 10);
  }
}

/// The Notes tab's action button, hosted by the dashboard shell's Scaffold.
class AddNoteButton extends ConsumerWidget {
  const AddNoteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      tooltip: 'New note',
      onPressed: () => showAddNoteSheet(context),
      child: const Icon(Icons.note_add_outlined),
    );
  }
}

class RecentNotesTab extends ConsumerWidget {
  const RecentNotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);
    // Notes queued from the sheet lead the feed until the re-read that
    // follows their save contains them. `/notes/recent` embeds the author;
    // a placeholder borrows theirs from the directory so the avatar draws.
    final queue = ref.watch(pendingCreatesProvider);
    final resolve = ref.read(pendingCreatesProvider.notifier).resolve;
    final directory = ref.watch(allPeopleProvider).value ?? const <Person>[];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(recentNotesProvider.future),
      child: AsyncView<List<Note>>(
        value: notes,
        // The saved copy for every build that is not the element's first one,
        // which is the only one `CachedList` seeds.
        fallback: notes.hasValue
            ? null
            : cachedSeedOf(ref, 'recent_notes', Note.fromJson),
        updatedAt: freshnessOf(ref, 'recent_notes'),
        onRetry: () => ref.invalidate(recentNotesProvider),
        isEmpty: (data) =>
            data.isEmpty && _pendingRows(queue, data, resolve).isEmpty,
        emptyIcon: Icons.sticky_note_2_outlined,
        emptyTitle: 'No notes yet',
        emptyMessage: 'Notes about people show up here. Tap + to write one.',
        builder: (data) {
          final pending = _pendingRows(queue, data, resolve);
          final rows = [
            for (final e in pending.reversed)
              (
                note: e.note.copyWith(
                  // A note about a person who is themselves still pending has
                  // no directory row yet; the queue's placeholder stands in.
                  person: directory
                          .where((p) => p.id == resolve(e.personRef))
                          .firstOrNull ??
                      queue
                          .whereType<PendingPerson>()
                          .where((p) => p.tempId == e.personRef)
                          .firstOrNull
                          ?.placeholder,
                ),
                pending: e,
              ),
            for (final note in data) (note: note, pending: null),
          ];
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 66),
            itemBuilder: (context, index) => _NoteRow(
              note: rows[index].note,
              pending: rows[index].pending,
            ),
          );
        },
      ),
    );
  }

  /// Every queued note, whoever it is about - the feed is not per person.
  static List<PendingNote> _pendingRows(
    List<PendingCreate> queue,
    List<Note> shown,
    String Function(String) resolve,
  ) {
    final ids = {for (final n in shown) n.noteId};
    return [
      for (final e in queue.whereType<PendingNote>())
        if (!(e.isDone && ids.contains(e.result?.noteId))) e,
    ];
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, this.pending});

  final Note note;

  /// Set while the row is the queue's; the status line replaces the age.
  final PendingNote? pending;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final person = note.person;
    final createdAt = note.createdAt;
    final category = note.category;
    final pending = this.pending;

    return InkWell(
      // The web widget links each row to its author's detail page. A note whose
      // person did not come back on the feed has nowhere to go.
      onTap: person == null
          ? null
          : () => context.push('/people/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonAvatar(
            storedPath: person?.profilePictureUrl,
            initials: person?.initials ?? '?',
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        person?.fullName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (pending != null && !pending.isDone)
                      PendingStatusLine(entry: pending)
                    else if (createdAt != null)
                      Text(
                        EventUtils.relative(createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.mutedForeground,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Note content is authored as Markdown — the web renders it
                // with `marked`, so rendering it as plain text here would show
                // raw syntax.
                MarkdownBlock(
                  data: note.content,
                  selectable: false,
                  config: Theme.of(context).brightness == Brightness.dark
                      ? MarkdownConfig.darkConfig
                      : MarkdownConfig.defaultConfig,
                ),
                if (category != null && category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
