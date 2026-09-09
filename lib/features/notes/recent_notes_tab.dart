import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/async_view.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/people_models.dart';
import '../calendar/event_utils.dart';

/// The only notes endpoint that embeds the author `person`, so every row can
/// show an avatar without an extra request.
final recentNotesProvider = FutureProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).recent(count: 10),
);

class RecentNotesTab extends ConsumerWidget {
  const RecentNotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(recentNotesProvider.future),
      child: AsyncView<List<Note>>(
        value: notes,
        onRetry: () => ref.invalidate(recentNotesProvider),
        emptyIcon: Icons.sticky_note_2_outlined,
        emptyTitle: 'No notes yet',
        emptyMessage: 'Notes added to people show up here.',
        builder: (data) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 66),
          itemBuilder: (context, index) => _NoteRow(note: data[index]),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final person = note.person;
    final createdAt = note.createdAt;
    final category = note.category;

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
                    if (createdAt != null)
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
