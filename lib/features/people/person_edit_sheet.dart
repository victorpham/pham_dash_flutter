import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/person_avatar.dart';
import '../../data/models/people_models.dart';
import 'people_providers.dart';
import 'person_picture_gallery.dart';
import 'person_tags_sheet.dart';

/// The upload endpoint's ceiling. Checking here turns a 400 from the server
/// into a sentence the user can act on.
const int _maxPictureBytes = 5 * 1024 * 1024;

/// Create or edit a person, returning the saved [Person] or null if cancelled.
///
/// Pass [person] to edit, omit it to create. A picture chosen while creating is
/// uploaded *after* the person exists — the upload endpoint is keyed by id, so
/// there is nowhere to put it before then. That is the same create → upload →
/// re-fetch sequence the web dialog runs.
Future<Person?> showPersonEditSheet(
  BuildContext context, {
  Person? person,
}) {
  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    // Anchored to the top rather than sized to its content. Creating autofocuses
    // the first name field, so the keyboard is already rising as the sheet
    // arrives — a content-sized sheet ends up behind it with the save button out
    // of reach. Full height instead, and the form scrolls in whatever the
    // keyboard leaves.
    builder: (context) => SizedBox(
      height: double.infinity,
      child: Padding(
        // Read off the sheet's own context. Taken from the caller's, as this
        // was, the inset stays at zero forever: that element does not rebuild
        // when the keyboard opens, so the padding never appears.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: PersonEditSheet(person: person),
      ),
    ),
  );
}

class PersonEditSheet extends ConsumerStatefulWidget {
  const PersonEditSheet({super.key, this.person});

  final Person? person;

  @override
  ConsumerState<PersonEditSheet> createState() => _PersonEditSheetState();
}

