import 'dart:io';

import 'package:flutter/material.dart';
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
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PersonEditSheet(person: person),
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

  late DateTime? _birthDate = widget.person?.birthDate;

  /// The picture chosen but not yet uploaded. On edit it uploads on save; on
  /// create it uploads once the person has an id.
  XFile? _pendingPicture;

  bool _saving = false;

  bool get _isEdit => widget.person != null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _vietnameseName.dispose();
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

    try {
      var saved = _isEdit
          ? await repository.update(
              widget.person!.id,
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              vietnameseName: vietnameseName.isEmpty ? null : vietnameseName,
              birthDate: _birthDate,
            )
          : await repository.create(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              vietnameseName: vietnameseName.isEmpty ? null : vietnameseName,
              birthDate: _birthDate,
            );

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
