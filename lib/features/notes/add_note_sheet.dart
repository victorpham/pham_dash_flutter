import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/person_avatar.dart';
import '../../core/ui/person_picker.dart';
import '../../data/models/people_models.dart';
import '../people/people_providers.dart';
import 'recent_notes_tab.dart';

/// Writes a note from the dashboard, where no person is implied yet.
///
/// A person is not an optional extra here: the only create route is
/// `POST /api/people/{personId}/notes`, so the id is part of the URL and an
/// unattached note has nowhere to go. The save button stays disabled until one
/// is chosen rather than letting the request fail.
///
/// Returns true when a note was created.
Future<bool> showAddNoteSheet(BuildContext context, {Person? person}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => AddNoteSheet(person: person),
  );
  return created ?? false;
}

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({super.key, this.person});

  /// Pre-selects the subject, for callers that already know it.
  final Person? person;

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _content = TextEditingController();
  final _category = TextEditingController();

  late Person? _person = widget.person;
  bool _saving = false;

  bool get _canSave =>
      !_saving && _person != null && _content.text.trim().isNotEmpty;

  @override
  void dispose() {
    _content.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final person = _person;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New note',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // The subject comes first: it decides where the note is filed, and
            // it is the one field that cannot be left out.
            Material(
              color: scheme.rowSurface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : _pickPerson,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (person == null)
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person_outline,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      else
                        PersonAvatar(
                          storedPath: person.profilePictureUrl,
                          initials: person.initials,
                          size: 40,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person?.fullName ?? 'Who is this note about?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: person == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              person == null
                                  ? 'Required'
                                  : 'Tap to choose someone else',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _content,
              autofocus: person != null,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: person == null
                    ? "What's new?"
                    : "What's new with ${person.firstName}?",
                helperText: 'Markdown is rendered when the note is shown.',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
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
              onPressed: _canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPerson() async {
    final people = await ref.read(allPeopleProvider.future);
    if (!mounted) return;

    final selected = await pickPerson(
      context,
      people: people,
      title: 'Search people',
    );
    if (selected != null) setState(() => _person = selected);
  }

  Future<void> _save() async {
    final person = _person;
    if (person == null) return;

    setState(() => _saving = true);
    final category = _category.text.trim();

    try {
      await ref.read(notesRepositoryProvider).create(
            person.id,
            content: _content.text.trim(),
            category: category.isEmpty ? null : category,
          );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    ref.invalidate(recentNotesProvider);
    // That person's own page is a note behind now too.
    ref.invalidate(personNotesProvider(person.id));

    if (mounted) Navigator.of(context).pop(true);
  }
}
