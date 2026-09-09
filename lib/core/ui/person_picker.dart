import 'package:flutter/material.dart';

import '../../data/models/people_models.dart';
import 'person_avatar.dart';

/// A searchable people sheet, returning the chosen person or null.
///
/// Search matches the same two fields the web people page does — the full name
/// and the Vietnamese name — so a person findable on the web is findable here.
Future<Person?> pickPerson(
  BuildContext context, {
  required List<Person> people,
  String title = 'Choose a person',
}) {
  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => PersonPicker(people: people, title: title),
  );
}

class PersonPicker extends StatefulWidget {
  const PersonPicker({
    super.key,
    required this.people,
    this.title = 'Choose a person',
  });

  final List<Person> people;
  final String title;

  @override
  State<PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<PersonPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
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
              decoration: InputDecoration(
                hintText: widget.title,
                prefixIcon: const Icon(Icons.search),
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