class _PersonEditSheetState extends ConsumerState<PersonEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.person?.firstName);
  late final _lastName = TextEditingController(text: widget.person?.lastName);
  late final _vietnameseName =
      TextEditingController(text: widget.person?.vietnameseName);
  late final _homeAddress =
      TextEditingController(text: widget.person?.homeAddress);

  late DateTime? _birthDate = widget.person?.birthDate;

  /// The picture chosen but not yet uploaded. On edit it uploads on save; on
  /// create it uploads once the person has an id.
  XFile? _pendingPicture;

  /// Ticked tags. Like the picture these cannot be applied until the person
  /// exists, so [_save] diffs this against the original after the write.
  late Set<int> _tagIds = {...?widget.person?.tags.map((tag) => tag.id)};

  bool _saving = false;

  bool get _isEdit => widget.person != null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _vietnameseName.dispose();
    _homeAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = _pendingPicture;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit person' : 'Add person',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),

            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (pending != null)
                    ClipOval(
                      child: Image.file(
                        File(pending.path),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    PersonAvatar(
                      storedPath: widget.person?.profilePictureUrl,
                      initials: widget.person?.initials ?? '?',
                      size: 84,
                    ),
                  Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      // Editing goes to the gallery, where a picture can be
                      // added, chosen or deleted. Creating cannot: the picture
                      // endpoints are keyed by id, and there is no id until the
                      // person is saved, so it keeps the pick-then-upload flow.
                      onTap: _saving
                          ? null
                          : _isEdit
                              ? _openGallery
                              : _pickPicture,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _isEdit
                              ? Icons.photo_library_outlined
                              : Icons.photo_camera_outlined,
                          size: 16,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _firstName,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name'),
              // The API rejects a blank first or last name with a 400; catching
              // it here keeps the round trip out of it.
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vietnameseName,
              decoration: const InputDecoration(
                labelText: 'Vietnamese name (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _homeAddress,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.streetAddress,
              autofillHints: const [AutofillHints.fullStreetAddress],
              // One line on purpose: the field is a single string, and newlines
              // would end up in both the clipboard and the map query.
              //
              // Capped rather than counted — `maxLength` would hang a 0/300
              // counter under an optional field nobody will get near the limit
              // of. The 300 matches the column; overflowing it is a
              // SqlException, which the API turns into a 500 rather than
              // anything the user could act on.
              inputFormatters: [LengthLimitingTextInputFormatter(300)],
              decoration: const InputDecoration(
                labelText: 'Home address (optional)',
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              icon: const Icon(Icons.cake_outlined),
              label: Text(
                _birthDate == null
                    ? 'Birth date (optional)'
                    : DateFormat('MMMM d, y').format(_birthDate!),
              ),
              onPressed: _saving ? null : _pickBirthDate,
            ),
            if (_birthDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _birthDate = null),
                  child: const Text('Clear birth date'),
                ),
              ),

            const SizedBox(height: 16),
            _TagPicker(
              selected: _tagIds,
              enabled: !_saving,
              onChanged: (ids) => setState(() => _tagIds = ids),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save' : 'Add person'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the picture to add another, switch which one is shown, or '
                'delete one.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.mutedForeground,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Birth date',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  /// Opens the gallery for a person that already exists.
  ///
  /// Any change in there is written immediately and invalidates the person, so
  /// there is nothing to fold into [_save] afterwards.
  Future<void> _openGallery() async {
    final person = widget.person;
    if (person == null) return;
    await showPersonPictureGallery(context, person: person);
  }

  Future<void> _pickPicture() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Downscaling here is what usually keeps the upload under the server's
      // 5 MB ceiling; phone camera originals routinely exceed it.
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (await picked.length() > _maxPictureBytes) {
      if (mounted) _toast('That image is larger than 5 MB.');
      return;
    }
    if (mounted) setState(() => _pendingPicture = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final repository = ref.read(peopleRepositoryProvider);
    final vietnameseName = _vietnameseName.text.trim();
    final homeAddress = _homeAddress.text.trim();

    try {
      var saved = _isEdit
          ? await repository.update(
              widget.person!.id,
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              vietnameseName: vietnameseName.isEmpty ? null : vietnameseName,
              homeAddress: homeAddress.isEmpty ? null : homeAddress,
              birthDate: _birthDate,
            )
          : await repository.create(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              vietnameseName: vietnameseName.isEmpty ? null : vietnameseName,
              homeAddress: homeAddress.isEmpty ? null : homeAddress,
              birthDate: _birthDate,
            );

      if (saved != null) {
        // A diff, not a replace: on edit only the changes go over the wire, and
        // on create `original` is empty so everything ticked is an attach. Like
        // the picture upload below, there is nowhere to put these until the
        // person has an id — which is why it happens here and not in the write
        // above. Cheap JSON calls first, so a slow multi-megabyte upload does
        // not delay the chips appearing.
        //
        // A failure here throws into the catch below and leaves a created but
        // partially tagged person. That is knowingly the same trade the picture
        // upload has always made: the person exists, the sheet toasts, and the
        // user finishes from the detail page.
        final original =
            widget.person?.tags.map((tag) => tag.id).toSet() ?? const <int>{};
        final tags = ref.read(personTagsRepositoryProvider);
        for (final tagId in _tagIds.difference(original)) {
          await tags.attach(saved.id, tagId);
        }
        for (final tagId in original.difference(_tagIds)) {
          await tags.detach(saved.id, tagId);
        }
      }

      final picture = _pendingPicture;
      if (saved != null && picture != null) {
        // PUT does not carry profilePictureUrl, so the upload is always a
        // second call — and it answers with the new path rather than the
        // person, hence the copyWith rather than a re-fetch.
        final url = await repository.uploadProfilePicture(
          saved.id,
          filePath: picture.path,
          fileName: picture.name,
        );
        saved = saved.copyWith(profilePictureUrl: url);
      }

      ref.invalidate(allPeopleProvider);
      if (saved != null) invalidatePerson(ref, saved.id);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(error.message);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

/// Ticks tags on and off for the person being edited.
///
/// Purely local — nothing is sent until save, because on a create there is no
/// person id to attach to yet. "New tag" is the exception: the vocabulary is
/// shared and creating one is its own write, so it goes over the wire straight
/// away and is then ticked.
class _TagPicker extends ConsumerWidget {
  const _TagPicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final Set<int> selected;
  final bool enabled;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tags = ref.watch(personTagsProvider).value ?? const <PersonTag>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              FilterChip(
                label: Text(tag.name),
                selected: selected.contains(tag.id),
                backgroundColor: parseHexColor(tag.color),
                labelStyle: chipLabelStyleOn(
                  parseHexColor(tag.color),
                  selected: selected.contains(tag.id),
                ),
                onSelected: enabled
                    ? (isSelected) => onChanged(
                          isSelected
                              ? {...selected, tag.id}
                              : ({...selected}..remove(tag.id)),
                        )
                    : null,
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('New tag'),
              onPressed: enabled ? () => _create(context, ref) : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await promptForPersonTag(context);
    if (result == null) return;

    final PersonTag? created;
    try {
      created = await ref
          .read(personTagsRepositoryProvider)
          .create(result.name, color: result.color);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }

    ref.invalidate(personTagsProvider);
    // Ticked for the person being edited, so creating one from here does what
    // it looks like it does.
    if (created != null) onChanged({...selected, created.id});
  }
}
